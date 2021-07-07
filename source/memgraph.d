module memgraph;

public import mgclient;

import std.string;

struct ConstMap {
	mg_map *_map;
}

struct Value {
	this(const mg_value *value) {
		_value = value;
	}
	const mg_value *_value;
}

struct Optional(V) {
	this(V value) {
		_value = value;
		_hasValue = true;
	}
	this(Args...)(Args args) {
		_value = V(args);
		_hasValue = true;
	}
	auto opAssign(V value) {
		_value = value;
		_hasValue = true;
		return this;
	}
	auto opCast(T : bool)() const {
		return _hasValue;
	}
	auto opCast(T : V)() const {
		return _value;
	}
	auto hasValue() const {
		return _hasValue;
	}
	auto value() const {
		return _value;
	}
private:
	bool _hasValue;
	V _value;
	alias _value this;
}

struct Client {
	struct Params {
		string host = "localhost";
		ushort port = 7687;
		string username;
		string password;
		bool useSsl;
		string userAgent; // defaults to "memgraph-d/major.minor.patch"
	}

	// TODO maybe rather a class ?

	// Client(const Client &) = delete;
	// Client(Client &&) = default;
	// Client &operator=(const Client &) = delete;
	// Client &operator=(Client &&) = delete;
	// ~Client();
	~this() {
		mg_session_destroy(session);
	}

	/// \brief Client software version.
	/// \return client version in the major.minor.patch format.
	static auto Version() { return fromStringz(mg_client_version()); }

	/// Initializes the client (the whole process).
	/// Should be called at the beginning of each process using the client.
	///
	/// \return Zero if initialization was successful.
	static int Init() { return mg_init(); }

	/// Finalizes the client (the whole process).
	/// Should be called at the end of each process using the client.
	static void Finalize() { mg_finalize(); }

	/// \brief Executes the given Cypher `statement`.
	/// \return true when the statement is successfully executed, false otherwise.
	/// \note
	/// After executing the statement, the method is blocked until all incoming
	/// data (execution results) are handled, i.e. until `FetchOne` method returns
	/// `std::nullopt`. Even if the result set is empty, the fetching has to be
	/// done/finished to be able to execute another statement.
	bool Execute(const ref string statement) {
		int status = mg_session_run(session, toStringz(statement), null, null, null, null);
		if (status < 0) {
			return false;
		}

		status = mg_session_pull(session, null);
		if (status < 0) {
			return false;
		}

		return true;
	}

	/// \brief Executes the given Cypher `statement`, supplied with additional
	/// `params`.
	/// \return true when the statement is successfully executed, false
	/// otherwise.
	/// \note
	/// After executing the statement, the method is blocked
	/// until all incoming data (execution results) are handled, i.e. until
	/// `FetchOne` method returns `std::nullopt`.
	bool Execute(const ref string statement, const ref ConstMap params) {
		int status = mg_session_run(session, toStringz(statement), params._map, null, null, null);
		if (status < 0) {
			return false;
		}

		status = mg_session_pull(session, null);
		if (status < 0) {
			return false;
		}
		return true;
	}

	/// \brief Fetches the next result from the input stream.
	/// \return next result from the input stream.
	/// If there is nothing to fetch, `std::nullopt` is returned.
	Value[] FetchOne() {
		mg_result *result;
		int status = mg_session_fetch(session, &result);
		if (status != 1) {
			return null; // TODO ?
		}

		Value[] values;
		const (mg_list) *list = mg_result_row(result);
		const size_t list_length = mg_list_size(list);
		values.length = list_length;
		for (uint i = 0; i < list_length; ++i) {
			values ~= Value(mg_list_at(list, i));
		}
		return values;
	}

	/// \brief Fetches all results and discards them.
	void DiscardAll() {
		while (FetchOne()) { }
	}

	/// \brief Fetches all results.
	Value[][] FetchAll() {
		Value[] maybeResult;
		Value[][] data;
		while ((maybeResult = FetchOne()).length > 0) {
			data ~= maybeResult;
		}
		return data;
	}

	/// \brief Start a transaction.
	/// \return true when the transaction was successfully started, false
	/// otherwise.
	bool BeginTransaction() {
		return mg_session_begin_transaction(session, null) == 0;
	}

	/// \brief Commit current transaction.
	/// \return true when the transaction was successfully committed, false
	/// otherwise.
	bool CommitTransaction() {
		mg_result *result;
		return mg_session_commit_transaction(session, &result) == 0;
	}

	/// \brief Rollback current transaction.
	/// \return true when the transaction was successfully rollbacked, false
	/// otherwise.
	bool RollbackTransaction() {
		mg_result *result;
		return mg_session_rollback_transaction(session, &result) == 0;
	}

	static Optional!Client Connect() {
		Params params; // use default parameters: localhost:7687
		return Connect(params);
	}

	/// \brief Static method that creates a Memgraph client instance.
	/// \return pointer to the created client instance.
	/// If the connection couldn't be established given the `params`, it returns
	/// a `nullptr`.
	static Optional!Client Connect(const ref Params params) {
		Optional!Client ret;
		mg_session_params *mg_params = mg_session_params_make();
		if (!mg_params) {
			return ret;
		}
		mg_session_params_set_host(mg_params, toStringz(params.host));
		mg_session_params_set_port(mg_params, params.port);
		if (params.username.length > 0) {
			mg_session_params_set_username(mg_params, toStringz(params.username));
			mg_session_params_set_password(mg_params, toStringz(params.password));
		}
		mg_session_params_set_user_agent(mg_params,
					params.userAgent.length > 0 ?
						toStringz(params.userAgent) :
						toStringz("memgraph-d/" ~ fromStringz(mg_client_version()))
				);
		mg_session_params_set_sslmode(mg_params, params.useSsl ? mg_sslmode.MG_SSLMODE_REQUIRE : mg_sslmode.MG_SSLMODE_DISABLE);

		mg_session *session = null;
		int status = mg_connect(mg_params, &session);
		mg_session_params_destroy(mg_params);
		if (status < 0) {
			return ret;
		}

		return Optional!Client(session);
	}

private:
	this(mg_session *session) {
		this.session = session;
	}

	mg_session *session;
}

version (unittest) {
	string dockerContainer;
}

/// Start a memgraph container for unit testing.
unittest {
	import std.process, std.stdio;
	writefln("memgraph.d: starting memgraph docker container...");
	auto run = execute(["docker", "run", "-p", "7687:7687", "-d", "memgraph/memgraph"]);
	assert(run.status == 0);
	dockerContainer = run.output;

	// Need to wait a while until the container is spun up, otherwise connecting will fail.
	import core.thread.osthread;
	import core.time;
	Thread.sleep(dur!("msecs")(1000));
}

unittest {
	import std.string, std.conv, std.stdio;

	writefln("memgraph.d: connecting to memgraph docker container...");

	assert(Client.Init() == 0);

	auto client = Client.Connect();

	assert(client.hasValue == true);

	Client.Finalize(); // TODO check if it is a problem if mg_finalize() comes before mg_session_destroy()
}

/// Stop the memgraph container again.
unittest {
	import std.process, std.string, std.stdio;
	writefln("memgraph.d: stopping memgraph docker container...");
	auto stop = execute(["docker", "rm", "-f", stripRight(dockerContainer)]);
	assert(stop.status == 0);
	assert(stop.output == dockerContainer);
}

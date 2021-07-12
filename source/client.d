/// Provides a connection for memgraph.
module client;

import std.string, std.stdio;

import mgclient, optional, value, map;

/// Provides a connection for memgraph.
struct Client {
	/// Connection parameters for Connect(Params)
	struct Params {
		/// Hostname, defaults to `localhost`.
		string host = "localhost";
		/// Port, defaults to 7687.
		ushort port = 7687;
		/// Username, if authentication is required.
		string username;
		/// Password, if authentication is required.
		string password;
		/// Set to true, if encryption is required.
		bool useSsl;
		/// Useragent used when connecting to memgraph, defaults to "memgraph-d/major.minor.patch".
		string userAgent;
	}

	// TODO
	// Client(const Client &) = delete;
	// Client(Client &&) = default;
	// Client &operator=(const Client &) = delete;
	// Client &operator=(Client &&) = delete;

	/// Destructor, destroys the memgraph session.
	~this() {
		if (session)
			mg_session_destroy(session);
	}

	/// Client software version.
	/// Return: Client version in the major.minor.patch format.
	static auto Version() { return fromStringz(mg_client_version()); }

	/// Initializes the client (the whole process).
	/// Should be called at the beginning of each process using the client.
	/// Return: Zero if initialization was successful.
	static int Init() { return mg_init(); }

	/// Finalizes the client (the whole process).
	/// Should be called at the end of each process using the client.
	static void Finalize() { mg_finalize(); }

	/// Executes the given Cypher `statement`.
	/// Return: true when the statement is successfully executed, false otherwise.
	/// After executing the statement, the method is blocked until all incoming
	/// data (execution results) are handled, i.e. until `FetchOne` method returns
	/// an empty array. Even if the result set is empty, the fetching has to be
	/// done/finished to be able to execute another statement.
	bool Execute(const string statement) {
		int status = mg_session_run(session, toStringz(statement), null, null, null, null);
		if (status < 0)
			return false;

		status = mg_session_pull(session, null);
		if (status < 0)
			return false;

		return true;
	}

	/// Executes the given Cypher `statement`, supplied with additional `params`.
	/// Return: true when the statement is successfully executed, false otherwise.
	/// After executing the statement, the method is blocked until all incoming
	/// data (execution results) are handled, i.e. until `FetchOne` method returns
	/// an empty array.
	bool Execute(const string statement, const ref Map params) {
		int status = mg_session_run(session, toStringz(statement), params.ptr, null, null, null);
		if (status < 0) {
			return false;
		}

		status = mg_session_pull(session, null);
		if (status < 0) {
			return false;
		}
		return true;
	}

	/// Fetches the next result from the input stream.
	/// Return next result from the input stream.
	/// If there is nothing to fetch, an empty array is returned.
	Value[] FetchOne() {
		mg_result *result;
		Value[] values;
		int status = mg_session_fetch(session, &result);
		if (status != 1)
			return values;

		const (mg_list) *list = mg_result_row(result);
		const size_t list_length = mg_list_size(list);
		values.length = list_length;
		for (uint i = 0; i < list_length; ++i)
			values[i] = Value(mg_list_at(list, i));
		return values;
	}

	/// Fetches all results and discards them.
	void DiscardAll() {
		while (FetchOne()) { }
	}

	/// Fetches all results.
	Value[][] FetchAll() {
		Value[] maybeResult;
		Value[][] data;
		while ((maybeResult = FetchOne()).length > 0)
			data ~= maybeResult;
		return data;
	}

	/// Start a transaction.
	/// Return: true when the transaction was successfully started, false otherwise.
	bool BeginTransaction() {
		return mg_session_begin_transaction(session, null) == 0;
	}

	/// Commit current transaction.
	/// Return: true when the transaction was successfully committed, false otherwise.
	bool CommitTransaction() {
		mg_result *result;
		return mg_session_commit_transaction(session, &result) == 0;
	}

	/// Rollback current transaction.
	/// Return: true when the transaction was successfully rollbacked, false otherwise.
	bool RollbackTransaction() {
		mg_result *result;
		return mg_session_rollback_transaction(session, &result) == 0;
	}

	/// Static method that creates a Memgraph client instance using default parameters localhost:7687
	/// Return: optional client connection instance.
	/// Returns an empty optional if the connection couldn't be established.
	static Optional!Client Connect() {
		Params params;
		return Connect(params);
	}

	/// Static method that creates a Memgraph client instance.
	/// Return: optional client connection instance.
	/// If the connection couldn't be established given the `params`, it returns
	/// an empty optional.
	static Optional!Client Connect(const ref Params params) {
		mg_session_params *mg_params = mg_session_params_make();
		if (!mg_params)
			return Optional!Client();
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
		if (status < 0)
			return Optional!Client();

		return Optional!Client(session);
	}

	this(ref return scope inout Client rhs) inout {
		writefln("*** Client Copy CTOR lhs: %s rhs: %s", session, rhs.session);
	}

	/*
	this(ref return scope const Client rhs) const {
		writefln("*** Client const Copy CTOR lhs: %s rhs: %s", session, rhs.session);
	}
	*/

	this(mg_session *session) {
		this.session = session;
	}

private:
	mg_session *session;
}

unittest {
	import testutils;
	startContainer();
}

/// Test connection to memgraph on localhost, port 7688.
unittest {
	assert(Client.Init() == 0);

	Client.Params params;
	params.port = 7688;
	auto client = Client.Connect(params);

	assert(client);

	Client.Finalize();
}

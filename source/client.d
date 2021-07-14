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
	static auto clientVersion() { return fromStringz(mg_client_version()); }

	/// Obtains the error message stored in the current session (if any).
	auto sessionError() {
		// mg_session_error() seems to randomly fill the first byte with garbage when there actually is no error.
		auto err = fromStringz(mg_session_error(session));
		return err.length == 1 ? "" : err;
	}

	/// Returns the status of the current session.
	///
	/// Return: One of the session codes in `mg_session_code`.
	auto sessionStatus() const {
		return mg_session_status(session);
	}

	/// Executes the given Cypher `statement`.
	/// Return: true when the statement is successfully executed, false otherwise.
	/// After executing the statement, the method is blocked until all incoming
	/// data (execution results) are handled, i.e. until `FetchOne` method returns
	/// an empty array. Even if the result set is empty, the fetching has to be
	/// done/finished to be able to execute another statement.
	bool execute(const string statement) {
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
	bool execute(const string statement, const ref Map params) {
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
	Value[] fetchOne() {
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
	void discardAll() {
		while (fetchOne()) { }
	}

	/// Fetches all results.
	Value[][] fetchAll() {
		Value[] maybeResult;
		Value[][] data;
		while ((maybeResult = fetchOne()).length > 0)
			data ~= maybeResult;
		return data;
	}

	/// Start a transaction.
	/// Return: true when the transaction was successfully started, false otherwise.
	bool beginTransaction() {
		return mg_session_begin_transaction(session, null) == 0;
	}

	/// Commit current transaction.
	/// Return: true when the transaction was successfully committed, false otherwise.
	bool commitTransaction() {
		mg_result *result;
		return mg_session_commit_transaction(session, &result) == 0;
	}

	/// Rollback current transaction.
	/// Return: true when the transaction was successfully rollbacked, false otherwise.
	bool rollbackTransaction() {
		mg_result *result;
		return mg_session_rollback_transaction(session, &result) == 0;
	}

	/// Static method that creates a Memgraph client instance using default parameters localhost:7687
	/// Return: optional client connection instance.
	/// Returns an empty optional if the connection couldn't be established.
	static Optional!Client connect() {
		Params params;
		return connect(params);
	}

	/// Static method that creates a Memgraph client instance.
	/// Return: optional client connection instance.
	/// If the connection couldn't be established given the `params`, it returns
	/// an empty optional.
	static Optional!Client connect(const ref Params params) {
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

/// Connect example
unittest {
	// Connect to memgraph DB at localhost:7688
	auto client = Client.connect();
}

unittest {
	import testutils;
	import memgraph;

	auto client = connectContainer();
	assert(client);

	assert(client.sessionStatus == mg_session_code.MG_SESSION_READY);

	assert(client.sessionError() == "");

	assert(client.clientVersion.length > 0);
}

unittest {
	import testutils;
	import memgraph;

	auto client = connectContainer();
	assert(client);

	createTestIndex(client);

	deleteTestData(client);

	// Create some test data inside a transaction, then roll it back.
	client.beginTransaction();

	createTestData(client);

	// Inside the transaction the row count should be 1.
	assert(client.execute("MATCH (n) RETURN n;"));
	assert(client.fetchAll.length == 1);

	client.rollbackTransaction();

	// Outside the transaction the row count should be 0.
	assert(client.execute("MATCH (n) RETURN n;"), client.sessionError);
	assert(client.fetchAll.length == 0);


	// Create some test data inside a transaction, then commit it.
	client.beginTransaction();

	createTestData(client);

	// Inside the transaction the row count should be 1.
	assert(client.execute("MATCH (n) RETURN n;"));
	assert(client.fetchAll.length == 1);

	client.commitTransaction();

	// Outside the transaction the row count should still be 1.
	assert(client.execute("MATCH (n) RETURN n;"), client.sessionError);
	assert(client.fetchAll.length == 1);
}

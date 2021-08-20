/// Provides a connection for memgraph.
module memgraph.client;

import std.string : fromStringz, toStringz;

import memgraph.mgclient, memgraph.value, memgraph.map, memgraph.params, memgraph.result;

/// Provides a connection for memgraph.
struct Client {
	/// Disable copying.
	@disable this(this);

	/// Client software version.
	/// Return: Client version in the major.minor.patch format.
	static auto clientVersion() { return fromStringz(mg_client_version()); }

	/// Obtains the error message stored in the current session (if any).
	@property auto error() {
		assert(ptr_ != null);
		return fromStringz(mg_session_error(ptr_));
	}

	/// Returns the status of the current session.
	/// Return: One of the session codes in `mg_session_code`.
	@property auto status() inout {
		assert(ptr_ != null);
		return mg_session_status(ptr_);
	}

	/// Runs the given Cypher `statement` and discards any possible results.
	/// Return: true when the statement ran successfully, false otherwise.
	bool run(const string statement) {
		auto result = execute(statement);
		if (!result)
			return false;
		foreach (r; result) { }
		return true;
	}

	/// Executes the given Cypher `statement`.
	/// Return: `Result` that can be used as a range e.g. using foreach() to process all results.
	/// After executing the statement, the method is blocked until all incoming
	/// data (execution results) are handled, i.e. until the returned `Result` has been completely processed.
	Result execute(const string statement) {
		return execute(statement, Map(0));
	}

	/// Executes the given Cypher `statement`, supplied with additional `params`.
	/// Return: `Result` that can be used as a range e.g. using foreach() to process all results.
	/// After executing the statement, the method is blocked until all incoming
	/// data (execution results) are handled, i.e. until the returned `Result` has been completely processed.
	Result execute(const string statement, const Map params) {
		assert(ptr_ != null);
		int status = mg_session_run(ptr_, toStringz(statement), params.ptr, null, null, null);
		if (status < 0)
			return Result();
		status = mg_session_pull(ptr_, null);
		if (status < 0)
			return Result();
		return Result(ptr_);
	}

/*
	/// Fetches the next result from the input stream.
	/// Return next result from the input stream.
	/// If there is nothing to fetch, an empty array is returned.
	Value[] fetchOne() {
		// TODO: encapsulate mg_result as `Result`
		mg_result *result;
		Value[] values;
		immutable status = mg_session_fetch(session, &result);
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
	*/

	/// Start a transaction.
	/// Return: true when the transaction was successfully started, false otherwise.
	bool begin() {
		assert(ptr_ != null);
		return mg_session_begin_transaction(ptr_, null) == 0;
	}

	/// Commit current transaction.
	/// Return: true when the transaction was successfully committed, false otherwise.
	bool commit() {
		assert(ptr_ != null);
		mg_result *result;
		return mg_session_commit_transaction(ptr_, &result) == 0;
	}

	/// Rollback current transaction.
	/// Return: true when the transaction was successfully rolled back, false otherwise.
	bool rollback() {
		assert(ptr_ != null);
		mg_result *result;
		return mg_session_rollback_transaction(ptr_, &result) == 0;
	}

	/// Static method that creates a Memgraph client instance using default parameters localhost:7687
	/// Return: client connection instance.
	/// Returns an unconnected instance if the connection couldn't be established.
	static Client connect() {
		Params params;
		return connect(params);
	}

	/// Static method that creates a Memgraph client instance.
	/// Return: client connection instance.
	/// If the connection couldn't be established given the `params`, it will
	/// return an unconnected instance.
	static Client connect(ref Params params) {
		mg_session *session = null;
		immutable status = mg_connect(params.ptr, &session);
		if (status < 0) {
			if (session)
				mg_session_destroy(session);
			return Client();
		}
		return Client(session);
	}

	/// Assigns a client to another. The target of the assignment gets detached from
	/// whatever client it was attached to, and attaches itself to the new client.
	ref Client opAssign(ref Client rhs) @safe return {
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Create a copy of `other` client.
	this(ref Client other) {
		import std.algorithm.mutation : swap;
		swap(this, other);
	}

	/// Destroy the internal `mg_session`.
	@safe @nogc ~this() {
		if (ptr_)
			mg_session_destroy(ptr_);
	}

	/// Status of this client connection as boolean value.
	/// Returns: true = the client connection was established
	///          false = this client is not connected
	auto opCast(T : bool)() const {
		return ptr_ != null;
	}

package:
	/// Create a new instance using the given `mg_session` pointer.
	this(mg_session *session) {
		assert(session != null);
		ptr_ = session;
	}

private:
	mg_session *ptr_;
}

unittest {
	import std.exception, core.exception;
	import testutils;
	import memgraph;

	auto client = connectContainer();
	assert(client);

	assert(client.status == mg_session_code.MG_SESSION_READY);
	assert(client.clientVersion.length > 0);

	auto client2 = Client();
	client2 = client;
	assert(client2.status == mg_session_code.MG_SESSION_READY);
	assert(client2.clientVersion.length > 0);

	assertThrown!AssertError(client.status);
	assertThrown!AssertError(client.error);

	auto client3 = Client(client2);
	assert(client3.status == mg_session_code.MG_SESSION_READY);
	assert(client3.clientVersion.length > 0);

	assertThrown!AssertError(client2.status);
	assertThrown!AssertError(client2.error);
}

unittest {
	import testutils;
	import memgraph;

	auto client = connectContainer();
	assert(client);

	assert(client.status == mg_session_code.MG_SESSION_READY);

	// TODO: something weird is going on with error:
	//       with ldc2, the first character seems to be random garbage if there actually is no error
	//       and with dmd, the whole error message seems to retain it's last state, even after successful connect
	// assert(client.error() == "", client.error);

	assert(client.clientVersion.length > 0);
}

unittest {
	import testutils;
	import memgraph;
	import std.algorithm : count;

	auto client = connectContainer();
	assert(client);

	createTestIndex(client);

	deleteTestData(client);

	// Create some test data inside a transaction, then roll it back.
	client.begin();

	createTestData(client);

	// Inside the transaction the row count should be 1.
	auto result = client.execute("MATCH (n) RETURN n;");
	assert(result, client.error);
	assert(result.count == 5);

	client.rollback();

	// Outside the transaction the row count should be 0.
	result = client.execute("MATCH (n) RETURN n;");
	assert(result, client.error);
	assert(result.count == 0);

	// Create some test data inside a transaction, then commit it.
	client.begin();

	createTestData(client);

	// Inside the transaction the row count should be 1.
	result = client.execute("MATCH (n) RETURN n;");
	assert(result, client.error);
	assert(result.count == 5);

	client.commit();

	// Outside the transaction the row count should still be 1.
	result = client.execute("MATCH (n) RETURN n;");
	assert(result, client.error);
	assert(result.count == 5);

	// Just some test for execute() using Map parameters.
	auto m = Map(10);
	m["test"] = 42;
	result = client.execute("MATCH (n) RETURN n;", m);
	assert(result, client.error);
	assert(result.count == 5);

	// Just for coverage at the moment
	assert(client.error.length >= 0);
	assert(result.summary.length >= 0);
	assert(result.columns == ["n"]);
}

unittest {
	Params params;
	params.host = "0.0.0.0";
	params.port = 12_345;
	auto client = Client.connect(params);
	assert(!client);
}

unittest {
	import testutils;
	import memgraph;
	auto client = connectContainer();
	assert(client);
	assert(!client.run("WHAT IS THE ANSWER TO LIFE, THE UNIVERSE AND EVERYTHING?"));
	auto m = Map(10);
	m["answer"] = 42;
	assert(!client.execute("WHAT IS THE ANSWER TO LIFE, THE UNIVERSE AND EVERYTHING?", m));
}

/// Connect example
unittest {
	import std.stdio;
	import memgraph;
	// Connect to memgraph DB at localhost:7688
	Params p = { host: "localhost", port: 7688 };
	auto client = Client.connect(p);
	if (!client) writefln("cannot connect to %s:%s: %s", p.host, p.port, client.status);
}

unittest {
	// Just for coverage. It probably will fail - unless there happens
	// to be a memgraph server running at localhost:7687
	Client.connect();
}

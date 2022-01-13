/// Provides a connection for memgraph.
module memgraph.client;

import std.string : fromStringz, toStringz;

import memgraph.mgclient, memgraph.value, memgraph.params, memgraph.result;

/// Provides a connection for memgraph.
struct Client {
  /// Disable copying.
  @disable this(this);

  /// Client software version.
  /// Return: Client version in the major.minor.patch format.
  @nogc static auto clientVersion() { return fromStringz(mg_client_version()); }

  /// Obtains the error message stored in the current session (if any).
  @nogc @property auto error() {
    assert(session_ != null);
    return fromStringz(mg_session_error(session_));
  }

  /// Returns the status of the current session.
  /// Return: One of the session codes in `mg_session_code`.
  @nogc @property auto status() inout {
    assert(session_ != null);
    return mg_session_status(session_);
  }

  /// Runs the given Cypher `statement` and discards any possible results.
  /// Return: true when the statement ran successfully, false otherwise.
  bool run(const string statement) {
    auto result = execute(statement);
    if (!result)
      return false;
    foreach (r; result) {}
    return true;
  }

  /// Executes the given Cypher `statement`.
  /// Return: `Result` that can be used as a range e.g. using foreach() to process all results.
  /// After executing the statement, the method is blocked until all incoming
  /// data (execution results) are handled, i.e. until the returned `Result` has been completely processed.
  Result execute(const string statement) {
    string[string] emptyParams;
    return execute(statement, emptyParams);
  }

  /// Executes the given Cypher `statement`, supplied with additional `params`.
  /// Return: `Result` that can be used as a range e.g. using foreach() to process all results.
  /// After executing the statement, the method is blocked until all incoming
  /// data (execution results) are handled, i.e. until the returned `Result` has been completely processed.
  Result execute(const string statement, const string[string] params) {
    assert(status == mg_session_code.MG_SESSION_READY);
    mg_error status;
    if (params.length == 0)
      status = mg_session_run(session_, toStringz(statement), null, null, null, null);
    else {
      import std.conv : to;
      extraParams_ = mg_map_make_empty(to!uint(params.length));
      foreach (ref key, ref value; params) {
        mg_error rc;
        if (key == "n") // TODO: this needs a better solution
          rc = mg_map_insert(extraParams_, toStringz(key), mg_value_make_integer(to!int(value)));
        else
          rc = mg_map_insert(extraParams_, toStringz(key), mg_value_make_string(toStringz(value)));
        assert(rc == mg_error.MG_SUCCESS);
      }
      status = mg_session_run(session_, toStringz(statement), extraParams_, null, null, null);
    }
    if (status < 0)
      return Result();
    return Result(session_, &result_, extraParams_);
  }

  /// Start a transaction.
  /// Return: true when the transaction was successfully started, false otherwise.
  @nogc bool begin() {
    assert(session_ != null);
    return mg_session_begin_transaction(session_, null) == 0;
  }

  /// Commit current transaction.
  /// Return: true when the transaction was successfully committed, false otherwise.
  @nogc bool commit() {
    assert(session_ != null);
    return mg_session_commit_transaction(session_, &result_) == 0;
  }

  /// Rollback current transaction.
  /// Return: true when the transaction was successfully rolled back, false otherwise.
  @nogc bool rollback() {
    assert(session_ != null);
    return mg_session_rollback_transaction(session_, &result_) == 0;
  }

  /// Static method that creates a Memgraph client instance using default parameters 127.0.0.1:7687
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

  /// Destroy the internal `mg_session`.
  @nogc ~this() {
    if (session_)
      mg_session_destroy(session_);
    if (extraParams_)
      mg_map_destroy(extraParams_);
  }

  /// Status of this client connection as boolean value.
  /// Returns: true = the client connection was established
  ///          false = this client is not connected
  @nogc auto opCast(T : bool)() const { return session_ != null; }

package:
  /// Create a new instance using the given `mg_session` pointer.
  @nogc this(mg_session *session) {
    assert(session != null);
    session_ = session;
  }

  auto ptr() inout { return session_; }

private:
  mg_session *session_;
  mg_result *result_;
  mg_map *extraParams_;
}

unittest {
  import std.exception, core.exception;
  import testutils;

  const client = connectContainer();
  assert(client);

  assert(client.status == mg_session_code.MG_SESSION_READY);
  assert(client.clientVersion.length > 0);
  assert(client.ptr != null);
}

unittest {
  import testutils;

  auto client = connectContainer();
  assert(client);

  assert(client.status == mg_session_code.MG_SESSION_READY);
  assert(client.error() == "", client.error);
  assert(client.clientVersion.length > 0);
}

unittest {
  import testutils;
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

  // Just some test for execute() using extra parameters.
  string[string] params;
  params["mode"] = "r";
  result = client.execute("MATCH (n) RETURN n;", params);
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
  const client = Client.connect(params);
  assert(!client);
}

unittest {
  import testutils : connectContainer;
  auto client = connectContainer();
  assert(client);
  assert(!client.run("WHAT IS THE ANSWER TO LIFE, THE UNIVERSE AND EVERYTHING?"));
  string[string] params;
  params["mode"] = "r";
  assert(!client.execute("WHAT IS THE ANSWER TO LIFE, THE UNIVERSE AND EVERYTHING?", params));
}

/// Connect example
unittest {
  import std.stdio : writefln;
  // Connect to memgraph DB at 127.0.0.1:7688
  Params p = { host: "127.0.0.1", port: 7688 };
  auto client = Client.connect(p);
  if (!client) writefln("cannot connect to %s:%s: %s", p.host, p.port, client.status);
}

unittest {
  // Just for coverage. It probably will fail - unless there happens
  // to be a memgraph server running at 127.0.0.1:7687
  cast(void)Client.connect();
}

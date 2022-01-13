/// Provides single result row or query execution summary.
module memgraph.result;

import std.string, std.conv;

import memgraph.mgclient, memgraph.value, memgraph.map, memgraph.detail, memgraph.list;

/// An object encapsulating a single result row or query execution summary. It's
/// lifetime is limited by lifetime of parent `mg_session`. Also, invoking
/// `mg_session_pull` ends the lifetime of previously returned `mg_result`.
/// Implements an `InputRange`.
struct Result {

  /// Returns names of columns output by the current query execution.
  ref auto columns() {
    if (columns_.length == 0) {
      assert(*result_ != null);
      auto list = mg_result_columns(*result_);
      immutable length = mg_list_size(list);
      columns_.length = length;
      for (uint i = 0; i < length; ++i)
        columns_[i] = Detail.convertString(mg_value_string(mg_list_at(list, i)));
    }
    return columns_;
  }

  /// Returns query execution summary as a key/value `Map`.
  auto summary() {
    if (summary_.length == 0) {
      assert(*result_ != null);
      auto map = mg_result_summary(*result_);
      immutable length = mg_map_size(map);
      for (uint i = 0; i < length; i++) {
        immutable key = Detail.convertString(mg_map_key_at(map, i));
        summary_[key] = Value(mg_map_value_at(map, i)).toString;
      }
    }
    return summary_;
  }

  /// Pulls the next result.
  /// Return: mg_error.MG_SUCCESS on success, an `mg_error` code on failure.
  @nogc auto pull() {
    assert(session_ != null);
    assert(mg_session_status(session_) == mg_session_code.MG_SESSION_EXECUTING);
    return mg_session_pull(session_, extraParams_);
  }

  /// Fetches the next result after a successful pull().
  /// Return: mg_error.MG_SUCCESS on success, an `mg_error` code on failure.
  auto fetch() {
    assert(session_ != null);
    assert(mg_session_status(session_) == mg_session_code.MG_SESSION_FETCHING);

    immutable status = mg_session_fetch(session_, result_);
    assert(*result_ != null);
    if (status == 1) {
      // 1 - a new result row was obtained and stored in result_
      values_ ~= List(mg_result_row(*result_));
      return mg_error.MG_SUCCESS;
    } else if (status == 0) {
      // 0 - no more results, the summary was stored in result_
      auto sum = summary();
      if ("has_more" in sum)
        hasMore_ = to!bool(sum["has_more"]);
      return mg_error.MG_SUCCESS;
    }
    // Anything else is an error.
    return status;
  }

  /// Returns `true` if there are more results to be pulled from the server, `false` otherwise.
  // @nogc auto hasMore() const { return hasMore_; }

  /// Check if the `Result` is empty.
  /// Return: true if empty, false if there are more rows to be fetched.
  /// Note: part of `InputRange` interface
  @property bool empty() {
    do {
      hasMore_ = false;
      if (mg_session_status(session_) == mg_session_code.MG_SESSION_EXECUTING) {
        if (pull() != mg_error.MG_SUCCESS) return true;
      }
      if (mg_session_status(session_) == mg_session_code.MG_SESSION_FETCHING) {
        if (fetch() != mg_error.MG_SUCCESS) return true;
      }
    } while (hasMore_);
    return values_.length == 0;
  }

  /// Returns the front element of the range.
  /// Note: part of `InputRange` interface
  @nogc auto front() {
    assert(values_.length > 0);
    return values_[0];
  }

  /// Pops the first element from the range, shortening the range by one element.
  /// Note: part of `InputRange` interface
  @nogc @property void popFront() {
    values_ = values_[1..$];
  }

  /// Returns `true` if this result set is valid, `false` otherwise.
  @nogc auto opCast(T : bool)() const {
    return session_ != null;
  }

package:
  /// Initial construction of a `Result` from the given `mg_session` pointer.
  /// Ranges in D first perform a copy of the range object on which they will
  /// operate. This means that the original `Result` instance could not be
  /// used to e.g. query the summary since it does not have the last `mg_result`.
  /// Allocate a reference counted `mg_result` pointer to be shared with all
  /// future range copies.
  this(mg_session *session, mg_result **result, mg_map *extraParams) {
    assert(session != null);
    assert(result != null);
    session_ = session;
    result_ = result;
    extraParams_ = extraParams;
  }

private:
  /// Pointer to `mg_session` instance.
  mg_session *session_;
  /// Pointer to `mg_result` instance.
  mg_result **result_;
  /// Extra parameters to use during pull().
  mg_map *extraParams_;
  /// Temporary value store.
  List[] values_;
  /// Flag that shows if there are more results pending to be pulled.
  bool hasMore_;
  /// Memoise result column names.
  string[] columns_;
  /// Memoise result execution summary.
  string[string] summary_;
} // struct Result

unittest {
  import std.range.primitives : isInputRange;
  assert(isInputRange!Result);
}

unittest {
  import testutils;
  import memgraph : Node, Type;

  auto client = connectContainer();
  assert(client);

  assert(client.run("CREATE INDEX ON :Person(id);"), client.error);

  assert(client.run("MATCH (n) DETACH DELETE n;"), client.error);

  foreach (id; 0..100)
    assert(client.run("CREATE (:Person {id: " ~ to!string(id) ~ "});"), client.error);

  auto result = client.execute("MATCH (n) RETURN n;", [ "n": "10" ]);
  assert(result, client.error);

  auto count = 0;
  foreach (ref r; result) {
    assert(r[0].type == Type.Node);
    auto n = to!Node(r[0]);
    assert(n.properties["id"] == count);
    count++;
  }
  assert(count == 100);
}

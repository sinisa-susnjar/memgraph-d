/// Provides single result row or query execution summary.
module memgraph.result;

import std.string, std.conv;

import memgraph.mgclient, memgraph.value, memgraph.map, memgraph.detail;

/// An object encapsulating a single result row or query execution summary. It's
/// lifetime is limited by lifetime of parent `mg_session`. Also, invoking
/// `mg_session_pull` ends the lifetime of previously returned `mg_result`.
/// Implements an `InputRange`.
struct Result {
  /// Returns names of columns output by the current query execution.
  auto columns() inout {
    assert(ptr_ != null);
    assert(*ptr_ != null);
    const (mg_list) *list = mg_result_columns(*ptr_);
    const size_t list_length = mg_list_size(list);
    string[] cols;
    cols.length = list_length;
    for (uint i = 0; i < list_length; ++i)
      cols[i] = Detail.convertString(mg_value_string(mg_list_at(list, i)));
    return cols;
  }

  /// Returns query execution summary as a key/value `Map`.
  auto summary() inout {
    assert(ptr_ != null);
    assert(*ptr_ != null);
    return Map(mg_result_summary(*ptr_));
  }

  /// Check if the `Result` is empty.
  /// Return: true if empty, false if there are more rows to be fetched.
  /// Note: part of `InputRange` interface
  @property bool empty() {
    if (values_.length == 0) {
      assert(ptr_ != null);
      immutable status = mg_session_fetch(session_, ptr_);
      if (status != 1)
        return true;
      const (mg_list) *list = mg_result_row(*ptr_);
      const size_t list_length = mg_list_size(list);
      Value[] data;
      data.length = list_length;
      for (uint i = 0; i < list_length; ++i)
        data[i] = Value(mg_list_at(list, i));
      values_ ~= data;
    }
    return values_.length == 0;
  }
  /// Returns the front element of the range.
  /// Note: part of `InputRange` interface
  auto front() {
    assert(values_.length > 0);
    return values_[0];
  }
  /// Pops the first element from the range, shortening the range by one element.
  /// Note: part of `InputRange` interface
  @property void popFront() {
    values_ = values_[1..$];
  }

  ~this() {
    import core.stdc.stdlib : free;
    refs_--;
    if (ptr_ && refs_ == 0)
      free(ptr_);
  }

  this(this) {
    refs_++;
  }

  auto opCast(T : bool)() const {
    return ptr_ != null;
  }

package:
  /// Initial construction of a `Result` from the given `mg_session` pointer.
  /// Ranges in D first perform a copy of the range object on which they will
  /// operate. This means that the original `Result` instance could not be
  /// used to e.g. query the summary since it does not have the last `mg_result`.
  /// Allocate a reference counted `mg_result` pointer to be shared with all
  /// future range copies.
  this(mg_session *session) {
    assert(session != null);
    import core.stdc.stdlib : malloc;
    session_ = session;
    ptr_ = cast(mg_result **)malloc((mg_result *).sizeof);
  }

private:
  /// Pointer to private `mg_session` instance.
  mg_session *session_;
  /// Pointer to private `mg_result` instance.
  mg_result **ptr_;
  /// Temporary value store.
  Value[][] values_;
  /// Reference count.
  uint refs_ = 1;
}

unittest {
  import std.range.primitives : isInputRange;
  assert(isInputRange!Result);
}

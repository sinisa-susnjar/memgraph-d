/// Provides single result row or query execution summary.
module memgraph.result;

import std.string, std.conv;

import memgraph.mgclient, memgraph.value, memgraph.map, memgraph.optional, memgraph.detail;

/// An object encapsulating a single result row or query execution summary. It's
/// lifetime is limited by lifetime of parent `mg_session`. Also, invoking
/// `mg_session_pull` ends the lifetime of previously returned `mg_result`.
/// Implements an `InputRange`.
struct Result {
	/// Returns names of columns output by the current query execution.
	auto columns() {
		assert(result != null);
		const (mg_list) *list = mg_result_columns(*result);
		const size_t list_length = mg_list_size(list);
		string[] cols;
		cols.length = list_length;
		for (uint i = 0; i < list_length; ++i)
			cols[i] = Detail.convertString(mg_value_string(mg_list_at(list, i)));
		return cols;
	}

	/// Returns query execution summary as a key/value `Map`.
	auto summary() {
		assert(result != null);
		if (*result != null)
			return Map(mg_result_summary(*result));
		return Map();
	}

	/// Check if the `Result` is empty.
	/// Return: true if empty, false if there are more rows to be fetched.
	/// Note: part of `InputRange` interface
	bool empty() {
		if (values.length == 0) {
			assert(result != null);
			immutable status = mg_session_fetch(session, result);
			if (status != 1)
				return true;
			const (mg_list) *list = mg_result_row(*result);
			const size_t list_length = mg_list_size(list);
			Value[] data;
			data.length = list_length;
			for (uint i = 0; i < list_length; ++i)
				data[i] = Value(mg_list_at(list, i));
			values ~= data;
		}
		return values.length == 0;
	}
	/// Returns the front element of the range.
	/// Note: part of `InputRange` interface
	auto front() {
		assert(values.length > 0);
		return values[0];
	}
	/// Pops the first element from the range, shortening the range by one element.
	/// Note: part of `InputRange` interface
	void popFront() {
		values = values[1..$];
	}

	/// Postblit constructor. Increases `mg_result` reference count for each copy made.
	this(this) {
		// Increase reference count for result pointer.
		n++;
	}

	/// Destructor, counts down `mg_result` reference count and frees memory if count goes to zero.
	~this() {
		// One `Result` instance gone, reduce reference count.
		if (!--n) {
			// Ref count is 0 - this means the original `Result` instance is being destructed,
			// the `mg_result` pointer is not needed anymore, free it.
			import core.stdc.stdlib : free;
			if (result != null)
				free(result);
			result = null;
		}
	}

package:
	/// Initial construction of a `Result` from the given `mg_session` pointer.
	/// Ranges in D first perform a copy of the range object on which they will
	/// operate. This means that the original `Result` instance could not be
	/// used to e.g. query the summary since it does not have the last `mg_result`.
	/// Allocate a reference counted `mg_result` pointer to be shared with all
	/// future range copies.
	this(mg_session *session) {
		import core.stdc.stdlib : malloc;
		this.session = session;
		result = cast(mg_result **)malloc((mg_result *).sizeof);
		assert(result != null);
	}

private:
	/// Pointer to private `mg_session` instance.
	mg_session *session;
	/// Pointer to private `mg_result` instance.
	mg_result **result;
	/// Reference count for `mg_result` pointer. Needed for ranges.
	size_t n = 1;
	/// Temporary value store.
	Value[][] values;
}

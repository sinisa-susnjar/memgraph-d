/// Provides single result row or query execution summary.
module memgraph.result;

import std.string, std.conv, std.stdio;

import memgraph.mgclient, memgraph.value, memgraph.map, memgraph.optional;

/// An object encapsulating a single result row or query execution summary. It's
/// lifetime is limited by lifetime of parent `mg_session`. Also, invoking
/// `mg_session_pull` ends the lifetime of previously returned `mg_result`.
struct Result {
	/// Returns names of columns output by the current query execution.
	// MGCLIENT_EXPORT const mg_list *mg_result_columns(const mg_result *result);

	/// Returns column values of current result row.
	// MGCLIENT_EXPORT const mg_list *mg_result_row(const mg_result *result);

	/// Returns query execution summary.
	auto summary() {
		// writefln("summary[%s]: result_: %s", &this, *result_);
		assert(result_ != null);
		if (*result_ != null)
			return Map(mg_result_summary(*result_));
		return Map();
	}

	bool empty() {
		// writefln("empty: result_: %s", *result_);
		if (values_.length == 0)
			fetchNext();
		return values_.length == 0;
	}
	auto front() {
		// writefln("front: result_: %s", *result_);
		assert(values_.length > 0);
		return values_[0];
	}
	void popFront() {
		// writefln("popFront: result_: %s", *result_);
		values_ = values_[1..$];
	}

	/*
	this(ref inout Result other) inout {
		writefln("result copy ctor: this: %s other: %s", &this, &other);
		result_ = other.result_;
		session_ = other.session_;
	}
	*/

	this(this) {
		// Increase reference count for result_ pointer.
		ref_++;
	}

	~this() {
		// One `Result` instance gone, reduce reference count.
		if (!--ref_) {
			// Ref count is 0 - this means the original `Result` instance is being destructed,
			// the `mg_result` pointer is not needed anymore, free it.
			import core.stdc.stdlib : free;
			if (result_ != null)
				free(result_);
			result_ = null;
		}
	}

package:

	this(mg_session *session) {
		// Initial construction of a `Result` from the given `mg_session` pointer.
		// Ranges in D first perform a copy of the range object on which they will
		// operate. This means that the original `Result` instance could not be
		// used to e.g. query the summary since it does not have the last `mg_result`.
		// Allocate a reference counted `mg_result` pointer to be shared with all
		// future range copies.
		import core.stdc.stdlib : malloc;
		session_ = session;
		result_ = cast(mg_result **)malloc((mg_result *).sizeof);
		assert(result_ != null);
	}

private:

	auto fetchNext() {
		assert(result_ != null);
		immutable status = mg_session_fetch(session_, result_);
		if (status != 1) {
			// writefln("fetchNext[%s]: status: %s result: %s", &this, status, *result_);
			return false;
		}

		const (mg_list) *list = mg_result_row(*result_);
		const size_t list_length = mg_list_size(list);

		values_.length = list_length;
		for (uint i = 0; i < list_length; ++i)
			values_[i] = Value(mg_list_at(list, i));

		return true;
	}

	/// Pointer to private `mg_session` instance.
	mg_session *session_;
	/// Pointer to private `mg_result` instance.
	mg_result **result_;
	/// Reference count for `mg_result` pointer. Needed for ranges.
	size_t ref_ = 1;
	Value[] values_;
}

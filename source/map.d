/// Provides a map (i.e. key/value) tuple.
module map;

import std.typecons, std.string;

import mgclient, detail, value;

/// Wrapper class for \ref mg_map.
struct Map {
	alias KeyValuePair = Tuple!(string, "key", Value, "value");

	// CREATE_ITERATOR(Map, KeyValuePair);

	this(mg_map *ptr) { ptr_ = ptr; }

	/// Create a Map from a copy of the given \ref mg_map.
	this(const mg_map *const_ptr) { this(mg_map_copy(const_ptr)); }

	/// Copy constructor.
	this(const ref Map other) { this(mg_map_copy(other.ptr_)); }

	// Map(Map &&other);
	// Map &operator=(const Map &other) = delete;
	// Map &operator=(Map &&other) = delete;
	~this() {
		if (ptr_ != null)
			mg_map_destroy(ptr_);
	}

	/// Copies content of the given `map`.
	// explicit Map(const ConstMap &map);

	/// Constructs an empty Map that can hold at most \p capacity key-value pairs.
	/// Key-value pairs should be constructed and then inserted using
	/// \ref Insert, \ref InsertUnsafe and similar.
	///
	/// Param: capacity The maximum number of key-value pairs that the newly
	///                 constructed Map can hold.
	this(uint capacity) { this(mg_map_make_empty(capacity)); }

	/// Constructs an map from the list of key-value pairs.
	/// Values are copied.
	// Map(std::initializer_list<std::pair<std::string, Value>> list);

	size_t size() const { return mg_map_size(ptr_); }

	// bool empty() const { return size() == 0; }

	/// Returns the value associated with the given `key`.
	/// Behaves undefined if there is no such a value.
	/// Each key-value pair has to be checked, resulting with
	/// O(n) time complexity.
	const Value opIndex(const ref string key) {
  		return Value(mg_map_at(ptr_, toStringz(key)));
	}

	// Iterator begin() const { return Iterator(this, 0); }
	// Iterator end() const { return Iterator(this, size()); }

	/// \brief Returns the key-value iterator for the given `key`.
	/// In the case there is no such pair, `end` iterator is returned.
	/// \note
	/// Each key-value pair has to be checked, resulting with O(n) time
	/// complexity.
	// Iterator find(const std::string_view key) const;

	/// \brief Inserts the given `key`-`value` pair into the map.
	/// Checks if the given `key` already exists by iterating over all entries.
	/// Copies both the `key` and the `value`.
	// bool Insert(const std::string_view key, const Value &value);

	/// \brief Inserts the given `key`-`value` pair into the map.
	/// Checks if the given `key` already exists by iterating over all entries.
	/// Copies both the `key` and the `value`.
	// bool Insert(const std::string_view key, const ConstValue &value);

	/// \brief Inserts the given `key`-`value` pair into the map.
	/// Checks if the given `key` already exists by iterating over all entries.
	/// Copies the `key` and takes the ownership of `value` by moving it.
	/// Behaviour of accessing the `value` after performing this operation is
	/// considered undefined.
	// bool Insert(const std::string_view key, Value &&value);

	/// \brief Inserts the given `key`-`value` pair into the map.
	/// It doesn't check if the given `key` already exists in the map.
	/// Copies both the `key` and the `value`.
	// bool InsertUnsafe(const std::string_view key, const Value &value);

	/// \brief Inserts the given `key`-`value` pair into the map.
	/// It doesn't check if the  given `key` already exists in the map.
	/// Copies both the `key` and the `value`.
	// bool InsertUnsafe(const std::string_view key, const ConstValue &value);

	/// \brief Inserts the given `key`-`value` pair into the map.
	/// It doesn't check if the given `key` already exists in the map.
	/// Copies the `key` and takes the ownership of `value` by moving it.
	/// Behaviour of accessing the `value` after performing this operation
	/// is considered undefined.
	// bool InsertUnsafe(const std::string_view key, Value &&value);

	// const ConstMap AsConstMap() const;

	bool opEquals(const ref Map other) const {
		return Detail.AreMapsEqual(ptr_, other.ptr_);
	}

	// const mg_map *ptr() const { return ptr_; }

	bool empty() const {
		return idx_ >= size();
	}

	KeyValuePair front() const {
		assert(idx_ < size());
		auto key = Detail.ConvertString(mg_map_key_at(ptr_, idx_));
		auto value = Value(mg_map_value_at(ptr_, idx_));
		return KeyValuePair(key, value);
	}

	void popFront() {
		idx_++;
	}

	auto ptr() const { return ptr_; }

private:
	mg_map *ptr_;
	uint idx_;
}

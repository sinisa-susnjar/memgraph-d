module memgraph;

public import mgclient;

import std.string, std.conv;
import std.typecons : Tuple;
import std.exception, std.conv;
import std.stdio;

struct Detail {
	static string ConvertString(const mg_string *str) {
		const auto data = mg_string_data(str);
		const auto len = mg_string_size(str);
		return to!string(data[0..len]);
	}

	static Value.Type ConvertType(mg_value_type type) {
		switch (type) {
			case mg_value_type.MG_VALUE_TYPE_NULL:
				return Value.Type.Null;
			case mg_value_type.MG_VALUE_TYPE_BOOL:
				return Value.Type.Bool;
			case mg_value_type.MG_VALUE_TYPE_INTEGER:
				return Value.Type.Int;
			case mg_value_type.MG_VALUE_TYPE_FLOAT:
				return Value.Type.Double;
			case mg_value_type.MG_VALUE_TYPE_STRING:
				return Value.Type.String;
			case mg_value_type.MG_VALUE_TYPE_LIST:
				return Value.Type.List;
			case mg_value_type.MG_VALUE_TYPE_MAP:
				return Value.Type.Map;
			case mg_value_type.MG_VALUE_TYPE_NODE:
				return Value.Type.Node;
			case mg_value_type.MG_VALUE_TYPE_RELATIONSHIP:
				return Value.Type.Relationship;
			case mg_value_type.MG_VALUE_TYPE_UNBOUND_RELATIONSHIP:
				return Value.Type.UnboundRelationship;
			case mg_value_type.MG_VALUE_TYPE_PATH:
				return Value.Type.Path;
			case mg_value_type.MG_VALUE_TYPE_DATE:
				return Value.Type.Date;
			case mg_value_type.MG_VALUE_TYPE_TIME:
				return Value.Type.Time;
			case mg_value_type.MG_VALUE_TYPE_LOCAL_TIME:
				return Value.Type.LocalTime;
			case mg_value_type.MG_VALUE_TYPE_DATE_TIME:
				return Value.Type.DateTime;
			case mg_value_type.MG_VALUE_TYPE_DATE_TIME_ZONE_ID:
				return Value.Type.DateTimeZoneId;
			case mg_value_type.MG_VALUE_TYPE_LOCAL_DATE_TIME:
				return Value.Type.LocalDateTime;
			case mg_value_type.MG_VALUE_TYPE_DURATION:
				return Value.Type.Duration;
			case mg_value_type.MG_VALUE_TYPE_POINT_2D:
				return Value.Type.Point2d;
			case mg_value_type.MG_VALUE_TYPE_POINT_3D:
				return Value.Type.Point3d;
			case mg_value_type.MG_VALUE_TYPE_UNKNOWN:
				throw new Exception("Unknown value type!");
			default:
				assert(0, "unexpected type: " ~ to!string(type));
		}
	}

	static bool AreValuesEqual(const mg_value *value1, const mg_value *value2) {
		if (value1 == value2) {
			return true;
		}
		if (mg_value_get_type(value1) != mg_value_get_type(value2)) {
			return false;
		}
		switch (mg_value_get_type(value1)) {
			case mg_value_type.MG_VALUE_TYPE_NULL:
				return true;
			case mg_value_type.MG_VALUE_TYPE_BOOL:
				return mg_value_bool(value1) == mg_value_bool(value2);
			case mg_value_type.MG_VALUE_TYPE_INTEGER:
				return mg_value_integer(value1) == mg_value_integer(value2);
			case mg_value_type.MG_VALUE_TYPE_FLOAT:
				return mg_value_float(value1) == mg_value_float(value2);
			case mg_value_type.MG_VALUE_TYPE_STRING:
				return Detail.ConvertString(mg_value_string(value1)) ==
					Detail.ConvertString(mg_value_string(value2));
			case mg_value_type.MG_VALUE_TYPE_LIST:
				return Detail.AreListsEqual(mg_value_list(value1),
						mg_value_list(value2));
			case mg_value_type.MG_VALUE_TYPE_MAP:
				return Detail.AreMapsEqual(mg_value_map(value1), mg_value_map(value2));
			case mg_value_type.MG_VALUE_TYPE_NODE:
				return Detail.AreNodesEqual(mg_value_node(value1),
						mg_value_node(value2));
			case mg_value_type.MG_VALUE_TYPE_RELATIONSHIP:
				return Detail.AreRelationshipsEqual(mg_value_relationship(value1),
						mg_value_relationship(value2));
			case mg_value_type.MG_VALUE_TYPE_UNBOUND_RELATIONSHIP:
				return Detail.AreUnboundRelationshipsEqual(
						mg_value_unbound_relationship(value1),
						mg_value_unbound_relationship(value2));
			case mg_value_type.MG_VALUE_TYPE_PATH:
				return Detail.ArePathsEqual(mg_value_path(value1),
						mg_value_path(value2));
			case mg_value_type.MG_VALUE_TYPE_DATE:
				return Detail.AreDatesEqual(mg_value_date(value1),
						mg_value_date(value2));
			case mg_value_type.MG_VALUE_TYPE_TIME:
				return Detail.AreTimesEqual(mg_value_time(value1),
						mg_value_time(value2));
			case mg_value_type.MG_VALUE_TYPE_LOCAL_TIME:
				return Detail.AreLocalTimesEqual(mg_value_local_time(value1),
						mg_value_local_time(value2));
			case mg_value_type.MG_VALUE_TYPE_DATE_TIME:
				return Detail.AreDateTimesEqual(mg_value_date_time(value1),
						mg_value_date_time(value2));
			case mg_value_type.MG_VALUE_TYPE_DATE_TIME_ZONE_ID:
				return Detail.AreDateTimeZoneIdsEqual(
						mg_value_date_time_zone_id(value1),
						mg_value_date_time_zone_id(value2));
			case mg_value_type.MG_VALUE_TYPE_LOCAL_DATE_TIME:
				return Detail.AreLocalDateTimesEqual(mg_value_local_date_time(value1),
						mg_value_local_date_time(value2));
			case mg_value_type.MG_VALUE_TYPE_DURATION:
				return Detail.AreDurationsEqual(mg_value_duration(value1),
						mg_value_duration(value2));
			case mg_value_type.MG_VALUE_TYPE_POINT_2D:
				return Detail.ArePoint2dsEqual(mg_value_point_2d(value1),
						mg_value_point_2d(value2));
			case mg_value_type.MG_VALUE_TYPE_POINT_3D:
				return Detail.ArePoint3dsEqual(mg_value_point_3d(value1),
						mg_value_point_3d(value2));
			case mg_value_type.MG_VALUE_TYPE_UNKNOWN:
				throw new Exception("Comparing values of unknown types!");
			default: assert(0, "unexpected type: " ~ to!string(mg_value_get_type(value1)));
		}
	}

	static bool AreListsEqual(const mg_list *list1, const mg_list *list2) {
		if (list1 == list2) {
			return true;
		}
		if (mg_list_size(list1) != mg_list_size(list2)) {
			return false;
		}
		const uint len = mg_list_size(list1);
		for (uint i = 0; i < len; ++i) {
			if (!Detail.AreValuesEqual(mg_list_at(list1, i), mg_list_at(list2, i))) {
				return false;
			}
		}
		return true;
	}

	static bool AreMapsEqual(const mg_map *map1, const mg_map *map2) {
		if (map1 == map2) {
			return true;
		}
		if (mg_map_size(map1) != mg_map_size(map2)) {
			return false;
		}
		const uint len = mg_map_size(map1);
		for (uint i = 0; i < len; ++i) {
			const mg_string *key = mg_map_key_at(map1, i);
			const mg_value *value1 = mg_map_value_at(map1, i);
			const mg_value *value2 =
				mg_map_at2(map2, mg_string_size(key), mg_string_data(key));
			if (value2 == null) {
				return false;
			}
			if (!Detail.AreValuesEqual(value1, value2)) {
				return false;
			}
		}
		return true;
	}

	static bool AreNodesEqual(const mg_node *node1, const mg_node *node2) {
		if (node1 == node2) {
			return true;
		}
		if (mg_node_id(node1) != mg_node_id(node2)) {
			return false;
		}
		if (mg_node_label_count(node1) != mg_node_label_count(node2)) {
			return false;
		}
		string[] labels1;
		string[] labels2;
		const uint label_count = mg_node_label_count(node1);
		labels1.length = labels2.length = label_count;
		for (uint i = 0; i < label_count; ++i) {
			labels1[i] = Detail.ConvertString(mg_node_label_at(node1, i));
			labels2[i] = Detail.ConvertString(mg_node_label_at(node2, i));
		}
		if (labels1 != labels2) {
			return false;
		}
		return Detail.AreMapsEqual(mg_node_properties(node1),
				mg_node_properties(node2));
	}

	static bool AreRelationshipsEqual(const mg_relationship *rel1,
			const mg_relationship *rel2) {
		if (rel1 == rel2) {
			return true;
		}
		if (mg_relationship_id(rel1) != mg_relationship_id(rel2)) {
			return false;
		}
		if (mg_relationship_start_id(rel1) != mg_relationship_start_id(rel2)) {
			return false;
		}
		if (mg_relationship_end_id(rel1) != mg_relationship_end_id(rel2)) {
			return false;
		}
		if (Detail.ConvertString(mg_relationship_type(rel1)) !=
				Detail.ConvertString(mg_relationship_type(rel2))) {
			return false;
		}
		return Detail.AreMapsEqual(mg_relationship_properties(rel1),
				mg_relationship_properties(rel2));
	}

	static bool AreUnboundRelationshipsEqual(const mg_unbound_relationship *rel1,
			const mg_unbound_relationship *rel2) {
		if (rel1 == rel2) {
			return true;
		}
		if (mg_unbound_relationship_id(rel1) != mg_unbound_relationship_id(rel2)) {
			return false;
		}
		if (Detail.ConvertString(mg_unbound_relationship_type(rel1)) !=
				Detail.ConvertString(mg_unbound_relationship_type(rel2))) {
			return false;
		}
		return Detail.AreMapsEqual(mg_unbound_relationship_properties(rel1),
				mg_unbound_relationship_properties(rel2));
	}

	static bool ArePathsEqual(const mg_path *path1, const mg_path *path2) {
		if (path1 == path2) {
			return true;
		}
		if (mg_path_length(path1) != mg_path_length(path2)) {
			return false;
		}
		const uint len = mg_path_length(path1);
		for (uint i = 0; i < len; ++i) {
			if (!Detail.AreNodesEqual(mg_path_node_at(path1, i),
						mg_path_node_at(path2, i))) {
				return false;
			}
			if (!Detail.AreUnboundRelationshipsEqual(
						mg_path_relationship_at(path1, i),
						mg_path_relationship_at(path2, i))) {
				return false;
			}
			if (mg_path_relationship_reversed_at(path1, i) !=
					mg_path_relationship_reversed_at(path2, i)) {
				return false;
			}
		}
		return Detail.AreNodesEqual(mg_path_node_at(path1, len),
				mg_path_node_at(path2, len));
	}

	static bool AreDatesEqual(const mg_date *date1, const mg_date *date2) {
		return mg_date_days(date1) == mg_date_days(date2);
	}

	static bool AreTimesEqual(const mg_time *time1, const mg_time *time2) {
		return mg_time_nanoseconds(time1) == mg_time_nanoseconds(time2) &&
			mg_time_tz_offset_seconds(time1) == mg_time_tz_offset_seconds(time2);
	}

	static bool AreLocalTimesEqual(const mg_local_time *local_time1,
			const mg_local_time *local_time2) {
		return mg_local_time_nanoseconds(local_time1) ==
			mg_local_time_nanoseconds(local_time2);
	}

	static bool AreDateTimesEqual(const mg_date_time *date_time1,
			const mg_date_time *date_time2) {
		return mg_date_time_seconds(date_time1) == mg_date_time_seconds(date_time2) &&
			mg_date_time_nanoseconds(date_time1) ==
			mg_date_time_nanoseconds(date_time2) &&
			mg_date_time_tz_offset_minutes(date_time1) ==
			mg_date_time_tz_offset_minutes(date_time2);
	}

	static bool AreDateTimeZoneIdsEqual(
			const mg_date_time_zone_id *date_time_zone_id1,
			const mg_date_time_zone_id *date_time_zone_id2) {
		return mg_date_time_zone_id_seconds(date_time_zone_id1) ==
			mg_date_time_zone_id_nanoseconds(date_time_zone_id2) &&
			mg_date_time_zone_id_nanoseconds(date_time_zone_id1) ==
			mg_date_time_zone_id_nanoseconds(date_time_zone_id2) &&
			mg_date_time_zone_id_tz_id(date_time_zone_id1) ==
			mg_date_time_zone_id_tz_id(date_time_zone_id2);
	}

	static bool AreLocalDateTimesEqual(const mg_local_date_time *local_date_time1,
			const mg_local_date_time *local_date_time2) {
		return mg_local_date_time_seconds(local_date_time1) ==
			mg_local_date_time_nanoseconds(local_date_time2) &&
			mg_local_date_time_nanoseconds(local_date_time1) ==
			mg_local_date_time_nanoseconds(local_date_time2);
	}

	static bool AreDurationsEqual(const mg_duration *duration1,
			const mg_duration *duration2) {
		return mg_duration_months(duration1) == mg_duration_months(duration2) &&
			mg_duration_days(duration1) == mg_duration_days(duration2) &&
			mg_duration_seconds(duration1) == mg_duration_seconds(duration2) &&
			mg_duration_nanoseconds(duration1) ==
			mg_duration_nanoseconds(duration2);
	}

	static bool ArePoint2dsEqual(const mg_point_2d *point_2d1,
			const mg_point_2d *point_2d2) {
		return mg_point_2d_srid(point_2d1) == mg_point_2d_srid(point_2d2) &&
			mg_point_2d_x(point_2d1) == mg_point_2d_x(point_2d2) &&
			mg_point_2d_y(point_2d1) == mg_point_2d_y(point_2d2);
	}

	static bool ArePoint3dsEqual(const mg_point_3d *point_3d1,
			const mg_point_3d *point_3d2) {
		return mg_point_3d_srid(point_3d1) == mg_point_3d_srid(point_3d2) &&
			mg_point_3d_x(point_3d1) == mg_point_3d_x(point_3d2) &&
			mg_point_3d_y(point_3d1) == mg_point_3d_y(point_3d2) &&
			mg_point_3d_z(point_3d1) == mg_point_3d_z(point_3d2);
	}

}

/// \brief Wrapper class for \ref mg_map.
struct Map {
	alias KeyValuePair = Tuple!(string, "key", Value, "value");

	// CREATE_ITERATOR(Map, KeyValuePair);

	this(mg_map *ptr) { ptr_ = ptr; }

	/// \brief Create a Map from a copy of the given \ref mg_map.
	this(const mg_map *const_ptr) { this(mg_map_copy(const_ptr)); }

	// Map(const Map &other);
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

	/// \brief Constructs an empty Map that can hold at most \p capacity key-value
	/// pairs.
	///
	/// Key-value pairs should be constructed and then inserted using
	/// \ref Insert, \ref InsertUnsafe and similar.
	///
	/// \param capacity The maximum number of key-value pairs that the newly
	///                 constructed Map can hold.
	this(uint capacity) { this(mg_map_make_empty(capacity)); }

	/// \brief Constructs an map from the list of key-value pairs.
	/// Values are copied.
	// Map(std::initializer_list<std::pair<std::string, Value>> list);

	size_t size() const { return mg_map_size(ptr_); }

	// bool empty() const { return size() == 0; }

	/// \brief Returns the value associated with the given `key`.
	/// Behaves undefined if there is no such a value.
	/// \note
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

private:
	mg_map *ptr_;
	uint idx_;
};


/*
inline std::pair<std::string_view, ConstValue> Map::Iterator::operator*()
    const {
  return std::make_pair(
      detail::ConvertString(mg_map_key_at(iterable_->ptr(), index_)),
      ConstValue(mg_map_value_at(iterable_->ptr(), index_)));
}
*/

// inline Map::Map(Map &&other) : Map(other.ptr_) { other.ptr_ = nullptr; }

// inline Map::Map(const ConstMap &map) : ptr_(mg_map_copy(map.ptr())) {}

/*
inline Map::Map(std::initializer_list<std::pair<std::string, Value>> list)
    : Map(list.size()) {
  for (const auto &[key, value] : list) {
    Insert(key, value.AsConstValue());
  }
}
*/

/*
inline Map::Iterator Map::find(const std::string_view key) const {
  for (size_t i = 0; i < size(); ++i) {
    if (key == detail::ConvertString(mg_map_key_at(ptr_, i))) {
      return Iterator(this, i);
    }
  }
  return end();
}
*/

/*
inline bool Map::Insert(const std::string_view key, const Value &value) {
  return mg_map_insert2(ptr_, mg_string_make2(key.size(), key.data()),
                        mg_value_copy(value.ptr())) == 0;
}

inline bool Map::Insert(const std::string_view key, const ConstValue &value) {
  return mg_map_insert2(ptr_, mg_string_make2(key.size(), key.data()),
                        mg_value_copy(value.ptr())) == 0;
}

inline bool Map::Insert(const std::string_view key, Value &&value) {
  bool result = mg_map_insert2(ptr_, mg_string_make2(key.size(), key.data()),
                               value.ptr_) == 0;
  value.ptr_ = nullptr;
  return result;
}

inline bool Map::InsertUnsafe(const std::string_view key, const Value &value) {
  return mg_map_insert_unsafe2(ptr_, mg_string_make2(key.size(), key.data()),
                               mg_value_copy(value.ptr())) == 0;
}

inline bool Map::InsertUnsafe(const std::string_view key,
                              const ConstValue &value) {
  return mg_map_insert_unsafe2(ptr_, mg_string_make2(key.size(), key.data()),
                               mg_value_copy(value.ptr())) == 0;
}

inline bool Map::InsertUnsafe(const std::string_view key, Value &&value) {
  bool result =
      mg_map_insert_unsafe2(ptr_, mg_string_make2(key.size(), key.data()),
                            value.ptr_) == 0;
  value.ptr_ = nullptr;
  return result;
}

inline const ConstMap Map::AsConstMap() const { return ConstMap(ptr_); }
*/

/*
inline std::pair<std::string_view, ConstValue> ConstMap::Iterator::operator*()
    const {
  return std::make_pair(
      detail::ConvertString(mg_map_key_at(iterable_->ptr(), index_)),
      ConstValue(mg_map_value_at(iterable_->ptr(), index_)));
}

inline ConstValue ConstMap::operator[](const std::string_view key) const {
  return ConstValue(mg_map_at2(const_ptr_, key.size(), key.data()));
}

inline ConstMap::Iterator ConstMap::find(const std::string_view key) const {
  for (size_t i = 0; i < size(); ++i) {
    if (key == detail::ConvertString(mg_map_key_at(const_ptr_, i))) {
      return Iterator(this, i);
    }
  }
  return end();
}

inline bool ConstMap::operator==(const ConstMap &other) const {
  return detail::AreMapsEqual(const_ptr_, other.const_ptr_);
}

inline bool ConstMap::operator==(const Map &other) const {
  return detail::AreMapsEqual(const_ptr_, other.ptr());
}
*/

/// \brief Wrapper class for \ref mg_node
struct Node {
	/// \brief View of the node's labels
	struct Labels {
		// CREATE_ITERATOR(Labels, std::string_view);

		this(const mg_node *node) { node_ = node; }

		size_t size() const { return mg_node_label_count(node_); }

		/// \brief Return node's label at the `index` position.
		// std::string_view operator[](size_t index) const;
		string opIndex(int index) const {
			return Detail.ConvertString(mg_node_label_at(node_, index));
		}

		// Iterator begin() { return Iterator(this, 0); }
		// Iterator end() { return Iterator(this, size()); }

		bool empty() const {
			return idx_ >= size();
		}
		string front() const {
			assert(idx_ < size());
			return Detail.ConvertString(mg_node_label_at(node_, idx_));
		}
		void popFront() {
			idx_++;
		}

	private:
		const mg_node *node_;
		uint idx_;
	}

	this(mg_node *ptr) { ptr_ = ptr; }

	/// \brief Create a Node from a copy of the given \ref mg_node.
	this(const mg_node *const_ptr) { this(mg_node_copy(const_ptr)); }

	this(const ref Node other) {
		this(mg_node_copy(other.ptr_));
	}

	// Node(Node &&other);
	// inline Node::Node(Node &&other) : ptr_(other.ptr_) { other.ptr_ = nullptr; }

	// Node &operator=(const Node &other) = delete;
	// Node &operator=(Node &&other) = delete;
	~this() {
		if (ptr_ != null)
			mg_node_destroy(ptr_);
	}

	// explicit Node(const ConstNode &node);

	// Id id() const { return Id::FromInt(mg_node_id(ptr_)); }
	long id() const { return mg_node_id(ptr_); }

	Labels labels() const { return Labels(ptr_); }

	Map properties() const { return Map(mg_node_properties(ptr_)); }

	// ConstNode AsConstNode() const;

	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator==(const Node &other) const;
	bool opEquals(const ref Node other) const {
		return Detail.AreNodesEqual(ptr_, other.ptr_);
	}
	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator==(const ConstNode &other) const;
	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator!=(const Node &other) const { return !(this == other); }
	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator!=(const ConstNode &other) const { return !(*this == other); }

	// mg_node *ptr() const { return ptr_; }

private:
	mg_node *ptr_;
};

/*
inline std::string_view Node::Labels::Iterator::operator*() const {
	return (*iterable_)[index_];
}
*/

// inline Node::Node(const ConstNode &node) : ptr_(mg_node_copy(node.ptr())) {}

/*
inline bool Node::operator==(const ConstNode &other) const {
	return detail::AreNodesEqual(ptr_, other.ptr());
}

inline ConstNode Node::AsConstNode() const { return ConstNode(ptr_); }

inline bool ConstNode::operator==(const ConstNode &other) const {
	return detail::AreNodesEqual(const_ptr_, other.const_ptr_);
}

inline bool ConstNode::operator==(const Node &other) const {
	return detail::AreNodesEqual(const_ptr_, other.ptr());
}
*/




struct Value {
	/// \brief Types that can be stored in a `Value`.
	enum Type {
		Null,
		Bool,
		Int,
		Double,
		String,
		List,
		Map,
		Node,
		Relationship,
		UnboundRelationship,
		Path,
		Date,
		Time,
		LocalTime,
		DateTime,
		DateTimeZoneId,
		LocalDateTime,
		Duration,
		Point2d,
		Point3d
	}

	/// \brief Constructs an object that becomes the owner of the given `value`.
	/// `value` is destroyed when a `Value` object is destroyed.
	this(mg_value *ptr) { ptr_ = ptr; }

	/// \brief Creates a Value from a copy of the given \ref mg_value.
	this(const mg_value *const_ptr) { this(mg_value_copy(const_ptr)); }

	this(const ref Value other) { this(mg_value_copy(other.ptr_)); }
	// Value(Value &&other);
	// Value &operator=(const Value &other) = delete;
	// Value &operator=(Value &&other) = delete;
	~this() {
		if (ptr_ != null)
			mg_value_destroy(ptr_);
	}

	// explicit Value(const ConstValue &value);

	/// \brief Creates Null value.
	// this() { this(mg_value_make_null()); }

	// Constructors for primitive types:
	this(bool value) { this(mg_value_make_bool(value)); }
	this(int value) { this(mg_value_make_integer(value)); }
	this(long value) { this(mg_value_make_integer(value)); }
	this(double value) { this(mg_value_make_float(value)); }

	// Constructors for string:
	this(const ref string value) {
		this(mg_value_make_string(toStringz(value)));
	}
	// explicit Value(const char *value);


	/// \brief Constructs a list value and takes the ownership of the `list`.
	/// \note
	/// Behaviour of accessing the `list` after performing this operation is
	/// considered undefined.
	// this(List &&list);

	/// \brief Constructs a map value and takes the ownership of the `map`.
	/// \note
	/// Behaviour of accessing the `map` after performing this operation is
	/// considered undefined.
	// this(Map &&map);

	/// \brief Constructs a vertex value and takes the ownership of the given
	/// `vertex`. \note Behaviour of accessing the `vertex` after performing this
	/// operation is considered undefined.
	// explicit Value(Node &&vertex);

	/// \brief Constructs an edge value and takes the ownership of the given
	/// `edge`. \note Behaviour of accessing the `edge` after performing this
	/// operation is considered undefined.
	// explicit Value(Relationship &&edge);

	/// \brief Constructs an unbounded edge value and takes the ownership of the
	/// given `edge`. \note Behaviour of accessing the `edge` after performing
	/// this operation is considered undefined.
	// explicit Value(UnboundRelationship &&edge);

	/// \brief Constructs a path value and takes the ownership of the given
	/// `path`. \note Behaviour of accessing the `path` after performing this
	/// operation is considered undefined.
	// explicit Value(Path &&path);


	/// \brief Constructs a date value and takes the ownership of the given
	/// `date`. \note Behaviour of accessing the `date` after performing this
	/// operation is considered undefined.
	// explicit Value(Date &&date);

	/// \brief Constructs a time value and takes the ownership of the given
	/// `time`. \note Behaviour of accessing the `time` after performing this
	/// operation is considered undefined.
	// explicit Value(Time &&time);

	/// \brief Constructs a LocalTime value and takes the ownership of the given
	/// `localTime`. \note Behaviour of accessing the `localTime` after performing
	/// this operation is considered undefined.
	// explicit Value(LocalTime &&localTime);

	/// \brief Constructs a DateTime value and takes the ownership of the given
	/// `dateTime`. \note Behaviour of accessing the `dateTime` after performing
	/// this operation is considered undefined.
	// explicit Value(DateTime &&dateTime);

	/// \brief Constructs a DateTimeZoneId value and takes the ownership of the
	/// given `dateTimeZoneId`. \note Behaviour of accessing the `dateTimeZoneId`
	/// after performing this operation is considered undefined.
	// explicit Value(DateTimeZoneId &&dateTimeZoneId);

	/// \brief Constructs a LocalDateTime value and takes the ownership of the
	/// given `localDateTime`. \note Behaviour of accessing the `localDateTime`
	/// after performing this operation is considered undefined.
	// explicit Value(LocalDateTime &&localDateTime);

	/// \brief Constructs a Duration value and takes the ownership of the given
	/// `duration`. \note Behaviour of accessing the `duration` after performing
	/// this operation is considered undefined.
	// explicit Value(Duration &&duration);

	/// \brief Constructs a Point2d value and takes the ownership of the given
	/// `point2d`. \note Behaviour of accessing the `point2d` after performing
	/// this operation is considered undefined.
	// explicit Value(Point2d &&point2d);

	/// \brief Constructs a Point3d value and takes the ownership of the given
	/// `point3d`. \note Behaviour of accessing the `point3d` after performing
	/// this operation is considered undefined.
	// explicit Value(Point3d &&point3d);

	/// \pre value type is Type::Bool
	// bool ValueBool() const;
	/// \pre value type is Type::Int
	// int64_t ValueInt() const;
	/// \pre value type is Type::Double
	// double ValueDouble() const;
	/// \pre value type is Type::String
	// std::string_view ValueString() const;
	/// \pre value type is Type::List
	// const ConstList ValueList() const;
	/// \pre value type is Type::Map
	// const ConstMap ValueMap() const;
	/// \pre value type is Type::Node
	// const ConstNode ValueNode() const;
	auto opCast(T : Node)() const {
		assert(type() == Type.Node);
		return Node(mg_value_node(ptr_));
	}
	auto opCast(T : long)() const {
		assert(type() == Type.Int);
		return mg_value_integer(ptr_);
	}
	auto toString() const {
		switch (type()) {
			case Type.Node:
				return to!string(Node(mg_value_node(ptr_)));
			case Type.String:
				return Detail.ConvertString(mg_value_string(ptr_));
			case Type.Bool:
				return to!string(to!bool(mg_value_bool(ptr_)));
			case Type.Double:
				return to!string(mg_value_float(ptr_));
			case Type.Int:
				return to!string(mg_value_integer(ptr_));
			default: assert(0, "unhandled type: " ~ to!string(type()));
		}
	}
	auto opCast(T : bool)() const {
		assert(type() == Type.Bool);
		return to!bool(mg_value_bool(ptr_));
	}
	auto opCast(T : double)() const {
		assert(type() == Type.Double);
		return mg_value_float(ptr_);
	}
	/// \pre value type is Type::Relationship
	// const ConstRelationship ValueRelationship() const;
	/// \pre value type is Type::UnboundRelationship
	// const ConstUnboundRelationship ValueUnboundRelationship() const;
	/// \pre value type is Type::Path
	// const ConstPath ValuePath() const;
	/// \pre value type is Type::Date
	// const ConstDate ValueDate() const;
	/// \pre value type is Type::Time
	// const ConstTime ValueTime() const;
	/// \pre value type is Type::LocalTime
	// const ConstLocalTime ValueLocalTime() const;
	/// \pre value type is Type::DateTime
	// const ConstDateTime ValueDateTime() const;
	/// \pre value type is Type::DateTimeZoneId
	// const ConstDateTimeZoneId ValueDateTimeZoneId() const;
	/// \pre value type is Type::LocalDateTime
	// const ConstLocalDateTime ValueLocalDateTime() const;

	/// \pre value type is Type::Duration
	//const ConstDuration ValueDuration() const;
	/// \pre value type is Type::Point2d
	//const ConstPoint2d ValuePoint2d() const;
	/// \pre value type is Type::Point3d
	//const ConstPoint3d ValuePoint3d() const;

	/// \exception std::runtime_error the value type is unknown
	Type type() const {
		return Detail.ConvertType(mg_value_get_type(ptr_));
	}

	//ConstValue AsConstValue() const;

	/// \exception std::runtime_error the value type is unknown
	//bool operator==(const Value &other) const;
	/// \exception std::runtime_error the value type is unknown
	//bool operator==(const ConstValue &other) const;
	/// \exception std::runtime_error the value type is unknown
	//bool operator!=(const Value &other) const { return !(*this == other); }
	/// \exception std::runtime_error the value type is unknown
	//bool operator!=(const ConstValue &other) const { return !(*this == other); }

	//const mg_value *ptr() const { return ptr_; }

private:
	mg_value *ptr_;
}

struct Optional(V) {
	this(ref return scope inout Optional!V rhs) inout { }
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
	@property auto value() const {
		return _value;
	}
	auto opDispatch(string name, T...)(T vals) {
		return mixin("_value." ~ name)(vals);
	}
private:
	alias value this;
	bool _hasValue;
	V _value;
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
		if (session)
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
	bool Execute(const string statement) {
		int status = mg_session_run(session, toStringz(statement), null, null, null, null);
		if (status < 0)
			return false;

		status = mg_session_pull(session, null);
		if (status < 0)
			return false;

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
	bool Execute(const string statement, const ref Map params) {
		int status = mg_session_run(session, toStringz(statement), params.ptr_, null, null, null);
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

	/// \brief Fetches all results and discards them.
	void DiscardAll() {
		while (FetchOne()) { }
	}

	/// \brief Fetches all results.
	Value[][] FetchAll() {
		Value[] maybeResult;
		Value[][] data;
		while ((maybeResult = FetchOne()).length > 0)
			data ~= maybeResult;
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

	/// \brief Static method that creates a Memgraph client instance using default parameters localhost:7687
	/// \return pointer to the created client instance.
	/// Returns a `null` if the connection couldn't be established.
	static Optional!Client Connect() {
		Params params;
		return Connect(params);
	}

	/// \brief Static method that creates a Memgraph client instance.
	/// \return pointer to the created client instance.
	/// If the connection couldn't be established given the `params`, it returns
	/// a `nullptr`.
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

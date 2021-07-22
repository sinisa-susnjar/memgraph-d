/// Main D module for the memgraph database.
/// Imports all required definitions.
module memgraph;

public import memgraph.mgclient;
public import memgraph.optional;
public import memgraph.client;
public import memgraph.value;
public import memgraph.node;
public import memgraph.map;
public import memgraph.enums;
public import memgraph.params;
public import memgraph.result;
public import memgraph.list;

import memgraph.detail;

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

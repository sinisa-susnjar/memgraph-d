/// Provides helper functions.
module memgraph.detail;

import std.conv;

import memgraph.mgclient, memgraph.enums;

/// Wrapper class around static helper functions.
struct Detail {
  /// Converts a `mg_string` to a D string.
  static string convertString(const mg_string *str) {
    assert(str != null);
    const auto data = mg_string_data(str);
    const auto len = mg_string_size(str);
    return to!string(data[0..len]);
  }

  /// Converts a `mg_value_type` enum to a `Type` enum.
  static Type convertType(mg_value_type type) {
    switch (type) {
      case mg_value_type.MG_VALUE_TYPE_NULL:
        return Type.Null;
      case mg_value_type.MG_VALUE_TYPE_BOOL:
        return Type.Bool;
      case mg_value_type.MG_VALUE_TYPE_INTEGER:
        return Type.Int;
      case mg_value_type.MG_VALUE_TYPE_FLOAT:
        return Type.Double;
      case mg_value_type.MG_VALUE_TYPE_STRING:
        return Type.String;
      case mg_value_type.MG_VALUE_TYPE_LIST:
        return Type.List;
      case mg_value_type.MG_VALUE_TYPE_MAP:
        return Type.Map;
      case mg_value_type.MG_VALUE_TYPE_NODE:
        return Type.Node;
      case mg_value_type.MG_VALUE_TYPE_RELATIONSHIP:
        return Type.Relationship;
      case mg_value_type.MG_VALUE_TYPE_UNBOUND_RELATIONSHIP:
        return Type.UnboundRelationship;
      case mg_value_type.MG_VALUE_TYPE_PATH:
        return Type.Path;
      case mg_value_type.MG_VALUE_TYPE_DATE:
        return Type.Date;
      case mg_value_type.MG_VALUE_TYPE_TIME:
        return Type.Time;
      case mg_value_type.MG_VALUE_TYPE_LOCAL_TIME:
        return Type.LocalTime;
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME:
        return Type.DateTime;
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME_ZONE_ID:
        return Type.DateTimeZoneId;
      case mg_value_type.MG_VALUE_TYPE_LOCAL_DATE_TIME:
        return Type.LocalDateTime;
      case mg_value_type.MG_VALUE_TYPE_DURATION:
        return Type.Duration;
      case mg_value_type.MG_VALUE_TYPE_POINT_2D:
        return Type.Point2d;
      case mg_value_type.MG_VALUE_TYPE_POINT_3D:
        return Type.Point3d;
      case mg_value_type.MG_VALUE_TYPE_UNKNOWN:
        assert(0, "unknown value type");
      default:
        assert(0, "unexpected value type: " ~ to!string(type));
    }
  }

  /// Compares two `mg_value`s.
  static bool areValuesEqual(const mg_value *value1, const mg_value *value2) {
    assert(value1 != null);
    assert(value2 != null);
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
        return Detail.convertString(mg_value_string(value1)) ==
          Detail.convertString(mg_value_string(value2));
      case mg_value_type.MG_VALUE_TYPE_LIST:
        return Detail.areListsEqual(mg_value_list(value1),
            mg_value_list(value2));
      case mg_value_type.MG_VALUE_TYPE_MAP:
        return Detail.areMapsEqual(mg_value_map(value1), mg_value_map(value2));
      case mg_value_type.MG_VALUE_TYPE_NODE:
        return Detail.areNodesEqual(mg_value_node(value1),
            mg_value_node(value2));
      case mg_value_type.MG_VALUE_TYPE_RELATIONSHIP:
        return Detail.areRelationshipsEqual(mg_value_relationship(value1),
            mg_value_relationship(value2));
      case mg_value_type.MG_VALUE_TYPE_UNBOUND_RELATIONSHIP:
        return Detail.areUnboundRelationshipsEqual(
            mg_value_unbound_relationship(value1),
            mg_value_unbound_relationship(value2));
      case mg_value_type.MG_VALUE_TYPE_PATH:
        return Detail.arePathsEqual(mg_value_path(value1),
            mg_value_path(value2));
      case mg_value_type.MG_VALUE_TYPE_DATE:
        return Detail.areDatesEqual(mg_value_date(value1),
            mg_value_date(value2));
      case mg_value_type.MG_VALUE_TYPE_TIME:
        return Detail.areTimesEqual(mg_value_time(value1),
            mg_value_time(value2));
      case mg_value_type.MG_VALUE_TYPE_LOCAL_TIME:
        return Detail.areLocalTimesEqual(mg_value_local_time(value1),
            mg_value_local_time(value2));
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME:
        return Detail.areDateTimesEqual(mg_value_date_time(value1),
            mg_value_date_time(value2));
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME_ZONE_ID:
        return Detail.areDateTimeZoneIdsEqual(
            mg_value_date_time_zone_id(value1),
            mg_value_date_time_zone_id(value2));
      case mg_value_type.MG_VALUE_TYPE_LOCAL_DATE_TIME:
        return Detail.areLocalDateTimesEqual(mg_value_local_date_time(value1),
            mg_value_local_date_time(value2));
      case mg_value_type.MG_VALUE_TYPE_DURATION:
        return Detail.areDurationsEqual(mg_value_duration(value1),
            mg_value_duration(value2));
      case mg_value_type.MG_VALUE_TYPE_POINT_2D:
        return Detail.arePoint2dsEqual(mg_value_point_2d(value1),
            mg_value_point_2d(value2));
      case mg_value_type.MG_VALUE_TYPE_POINT_3D:
        return Detail.arePoint3dsEqual(mg_value_point_3d(value1),
            mg_value_point_3d(value2));
      case mg_value_type.MG_VALUE_TYPE_UNKNOWN:
        assert(0, "comparing values of unknown types!");
      default: assert(0, "unexpected type: " ~ to!string(mg_value_get_type(value1)));
    }
  }

  /// Compares two `mg_list`s.
  static bool areListsEqual(const mg_list *list1, const mg_list *list2) {
    assert(list1 != null);
    assert(list2 != null);
    if (list1 == list2)
      return true;
    if (mg_list_size(list1) != mg_list_size(list2))
      return false;
    const uint len = mg_list_size(list1);
    for (uint i = 0; i < len; ++i) {
      if (!Detail.areValuesEqual(mg_list_at(list1, i), mg_list_at(list2, i)))
        return false;
    }
    return true;
  }

  /// Compares two `mg_map`s.
  static bool areMapsEqual(const mg_map *map1, const mg_map *map2) {
    assert(map1 != null);
    assert(map2 != null);
    if (map1 == map2)
      return true;
    if (mg_map_size(map1) != mg_map_size(map2))
      return false;
    const uint len = mg_map_size(map1);
    for (uint i = 0; i < len; ++i) {
      const mg_string *key = mg_map_key_at(map1, i);
      const mg_value *value1 = mg_map_value_at(map1, i);
      const mg_value *value2 =
        mg_map_at2(map2, mg_string_size(key), mg_string_data(key));
      if (value2 == null)
        return false;
      if (!Detail.areValuesEqual(value1, value2))
        return false;
    }
    return true;
  }

  /// Compares two nodes for equality.
  /// Params: node1 = first node to compare
  ///         node2 = second node to compare
  /// Return: `true` if both nodes are equal, `false` otherwise
  static bool areNodesEqual(const mg_node *node1, const mg_node *node2) {
    assert(node1 != null);
    assert(node2 != null);
    if (node1 == node2)
      return true;
    if (mg_node_id(node1) != mg_node_id(node2))
      return false;
    if (mg_node_label_count(node1) != mg_node_label_count(node2))
      return false;
    string[] labels1;
    string[] labels2;
    const uint label_count = mg_node_label_count(node1);
    labels1.length = labels2.length = label_count;
    for (uint i = 0; i < label_count; ++i) {
      labels1[i] = Detail.convertString(mg_node_label_at(node1, i));
      labels2[i] = Detail.convertString(mg_node_label_at(node2, i));
    }
    if (labels1 != labels2)
      return false;
    return Detail.areMapsEqual(mg_node_properties(node1),
        mg_node_properties(node2));
  }  // areNodesEqual()

  /// Compares two `mg_relationship`s.
  static bool areRelationshipsEqual(const mg_relationship *rel1,
      const mg_relationship *rel2) {
    assert(rel1 != null);
    assert(rel2 != null);
    if (rel1 == rel2)
      return true;
    if (mg_relationship_id(rel1) != mg_relationship_id(rel2))
      return false;
    if (mg_relationship_start_id(rel1) != mg_relationship_start_id(rel2))
      return false;
    if (mg_relationship_end_id(rel1) != mg_relationship_end_id(rel2))
      return false;
    if (Detail.convertString(mg_relationship_type(rel1)) !=
        Detail.convertString(mg_relationship_type(rel2)))
      return false;
    return Detail.areMapsEqual(mg_relationship_properties(rel1),
        mg_relationship_properties(rel2));
  }

  /// Compares two `mg_unbound_relationship`s.
  static bool areUnboundRelationshipsEqual(const mg_unbound_relationship *rel1,
      const mg_unbound_relationship *rel2) {
    assert(rel1 != null);
    assert(rel2 != null);
    if (rel1 == rel2)
      return true;
    if (mg_unbound_relationship_id(rel1) != mg_unbound_relationship_id(rel2))
      return false;
    if (Detail.convertString(mg_unbound_relationship_type(rel1)) !=
        Detail.convertString(mg_unbound_relationship_type(rel2)))
      return false;
    return Detail.areMapsEqual(mg_unbound_relationship_properties(rel1),
        mg_unbound_relationship_properties(rel2));
  }

  /// Compares two `mg_path`s.
  static bool arePathsEqual(const mg_path *path1, const mg_path *path2) {
    assert(path1 != null);
    assert(path2 != null);
    if (path1 == path2)
      return true;
    if (mg_path_length(path1) != mg_path_length(path2))
      return false;
    const uint len = mg_path_length(path1);
    for (uint i = 0; i < len; ++i) {
      if (!Detail.areNodesEqual(mg_path_node_at(path1, i),
            mg_path_node_at(path2, i))) {
        return false;
      }
      if (!Detail.areUnboundRelationshipsEqual(
            mg_path_relationship_at(path1, i),
            mg_path_relationship_at(path2, i))) {
        return false;
      }
      if (mg_path_relationship_reversed_at(path1, i) !=
          mg_path_relationship_reversed_at(path2, i)) {
        return false;
      }
    }
    return Detail.areNodesEqual(mg_path_node_at(path1, len),
        mg_path_node_at(path2, len));
  }

  /// Compares two `mg_date`s.
  static bool areDatesEqual(const mg_date *date1, const mg_date *date2) {
    assert(date1 != null);
    assert(date2 != null);
    return mg_date_days(date1) == mg_date_days(date2);
  }

  /// Compares two `mg_time`s.
  static bool areTimesEqual(const mg_time *time1, const mg_time *time2) {
    assert(time1 != null);
    assert(time2 != null);
    return mg_time_nanoseconds(time1) == mg_time_nanoseconds(time2) &&
      mg_time_tz_offset_seconds(time1) == mg_time_tz_offset_seconds(time2);
  }

  /// Compares two `mg_local_time`s.
  static bool areLocalTimesEqual(const mg_local_time *local_time1,
      const mg_local_time *local_time2) {
    assert(local_time1 != null);
    assert(local_time2 != null);
    return mg_local_time_nanoseconds(local_time1) ==
      mg_local_time_nanoseconds(local_time2);
  }

  /// Compares two `mg_date_time`s.
  static bool areDateTimesEqual(const mg_date_time *date_time1,
      const mg_date_time *date_time2) {
    assert(date_time1 != null);
    assert(date_time2 != null);
    return mg_date_time_seconds(date_time1) == mg_date_time_seconds(date_time2) &&
      mg_date_time_nanoseconds(date_time1) ==
      mg_date_time_nanoseconds(date_time2) &&
      mg_date_time_tz_offset_minutes(date_time1) ==
      mg_date_time_tz_offset_minutes(date_time2);
  }

  /// Compares two `mg_date_time_zone`s.
  static bool areDateTimeZoneIdsEqual(
      const mg_date_time_zone_id *date_time_zone_id1,
      const mg_date_time_zone_id *date_time_zone_id2) {
    assert(date_time_zone_id1 != null);
    assert(date_time_zone_id2 != null);
    return mg_date_time_zone_id_seconds(date_time_zone_id1) ==
      mg_date_time_zone_id_seconds(date_time_zone_id2) &&
      mg_date_time_zone_id_nanoseconds(date_time_zone_id1) ==
      mg_date_time_zone_id_nanoseconds(date_time_zone_id2) &&
      mg_date_time_zone_id_tz_id(date_time_zone_id1) ==
      mg_date_time_zone_id_tz_id(date_time_zone_id2);
  }

  /// Compares two `mg_local_date_time`s.
  static bool areLocalDateTimesEqual(const mg_local_date_time *local_date_time1,
      const mg_local_date_time *local_date_time2) {
    assert(local_date_time1 != null);
    assert(local_date_time2 != null);
    return mg_local_date_time_seconds(local_date_time1) ==
      mg_local_date_time_seconds(local_date_time2) &&
      mg_local_date_time_nanoseconds(local_date_time1) ==
      mg_local_date_time_nanoseconds(local_date_time2);
  }

  /// Compares two `mg_duration`s.
  static bool areDurationsEqual(const mg_duration *duration1,
      const mg_duration *duration2) {
    assert(duration1 != null);
    assert(duration2 != null);
    return mg_duration_months(duration1) == mg_duration_months(duration2) &&
      mg_duration_days(duration1) == mg_duration_days(duration2) &&
      mg_duration_seconds(duration1) == mg_duration_seconds(duration2) &&
      mg_duration_nanoseconds(duration1) ==
      mg_duration_nanoseconds(duration2);
  }

  /// Compares two `mg_point_2d`s.
  static bool arePoint2dsEqual(const mg_point_2d *point_2d1,
      const mg_point_2d *point_2d2) {
    assert(point_2d1 != null);
    assert(point_2d2 != null);
    return mg_point_2d_srid(point_2d1) == mg_point_2d_srid(point_2d2) &&
      mg_point_2d_x(point_2d1) == mg_point_2d_x(point_2d2) &&
      mg_point_2d_y(point_2d1) == mg_point_2d_y(point_2d2);
  }

  /// Compares two `mg_point_3d`s.
  static bool arePoint3dsEqual(const mg_point_3d *point_3d1,
      const mg_point_3d *point_3d2) {
    assert(point_3d1 != null);
    assert(point_3d2 != null);
    return mg_point_3d_srid(point_3d1) == mg_point_3d_srid(point_3d2) &&
      mg_point_3d_x(point_3d1) == mg_point_3d_x(point_3d2) &&
      mg_point_3d_y(point_3d1) == mg_point_3d_y(point_3d2) &&
      mg_point_3d_z(point_3d1) == mg_point_3d_z(point_3d2);
  }
}

/// Provides helper functions.
module memgraph.detail;

import memgraph.mgclient, memgraph.enums;

/// Wrapper class around static helper functions.
struct Detail {
  /// Converts a `mg_string` to a D string.
  @nogc static string convertString(const mg_string *str) {
    assert(str != null);
    const auto data = mg_string_data(str);
    const auto len = mg_string_size(str);
    return cast(string)data[0..len];
  }

  unittest {
    const p = mg_string_make("Some test string");
    assert(p != null);
    const s = Detail.convertString(p);
    assert(s == "Some test string");
  }

  /// Converts a `mg_value_type` enum to a `Type` enum.
  @nogc static Type convertType(mg_value_type type) {
    final switch (type) {
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
        assert(0);
      case mg_value_type.MG_VALUE_TYPE_LOCAL_TIME:
        return Type.LocalTime;
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME:
        assert(0);
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME_ZONE_ID:
        assert(0);
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
    }
  }

  unittest {
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_NULL) == Type.Null);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_BOOL) == Type.Bool);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_INTEGER) == Type.Int);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_FLOAT) == Type.Double);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_STRING) == Type.String);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_LIST) == Type.List);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_MAP) == Type.Map);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_NODE) == Type.Node);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_RELATIONSHIP) == Type.Relationship);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_UNBOUND_RELATIONSHIP) == Type.UnboundRelationship);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_PATH) == Type.Path);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_DATE) == Type.Date);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_LOCAL_TIME) == Type.LocalTime);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_LOCAL_DATE_TIME) == Type.LocalDateTime);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_DURATION) == Type.Duration);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_POINT_2D) == Type.Point2d);
    assert(Detail.convertType(mg_value_type.MG_VALUE_TYPE_POINT_3D) == Type.Point3d);

    import std.exception, core.exception;

    // The following types are currently not supported, pending addition
    // of the appropriate temporal functions to the memgraph backend.
    assertThrown!AssertError(Detail.convertType(mg_value_type.MG_VALUE_TYPE_TIME));
    assertThrown!AssertError(Detail.convertType(mg_value_type.MG_VALUE_TYPE_DATE_TIME));
    assertThrown!AssertError(Detail.convertType(mg_value_type.MG_VALUE_TYPE_DATE_TIME_ZONE_ID));

    // Check for "unknown" type.
    assertThrown!AssertError(Detail.convertType(mg_value_type.MG_VALUE_TYPE_UNKNOWN));
  }

  /// Compares two `mg_value`s.
  @nogc static bool areValuesEqual(const mg_value *value1, const mg_value *value2) {
    assert(value1 != null);
    assert(value2 != null);
    if (value1 == value2) {
      return true;
    }
    if (mg_value_get_type(value1) != mg_value_get_type(value2)) {
      return false;
    }
    final switch (mg_value_get_type(value1)) {
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
        // return Detail.areTimesEqual(mg_value_time(value1), mg_value_time(value2));
        assert(0);
      case mg_value_type.MG_VALUE_TYPE_LOCAL_TIME:
        return Detail.areLocalTimesEqual(mg_value_local_time(value1),
            mg_value_local_time(value2));
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME:
        // return Detail.areDateTimesEqual(mg_value_date_time(value1), mg_value_date_time(value2));
        assert(0);
      case mg_value_type.MG_VALUE_TYPE_DATE_TIME_ZONE_ID:
        /*
        return Detail.areDateTimeZoneIdsEqual(
            mg_value_date_time_zone_id(value1),
            mg_value_date_time_zone_id(value2));
        */
        assert(0);
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
    }
  }

  unittest {
    auto nullValue1 = mg_value_make_null();
    auto nullValue2 = mg_value_make_null();
    auto stringValue1 = mg_value_make_string("Hello World");
    auto stringValue2 = mg_value_make_string("Hello World");

    assert(Detail.areValuesEqual(nullValue1, nullValue2));
    assert(!Detail.areValuesEqual(nullValue1, stringValue1));
    assert(Detail.areValuesEqual(stringValue1, stringValue2));

    auto boolValue1 = mg_value_make_bool(1);
    auto boolValue2 = mg_value_make_bool(1);
    assert(Detail.areValuesEqual(boolValue1, boolValue2));

    auto intValue1 = mg_value_make_integer(42);
    auto intValue2 = mg_value_make_integer(42);
    assert(Detail.areValuesEqual(intValue1, intValue2));

    auto floatValue1 = mg_value_make_float(3.14);
    auto floatValue2 = mg_value_make_float(3.14);
    assert(Detail.areValuesEqual(floatValue1, floatValue2));
  }

  /// Compares two `mg_list`s.
  @nogc static bool areListsEqual(const mg_list *list1, const mg_list *list2) {
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

  unittest {
    auto list1 = mg_list_make_empty(1);
    mg_list_append(list1, mg_value_make_string("Value1"));
    auto list2 = mg_list_make_empty(1);
    mg_list_append(list2, mg_value_make_string("Value1"));

    auto listValue1 = mg_value_make_list(list1);
    auto listValue2 = mg_value_make_list(list2);
    assert(Detail.areValuesEqual(listValue1, listValue1));
    assert(Detail.areValuesEqual(listValue1, listValue2));

    auto list3 = mg_list_make_empty(2);
    mg_list_append(list3, mg_value_make_string("Value1"));
    mg_list_append(list3, mg_value_make_string("Value2"));
    auto listValue3 = mg_value_make_list(list3);
    assert(!Detail.areValuesEqual(listValue1, listValue3));

    auto list4 = mg_list_make_empty(2);
    mg_list_append(list4, mg_value_make_string("Value1"));
    mg_list_append(list4, mg_value_make_string("Value3"));
    auto listValue4 = mg_value_make_list(list4);
    assert(!Detail.areValuesEqual(listValue3, listValue4));
  }

  /// Compares two `mg_map`s.
  @nogc static bool areMapsEqual(const mg_map *map1, const mg_map *map2) {
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

  unittest {
    auto map1 = mg_map_make_empty(1);
    mg_map_insert(map1, "key1", mg_value_make_string("Value1"));
    auto map2 = mg_map_make_empty(1);
    mg_map_insert(map2, "key1", mg_value_make_string("Value1"));

    auto mapValue1 = mg_value_make_map(map1);
    auto mapValue2 = mg_value_make_map(map2);
    assert(Detail.areValuesEqual(mapValue1, mapValue2));
    assert(Detail.areValuesEqual(mapValue1, mapValue1));

    auto map3 = mg_map_make_empty(2);
    mg_map_insert(map3, "key1", mg_value_make_string("Value1"));
    mg_map_insert(map3, "key2", mg_value_make_string("Value2"));
    auto mapValue3 = mg_value_make_map(map3);
    assert(!Detail.areValuesEqual(mapValue1, mapValue3));

    auto map4 = mg_map_make_empty(2);
    mg_map_insert(map4, "key1", mg_value_make_string("Value1"));
    mg_map_insert(map4, "key3", mg_value_make_string("Value3"));
    auto mapValue4 = mg_value_make_map(map4);
    assert(!Detail.areValuesEqual(mapValue3, mapValue4));

    auto map5 = mg_map_make_empty(2);
    mg_map_insert(map5, "key1", mg_value_make_string("Value1"));
    mg_map_insert(map5, "key2", mg_value_make_string("Value3"));
    auto mapValue5 = mg_value_make_map(map5);
    assert(!Detail.areValuesEqual(mapValue3, mapValue5));
  }

  /// Compares two nodes for equality.
  /// Params: node1 = first node to compare
  ///         node2 = second node to compare
  /// Return: `true` if both nodes are equal, `false` otherwise
  @nogc static bool areNodesEqual(const mg_node *node1, const mg_node *node2) {
    assert(node1 != null);
    assert(node2 != null);
    if (node1 == node2)
      return true;
    if (mg_node_id(node1) != mg_node_id(node2))
      return false;
    if (mg_node_label_count(node1) != mg_node_label_count(node2))
      return false;
    immutable label_count = mg_node_label_count(node1);
    for (uint i = 0; i < label_count; ++i) {
      if (Detail.convertString(mg_node_label_at(node1, i)) != Detail.convertString(mg_node_label_at(node2, i)))
        return false;
    }
    return Detail.areMapsEqual(mg_node_properties(node1), mg_node_properties(node2));
  }  // areNodesEqual()

  unittest {
    auto label1 = mg_string_make("label1");
    auto map1 = mg_map_make_empty(1);
    mg_map_insert(map1, "key1", mg_value_make_string("value1"));
    auto node1 = mg_node_make(1, 1, &label1, map1);
    auto nodeValue1 = mg_value_make_node(node1);
    assert(Detail.areValuesEqual(nodeValue1, nodeValue1));

    auto node2 = mg_node_make(2, 1, &label1, map1);
    auto nodeValue2 = mg_value_make_node(node2);
    assert(!Detail.areValuesEqual(nodeValue1, nodeValue2));

    auto label2 = mg_string_make("label2");
    mg_string** labels = cast(mg_string**)[ label1, label2 ];
    auto node3 = mg_node_make(1, 2, labels, map1);
    auto nodeValue3 = mg_value_make_node(node3);
    assert(!Detail.areValuesEqual(nodeValue1, nodeValue3));

    const label3 = mg_string_make("label3");
    mg_string** labels2 = cast(mg_string**)[ label1, label3 ];
    auto node4 = mg_node_make(1, 2, labels2, map1);
    auto nodeValue4 = mg_value_make_node(node4);
    assert(!Detail.areValuesEqual(nodeValue3, nodeValue4));

    labels2[1] = label2;
    auto node5 = mg_node_make(1, 2, labels2, map1);
    auto nodeValue5 = mg_value_make_node(node5);
    assert(Detail.areValuesEqual(nodeValue3, nodeValue5));
  }

  /// Compares two `mg_relationship`s.
  @nogc static bool areRelationshipsEqual(const mg_relationship *rel1,
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

  unittest {
    auto relType1 = mg_string_make("Rel1");
    auto props1 = mg_map_make_empty(1);
    mg_map_insert(props1, "key1", mg_value_make_string("Value1"));
    auto rel1 = mg_relationship_make(1, 100, 101, relType1, props1);
    auto relValue1 = mg_value_make_relationship(rel1);

    auto relType2 = mg_string_make("Rel1");
    auto props2 = mg_map_make_empty(1);
    mg_map_insert(props2, "key1", mg_value_make_string("Value1"));
    auto rel2 = mg_relationship_make(1, 100, 101, relType2, props2);
    auto relValue2 = mg_value_make_relationship(rel2);

    assert(Detail.areValuesEqual(relValue1, relValue2));
    rel2.id = 2;
    assert(!Detail.areValuesEqual(relValue1, relValue2));
    rel2.id = rel1.id;
    rel2.start_id = 42;
    assert(!Detail.areValuesEqual(relValue1, relValue2));
    rel2.id = rel1.id;
    rel2.start_id = rel1.start_id;
    rel2.end_id = 42;
    assert(!Detail.areValuesEqual(relValue1, relValue2));
    auto relType3 = mg_string_make("Rel3");
    auto rel3 = mg_relationship_make(1, 100, 101, relType3, props2);
    auto relValue3 = mg_value_make_relationship(rel3);
    assert(!Detail.areValuesEqual(relValue1, relValue3));
  }

  /// Compares two `mg_unbound_relationship`s.
  @nogc static bool areUnboundRelationshipsEqual(const mg_unbound_relationship *rel1,
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

  unittest {
    auto relType1 = mg_string_make("Rel1");
    auto props1 = mg_map_make_empty(1);
    mg_map_insert(props1, "key1", mg_value_make_string("Value1"));
    auto rel1 = mg_unbound_relationship_make(1, relType1, props1);
    auto relValue1 = mg_value_make_unbound_relationship(rel1);

    auto relType2 = mg_string_make("Rel1");
    auto props2 = mg_map_make_empty(1);
    mg_map_insert(props2, "key1", mg_value_make_string("Value1"));
    auto rel2 = mg_unbound_relationship_make(1, relType2, props2);
    auto relValue2 = mg_value_make_unbound_relationship(rel2);

    assert(Detail.areValuesEqual(relValue1, relValue2));
    rel2.id = 2;
    assert(!Detail.areValuesEqual(relValue1, relValue2));
    auto relType3 = mg_string_make("Rel3");
    auto rel3 = mg_unbound_relationship_make(1, relType3, props2);
    auto relValue3 = mg_value_make_unbound_relationship(rel3);
    assert(!Detail.areValuesEqual(relValue1, relValue3));
  }

  /// Compares two `mg_path`s.
  @nogc static bool arePathsEqual(const mg_path *path1, const mg_path *path2) {
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

  unittest {

    mg_node*[6] nodes;
    nodes[0] = mg_node_make(1, 0, null, mg_map_make_empty(0));
    nodes[1] = mg_node_make(2, 0, null, mg_map_make_empty(0));
    nodes[2] = mg_node_make(3, 0, null, mg_map_make_empty(0));
    nodes[3] = mg_node_make(4, 0, null, mg_map_make_empty(0));
    nodes[4] = mg_node_make(5, 0, null, mg_map_make_empty(0));
    nodes[5] = mg_node_make(6, 0, null, mg_map_make_empty(0));

    const auto seqs = [0L, 1L, 2L, 3L, 4L, 5L];

    mg_unbound_relationship*[6] rels;
    rels[0] = mg_unbound_relationship_make(1, mg_string_make("Rel1"), mg_map_make_empty(0));
    rels[1] = mg_unbound_relationship_make(2, mg_string_make("Rel1"), mg_map_make_empty(0));
    rels[2] = mg_unbound_relationship_make(3, mg_string_make("Rel1"), mg_map_make_empty(0));
    rels[3] = mg_unbound_relationship_make(4, mg_string_make("Rel1"), mg_map_make_empty(0));
    rels[4] = mg_unbound_relationship_make(5, mg_string_make("Rel1"), mg_map_make_empty(0));
    rels[5] = mg_unbound_relationship_make(6, mg_string_make("Rel2"), mg_map_make_empty(0));

    auto path1 = mg_path_make(2u, cast(mg_node**)nodes, 1u, cast(mg_unbound_relationship**)rels,
                              2u, cast(const long*)seqs);
    auto pathValue1 = mg_value_make_path(path1);
    auto path2 = mg_path_make(2u, cast(mg_node**)nodes, 1u, cast(mg_unbound_relationship**)rels,
                              2u, cast(const long*)seqs);
    auto pathValue2 = mg_value_make_path(path2);

    assert(Detail.areValuesEqual(pathValue1, pathValue2));

    auto path3 = mg_path_make(4u, cast(mg_node**)nodes, 3u, cast(mg_unbound_relationship**)rels,
                              4u, cast(const long*)seqs);
    auto pathValue3 = mg_value_make_path(path3);

    assert(!Detail.areValuesEqual(pathValue1, pathValue3));

    auto path4 = mg_path_make(4u, cast(mg_node**)&nodes[1], 3u, cast(mg_unbound_relationship**)&rels[1],
                              4u, cast(const long*)&seqs[1]);
    auto pathValue4 = mg_value_make_path(path4);

    assert(!Detail.areValuesEqual(pathValue3, pathValue4));

    auto path5 = mg_path_make(4u, cast(mg_node**)&nodes[1], 3u, cast(mg_unbound_relationship**)&rels[2],
                              4u, cast(const long*)&seqs[1]);
    auto pathValue5 = mg_value_make_path(path5);

    assert(!Detail.areValuesEqual(pathValue4, pathValue5));

    // TODO: test path reversed at line 451
  }

  /// Compares two `mg_date`s.
  @nogc static bool areDatesEqual(const mg_date *date1, const mg_date *date2) {
    assert(date1 != null);
    assert(date2 != null);
    return mg_date_days(date1) == mg_date_days(date2);
  }

  /// Compares two `mg_time`s.
  /*
  @nogc static bool areTimesEqual(const mg_time *time1, const mg_time *time2) {
    assert(time1 != null);
    assert(time2 != null);
    return mg_time_nanoseconds(time1) == mg_time_nanoseconds(time2) &&
      mg_time_tz_offset_seconds(time1) == mg_time_tz_offset_seconds(time2);
  }
  */

  /// Compares two `mg_local_time`s.
  @nogc static bool areLocalTimesEqual(const mg_local_time *local_time1,
      const mg_local_time *local_time2) {
    assert(local_time1 != null);
    assert(local_time2 != null);
    return mg_local_time_nanoseconds(local_time1) ==
      mg_local_time_nanoseconds(local_time2);
  }

  unittest {
    auto localTime1 = mg_local_time_make(4711);
    auto localTimeValue1 = mg_value_make_local_time(localTime1);
    auto localTime2 = mg_local_time_make(4711);
    auto localTimeValue2 = mg_value_make_local_time(localTime2);
    assert(Detail.areValuesEqual(localTimeValue1, localTimeValue2));
  }

  /// Compares two `mg_date_time`s.
  /*
  @nogc static bool areDateTimesEqual(const mg_date_time *date_time1,
      const mg_date_time *date_time2) {
    assert(date_time1 != null);
    assert(date_time2 != null);
    return mg_date_time_seconds(date_time1) == mg_date_time_seconds(date_time2) &&
      mg_date_time_nanoseconds(date_time1) ==
      mg_date_time_nanoseconds(date_time2) &&
      mg_date_time_tz_offset_minutes(date_time1) ==
      mg_date_time_tz_offset_minutes(date_time2);
  }
  */

  /// Compares two `mg_date_time_zone`s.
  /*
  @nogc static bool areDateTimeZoneIdsEqual(
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
  */

  /// Compares two `mg_local_date_time`s.
  @nogc static bool areLocalDateTimesEqual(const mg_local_date_time *local_date_time1,
      const mg_local_date_time *local_date_time2) {
    assert(local_date_time1 != null);
    assert(local_date_time2 != null);
    return mg_local_date_time_seconds(local_date_time1) ==
      mg_local_date_time_seconds(local_date_time2) &&
      mg_local_date_time_nanoseconds(local_date_time1) ==
      mg_local_date_time_nanoseconds(local_date_time2);
  }

  unittest {
    auto dateTime1 = mg_local_date_time_make(100, 42);
    auto dateTimeValue1 = mg_value_make_local_date_time(dateTime1);
    auto dateTime2 = mg_local_date_time_make(100, 42);
    auto dateTimeValue2 = mg_value_make_local_date_time(dateTime2);
    assert(Detail.areValuesEqual(dateTimeValue1, dateTimeValue2));
  }

  /// Compares two `mg_duration`s.
  @nogc static bool areDurationsEqual(const mg_duration *duration1,
      const mg_duration *duration2) {
    assert(duration1 != null);
    assert(duration2 != null);
    return mg_duration_months(duration1) == mg_duration_months(duration2) &&
      mg_duration_days(duration1) == mg_duration_days(duration2) &&
      mg_duration_seconds(duration1) == mg_duration_seconds(duration2) &&
      mg_duration_nanoseconds(duration1) ==
      mg_duration_nanoseconds(duration2);
  }

  unittest {
    auto dur1 = mg_duration_make(0, 7, 100, 42);
    auto durValue1 = mg_value_make_duration(dur1);
    auto dur2 = mg_duration_make(0, 7, 100, 42);
    auto durValue2 = mg_value_make_duration(dur2);
    assert(Detail.areValuesEqual(durValue1, durValue2));
  }

  /// Compares two `mg_point_2d`s.
  @nogc static bool arePoint2dsEqual(const mg_point_2d *point_2d1,
      const mg_point_2d *point_2d2) {
    assert(point_2d1 != null);
    assert(point_2d2 != null);
    return mg_point_2d_srid(point_2d1) == mg_point_2d_srid(point_2d2) &&
      mg_point_2d_x(point_2d1) == mg_point_2d_x(point_2d2) &&
      mg_point_2d_y(point_2d1) == mg_point_2d_y(point_2d2);
  }

  unittest {
    auto point1 = mg_point_2d_alloc(&mg_system_allocator);
    point1.srid = 1;
    point1.x = 100;
    point1.y = 100;
    auto pointValue1 = mg_value_make_point_2d(point1);

    auto point2 = mg_point_2d_alloc(&mg_system_allocator);
    point2.srid = 1;
    point2.x = 100;
    point2.y = 100;
    auto pointValue2 = mg_value_make_point_2d(point2);

    assert(Detail.areValuesEqual(pointValue1, pointValue2));
  }

  /// Compares two `mg_point_3d`s.
  @nogc static bool arePoint3dsEqual(const mg_point_3d *point_3d1,
      const mg_point_3d *point_3d2) {
    assert(point_3d1 != null);
    assert(point_3d2 != null);
    return mg_point_3d_srid(point_3d1) == mg_point_3d_srid(point_3d2) &&
      mg_point_3d_x(point_3d1) == mg_point_3d_x(point_3d2) &&
      mg_point_3d_y(point_3d1) == mg_point_3d_y(point_3d2) &&
      mg_point_3d_z(point_3d1) == mg_point_3d_z(point_3d2);
  }

  unittest {
    auto point1 = mg_point_3d_alloc(&mg_system_allocator);
    point1.srid = 1;
    point1.x = 100;
    point1.y = 100;
    point1.z = 100;
    auto pointValue1 = mg_value_make_point_3d(point1);

    auto point2 = mg_point_3d_alloc(&mg_system_allocator);
    point2.srid = 1;
    point2.x = 100;
    point2.y = 100;
    point2.z = 100;
    auto pointValue2 = mg_value_make_point_3d(point2);

    assert(Detail.areValuesEqual(pointValue1, pointValue2));
  }
}

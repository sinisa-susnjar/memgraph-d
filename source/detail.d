module detail;

import std.conv;

import mgclient, enums;

struct Detail {
	static string ConvertString(const mg_string *str) {
		const auto data = mg_string_data(str);
		const auto len = mg_string_size(str);
		return to!string(data[0..len]);
	}

	static Type ConvertType(mg_value_type type) {
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

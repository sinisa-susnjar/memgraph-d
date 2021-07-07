module mgclient;

extern (C) {
	const (char) *mg_client_version();
	int mg_init();
	void mg_finalize();

	enum mg_value_type {
		MG_VALUE_TYPE_NULL,
		MG_VALUE_TYPE_BOOL,
		MG_VALUE_TYPE_INTEGER,
		MG_VALUE_TYPE_FLOAT,
		MG_VALUE_TYPE_STRING,
		MG_VALUE_TYPE_LIST,
		MG_VALUE_TYPE_MAP,
		MG_VALUE_TYPE_NODE,
		MG_VALUE_TYPE_RELATIONSHIP,
		MG_VALUE_TYPE_UNBOUND_RELATIONSHIP,
		MG_VALUE_TYPE_PATH,
		MG_VALUE_TYPE_DATE,
		MG_VALUE_TYPE_TIME,
		MG_VALUE_TYPE_LOCAL_TIME,
		MG_VALUE_TYPE_DATE_TIME,
		MG_VALUE_TYPE_DATE_TIME_ZONE_ID,
		MG_VALUE_TYPE_LOCAL_DATE_TIME,
		MG_VALUE_TYPE_DURATION,
		MG_VALUE_TYPE_POINT_2D,
		MG_VALUE_TYPE_POINT_3D,
		MG_VALUE_TYPE_UNKNOWN
	}

	struct mg_value;
	struct mg_string;
	struct mg_list;
	struct mg_map;
	struct mg_node;
	struct mg_relationship;
	struct mg_unbound_relationship;
	struct mg_path;
	struct mg_date;
	struct mg_time;
	struct mg_local_time;
	struct mg_date_time;
	struct mg_date_time_zone_id;
	struct mg_local_date_time;
	struct mg_duration;
	struct mg_point_2d;
	struct mg_point_3d;

	mg_value *mg_value_make_null();
	mg_value *mg_value_make_bool(int val);
	mg_value *mg_value_make_integer(long val);
	mg_value *mg_value_make_float(double val);
	mg_value *mg_value_make_string(const char *str);
	mg_value *mg_value_make_string2(mg_string *str);
	mg_value *mg_value_make_list(mg_list *list);
	mg_value *mg_value_make_map(mg_map *map);
	mg_value *mg_value_make_node(mg_node *node);
	mg_value *mg_value_make_relationship(mg_relationship *rel);
	mg_value *mg_value_make_unbound_relationship(mg_unbound_relationship *rel);
	mg_value *mg_value_make_path(mg_path *path);
	mg_value *mg_value_make_date(mg_date *date);
	mg_value *mg_value_make_time(mg_time *time);
	mg_value *mg_value_make_local_time(mg_local_time *local_time);
	mg_value *mg_value_make_date_time(mg_date_time *date_time);
	mg_value *mg_value_make_date_time_zone_id(mg_date_time_zone_id *date_time_zone_id);
	mg_value *mg_value_make_local_date_time(mg_local_date_time *local_date_time);
	mg_value *mg_value_make_duration(mg_duration *duration);
	mg_value *mg_value_make_point_2d(mg_point_2d *point_2d);
	mg_value *mg_value_make_point_3d(mg_point_3d *point_3d);
	enum mg_value_type mg_value_get_type(const mg_value *val);
	int mg_value_bool(const mg_value *val);
	long mg_value_integer(const mg_value *val);
	double mg_value_float(const mg_value *val);
	const (mg_string) *mg_value_string(const mg_value *val);
	const (mg_list) *mg_value_list(const mg_value *val);
	const (mg_map) *mg_value_map(const mg_value *val);
	const (mg_node) *mg_value_node(const mg_value *val);
	const (mg_relationship) *mg_value_relationship(const mg_value *val);
	const (mg_unbound_relationship) *mg_value_unbound_relationship(const mg_value *val);
	const (mg_path) *mg_value_path(const mg_value *val);
	const (mg_date) *mg_value_date(const mg_value *val);
	const (mg_time) *mg_value_time(const mg_value *val);
	const (mg_local_time) *mg_value_local_time(const mg_value *val);
	const (mg_date_time) *mg_value_date_time(const mg_value *val);
	const (mg_date_time_zone_id) *mg_value_date_time_zone_id(const mg_value *val);
	const (mg_local_date_time) *mg_value_local_date_time(const mg_value *val);
	const (mg_duration) *mg_value_duration(const mg_value *val);
	const (mg_point_2d) *mg_value_point_2d(const mg_value *val);
	const (mg_point_3d) *mg_value_point_3d(const mg_value *val);
	mg_value *mg_value_copy(const mg_value *val);
	void mg_value_destroy(mg_value *val);
	mg_string *mg_string_make(const char *str);
	mg_string *mg_string_make2(uint len, const char *data);
	const (char) *mg_string_data(const mg_string *str);
	uint mg_string_size(const mg_string *str);
	mg_string *mg_string_copy(const mg_string *str);
	void mg_string_destroy(mg_string *str);
	mg_list *mg_list_make_empty(uint capacity);
	int mg_list_append(mg_list *list, mg_value *value);
	uint mg_list_size(const mg_list *list);
	const (mg_value) *mg_list_at(const mg_list *list, uint pos);
	mg_list *mg_list_copy(const mg_list *list);
	void mg_list_destroy(mg_list *list);
	mg_map *mg_map_make_empty(uint capacity);
	int mg_map_insert(mg_map *map, const char *key_str, mg_value *value);
	int mg_map_insert2(mg_map *map, mg_string *key, mg_value *value);
	int mg_map_insert_unsafe(mg_map *map, const char *key_str, mg_value *value);
	int mg_map_insert_unsafe2(mg_map *map, mg_string *key, mg_value *value);
	const (mg_value) *mg_map_at(const mg_map *map, const char *key_str);
	const (mg_value) *mg_map_at2(const mg_map *map, uint key_size, const char *key_data);
	uint mg_map_size(const mg_map *map);
	const (mg_string) *mg_map_key_at(const mg_map *, uint pos);
	const (mg_value) *mg_map_value_at(const mg_map *, uint pos);
	mg_map *mg_map_copy(const mg_map *map);
	void mg_map_destroy(mg_map *map);
	long mg_node_id(const mg_node *node);
	uint mg_node_label_count(const mg_node *node);
	const (mg_string) *mg_node_label_at(const mg_node *node, uint pos);
	const (mg_map) *mg_node_properties(const mg_node *node);
	mg_node *mg_node_copy(const mg_node *node);
	void mg_node_destroy(mg_node *node);
	long mg_relationship_id(const mg_relationship *rel);
	long mg_relationship_start_id(const mg_relationship *rel);
	long mg_relationship_end_id(const mg_relationship *rel);
	const (mg_string) *mg_relationship_type(const mg_relationship *rel);
	const (mg_map) *mg_relationship_properties(const mg_relationship *rel);
	mg_relationship *mg_relationship_copy(const mg_relationship *rel);
	void mg_relationship_destroy(mg_relationship *rel);
	long mg_unbound_relationship_id(const mg_unbound_relationship *rel);
	const (mg_string) *mg_unbound_relationship_type(const mg_unbound_relationship *rel);
	const (mg_map) *mg_unbound_relationship_properties(const mg_unbound_relationship *rel);
	mg_unbound_relationship *mg_unbound_relationship_copy(const mg_unbound_relationship *rel);
	void mg_unbound_relationship_destroy(mg_unbound_relationship *rel);
	uint mg_path_length(const mg_path *path);
	const (mg_node) *mg_path_node_at(const mg_path *path, uint pos);
	const (mg_unbound_relationship) *mg_path_relationship_at(const mg_path *path, uint pos);
	int mg_path_relationship_reversed_at(const mg_path *path, uint pos);
	mg_path *mg_path_copy(const mg_path *path);
	void mg_path_destroy(mg_path *path);
	long mg_date_days(const mg_date *date);
	mg_date *mg_date_copy(const mg_date *date);
	void mg_date_destroy(mg_date *date);
	long mg_time_nanoseconds(const mg_time *time);
	long mg_time_tz_offset_seconds(const mg_time *time);
	mg_time *mg_time_copy(const mg_time *time);
	void mg_time_destroy(mg_time *time);
	long mg_local_time_nanoseconds(const mg_local_time *local_time);
	mg_local_time *mg_local_time_copy(const mg_local_time *local_time);
	void mg_local_time_destroy(mg_local_time *local_time);
	long mg_date_time_seconds(const mg_date_time *date_time);
	long mg_date_time_nanoseconds(const mg_date_time *date_time);
	long mg_date_time_tz_offset_minutes(const mg_date_time *date_time);
	mg_date_time *mg_date_time_copy(const mg_date_time *date_time);
	void mg_date_time_destroy(mg_date_time *date_time);
	long mg_date_time_zone_id_seconds(const mg_date_time_zone_id *date_time_zone_id);
	long mg_date_time_zone_id_nanoseconds(const mg_date_time_zone_id *date_time_zone_id);
	long mg_date_time_zone_id_tz_id(const mg_date_time_zone_id *date_time_zone_id);
	mg_date_time_zone_id *mg_date_time_zone_id_copy(const mg_date_time_zone_id *date_time_zone_id);
	void mg_date_time_zone_id_destroy(mg_date_time_zone_id *date_time_zone_id);
	long mg_local_date_time_seconds(const mg_local_date_time *local_date_time);
	long mg_local_date_time_nanoseconds(const mg_local_date_time *local_date_time);
	mg_local_date_time *mg_local_date_time_copy(const mg_local_date_time *local_date_time);
	void mg_local_date_time_destroy(mg_local_date_time *local_date_time);
	long mg_duration_months(const mg_duration *duration);
	long mg_duration_days(const mg_duration *duration);
	long mg_duration_seconds(const mg_duration *duration);
	long mg_duration_nanoseconds(const mg_duration *duration);
	mg_duration *mg_duration_copy(const mg_duration *duration);
	void mg_duration_destroy(mg_duration *duration);
	long mg_point_2d_srid(const mg_point_2d *point_2d);
	double mg_point_2d_x(const mg_point_2d *point_2d);
	double mg_point_2d_y(const mg_point_2d *point_2d);
	mg_point_2d *mg_point_2d_copy(const mg_point_2d *point_2d);
	void mg_point_2d_destroy(mg_point_2d *point_2d);
	long mg_point_3d_srid(const mg_point_3d *point_3d);
	double mg_point_3d_x(const mg_point_3d *point_3d);
	double mg_point_3d_y(const mg_point_3d *point_3d);
	double mg_point_3d_z(const mg_point_3d *point_3d);
	mg_point_3d *mg_point_3d_copy(const mg_point_3d *point_3d);
	void mg_point_3d_destroy(mg_point_3d *point_3d);

	enum mg_session_code {
		MG_SESSION_READY = 0,
		MG_SESSION_EXECUTING = 1,
		MG_SESSION_BAD = 2,
		MG_SESSION_FETCHING = 3
	}

	enum mg_error {
		MG_SUCCESS = 0,
		MG_ERROR_SEND_FAILED = -1,
		MG_ERROR_RECV_FAILED = -2,
		MG_ERROR_OOM = -3,
		MG_ERROR_CONTAINER_FULL = -4,
		MG_ERROR_INVALID_VALUE = -5,
		MG_ERROR_DECODING_FAILED = -6,
		MG_ERROR_DUPLICATE_KEY = -7,
		MG_ERROR_NETWORK_FAILURE = -8,
		MG_ERROR_BAD_PARAMETER = -9,
		MG_ERROR_PROTOCOL_VIOLATION = -10,
		MG_ERROR_CLIENT_ERROR = -11,
		MG_ERROR_TRANSIENT_ERROR = -12,
		MG_ERROR_DATABASE_ERROR = -13,
		MG_ERROR_UNKNOWN_ERROR = -14,
		MG_ERROR_BAD_CALL = -15,
		MG_ERROR_SIZE_EXCEEDED = -16,
		MG_ERROR_SSL_ERROR = -17,
		MG_ERROR_TRUST_CALLBACK = -18,
		MG_ERROR_SOCKET = -100,
		MG_ERROR_UNIMPLEMENTED = -1000
	}

	enum mg_sslmode {
		MG_SSLMODE_DISABLE,
		MG_SSLMODE_REQUIRE,
	};

	struct mg_session;
	struct mg_session_params;
	alias mg_trust_callback_type = int function(const char *, const char *, const char *, const char *, void *);
	mg_session_params *mg_session_params_make();
	void mg_session_params_destroy(mg_session_params *);
	void mg_session_params_set_address(mg_session_params *, const char *address);
	void mg_session_params_set_host(mg_session_params *, const char *host);
	void mg_session_params_set_port(mg_session_params *, ushort port);
	void mg_session_params_set_username(mg_session_params *, const char *username);
	void mg_session_params_set_password(mg_session_params *, const char *password);
	void mg_session_params_set_user_agent(mg_session_params *, const char *user_agent);
	void mg_session_params_set_sslmode(mg_session_params *, mg_sslmode sslmode);
	void mg_session_params_set_sslcert(mg_session_params *, const char *sslcert);
	void mg_session_params_set_sslkey(mg_session_params *, const char *sslkey);
	void mg_session_params_set_trust_callback(mg_session_params *, mg_trust_callback_type trust_callback);
	void mg_session_params_set_trust_data(mg_session_params *, void *trust_data);
	const (char) *mg_session_params_get_address(const mg_session_params *);
	const (char) *mg_session_params_get_host(const mg_session_params *);
	ushort mg_session_params_get_port(const mg_session_params *);
	const (char) *mg_session_params_get_username(const mg_session_params *);
	const (char) *mg_session_params_get_password(const mg_session_params *);
	const (char) *mg_session_params_get_user_agent(const mg_session_params *);
	enum mg_sslmode mg_session_params_get_sslmode(const mg_session_params *);
	const (char) *mg_session_params_get_sslcert(const mg_session_params *);
	const (char) *mg_session_params_get_sslkey(const mg_session_params *);
	mg_trust_callback_type mg_session_params_get_trust_callback(const mg_session_params *params);
	void *mg_session_params_get_trust_data(const mg_session_params *);
	int mg_connect(const mg_session_params *params, mg_session **session);
	int mg_session_status(const mg_session *session);
	const (char) *mg_session_error(mg_session *session);
	void mg_session_destroy(mg_session *session);

	struct mg_result;
	int mg_session_run(mg_session *session, const char *query, const mg_map *params, const mg_map *extra_run_information, const mg_list **columns, long *qid);
	int mg_session_begin_transaction(mg_session *session, const mg_map *extra_run_information);
	int mg_session_commit_transaction(mg_session *session, mg_result **result);
	int mg_session_rollback_transaction(mg_session *session, mg_result **result);
	int mg_session_fetch(mg_session *session, mg_result **result);
	int mg_session_pull(mg_session *session, const mg_map *pull_information);
	const (mg_list) *mg_result_columns(const mg_result *result);
	const (mg_list) *mg_result_row(const mg_result *result);
	const (mg_map) *mg_result_summary(const mg_result *result);
}

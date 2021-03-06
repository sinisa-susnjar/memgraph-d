/// C API interface to the memgraph mgclient library.
///
/// Provides `mg_session`, a data type representing a connection to Bolt
/// server, along with functions for connecting to Bolt database and
/// executing queries against it, and `mg_value`, a data type representing a
/// value in Bolt protocol along with supporting types and manipulation
/// functions for them.
///
/// `mg_session` is an opaque data type representing a connection to Bolt
/// server. Commands can be submitted for execution using `mg_session_run`
/// and results can be obtained using `mg_session_pull`. A `mg_session`
/// can execute at most one command at a time, and all results should be
/// consumed before trying to execute the next query.
///
/// The usual flow for execution of a single query would be the following:
///
///  1. Submit the command for execution using `mg_session_run`.
///
///  2. Call `mg_session_pull` until it returns 0 to consume result rows and
///     access result values using `mg_result_row`.
///
///  3. If necessary, access command execution summary using `mg_result_summary`.
///
/// If any of the functions returns an error exit code, more detailed error
/// message can be obtained by calling `mg_session_error`.
///
/// `mg_value` is an opaque data type representing an arbitrary value of any
/// of the types specified by the Bolt protocol. It can encapsulate any of its
/// supporting types: `mg_string`, `mg_list`, `mg_map`, `mg_node`,
/// `mg_relationship`, `mg_unbound_relationship` and `mg_path`.
/// Provided along with them are basic manipulation functions for those data
/// types. The API for most of data types is quite rudimentary, and as such is
/// not usable for complex operations on strings, maps, lists, etc. It is only
/// supposed to be used to construct data to be sent to the Bolt server, and
/// read data obtained from the Bolt server.
///
/// Each object has a corresponding `mg_*_destroy` function that should be
/// invoked on the object at the end of its lifetime to free the resources
/// allocated for its storage. Each object has an owner, that is responsible for
/// its destruction. Object can be owned by the API client or by another
/// object. When being destroyed, an object will also destroy all other
/// objects it owns. Therefore, API client is only responsible for
/// destroying the object it directly owns. For example, if the API client
/// constructed a `mg_list` value and inserted some other `mg_value`
/// objects into it, they must only invoke `mg_list_destroy` on the list and
/// all of its members will be properly destroyed, because the list owns all of
/// its elements. Invoking `mg_*_destroy` on objects that are not owned by the
/// caller will usually result in memory corruption, double freeing, nuclear
/// apocalypse and similar unwanted behaviors. Therefore, object ownership
/// should be tracked carefully.
///
/// Invoking certain functions on objects might cause ownership changes.
/// Obviously, you shouldn't pass objects you don't own to functions that steal
/// ownership.
///
/// Function signatures are of big help in ownership tracking. Now follow two
/// simple rules, all functions that do not conform to those rules (if any) will
/// explicitly specify that in their documentation.
///
///  1. Return values
///
///     Functions that return a non-const pointer to an object give
///     ownership of the returned object to the caller. Examples are:
///       - creation functions (e.g. `mg_list_make_empty`).
///       - copy functions (e.g. `mg_value_copy`).
///       - `mg_connect` has a `mg_session **` output parameter because the
///         API client becomes the owner of the `mg_session` object
///
///     Functions that return a const pointer to a object provide
///     read-only access to the returned object that is valid only while the
///     owning object is alive. Examples are:
///       - access functions on `mg_value` (e.g. `mg_value_list`).
///       - member access functions on containers (e.g. `mg_map_key_at`,
///         `mg_list_at`, `mg_map_at`).
///       - field access functions on graph types (e.g. `mg_node_properties`).
///       - `mg_session_pull` has a `const mg_result **` output parameter,
///         because the `mg_session` object keeps ownership of the returned
///         result and destroys it on next pull
///
///  2. Function arguments
///
///     Functions that take a non-const pointer to a object either modify
///     it or change its ownership (it is usually obvious what happens).
///     Examples are:
///       - member insert functions on containers transfer the ownership of
///         inserted values to the container. They also take a non-const pointer
///         to the container because they modify it. Ownership of the container
///         is not changed (e.g. `mg_map_insert` takes ownership of the
///         passed key and value).
///      - `mg_session_run` takes a non-const pointer to the session because
///        it modifies it internal state, but there is no ownership change
///
///     An obvious exception here are `mg_*_destroy` functions which do not
///     change ownership of the object.
///
///     Functions that take a const pointer to a object do not change the
///     owner of the passed object nor they modify it. Examples are:
///       - member access functions on containers take const pointer to the
///         container (e.g. `mg_list_at`, `mg_map_at`, ...).
///       - member access functions on graph types take const pointer to the
///         container (e.g. `mg_path_node_at`, `mg_node_label_count`,
///         ...).
///       - copy functions.
module memgraph.mgclient;

/// Initializes the client (the whole process).
/// Module constructor used to initialise memgraph via a call to mg_init().
static this() {
  const rc = mg_init();
  assert(rc == mg_error.MG_SUCCESS);
}

/// Finalizes the client (the whole process).
/// Module destructor used to finalise memgraph via a call to mg_finalize().
static ~this() {
  mg_finalize();
}

extern (C) {
  /// Client software version.
  /// Return: Client version in the major.minor.patch format.
  @safe @nogc const (char) *mg_client_version() pure nothrow;

  /// Initializes the client (the whole process).
  /// Should be called at the beginning of each process using the client.
  /// Return: Zero if initialization was successful.
  @safe @nogc mg_error mg_init() pure nothrow;

  /// Finalizes the client (the whole process).
  /// Should be called at the end of each process using the client.
  @safe @nogc void mg_finalize() pure nothrow;

  /// An enum listing all the types as specified by Bolt protocol.
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

  /// A Bolt value, encapsulating all other values.
  version(unittest) {
    struct mg_value {
      mg_value_type type;
      union {
        int bool_v;
        long integer_v;
        double float_v;
        mg_string *string_v;
        mg_list *list_v;
        mg_map *map_v;
        mg_node *node_v;
        mg_relationship *relationship_v;
        mg_unbound_relationship *unbound_relationship_v;
        mg_path *path_v;
        mg_date *date_v;
        mg_time *time_v;
        mg_local_time *local_time_v;
        mg_date_time *date_time_v;
        mg_date_time_zone_id *date_time_zone_id_v;
        mg_local_date_time *local_date_time_v;
        mg_duration *duration_v;
        mg_point_2d *point_2d_v;
        mg_point_3d *point_3d_v;
      }
    }
  } else {
    struct mg_value;
  }

  /// An UTF-8 encoded string.
  ///
  /// Note that the length of the string is the byte count of the UTF-8 encoded
  /// data. It is guaranteed that the bytes of the string are stored contiguously,
  /// and they can be accessed through a pointer to first element returned by
  /// `mg_string_data`.
  ///
  /// Note that the library doesn't perform any checks whatsoever to see if the
  /// provided data is a valid UTF-8 encoded string when constructing instances of
  /// `mg_string`.
  ///
  /// Maximum possible string length allowed by Bolt protocol is `uint.max`.
  version(unittest) {
    struct mg_string {
      uint size;
      char *data;
    }
  } else {
    struct mg_string;
  }

  /// An ordered sequence of values.
  ///
  /// List may contain a mixture of different types as its elements. A list owns
  /// all values stored in it.
  ///
  /// Maximum possible list length allowed by Bolt is `uint.max`.
  version(unittest) {
    struct mg_list {
      uint size;
      uint capacity;
      mg_value **elements;
    }
  } else {
    struct mg_list;
  }

  /// Sized sequence of pairs of keys and values.
  ///
  /// Map may contain a mixture of different types as values. A map owns all keys
  /// and values stored in it.
  ///
  /// Maximum possible map size allowed by Bolt protocol is `uint.max`.
  version(unittest) {
    struct mg_map {
      uint size;
      uint capacity;
      mg_string **keys;
      mg_value **values;
    }
  } else {
    struct mg_map;
  }

  /// Represents a node from a labeled property graph.
  ///
  /// Consists of a unique identifier (withing the scope of its origin graph), a
  /// list of labels and a map of properties. A node owns its labels and
  /// properties.
  ///
  /// Maximum possible number of labels allowed by Bolt protocol is `uint.max`.
  version(unittest) {
    struct mg_node {
      long id;
      uint label_count;
      mg_string **labels;
      mg_map *properties;
    }
  } else {
    struct mg_node;
  }

  /// Represents a relationship from a labeled property graph.
  ///
  /// Consists of a unique identifier (within the scope of its origin graph),
  /// identifiers for the start and end nodes of that relationship, a type and a
  /// map of properties. A relationship owns its type string and property map.
  version(unittest) {
    struct mg_relationship {
      long id;
      long start_id;
      long end_id;
      mg_string *type;
      mg_map *properties;
    }
  } else {
    struct mg_relationship;
  }

  /// Represents a relationship from a labeled property graph.
  ///
  /// Like `mg_relationship`, but without identifiers for start and end nodes.
  /// Mainly used as a supporting type for `mg_path`. An unbound relationship
  /// owns its type string and property map.
  version(unittest) {
    struct mg_unbound_relationship {
      long id;
      mg_string *type;
      mg_map *properties;
    }
  } else {
    struct mg_unbound_relationship;
  }

  /// Represents a sequence of alternating nodes and relationships
  /// corresponding to a walk in a labeled property graph.
  ///
  /// A path of length L consists of L + 1 nodes indexed from 0 to L, and L
  /// unbound relationships, indexed from 0 to L - 1. Each relationship has a
  /// direction. A relationship is said to be reversed if it was traversed in the
  /// direction opposite of the direction of the underlying relationship in the
  /// data graph.
  version(unittest) {
    struct mg_path {
      uint node_count;
      uint relationship_count;
      uint sequence_length;
      mg_node **nodes;
      mg_unbound_relationship **relationships;
      long *sequence;
    }
  } else {
    struct mg_path;
  }

  /// Represents a date.
  ///
  /// Date is defined with number of days since the Unix epoch.
  version(unittest) {
    struct mg_date {
      long days;
    }
  } else {
    struct mg_date;
  }

  /// Represents time with its time zone.
  ///
  /// Time is defined with nanoseconds since midnight.
  /// Timezone is defined with seconds from UTC.
  version(unittest) {
    struct mg_time {
      long nanoseconds;
      long tz_offset_seconds;
    }
  } else {
    struct mg_time;
  }

  /// Represents local time.
  ///
  /// Time is defined with nanoseconds since midnight.
  version(unittest) {
    struct mg_local_time {
      long nanoseconds;
    }
  } else {
    struct mg_local_time;
  }

  /// Represents date and time with its time zone.
  ///
  /// Date is defined with seconds since the adjusted Unix epoch.
  /// Time is defined with nanoseconds since midnight.
  /// Time zone is defined with minutes from UTC.
  version(unittest) {
    struct mg_date_time {
      long seconds;
      long nanoseconds;
      long tz_offset_minutes;
    }
  } else {
    struct mg_date_time;
  }

  /// Represents date and time with its time zone.
  ///
  /// Date is defined with seconds since the adjusted Unix epoch.
  /// Time is defined with nanoseconds since midnight.
  /// Timezone is defined with an identifier for a specific time zone.
  version(unittest) {
    struct mg_date_time_zone_id {
      long seconds;
      long nanoseconds;
      long tz_id;
    }
  } else {
    struct mg_date_time_zone_id;
  }

  /// Represents date and time without its time zone.
  ///
  /// Date is defined with seconds since the Unix epoch.
  /// Time is defined with nanoseconds since midnight.
  version(unittest) {
    struct mg_local_date_time {
      long seconds;
      long nanoseconds;
    }
  } else {
    struct mg_local_date_time;
  }

  /// Represents a temporal amount which captures the difference in time
  /// between two instants.
  ///
  /// Duration is defined with months, days, seconds, and nanoseconds.
  /// Note: Duration can be negative.
  version(unittest) {
    struct mg_duration {
      long months;
      long days;
      long seconds;
      long nanoseconds;
    }
  } else {
    struct mg_duration;
  }

  /// Represents a single location in 2-dimensional space.
  ///
  /// Contains SRID along with its x and y coordinates.
  version(unittest) {
    struct mg_point_2d {
      long srid;
      double x;
      double y;
    }
  } else {
    struct mg_point_2d;
  }

  /// Represents a single location in 3-dimensional space.
  ///
  /// Contains SRID along with its x, y and z coordinates.
  version(unittest) {
    struct mg_point_3d {
      long srid;
      double x;
      double y;
      double z;
    }
  } else {
    struct mg_point_3d;
  }

  /// Constructs a nil `mg_value`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_null() pure nothrow;

  /// Constructs a boolean `mg_value`.
  ///
  /// Params: val = If the parameter is zero, constructed value will be false.
  ///               Otherwise, it will be true.
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_bool(int val) pure nothrow;

  /// Constructs an integer `mg_value` with the given underlying value.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_integer(long val) pure nothrow;

  /// Constructs a float `mg_value` with the given underlying value.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_float(double val) pure nothrow;

  /// Constructs a string `mg_value` given a null-terminated string.
  ///
  /// A new `mg_string` instance will be created from the null-terminated
  /// string as the underlying value.
  ///
  /// Params: str = A null-terminated UTF-8 string.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_string(const char *str) pure nothrow;

  /// Construct a string `mg_value` given the underlying `mg_string`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_string2(mg_string *str) pure nothrow;

  /// Constructs a list `mg_value` given the underlying `mg_list`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_list(mg_list *list) pure nothrow;

  /// Constructs a map `mg_value` given the underlying `mg_map`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_map(mg_map *map) pure nothrow;

  /// Constructs a node `mg_value` given the underlying `mg_node`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_node(mg_node *node) pure nothrow;

  /// Constructs a relationship `mg_value` given the underlying
  /// `mg_relationship`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_relationship(mg_relationship *rel) pure nothrow;

  /// Constructs an unbound relationship `mg_value` given the underlying
  /// `mg_unbound_relationship`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_unbound_relationship(mg_unbound_relationship *rel) pure nothrow;

  /// Constructs a path `mg_value` given the underlying `mg_path`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_path(mg_path *path) pure nothrow;

  /// Constructs a date `mg_value` given the underlying `mg_date`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_date(mg_date *date) pure nothrow;

  /// Constructs a time `mg_value` given the underlying `mg_time`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_time(mg_time *time) pure nothrow;

  /// Constructs a local time `mg_value` given the underlying `mg_local_time`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_local_time(mg_local_time *local_time) pure nothrow;

  /// Constructs a date and time `mg_value` given the underlying `mg_date_time`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_date_time(mg_date_time *date_time) pure nothrow;

  /// Constructs a date and time `mg_value` given the underlying `mg_date_time_zone_id`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_date_time_zone_id(mg_date_time_zone_id *date_time_zone_id) pure nothrow;

  /// Constructs a local date and time `mg_value` given the underlying `mg_local_date_time`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_local_date_time(mg_local_date_time *local_date_time) pure nothrow;

  /// Constructs a duration `mg_value` given the underlying `mg_duration`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_duration(mg_duration *duration) pure nothrow;

  /// Constructs a 2D point `mg_value` given the underlying `mg_point_2d`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_point_2d(mg_point_2d *point_2d) pure nothrow;

  /// Constructs a 3D point `mg_value` given the underlying `mg_point_3d`.
  ///
  /// Return: Pointer to the newly constructed value or NULL if error occurred.
  @safe @nogc mg_value *mg_value_make_point_3d(mg_point_3d *point_3d) pure nothrow;

  /// Returns the type of the given `mg_value`.
  @safe @nogc mg_value_type mg_value_get_type(const mg_value *val) pure nothrow;

  /// Returns non-zero value if value contains true, zero otherwise.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc bool mg_value_bool(const mg_value *val) pure nothrow;

  /// Returns the underlying integer value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc long mg_value_integer(const mg_value *val) pure nothrow;

  /// Returns the underlying float value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc double mg_value_float(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_string` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_string) *mg_value_string(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_list` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_list) *mg_value_list(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_map` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_map) *mg_value_map(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_node` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_node) *mg_value_node(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_relationship` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_relationship) *mg_value_relationship(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_unbound_relationship` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_unbound_relationship) *mg_value_unbound_relationship(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_path` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_path) *mg_value_path(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_date` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_date) *mg_value_date(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_time` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_time) *mg_value_time(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_local_time` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_local_time) *mg_value_local_time(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_date_time` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_date_time) *mg_value_date_time(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_date_time_zone_id` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_date_time_zone_id) *mg_value_date_time_zone_id(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_local_date_time` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_local_date_time) *mg_value_local_date_time(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_duration` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_duration) *mg_value_duration(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_point_2d` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_point_2d) *mg_value_point_2d(const mg_value *val) pure nothrow;

  /// Returns the underlying `mg_point_3d` value.
  ///
  /// Type check should be made first. Accessing the wrong value results in
  /// undefined behavior.
  @safe @nogc const (mg_point_3d) *mg_value_point_3d(const mg_value *val) pure nothrow;

  /// Creates a copy of the given value.
  ///
  /// Return: Pointer to the copy or NULL if error occurred.
  @safe @nogc mg_value *mg_value_copy(const mg_value *val) pure nothrow;

  /// Destroys the given value.
  @safe @nogc void mg_value_destroy(mg_value *val) pure nothrow;

  /// Constructs a string given a null-terminated string.
  ///
  /// A new buffer of appropriate length will be allocated and the given string
  /// will be copied there.
  ///
  /// Params: str = A null-terminated UTF-8 string.
  ///
  /// Return: A pointer to the newly constructed `mg_string` object or NULL
  ///         if an error occurred.
  @safe @nogc mg_string *mg_string_make(const char *str) pure nothrow;

  /// Constructs a string given its length (in bytes) and contents.
  ///
  /// A new buffer of will be allocated and the given data will be copied there.
  ///
  /// Params: len = Number of bytes in the data buffer.
  ///        data = The string contents.
  ///
  /// Return: A pointer to the newly constructed `mg_string` object or NULL
  ///         if an error occurred.
  @safe @nogc mg_string *mg_string_make2(uint len, const char *data) pure nothrow;

  /// Returns a pointer to the beginning of data buffer of string `str`.
  @safe @nogc const (char) *mg_string_data(const mg_string *str) pure nothrow;

  /// Returns the length (in bytes) of string `str`.
  @safe @nogc uint mg_string_size(const mg_string *str) pure nothrow;

  /// Creates a copy of the given string.
  ///
  /// Return: A pointer to the copy or NULL if an error occurred.
  @safe @nogc mg_string *mg_string_copy(const mg_string *str) pure nothrow;

  /// Destroys the given string.
  @safe @nogc void mg_string_destroy(mg_string *str) pure nothrow;

  /// Constructs a list that can hold at most `capacity` elements.
  ///
  /// Elements should be constructed and then inserted using `mg_list_append`.
  ///
  /// Params: capacity = The maximum number of elements that the newly constructed
  ///                 list can hold.
  ///
  /// Return: A pointer to the newly constructed empty list or NULL if an error
  ///         occurred.
  @safe @nogc mg_list *mg_list_make_empty(uint capacity) pure nothrow;

  /// Appends an element at the end of the list `list`.
  ///
  /// Insertion will fail if the list capacity is already exhausted. If the
  /// insertion fails, the map doesn't take ownership of `value`.
  ///
  /// Params: list = The list instance to be modified.
  ///        value = The value to be appended.
  ///
  /// Return: The function returns non-zero value if insertion failed, zero
  ///         otherwise.
  @safe @nogc mg_error mg_list_append(mg_list *list, mg_value *value) pure nothrow;

  /// Returns the number of elements in list `list`.
  @safe @nogc uint mg_list_size(const mg_list *list) pure nothrow;

  /// Retrieves the element at position `pos` in list `list`.
  ///
  /// Return: A pointer to required list element. If `pos` is outside of list
  ///         bounds, NULL is returned.
  @safe @nogc const (mg_value) *mg_list_at(const mg_list *list, uint pos) pure nothrow;

  /// Creates a copy of the given list.
  ///
  /// Return: A pointer to the copy or NULL if an error occurred.
  @safe @nogc mg_list *mg_list_copy(const mg_list *list) pure nothrow;

  /// Destroys the given list.
  @safe @nogc void mg_list_destroy(mg_list *list) pure nothrow;

  /// Constructs an empty map that can hold at most `capacity` key-value pairs.
  ///
  /// Key-value pairs should be constructed and then inserted using
  /// `mg_map_insert`, `mg_map_insert_unsafe` and similar.
  ///
  /// Params: capacity = The maximum number of key-value pairs that the newly
  ///                 constructed list can hold.
  ///
  /// Return: A pointer to the newly constructed empty map or NULL if an error
  ///         occurred.
  @safe @nogc mg_map *mg_map_make_empty(uint capacity) pure nothrow;

  /// Inserts the given key-value pair into the map.
  ///
  /// A check is performed to see if the given key is unique in the map which
  /// means that a number of key comparisons equal to the current number of
  /// elements in the map is made.
  ///
  /// If key length is greater that `uint.max`, or the key already exists in
  /// map, or the map's capacity is exhausted, the insertion will fail. If
  /// insertion fails, the map doesn't take ownership of `value`.
  ///
  /// If the insertion is successful, a new `mg_string` is constructed for
  /// the storage of the key and the map takes ownership of `value`.
  ///
  /// Params: map =   The map instance to be modifed.
  ///      key_str =  A null-terminated string to be used as key.
  ///         value = Value to be inserted.
  ///
  /// Return: The function returns non-zero value if insertion failed, zero
  ///         otherwise.
  @safe @nogc mg_error mg_map_insert(mg_map *map, const char *key_str, mg_value *value) pure nothrow;

  /// Inserts the given key-value pair into the map.
  ///
  /// A check is performed to see if the given key is unique in the map which
  /// means that a number of key comparisons equal to the current number of
  /// elements in the map is made.
  ///
  /// If the key already exists in map, or the map's capacity is exhausted, the
  /// insertion will fail. If insertion fails, the map doesn't take ownership of
  /// `key` and `value`.
  ///
  /// If the insertion is successful, map takes ownership of `key` and `value`.
  ///
  /// Params: map =   The map instance to be modifed.
  ///         key =   A `mg_string` to be used as key.
  ///        value =  Value to be inserted.
  ///
  /// Return: The function returns non-zero value if insertion failed, zero
  ///         otherwise.
  @safe @nogc int mg_map_insert2(mg_map *map, mg_string *key, mg_value *value) pure nothrow;

  /// Inserts the given key-value pair into the map.
  ///
  /// No check is performed for key uniqueness. Note that map containing duplicate
  /// keys is considered invalid in Bolt protocol.
  ///
  /// If key length is greated than `uint.max` or or the map's capacity is
  /// exhausted, the insertion will fail. If insertion fails, the map doesn't take
  /// ownership of `value`.
  ///
  /// If the insertion is successful, a new `mg_string` is constructed for the
  /// storage of the key and the map takes ownership of `value`.
  ///
  /// Params: map =  The map instance to be modifed.
  ///      key_str = A null-terminated string to be used as key.
  ///        value = Value to be inserted.
  ///
  /// Return: The function returns non-zero value if insertion failed, zero
  ///         otherwise.
  @safe @nogc int mg_map_insert_unsafe(mg_map *map, const char *key_str, mg_value *value) pure nothrow;

  /// Inserts the given key-value pair into the map.
  ///
  /// No check is performed for key uniqueness. Note that map containing duplicate
  /// keys is considered invalid in Bolt protocol.
  ///
  /// If the map's capacity is exhausted, the insertion will fail. If insertion
  /// fails, the map doesn't take ownership of `key` and `value`.
  ///
  /// If the insertion is successful, map takes ownership of `key` and `value`.
  ///
  /// Params:  map = The map instance to be modifed.
  ///          key = A `mg_string` to be used as key.
  ///        value = Value to be inserted.
  ///
  /// Return: The function returns non-zero value if insertion failed, zero
  ///         otherwise.
  @safe @nogc int mg_map_insert_unsafe2(mg_map *map, mg_string *key, mg_value *value) pure nothrow;

  /// Looks up a map value with the given key.
  ///
  /// Params: map =  The map instance to be queried.
  ///      key_str = A null-terminated string representing the key to be looked-up
  ///                in the map.
  ///
  /// Return: If the key is found in the map, the pointer to the corresponding
  ///         `mg_value` is returned. Otherwise, NULL is returned.
  @safe @nogc const (mg_value) *mg_map_at(const mg_map *map, const char *key_str) pure nothrow;

  /// Looks up a map value with the given key.
  ///
  /// Params: map =   The map instance to be queried.
  ///      key_size = The length of the string representing the key to be
  ///                 looked-up in the map.
  ///      key_data = Bytes constituting the key string.
  ///
  /// Return: If the key is found in the map, the pointer to the corresponding
  ///         `mg_value` is returned. Otherwise, NULL is returned.
  @safe @nogc const (mg_value) *mg_map_at2(const mg_map *map, uint key_size, const char *key_data) pure nothrow;

  /// Returns the number of key-value pairs in map `map`.
  @safe @nogc uint mg_map_size(const mg_map *map) pure nothrow;

  /// Retrieves the key at position `pos` in map `map`.
  ///
  /// Return: A pointer to required key. If `pos` is outside of map bounds,
  ///         NULL is returned.
  @safe @nogc const (mg_string) *mg_map_key_at(const mg_map *, uint pos) pure nothrow;

  /// Retrieves the value at position `pos` in map `map`.
  ///
  /// Return: A pointer to required value. If `pos` is outside of map bounds,
  ///         NULL is returned.
  @safe @nogc const (mg_value) *mg_map_value_at(const mg_map *, uint pos) pure nothrow;

  /// Creates a copy of the given map.
  ///
  /// Return: A pointer to the copy or NULL if an error occurred.
  @safe @nogc mg_map *mg_map_copy(const mg_map *map) pure nothrow;

  /// Destroys the given map.
  @safe @nogc void mg_map_destroy(mg_map *map) pure nothrow;

  /// Constructs a new mg_node with node id `id`, and `labelCount` labels given in `labels`.
  /// Note: the new node takes ownership of the `properties` mg_map.
  /// Return: A pointer to the new node or null if an error occurred.
  @safe @nogc mg_node *mg_node_make(int id, uint labelCount, mg_string **labels, mg_map *properties) pure nothrow;

  /// Returns the ID of node `node`.
  @safe @nogc long mg_node_id(const mg_node *node) pure nothrow;

  /// Returns the number of labels of node `node`.
  @safe @nogc uint mg_node_label_count(const mg_node *node) pure nothrow;

  /// Returns the label at position `pos` in node `node`'s label list.
  ///
  /// Return: A pointer to the required label. If `pos` is outside of label list
  ///         bounds, NULL is returned.
  @safe @nogc const (mg_string) *mg_node_label_at(const mg_node *node, uint pos) pure nothrow;

  /// Returns property map of node `node`.
  @safe @nogc const (mg_map) *mg_node_properties(const mg_node *node) pure nothrow;

  /// Creates a copy of the given node.
  ///
  /// Return: A pointer to the copy or NULL if an error occurred.
  @safe @nogc mg_node *mg_node_copy(const mg_node *node) pure nothrow;

  /// Destroys the given node.
  @safe @nogc void mg_node_destroy(mg_node *node) pure nothrow;

  /// Creates a new relationship with the given parameters.
  @safe @nogc mg_relationship *mg_relationship_make(long id, long start_id,
                                      long end_id, mg_string *type,
                                      mg_map *properties) pure nothrow;

  /// Returns the ID of the relationship `rel`.
  @safe @nogc long mg_relationship_id(const mg_relationship *rel) pure nothrow;

  /// Returns the ID of the start node of relationship `rel`.
  @safe @nogc long mg_relationship_start_id(const mg_relationship *rel) pure nothrow;

  /// Returns the ID of the end node of relationship `rel`.
  @safe @nogc long mg_relationship_end_id(const mg_relationship *rel) pure nothrow;

  /// Returns the type of the relationship `rel`.
  @safe @nogc const (mg_string) *mg_relationship_type(const mg_relationship *rel) pure nothrow;

  /// Returns the property map of the relationship `rel`.
  @safe @nogc const (mg_map) *mg_relationship_properties(const mg_relationship *rel) pure nothrow;

  /// Creates a copy of the given relationship.
  ///
  /// Return: A pointer to the copy or NULL if an error occurred.
  @safe @nogc mg_relationship *mg_relationship_copy(const mg_relationship *rel) pure nothrow;

  /// Destroys the given relationship.
  @safe @nogc void mg_relationship_destroy(mg_relationship *rel) pure nothrow;

  /// Creates a new unbound relationship with the given parameters.
  @safe @nogc mg_unbound_relationship *mg_unbound_relationship_make(long id,
                                                      mg_string *type,
                                                      mg_map *properties) pure nothrow;

  /// Returns the ID of the unbound relationship `rel`.
  @safe @nogc long mg_unbound_relationship_id(const mg_unbound_relationship *rel) pure nothrow;

  /// Returns the type of the unbound relationship `rel`.
  @safe @nogc const (mg_string) *mg_unbound_relationship_type(const mg_unbound_relationship *rel) pure nothrow;

  /// Returns the property map of the unbound relationship `rel`.
  @safe @nogc const (mg_map) *mg_unbound_relationship_properties(const mg_unbound_relationship *rel) pure nothrow;

  /// Creates a copy of the given unbound relationship.
  ///
  /// Return: A pointer to the copy or NULL if an error occurred.
  @safe @nogc mg_unbound_relationship *mg_unbound_relationship_copy(const mg_unbound_relationship *rel) pure nothrow;

  /// Destroys the given unbound relationship.
  @safe @nogc void mg_unbound_relationship_destroy(mg_unbound_relationship *rel) pure nothrow;

  /// Create a new mg_path from the given parameters.
  @safe @nogc mg_path *mg_path_make(uint node_count, mg_node **nodes,
                                    uint relationship_count,
                                    mg_unbound_relationship **relationships,
                                    uint sequence_length, const long *sequence) pure nothrow;

  /// Returns the length (the number of edges) of path `path`.
  @safe @nogc uint mg_path_length(const mg_path *path) pure nothrow;

  /// Returns the node at position `pos` in the traversal of path `path`.
  ///
  /// Nodes are indexed from 0 to path length.
  ///
  /// Return: A pointer to the required node. If `pos` is out of path bounds,
  ///         NULL is returned.
  @safe @nogc const (mg_node) *mg_path_node_at(const mg_path *path, uint pos) pure nothrow;

  /// Returns the relationship at position `pos` in traversal of path `path`.
  ///
  /// Relationships are indexed from 0 to path length - 1.
  ///
  /// Return: A pointer to the required relationship. If `pos` is outside of
  ///         path bounds, NULL is returned.
  @safe @nogc const (mg_unbound_relationship) *mg_path_relationship_at(const mg_path *path, uint pos) pure nothrow;

  /// Checks if the relationship at position `pos` in traversal of path `path`
  /// is reversed.
  ///
  /// Relationships are indexed from 0 to path length - 1.
  ///
  /// Return: Returns 0 if relationships is traversed in the same direction as the
  ///         underlying relationship in the data graph, and 1 if it is traversed
  ///         in the opposite direction. If `pos` is outside of path bounds, -1
  ///         is returned.
  @safe @nogc int mg_path_relationship_reversed_at(const mg_path *path, uint pos) pure nothrow;

  /// Creates a copy of the given path.
  ///
  /// Return: A pointer to the copy or NULL if an error occurred.
  @safe @nogc mg_path *mg_path_copy(const mg_path *path) pure nothrow;

  /// Destroys the given path.
  @safe @nogc void mg_path_destroy(mg_path *path) pure nothrow;

  /// Creates a `mg_date` from the given number of days since the Unix epoch.
  /// Return: A pointer to a newly allocated mg_date or `null` if an error occurred.
  @safe @nogc mg_date *mg_date_make(long days) pure nothrow;

  /// Returns days since the Unix epoch.
  @safe @nogc long mg_date_days(const mg_date *date) pure nothrow;

  /// Creates a copy of the given date.
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_date *mg_date_copy(const mg_date *date) pure nothrow;

  /// Destroys the given date.
  @safe @nogc void mg_date_destroy(mg_date *date) pure nothrow;

  /// Returns nanoseconds since midnight.
  @safe @nogc long mg_time_nanoseconds(const mg_time *time) pure nothrow;

  /// Returns time zone offset in seconds from UTC.
  @safe @nogc long mg_time_tz_offset_seconds(const mg_time *time) pure nothrow;

  /// Creates a copy of the given time.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_time *mg_time_copy(const mg_time *time) pure nothrow;

  /// Destroys the given time.
  @safe @nogc void mg_time_destroy(mg_time *time) pure nothrow;

  /// Creates a `mg_local_time` from nanoseconds.
  /// Return: A pointer to `mg_local_time` or `null` if an error occurred.
  @safe @nogc mg_local_time *mg_local_time_make(long nanoseconds) pure nothrow;

  /// Returns nanoseconds since midnight.
  @safe @nogc long mg_local_time_nanoseconds(const mg_local_time *local_time) pure nothrow;

  /// Creates a copy of the given local time.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_local_time *mg_local_time_copy(const mg_local_time *local_time) pure nothrow;

  /// Destroys the given local time.
  @safe @nogc void mg_local_time_destroy(mg_local_time *local_time) pure nothrow;

  /// Creates a `mg_date_time` from the given `seconds`, `nanoseconds` and `tz_offset_minutes`.
  /// Return: A pointer to a mg_date_time or `null` if an error occurred.
  @safe @nogc mg_date_time *mg_date_time_make(long seconds, long nanoseconds, long tz_offset_minutes) pure nothrow;

  /// Returns seconds since Unix epoch.
  @safe @nogc long mg_date_time_seconds(const mg_date_time *date_time) pure nothrow;

  /// Returns nanoseconds since midnight.
  @safe @nogc long mg_date_time_nanoseconds(const mg_date_time *date_time) pure nothrow;

  /// Returns time zone offset in minutes from UTC.
  @safe @nogc long mg_date_time_tz_offset_minutes(const mg_date_time *date_time) pure nothrow;

  /// Creates a copy of the given date and time.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_date_time *mg_date_time_copy(const mg_date_time *date_time) pure nothrow;

  /// Destroys the given date and time.
  @safe @nogc void mg_date_time_destroy(mg_date_time *date_time) pure nothrow;

  /// Returns seconds since Unix epoch.
  @safe @nogc long mg_date_time_zone_id_seconds(const mg_date_time_zone_id *date_time_zone_id) pure nothrow;

  /// Returns nanoseconds since midnight.
  @safe @nogc long mg_date_time_zone_id_nanoseconds(const mg_date_time_zone_id *date_time_zone_id) pure nothrow;

  /// Returns time zone represented by the identifier.
  @safe @nogc long mg_date_time_zone_id_tz_id(const mg_date_time_zone_id *date_time_zone_id) pure nothrow;

  /// Creates a copy of the given date and time.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_date_time_zone_id *mg_date_time_zone_id_copy(const mg_date_time_zone_id *date_time_zone_id)
                          pure nothrow;

  /// Destroys the given date and time.
  @safe @nogc void mg_date_time_zone_id_destroy(mg_date_time_zone_id *date_time_zone_id) pure nothrow;

  /// Creates a `mg_local_date_time` from seconds and nanoseconds.
  /// Return: A pointer to `mg_local_date_time` or `null` if an error occurred.
  @safe @nogc mg_local_date_time *mg_local_date_time_make(long seconds, long nanoseconds) pure nothrow;

  /// Returns seconds since Unix epoch.
  @safe @nogc long mg_local_date_time_seconds(const mg_local_date_time *local_date_time) pure nothrow;

  /// Returns nanoseconds since midnight.
  @safe @nogc long mg_local_date_time_nanoseconds(const mg_local_date_time *local_date_time) pure nothrow;

  /// Creates a copy of the given local date and time.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_local_date_time *mg_local_date_time_copy(const mg_local_date_time *local_date_time) pure nothrow;

  /// Destroy the given local date and time.
  @safe @nogc void mg_local_date_time_destroy(mg_local_date_time *local_date_time) pure nothrow;

  /// Creates a `mg_duration` from the given months, days, seconds and nanoseconds.
  /// Return: A pointer to a newly allocated `mg_duration` or `null` if an error occurred.
  @safe @nogc mg_duration *mg_duration_make(long months, long days,
                                              long seconds,
                                              long nanoseconds) pure nothrow;

  /// Returns the months part of the temporal amount.
  @safe @nogc long mg_duration_months(const mg_duration *duration) pure nothrow;

  /// Returns the days part of the temporal amount.
  @safe @nogc long mg_duration_days(const mg_duration *duration) pure nothrow;

  /// Returns the seconds part of the temporal amount.
  @safe @nogc long mg_duration_seconds(const mg_duration *duration) pure nothrow;

  /// Returns the nanoseconds part of the temporal amount.
  @safe @nogc long mg_duration_nanoseconds(const mg_duration *duration) pure nothrow;

  /// Creates a copy of the given duration.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_duration *mg_duration_copy(const mg_duration *duration) pure nothrow;

  /// Destroy the given duration.
  @safe @nogc void mg_duration_destroy(mg_duration *duration) pure nothrow;

  /// Returns SRID of the 2D point.
  @safe @nogc long mg_point_2d_srid(const mg_point_2d *point_2d) pure nothrow;

  /// Returns the x coordinate of the 2D point.
  @safe @nogc double mg_point_2d_x(const mg_point_2d *point_2d) pure nothrow;

  /// Returns the y coordinate of the 2D point.
  @safe @nogc double mg_point_2d_y(const mg_point_2d *point_2d) pure nothrow;

  /// Creates a copy of the given 2D point.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_point_2d *mg_point_2d_copy(const mg_point_2d *point_2d) pure nothrow;

  /// Destroys the given 2D point.
  @safe @nogc void mg_point_2d_destroy(mg_point_2d *point_2d) pure nothrow;

  /// Returns SRID of the 3D point.
  @safe @nogc long mg_point_3d_srid(const mg_point_3d *point_3d) pure nothrow;

  /// Returns the x coordinate of the 3D point.
  @safe @nogc double mg_point_3d_x(const mg_point_3d *point_3d) pure nothrow;

  /// Returns the y coordinate of the 3D point.
  @safe @nogc double mg_point_3d_y(const mg_point_3d *point_3d) pure nothrow;

  /// Returns the z coordinate of the 3D point.
  @safe @nogc double mg_point_3d_z(const mg_point_3d *point_3d) pure nothrow;

  /// Creates a copy of the given 3D point.
  ///
  /// Return: A pointer to the copy or NULL if an error occured.
  @safe @nogc mg_point_3d *mg_point_3d_copy(const mg_point_3d *point_3d) pure nothrow;

  /// Destroys the given 3D point.
  @safe @nogc void mg_point_3d_destroy(mg_point_3d *point_3d) pure nothrow;

  /// Return codes for `mg_session_status`.
  enum mg_session_code {
    /// Marks a `mg_session` ready to execute a new query using `mg_session_run`.
    MG_SESSION_READY = 0,
    /// Marks a `mg_session` which is currently executing a query. Results can be
    /// pulled using `mg_session_pull`.
    MG_SESSION_EXECUTING = 1,
    /// Marks a bad `mg_session` which cannot be used to execute queries and can
    /// only be destroyed.
    MG_SESSION_BAD = 2,
    /// Marks a `mg_session` which is currently fetching result of a query.
    /// Results can be fetched using `mg_session_fetch`.
    MG_SESSION_FETCHING = 3
  }

  /// Return codes used by mgclient functions.
  enum mg_error {
    /// Success code.
    MG_SUCCESS = 0,
    /// Failed to send data to server.
    MG_ERROR_SEND_FAILED = -1,
    /// Failed to receive data from server.
    MG_ERROR_RECV_FAILED = -2,
    /// Out of memory.
    MG_ERROR_OOM = -3,
    /// Trying to insert more values in a full container.
    MG_ERROR_CONTAINER_FULL = -4,
    /// Invalid value type was given as a function argument.
    MG_ERROR_INVALID_VALUE = -5,
    /// Failed to decode data returned from server.
    MG_ERROR_DECODING_FAILED = -6,
    /// Trying to insert a duplicate key in map.
    MG_ERROR_DUPLICATE_KEY = -7,
    /// An error occurred while trying to connect to server.
    MG_ERROR_NETWORK_FAILURE = -8,
    /// Invalid parameter supplied to `mg_connect`.
    MG_ERROR_BAD_PARAMETER = -9,
    /// Server violated the Bolt protocol by sending an invalid message type or
    /// invalid value.
    MG_ERROR_PROTOCOL_VIOLATION = -10,
    /// Server sent a FAILURE message containing ClientError code.
    MG_ERROR_CLIENT_ERROR = -11,
    /// Server sent a FAILURE message containing TransientError code.
    MG_ERROR_TRANSIENT_ERROR = -12,
    /// Server sent a FAILURE message containing DatabaseError code.
    MG_ERROR_DATABASE_ERROR = -13,
    /// Got an unknown error message from server.
    MG_ERROR_UNKNOWN_ERROR = -14,
    /// Invalid usage of the library.
    MG_ERROR_BAD_CALL = -15,
    /// Maximum container size allowed by Bolt exceeded.
    MG_ERROR_SIZE_EXCEEDED = -16,
    /// An error occurred during SSL connection negotiation.
    MG_ERROR_SSL_ERROR = -17,
    /// User provided trust callback returned a non-zeron value after SSL connection
    /// negotiation.
    MG_ERROR_TRUST_CALLBACK = -18,
    /// Unable to initialize the socket (both create and connect).
    MG_ERROR_SOCKET = -100,
    /// Function unimplemented.
    MG_ERROR_UNIMPLEMENTED = -1000
  }

  /// Determines whether a secure SSL TCP/IP connection will be negotiated with
  /// the server.
  enum mg_sslmode {
    /// Only try a non-SSL connection.
    MG_SSLMODE_DISABLE,
    /// Only try a SSL connection.
    MG_SSLMODE_REQUIRE,
  }

  /// An object encapsulating a Bolt session.
  struct mg_session;

  /// An object containing parameters for `mg_connect`.
  ///
  /// Currently recognized parameters are:
  ///  - host
  ///
  ///      DNS resolvable name of host to connect to. Exactly one of host and
  ///      address parameters must be specified.
  ///
  ///  - address
  ///
  ///      Numeric IP address of host to connect to. This should be in the
  ///      standard IPv4 address format. You can also use IPv6 if your machine
  ///      supports it. Exactly one of host and address parameters must be
  ///      specified.
  ///
  ///  - port
  ///
  ///      Port number to connect to at the server host.
  ///
  ///  - username
  ///
  ///      Username to connect as.
  ///
  ///  - password
  ///
  ///      Password to be used if the server demands password authentication.
  ///
  ///  - user_agent
  ///
  ///      Alternate name and version of the client to send to server. Default is
  ///      "MemgraphBolt/0.1".
  ///
  ///  - sslmode
  ///
  ///      This option determines whether a secure connection will be negotiated
  ///      with the server. There are 2 possible values:
  ///
  ///      - `MG_SSLMODE_DISABLE`
  ///
  ///        Only try a non-SSL connection (default).
  ///
  ///      - `MG_SSLMODE_REQUIRE`
  ///
  ///        Only try an SSL connection.
  ///
  ///  - sslcert
  ///
  ///      This parameter specifies the file name of the client SSL certificate.
  ///      It is ignored in case an SSL connection is not made.
  ///
  ///  - sslkey
  ///
  ///     This parameter specifies the location of the secret key used for the
  ///     client certificate. This parameter is ignored in case an SSL connection
  ///     is not made.
  ///
  ///  - trust_callback
  ///
  ///     A pointer to a function of prototype:
  ///        int trust_callback(const char *hostname, const char *ip_address,
  ///                           const char *key_type, const char *fingerprint,
  ///                           void *trust_data);
  ///
  ///     After performing the SSL handshake, `mg_connect` will call this
  ///     function providing the hostname, IP address, public key type and
  ///     fingerprint and user provided data. If the function returns a non-zero
  ///     value, SSL connection will be immediately terminated. This can be used
  ///     to implement TOFU (trust on first use) mechanism.
  ///     It might happen that hostname can not be determined, in that case the
  ///     trust callback will be called with hostname="undefined".
  ///
  ///  - trust_data
  ///
  ///    Additional data that will be provided to trust_callback function.
  struct mg_session_params;

  /// Prototype of the callback function for verifying an SSL connection by user.
  alias mg_trust_callback_type = int function(const char *, const char *, const char *, const char *, void *);

  /// Creates a new `mg_session_params` object.
  @safe @nogc mg_session_params *mg_session_params_make() pure nothrow;

  /// Destroys a `mg_session_params` object.
  @safe @nogc void mg_session_params_destroy(mg_session_params *) pure nothrow;

  /// Getters and setters for `mg_session_params` values.
  @safe @nogc void mg_session_params_set_address(mg_session_params *, const char *address) pure nothrow;
  @safe @nogc void mg_session_params_set_host(mg_session_params *, const char *host) pure nothrow;
  @safe @nogc void mg_session_params_set_port(mg_session_params *, ushort port) pure nothrow;
  @safe @nogc void mg_session_params_set_username(mg_session_params *, const char *username) pure nothrow;
  @safe @nogc void mg_session_params_set_password(mg_session_params *, const char *password) pure nothrow;
  @safe @nogc void mg_session_params_set_user_agent(mg_session_params *, const char *user_agent) pure nothrow;
  @safe @nogc void mg_session_params_set_sslmode(mg_session_params *, mg_sslmode sslmode) pure nothrow;
  @safe @nogc void mg_session_params_set_sslcert(mg_session_params *, const char *sslcert) pure nothrow;
  @safe @nogc void mg_session_params_set_sslkey(mg_session_params *, const char *sslkey) pure nothrow;
  @safe @nogc void mg_session_params_set_trust_callback(mg_session_params *,
                                    mg_trust_callback_type trust_callback) pure nothrow;
  @safe @nogc void mg_session_params_set_trust_data(mg_session_params *, void *trust_data) pure nothrow;
  @safe @nogc const (char) *mg_session_params_get_address(const mg_session_params *) pure nothrow;
  @safe @nogc const (char) *mg_session_params_get_host(const mg_session_params *) pure nothrow;
  @safe @nogc ushort mg_session_params_get_port(const mg_session_params *) pure nothrow;
  @safe @nogc const (char) *mg_session_params_get_username(const mg_session_params *) pure nothrow;
  @safe @nogc const (char) *mg_session_params_get_password(const mg_session_params *) pure nothrow;
  @safe @nogc const (char) *mg_session_params_get_user_agent(const mg_session_params *) pure nothrow;
  @safe @nogc mg_sslmode mg_session_params_get_sslmode(const mg_session_params *) pure nothrow;
  @safe @nogc const (char) *mg_session_params_get_sslcert(const mg_session_params *) pure nothrow;
  @safe @nogc const (char) *mg_session_params_get_sslkey(const mg_session_params *) pure nothrow;
  @safe @nogc mg_trust_callback_type mg_session_params_get_trust_callback(const mg_session_params *params) pure nothrow;
  @safe @nogc void *mg_session_params_get_trust_data(const mg_session_params *) pure nothrow;

  /// Makes a new connection to the database server.
  ///
  /// This function opens a new database connection using the parameters specified
  /// in provided `params` argument.
  ///
  /// Params:  params = New Bolt connection parameters. See documentation for
  ///                     `mg_session_params`.
  ///         session = A pointer to a newly created `mg_session` is written
  ///                     here, unless there wasn't enough memory to allocate a
  ///                     `mg_session` object. In that case, it is set to NULL.
  ///
  /// Return: Returns 0 if connected successfuly, otherwise returns a non-zero
  ///         error code. A more detailed error message can be obtained by using
  ///         `mg_session_error` on `session`, unless it is set to NULL.
  @safe @nogc int mg_connect(const mg_session_params *params, mg_session **session) pure nothrow;

  /// Returns the status of `mg_session`.
  ///
  /// Return: One of the session codes in `mg_session_code`.
  @safe @nogc mg_session_code mg_session_status(const mg_session *session) pure nothrow;

  /// Obtains the error message stored in `mg_session` (if any).
  @safe @nogc const (char) *mg_session_error(mg_session *session) pure nothrow;

  /// Destroys a `mg_session` and releases all of its resources.
  @safe @nogc void mg_session_destroy(mg_session *session) pure nothrow;

  /// An object encapsulating a single result row or query execution summary. Its
  /// lifetime is limited by lifetime of parent `mg_session`. Also, invoking
  /// `mg_session_pull` ends the lifetime of previously returned `mg_result`.
  struct mg_result;

  /// Submits a query to the server for execution.
  ///
  /// All records from the previous query must be pulled before executing the
  /// next query.
  ///
  /// Params: session =             A `mg_session` to be used for query execution.
  ///         query =               Query string.
  ///         params =              A `mg_map` containing query parameters. NULL
  ///                              can be supplied instead of an empty parameter
  ///                              map.
  ///         columns =            Names of the columns output by the query
  ///                              execution will be stored in here. This is the
  ///                              same as the value
  ///                              obtained by `mg_result_columns` on a pulled
  ///                              `mg_result`. NULL can be supplied if we're
  ///                              not interested in the columns names.
  ///      extra_run_information = A `mg_map` containing extra information for
  ///                              running the statement.
  ///                              It can contain the following information:
  ///                               - bookmarks - list of strings containing some
  ///                               kind of bookmark identification
  ///                               - tx_timeout - integer that specifies a
  ///                               transaction timeout in ms.
  ///                               - tx_metadata - dictionary taht can contain
  ///                               some metadata information, mainly used for
  ///                               logging.
  ///                               - mode - specifies what kind of server is the
  ///                               run targeting. For write access use "w" and
  ///                               for read access use "r". Defaults to write
  ///                               access.
  ///                               - db - specifies the database name for
  ///                               multi-database to select where the transaction
  ///                               takes place. If no `db` is sent or empty
  ///                               string it implies that it is the default
  ///                               database.
  ///            qid =              QID for the statement will be stored in here
  ///                               if an Explicit transaction was started.
  /// Return: Returns 0 if query was submitted for execution successfuly.
  ///         Otherwise, a non-zero error code is returned.
  @safe @nogc mg_error mg_session_run(mg_session *session, const char *query, const mg_map *params,
                            const mg_map *extra_run_information, const mg_list **columns, long *qid) pure nothrow;

  /// Starts an Explicit transaction on the server.
  ///
  /// Every run will be part of that transaction until its explicitly ended.
  ///
  /// Params: session =              A `mg_session` on which the transaction should be started.
  ///       extra_run_information  = A `mg_map` containing extra information that will be used
  ///                                 for every statement that is ran as part of the transaction.
  ///                              It can contain the following information:
  ///                               - bookmarks - list of strings containing some
  ///                               kind of bookmark identification
  ///                               - tx_timeout - integer that specifies a
  ///                               transaction timeout in ms.
  ///                               - tx_metadata - dictionary taht can contain
  ///                               some metadata information, mainly used for
  ///                               logging.
  ///                               - mode - specifies what kind of server is the
  ///                               run targeting. For write access use "w" and
  ///                               for read access use "r". Defaults to write
  ///                               access.
  ///                               - db - specifies the database name for
  ///                               multi-database to select where the transaction
  ///                               takes place. If no `db` is sent or empty
  ///                               string it implies that it is the default
  ///                               database.
  /// Return: Returns 0 if the transaction was started successfully.
  ///         Otherwise, a non-zero error code is returned.
  @safe @nogc mg_error mg_session_begin_transaction(mg_session *session,
                                            const mg_map *extra_run_information) pure nothrow;

  /// Commits current Explicit transaction.
  ///
  /// Params: session = A `mg_session` on which the transaction should be committed.
  ///         result =  Contains the information about the committed transaction
  ///                   if it was successful.
  /// Return: Returns 0 if the transaction was ended successfully.
  ///         Otherwise, a non-zero error code is returned.
  @safe @nogc mg_error mg_session_commit_transaction(mg_session *session, mg_result **result) pure nothrow;

  /// Rollbacks current Explicit transaction.
  ///
  /// Params: session = A `mg_session` on which the transaction should be rolled back.
  ///         result =  Contains the information about the rolled back transaction
  ///                   if it was successful.
  /// Return: Returns 0 if the transaction was ended successfully.
  ///         Otherwise, a non-zero error code is returned.
  @safe @nogc mg_error mg_session_rollback_transaction(mg_session *session, mg_result **result) pure nothrow;

  /// Tries to fetch the next query result from `mg_session`.
  ///
  /// The owner of the returned result is `mg_session` `session`, and the
  /// result is destroyed on next call to `mg_session_fetch`.
  ///
  /// Return: On success, 0 or 1 is returned. Exit code 1 means that a new result
  ///         row was obtained and stored in `result` and its contents may be
  ///         accessed using `mg_result_row`. Exit code 0 means that there are
  ///         no more result rows and that the query execution summary was stored
  ///         in `result`. Its contents may be accessed using `mg_result_summary`.
  ///         On failure, a non-zero exit code is returned.
  @safe @nogc mg_error mg_session_fetch(mg_session *session, mg_result **result) pure nothrow;

  /// Tries to pull results of a statement.
  ///
  /// Params: session =       A `mg_session` from which the results should be pulled.
  ///      pull_information = A `mg_map` that contains extra information for pulling the results.
  ///                         It can contain the following information:
  ///                          - n - how many records to fetch. `n=-1` will fetch
  ///                          all records.
  ///                          - qid - query identification, specifies the result
  ///                          from which statement the results should be pulled.
  ///                          `qid=-1` denotes the last executed statement. This
  ///                          is only for Explicit transactions.
  /// Return: Returns 0 if the result was pulled successfuly.
  ///         Otherwise, a non-zero error code is returned.
  @safe @nogc mg_error mg_session_pull(mg_session *session, const mg_map *pull_information) pure nothrow;

  /// Returns names of columns output by the current query execution.
  @safe @nogc const (mg_list) *mg_result_columns(const mg_result *result) pure nothrow;

  /// Returns column values of current result row.
  @safe @nogc const (mg_list) *mg_result_row(const mg_result *result) pure nothrow;

  /// Returns query execution summary.
  @safe @nogc const (mg_map) *mg_result_summary(const mg_result *result) pure nothrow;
}

version(unittest) {
  // Extern C definitions for allocation of memgraph internal types.
  extern (C) {
    // Need at least an empty definition for extern struct.
    struct mg_allocator {}
    extern shared mg_allocator mg_system_allocator;

    @safe @nogc mg_string *mg_string_alloc(uint size, mg_allocator *allocator) pure nothrow;
    @safe @nogc mg_list *mg_list_alloc(uint size, mg_allocator *allocator) pure nothrow;
    @safe @nogc mg_map *mg_map_alloc(uint size, mg_allocator *allocator) pure nothrow;
    @safe @nogc mg_node *mg_node_alloc(uint label_count, mg_allocator *allocator) pure nothrow;
    @safe @nogc mg_path *mg_path_alloc(uint node_count, uint relationship_count, uint sequence_length,
                                       mg_allocator *allocator) pure nothrow;

    @safe @nogc mg_date *mg_date_alloc(shared mg_allocator *alloc) pure nothrow;
    @safe @nogc mg_time *mg_time_alloc(shared mg_allocator *alloc) pure nothrow;
    @safe @nogc mg_local_time *mg_local_time_alloc(shared mg_allocator *alloc) pure nothrow;
    @safe @nogc mg_date_time *mg_date_time_alloc(shared mg_allocator *alloc) pure nothrow;
    @safe @nogc mg_date_time_zone_id *mg_date_time_zone_id_alloc(shared mg_allocator *alloc) pure nothrow;
    @safe @nogc mg_local_date_time *mg_local_date_time_alloc(shared mg_allocator *alloc) pure nothrow;
    @safe @nogc mg_duration *mg_duration_alloc(shared mg_allocator *alloc) pure nothrow;

    @safe @nogc mg_point_2d *mg_point_2d_alloc(shared mg_allocator *allocator) pure nothrow;
    @safe @nogc mg_point_3d *mg_point_3d_alloc(shared mg_allocator *allocator) pure nothrow;
  }
}

unittest {
  import testutils : startContainer;
  startContainer();
}

/// Test connection to memgraph on 127.0.0.1, port 7688.
unittest {
  import std.string : toStringz, fromStringz;
  import std.conv : to;

  assert(mg_init() == 0);

  auto params = mg_session_params_make();
  assert(params != null);

  mg_session_params_set_host(params, toStringz("127.0.0.1"));
  mg_session_params_set_port(params, to!ushort(7688));
  mg_session_params_set_sslmode(params, mg_sslmode.MG_SSLMODE_DISABLE);

  mg_session *session = null;
  const int status = mg_connect(params, &session);
  mg_session_params_destroy(params);

  assert(status == 0, fromStringz(mg_session_error(session)));

  mg_session_destroy(session);
  mg_finalize();
}

module memgraph;

public import mgclient;

import std.string;

struct Detail {
	static Value.Type ConvertType(mg_value_type type) {
		import std.exception, std.conv;
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
}

struct ConstMap {
	mg_map *_map;
}

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
	auto value() const {
		return _value;
	}
private:
	bool _hasValue;
	V _value;
	alias _value this;
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
	bool Execute(const ref string statement) {
		int status = mg_session_run(session, toStringz(statement), null, null, null, null);
		if (status < 0) {
			return false;
		}

		status = mg_session_pull(session, null);
		if (status < 0) {
			return false;
		}

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
	bool Execute(const ref string statement, const ref ConstMap params) {
		int status = mg_session_run(session, toStringz(statement), params._map, null, null, null);
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
		int status = mg_session_fetch(session, &result);
		if (status != 1) {
			return null; // TODO ?
		}

		Value[] values;
		const (mg_list) *list = mg_result_row(result);
		const size_t list_length = mg_list_size(list);
		values.length = list_length;
		for (uint i = 0; i < list_length; ++i) {
			values ~= Value(mg_list_at(list, i));
		}
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
		while ((maybeResult = FetchOne()).length > 0) {
			data ~= maybeResult;
		}
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

	static Optional!Client Connect() {
		Params params; // use default parameters: localhost:7687
		return Connect(params);
	}

	/// \brief Static method that creates a Memgraph client instance.
	/// \return pointer to the created client instance.
	/// If the connection couldn't be established given the `params`, it returns
	/// a `nullptr`.
	static Optional!Client Connect(const ref Params params) {
		Optional!Client ret;
		mg_session_params *mg_params = mg_session_params_make();
		if (!mg_params) {
			return ret;
		}
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
		if (status < 0) {
			return ret;
		}

		return Optional!Client(session);
	}

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

module value;

import std.conv, std.string;

import mgclient, detail, node, enums;

/// A Bolt value, encapsulating all other values.
struct Value {

	/// Constructs an object that becomes the owner of the given `value`.
	/// `value` is destroyed when a `Value` object is destroyed.
	this(mg_value *ptr) { ptr_ = ptr; }

	/// Creates a Value from a copy of the given `mg_value`.
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

/// Provides a wrapper for a Bolt value.
module memgraph.value;

import std.conv, std.string;

import memgraph.mgclient, memgraph.detail, memgraph.node, memgraph.enums;

/// A Bolt value, encapsulating all other values.
struct Value {

	/// Constructs an object that becomes the owner of the given `value`.
	/// `value` is destroyed when a `Value` object is destroyed.
	this(mg_value *ptr) { ptr_ = ptr; }

	/// Creates a new Value from a copy of the given `mg_value`.
	this(const mg_value *const_ptr) { this(mg_value_copy(const_ptr)); }

	/// Creates a new Value from a copy of the given `Value`.
	this(const ref Value other) { this(mg_value_copy(other.ptr_)); }

	/// Destroys any value held.
	~this() {
		if (ptr_ != null)
			mg_value_destroy(ptr_);
	}

	/// Creates a Null value.
	// TODO: not sure this is worth the trouble atm
	// this(typeof(null)) { this(mg_value_make_null()); }
	// @disable this();

	/// Make a new `Value` from a bool.
	this(bool value) { this(mg_value_make_bool(value)); }
	/// Make a new `Value` from a int.
	this(int value) { this(mg_value_make_integer(value)); }
	/// Make a new `Value` from a long.
	this(long value) { this(mg_value_make_integer(value)); }
	/// Make a new `Value` from a double.
	this(double value) { this(mg_value_make_float(value)); }

	// Make a new `Value` from a string.
	this(const string value) {
		this(mg_value_make_string(toStringz(value)));
	}


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

	/// Constructs a vertex value and takes the ownership of the given `vertex`.
	this(ref Node vertex) {
		this(mg_value_make_node(vertex.ptr));
		// vertex.ptr = null;
	}

	/// Constructs a vertex value and copies the given `vertex`.
	this(const ref Node vertex) {
		this(mg_value_make_node(mg_node_copy(vertex.ptr)));
	}

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

	// const ConstList ValueList() const;
	// const ConstMap ValueMap() const;

	/// Return this value as a `Node`.
	auto opCast(T : Node)() const {
		assert(type() == Type.Node);
		return Node(mg_value_node(ptr_));
	}

	/// Return this value as a long.
	auto opCast(T : long)() const {
		assert(type() == Type.Int);
		return mg_value_integer(ptr_);
	}

	/// Return this value as an int.
	auto opCast(T : int)() const {
		assert(type() == Type.Int);
		return mg_value_integer(ptr_);
	}

	/// Return this value as a bool.
	auto opCast(T : bool)() const {
		assert(type() == Type.Bool);
		return to!bool(mg_value_bool(ptr_));
	}

	/// Return this value as a double.
	auto opCast(T : double)() const {
		assert(type() == Type.Double);
		return mg_value_float(ptr_);
	}

	/// Return this value as a string.
	/// If the value held is not of type `Type.String`, then
	/// it will be first converted into the appropriate string
	/// representation.
	auto toString() const {
		switch (type()) {
			case Type.Node:
				return to!string(Node(mg_value_node(ptr_)));
			case Type.String:
				return Detail.convertString(mg_value_string(ptr_));
			case Type.Bool:
				return to!string(to!bool(mg_value_bool(ptr_)));
			case Type.Double:
				return to!string(mg_value_float(ptr_));
			case Type.Int:
				return to!string(mg_value_integer(ptr_));
			default: assert(0, "unhandled type: " ~ to!string(type()));
		}
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

	/// Return the type of value being held.
	Type type() const {
		// if (ptr_ == null) return Type.Null;
		return Detail.convertType(mg_value_get_type(ptr_));
	}

	/// Comparison operator for another `Value`.
	bool opEquals(const ref Value other) const {
		return Detail.areValuesEqual(ptr_, other.ptr_);
	}

	/// Comparison operator for a string.
	/// Note: The code asserts that the current value holds a string.
	bool opEquals(const string val) const {
		assert(type == Type.String);
		return Detail.convertString(mg_value_string(ptr_)) == val;
	}

	/// Comparison operator for a long.
	/// Note: The code asserts that the current value holds an integer.
	bool opEquals(const long val) const {
		assert(type == Type.Int);
		return mg_value_integer(ptr_) == val;
	}

	/// Comparison operator for a int.
	/// Note: The code asserts that the current value holds an integer.
	bool opEquals(const int val) const {
		assert(type == Type.Int);
		return mg_value_integer(ptr_) == val;
	}

	/// Comparison operator for a bool.
	/// Note: The code asserts that the current value holds a bool.
	bool opEquals(const bool val) const {
		assert(type == Type.Bool);
		return mg_value_bool(ptr_) == val;
	}

	/// Comparison operator for a double.
	/// Note: The code asserts that the current value holds a double.
	bool opEquals(const double val) const {
		assert(type == Type.Double);
		return mg_value_float(ptr_) == val;
	}

private:
	mg_value *ptr_;
}

unittest {
	auto v1 = Value("Zdravo, svijete!");
	assert(v1.type == Type.String);
	assert(v1 == "Zdravo, svijete!");

	auto v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == "Zdravo, svijete!");

	assert(v1.toString == "Zdravo, svijete!");
}

unittest {
	auto v1 = Value(42L);
	assert(v1.type == Type.Int);
	assert(v1 == 42);
	assert(v1 == 42L);

	auto v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == 42);

	auto v3 = Value(42);
	assert(v1.type == v3.type);
	assert(v1 == v3);
	assert(v3 == 42);

	assert(v1.toString == "42");
}

unittest {
	auto v1 = Value(true);
	assert(v1.type == Type.Bool);
	assert(v1 == true);

	auto v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == true);

	assert(v1.toString == "true");
}

unittest {
	auto v1 = Value(3.1415926);
	assert(v1.type == Type.Double);
	assert(v1 == 3.1415926);

	auto v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == 3.1415926);

	assert(v1.toString == "3.14159");
}
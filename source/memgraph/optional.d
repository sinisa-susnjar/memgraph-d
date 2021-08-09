/// Provide a optional value.
module memgraph.optional;

/// Holds an optional value of type `V`.
struct Optional(V) {
	@disable this(this);

	/// Copy construct `this` from another `Optional` instance.
	this(ref return scope inout Optional!V rhs) inout {
		 value_ = rhs.value_;
		 hasValue_ = rhs.hasValue_;
	}
	/// Copy construct `this` from a value of type `V`.
	this(inout V value) inout {
		value_ = value;
		hasValue_ = true;
	}
	/// Copy construct `this` by creating an instance of type `V` using constructor arguments `args`.
	this(Args...)(Args args) {
		static if (args.length > 0) {
			value_ = V(args);
			hasValue_ = true;
		}
	}
	/// Assign value of type `V` to `this`.
	auto opAssign(V value) {
		value_ = value;
		hasValue_ = true;
		return this;
	}
	/// When a `bool` is required, checks if this `Optional` contains a value.
	/// Return: true if `this` holds a value, false otherwise.
	auto opCast(T : bool)() const {
		return hasValue_;
	}
	/// Return value of type `V`.
	auto opCast(T : inout V)() inout {
		return value_;
	}
	/// Returns if `this` holds a value or not.
	/// Return: true if `this` holds a value, false otherwise.
	@property auto hasValue() inout {
		return hasValue_;
	}
	/// Return value of type `V`.
	@property inout(V) value() inout {
		return value_;
	}
	/// Dispatch function calls to the stored value and return any results.
	auto opDispatch(string name, T...)(T vals) {
		return mixin("value_." ~ name)(vals);
	}
private:
	alias value this;
	bool hasValue_;
	V value_;
}

/// Assign a string to an optional.
unittest {
	Optional!string s = "Hello there";

	assert(s.hasValue);
	assert(s.value == "Hello there");
	assert(s == "Hello there");

	s = "Hi!";
	assert(s == "Hi!");
}

/// Call a method on a struct stored in an optional.
unittest {
	struct TestStruct {
		int addOne(int val) {
			return val + 1;
		}
	}

	auto s = Optional!TestStruct();
	assert(s.addOne(41) == 42);
}

unittest {
	immutable Optional!string s = "Hi";
	assert(s.hasValue);
	assert(s.value == "Hi");
	assert(s == "Hi");
}

unittest {
	const Optional!string s = "Hi";
	assert(s.hasValue);
	assert(s.value == "Hi");
	assert(s == "Hi");
}

unittest {
	immutable Optional!string s1 = "Hi";
	immutable a1 = s1;
	assert(a1 == s1);
}

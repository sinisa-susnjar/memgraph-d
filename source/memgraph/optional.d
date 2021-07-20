/// Provide a optional value.
module memgraph.optional;

/// Holds an optional value of type `V`.
struct Optional(V) {
	// this(ref return scope inout Optional!V rhs) inout {
	this(ref inout Optional!V rhs) inout {
		 _value = rhs._value;
	}
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
	@property V value() {
		return _value;
	}
	auto opDispatch(string name, T...)(T vals) {
		return mixin("_value." ~ name)(vals);
	}
private:
	alias value this;
	bool _hasValue;
	V _value;
}

unittest {
	Optional!string s = "Hello there";

	assert(s.hasValue);
	assert(s.value == "Hello there");
	assert(s == "Hello there");

	s = "Hi!";
	assert(s == "Hi!");
}

unittest {
	struct TestStruct {
		int addOne(int val) {
			return val + 1;
		}
	}

	auto s = Optional!TestStruct();
	assert(s.addOne(41) == 42);
}

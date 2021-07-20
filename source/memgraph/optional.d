/// Provide a optional value.
module memgraph.optional;

/// Holds an optional value of type `V`.
struct Optional(V) {
	this(ref return scope inout Optional!V rhs) inout {
		 _value = rhs._value;
		 _hasValue = rhs._hasValue;
	}
	this(inout V value) inout {
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
	auto opCast(T : inout V)() inout {
		return _value;
	}
	@property auto hasValue() inout {
		return _hasValue;
	}
	@property inout(V) value() inout {
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
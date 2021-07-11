/// Provide a optional value.
module optional;

/// Holds an optional value of type `V`.
struct Optional(V) {
	this(ref return scope inout Optional!V rhs) inout { }
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
	@property auto value() const {
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

/// Provides a thread-safe atomic reference counted pointer.
module memgraph.atomic;

import core.atomic : atomicOp, atomicStore, atomicLoad;

import std.stdio;

/// Thread-safe atomic shared pointer to T.
struct SharedPtr(T)
{
	shared struct Control {
		this(T args) {
			data_ = args;
		}
		T data_;
		uint refs_ = 1;
		alias data_ this;
	}

	Control *ctrl_;

	alias ctrl_ this;

	/// Checks if the stored pointer is not `null`.
	bool opCast(T : bool)() const nothrow {
		return ctrl_ != null;
	}

	ref SharedPtr!T opAssign(SharedPtr!T rhs) @safe return {
		writefln("SharedPtr.opAssign");
		atomicStore(ctrl_, rhs.ctrl_);
		atomicOp!"+="(ctrl_.refs_, 1);
		return this;
	}

	this(this) @safe {
		atomicOp!"+="(ctrl_.refs_, 1);
		writefln("SharedPtr.this[%s](this)(%s)", ctrl_, ctrl_.refs_);
	}

	this(SharedPtr!T rhs) @safe {
		writefln("SharedPtr.copyCTOR");
		atomicStore(ctrl_, rhs.ctrl_);
		atomicOp!"+="(ctrl_.refs_, 1);
	}

	this(Control *ptr) {
		writefln("SharedPtr.this");
		atomicStore(ctrl_, ptr);
	}

	auto useCount() {
		if (ctrl_ == null)
			return 0;
		assert(atomicLoad(ctrl_));
		return ctrl_.refs_;
	}

	~this() {
		if (ctrl_ == null)
			return;
		writefln("SharedPtr.~this[%s](%s)", ctrl_, ctrl_.refs_);
		if (atomicOp!"-="(ctrl_.refs_, 1) == 0)
			ctrl_ = null;
	}

	static auto make(Args...)(Args args) {
		// import core.stdc.stdlib : malloc;
		import std.exception : enforce;
		// assert(!ref_);
		return SharedPtr!T(enforce(new Control(T(args)), "Out of memory"));
		// assert(ref_);
	}
}

unittest {
	struct Dummy {
		string greeting;
	}
	import core.stdc.stdlib : malloc, free;
	import std.stdio;

	{
		auto p = SharedPtr!Dummy.make("Live long and prosper");
		assert(p.useCount == 1);
		assert(p.greeting == "Live long and prosper");
		// writefln("p: %s %s", p.useCount, p.greeting);
		{
			auto p2 = p;
			// writefln("p2: %s", p2.useCount);
			// writefln("p: %s", p.useCount);
			assert(p.useCount == 2);
			assert(p2.useCount == 2);
			assert(p2.greeting == "Live long and prosper");
		}
		writefln("p: %s", p.useCount);

		auto p3 = SharedPtr!Dummy();
		writefln("p3: %s", p3.useCount);
		p3 = p;
		writefln("p3: %s", p3.useCount);
		writefln("p: %s", p.useCount);

		{
			auto p4 = SharedPtr!Dummy(p3);
			writefln("p4: %s", p4.useCount);
			writefln("p3: %s", p3.useCount);
			writefln("p: %s", p.useCount);
		}
		writefln("p3: %s", p3.useCount);
		writefln("p: %s", p.useCount);

		auto p5 = SharedPtr!Dummy();
	}

	// auto p = SharedPtr!Dummy.make("Live long and prosper");

	// writefln("p: %s", p.greeting);

	// AtomicRef can be used with scope memory
	// auto a1 = AtomicRef!(Dummy, free)(p);
}

/// Thread-safe atomic reference counted pointer to T.
struct AtomicRef(T, alias Dtor)
{
	@disable this();

	/// Create a new instance using a pointer to T `ptr` and an optional initial reference `count`.
	this(T *ptr, uint count = 1) {
		ptr_ = ptr;
		atomicStore(refs_, count);
	}

	/// Reduces the reference count and if last owner (i.e. reference count equals 0),
	/// calls the provided `Dtor` function to destroy the pointer to `T`.
	~this() {
		if (atomicOp!"-="(refs_, 1) == 0) {
			Dtor(ptr_);
			ptr_ = null;
		}
	}

	/// Increment reference counter.
	pragma(inline, true)
	auto inc() nothrow {
		assert(atomicLoad(refs_));
		return atomicOp!"+="(refs_, 1);
	}

	auto ptr() const { return ptr_; }

	// TODO: disable copying for now - need to invest some time to make it a copyable
	//       AtomicRef - will probably need to have a control structure like shared_ptr
	@disable void opAssign(AtomicRef!(T, Dtor) rhs); // @safe return { }

private:
	T *ptr_ = null;
	shared uint refs_ = 1;
}

unittest {
	{
		struct Dummy {
			string greeting;
		}
		import core.stdc.stdlib : malloc, free;
		auto p = cast(Dummy *)malloc(Dummy.sizeof);
		import std.stdio;
		p.greeting = "Live long and prosper";
		writefln("p: %s", p.greeting);

		// AtomicRef can be used with GC allocated memory
		auto a1 = new AtomicRef!(Dummy, free)(p);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}

unittest {
	struct Dummy {
		string greeting;
	}
	import core.stdc.stdlib : malloc, free;
	auto p = cast(Dummy *)malloc(Dummy.sizeof);
	import std.stdio;
	p.greeting = "Live long and prosper";
	writefln("p: %s", p.greeting);

	// AtomicRef can be used with scope memory
	auto a1 = AtomicRef!(Dummy, free)(p);
}

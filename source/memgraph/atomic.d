/// Provides a thread-safe atomic reference counted pointer.
module memgraph.atomic;

import core.atomic : atomicOp, atomicStore, atomicLoad;

import std.stdio;

/// Thread-safe atomic shared pointer to T.
struct SharedPtr(T)
{
	shared struct Control {
		@disable this();
		@disable this(this);
		this(T data) {
			data_ = data;
		}
		this(T data, void delegate(T t) dtor) {
			data_ = data;
			dtor_ = dtor;
		}
		~this() {
			if (dtor_) {
				writefln("calling Dtor for %s (%s)", T.stringof, data_);
				dtor_(data_);
			}
		}
	private:
		T data_;
		void delegate(T t) dtor_;
		uint refs_ = 1;
		alias data_ this;
	}

	auto ptr() const { return ctrl_.data_; }

	/// Checks if the stored pointer is not `null`.
	bool opCast(T : bool)() const nothrow {
		return ctrl_ != null;
	}

	// void dump() const { writefln("ctrl: %s data: %s", ctrl_, ctrl_.data_); }

	ref SharedPtr!(T) opAssign(SharedPtr!T rhs) @safe return {
		// writefln("SharedPtr.opAssign");
		atomicStore(ctrl_, rhs.ctrl_);
		atomicOp!"+="(ctrl_.refs_, 1);
		return this;
	}

	this(this) @safe {
		atomicOp!"+="(ctrl_.refs_, 1);
		// writefln("SharedPtr.this[%s](this)(%s)", ctrl_, ctrl_.refs_);
	}

	this(SharedPtr!T rhs) @safe {
		// writefln("SharedPtr.copyCTOR");
		atomicStore(ctrl_, rhs.ctrl_);
		atomicOp!"+="(ctrl_.refs_, 1);
	}

	this(Control *ptr) {
		// writefln("SharedPtr.this");
		atomicStore(ctrl_, ptr);
	}

	uint useCount() {
		if (ctrl_ == null)
			return 0;
		return atomicLoad(ctrl_.refs_);
	}

	~this() {
		if (ctrl_ == null)
			return;
		// writefln("SharedPtr.~this[%s](%s)", ctrl_, ctrl_.refs_);
		if (atomicOp!"-="(ctrl_.refs_, 1) == 0)
			ctrl_ = null;
	}

	static auto make(Args...)(Args args) {
		import std.exception : enforce;
		return SharedPtr!T(enforce(new Control(T(args)), "Out of memory"));
	}

	static auto make(Args...)(Args args, void delegate(T t) dtor) {
		import std.exception : enforce;
		return SharedPtr!T(enforce(new Control(T(args), dtor), "Out of memory"));
	}

private:
	Control *ctrl_;
	alias ctrl_ this;
}

unittest {
	struct Dummy {
		string greeting;
		int value;
	}
	import std.stdio;

	{
		auto p = SharedPtr!Dummy.make("Live long and prosper", 23);
		{
			assert(p.useCount == 1);
			assert(p.greeting == "Live long and prosper");
			assert(p.value == 23);
			// writefln("p: %s %s", p.useCount, p.greeting);
			{
				auto p2 = p;
				// writefln("p2: %s", p2.useCount);
				// writefln("p: %s", p.useCount);
				assert(p.useCount == 2);
				assert(p2.useCount == 2);
				assert(p2.greeting == "Live long and prosper");
			}
			assert(p.useCount == 1);
			// writefln("p: %s", p.useCount);

			auto p3 = SharedPtr!Dummy();
			// writefln("p3: %s", p3.useCount);
			assert(p3.useCount == 0);
			p3 = p;
			// writefln("p3: %s", p3.useCount);
			// writefln("p: %s", p.useCount);
			assert(p.useCount == 2);
			assert(p3.useCount == 2);

			{
				auto p4 = SharedPtr!Dummy(p3);
				// writefln("p4: %s", p4.useCount);
				// writefln("p3: %s", p3.useCount);
				// writefln("p: %s", p.useCount);
				assert(p4.useCount == 3);
				assert(p3.useCount == 3);
				assert(p.useCount == 3);
			}
			// writefln("p3: %s", p3.useCount);
			// writefln("p: %s", p.useCount);
			assert(p3.useCount == 2);
			assert(p.useCount == 2);
		}
		assert(p.useCount == 1);

		auto p5 = SharedPtr!Dummy();
	}
}

unittest {
	import std.concurrency;
	import core.thread;
	import std.stdio;

	struct Dummy {
		string question;
		int answer;
	}

	auto p = SharedPtr!Dummy.make("What is the answer to life, the universe and everything?");

	assert(p.useCount == 1);
	assert(p.question == "What is the answer to life, the universe and everything?");
	assert(p.answer == 0);

	{
		// writefln("thisTid: %s", thisTid);
		static void deepThought(Tid ownerTid) {
			// writefln("thisTid: %s ownerTid: %s", thisTid, ownerTid);
			receive((SharedPtr!Dummy p) {
					assert(p.useCount == 3); // one copy for send(), another for receive()
					assert(p.question == "What is the answer to life, the universe and everything?");
					assert(p.answer == 0);
					p.answer = 42;
					// writefln("child useCount: %s answer: %s", p.useCount, p.answer);
					// p.dump;
					// send(ownerTid, p.useCount);
				});
		}
		auto childTid = spawn(&deepThought, thisTid);
		// writefln("childTid: %s", childTid);
		send(childTid, p);
		// auto useCount = receiveOnly!uint;
		// writefln("parent useCount: %s answer: %s", p.useCount, p.answer);
		thread_joinAll();
		// p.dump;
		// assert(p.useCount == 3);
		// assert(p.answer == 42);
	}
	// writefln("final p.useCount: %s answer: %s", p.useCount, p.answer);
	assert(p.useCount == 1);
	assert(p.answer == 42);
	// Force garbage collection for full code coverage
	// import core.memory;
	// GC.collect();
	// assert(p.useCount == 1);
}

unittest {
	import std.concurrency;
	import core.thread;
	import std.stdio;

	struct Dummy {
		string question;
		int answer;
	}

	auto p = SharedPtr!Dummy.make("What is the answer to life, the universe and everything?");

	assert(p.useCount == 1);
	assert(p.question == "What is the answer to life, the universe and everything?");
	assert(p.answer == 0);

	writefln("start unittest");

	{
		// writefln("thisTid: %s", thisTid);
		static void stressTest(Tid ownerTid) {
			// writefln("thisTid: %s ownerTid: %s", thisTid, ownerTid);
			receive((SharedPtr!Dummy p) {
					// writefln("before array");
					SharedPtr!Dummy[] sp;
					// writefln("after array");
					// sp.reserve = 10;
					// writefln("before loop");
					foreach (i; 0..43) {
						// SharedPtr!Dummy sp;
						p.answer = i;
						sp ~= p;
						// writefln("loop...");
					}
					// writefln("child p.useCount: %s answer: %s", p.useCount, p.answer);
					send(ownerTid, p.useCount);
				});
			// writefln("end of stressTest");
			// Force garbage collection for full code coverage
			// import core.memory;
			// GC.collect();
		}
		foreach (n; 0..10) {
			auto childTid = spawn(&stressTest, thisTid);
			// writefln("childTid: %s", childTid);
			send(childTid, p);
		}
		foreach (n; 0..10) {
			auto useCount = receiveOnly!uint;
			// writefln("child #%s useCount: %s %s %s", n, useCount, p.useCount, p.answer);
		}
		// assert(useCount == 3);
		// assert(p.answer == 42);
	}
	// Force garbage collection so dynamic SharedPtr arrays are collected.
	import core.memory;
	GC.collect();
	// writefln("final p.useCount: %s answer: %s", p.useCount, p.answer);
	assert(p.useCount == 1);
	assert(p.answer == 42);
	// assert(p.useCount == 1);
}

unittest {
	{
		struct Dummy {
			string greeting;
		}
		import core.stdc.stdlib : malloc, free;
		auto p = cast(shared Dummy *)malloc(Dummy.sizeof);
		import std.stdio;
		p.greeting = "Live long and prosper";
		auto a = SharedPtr!(typeof(p)).make(p, (ptr) { free(cast(void*)ptr); });
	}
	// Force garbage collection for full code coverage
	// import core.memory;
	// GC.collect();
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
		// writefln("p: %s", p.greeting);

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
	// writefln("p: %s", p.greeting);

	// AtomicRef can be used with scope memory
	auto a1 = AtomicRef!(Dummy, free)(p);
}

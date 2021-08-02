/// Provides an atomic lock-free reference counted pointer.
module memgraph.atomic;

import core.atomic : atomicOp, atomicStore, atomicLoad;

/// Thread-safe lock-free atomic shared pointer to T.
struct SharedPtr(T)
{
	import std.traits;

	/// Unqualified pointer type for dealing with custom deleters.
	alias PtrType = Unqual!T *;

	/// Control block for shared pointer. Contains pointer to the "pointee" and the reference count.
	shared struct Control {
		@disable this();
		@disable this(this);
		this(T* data) {
			atomicStore(data_, cast(shared(T*))data);
		}
		this(T* data, void delegate(PtrType t) dtor) {
			atomicStore(data_, cast(shared(T*))data);
			dtor_ = dtor;
		}
		~this() {
			if (dtor_)
				dtor_(cast(PtrType)data_);
		}
	private:
		void delegate(PtrType t) dtor_;
		alias data_ this;
		uint refs_ = 1;
		T* data_;
	}

	/// Checks if the stored pointer is not `null`.
	bool opCast(T : bool)() const nothrow {
		return ctrl_ != null;
	}

	/// Assigns another shared pointer to this one, increasing the reference count.
	ref SharedPtr!(T) opAssign(SharedPtr!T rhs) @safe return {
		atomicStore(ctrl_, rhs.ctrl_);
		atomicOp!"+="(ctrl_.refs_, 1);
		return this;
	}

	/// Postblit. Increase reference count.
	this(this) @safe {
		atomicOp!"+="(ctrl_.refs_, 1);
	}

	/// Copy ctor. Increase reference count.
	this(SharedPtr!T rhs) @safe {
		atomicStore(ctrl_, rhs.ctrl_);
		atomicOp!"+="(ctrl_.refs_, 1);
	}

	/// Returns the use count of this shared pointer, i.e. how many references are in use.
	uint useCount() {
		if (ctrl_ == null)
			return 0;
		return atomicLoad(ctrl_.refs_);
	}

	/// Return pointer to "pointee" of type `T`.
	auto data() const {
		if (ctrl_ == null)
			return null;
		return cast(PtrType)ctrl_.data_;
	}

	~this() {
		if (ctrl_ == null)
			return;
		if (atomicOp!"-="(ctrl_.refs_, 1) == 0)
			ctrl_ = null;
	}

	/// Create a new pointee of type `T` using the given `Args...`.
	static auto make(Args...)(Args args) {
		import std.exception : enforce;
		return SharedPtr!T(enforce(new Control(new T(args)), "Out of memory"));
	}

	/// Use the previously created pointee of type `T` and delete it using `dtor` once the usage reaches zero.
	static auto make(PtrType ptr, void delegate(PtrType t) dtor) {
		import std.exception : enforce;
		return SharedPtr!T(enforce(new Control(ptr, dtor), "Out of memory"));
	}

private:
	/// Pointer to control block.
	Control *ctrl_;
	alias ctrl_ this;

	/// Create from a control block. Only for internal use.
	this(Control *ptr) {
		atomicStore(ctrl_, ptr);
	}
}

// Unit-test shared pointer within different scopes.
unittest {
	struct Dummy {
		string greeting;
		int value;
	}

	{
		auto p = SharedPtr!Dummy.make("Live long and prosper", 23);
		{
			assert(p.useCount == 1);
			assert(p.greeting == "Live long and prosper");
			assert(p.value == 23);
			{
				auto p2 = p;
				assert(p.useCount == 2);
				assert(p2.useCount == 2);
				assert(p2.greeting == "Live long and prosper");
			}
			assert(p.useCount == 1);

			auto p3 = SharedPtr!Dummy();
			assert(p3.useCount == 0);
			p3 = p;
			assert(p.useCount == 2);
			assert(p3.useCount == 2);

			{
				auto p4 = SharedPtr!Dummy(p3);
				assert(p4.useCount == 3);
				assert(p3.useCount == 3);
				assert(p.useCount == 3);
			}
			assert(p3.useCount == 2);
			assert(p.useCount == 2);
		}
		assert(p.useCount == 1);

		auto p5 = SharedPtr!Dummy();
	}
}

// Unit-test passing of shared pointer to a single thread.
unittest {
	import std.concurrency;
	import core.thread;

	struct Dummy {
		string question;
		int answer;
	}

	auto p = SharedPtr!Dummy.make("What is the answer to life, the universe and everything?");

	assert(p.useCount == 1);
	assert(p.question == "What is the answer to life, the universe and everything?");
	assert(p.answer == 0);

	{
		static void deepThought(Tid ownerTid) {
			receive((SharedPtr!Dummy p) {
					assert(p.useCount == 3); // one copy for send(), another for receive()
					assert(p.question == "What is the answer to life, the universe and everything?");
					assert(p.answer == 0);
					p.answer = 42;
				});
		}
		auto childTid = spawn(&deepThought, thisTid);
		send(childTid, p);
		thread_joinAll();
	}
	assert(p.useCount == 1);
	assert(p.answer == 42);
	// Force garbage collection for full code coverage
	// import core.memory;
	// GC.collect();
	// assert(p.useCount == 1);
}

// Unit-test passing of shared pointer to multiple threads.
unittest {
	import std.concurrency;
	import core.thread;

	struct Dummy {
		string question;
		int answer;
	}

	auto p = SharedPtr!Dummy.make("What is the answer to life, the universe and everything?");

	assert(p.useCount == 1);
	assert(p.question == "What is the answer to life, the universe and everything?");
	assert(p.answer == 0);

	{
		static void stressTest(Tid ownerTid) {
			receive((SharedPtr!Dummy p) {
					SharedPtr!Dummy[] sp;
					foreach (i; 0..43) {
						p.answer = i;
						sp ~= p;
					}
					send(ownerTid, p.useCount);
				});
		}
		foreach (n; 0..10) {
			auto childTid = spawn(&stressTest, thisTid);
			send(childTid, p);
		}
		foreach (n; 0..10) {
			auto useCount = receiveOnly!uint;
		}
	}
	// Force garbage collection so dynamic SharedPtr arrays are collected.
	import core.memory;
	GC.collect();
	assert(p.useCount == 1);
	assert(p.answer == 42);
}

// Unit-test shared pointer with custom destructor.
unittest {
	struct Dummy {
		string greeting;
	}
	import core.stdc.stdlib : malloc, free;
	auto p = cast(Dummy *)malloc(Dummy.sizeof);
	p.greeting = "Live long and prosper";
	auto a = SharedPtr!Dummy.make(p, (ptr) { free(cast(void*)ptr); });
	assert(a.useCount == 1);
	assert(a.greeting == "Live long and prosper");
}

unittest {
	struct Dummy {
		string greeting;
	}
	SharedPtr!Dummy emptyPtr;
	assert(emptyPtr.useCount == 0);
	assert(emptyPtr.data == null);
	assert(!emptyPtr);
}

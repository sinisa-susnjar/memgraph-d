/// Provides a thread-safe atomic reference counted pointer.
module memgraph.atomic;

import core.atomic : atomicOp, atomicStore, atomicLoad;

/// Thread-safe atomic reference counted pointer to T.
struct AtomicRef(T, alias Dtor)
{
	@disable this();

	/// Create a new instance using a pointer to T `ptr` and an initial reference `count`.
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

		auto a1 = new AtomicRef!(Dummy, free)(p);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}

/// Provides a node wrapper.
module node;

import mgclient, detail, map;

/// Represents a node from a labeled property graph.
///
/// Consists of a unique identifier (withing the scope of its origin graph), a
/// list of labels and a map of properties. A node owns its labels and
/// properties.
///
/// Maximum possible number of labels allowed by Bolt protocol is `uint.max`.
struct Node {
	/// View of the node's labels.
	struct Labels {
		/// Returns the number of labels of node `node`.
		size_t size() const { return mg_node_label_count(node_); }

		/// Return node's label at the `index` position.
		string opIndex(int index) const {
			return Detail.ConvertString(mg_node_label_at(node_, index));
		}

		bool empty() const {
			return idx_ >= size();
		}
		string front() const {
			assert(idx_ < size());
			return Detail.ConvertString(mg_node_label_at(node_, idx_));
		}
		void popFront() {
			idx_++;
		}

	private:
		this(const mg_node *node) { node_ = node; }
		const mg_node *node_;
		uint idx_;
	}

	/// Create a Node using the given `mg_node`.
	this(mg_node *ptr) { ptr_ = ptr; }

	/// Create a Node from a copy of the given `mg_node`.
	this(const mg_node *const_ptr) { this(mg_node_copy(const_ptr)); }

	/// Create a Node from a copy of the given `node`.
	this(const ref Node other) {
		this(mg_node_copy(other.ptr_));
	}

	/// Destroys the given node.
	~this() {
		if (ptr_ != null)
			mg_node_destroy(ptr_);
	}

	/// Returns the ID of this node.
	long id() const { return mg_node_id(ptr_); }

	/// Returns the labels belonging to this node.
	Labels labels() const { return Labels(ptr_); }

	/// Returns the property map belonging to this node.
	Map properties() const { return Map(mg_node_properties(ptr_)); }

	/// Comparison operator.
	bool opEquals(const ref Node other) const {
		return Detail.areNodesEqual(ptr_, other.ptr_);
	}

private:
	/// Pointer to `mg_node` instance.
	mg_node *ptr_;
}

unittest {
	import testutils;
	startContainer();
}

unittest {
	import memgraph;
	import std.algorithm, std.conv;

	Client.Params params;
	params.port = 7688;

	import std.stdio;
	writefln("running node.d unit tests");

	auto client = Client.Connect(params);
	assert(client);

	assert(client.Execute("MATCH (n) DETACH DELETE n;"));
	client.DiscardAll();

	assert(client.Execute("CREATE INDEX ON :Person(id);"));
	client.DiscardAll();

	assert(client.Execute(
				"CREATE (:Person:Entrepreneur {id: 0, age: 40, name: 'John', " ~
				"isStudent: false, score: 5.0});"));
	client.DiscardAll();

	assert(client.Execute("MATCH (n) RETURN n;"));

	const auto row = client.FetchOne();
	assert(row.length == 1);

	const auto value = row[0];

	assert(value.type() == Type.Node);

	const auto node = to!Node(value);

	const auto labels = node.labels();

	import std.stdio;

	assert(labels.size() == 2);
	assert(labels[0] == "Person");
	assert(labels[1] == "Entrepreneur");

	const auto props = node.properties();
	assert(props.size() == 5);
	assert(to!long(props["id"]) == 0);
	assert(to!long(props["age"]) == 40);
	assert(to!string(props["name"]) == "John");
	assert(to!bool(props["isStudent"]) == false);
	assert(to!double(props["score"]) == 5.0);
}


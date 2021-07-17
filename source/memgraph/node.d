/// Provides a node wrapper.
module memgraph.node;

import memgraph.mgclient, memgraph.detail, memgraph.map;

import std.typecons, std.conv;

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
			return Detail.convertString(mg_node_label_at(node_, index));
		}

		bool empty() const {
			return idx_ >= size();
		}
		auto front() const {
			assert(idx_ < size());
			return Tuple!(uint, string)(idx_, Detail.convertString(mg_node_label_at(node_, idx_)));
		}
		void popFront() {
			idx_++;
		}

		bool opEquals(const string[] labels) {
			if (labels.length != size())
				return false;
			foreach (idx, label; labels) {
				if (label != Detail.convertString(mg_node_label_at(node_, to!uint(idx))))
					return false;
			}
			return true;
		}

	private:
		this(const mg_node *node) { node_ = node; }
		const mg_node *node_;
		uint idx_;
	}

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

package:
	/// Create a Node using the given `mg_node`.
	this(mg_node *ptr) { ptr_ = ptr; }

	/// Create a Node from a copy of the given `mg_node`.
	this(const mg_node *const_ptr) { this(mg_node_copy(const_ptr)); }

	auto ptr() const { return ptr_; }
	auto ptr() { return ptr_; }

private:
	/// Pointer to `mg_node` instance.
	mg_node *ptr_;
}

unittest {
	import testutils;
	startContainer();
}

unittest {
	import testutils;
	import memgraph;
	import std.algorithm, std.conv;

	auto client = connectContainer();
	assert(client);

	createTestIndex(client);

	deleteTestData(client);

	createTestData(client);

	assert(client.execute("MATCH (n) RETURN n;"));
	const auto row = client.fetchOne();
	assert(row.length == 1);

	const auto value = row[0];

	assert(value.type() == Type.Node);

	const auto node = to!Node(value);

	auto labels = node.labels();

	assert(node.id() >= 0);

	immutable auto expectedLabels = [ "Person", "Entrepreneur" ];

	assert(labels.size() == 2);
	assert(labels[0] == "Person");
	assert(labels[1] == "Entrepreneur");

	foreach (idx, label; labels)
		assert(label == expectedLabels[idx]);

	assert(expectedLabels == labels);

	const auto other = Node(node);
	assert(other == node);

	const auto props = node.properties();
	assert(props.length == 5);
	assert(props["id"] == 0);
	assert(props["age"] == 40);
	assert(props["name"] == "John");
	assert(props["isStudent"] == false);
	assert(props["score"] == 5.0);

	auto otherProps = Map(props);
	assert(otherProps == props);

	// const auto otherProps2 = Map(otherProps.ptr);
	// assert(otherProps2 == otherProps);
}

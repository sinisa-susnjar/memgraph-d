/// Provides a node wrapper.
module memgraph.node;

import memgraph.mgclient, memgraph.detail, memgraph.map;
import memgraph.value, memgraph.enums;

import std.conv;

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
		size_t size() const {
			assert(node_ != null);
			return mg_node_label_count(node_);
		}

		/// Return node's label at the `index` position.
		string opIndex(int index) const {
			assert(node_ != null);
			return Detail.convertString(mg_node_label_at(node_, index));
		}

		/// Checks if the range is empty.
		bool empty() const {
			return idx_ >= size();
		}

		/// Returns the next element in the range.
		auto front() const {
			assert(idx_ < size());
			return Detail.convertString(mg_node_label_at(node_, idx_));
		}

		/// Move to the next element in the range.
		void popFront() {
			idx_++;
		}

		bool opEquals(const string[] labels) const {
			if (labels.length != size())
				return false;
			foreach (idx, label; labels) {
				if (label != Detail.convertString(mg_node_label_at(node_, to!uint(idx))))
					return false;
			}
			return true;
		}

	private:
		this(const mg_node *node) {
			assert(node != null);
			node_ = node;
		}
		const mg_node *node_;
		uint idx_;
	}

	/// Return a printable string representation of this node.
	const (string) toString() const {
		import std.range : join;
		return labels.join(":") ~ " " ~ to!string(properties());
	}

	this(this) {
		if (ptr_)
			ptr_ = mg_node_copy(ptr_);
	}

	/// Create a copy of the given `node`.
	this(inout ref Node other) {
		this(mg_node_copy(other.ptr_));
	}

	/// Create a node from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.Node);
		this(mg_node_copy(mg_value_node(value.ptr)));
	}

	/// Returns the ID of this node.
	long id() const {
		assert(ptr_ != null);
		return mg_node_id(ptr_);
	}

	/// Returns the labels belonging to this node.
	Labels labels() const { return Labels(ptr_); }

	/// Returns the property map belonging to this node.
	const (Map) properties() const { return Map(mg_node_properties(ptr_)); }

	/// Comparison operator.
	bool opEquals(const ref Node other) const {
		return Detail.areNodesEqual(ptr_, other.ptr_);
	}

	~this() {
		if (ptr_)
			mg_node_destroy(ptr_);
	}

package:
	/// Create a Node using the given `mg_node`.
	this(mg_node *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Node from a copy of the given `mg_node`.
	this(const mg_node *ptr) {
		assert(ptr != null);
		this(mg_node_copy(ptr));
	}

	const (mg_node *) ptr() const { return ptr_; }

private:
	/// Pointer to `mg_node` instance.
	mg_node *ptr_;
}

unittest {
	import testutils : startContainer;
	startContainer();
}

unittest {
	import testutils;
	import memgraph;
	import std.algorithm, std.conv, std.range;

	auto client = connectContainer();
	assert(client);

	createTestIndex(client);

	deleteTestData(client);

	createTestData(client);

	auto result = client.execute("MATCH (n) RETURN n;");
	assert(result, client.error);
	assert(!result.empty());
	auto value = result.front;
	assert(result.count == 5);

	assert(value[0].type() == Type.Node);

	auto node = to!Node(value[0]);

	auto labels = node.labels();

	assert(node.id() >= 0);

	immutable auto expectedLabels = [ "Person", "Entrepreneur" ];

	assert(labels.size() == 2);
	assert(labels[0] == expectedLabels[0]);
	assert(labels[1] == expectedLabels[1]);

	assert([] != labels);
	assert([ "Nope", "x" ] != labels);
	assert(expectedLabels == labels);
	assert(expectedLabels.join(":") == labels.join(":"));

	auto other = Node(node);
	assert(other == node);

	const auto props = node.properties();
	assert(props.length == 5);
	assert(props["id"] == 0);
	assert(props["age"] == 40);
	assert(props["name"] == "John");
	assert(props["isStudent"] == false);
	assert(props["score"] == 5.0);

	assert(to!string(node) == labels.join(":") ~ " " ~ to!string(props));

	const otherProps = props;
	assert(otherProps == props);

	// this is a package internal method
	assert(node.ptr != null);

	const v = Value(node);
	assert(v.type == Type.Node);
	assert(v == node);
	assert(node == v);

	const v2 = Value(node);
	assert(v == v2);
}

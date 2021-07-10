module node;

import mgclient, detail, map;

/// \brief Wrapper class for \ref mg_node
struct Node {
	/// \brief View of the node's labels
	struct Labels {
		// CREATE_ITERATOR(Labels, std::string_view);

		this(const mg_node *node) { node_ = node; }

		size_t size() const { return mg_node_label_count(node_); }

		/// \brief Return node's label at the `index` position.
		// std::string_view operator[](size_t index) const;
		string opIndex(int index) const {
			return Detail.ConvertString(mg_node_label_at(node_, index));
		}

		// Iterator begin() { return Iterator(this, 0); }
		// Iterator end() { return Iterator(this, size()); }

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
		const mg_node *node_;
		uint idx_;
	}

	this(mg_node *ptr) { ptr_ = ptr; }

	/// \brief Create a Node from a copy of the given \ref mg_node.
	this(const mg_node *const_ptr) { this(mg_node_copy(const_ptr)); }

	this(const ref Node other) {
		this(mg_node_copy(other.ptr_));
	}

	// Node(Node &&other);
	// inline Node::Node(Node &&other) : ptr_(other.ptr_) { other.ptr_ = nullptr; }

	// Node &operator=(const Node &other) = delete;
	// Node &operator=(Node &&other) = delete;
	~this() {
		if (ptr_ != null)
			mg_node_destroy(ptr_);
	}

	// explicit Node(const ConstNode &node);

	// Id id() const { return Id::FromInt(mg_node_id(ptr_)); }
	long id() const { return mg_node_id(ptr_); }

	Labels labels() const { return Labels(ptr_); }

	Map properties() const { return Map(mg_node_properties(ptr_)); }

	// ConstNode AsConstNode() const;

	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator==(const Node &other) const;
	bool opEquals(const ref Node other) const {
		return Detail.AreNodesEqual(ptr_, other.ptr_);
	}
	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator==(const ConstNode &other) const;
	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator!=(const Node &other) const { return !(this == other); }
	/// \exception std::runtime_error node property contains value with
	/// unknown type
	// bool operator!=(const ConstNode &other) const { return !(*this == other); }

	// mg_node *ptr() const { return ptr_; }

private:
	mg_node *ptr_;
}

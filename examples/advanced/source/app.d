import memgraph;

import std.stdio, std.conv, std.array;

// Example adapted from advanced.cpp included in the mgclient git repo.

void ClearDatabaseData(ref Optional!Client client) {
	if (!client.execute("MATCH (n) DETACH DELETE n;")) {
		writefln("Failed to delete all data from the database.");
		assert(0);
	}
	client.discardAll();
}

int main(string[] args) {
	if (args.length != 3) {
		writefln("Usage: %s [host] [port]", args[0]);
		return 1;
	}

	Client.Params params;
	params.host = args[1];
	params.port = to!ushort(args[2]);

	auto client = Client.connect(params);
	if (!client) {
		writefln("Failed to connect.");
		return 1;
	}

	ClearDatabaseData(client);

	if (!client.execute("CREATE INDEX ON :Person(id);")) {
		writefln("Failed to create an index.");
		return 1;
	}
	client.discardAll();

	if (!client.execute(
				"CREATE (:Person:Entrepreneur {id: 0, age: 40, name: 'John', " ~
				"isStudent: false, score: 5.0});")) {
		writefln("Failed to add data.");
		return 1;
	}
	client.discardAll();

	if (!client.execute("MATCH (n) RETURN n;")) {
		writefln("Failed to read data.");
		return 1;
	}
	auto maybeData = client.fetchAll();
	if (maybeData.length) {
		const auto data = maybeData[0];
		writefln("Number of results: %s", data.length);
	}

	if (!client.execute("MATCH (n) RETURN n;")) {
		writefln("Failed to read data.");
		return 1;
	}

	Value[] maybeResult;
	while ((maybeResult = client.fetchOne()).length) {
		import std.algorithm;
		const auto value = maybeResult[0];
		if (value.type() == Type.Node) {
			const auto node = to!Node(value);

			auto labels = node.labels();
			string labelsStr = labels.join(":");

			auto props = node.properties();
			writefln("props: %s", props);
			// string s = props.map.each!((a) => a.key);
			string propsStr = "{ ";
			foreach (k, v; props) {
				propsStr ~= k ~ ":" ~ to!string(v) ~ " ";
			}
			propsStr ~= "}";
			writefln("%s %s", labelsStr, propsStr);
		}
	}

	ClearDatabaseData(client);

	return 0;
}

import memgraph;

import std.stdio, std.conv, std.array;

// Example adapted from advanced.cpp included in the mgclient git repo.

void ClearDatabaseData(ref Optional!Client client) {
	if (!client.execute("MATCH (n) DETACH DELETE n;", true)) {
		writefln("Failed to delete all data from the database: %s %s", client.status, client.error);
		assert(0);
	}
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

	if (!client.execute("CREATE INDEX ON :Person(id);", true)) {
		writefln("Failed to create an index: %s %s", client.status, client.error);
		return 1;
	}

	foreach (id; 0..100) {
		if (!client.execute(
					"CREATE (:Person:Entrepreneur {id: " ~ to!string(id) ~ ", age: 40, name: 'John', " ~
					"isStudent: false, score: 5.0});", true)) {
			writefln("Failed to add data: %s %s", client.status, client.error);
			return 1;
		}
	}

	if (!client.execute("MATCH (n) RETURN n;")) {
		writefln("Failed to read data: %s %s", client.status, client.error);
		return 1;
	}
	auto maybeData = client.fetchAll();
	if (maybeData.length)
		writefln("Number of results: %s", maybeData.length);

	if (!client.execute("MATCH (n) RETURN n;")) {
		writefln("Failed to read data: %s %s", client.status, client.error);
		return 1;
	}

	Value[] maybeResult;
	while ((maybeResult = client.fetchOne()).length) {
		import std.algorithm;
		const auto value = maybeResult[0];
		if (value.type() == Type.Node) {
			const auto node = to!Node(value);
			writefln("%s %s", node.labels.join(":"),
					"{" ~ node.properties.byKeyValue.map!(p => p.key ~ ":" ~ to!string(p.value)).join(" ") ~ "}");
		}
	}

	ClearDatabaseData(client);

	return 0;
}

import memgraph;

import std.stdio, std.conv, std.array;
import std.algorithm : map;

// Example adapted from advanced.cpp included in the mgclient git repo.

private void clearDatabaseData(ref Optional!Client client) {
	if (!client.run("MATCH (n) DETACH DELETE n;")) {
		writefln("Failed to delete all data from the database: %s %s", client.status, client.error);
		assert(0);
	}
}

int main(string[] args) {
	if (args.length != 3) {
		writefln("Usage: %s [host] [port]", args[0]);
		return 1;
	}

	Params params = { host: args[1], port: to!ushort(args[2]) };
	auto client = Client.connect(params);
	if (!client) {
		writefln("Failed to connect.");
		return 1;
	}

	clearDatabaseData(client);

	if (!client.run("CREATE INDEX ON :Person(id);")) {
		writefln("Failed to create an index: %s %s", client.status, client.error);
		return 1;
	}

	foreach (id; 0..100) {
		if (!client.run(
					"CREATE (:Person:Entrepreneur {id: " ~ to!string(id) ~ ", age: 40, name: 'John', " ~
					"isStudent: false, score: 5.0});")) {
			writefln("Failed to add data: %s %s", client.status, client.error);
			return 1;
		}
	}

	auto results = client.execute("MATCH (n) RETURN n;");

	/* TODO: calling summary on a non-fetched result crashes - why?
	auto summary = results.summary();
	writefln("map: ", summary);
	writefln("summary: {%s}", summary.byKeyValue.map!(p => p.key ~ ":" ~ to!string(p.value)).join(" "));
	*/

	size_t resultCount;
	foreach (r; results) {
		if (r.type() == Type.Node) {
			const auto node = to!Node(r);
			writefln("%s {%s}", node.labels.join(":"),
					node.properties.byKeyValue.map!(p => p.key ~ ":" ~ to!string(p.value)).join(" "));
		}
		resultCount++;
	}
	writefln("Summary: {%s}", results.summary.byKeyValue.map!(p => p.key ~ ":" ~ to!string(p.value)).join(" "));
	writefln("Number of results: %s", resultCount);

	clearDatabaseData(client);

	return 0;
}

import memgraph;

import std.stdio, std.conv, std.array;
import std.algorithm : map;
import std.datetime.stopwatch;

// Load testing the D bindings for memgraph.

private void clearDatabaseData(ref Client client) {
	if (!client.run("MATCH (n) DETACH DELETE n;")) {
		writefln("Failed to delete all data from the database: %s %s", client.status, client.error);
		assert(0);
	}
	writefln("cleared database...");
}

int main(string[] args) {
	if (args.length != 4) {
		writefln("Usage: %s host port N", args[0]);
		return 1;
	}

	Params params = { host: args[1], port: to!ushort(args[2]) };
	auto client = Client.connect(params);
	if (!client) {
		writefln("Failed to connect.");
		return 1;
	}

	immutable N = to!size_t(args[3]);

	clearDatabaseData(client);

	if (!client.run("CREATE INDEX ON :Person(id);")) {
		writefln("Failed to create an index: %s %s", client.status, client.error);
		return 1;
	}

	writefln("starting insert...");
	immutable insertStopWatch = StopWatch(AutoStart.yes);
	foreach (id; 0..N) {
		if (!client.run(
					"CREATE (:Person:Entrepreneur {id: " ~ to!string(id) ~ ", age: 40, name: 'John', " ~
					"isStudent: false, score: 5.0});")) {
			writefln("Failed to add data: %s %s", client.status, client.error);
			return 1;
		}
	}
	auto insertMs = insertStopWatch.peek.total!"msecs";
	writefln("inserted %d rows in %s ms (%s rows / ms)", N, insertMs, to!uint(cast(double)N / insertMs));

	writefln("starting select...");
	immutable selectStopWatch = StopWatch(AutoStart.yes);
	auto results = client.execute("MATCH (n) RETURN n;");

	size_t resultCount;
	foreach (r; results) {
		assert(r.length == 1);
		/*
		if (r[0].type() == Type.Node) {
			const auto node = to!Node(r[0]);
			writefln("%s {%s}", node.labels.join(":"),
					node.properties.map!(p => p.key ~ ":" ~ to!string(p.value)).join(" "));
		}
		*/
		resultCount++;
	}
	auto selectMs = selectStopWatch.peek.total!"msecs";
	writefln("selected %d rows in %s ms (%s rows / ms)", N, selectMs, to!uint(cast(double)N / selectMs));

	writefln("Summary: {%s}", results.summary.map!(p => p.key ~ ":" ~ to!string(p.value)).join(" "));
	writefln("Columns: %s", results.columns);
	writefln("Number of results: %s", resultCount);

	clearDatabaseData(client);

	return 0;
}

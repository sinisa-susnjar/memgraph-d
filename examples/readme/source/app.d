import std.stdio, std.conv;
import memgraph;

// D memgraph-d example from README.md

int main() {
  auto client = Client.connect();
  if (!client) {
    writefln("Failed to connect: %s", client.status);
    return 1;
  }

  if (!client.run("CREATE INDEX ON :Person(id);")) {
    writefln("Failed to create index: %s %s", client.status, client.error);
    return 1;
  }

  if (!client.run("CREATE (:Person:Entrepreneur {id: 0, age: 40, name: 'John', " ~
                  "isStudent: false, score: 5.0});")) {
    writefln("Failed to add data: %s %s", client.status, client.error);
    return 1;
  }

  auto results = client.execute("MATCH (n) RETURN n;");
  foreach (r; results)
    writefln("%s", r[0]);

  writefln("Summary: %s", results.summary);
  writefln("Columns: %s", results.columns);

  return 0;
}

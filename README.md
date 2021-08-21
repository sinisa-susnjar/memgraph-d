[![build](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/d.yml/badge.svg)](https://github.com/sinisa-susnjar/memgraph-d/actions) [![coverage](https://codecov.io/gh/sinisa-susnjar/memgraph-d/branch/main/graph/badge.svg?token=ILY7NOAXDF)](https://codecov.io/gh/sinisa-susnjar/memgraph-d)

# memgraph-d

D bindings for the memgraph DB

Memgraph DB is &copy; Memgraph Ltd., see https://memgraph.com

## Example
```d
import std.stdio, std.conv, std.algorithm, std.range;
import memgraph;

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
    foreach (r; results) {
        assert(r.length == 1);
        if (r[0].type == Type.Node) {
            const auto node = to!Node(r[0]);
            writefln("%s {%s}", node.labels.join(":"),
                     node.properties.map!(
                         p => p.key ~ ":" ~ to!string(p.value)).join(" "));
        }
    }
    writefln("Summary: {%s}",
             results.summary.map!(
                 p => p.key ~ ":" ~ to!string(p.value)).join(" "));
    writefln("Columns: %s", results.columns);

    return 0;
}
```

### Output

```
Person:Entrepreneur {score:5 age:40 id:0 isStudent:false name:John}
Summary: {cost_estimate:1 type:r planning_time:0.000198 has_more:false plan_execution_time:0.000329302 parsing_time:4.0088e-05}
Columns: ["n"]
```

## Prerequisites

To run the examples or the unit tests, a local Docker installation is required. Install Docker as appropriate for your platform.

    docker pull memgraph/memgraph

Then start a local memgraph container with e.g.:

    docker run -p 7687:7687 memgraph/memgraph --also-log-to-stderr --log-level=DEBUG

## Building the library

    dub build

This will pull the `mgclient` C interface for memgraph as a git submodule and build it locally.
Please refer to https://github.com/memgraph/mgclient for the build requirements.

## Building the examples

This package contains two examples that were adapted from the examples contained in the `mgclient` C interface library.

    cd examples/basic_c
    dub build
    ./run.sh

    cd examples/advanced
    dub build
    ./advanced 127.0.0.1 7687

## Generate local documentation

    dub build -b ddox

## Run unittests and generate coverage data

    dub test -b unittest-cov

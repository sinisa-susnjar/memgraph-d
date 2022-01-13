[![ubuntu](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/ubuntu.yml) [![macos](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/macos.yml/badge.svg)](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/macos.yml) [![windows](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/windows.yml/badge.svg)](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/windows.yml) [![coverage](https://codecov.io/gh/sinisa-susnjar/memgraph-d/branch/main/graph/badge.svg?token=ILY7NOAXDF)](https://codecov.io/gh/sinisa-susnjar/memgraph-d)

# memgraph-d

D bindings for the memgraph DB

Memgraph DB is &copy; Memgraph Ltd., see https://memgraph.com

Please note that all structs are only thin wrappers around the native mg_\* types and
that no copying or allocations are being made.

## Example
```d
import std.stdio, std.conv;
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
  foreach (r; results)
    writefln("%s", r[0]);

  writefln("Summary: %s", results.summary);
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

    docker run -p 7687:7687 --name memgraph memgraph/memgraph --also-log-to-stderr --log-level=DEBUG

subsequently:

    docker start memgraph

## Building the library

    dub build

This will pull the `mgclient` C interface for memgraph as a git submodule and build it locally.
Please refer to https://github.com/memgraph/mgclient for the build requirements.

## Building the examples

This package contains two examples that were adapted from the examples contained in the `mgclient` C interface library.

    cd examples/basic
    dub build
    ./run.sh

    cd examples/advanced
    dub build
    ./advanced 127.0.0.1 7687

## Generate local documentation

    dub build -b ddox

## Run unittests and generate coverage data

    dub test -b unittest-cov

## Some useful commands

### Start mgconsole via docker

    IP=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' memgraph`
    docker run -it --entrypoint=mgconsole memgraph/memgraph --host $IP --use-ssl=False

### Use mgconsole to run a cypher script

    docker run -i --entrypoint=mgconsole memgraph/memgraph --host $IP --use-ssl=False -output_format=csv < script.cql

# History

* v0.0.5 Reduced number of memory allocations by ~95%, added proper pagination when fetching results,
         using native D temporal types, @nogc where possible and many more small improvements.

[![build](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/d.yml/badge.svg)](https://github.com/sinisa-susnjar/memgraph-d/actions) [![coverage](https://codecov.io/gh/sinisa-susnjar/memgraph-d/branch/main/graph/badge.svg?token=ILY7NOAXDF)](https://codecov.io/gh/sinisa-susnjar/memgraph-d)

# memgraph-d

D bindings for the memgraph DB

Memgraph DB is &copy; Memgraph Ltd., see https://memgraph.com

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
    ./advanced localhost 7687

## Generate local documentation

    dub build -b ddox

## Run unittests and generate coverage data

    dub test -b unittest-cov

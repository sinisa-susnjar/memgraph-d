![example workflow](https://github.com/sinisa-susnjar/memgraph-d/actions/workflows/d.yml/badge.svg)

# memgraph-d

D bindings for the memgraph DB

Memgraph DB is &copy; Memgraph Ltd., see https://memgraph.com

## Run

docker pull memgraph/memgraph

docker run -p 7687:7687 memgraph/memgraph

docker run -p 7687:7687 memgraph/memgraph --also-log-to-stderr --log-level=DEBUG

## Generate local documentation

dub build -b ddox

## Run unittests and generate coverage data

DFLAGS="-cov -unittest" dub test

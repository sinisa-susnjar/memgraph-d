# memgraph-d

D bindings for the memgraph DB

## Run

docker pull memgraph/memgraph

docker run -p 7687:7687 memgraph/memgraph

docker run -p 7687:7687 memgraph/memgraph --also-log-to-stderr --log-level=DEBUG

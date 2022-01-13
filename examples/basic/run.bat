basic.exe 127.0.0.1 7687 "CREATE (c:City {name: 'Zagreb', population_size: 1000000})"
basic.exe 127.0.0.1 7687 "MATCH (c:City) RETURN c"
basic.exe 127.0.0.1 7687 "MATCH (c) DETACH DELETE c"

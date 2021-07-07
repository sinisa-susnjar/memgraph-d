# ./basic_c localhost 7687 'CREATE (c:City {name: "Zagreb", population_size: 1000000})'
./basic_c localhost 7687 'MATCH (c:City) RETURN c'

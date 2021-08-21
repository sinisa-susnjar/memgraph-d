module testutils;

version (unittest) {
	import memgraph;

	// Port where the memgraph container is listening.
	enum MEMGRAPH_PORT = 7688;

	bool canConnect() {
		import std.string, std.conv, std.stdio;
		auto params = mg_session_params_make();
		assert(params != null);

		mg_session_params_set_host(params, toStringz("127.0.0.1"));
		mg_session_params_set_port(params, to!ushort(MEMGRAPH_PORT));
		mg_session_params_set_sslmode(params, mg_sslmode.MG_SSLMODE_DISABLE);

		mg_session *session = null;
		immutable status = mg_connect(params, &session);
		mg_session_params_destroy(params);

		mg_session_destroy(session);

		return status == 0;
	}	// canConnect()

	// Start a memgraph container for unit testing if it is not already running.
	// Store the container id in $TMP/memgraph-d.container so it can be used in
	// other tests without having to start a new container each time.
	void startContainer() {
		import std.process, std.stdio, std.file, std.string;

		import std.conv;

		auto containerIdFileName = environment.get("TMP", "/tmp") ~ "/memgraph-d.container";

		auto startContainer = true;

		if (exists(containerIdFileName)) {
			// Read container id from temp storage.
			auto containerIdFile = File(containerIdFileName, "r");
			auto containerId = containerIdFile.readln();
			containerIdFile.close();

			// Check if the container is still up and running.
			auto ps = execute(["docker", "ps", "-q", "--no-trunc"]);
			assert(ps.status == 0);
			startContainer = false;

			if (ps.output.indexOf(containerId) < 0)
				startContainer = true;
		}

		if (startContainer) {
			import std.conv;

			// Pull the latest memgraph docker image.
			immutable pull = execute(["docker", "pull", "memgraph/memgraph"]);
			assert(pull.status == 0);

			// Start a new memgraph docker container.
			auto containerIdFile = File(containerIdFileName, "w");
			immutable run = execute(["docker", "run", "-d", "-p",
								to!string(MEMGRAPH_PORT) ~ ":7687", "-d", "memgraph/memgraph"]);
			assert(run.status == 0);

			// Store container id.
			auto containerId = run.output;
			containerIdFile.write(containerId);
			containerIdFile.close();

			// Need to wait a while until the container is spun up, otherwise connecting will fail.
			while (!canConnect()) {
				import core.thread.osthread, core.time;
				Thread.sleep(dur!("msecs")(250));
			}
		}
	}	// startContainer()

	// Create a client connection to the running unit test container.
	auto connectContainer() {
		startContainer(); // Make sure container is up.
		Params params;
		params.port = MEMGRAPH_PORT;
		return Client.connect(params);
	}	// connectContainer()

	// Create an index on the test data.
	void createTestIndex(ref Client client) {
		assert(client.run("CREATE INDEX ON :Person(id);"), client.error);
	}	// createTestIndex()

	// Delete the test data.
	void deleteTestData(ref Client client) {
		assert(client.run("MATCH (n) DETACH DELETE n;"), client.error);
	}	// deleteTestData()

	// Create some test data.
	void createTestData(ref Client client) {
		// Create a few nodes.
		assert(client.run(
			"CREATE (:Person:Entrepreneur {id: 0, age: 40, name: 'John', " ~
				"isStudent: false, score: 5.0});"), client.error);
		assert(client.run(
			"CREATE (:Person:Entrepreneur {id: 1, age: 20, name: 'Valery', " ~
				"isStudent: true, score: 5.0});"), client.error);
		assert(client.run(
			"CREATE (:Person:Entrepreneur {id: 2, age: 50, name: 'Peter', " ~
				"isStudent: false, score: 4.0});"), client.error);
		assert(client.run(
			"CREATE (:Person:Entrepreneur {id: 3, age: 30, name: 'Ray', " ~
				"isStudent: false, score: 9.0});"), client.error);
		assert(client.run(
			"CREATE (:Person:Entrepreneur {id: 4, age: 25, name: 'Olaf', " ~
				"isStudent: true, score: 10.0});"), client.error);

		// Create some relationships.
		assert(client.run(
			"MATCH (a:Person), (b:Person) WHERE a.name = 'John' AND b.name = 'Peter' " ~
				"CREATE (a)-[r:IS_MANAGER]->(b);"), client.error);
		assert(client.run(
			"MATCH (a:Person), (b:Person) WHERE a.name = 'Peter' AND b.name = 'Valery' " ~
				"CREATE (a)-[r:IS_MANAGER]->(b);"), client.error);
		assert(client.run(
			"MATCH (a:Person), (b:Person) WHERE a.name = 'Valery' AND b.name = 'Olaf' " ~
				"CREATE (a)-[r:IS_MANAGER]->(b);"), client.error);
	}	// createTestData()

}

module testutils;

version (unittest) {
	import memgraph;

	// Port where the memgraph container is listening.
	enum MEMGRAPH_PORT = 7688;

	bool canConnect() {
		import std.string, std.conv, std.stdio;
		auto params = mg_session_params_make();
		assert(params != null);

		mg_session_params_set_host(params, toStringz("localhost"));
		mg_session_params_set_port(params, to!ushort(MEMGRAPH_PORT));
		mg_session_params_set_sslmode(params, mg_sslmode.MG_SSLMODE_DISABLE);

		mg_session *session = null;
		int status = mg_connect(params, &session);
		mg_session_params_destroy(params);

		// writefln("canConnect: %s", fromStringz(mg_session_error(session)));

		mg_session_destroy(session);

		return status == 0;
	}	// canConnect()

	// Start a memgraph container for unit testing if it is not already running.
	// Store the container id in $TMP/memgraph-d.container so it can be used in
	// other tests without having to start a new container each time.
	void startContainer() {
		import std.process, std.stdio, std.file, std.string;

		import std.conv;
		// writefln("startContainer() on localhost:%s", to!string(MEMGRAPH_PORT));

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

		// writefln("startContainer(): %s", startContainer);

		if (startContainer) {
			import std.conv;

			// writefln("startContainer(): pull");

			// Pull the latest memgraph docker image.
			auto pull = execute(["docker", "pull", "memgraph/memgraph"]);
			assert(pull.status == 0);

			// writefln("startContainer(): run");

			// Start a new memgraph docker container.
			auto containerIdFile = File(containerIdFileName, "w");
			auto run = execute(["docker", "run", "-d", "-p", to!string(MEMGRAPH_PORT) ~ ":7687", "-d", "memgraph/memgraph"]);
			assert(run.status == 0);

			// Store container id.
			auto containerId = run.output;
			containerIdFile.write(containerId);
			containerIdFile.close();

			// writefln("startContainer(): %s", containerId);

			// Need to wait a while until the container is spun up, otherwise connecting will fail.
			while (!canConnect()) {
				import core.thread.osthread, core.time;
				// writefln("can't connect yet");
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
	void createTestIndex(ref Optional!Client client) {
		assert(client.execute("CREATE INDEX ON :Person(id);", true), client.error);
	}	// createTestIndex()

	// Delete the test data.
	void deleteTestData(ref Optional!Client client) {
		assert(client.execute("MATCH (n) DETACH DELETE n;", true), client.error);
	}	// deleteTestData()

	// Create some test data.
	void createTestData(ref Optional!Client client) {
		assert(client.execute("CREATE (:Person:Entrepreneur {id: 0, age: 40, name: 'John', isStudent: false, score: 5.0});", true),
				client.error);
	}	// createTestData()

}

module testutils;

version (unittest) {

	// Start a memgraph container for unit testing if it is not already running.
	// Store the container id in $TMP/memgraph-d.container so it can be used in
	// other tests without having to start a new container each time.
	void startContainer() {
		import std.process, std.stdio, std.file, std.string;

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
			// Pull the latest memgraph docker image.
			auto pull = execute(["docker", "pull", "memgraph/memgraph"]);
			assert(pull.status == 0);

			// Start a new memgraph docker container.
			auto containerIdFile = File(containerIdFileName, "w");
			auto run = execute(["docker", "run", "-d", "-p", "7688:7687", "-d", "memgraph/memgraph"]);
			assert(run.status == 0);

			// Store container id.
			auto containerId = run.output;
			containerIdFile.write(containerId);
			containerIdFile.close();

			// Need to wait a while until the container is spun up, otherwise connecting will fail.
			import core.thread.osthread, core.time;
			Thread.sleep(dur!("msecs")(1000));
		}
	}	// startContainer()

}

import memgraph;

import std.stdio, std.string, std.conv;

// Example adapted from advanced.cpp included in the mgclient git repo.

void ClearDatabaseData(Client client) {
	if (!client.Execute("MATCH (n) DETACH DELETE n;")) {
		writefln("Failed to delete all data from the database.");
		assert(0);
	}
	client.DiscardAll();
}

/*
int main(int argc, char *argv[]) {

  {

    if (!client->Execute("CREATE INDEX ON :Person(id);")) {
      std::cerr << "Failed to create an index." << std::endl;
      return 1;
    }
    client->DiscardAll();

    if (!client->Execute(
            "CREATE (:Person:Entrepreneur {id: 0, age: 40, name: 'John', "
            "isStudent: false, score: 5.0});")) {
      std::cerr << "Failed to add data." << std::endl;
      return 1;
    }
    client->DiscardAll();

    if (!client->Execute("MATCH (n) RETURN n;")) {
      std::cerr << "Failed to read data." << std::endl;
      return 1;
    }
    if (const auto maybe_data = client->FetchAll()) {
      const auto data = *maybe_data;
      std::cout << "Number of results: " << data.size() << std::endl;
    }

    if (!client->Execute("MATCH (n) RETURN n;")) {
      std::cerr << "Failed to read data." << std::endl;
      return 1;
    }
    while (const auto maybe_result = client->FetchOne()) {
      const auto result = *maybe_result;
      if (result.size() < 1) {
        continue;
      }
      const auto value = result[0];
      if (value.type() == mg::Value::Type::Node) {
        const auto node = value.ValueNode();
        auto labels = node.labels();
        std::string labels_str = std::accumulate(
            labels.begin(), labels.end(), std::string(""),
            [](const std::string &acc, const std::string_view value) {
              return acc + ":" + std::string(value);
            });
        const auto props = node.properties();
        std::string props_str =
            std::accumulate(
                props.begin(), props.end(), std::string("{"),
                [](const std::string &acc, const auto &key_value) {
                  const auto &[key, value] = key_value;
                  std::string value_str;
                  if (value.type() == mg::Value::Type::Int) {
                    value_str = std::to_string(value.ValueInt());
                  } else if (value.type() == mg::Value::Type::String) {
                    value_str = value.ValueString();
                  } else if (value.type() == mg::Value::Type::Bool) {
                    value_str = std::to_string(value.ValueBool());
                  } else if (value.type() == mg::Value::Type::Double) {
                    value_str = std::to_string(value.ValueDouble());
                  } else {
                    std::cerr
                        << "Uncovered converstion from data type to a string"
                        << std::endl;
                    std::exit(1);
                  }
                  return acc + " " + std::string(key) + ": " + value_str;
                }) +
            " }";
        std::cout << labels_str << " " << props_str << std::endl;
      }
    }

    ClearDatabaseData(client.get());
  }
  return 0;
}
*/

int main(string[] args) {
	if (args.length != 3) {
		writefln("Usage: %s [host] [port]", args[0]);
		return 1;
	}

	Client.Init();

	Client.Params params;
	params.host = args[1];
	params.port = to!ushort(args[2]);

	auto client = Client.Connect(params);
	if (!client) {
		writefln("Failed to connect.");
		return 1;
	}

	ClearDatabaseData(client.value);

	/*
	mg_session_params *params = mg_session_params_make();
	if (!params) {
		writefln("failed to allocate session parameters");
		return 1;
	}
	mg_session_params_set_host(params, toStringz(args[1]));
	mg_session_params_set_port(params, to!ushort(args[2]));
	mg_session_params_set_sslmode(params, mg_sslmode.MG_SSLMODE_DISABLE);

	mg_session *session = null;
	int status = mg_connect(params, &session);
	mg_session_params_destroy(params);
	if (status < 0) {
		writefln("failed to connect to Memgraph: %s", fromStringz(mg_session_error(session)));
		mg_session_destroy(session);
		return 1;
	}

	if (mg_session_run(session, toStringz(args[3]), null, null, null, null) < 0) {
		writefln("failed to execute query: %s", fromStringz(mg_session_error(session)));
		mg_session_destroy(session);
		return 1;
	}

	if (mg_session_pull(session, null)) {
		writefln("failed to pull results of the query: %s", fromStringz(mg_session_error(session)));
		mg_session_destroy(session);
		return 1;
	}

	mg_result *result;
	int rows = 0;
	while ((status = mg_session_fetch(session, &result)) == 1) {
		rows++;
	}

	if (status < 0) {
		writefln("error occurred during query execution: %s", fromStringz(mg_session_error(session)));
	} else {
		writefln("query executed successfuly and returned %d rows", rows);
	}
	*/

	Client.Finalize();

	return 0;
}

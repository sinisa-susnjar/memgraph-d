import memgraph;

import std.stdio, std.string, std.conv;

// Example adapted from basic.c included in the mgclient git repo.

int main(string[] args)
{
	if (args.length != 4) {
		writefln("Usage: %s [host] [port] [query]", args[0]);
		return 1;
	}

	mg_init();
	writefln("mgclient version: %s", fromStringz(mg_client_version()));

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

	mg_session_destroy(session);
	mg_finalize();

	return 0;
}

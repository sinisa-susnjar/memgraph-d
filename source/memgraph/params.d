/// Provides connection parameters for memgraph.
module memgraph.params;

import std.string, std.conv;

import memgraph.mgclient;

/// An object containing connection parameters for `Client.connect(Params)`.
struct Params {
	/// DNS resolvable name of host to connect to. Either one of host or
	/// address parameters must be specified (defaults to `localhost`).
	string host = "localhost";
	/// Port number to connect to at the server host (defaults to 7687).
	ushort port = 7687;
	/// Numeric IP address of host to connect to. This should be in the
	/// standard IPv4 address format. You can also use IPv6 if your machine
	/// supports it. Either one of host or address parameters must be
	/// specified.
	string address;
	/// Username, if authentication is required.
	string username;
	/// Password to be used if the server demands password authentication.
	string password;
	/// This option determines whether a secure connection will be negotiated
	/// with the server. There are 2 possible values:
	/// - `MG_SSLMODE_DISABLE`
	///   Only try a non-SSL connection (default).
	/// - `MG_SSLMODE_REQUIRE`
	///   Only try an SSL connection.
	mg_sslmode sslMode = mg_sslmode.MG_SSLMODE_DISABLE;
	/// This parameter specifies the file name of the client SSL certificate.
	/// It is ignored in case an SSL connection is not made.
	string sslCert;
	/// This parameter specifies the location of the secret key used for the
	/// client certificate. This parameter is ignored in case an SSL connection
	/// is not made.
	string sslKey;
	/// Useragent used when connecting to memgraph, defaults to
	/// Alternate name and version of the client to send to server. Default is
	/// "memgraph-d/major.minor.patch".
	string userAgent;
	/// A pointer to a function of prototype `mg_trust_callback_type`:
	///   int trust_callback(const char *hostname, const char *ip_address,
	///                      const char *key_type, const char *fingerprint,
	///                      void *trust_data);
	///
	/// After performing the SSL handshake, `mg_connect` will call this
	/// function providing the hostname, IP address, public key type and
	/// fingerprint and user provided data. If the function returns a non-zero
	/// value, SSL connection will be immediately terminated. This can be used
	/// to implement TOFU (trust on first use) mechanism.
	/// It might happen that hostname can not be determined, in that case the
	/// trust callback will be called with hostname="undefined".
	mg_trust_callback_type sslTrustCallback;
	/// Additional data that will be provided to the sslTrustCallback function.
	void *sslTrustData;

	/// Destructor, destroys the internal session parameters.
	~this() {
		if (ptr_)
			mg_session_params_destroy(ptr_);
	}

package:
	const (mg_session_params *) ptr() {
		if (!ptr_)
			ptr_ = mg_session_params_make();
		if (host.length)
			mg_session_params_set_host(ptr_, toStringz(host));
		if (address.length)
			mg_session_params_set_address(ptr_, toStringz(address));
		if (port)
			mg_session_params_set_port(ptr_, port);
		if (username.length)
			mg_session_params_set_username(ptr_, toStringz(username));
		if (password.length)
			mg_session_params_set_password(ptr_, toStringz(password));

		if (!userAgent.length)
			userAgent = to!string("memgraph-d/" ~ fromStringz(mg_client_version()));
		mg_session_params_set_user_agent(ptr_, toStringz(userAgent));

		mg_session_params_set_sslmode(ptr_, sslMode);
		if (sslCert.length)
			mg_session_params_set_sslcert(ptr_, toStringz(sslCert));
		if (sslKey.length)
			mg_session_params_set_sslkey(ptr_, toStringz(sslKey));

		if (sslTrustCallback)
			mg_session_params_set_trust_callback(ptr_, sslTrustCallback);
		if (sslTrustData)
			mg_session_params_set_trust_data(ptr_, sslTrustData);

		return ptr_;
	}

private:
	/// Pointer to private `mg_session_params` instance that
	/// contains all parameters for this `Params` structure.
	mg_session_params *ptr_;
}

unittest {
	Params p;

	assert(p.host == "localhost");
	assert(p.port == 7687);
	assert(p.sslMode == mg_sslmode.MG_SSLMODE_DISABLE);

	p.address = "127.0.0.1";
	p.username = "sini";
	p.password = "whatever";

	p.sslCert = "someCertFile";
	p.sslKey = "someKeyFile";

	ubyte[] trustData = cast(ubyte[])"trustData";
	p.sslTrustData = cast(void*)trustData;
	p.sslTrustCallback = (hostname, ip_address, key_type, fingerprint, trust_data) { return 0; };

	assert(p.ptr() != null);
}

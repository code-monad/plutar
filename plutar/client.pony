use "http"
use "net_ssl"
use "debug"

trait SimpleClient
	
	be cancelled() =>
		Debug.out("-- response cancelled --")
		
	be failed(reason: HTTPFailureReason) =>
		match reason
			| AuthFailed =>
			Debug.err("-- auth failed --")
			| ConnectFailed =>
			Debug.err("-- connect failed --")
			| ConnectionClosed =>
			Debug.err("-- connection closed --")
		end
		
	be have_response(response: Payload val) =>
		"""
		Process return the the response message.
		"""
		if response.status == 0 then
			Debug.out("Failed")
			return
		end
		
	// Print the status and method
	Debug.out(
	"Response " +
    response.status.string() + " " +
    response.method)
	
    // Print the body if there is any.  This will fail in Chunked or
    // Stream transfer modes.
    try
      let body = response.body()?
      for piece in body.values() do
          Debug.out(piece as String)
	  end
	end

	be have_body(data: ByteSeq val)
	=>
    """
    Some additional response data.
    """
    None

	be finished() =>
	"""
	End of the response data.
	"""
    Debug.out("-- end of body --")	


actor Poster is SimpleClient
	
	new create(auth: AmbientAuth, sslctx: (SSLContext| None), url: URL, content: String, timeout: U64 = 6000) =>
		 
		// The Client manages all links.
		let client = HTTPClient(auth, consume sslctx where keepalive_timeout_secs = timeout.u32())
		// The Notify Factory will create HTTPHandlers as required.  It is
		// done this way because we do not know exactly when an HTTPSession
		// is created - they can be re-used.
		let dumpMaker = recover val ClientFactory.create(this) end
		
		try
			// Start building a GET request.
			let req = Payload.request("POST", url)
			req("User-Agent") = "Plutra"
			req("Content-Type") = "application/json"
			req.add_chunk(content)
			// Submit the request
			let sentreq = client(consume req, dumpMaker)?
			
			// Could send body data via `sentreq`, if it was a POST
			
		else
			Debug.out("Malformed URL: " + url.string())
		end


actor Getter is SimpleClient
	
	new create(auth: AmbientAuth, sslctx: (SSLContext| None), url: URL, timeout: U64 = 6000) =>
		// The Client manages all links.
		let client = HTTPClient(auth, consume sslctx where keepalive_timeout_secs = timeout.u32())
		// The Notify Factory will create HTTPHandlers as required.  It is
		// done this way because we do not know exactly when an HTTPSession
		// is created - they can be re-used.
		let dumpMaker = recover val ClientFactory.create(this) end
		
		try
			// Start building a GET request.
			let req = Payload.request("GET", url)
			req("User-Agent") = "Plutra"
			// Submit the request
			let sentreq = client(consume req, dumpMaker)?
			// Could send body data via `sentreq`, if it was a POST
		else
			Debug.out("Malformed URL: " + url.string())
		end

type SimpleClientType is (Poster | Getter)

class ClientFactory is HandlerFactory

	let _main: SimpleClientType

	new iso create(main': SimpleClientType tag) =>
		_main = main'

	fun apply(session: HTTPSession): HTTPHandler ref^ =>
		ClientHandler.create(_main, session)


class ClientHandler is HTTPHandler

	let _main: SimpleClientType
	let _session: HTTPSession

	new ref create(main': SimpleClientType, session: HTTPSession) =>
		_main = main'
		_session = session

	fun ref apply(response: Payload val) =>
		_main.have_response(response)

	fun ref chunk(data: ByteSeq val) =>
		_main.have_body(data)

	fun ref finished() =>

		_main.finished()
		_session.dispose()

	fun ref cancelled() =>
		_main.cancelled()

	fun ref failed(reason: HTTPFailureReason) =>
		_main.failed(reason)

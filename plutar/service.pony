use "http"
use "json"
use "debug"

class ListenHandler

	new iso create() => None

	fun ref listening(server: HTTPServer ref) =>
		try
			(let host, let service) = server.local_address().name()?
			Debug.out("connected: " + host)
		else
			Debug.out("failed to get local address.")
		end

	fun ref not_listening(server: HTTPServer ref) =>
		Debug.out("Failed to listen")

	fun ref closed(server: HTTPServer ref) =>
		Debug.out("Closing...")

class HandlerMaker is HandlerFactory

	let remote_host: String
	let _auth: AmbientAuth
	let _config: Config val
	
	new val create(remote_host': String, auth': AmbientAuth, config': Config val) =>
		remote_host = remote_host'
		_auth = auth'
		_config = config'

	fun apply(session: HTTPSession): HTTPHandler^ =>
		ServiceHandler.create(session, remote_host.string(), _auth, _config.modules_doc)

class ServiceHandler is HTTPHandler

	let _session: HTTPSession
	let _base: String
	let _auth: AmbientAuth
	let _modules_config: JsonObject val

	var _response: Payload = Payload.response()

	new ref create(session: HTTPSession, remote_host': String, auth': AmbientAuth, modules_config' : JsonObject val) =>
		_session = session
		_base = remote_host'
		_auth = auth'
		_modules_config = modules_config'

	fun ref apply(request: Payload val) =>
		Debug.out("Request called: " + request.url.path)
		_response.status = StatusNoContent()
		
		try
			let body: String ref = recover String end
			for data in request.body()?.values() do
				body.append(data)
			end
			
			let json_parser = JsonDoc
			
			
			json_parser.parse(body.string())?
			let content: JsonObject =json_parser.data as JsonObject
			let msg: QQMessage = QQMessage.parse(content)?
			match MessageRouter(msg, _modules_config)
				| let repl : QQMessage =>
				let target = try URL.valid(_base + "/send_msg")? end as URL
				Debug.out("Replied: " + repl.raw() + " to " + target.string())
				Poster.create(_auth, None, target, repl.raw())
			end
		else
			Debug.out("Error msg! ")
			try
				let body: String ref = recover String end
				for data in request.body()?.values() do
					body.append(data)
				end
				Debug.out(body.string())
			end
		end

	fun ref finished() =>
		_session(_response = Payload.response())

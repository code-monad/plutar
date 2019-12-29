use "files"
use "json"
use "debug"

class Config
	let local_host : String
	let local_port : String
	let remote_host : String
	let interval : I64

	let _config_doc : JsonObject
	let modules_doc: JsonObject
	
	new val create(path: FilePath)? =>
		match OpenFile(path)
			| let file: File =>
			let content = file.read_string(file.size())
			let parser = JsonDoc
			parser.parse(content.string())?

			_config_doc = (parser.data as JsonObject).data("config")? as JsonObject
			modules_doc = (parser.data as JsonObject).data("modules")? as JsonObject
			for k in modules_doc.data.keys() do
				let data = match modules_doc.data(k)?
				|let v: Stringable => v.string()
			else
				"Unstringable part"
			end
			Debug.out("key:" + k + ", value: " + data)
			end

			local_host = try _config_doc.data("host")? as String else "0.0.0.0" end
			local_port = try _config_doc.data("port")? as String else "5700" end
			remote_host = try _config_doc.data("remote")? as String else "" end
			interval = try _config_doc.data("interval")? as I64 else 0 end			
		else
			error
		end
	
	fun string() : String =>
		_config_doc.string(" ", true)

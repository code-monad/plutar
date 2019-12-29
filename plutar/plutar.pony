use "json"
use "files"
use "debug"
use "http"
use "cli"

actor Main
	new create(env: Env) =>
		try
			let command =
			match recover val CLI.parse(env.args, env.vars) end
				| let c: Command val => c
				| (let exit_code: U8, let msg: String) =>
				if exit_code == 0 then
					env.out.print(msg)
				else
					env.out.print(CLI.help())
					env.exitcode(exit_code.i32())
				end
				return
			end

			let config_dest : String = command.option("config").string()

			Debug.out("Using config: " + config_dest)

			let logger = CommonLog(env.out)

			let config_path = FilePath(env.root as AmbientAuth, config_dest)?
			try
				let config = Config(config_path)?
				Debug.out(config.string())
				let limit : USize = USize.from[U64](command.arg("limit").u64())
				let service = config.local_port
				let host = config.local_host
				let auth = try
					env.root as AmbientAuth
				else
					env.out.print("unable to use network")
				return
				end
				HTTPServer(auth, ListenHandler, HandlerMaker(config.remote_host, auth, config), logger
				where service = service, host=host, limit=limit, reversedns=auth)			
			else
				env.out.print("error config file " + config_dest)
				return
			end
		end
		

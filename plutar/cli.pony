use "cli"

primitive CLI
	fun parse(
		args: Array[String] box,
		envs: (Array[String] box | None)
		) : (Command | (U8, String))
	=>
	try
		match CommandParser(_spec()?).parse(args, envs)
			|let c: Command => c
			|let h: CommandHelp => (0, h.help_string())
			|let e: SyntaxError => (1, e.string())
		end
	else
		(-1, "unable to parse command")
	end


	fun help(): String =>
		try Help.general(_spec()?).help_string() else "" end

	fun _spec(): CommandSpec ? =>
		CommandSpec.leaf(
		"lutra",
		"A minimal Secure-Shell manager",
		[
		  OptionSpec.string(
		  "config", "Specify a config file", 'c', "config.json")
		],
		[ ArgSpec.u64(
		  "limit", "worker limitation", 100)
		]
		)?.>add_help("help", "Get this page.")?

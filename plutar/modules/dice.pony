use ".."
use "random"
use "time"
use "sform"
use "debug"

type DiceCommandData is (U64, U64) // Times, Face

primitive DiceCommandPrint
	fun apply(data : DiceCommandData) : String =>
		Sform(".r%d%")(data._1)(data._2).string()


primitive DiceParser
	fun apply(cmd_msg: QQMessage, formatter: String, error_lint: String = "错误的roll指令！"): QQMessage =>
		try
			let cmd = cmd_msg.content.substring(2)
			let s: Array[String val] = cmd.split("d ")

			let comment: String ref = recover ref String end
			for c in s.slice(2).values() do
				comment.append(c)
			end
			
			
			let data: DiceCommandData = (s(0)?.u64()?, s(1)?.u64()?)
			var caller : String
			var repl_to : I64
			if cmd_msg.message_type is PrivateMessage then
				caller = ""
				repl_to = cmd_msg.sender.user_id
			else
				caller = CQ.at(cmd_msg.sender.user_id)
				repl_to = cmd_msg.group_id
			end
			
			let msg: QQMessage = QQMessage.build(parse(caller, data, comment.string(), formatter) where repl_to = repl_to, message_type' = cmd_msg.message_type, group_id' = cmd_msg.group_id)
			msg
		else
			QQMessage.build(error_lint where repl_to = cmd_msg.sender.user_id)
		end

	fun parse(caller: String, command: DiceCommandData, comment: String, formatter: String) : String =>
		var result = recover String end
		Debug.out("Formatter is " + formatter)
		result = Sform(formatter)(caller)(DiceCommandPrint(command))(act(command).string())(comment).string()
		
		result
		

	fun act(command: DiceCommandData) : U64 =>
		let rand = Rand(U64.from[I64](Time.now()._1), U64.from[I64](Time.now()._2))
		var result: U64 = Dice(rand)(command._1, command._2)
		result

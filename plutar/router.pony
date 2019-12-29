
use "debug"
use "json"

use "./modules"

primitive IsBotCommand
	fun apply(content: String, self: I64): Bool => content.at(".") or IsAtSelf(content, self)

primitive IsAtSelf
	fun apply(content: String, self: I64): Bool => self == CQ.get_at(content)

primitive CommandMatcher
	fun apply(command: String, self: I64): BotCommand =>
		if command.at("r", 1) then
			DiceCommand
		elseif IsAtSelf(command, self) then // Here a CQ included, check if self is the same
			Debug.out("At myself")
		else
			None
		end

primitive MessageRouter
	fun apply(msg: QQMessage, modules_config: JsonObject val): (QQMessage | None) =>
		Debug.out(msg.raw())
		_parse(msg, modules_config)

	fun _parse(msg: QQMessage, modules_config: JsonObject val) : (QQMessage | None) =>
		if IsBotCommand(msg.content, msg.self) then
			Debug.out(msg.sender.nickname + " called [" + (msg.content) + "]")
			match CommandMatcher(msg.content, msg.self)
				| DiceCommand =>
				Debug.out("DiceCommand")
				try
					let dice_config: JsonObject val = modules_config.data("Dice")? as JsonObject val
					Debug.out("dice config: " + dice_config.string())
					if dice_config.data("enable")? as Bool then
						return DiceParser(msg, dice_config.data("formatter")? as String)
					end
				end
			end
			
		else
			Debug.out("Normal Message or unrecognized command, skipped.")
		end

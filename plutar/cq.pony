primitive CQ
	fun at(person: I64) : String =>
		"[CQ:at,qq="+person.string()+"]"

	fun get_at(message: String) : I64 =>
		try
			let chopped: String = message.split_by("[CQ:at,qq=")(1)?
			let id = chopped.substring(0, chopped.find("]")?)
			id.i64()?
		else
			0
		end

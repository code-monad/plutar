use "json"
use "debug"

primitive PostTypeMessage
	fun string(): String => GetPostType.to_string(this)
primitive PostTypeNotice
	fun string(): String=> GetPostType.to_string(this)

type PostType is (PostTypeMessage | PostTypeNotice)

primitive PrivateMessage
	fun string(): String => "private"

primitive DiscussMessage
	fun string(): String => "discuss"

primitive GroupMessage
	fun string(): String => "group"


type MessageType is (PrivateMessage | DiscussMessage | GroupMessage | None)

primitive GetPostType
	fun apply(post_type: String) : (PostType|None) =>
		match post_type
			| "message" => PostTypeMessage
			| "notice" => PostTypeNotice
		end

	fun to_string(post_type: PostType) : String=>
		match post_type
			| PostTypeMessage => "message"
			| PostTypeNotice => "notice"
		end

primitive GetMessageType
	fun apply(message_type: String) : MessageType       =>
		match message_type
			| "private" => PrivateMessage
			| "discuss" => DiscussMessage
			| "group" => GroupMessage
		end
		
	fun to_string(message_type: MessageType) : String=>
		match message_type
			| PrivateMessage => "private"
			| DiscussMessage => "discuss"
			| GroupMessage => "group"
			| None => "private"
		end

	fun repl_field(message_type: MessageType) : String =>
		match message_type
			| PrivateMessage => "user_id"
			| DiscussMessage => "discuss_id"
			| GroupMessage => "group_id"
			| None => "private"
		end
		
primitive QQMessagePrint
	fun apply(msg: QQMessage box): String =>
		let out = recover String end
		out.>append("[self]:").append(msg.self.string())
		out.>append(" [content]:\"").>append(msg.content.string()).append("\"")
		out

primitive Male
primitive Female
type Gender is (Male | Female)

primitive GetGender
	fun apply(gender: String) : (Gender | None) =>
		match gender
			| "male" => Male
			| "female" => Female
		end

class People
	let user_id: I64
	let sex: (Gender | None)
	let age: I64
	let nickname: String

	new create(user_id': I64, sex': String, age': I64, nickname': String) =>
		user_id = user_id'
		sex = GetGender(sex')
		age = age'
		nickname = nickname'

	new anonymous() =>
		user_id = 0
		sex = None
		age = 0
		nickname = ""
		
class QQMessage
	let msg: JsonObject
	let id: I64
	let group_id: I64
	let self: I64
	let post_type: PostType
	let message_type: MessageType
	var content: String
	let sender: People
	
	new parse(msg': JsonObject)? =>
		msg = msg'
		id = try msg.data("message_id")? as I64 else 0 end
		self = try msg.data("self_id")? as I64 else 0 end
		post_type = GetPostType(msg.data("post_type")? as String) as PostType
		content = try msg.data("message")? as String else "" end
		message_type = GetMessageType( try msg.data("message_type")? as String else "" end)
		group_id =
			match  message_type
				| GroupMessage => try msg.data("group_id")? as I64 else 0 end
				| DiscussMessage => try msg.data("group_id")? as I64 else 0 end
			else
				0
			end
					
		sender =
			match msg.data("sender")?
				| let s: JsonObject =>
				People.create(
				try s.data("user_id")? as I64 else 0 end,
				try s.data("sex")? as String else "" end,
				try s.data("age")? as I64 else 0 end,
				try s.data("nickname")? as String else "" end)
			else
				People.anonymous()
			end

	new build(content': String = "", repl_to: I64 = 0, group_id': I64 = 0,message_type': MessageType = PrivateMessage) =>
		msg = recover JsonObject end
		id = 0
		self = 0
		post_type = PostTypeMessage
		content = content'
		group_id = group_id'
		message_type = message_type'
		sender = People.anonymous()
		msg.data("message") = content
		msg.data("message_type") = message_type.string()
		match message_type
			| GroupMessage => msg.data("group_id") = group_id
			| DiscussMessage => msg.data("discuss_id") = group_id
		end
		msg.data(GetMessageType.repl_field(message_type)) = repl_to

	fun string(): String =>
		QQMessagePrint(this)

	fun raw(): String =>
		msg.string()

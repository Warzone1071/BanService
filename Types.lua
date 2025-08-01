export type BanData = {
	IsBanned: boolean,
	Reason: string,
	Duration: number,
	BanTime: number,
	BannedBy: number,
}

export type BanType = "ban" | "globalban" | "offlineban"
export type UnbanType = "Unban" | "UnbanOffline"
export type MessageType = "print" | "warn"

export type EmbedField = {
	name: string,
	value: string,
	inline: boolean,
}

export type Author = {
	name: string,
	icon_url: string?,
	url: string?,
}

export type Embed = {
	author: Author?,
	title: string?,
	description: string?,
	fields: { [number]: EmbedField }?,
	thumbnail: { url: string }?,
	color: number?,
	footer: any?,
	timestamp: string?,
	image: { url: string }?,
}

export type WebhookQueueData = {
	content: string?,
	embeds: { [number]: Embed }?,
	file: any?,
}

export type WebhookObject = {
	_id: string,
	_token: string,
	_instance: string,

	colors: {
		red: number,
		green: number,
		blue: number,
		black: number,
		yellow: number,
	},

	Queue: (self: WebhookObject, data: WebhookQueueData, threadId: string?) -> (any?),

	createEmbed: (
		self: WebhookObject,
		title: string,
		description: string,
		fields: { [number]: EmbedField }?,
		thumbnailUrl: string?
	) -> (),

	sendAuthorEmbed: (
		self: WebhookObject,
		author: Author,
		description: string,
		fields: { [number]: EmbedField }?,
		thumbnailUrl: string?
	) -> (),

	createAuthorEmbed: (
		self: WebhookObject,
		author: Author,
		description: string,
		fields: { [number]: EmbedField }?,
		thumbnailUrl: string?
	) -> (),

	SetPreventDuplicates: (self: WebhookObject, state: boolean) -> (),
	GetPreventDuplicates: (self: WebhookObject) -> boolean,

	getEnabled: (self: WebhookObject) -> {
		Keyboard: boolean,
		Gamepad: boolean,
		Touch: boolean,
	},

	getPlatform: (self: WebhookObject) -> string,

	isController: (self: WebhookObject) -> boolean,

	isVR: (self: WebhookObject) -> boolean,

	getServerType: (self: WebhookObject) -> string,
}

return {}

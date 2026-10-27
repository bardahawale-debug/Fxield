local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local OWNER_USERNAME = "FxplayzOfficial"
local OWNER_USER_ID_OVERRIDE = 0

local ENTRIES = {}

local function add(path, className, source)
	table.insert(ENTRIES, { path = path, class = className, source = source })
end

add("ReplicatedStorage/Fxield/Shared/CommandDefinitions", "ModuleScript", [=[
local Constants = require(script.Parent.Constants)
local Schema = require(script.Parent.ConfigSchema)

local L = Constants.Levels

local function A(name, argType, extra)
	local arg = { name = name, type = argType }
	if extra then
		for k, v in pairs(extra) do
			arg[k] = v
		end
	end
	return arg
end

local featureOptions = {}
for _, field in ipairs(Schema.Fields) do
	local feature = field.key:match("^features%.(.+)$")
	if feature then
		table.insert(featureOptions, feature)
	end
end

local defs = {
	{ name = "help", aliases = { "?" }, description = "Show an overview, or details for one command.", usage = "help [command]", category = "General", level = L.Member, clientOnly = true, args = { A("command", "string", { optional = true }) } },
	{ name = "commands", aliases = { "cmds" }, description = "List the commands you can use, optionally by category.", usage = "commands [category]", category = "General", level = L.Member, clientOnly = true, args = { A("category", "string", { optional = true }) } },
	{ name = "search", aliases = { "find" }, description = "Search commands by name, alias or description.", usage = "search <text>", category = "General", level = L.Member, clientOnly = true, args = { A("text", "text") } },
	{ name = "settings", description = "Open the settings page.", usage = "settings", category = "General", level = L.Member, clientOnly = true },
	{ name = "theme", description = "Show or change the interface theme.", usage = "theme [dark|midnight|light]", category = "General", level = L.Member, clientOnly = true, args = { A("theme", "enum", { optional = true, options = { "dark", "midnight", "light" } }) } },
	{ name = "guiscale", aliases = { "scale" }, description = "Show or set the interface scale (0.7 to 1.6).", usage = "guiscale [scale]", category = "General", level = L.Member, clientOnly = true, args = { A("scale", "number", { optional = true, min = 0.7, max = 1.6 }) } },
	{ name = "history", description = "Show your recent commands.", usage = "history", category = "General", level = L.Member, clientOnly = true },
	{ name = "clearhistory", description = "Clear your command history.", usage = "clearhistory", category = "General", level = L.Member, clientOnly = true },

	{ name = "serverinfo", aliases = { "sinfo" }, description = "Show server details and health.", usage = "serverinfo", category = "Info", level = L.Member, noAudit = true },
	{ name = "playerinfo", aliases = { "pinfo" }, description = "Show public details about a player.", usage = "playerinfo <player>", category = "Info", level = L.Member, noAudit = true, args = { A("player", "player") } },

	{ name = "notify", description = "Send a notification to players.", usage = "notify <players> <message>", category = "Communication", level = L.Owner, args = { A("players", "players"), A("text", "text", { maxLength = 200 }) } },
	{ name = "announce", aliases = { "say" }, description = "Show an announcement to everyone in the server.", usage = "announce <message>", category = "Communication", level = L.Owner, args = { A("text", "text", { maxLength = 200 }) } },

	{ name = "kick", description = "Remove a player from this server.", usage = "kick <player> [reason]", category = "Moderation", level = L.Owner, args = { A("player", "player"), A("reason", "text", { optional = true, maxLength = 150 }) } },
	{ name = "freeze", description = "Anchor players in place.", usage = "freeze <players>", category = "Moderation", level = L.Owner, args = { A("players", "players") } },
	{ name = "unfreeze", aliases = { "thaw" }, description = "Release frozen players.", usage = "unfreeze <players>", category = "Moderation", level = L.Owner, args = { A("players", "players") } },

	{ name = "teleport", aliases = { "tp" }, description = "Teleport players to another player.", usage = "teleport <players> <destination>", category = "Players", level = L.Owner, args = { A("players", "players"), A("destination", "player") } },
	{ name = "goto", description = "Teleport yourself to a player.", usage = "goto <player>", category = "Players", level = L.Owner, args = { A("player", "player") } },
	{ name = "bring", description = "Bring players to you.", usage = "bring <players>", category = "Players", level = L.Owner, args = { A("players", "players") } },
	{ name = "respawn", aliases = { "re" }, description = "Respawn players.", usage = "respawn <players>", category = "Players", level = L.Owner, args = { A("players", "players") } },
	{ name = "heal", description = "Restore players to full health.", usage = "heal <players>", category = "Players", level = L.Owner, args = { A("players", "players") } },
	{ name = "setwalkspeed", aliases = { "speed", "ws" }, description = "Set the walk speed of players (0 to 100).", usage = "setwalkspeed <players> <speed>", category = "Players", level = L.Owner, args = { A("players", "players"), A("speed", "number", { min = 0, max = 100 }) } },
	{ name = "setjumppower", aliases = { "jp" }, description = "Set the jump power of players (0 to 200).", usage = "setjumppower <players> <power>", category = "Players", level = L.Owner, args = { A("players", "players"), A("power", "number", { min = 0, max = 200 }) } },

	{ name = "setgravity", aliases = { "gravity" }, description = "Set world gravity (0 to 500).", usage = "setgravity <value>", category = "World", level = L.Owner, noAudit = true, args = { A("value", "number") } },
	{ name = "settimeofday", aliases = { "time" }, description = "Set the time of day in hours (0 to 24).", usage = "settimeofday <hours>", category = "World", level = L.Owner, noAudit = true, args = { A("hours", "number") } },
	{ name = "setlighting", aliases = { "lighting" }, description = "Set a lighting property.", usage = "setlighting <brightness|exposure|fogend> <value>", category = "World", level = L.Owner, noAudit = true, args = { A("property", "enum", { options = { "brightness", "exposure", "fogend" } }), A("value", "number") } },
	{ name = "setgamespeed", aliases = { "gamespeed" }, description = "Scale player movement speed (0.1 to 3). Not a physics time scale.", usage = "setgamespeed <multiplier>", category = "World", level = L.Owner, noAudit = true, args = { A("multiplier", "number") } },

	{ name = "maintenance", description = "Toggle maintenance mode (removes everyone except the owner).", usage = "maintenance [on|off]", category = "Server", level = L.Owner, confirm = true, noAudit = true, args = { A("state", "enum", { optional = true, options = { "on", "off" } }) } },
	{ name = "featuretoggle", aliases = { "feature" }, description = "Turn a feature flag on or off.", usage = "featuretoggle <feature> [on|off]", category = "Server", level = L.Owner, noAudit = true, args = { A("feature", "enum", { options = featureOptions }), A("state", "enum", { optional = true, options = { "on", "off" } }) } },

	{ name = "config", aliases = { "cfg" }, description = "List, read or change live configuration.", usage = "config <list|get|set> [key] [value]", category = "Config", level = L.Owner, noAudit = true, args = { A("action", "enum", { options = { "list", "get", "set" } }), A("key", "string", { optional = true, maxLength = 64 }), A("value", "text", { optional = true, maxLength = 100 }) } },
	{ name = "configreload", description = "Reload saved configuration from the data store.", usage = "configreload", category = "Config", level = L.Owner, confirm = true, noAudit = true },
	{ name = "resetconfig", description = "Reset one setting, or all settings, to defaults.", usage = "resetconfig [key]", category = "Config", level = L.Owner, confirm = true, noAudit = true, args = { A("key", "string", { optional = true, maxLength = 64 }) } },

	{ name = "auditlog", aliases = { "audit" }, description = "Show recent audit log entries.", usage = "auditlog [count]", category = "Security", level = L.Owner, noAudit = true, args = { A("count", "integer", { optional = true, min = 1, max = 50 }) } },
	{ name = "authlog", description = "Show recent key-authentication events.", usage = "authlog [count]", category = "Security", level = L.Owner, noAudit = true, args = { A("count", "integer", { optional = true, min = 1, max = 50 }) } },
	{ name = "restrictions", description = "List active key-attempt restrictions.", usage = "restrictions", category = "Security", level = L.Owner, noAudit = true },
	{ name = "unrestrict", description = "Reverse a key-attempt restriction by UserId.", usage = "unrestrict <userid>", category = "Security", level = L.Owner, noAudit = true, args = { A("userid", "integer", { min = 1, max = 9007199254740991 }) } },
	{ name = "permissions", aliases = { "perms" }, description = "List who is signed in, or end a player's Fxield session.", usage = "permissions [list|revoke] [player]", category = "Security", level = L.Owner, noAudit = true, confirm = { arg = "action", values = { revoke = true } }, args = { A("action", "enum", { optional = true, options = { "list", "revoke" } }), A("player", "player", { optional = true }) } },

	{ name = "undo", description = "Undo your last undoable command.", usage = "undo", category = "System", level = L.Owner },
	{ name = "modules", description = "List runtime-reloadable modules and versions.", usage = "modules", category = "System", level = L.Owner, noAudit = true },
	{ name = "modulereload", aliases = { "reloadmodule" }, description = "Switch or reload a runtime module (validated, with rollback).", usage = "modulereload <name> [version]", category = "System", level = L.Owner, confirm = true, noAudit = true, args = { A("name", "string", { maxLength = 40 }), A("version", "string", { optional = true, maxLength = 40 }) } },
	{ name = "modulerollback", description = "Roll a module back to its previous known-good version.", usage = "modulerollback <name>", category = "System", level = L.Owner, confirm = true, noAudit = true, args = { A("name", "string", { maxLength = 40 }) } },
}

local byName = {}
for _, def in ipairs(defs) do
	byName[def.name] = def
	for _, alias in ipairs(def.aliases or {}) do
		byName[alias] = def
	end
end

local Definitions = {}
Definitions.All = defs

function Definitions.Find(name)
	if type(name) ~= "string" then
		return nil
	end
	return byName[name:lower()]
end

function Definitions.ForLevel(level)
	local out = {}
	for _, def in ipairs(defs) do
		if def.level <= level then
			table.insert(out, table.clone(def))
		end
	end
	return out
end

return Definitions
]=])

add("ReplicatedStorage/Fxield/Shared/ConfigSchema", "ModuleScript", [=[
local ConfigSchema = {}

ConfigSchema.Fields = {

	{ key = "gameplay.walkSpeed", label = "Walk speed", category = "Gameplay", type = "number", default = 16, min = 0, max = 100, step = 1, description = "Default WalkSpeed applied by the Movement module.", public = true },
	{ key = "gameplay.jumpPower", label = "Jump power", category = "Gameplay", type = "number", default = 50, min = 0, max = 200, step = 1, description = "Default JumpPower applied by the Movement module.", public = true },
	{ key = "gameplay.speedMultiplier", label = "Speed multiplier", category = "Gameplay", type = "number", default = 1, min = 0.1, max = 3, step = 0.1, description = "Scales walk speed. This is NOT a physics time scale.", public = true },
	{ key = "gameplay.autoJump", label = "Auto jump", category = "Gameplay", type = "boolean", default = false, description = "Used by Movement module v2 and later." },
	{ key = "gameplay.respawnTime", label = "Respawn time (s)", category = "Gameplay", type = "number", default = 5, min = 0, max = 30, step = 1, description = "Players.RespawnTime." },
	{ key = "gameplay.gravity", label = "Gravity", category = "Gameplay", type = "number", default = 196.2, min = 0, max = 500, step = 1, description = "Workspace.Gravity." },
	{ key = "gameplay.abilityCooldown", label = "Ability cooldown (s)", category = "Gameplay", type = "number", default = 3, min = 0, max = 60, step = 0.5, description = "Example gameplay value: your own scripts read it via ConfigService.Get.", public = true },

	{ key = "world.clockTime", label = "Time of day (hours)", category = "World", type = "number", default = 14, min = 0, max = 24, step = 0.5, description = "Lighting.ClockTime." },
	{ key = "world.brightness", label = "Brightness", category = "World", type = "number", default = 2, min = 0, max = 10, step = 0.1, description = "Lighting.Brightness." },
	{ key = "world.exposure", label = "Exposure", category = "World", type = "number", default = 0, min = -3, max = 3, step = 0.1, description = "Lighting.ExposureCompensation." },
	{ key = "world.fogEnd", label = "Fog end (studs)", category = "World", type = "number", default = 100000, min = 50, max = 100000, step = 50, description = "Lighting.FogEnd." },

	{ key = "features.pvp", label = "PvP enabled", category = "Features", type = "boolean", default = true, description = "Example feature flag for your own combat scripts.", public = true },
	{ key = "features.emotes", label = "Emotes enabled", category = "Features", type = "boolean", default = true, description = "Example feature flag.", public = true },
	{ key = "features.abilities", label = "Abilities enabled", category = "Features", type = "boolean", default = true, description = "Example feature flag.", public = true },

	{ key = "server.maintenance", label = "Maintenance mode", category = "Server", type = "boolean", default = false, description = "Removes everyone except the owner and blocks others from joining." },

	{ key = "ui.title", label = "Panel title", category = "Interface", type = "string", default = "Fxield", maxLength = 24, description = "Title shown in the Fxield window.", public = true },
	{ key = "ui.announcementPrefix", label = "Announcement title", category = "Interface", type = "string", default = "Announcement", maxLength = 24, description = "Heading used by the announce command.", public = true },
	{ key = "ui.defaultAccent", label = "Default accent color", category = "Interface", type = "color", default = "#8B5CF6", description = "Accent for users who have not picked their own.", public = true },
}

ConfigSchema.ByKey = {}
for _, field in ipairs(ConfigSchema.Fields) do
	ConfigSchema.ByKey[field.key] = field
end

local function isFinite(n)
	return n == n and n ~= math.huge and n ~= -math.huge
end

function ConfigSchema.Validate(field, raw)
	local t = field.type

	if t == "number" or t == "integer" then
		local n = raw
		if type(n) == "string" then
			n = tonumber(n)
		end
		if type(n) ~= "number" or not isFinite(n) then
			return false, "Expected a number."
		end
		if t == "integer" and n % 1 ~= 0 then
			return false, "Expected a whole number."
		end
		if field.min and n < field.min then
			return false, ("Must be at least %s."):format(tostring(field.min))
		end
		if field.max and n > field.max then
			return false, ("Must be at most %s."):format(tostring(field.max))
		end
		return true, n

	elseif t == "boolean" then
		if type(raw) == "boolean" then
			return true, raw
		end
		if type(raw) == "string" then
			local s = raw:lower()
			if s == "on" or s == "true" or s == "yes" or s == "1" then
				return true, true
			elseif s == "off" or s == "false" or s == "no" or s == "0" then
				return true, false
			end
		end
		return false, "Expected on or off."

	elseif t == "string" then
		if type(raw) ~= "string" then
			return false, "Expected text."
		end
		local s = (raw:gsub("%c", ""))
		s = s:match("^%s*(.-)%s*$")
		if #s < (field.minLength or 1) then
			return false, "Text is too short."
		end
		if #s > (field.maxLength or 100) then
			return false, ("Text is too long (max %d)."):format(field.maxLength or 100)
		end
		return true, s

	elseif t == "color" then
		if type(raw) ~= "string" then
			return false, "Expected a hex color like #4F8CFF."
		end
		local hex = raw:match("^#?(%x%x%x%x%x%x)$")
		if not hex then
			return false, "Expected a hex color like #4F8CFF."
		end
		return true, "#" .. hex:upper()

	elseif t == "enum" then
		if type(raw) ~= "string" then
			return false, "Expected one of: " .. table.concat(field.options or {}, ", ")
		end
		for _, option in ipairs(field.options or {}) do
			if option:lower() == raw:lower() then
				return true, option
			end
		end
		return false, "Expected one of: " .. table.concat(field.options or {}, ", ")

	elseif t == "keycode" then
		if type(raw) ~= "string" then
			return false, "Expected a key name."
		end
		local item = Enum.KeyCode:FromName(raw)
		if not item or item == Enum.KeyCode.Unknown then
			return false, "Unknown key."
		end
		return true, item.Name
	end

	return false, "Unsupported setting type."
end

return ConfigSchema
]=])

add("ReplicatedStorage/Fxield/Shared/Constants", "ModuleScript", [=[
local Constants = {}

Constants.Name = "Fxield"
Constants.Version = "2.0.0"

Constants.Levels = {
	Guest = 0,
	Member = 1,
	Owner = 2,
}

Constants.LevelNames = {
	[0] = "Guest",
	[1] = "Member",
	[2] = "Owner",
}

Constants.MaxCommandLength = 256
Constants.MaxMessageLength = 4000
Constants.MaxKeyLength = 128

return Constants
]=])

add("ReplicatedStorage/Fxield/Shared/PrefsSchema", "ModuleScript", [=[
local PrefsSchema = {}

PrefsSchema.Fields = {
	{ key = "theme", type = "enum", options = { "dark", "midnight", "light" }, default = "dark" },
	{ key = "accent", type = "color", default = "#8B5CF6" },
	{ key = "scale", type = "number", min = 0.7, max = 1.6, default = 1 },
	{ key = "textScale", type = "number", min = 0.8, max = 1.5, default = 1 },
	{ key = "reducedMotion", type = "boolean", default = false },
	{ key = "highContrast", type = "boolean", default = false },
	{ key = "keybind", type = "keycode", default = "Semicolon" },
}

PrefsSchema.ByKey = {}
for _, field in ipairs(PrefsSchema.Fields) do
	PrefsSchema.ByKey[field.key] = field
end

return PrefsSchema
]=])

add("ReplicatedStorage/Fxield/Shared/Types", "ModuleScript", [=[
export type ArgDef = {
	name: string,

	type: string,
	optional: boolean?,
	min: number?,
	max: number?,
	maxLength: number?,
	options: { string }?,
}

export type CommandDef = {
	name: string,
	aliases: { string }?,
	description: string,
	usage: string,
	category: string,
	level: number,
	args: { ArgDef }?,
	clientOnly: boolean?,
	confirm: (boolean | { arg: string, values: { [string]: boolean } })?,
	noAudit: boolean?,
}

export type ConfigField = {
	key: string,
	label: string,
	category: string,

	type: string,
	default: any,
	min: number?,
	max: number?,
	step: number?,
	maxLength: number?,
	minLength: number?,
	options: { string }?,
	description: string?,
	public: boolean?,
}

export type CommandResponse = {
	id: number,
	ok: boolean,
	message: string,
	needsConfirm: boolean?,
	token: string?,
}

export type ModuleContract = {
	Name: string,
	Version: string,
	ApiVersion: number,
	ConfigKeys: { string }?,
	Validate: ((ctx: any) -> (boolean, string?))?,
	Start: (ctx: any) -> (),
	Stop: (ctx: any) -> (),
}

return {}
]=])

add("ServerScriptService/FxieldServer/AuditService", "ModuleScript", [=[
local DataStoreService = game:GetService("DataStoreService")

local AuditService = {}

local MAX_ENTRIES = 300
local entries = {}
local pending = {}
local store

local function truncate(value)
	if value == nil then
		return nil
	end
	local s = tostring(value)
	if #s > 200 then
		s = s:sub(1, 200) .. "..."
	end
	return s
end

function AuditService.Format(entry)
	local parts = {
		("[%s UTC]"):format(os.date("!%Y-%m-%d %H:%M:%S", entry.time)),
		("%s(%d)"):format(tostring(entry.actor), entry.actorId or 0),
		tostring(entry.action),
	}
	if entry.target then
		table.insert(parts, "-> " .. entry.target)
	end
	if entry.old ~= nil or entry.new ~= nil then
		table.insert(parts, ("[%s => %s]"):format(tostring(entry.old), tostring(entry.new)))
	end
	if entry.note then
		table.insert(parts, "(" .. entry.note .. ")")
	end
	return table.concat(parts, " ")
end

function AuditService.Init()
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore("FxieldAudit")
	end)
	if ok then
		store = s
	end
	if store then
		local okLoad, data = pcall(function()
			return store:GetAsync("log_v1")
		end)
		if okLoad and type(data) == "table" then
			for _, e in ipairs(data) do
				if type(e) == "table" and type(e.time) == "number" then
					table.insert(entries, e)
				end
			end
			while #entries > MAX_ENTRIES do
				table.remove(entries, 1)
			end
		elseif not okLoad then
			warn("[Fxield] Audit log could not be loaded: " .. tostring(data))
		end
	end
	task.spawn(function()
		while true do
			task.wait(60)
			AuditService.Flush()
		end
	end)
end

function AuditService.Log(actor, action, target, old, new, note)
	local actorName, actorId = "System", 0
	if typeof(actor) == "Instance" and actor:IsA("Player") then
		actorName, actorId = actor.Name, actor.UserId
	elseif type(actor) == "string" then
		actorName = actor
	end
	local entry = {
		time = os.time(),
		actor = actorName,
		actorId = actorId,
		action = truncate(action),
		target = truncate(target),
		old = truncate(old),
		new = truncate(new),
		note = truncate(note),
	}
	table.insert(entries, entry)
	table.insert(pending, entry)
	while #entries > MAX_ENTRIES do
		table.remove(entries, 1)
	end
	if #pending > 500 then
		table.remove(pending, 1)
	end
	print("[Fxield][Audit] " .. AuditService.Format(entry))
	return entry
end

function AuditService.GetRecent(count)
	local out = {}
	local first = math.max(1, #entries - count + 1)
	for i = first, #entries do
		table.insert(out, entries[i])
	end
	return out
end

function AuditService.Flush()
	if not store or #pending == 0 then
		return
	end
	local batch = pending
	pending = {}
	local ok, err = pcall(function()
		store:UpdateAsync("log_v1", function(current)
			current = type(current) == "table" and current or {}
			for _, e in ipairs(batch) do
				table.insert(current, e)
			end
			while #current > MAX_ENTRIES do
				table.remove(current, 1)
			end
			return current
		end)
	end)
	if not ok then
		warn("[Fxield] Audit flush failed: " .. tostring(err))
		for _, e in ipairs(batch) do
			table.insert(pending, e)
		end
	end
end

return AuditService
]=])

add("ServerScriptService/FxieldServer/AuthService", "ModuleScript", [=[
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared"):WaitForChild("Constants"))
local ServerConfig = require(script.Parent.ServerConfig)
local RateLimiter = require(script.Parent.RateLimiter)

local AuthService = {}
AuthService.OnRestricted = nil

local store
local audit
local ownerVerified = false
local sessions = {}
local records = {}
local busy = {}
local attemptLimiter = RateLimiter.new(3, 0.2)
local globalLimiter = RateLimiter.new(40, 0.5)

local function recordKey(userId)
	return "u_" .. tostring(userId)
end

local function normalize(record)
	record.fails = tonumber(record.fails) or 0
	record.totalFails = tonumber(record.totalFails) or 0
	record.restrictedUntil = tonumber(record.restrictedUntil) or 0
	record.restrictedAt = tonumber(record.restrictedAt) or 0
	record.restrictionCount = tonumber(record.restrictionCount) or 0
	record.lastFail = tonumber(record.lastFail) or 0
	return record
end

local function log(actor, action, target, note)
	if audit then
		audit.Log(actor, action, target, nil, nil, note)
	end
end

local function constantTimeEquals(a, b)
	local diff = (#a ~= #b) and 1 or 0
	local length = math.max(#a, #b)
	for i = 1, length do
		local x = string.byte(a, i) or 0
		local y = string.byte(b, i) or 0
		diff = bit32.bor(diff, bit32.bxor(x, y))
	end
	return diff == 0
end

local function formatDuration(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return ("%d hour(s) %d minute(s)"):format(seconds // 3600, (seconds % 3600) // 60)
	elseif seconds >= 60 then
		return ("%d minute(s)"):format(math.ceil(seconds / 60))
	end
	return ("%d second(s)"):format(seconds)
end

local function restrictedResult(retryAfter)
	return {
		ok = false,
		code = "restricted",
		retryAfter = retryAfter,
		message = ("Too many failed attempts. Access is restricted for %s."):format(formatDuration(retryAfter)),
	}
end

local function readRecord(userId)
	if not store then
		return nil
	end
	local ok, data = pcall(function()
		return store:GetAsync(recordKey(userId))
	end)
	if not ok then
		return nil
	end
	return normalize(type(data) == "table" and data or {})
end

local function getRecord(userId)
	local record = readRecord(userId)
	if record then
		records[userId] = record
		return record, true
	end
	if records[userId] then
		return records[userId], true
	end
	if RunService:IsStudio() or not ServerConfig.FailClosedOnStoreError then
		record = normalize({})
		records[userId] = record
		return record, true
	end
	return nil, false
end

local function updateRecord(userId, mutator)
	if store then
		local result
		local ok = pcall(function()
			store:UpdateAsync(recordKey(userId), function(current)
				current = normalize(type(current) == "table" and current or {})
				mutator(current)
				result = table.clone(current)
				return current
			end)
		end)
		if ok and result then
			records[userId] = result
			return result, true
		end
	end
	local fallback = records[userId] or normalize({})
	mutator(fallback)
	records[userId] = fallback
	return fallback, false
end

local function processSubmission(player, key)
	local userId = player.UserId
	local owner = AuthService.IsOwnerId(userId)

	local record, usable = getRecord(userId)
	if not usable then
		return {
			ok = false,
			code = "unavailable",
			message = "Authentication is temporarily unavailable. Please try again shortly.",
		}
	end

	local currentTime = os.time()
	if not owner and record.restrictedUntil > currentTime then
		return restrictedResult(record.restrictedUntil - currentTime)
	end

	local valid = #key > 0 and #key <= Constants.MaxKeyLength and constantTimeEquals(key, ServerConfig.AccessKey)
	if valid then
		updateRecord(userId, function(r)
			r.fails = 0
		end)
		if player.Parent then
			sessions[userId] = true
		end
		log(player, "auth:success", tostring(userId), "access granted")
		return { ok = true, code = "success", message = "Access granted." }
	end

	local restrictedNow = false
	local updated = updateRecord(userId, function(r)
		restrictedNow = false
		r.fails += 1
		r.totalFails += 1
		r.lastFail = currentTime
		if not owner and r.fails >= ServerConfig.MaxFailedAttempts then
			r.restrictedUntil = currentTime + ServerConfig.RestrictionSeconds
			r.restrictedAt = currentTime
			r.restrictionCount += 1
			r.fails = 0
			restrictedNow = true
		end
	end)

	if restrictedNow then
		log(player, "auth:restricted", tostring(userId), ("restricted for %d seconds after %d consecutive failed attempts"):format(ServerConfig.RestrictionSeconds, ServerConfig.MaxFailedAttempts))
		if AuthService.OnRestricted then
			task.spawn(AuthService.OnRestricted, player, updated)
		end
		return restrictedResult(ServerConfig.RestrictionSeconds)
	end

	log(player, "auth:failed", tostring(userId), ("invalid key, consecutive failures: %d"):format(updated.fails))
	local result = { ok = false, code = "invalid", message = "Invalid key." }
	if not owner then
		result.attemptsLeft = math.max(0, ServerConfig.MaxFailedAttempts - updated.fails)
		result.message = ("Invalid key. %d attempt(s) remaining."):format(result.attemptsLeft)
	end
	return result
end

function AuthService.Init(auditService)
	audit = auditService
	local ok, dataStore = pcall(function()
		return DataStoreService:GetDataStore("FxieldAuth")
	end)
	if ok then
		store = dataStore
	end
	Players.PlayerRemoving:Connect(function(player)
		local userId = player.UserId
		sessions[userId] = nil
		records[userId] = nil
		busy[userId] = nil
		attemptLimiter:Clear(userId)
	end)
end

function AuthService.SetOwnerVerified(verified)
	ownerVerified = verified == true
end

function AuthService.IsOwnerId(userId)
	return ownerVerified and ServerConfig.OwnerUserId > 0 and userId == ServerConfig.OwnerUserId
end

function AuthService.IsAuthenticated(player)
	return typeof(player) == "Instance" and player:IsA("Player") and sessions[player.UserId] == true
end

function AuthService.GetStatus(player)
	local userId = player.UserId
	if sessions[userId] then
		return { ok = true, state = "authenticated" }
	end
	local record = records[userId]
	if record and not AuthService.IsOwnerId(userId) and record.restrictedUntil > os.time() then
		local retryAfter = record.restrictedUntil - os.time()
		local result = restrictedResult(retryAfter)
		result.ok = true
		result.state = "restricted"
		return result
	end
	return { ok = true, state = "needsKey", maxAttempts = ServerConfig.MaxFailedAttempts }
end

function AuthService.Submit(player, key)
	if typeof(key) ~= "string" then
		return { ok = false, code = "bad_request", message = "Invalid request." }
	end
	local userId = player.UserId
	if busy[userId] or not globalLimiter:Take("all") or not attemptLimiter:Take(userId) then
		return { ok = false, code = "rate_limited", retryAfter = 5, message = "Please wait a few seconds before trying again." }
	end
	busy[userId] = true
	local ok, result = pcall(processSubmission, player, key)
	busy[userId] = nil
	if not ok then
		warn("[Fxield] Authentication error: " .. tostring(result))
		return { ok = false, code = "unavailable", message = "Authentication is temporarily unavailable. Please try again shortly." }
	end
	return result
end

function AuthService.Revoke(userId)
	local had = sessions[userId] == true
	sessions[userId] = nil
	return had
end

function AuthService.ListRestrictions()
	local list, seen = {}, {}
	local currentTime = os.time()
	for userId, record in pairs(records) do
		if record.restrictedUntil > currentTime then
			seen[userId] = true
			table.insert(list, { userId = userId, restrictedUntil = record.restrictedUntil, totalFails = record.totalFails })
		end
	end
	local complete = false
	if store then
		local ok, pages = pcall(function()
			return store:ListKeysAsync("u_", 50)
		end)
		if ok and pages then
			local okPage, page = pcall(function()
				return pages:GetCurrentPage()
			end)
			if okPage then
				complete = true
				for _, entry in ipairs(page) do
					local userId = tonumber(string.match(entry.KeyName, "^u_(%d+)$"))
					if userId and not seen[userId] then
						local record = readRecord(userId)
						if record and record.restrictedUntil > currentTime then
							table.insert(list, { userId = userId, restrictedUntil = record.restrictedUntil, totalFails = record.totalFails })
						end
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.restrictedUntil > b.restrictedUntil
	end)
	return list, complete
end

function AuthService.Unrestrict(userId, actor)
	if type(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then
		return false, "Invalid UserId."
	end
	local _, persisted = updateRecord(userId, function(r)
		r.restrictedUntil = 0
		r.fails = 0
	end)
	log(actor, "auth:unrestrict", tostring(userId), persisted and "restriction cleared" or "cleared in memory only because the data store was unavailable")
	return true, persisted
end

return AuthService
]=])

add("ServerScriptService/FxieldServer/Bootstrap", "Script", [=[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fxield = ReplicatedStorage:WaitForChild("Fxield")
local Shared = Fxield:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Schema = require(Shared:WaitForChild("ConfigSchema"))
local Definitions = require(Shared:WaitForChild("CommandDefinitions"))

local Server = script.Parent
local ServerConfig = require(Server.ServerConfig)
local RateLimiter = require(Server.RateLimiter)
local AuthService = require(Server.AuthService)
local PermissionService = require(Server.PermissionService)
local AuditService = require(Server.AuditService)
local ConfigService = require(Server.ConfigService)
local PreferencesService = require(Server.PreferencesService)
local ModuleManager = require(Server.ModuleManager)
local CommandService = require(Server.CommandService)

local Levels = Constants.Levels

local function ensure(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName ~= className then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		existing = Instance.new(className)
		existing.Name = name
		existing.Parent = parent
	end
	return existing
end

local remotesFolder = ensure(Fxield, "Folder", "Remotes")
local Remotes = {
	CommandRequest = ensure(remotesFolder, "RemoteEvent", "CommandRequest"),
	CommandResponse = ensure(remotesFolder, "RemoteEvent", "CommandResponse"),
	Notification = ensure(remotesFolder, "RemoteEvent", "Notification"),
	ConfigUpdate = ensure(remotesFolder, "RemoteEvent", "ConfigUpdate"),
	ConfigRequest = ensure(remotesFolder, "RemoteFunction", "ConfigRequest"),
	Session = ensure(remotesFolder, "RemoteFunction", "Session"),
	Auth = ensure(remotesFolder, "RemoteFunction", "Auth"),
}

AuditService.Init()
AuthService.Init(AuditService)
PermissionService.Init()
ConfigService.Init(AuditService)
PreferencesService.Init(ConfigService)
ModuleManager.Init({ Config = ConfigService, Audit = AuditService })

for _, folder in ipairs(Server:WaitForChild("RuntimeModules"):GetChildren()) do
	if folder:IsA("Folder") then
		ModuleManager.Register(folder, "v1")
	end
end
ModuleManager.StartAll()

CommandService.Init({
	Remotes = Remotes,
	Permissions = PermissionService,
	Audit = AuditService,
	Config = ConfigService,
	Modules = ModuleManager,
	Auth = AuthService,
})

AuthService.OnRestricted = function(player)
	for _, other in ipairs(Players:GetPlayers()) do
		if PermissionService.IsOwner(other) then
			CommandService.Notify(other, "warn", ("%s (%d) was restricted after failed key attempts."):format(player.Name, player.UserId), "Fxield security")
		end
	end
end

local function attributeName(key)
	return "Config_" .. (key:gsub("%.", "_"))
end

local function mirror(key, value)
	local field = Schema.ByKey[key]
	if field and field.public then
		Fxield:SetAttribute(attributeName(key), value)
	end
end

for _, field in ipairs(Schema.Fields) do
	mirror(field.key, ConfigService.Get(field.key))
end

ConfigService.OnBatch(function(entry)
	local all, public = {}, {}
	for key, change in pairs(entry.changes) do
		all[key] = change.new
		local field = Schema.ByKey[key]
		if field and field.public then
			public[key] = change.new
			mirror(key, change.new)
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local payload = PermissionService.GetLevel(player) >= Levels.Owner and all or public
		if next(payload) then
			Remotes.ConfigUpdate:FireClient(player, { values = payload, id = entry.id })
		end
	end
end)

local MAINTENANCE_MESSAGE = "The server is under maintenance. Please try again later."

local function checkMaintenance(player)
	if ConfigService.Get("server.maintenance") and not PermissionService.IsOwner(player) then
		player:Kick(MAINTENANCE_MESSAGE)
	end
end

ConfigService.OnChanged("server.maintenance", function(_, enabled)
	if enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			checkMaintenance(player)
		end
	end
end)
Players.PlayerAdded:Connect(checkMaintenance)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(checkMaintenance, player)
end

local statusLimiter = RateLimiter.new(10, 1)
local sessionLimiter = RateLimiter.new(8, 2)
local configLimiter = RateLimiter.new(6, 1)
local lastDenied = {}

local function noteDenied(player, what)
	local now = os.clock()
	if lastDenied[player.UserId] and now - lastDenied[player.UserId] < 15 then
		return
	end
	lastDenied[player.UserId] = now
	AuditService.Log(player, "denied", what, nil, nil, "unauthorized remote call")
end

local function handleAuth(player, action, key)
	if typeof(action) ~= "string" then
		return { ok = false, code = "bad_request", message = "Invalid request." }
	end
	if action == "status" then
		if not statusLimiter:Take(player.UserId) then
			return { ok = false, code = "rate_limited", message = "Please wait a moment." }
		end
		local status
		if PermissionService.IsSessionActive(player) then
			status = { ok = true, state = "authenticated" }
		else
			status = AuthService.GetStatus(player)
		end
		status.showLauncher = ServerConfig.ShowLauncherToGuests or PermissionService.IsOwner(player)
		return status
	elseif action == "submit" then
		return AuthService.Submit(player, key)
	end
	return { ok = false, code = "bad_request", message = "Unknown action." }
end

Remotes.Auth.OnServerInvoke = function(player, action, key)
	local ok, result = pcall(handleAuth, player, action, key)
	if ok then
		return result
	end
	warn("[Fxield] Auth remote error: " .. tostring(result))
	return { ok = false, code = "unavailable", message = "Authentication is temporarily unavailable." }
end

local function handleSession(player, action, payload)
	if not sessionLimiter:Take(player.UserId) then
		return { ok = false, error = "Slow down." }
	end
	if typeof(action) ~= "string" then
		return { ok = false, error = "Bad request." }
	end
	local level = PermissionService.GetLevel(player)
	if level < Levels.Member then
		noteDenied(player, "session:" .. string.sub(action, 1, 30))
		return { ok = false, code = "auth", error = "Authentication required." }
	end

	if action == "hello" then
		local data = {
			ok = true,
			level = level,
			levelName = Constants.LevelNames[level],
			version = Constants.Version,
			title = ConfigService.Get("ui.title"),
			commands = Definitions.ForLevel(level),
			prefs = PreferencesService.Get(player),
		}
		if level >= Levels.Owner then
			data.schema = Schema.Fields
			data.config = ConfigService.GetAll()
		end
		return data
	elseif action == "getPrefs" then
		return { ok = true, prefs = PreferencesService.Get(player) }
	elseif action == "setPrefs" then
		local ok, errors = PreferencesService.Set(player, payload)
		return { ok = ok, errors = errors }
	end
	return { ok = false, error = "Unknown action." }
end

Remotes.Session.OnServerInvoke = function(player, action, payload)
	local ok, result = pcall(handleSession, player, action, payload)
	if ok then
		return result
	end
	warn("[Fxield] Session error: " .. tostring(result))
	return { ok = false, error = "Server error." }
end

local function sanitizeChanges(tbl)
	if type(tbl) ~= "table" then
		return nil
	end
	local out, n = {}, 0
	for k, v in pairs(tbl) do
		if type(k) ~= "string" or #k > 64 then
			return nil
		end
		n += 1
		if n > 64 then
			return nil
		end
		out[k] = v
	end
	return out
end

local function snapshot()
	return ConfigService.GetAll(), ConfigService.GetHistory(30)
end

local function handleConfigRequest(player, action, payload)
	if not configLimiter:Take(player.UserId) then
		return { ok = false, error = "You are doing that too fast." }
	end
	if typeof(action) ~= "string" then
		return { ok = false, error = "Bad request." }
	end
	if PermissionService.GetLevel(player) < Levels.Owner then
		noteDenied(player, "config:" .. string.sub(action, 1, 30))
		return { ok = false, error = "Not authorized." }
	end
	payload = type(payload) == "table" and payload or {}

	if action == "get" or action == "history" then
		local config, history = snapshot()
		return { ok = true, config = config, history = history }
	elseif action == "preview" then
		local changes = sanitizeChanges(payload.changes)
		if not changes then
			return { ok = false, error = "Bad request." }
		end
		local results, allOk = ConfigService.Preview(changes)
		return { ok = allOk, results = results }
	elseif action == "apply" then
		local changes = sanitizeChanges(payload.changes)
		if not changes then
			return { ok = false, error = "Bad request." }
		end
		local ok, results = ConfigService.Apply(changes, player, "live-editor")
		local config, history = snapshot()
		return { ok = ok, results = results, config = config, history = history }
	elseif action == "undo" then
		local ok, result = ConfigService.Undo(player)
		local config, history = snapshot()
		return { ok = ok, error = (not ok) and result or nil, config = config, history = history }
	elseif action == "reset" then
		if payload.confirm ~= true then
			return { ok = false, error = "Confirmation required." }
		end
		local ok, result = ConfigService.Reset(nil, player)
		local config, history = snapshot()
		return { ok = ok, error = (not ok) and tostring(result) or nil, config = config, history = history }
	end
	return { ok = false, error = "Unknown action." }
end

Remotes.ConfigRequest.OnServerInvoke = function(player, action, payload)
	local ok, result = pcall(handleConfigRequest, player, action, payload)
	if ok then
		return result
	end
	warn("[Fxield] ConfigRequest error: " .. tostring(result))
	return { ok = false, error = "Server error." }
end

Players.PlayerRemoving:Connect(function(player)
	statusLimiter:Clear(player.UserId)
	sessionLimiter:Clear(player.UserId)
	configLimiter:Clear(player.UserId)
	lastDenied[player.UserId] = nil
end)

game:BindToClose(function()
	ConfigService.Flush()
	PreferencesService.SaveAll()
	AuditService.Flush()
	ModuleManager.StopAll()
end)

Fxield:SetAttribute("Ready", true)
print(("[Fxield] %s %s ready. Owner configured: %s."):format(Constants.Name, Constants.Version, tostring(PermissionService.OwnerVerified)))
]=])

add("ServerScriptService/FxieldServer/CommandService", "ModuleScript", [=[
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Schema = require(Shared:WaitForChild("ConfigSchema"))
local Definitions = require(Shared:WaitForChild("CommandDefinitions"))
local RateLimiter = require(script.Parent.RateLimiter)

local Levels = Constants.Levels

local CommandService = {}

local handlers = {}
local pending = {}
local undoStacks = {}
local busy = {}
local lastDenied = {}
local limiter = RateLimiter.new(10, 2)
local deps
local errorCounter = 0

local NOTIFY_KINDS = { info = true, success = true, warn = true, error = true, announce = true }

local function tokenize(line)
	local tokens = {}
	local i, n = 1, #line
	while i <= n do
		local c = line:sub(i, i)
		if c:match("%s") then
			i += 1
		elseif c == '"' then
			local j = line:find('"', i + 1, true)
			if not j then
				return nil, "Unclosed quotation mark."
			end
			table.insert(tokens, line:sub(i + 1, j - 1))
			i = j + 1
		else
			local j = line:find("%s", i) or (n + 1)
			table.insert(tokens, line:sub(i, j - 1))
			i = j
		end
	end
	return tokens
end

local function resolvePlayers(actor, token)
	local t = token:lower()
	if t == "me" then
		return { actor }
	elseif t == "all" then
		return Players:GetPlayers()
	elseif t == "others" then
		local result = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= actor then
				table.insert(result, p)
			end
		end
		return result
	end
	local exact, partial = {}, {}
	for _, p in ipairs(Players:GetPlayers()) do
		local name, display = p.Name:lower(), p.DisplayName:lower()
		if name == t or display == t then
			table.insert(exact, p)
		elseif name:sub(1, #t) == t or display:sub(1, #t) == t then
			table.insert(partial, p)
		end
	end
	if #exact > 0 then
		return exact
	end
	return partial
end

local function parseValue(actor, arg, raw)
	local t = arg.type
	if t == "player" then
		local list = resolvePlayers(actor, raw)
		local lowered = raw:lower()
		if lowered == "all" or lowered == "others" then
			return false, ("<%s> must be a single player."):format(arg.name)
		end
		if #list == 0 then
			return false, ("No player matches '%s'."):format(raw)
		elseif #list > 1 then
			return false, ("'%s' matches several players; be more specific."):format(raw)
		end
		return true, list[1]
	elseif t == "players" then
		local list = resolvePlayers(actor, raw)
		if #list == 0 then
			return false, ("No player matches '%s'."):format(raw)
		end
		return true, list
	end

	local field
	if t == "number" or t == "integer" then
		field = { type = t, min = arg.min, max = arg.max }
	elseif t == "boolean" then
		field = { type = "boolean" }
	elseif t == "enum" then
		field = { type = "enum", options = arg.options }
	elseif t == "string" or t == "text" then
		field = { type = "string", minLength = 0, maxLength = arg.maxLength or (t == "text" and 200 or 64) }
	else
		return false, "Unsupported argument type."
	end
	local ok, value = Schema.Validate(field, raw)
	if not ok then
		return false, ("<%s>: %s"):format(arg.name, value)
	end
	return true, value
end

local function parseArgs(actor, def, tokens)
	local args = {}
	local idx = 2
	for _, arg in ipairs(def.args or {}) do
		local tok = tokens[idx]
		if tok == nil then
			if not arg.optional then
				return nil, ("Missing <%s>. Usage: %s"):format(arg.name, def.usage)
			end
			break
		end
		local raw = tok
		if arg.type == "text" then
			raw = table.concat(tokens, " ", idx)
			idx = #tokens + 1
		else
			idx += 1
		end
		local ok, value = parseValue(actor, arg, raw)
		if not ok then
			return nil, value
		end
		args[arg.name] = value
	end
	if tokens[idx] ~= nil then
		return nil, "Too many arguments. Usage: " .. def.usage
	end
	return args
end

local function needsConfirmation(def, args)
	if def.confirm == true then
		return true
	elseif type(def.confirm) == "table" then
		local value = args[def.confirm.arg]
		return value ~= nil and def.confirm.values[value] == true
	end
	return false
end

local function respond(player, id, ok, message, extra)
	if player.Parent == nil then
		return
	end
	local payload = {
		id = id,
		ok = ok,
		message = string.sub(tostring(message or ""), 1, Constants.MaxMessageLength),
	}
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	deps.Remotes.CommandResponse:FireClient(player, payload)
end

function CommandService.Notify(player, kind, text, title, action)
	if typeof(player) ~= "Instance" or player.Parent == nil then
		return
	end
	if not NOTIFY_KINDS[kind] then
		kind = "info"
	end
	deps.Remotes.Notification:FireClient(player, {
		kind = kind,
		text = string.sub(tostring(text), 1, 300),
		title = title and string.sub(tostring(title), 1, 40) or nil,
		action = action == "signout" and action or nil,
	})
end

local function noteDenied(player, what)
	local now = os.clock()
	if lastDenied[player.UserId] and now - lastDenied[player.UserId] < 15 then
		return
	end
	lastDenied[player.UserId] = now
	deps.Audit.Log(player, "denied", what, nil, nil, "unauthorized or rate-limited attempt")
end

local function makeContext(player, level, def, args)
	local audited = false
	local ctx = {
		Player = player,
		Level = level,
		Definition = def,
		Args = args,
		Config = deps.Config,
		Permissions = deps.Permissions,
		Modules = deps.Modules,
		AuditLog = deps.Audit,
		Auth = deps.Auth,
	}
	function ctx.Audit(target, old, new, note)
		audited = true
		deps.Audit.Log(player, def.name, target, old, new, note)
	end
	function ctx.Notify(target, kind, text, title, action)
		CommandService.Notify(target, kind, text, title, action)
	end

	function ctx.CanTarget(target)
		if typeof(target) == "Instance" and target:IsA("Player") and target.Parent ~= nil then
			return true
		end
		return false, "That player is no longer in the server."
	end
	function ctx.PopUndo()
		local stack = undoStacks[player.UserId]
		return stack and table.remove(stack) or nil
	end
	return ctx, function()
		return audited
	end
end

local function handleRequest(player, id, line, token)

	if typeof(id) ~= "number" or id ~= id or id % 1 ~= 0 or id < 0 or id > 2147483647 then
		return
	end
	if typeof(line) ~= "string" or #line == 0 or #line > Constants.MaxCommandLength then
		return respond(player, id, false, "Invalid command text.")
	end
	if token ~= nil and (typeof(token) ~= "string" or #token > 64) then
		return respond(player, id, false, "Invalid request.")
	end

	if not limiter:Take(player.UserId) then
		noteDenied(player, "rate limit")
		return respond(player, id, false, "You are sending commands too fast.")
	end

	local level = deps.Permissions.GetLevel(player)
	if level < Levels.Member then
		noteDenied(player, "command: " .. line)
		return respond(player, id, false, "Authentication required. Open Fxield and enter your access key.")
	end

	local cleaned = line:gsub("^%s*[:;]", "")
	local tokens, tokenError = tokenize(cleaned)
	if not tokens then
		return respond(player, id, false, tokenError)
	end
	if #tokens == 0 then
		return respond(player, id, false, "Type a command. Try 'help'.")
	end
	local def = Definitions.Find(tokens[1])
	if not def or def.clientOnly then
		return respond(player, id, false, ("Unknown command '%s'. Try 'commands'."):format(tokens[1]:sub(1, 30)))
	end
	if level < def.level then
		noteDenied(player, "command: " .. def.name)
		return respond(player, id, false, "You do not have permission to use that command.")
	end
	local handler = handlers[def.name]
	if not handler then
		return respond(player, id, false, "That command is not available on this server.")
	end

	local args, argError = parseArgs(player, def, tokens)
	if not args then
		return respond(player, id, false, argError)
	end

	if needsConfirmation(def, args) then
		local p = pending[player.UserId]
		if p and token and p.token == token and p.line == line and os.clock() < p.expires then
			pending[player.UserId] = nil
		else
			local newToken = HttpService:GenerateGUID(false)
			pending[player.UserId] = { token = newToken, line = line, expires = os.clock() + 30 }
			return respond(player, id, false, def.description, { needsConfirm = true, token = newToken })
		end
	end

	if busy[player.UserId] then
		return respond(player, id, false, "Your previous command is still running.")
	end
	busy[player.UserId] = true
	local ctx, wasAudited = makeContext(player, level, def, args)
	local results = table.pack(xpcall(handler, function(e)
		return debug.traceback(tostring(e), 2)
	end, ctx, args))
	busy[player.UserId] = nil

	if not results[1] then
		errorCounter += 1
		warn(("[Fxield] Command '%s' failed (ref #%d) for %s:\n%s"):format(def.name, errorCounter, player.Name, tostring(results[2])))
		deps.Audit.Log(player, def.name, nil, nil, nil, "internal error #" .. errorCounter)
		return respond(player, id, false, ("Internal error (ref #%d). The error was logged."):format(errorCounter))
	end

	local r1, r2, r3 = results[2], results[3], results[4]
	local success, message, undoFn
	if type(r1) == "string" then
		success, message = true, r1
	elseif type(r1) == "boolean" then
		success, message, undoFn = r1, r2, r3
	else
		success, message = true, "Done."
	end
	if message == nil then
		message = success and "Done." or "Failed."
	end

	if success then
		if type(undoFn) == "function" then
			local stack = undoStacks[player.UserId]
			if not stack then
				stack = {}
				undoStacks[player.UserId] = stack
			end
			table.insert(stack, { name = def.name, fn = undoFn })
			while #stack > 20 do
				table.remove(stack, 1)
			end
		end
		if not def.noAudit and not wasAudited() then
			deps.Audit.Log(player, def.name, nil, nil, nil, line)
		end
	end
	respond(player, id, success, message)
end

function CommandService.Init(d)
	deps = d

	local folder = script.Parent:WaitForChild("Commands")
	for _, mod in ipairs(folder:GetChildren()) do
		if mod:IsA("ModuleScript") then
			local ok, tbl = pcall(require, mod)
			if ok and type(tbl) == "table" then
				for name, fn in pairs(tbl) do
					if type(fn) == "function" then
						handlers[name:lower()] = fn
					end
				end
			else
				warn(("[Fxield] Command module '%s' failed to load: %s"):format(mod.Name, tostring(tbl)))
			end
		end
	end
	for _, def in ipairs(Definitions.All) do
		if not def.clientOnly and not handlers[def.name] then
			warn(("[Fxield] No handler registered for command '%s'."):format(def.name))
		end
	end

	deps.Remotes.CommandRequest.OnServerEvent:Connect(function(player, id, line, token)
		local ok, err = pcall(handleRequest, player, id, line, token)
		if not ok then
			busy[player.UserId] = nil
			warn("[Fxield] Request handler error: " .. tostring(err))
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local uid = player.UserId
		pending[uid], undoStacks[uid], busy[uid], lastDenied[uid] = nil, nil, nil, nil
		limiter:Clear(uid)
	end)
end

return CommandService
]=])

add("ServerScriptService/FxieldServer/CommandUtil", "ModuleScript", [=[
local Util = {}

function Util.GetHumanoid(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

function Util.GetRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function Util.Names(list)
	local names = {}
	for _, p in ipairs(list) do
		table.insert(names, p.Name)
	end
	return table.concat(names, ", ")
end

function Util.Summary(verb, done, skipped)
	local text = ("%s %d player(s)"):format(verb, done)
	if skipped > 0 then
		text ..= (" (%d skipped: left the server or has no character)"):format(skipped)
	end
	return text .. "."
end

function Util.EachTarget(ctx, list, fn)
	local done, skipped = 0, 0
	for _, p in ipairs(list) do
		if p.Parent == nil then
			skipped += 1
		elseif not ctx.CanTarget(p) then
			skipped += 1
		else
			local ok, res = pcall(fn, p)
			if ok and res ~= false then
				done += 1
			else
				skipped += 1
			end
		end
	end
	return done, skipped
end

function Util.SetConfig(ctx, key, raw, label)
	local Config = ctx.Config
	local old = Config.Get(key)
	local ok, results = Config.Apply({ [key] = raw }, ctx.Player, "command:" .. ctx.Definition.name)
	if not ok then
		local first = results and results[1]
		return false, first and first.error or "Invalid value."
	end
	local new = Config.Get(key)
	local undo = function()
		local restored = Config.Apply({ [key] = old }, ctx.Player, "undo")
		return restored, restored and ("Restored %s."):format(label or key) or "Could not restore."
	end
	return true, ("%s: %s -> %s"):format(label or key, tostring(old), tostring(new)), undo
end

return Util
]=])

add("ServerScriptService/FxieldServer/Commands/Admin", "ModuleScript", [=[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared"):WaitForChild("ConfigSchema"))
local Util = require(script.Parent.Parent.CommandUtil)

local H = {}

local function describeRange(field)
	if field.min and field.max then
		return (" [%s to %s]"):format(tostring(field.min), tostring(field.max))
	end
	return ""
end

function H.config(ctx, args)
	local action = args.action

	if action == "list" then
		local lines = {}
		for _, field in ipairs(Schema.Fields) do
			table.insert(lines, ("%s = %s%s"):format(field.key, tostring(ctx.Config.Get(field.key)), describeRange(field)))
		end
		return true, table.concat(lines, "\n")
	end

	if not args.key then
		return false, "Specify a key. Try 'config list'."
	end
	local field = Schema.ByKey[args.key]
	if not field then
		return false, "Unknown setting. Try 'config list'."
	end

	if action == "get" then
		return true, ("%s = %s%s\n%s"):format(field.key, tostring(ctx.Config.Get(field.key)), describeRange(field), field.description or "")
	end

	if args.value == nil then
		return false, "Specify a value. Usage: config set <key> <value>"
	end
	return Util.SetConfig(ctx, field.key, args.value, field.key)
end

function H.configreload(ctx)
	local ok, result = ctx.Config.Reload(ctx.Player)
	if not ok then
		return false, "Reload failed: " .. tostring(result)
	end
	return true, ("Configuration reloaded; %d setting(s) changed."):format(result)
end

function H.resetconfig(ctx, args)
	local keys = nil
	if args.key then
		if not Schema.ByKey[args.key] then
			return false, "Unknown setting."
		end
		keys = { args.key }
	end
	local ok, result = ctx.Config.Reset(keys, ctx.Player)
	if not ok then
		return false, tostring(result)
	end
	if result == nil then
		return true, "Already at default values."
	end
	return true, args.key and ("Reset %s to its default."):format(args.key) or "All settings reset to defaults."
end

function H.modules(ctx)
	local list = ctx.Modules.List()
	if #list == 0 then
		return true, "No runtime modules are registered."
	end
	local lines = {}
	for _, m in ipairs(list) do
		table.insert(lines, ("%s: %s%s | versions: %s | good: %s"):format(
			m.name,
			m.state,
			m.active and (" " .. m.active .. " (v" .. tostring(m.version) .. ")") or "",
			table.concat(m.versions, ", "),
			#m.good > 0 and table.concat(m.good, " > ") or "none"
		))
	end
	return true, table.concat(lines, "\n")
end

function H.modulereload(ctx, args)
	return ctx.Modules.Switch(args.name, args.version, ctx.Player)
end

function H.modulerollback(ctx, args)
	return ctx.Modules.Rollback(args.name, ctx.Player)
end

function H.undo(ctx)
	local entry = ctx.PopUndo()
	if not entry then
		return false, "Nothing to undo."
	end
	local ok, success, message = pcall(entry.fn)
	if not ok then
		return false, "The undo action failed."
	end
	ctx.Audit(entry.name, nil, nil, "undo")
	return success ~= false, message or ("Undid %s."):format(entry.name)
end

return H
]=])

add("ServerScriptService/FxieldServer/Commands/AuthAdmin", "ModuleScript", [=[
local H = {}

local function describeTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return ("%dh %dm"):format(seconds // 3600, (seconds % 3600) // 60)
	end
	return ("%dm %ds"):format(seconds // 60, seconds % 60)
end

function H.authlog(ctx, args)
	local wanted = args.count or 15
	local matches = {}
	local entries = ctx.AuditLog.GetRecent(300)
	for i = #entries, 1, -1 do
		local entry = entries[i]
		if type(entry.action) == "string" and entry.action:sub(1, 5) == "auth:" then
			table.insert(matches, 1, ctx.AuditLog.Format(entry))
			if #matches >= wanted then
				break
			end
		end
	end
	if #matches == 0 then
		return true, "No authentication events recorded yet."
	end
	return true, table.concat(matches, "\n")
end

function H.restrictions(ctx)
	local list, complete = ctx.Auth.ListRestrictions()
	if #list == 0 then
		return true, "No active restrictions." .. (complete and "" or " (The data store could not be read, so only this server's memory was checked.)")
	end
	local lines = {}
	local currentTime = os.time()
	for _, item in ipairs(list) do
		table.insert(lines, ("UserId %d: %s remaining, %d failed attempt(s) in total"):format(item.userId, describeTime(item.restrictedUntil - currentTime), item.totalFails))
	end
	table.insert(lines, "Reverse one with: unrestrict <userid>")
	return true, table.concat(lines, "\n")
end

function H.unrestrict(ctx, args)
	local ok, result = ctx.Auth.Unrestrict(args.userid, ctx.Player)
	if not ok then
		return false, tostring(result)
	end
	if result then
		return true, ("Restriction cleared for UserId %d."):format(args.userid)
	end
	return true, ("Restriction cleared for UserId %d on this server only; the data store was unavailable."):format(args.userid)
end

return H
]=])

add("ServerScriptService/FxieldServer/Commands/Info", "ModuleScript", [=[
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))

local H = {}

local function formatDuration(seconds)
	seconds = math.floor(seconds)
	return ("%dh %dm %ds"):format(seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

function H.serverinfo(ctx)
	local lines = {
		("%s %s"):format(Constants.Name, Constants.Version),
		("Place: %d (version %d)"):format(game.PlaceId, game.PlaceVersion),
		("Server: %s"):format(game.JobId == "" and "Studio" or game.JobId),
		("Players: %d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers),
		("Uptime: %s"):format(formatDuration(workspace.DistributedGameTime)),
		("Physics FPS: %.0f"):format(workspace:GetRealPhysicsFPS()),
		("Memory: %.0f MB"):format(Stats:GetTotalMemoryUsageMb()),
		("Maintenance: %s"):format(ctx.Config.Get("server.maintenance") and "ON" or "off"),
	}
	return true, table.concat(lines, "\n")
end

function H.playerinfo(ctx, args)
	local p = args.player
	if p.Parent == nil then
		return false, "That player already left."
	end
	local lines = {
		("%s (@%s) id %d"):format(p.DisplayName, p.Name, p.UserId),
		("Account age: %d days"):format(p.AccountAge),
		("Team: %s"):format(p.Team and p.Team.Name or "none"),
		("Ping: %.0f ms"):format(p:GetNetworkPing() * 1000),
	}
	if ctx.Level >= Constants.Levels.Owner then
		table.insert(lines, ("Fxield access: %s"):format(ctx.Permissions.GetLevelName(p)))
	end
	return true, table.concat(lines, "\n")
end

function H.auditlog(ctx, args)
	local entries = ctx.AuditLog.GetRecent(args.count or 10)
	if #entries == 0 then
		return true, "The audit log is empty."
	end
	local lines = {}
	for _, entry in ipairs(entries) do
		table.insert(lines, ctx.AuditLog.Format(entry))
	end
	return true, table.concat(lines, "\n")
end

function H.permissions(ctx, args)
	local action = args.action or "list"

	if action == "list" then
		local lines = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local active = ctx.Permissions.IsSessionActive(p)
			table.insert(lines, ("%s: %s%s"):format(p.Name, ctx.Permissions.GetLevelName(p), active and " (signed in)" or ""))
		end
		return true, table.concat(lines, "\n")
	end

	local target = args.player
	if not target then
		return false, "Specify a player."
	end
	if target == ctx.Player then
		return false, "You cannot end your own session."
	end
	local had = ctx.Auth.Revoke(target.UserId)
	ctx.Audit(target.Name, had and "signed in" or "not signed in", "signed out", "session revoked")
	ctx.Notify(target, "warn", "Your Fxield session was ended by the owner.", "Fxield", "signout")
	return true, had and ("Ended the Fxield session for %s."):format(target.Name) or ("%s was not signed in."):format(target.Name)
end

return H
]=])

add("ServerScriptService/FxieldServer/Commands/Moderation", "ModuleScript", [=[
local Util = require(script.Parent.Parent.CommandUtil)

local rng = Random.new()
local H = {}

function H.notify(ctx, args)
	local count = 0
	for _, p in ipairs(args.players) do
		if p.Parent then
			ctx.Notify(p, "info", args.text, "Message from staff")
			count += 1
		end
	end
	ctx.Audit(Util.Names(args.players), nil, args.text)
	return true, ("Notified %d player(s)."):format(count)
end

function H.kick(ctx, args)
	local target = args.player
	if target == ctx.Player then
		return false, "You cannot kick yourself."
	end
	local allowed, err = ctx.CanTarget(target)
	if not allowed then
		return false, err
	end
	if target.Parent == nil then
		return false, "That player already left."
	end
	local reason = args.reason or "No reason given."
	local name = target.Name
	ctx.Audit(name, nil, reason, "kick")
	target:Kick("Removed by a moderator. Reason: " .. reason)
	return true, ("Kicked %s."):format(name)
end

local function setAnchored(ctx, targets, state)
	local changed = {}
	local done, skipped = Util.EachTarget(ctx, targets, function(p)
		local root = Util.GetRoot(p)
		if not root then
			return false
		end
		if root.Anchored ~= state then
			table.insert(changed, p)
		end
		root.Anchored = state
		return true
	end)
	ctx.Audit(Util.Names(targets), tostring(not state), tostring(state))
	local undo = function()
		for _, p in ipairs(changed) do
			local root = p.Parent and Util.GetRoot(p)
			if root then
				root.Anchored = not state
			end
		end
		return true, "Reverted."
	end
	return done, skipped, undo
end

function H.freeze(ctx, args)
	local done, skipped, undo = setAnchored(ctx, args.players, true)
	return true, Util.Summary("Froze", done, skipped), undo
end

function H.unfreeze(ctx, args)
	local done, skipped, undo = setAnchored(ctx, args.players, false)
	return true, Util.Summary("Unfroze", done, skipped), undo
end

local function teleportMany(ctx, targets, destRoot, destPlayer)
	local previous = {}
	local done, skipped = Util.EachTarget(ctx, targets, function(p)
		if p == destPlayer then
			return false
		end
		local root = Util.GetRoot(p)
		if not root then
			return false
		end
		previous[p] = root.CFrame
		root.CFrame = destRoot.CFrame * CFrame.new(rng:NextNumber(-4, 4), 3, rng:NextNumber(-4, 4))
		return true
	end)
	local undo = function()
		local n = 0
		for p, cf in pairs(previous) do
			local root = p.Parent and Util.GetRoot(p)
			if root then
				root.CFrame = cf
				n += 1
			end
		end
		return true, ("Restored %d position(s)."):format(n)
	end
	return done, skipped, undo
end

function H.teleport(ctx, args)
	local destRoot = Util.GetRoot(args.destination)
	if not destRoot then
		return false, args.destination.Name .. " has no character."
	end
	local done, skipped, undo = teleportMany(ctx, args.players, destRoot, args.destination)
	ctx.Audit(Util.Names(args.players), nil, args.destination.Name, "teleport")
	return true, Util.Summary("Teleported", done, skipped), undo
end

H["goto"] = function(ctx, args)
	if args.player == ctx.Player then
		return false, "You are already there."
	end
	local destRoot = Util.GetRoot(args.player)
	if not destRoot then
		return false, args.player.Name .. " has no character."
	end
	local done, skipped, undo = teleportMany(ctx, { ctx.Player }, destRoot, args.player)
	if done == 0 then
		return false, "You have no character to teleport."
	end
	return true, ("Teleported to %s."):format(args.player.Name), undo
end

function H.bring(ctx, args)
	local destRoot = Util.GetRoot(ctx.Player)
	if not destRoot then
		return false, "You have no character."
	end
	local done, skipped, undo = teleportMany(ctx, args.players, destRoot, ctx.Player)
	ctx.Audit(Util.Names(args.players), nil, ctx.Player.Name, "bring")
	return true, Util.Summary("Brought", done, skipped), undo
end

function H.respawn(ctx, args)
	local done, skipped = Util.EachTarget(ctx, args.players, function(p)
		p:LoadCharacter()
		return true
	end)
	ctx.Audit(Util.Names(args.players), nil, nil, "respawn")
	return true, Util.Summary("Respawned", done, skipped)
end

function H.heal(ctx, args)
	local done, skipped = Util.EachTarget(ctx, args.players, function(p)
		local humanoid = Util.GetHumanoid(p)
		if not humanoid then
			return false
		end
		humanoid.Health = humanoid.MaxHealth
		return true
	end)
	ctx.Audit(Util.Names(args.players), nil, nil, "heal")
	return true, Util.Summary("Healed", done, skipped)
end

function H.setwalkspeed(ctx, args)
	local previous = {}
	local done, skipped = Util.EachTarget(ctx, args.players, function(p)
		local humanoid = Util.GetHumanoid(p)
		if not humanoid then
			return false
		end
		previous[p] = humanoid.WalkSpeed
		humanoid.WalkSpeed = args.speed
		return true
	end)
	ctx.Audit(Util.Names(args.players), "previous", args.speed)
	local undo = function()
		for p, speed in pairs(previous) do
			local humanoid = p.Parent and Util.GetHumanoid(p)
			if humanoid then
				humanoid.WalkSpeed = speed
			end
		end
		return true, "Walk speeds restored."
	end
	return true, Util.Summary("Set walk speed for", done, skipped) .. " (lasts until respawn or a Movement config change).", undo
end

function H.setjumppower(ctx, args)
	local previous = {}
	local done, skipped = Util.EachTarget(ctx, args.players, function(p)
		local humanoid = Util.GetHumanoid(p)
		if not humanoid then
			return false
		end
		previous[p] = humanoid.JumpPower
		humanoid.UseJumpPower = true
		humanoid.JumpPower = args.power
		return true
	end)
	ctx.Audit(Util.Names(args.players), "previous", args.power)
	local undo = function()
		for p, power in pairs(previous) do
			local humanoid = p.Parent and Util.GetHumanoid(p)
			if humanoid then
				humanoid.JumpPower = power
			end
		end
		return true, "Jump powers restored."
	end
	return true, Util.Summary("Set jump power for", done, skipped) .. " (lasts until respawn or a Movement config change).", undo
end

return H
]=])

add("ServerScriptService/FxieldServer/Commands/World", "ModuleScript", [=[
local Players = game:GetService("Players")
local Util = require(script.Parent.Parent.CommandUtil)

local H = {}

function H.announce(ctx, args)
	local title = ctx.Config.Get("ui.announcementPrefix")
	for _, p in ipairs(Players:GetPlayers()) do
		ctx.Notify(p, "announce", args.text, title)
	end
	ctx.Audit("everyone", nil, args.text, "announce")
	return true, "Announcement sent."
end

function H.setgravity(ctx, args)
	return Util.SetConfig(ctx, "gameplay.gravity", args.value, "Gravity")
end

function H.settimeofday(ctx, args)
	return Util.SetConfig(ctx, "world.clockTime", args.hours, "Time of day")
end

local lightingKeys = {
	brightness = "world.brightness",
	exposure = "world.exposure",
	fogend = "world.fogEnd",
}

function H.setlighting(ctx, args)
	local key = lightingKeys[args.property]
	if not key then
		return false, "Unknown lighting property."
	end
	return Util.SetConfig(ctx, key, args.value, args.property)
end

function H.setgamespeed(ctx, args)
	return Util.SetConfig(ctx, "gameplay.speedMultiplier", args.multiplier, "Movement speed multiplier")
end

local function resolveState(state, current)
	if state == nil then
		return not current
	end
	return state == "on"
end

function H.maintenance(ctx, args)
	local value = resolveState(args.state, ctx.Config.Get("server.maintenance"))
	return Util.SetConfig(ctx, "server.maintenance", value, "Maintenance mode")
end

function H.featuretoggle(ctx, args)
	local key = "features." .. args.feature
	local value = resolveState(args.state, ctx.Config.Get(key))
	return Util.SetConfig(ctx, key, value, args.feature)
end

return H
]=])

add("ServerScriptService/FxieldServer/ConfigService", "ModuleScript", [=[
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared"):WaitForChild("ConfigSchema"))

local ConfigService = {}

local HISTORY_MAX = 100
local SAVED_HISTORY = 50

local values = {}
local history = {}
local listeners = {}
local batchListeners = {}
local store
local audit
local dirty = false
local scheduled = false
local nextHistoryId = 1

local function defaults()
	local t = {}
	for _, field in ipairs(Schema.Fields) do
		t[field.key] = field.default
	end
	return t
end

local function actorInfo(actor)
	if typeof(actor) == "Instance" and actor:IsA("Player") then
		return actor.Name, actor.UserId
	elseif type(actor) == "string" then
		return actor, 0
	end
	return "System", 0
end

local function safeCall(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Fxield] Config listener error: " .. tostring(err))
	end
end

local function fetch()
	if not store then
		return nil, "DataStore unavailable"
	end
	local ok, data = pcall(function()
		return store:GetAsync("config_v1")
	end)
	if not ok then
		return nil, tostring(data)
	end
	return data, nil
end

local function sanitizeStored(data)
	local out = {}
	if type(data) ~= "table" or type(data.values) ~= "table" then
		return out
	end
	for _, field in ipairs(Schema.Fields) do
		local raw = data.values[field.key]
		if raw ~= nil then
			local ok, v = Schema.Validate(field, raw)
			if ok then
				out[field.key] = v
			end
		end
	end
	return out
end

local function markDirty()
	dirty = true
	if scheduled then
		return
	end
	scheduled = true
	task.delay(5, function()
		scheduled = false
		ConfigService.Flush()
	end)
end

local function commit(changes, kind, actor, reason)
	local actorName, actorId = actorInfo(actor)
	local entry = {
		id = nextHistoryId,
		time = os.time(),
		actor = actorName,
		actorId = actorId,
		kind = kind,
		reason = reason,
		changes = {},
	}
	nextHistoryId += 1

	for key, new in pairs(changes) do
		entry.changes[key] = { old = values[key], new = new }
		values[key] = new
	end

	table.insert(history, entry)
	while #history > HISTORY_MAX do
		table.remove(history, 1)
	end

	if audit then
		for key, change in pairs(entry.changes) do
			audit.Log(actor, "config:" .. kind, key, change.old, change.new, reason)
		end
	end

	markDirty()

	local snapshot = table.clone(listeners)
	for key, change in pairs(entry.changes) do
		for _, l in ipairs(snapshot) do
			if not l.dead and (l.key == nil or l.key == key) then
				task.spawn(safeCall, l.fn, key, change.new, change.old)
			end
		end
	end
	for _, l in ipairs(table.clone(batchListeners)) do
		if not l.dead then
			task.spawn(safeCall, l.fn, entry)
		end
	end
	return entry
end

local function addListener(list, l)
	table.insert(list, l)
	return {
		Disconnect = function()
			l.dead = true
			local i = table.find(list, l)
			if i then
				table.remove(list, i)
			end
		end,
	}
end

function ConfigService.Init(auditService)
	audit = auditService
	values = defaults()
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore("FxieldConfig")
	end)
	if ok then
		store = s
	end
	local data, err = fetch()
	if data then
		for key, v in pairs(sanitizeStored(data)) do
			values[key] = v
		end
		if type(data.history) == "table" then
			for _, e in ipairs(data.history) do
				if type(e) == "table" and type(e.changes) == "table" and type(e.id) == "number" then
					table.insert(history, e)
					nextHistoryId = math.max(nextHistoryId, e.id + 1)
				end
			end
		end
	elseif err then
		warn("[Fxield] Using default configuration (" .. err .. "). Enable Studio API access to persist settings.")
	end
end

function ConfigService.Get(key)
	return values[key]
end

function ConfigService.GetAll()
	return table.clone(values)
end

function ConfigService.OnChanged(key, fn)
	return addListener(listeners, { key = key, fn = fn })
end

function ConfigService.OnBatch(fn)
	return addListener(batchListeners, { fn = fn })
end

function ConfigService.Preview(changes)
	local results, allOk = {}, true
	if type(changes) ~= "table" then
		return { { key = "*", ok = false, error = "Bad request." } }, false
	end
	local keys = {}
	for k in pairs(changes) do
		if type(k) ~= "string" then
			return { { key = "*", ok = false, error = "Bad request." } }, false
		end
		table.insert(keys, k)
	end
	if #keys > 64 then
		return { { key = "*", ok = false, error = "Too many changes." } }, false
	end
	table.sort(keys)

	for _, key in ipairs(keys) do
		local field = Schema.ByKey[key]
		local res = { key = key }
		if not field then
			res.ok = false
			res.error = "Unknown setting."
		else
			res.label = field.label
			local raw = changes[key]
			local tr = type(raw)
			if tr ~= "number" and tr ~= "string" and tr ~= "boolean" then
				res.ok = false
				res.error = "Invalid value type."
			elseif tr == "string" and #raw > 200 then
				res.ok = false
				res.error = "Value is too long."
			else
				local ok, v = Schema.Validate(field, raw)
				if ok then
					res.ok = true
					res.old = values[key]
					res.new = v
					res.unchanged = (v == values[key])
				else
					res.ok = false
					res.error = v
				end
			end
		end
		if not res.ok then
			allOk = false
		end
		table.insert(results, res)
	end
	return results, allOk
end

function ConfigService.Apply(changes, actor, reason)
	local results, allOk = ConfigService.Preview(changes)
	if not allOk then
		return false, results
	end
	local delta, count = {}, 0
	for _, r in ipairs(results) do
		if not r.unchanged then
			delta[r.key] = r.new
			count += 1
		end
	end
	if count == 0 then
		return true, results, nil
	end
	return true, results, commit(delta, "set", actor, reason)
end

function ConfigService.Undo(actor)
	for i = #history, 1, -1 do
		local entry = history[i]
		if not entry.undone and entry.kind ~= "undo" then
			local delta = {}
			for key, change in pairs(entry.changes) do
				if Schema.ByKey[key] then
					delta[key] = change.old
				end
			end
			entry.undone = true
			return true, commit(delta, "undo", actor, "undo #" .. tostring(entry.id))
		end
	end
	return false, "Nothing to undo."
end

function ConfigService.Reset(keys, actor)
	local delta, count = {}, 0
	local function consider(field)
		if values[field.key] ~= field.default then
			delta[field.key] = field.default
			count += 1
		end
	end
	if keys == nil then
		for _, field in ipairs(Schema.Fields) do
			consider(field)
		end
	else
		for _, key in ipairs(keys) do
			local field = Schema.ByKey[key]
			if not field then
				return false, "Unknown setting: " .. tostring(key)
			end
			consider(field)
		end
	end
	if count == 0 then
		return true, nil
	end
	return true, commit(delta, "reset", actor, keys and "reset keys" or "reset all")
end

function ConfigService.Reload(actor)
	local data, err = fetch()
	if err then
		return false, err
	end
	local fresh = defaults()
	for key, v in pairs(sanitizeStored(data)) do
		fresh[key] = v
	end
	local delta, count = {}, 0
	for key, v in pairs(fresh) do
		if values[key] ~= v then
			delta[key] = v
			count += 1
		end
	end
	if count > 0 then
		commit(delta, "reload", actor, "configreload")
	end
	return true, count
end

function ConfigService.GetHistory(limit)
	local out = {}
	local stop = math.max(1, #history - (limit or 30) + 1)
	for i = #history, stop, -1 do
		local e = history[i]
		local changes = {}
		for key, change in pairs(e.changes) do
			changes[key] = { old = change.old, new = change.new }
		end
		table.insert(out, {
			id = e.id,
			time = e.time,
			actor = e.actor,
			kind = e.kind,
			reason = e.reason,
			undone = e.undone == true,
			changes = changes,
		})
	end
	return out
end

function ConfigService.Flush()
	if not store or not dirty then
		return
	end
	dirty = false
	local saved = {}
	local first = math.max(1, #history - SAVED_HISTORY + 1)
	for i = first, #history do
		table.insert(saved, history[i])
	end
	local payload = { version = 1, values = table.clone(values), history = saved }
	local ok, err = pcall(function()
		store:SetAsync("config_v1", payload)
	end)
	if not ok then
		dirty = true
		warn("[Fxield] Config save failed: " .. tostring(err))
	end
end

return ConfigService
]=])

add("ServerScriptService/FxieldServer/ModuleManager", "ModuleScript", [=[
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared"):WaitForChild("ConfigSchema"))

local ModuleManager = {}
ModuleManager.API_VERSION = 1

local records = {}
local deps
local loadedFolder

local function findRecord(name)
	if type(name) ~= "string" then
		return nil
	end
	local lowered = name:lower()
	for recordName, rec in pairs(records) do
		if recordName:lower() == lowered then
			return rec
		end
	end
	return nil
end

local function newContext(name, version)
	local ctx = { Name = name, Version = version, Config = deps.Config, alive = true, _tracked = {}, _threads = {} }

	function ctx:Track(obj)
		table.insert(self._tracked, obj)
		return obj
	end
	function ctx:Connect(signal, fn)
		return self:Track(signal:Connect(fn))
	end
	function ctx:OnConfig(key, fn)
		return self:Track(self.Config.OnChanged(key, fn))
	end
	function ctx:Spawn(fn, ...)
		local thread = task.spawn(fn, ...)
		table.insert(self._threads, thread)
		return thread
	end
	function ctx:Log(msg)
		print(("[Fxield][%s %s] %s"):format(self.Name, tostring(self.Version), tostring(msg)))
	end
	function ctx:Cleanup()
		self.alive = false
		for _, obj in ipairs(self._tracked) do
			local t = typeof(obj)
			if t == "RBXScriptConnection" then
				obj:Disconnect()
			elseif t == "Instance" then
				obj:Destroy()
			elseif t == "function" then
				pcall(obj)
			elseif t == "table" and type(obj.Disconnect) == "function" then
				pcall(obj.Disconnect, obj)
			end
		end
		for _, thread in ipairs(self._threads) do
			pcall(task.cancel, thread)
		end
		table.clear(self._tracked)
		table.clear(self._threads)
	end
	return ctx
end

local function validateShape(name, mod)
	if type(mod) ~= "table" then
		return false, "module did not return a table"
	end
	if mod.Name ~= name then
		return false, ("module Name must be '%s'"):format(name)
	end
	if type(mod.Version) ~= "string" then
		return false, "missing Version string"
	end
	if mod.ApiVersion ~= ModuleManager.API_VERSION then
		return false, ("incompatible ApiVersion %s (expected %d)"):format(tostring(mod.ApiVersion), ModuleManager.API_VERSION)
	end
	if type(mod.Start) ~= "function" or type(mod.Stop) ~= "function" then
		return false, "Start and Stop functions are required"
	end
	if mod.ConfigKeys ~= nil then
		if type(mod.ConfigKeys) ~= "table" then
			return false, "ConfigKeys must be a list"
		end
		for _, key in ipairs(mod.ConfigKeys) do
			if not Schema.ByKey[key] then
				return false, ("requires unknown config key '%s'"):format(tostring(key))
			end
		end
	end
	return true
end

local function loadVersion(rec, versionName)
	local source = type(versionName) == "string" and rec.folder:FindFirstChild(versionName) or nil
	if not source or not source:IsA("ModuleScript") then
		return false, "unknown version '" .. tostring(versionName) .. "'"
	end
	local clone = source:Clone()
	clone.Parent = loadedFolder
	local ok, mod = pcall(require, clone)
	if not ok then
		clone:Destroy()
		return false, "failed to load: " .. tostring(mod)
	end
	local valid, err = validateShape(rec.name, mod)
	if not valid then
		clone:Destroy()
		return false, err
	end
	return true, mod, clone
end

local function runValidate(rec, mod, versionName)
	if type(mod.Validate) ~= "function" then
		return true
	end
	local tmp = newContext(rec.name, versionName)
	local ok, res, err = pcall(mod.Validate, tmp)
	tmp:Cleanup()
	if not ok then
		return false, tostring(res)
	end
	if res == false then
		return false, tostring(err or "Validate returned false")
	end
	return true
end

local function stopActive(rec)
	if not rec.module then
		return
	end
	local ok, err = pcall(rec.module.Stop, rec.ctx)
	if not ok then
		warn(("[Fxield] Module %s Stop error: %s"):format(rec.name, tostring(err)))
	end
	rec.ctx:Cleanup()
	rec.module = nil
	rec.ctx = nil
end

local function startModule(rec, mod, clone, versionName)
	local ctx = newContext(rec.name, versionName)
	local ok, err = pcall(mod.Start, ctx)
	if not ok then
		ctx:Cleanup()
		return false, tostring(err)
	end
	rec.module, rec.ctx, rec.clone, rec.active = mod, ctx, clone, versionName
	rec.state = "active"
	return true
end

local function doSwitch(rec, versionName, actor)
	local function log(note, old, new)
		deps.Audit.Log(actor, "module:" .. rec.name, rec.name, old, new, note)
	end
	local previousVersion = rec.active

	local ok, modOrErr, clone = loadVersion(rec, versionName)
	if not ok then
		log("rejected: " .. modOrErr, previousVersion, versionName)
		return false, "Update rejected: " .. modOrErr
	end
	local mod = modOrErr

	local okValidate, errValidate = runValidate(rec, mod, versionName)
	if not okValidate then
		clone:Destroy()
		log("validation failed: " .. errValidate, previousVersion, versionName)
		return false, "Update rejected: validation failed (" .. errValidate .. ")"
	end

	local old = { mod = rec.module, clone = rec.clone, version = rec.active }
	stopActive(rec)
	local started, startErr = startModule(rec, mod, clone, versionName)
	if started then
		if old.clone and old.clone ~= clone then
			old.clone:Destroy()
		end
		table.insert(rec.good, versionName)
		while #rec.good > 5 do
			table.remove(rec.good, 1)
		end
		log("activated", previousVersion, versionName)
		return true, ("%s is now running %s (v%s)."):format(rec.name, versionName, mod.Version)
	end

	clone:Destroy()
	log("start failed: " .. startErr, previousVersion, versionName)
	if old.mod then
		local restored = startModule(rec, old.mod, old.clone, old.version)
		if restored then
			log("rolled back", versionName, old.version)
			return false, ("Update failed (%s). Rolled back to %s."):format(startErr, old.version)
		end
	end

	for i = #rec.good, 1, -1 do
		local v = rec.good[i]
		if v ~= versionName and v ~= old.version then
			local okLoad, mod2, clone2 = loadVersion(rec, v)
			if okLoad then
				if startModule(rec, mod2, clone2, v) then
					log("recovered with " .. v, versionName, v)
					return false, ("Update failed (%s). Recovered with %s."):format(startErr, v)
				end
				clone2:Destroy()
			end
		end
	end

	rec.state = "failed"
	rec.active = nil
	log("recovery failed; module disabled", versionName, nil)
	return false, "Update failed and no known-good version could be restored. The module is disabled."
end

function ModuleManager.Init(d)
	deps = d
	loadedFolder = Instance.new("Folder")
	loadedFolder.Name = "FxieldLoadedModules"
	loadedFolder.Parent = ServerStorage
end

function ModuleManager.Register(folder, defaultVersion)
	records[folder.Name] = {
		name = folder.Name,
		folder = folder,
		default = defaultVersion,
		good = {},
		state = "stopped",
		busy = false,
	}
end

function ModuleManager.Switch(name, versionName, actor)
	local rec = findRecord(name)
	if not rec then
		return false, "Unknown module."
	end
	if rec.busy then
		return false, "That module is busy with another operation."
	end
	rec.busy = true
	local ok, a, b = pcall(doSwitch, rec, versionName or rec.active or rec.default, actor)
	rec.busy = false
	if not ok then
		warn("[Fxield] Module switch crashed: " .. tostring(a))
		deps.Audit.Log(actor, "module:" .. rec.name, rec.name, nil, nil, "internal error")
		return false, "Update failed unexpectedly. See the server log."
	end
	return a, b
end

function ModuleManager.Rollback(name, actor)
	local rec = findRecord(name)
	if not rec then
		return false, "Unknown module."
	end
	local target
	for i = #rec.good - 1, 1, -1 do
		if rec.good[i] ~= rec.active then
			target = rec.good[i]
			break
		end
	end
	if not target then
		return false, "No earlier known-good version to roll back to."
	end
	return ModuleManager.Switch(name, target, actor)
end

function ModuleManager.List()
	local out = {}
	for _, rec in pairs(records) do
		local versions = {}
		for _, child in ipairs(rec.folder:GetChildren()) do
			if child:IsA("ModuleScript") then
				table.insert(versions, child.Name)
			end
		end
		table.sort(versions)
		table.insert(out, {
			name = rec.name,
			state = rec.state,
			active = rec.active,
			version = rec.module and rec.module.Version or nil,
			versions = versions,
			good = table.clone(rec.good),
		})
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

function ModuleManager.StartAll()
	for _, rec in pairs(records) do
		local ok, msg = ModuleManager.Switch(rec.name, rec.default, "System")
		if not ok then
			warn(("[Fxield] Module %s failed to start: %s"):format(rec.name, tostring(msg)))
		end
	end
end

function ModuleManager.StopAll()
	for _, rec in pairs(records) do
		if not rec.busy then
			pcall(stopActive, rec)
		end
	end
end

return ModuleManager
]=])

add("ServerScriptService/FxieldServer/PermissionService", "ModuleScript", [=[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared"):WaitForChild("Constants"))
local ServerConfig = require(script.Parent.ServerConfig)
local AuthService = require(script.Parent.AuthService)

local Levels = Constants.Levels

local PermissionService = {}
PermissionService.OwnerVerified = false

function PermissionService.Init()
	local ownerId = ServerConfig.OwnerUserId
	if type(ownerId) ~= "number" or ownerId <= 0 or ownerId % 1 ~= 0 then
		warn("[Fxield] The owner account is not configured, so administration is disabled (fail closed). Set OwnerUserId in ServerScriptService > FxieldServer > ServerConfig to the numeric UserId of " .. ServerConfig.OwnerUsername .. ", or re-run the installer while connected to the internet.")
		AuthService.SetOwnerVerified(false)
		return
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(ownerId)
	end)
	if ok and type(name) == "string" then
		if name:lower() ~= ServerConfig.OwnerUsername:lower() and ServerConfig.StrictOwnerNameCheck then
			warn(("[Fxield] OwnerUserId %d belongs to '%s', not '%s'. Administration is disabled. Correct ServerConfig, or set StrictOwnerNameCheck to false only if the owner renamed the account."):format(ownerId, name, ServerConfig.OwnerUsername))
			AuthService.SetOwnerVerified(false)
			return
		end
	else
		warn("[Fxield] Could not re-check the owner account name right now; continuing with the configured UserId.")
	end
	PermissionService.OwnerVerified = true
	AuthService.SetOwnerVerified(true)
end

function PermissionService.IsOwner(player)
	return PermissionService.OwnerVerified
		and typeof(player) == "Instance"
		and player:IsA("Player")
		and player.UserId == ServerConfig.OwnerUserId
end

function PermissionService.IsSessionActive(player)
	if AuthService.IsAuthenticated(player) then
		return true
	end
	return (not ServerConfig.OwnerRequiresKey) and PermissionService.IsOwner(player)
end

function PermissionService.GetLevel(player)
	if not PermissionService.IsSessionActive(player) then
		return Levels.Guest
	end
	if PermissionService.IsOwner(player) then
		return Levels.Owner
	end
	return Levels.Member
end

function PermissionService.GetLevelName(player)
	return Constants.LevelNames[PermissionService.GetLevel(player)] or "Guest"
end

return PermissionService
]=])

add("ServerScriptService/FxieldServer/PreferencesService", "ModuleScript", [=[
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared")
local Schema = require(Shared:WaitForChild("ConfigSchema"))
local PrefsSchema = require(Shared:WaitForChild("PrefsSchema"))

local PreferencesService = {}

local cache = {}
local store
local config

local function save(userId)
	local entry = cache[userId]
	if not store or not entry or not entry.dirty then
		return
	end
	entry.dirty = false
	local ok, err = pcall(function()
		store:SetAsync(tostring(userId), entry.stored)
	end)
	if not ok then
		entry.dirty = true
		warn("[Fxield] Preferences save failed: " .. tostring(err))
	end
end

local function ensure(player)
	local entry = cache[player.UserId]
	if entry then
		return entry
	end
	entry = { stored = {}, dirty = false }
	if store then
		local ok, data = pcall(function()
			return store:GetAsync(tostring(player.UserId))
		end)
		if ok and type(data) == "table" then
			for _, field in ipairs(PrefsSchema.Fields) do
				local raw = data[field.key]
				if raw ~= nil then
					local valid, v = Schema.Validate(field, raw)
					if valid then
						entry.stored[field.key] = v
					end
				end
			end
		end
	end
	if player.Parent then
		cache[player.UserId] = entry
	end
	return entry
end

function PreferencesService.Init(configService)
	config = configService
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore("FxieldPrefs")
	end)
	if ok then
		store = s
	end
	Players.PlayerRemoving:Connect(function(player)
		task.spawn(function()
			save(player.UserId)
			cache[player.UserId] = nil
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(60)
			for userId in pairs(cache) do
				save(userId)
			end
		end
	end)
end

function PreferencesService.Get(player)
	local entry = ensure(player)
	local out = {}
	for _, field in ipairs(PrefsSchema.Fields) do
		local v = entry.stored[field.key]
		if v == nil then
			v = field.default
			if field.key == "accent" and config then
				v = config.Get("ui.defaultAccent") or v
			end
		end
		out[field.key] = v
	end
	return out
end

function PreferencesService.Set(player, payload)
	if type(payload) ~= "table" then
		return false, { ["*"] = "Bad request." }
	end
	local entry = ensure(player)
	local errors, hadError = {}, false
	local n = 0
	for key, raw in pairs(payload) do
		n += 1
		if n > 16 then
			break
		end
		local field = type(key) == "string" and PrefsSchema.ByKey[key] or nil
		local tr = type(raw)
		if not field or (tr ~= "number" and tr ~= "string" and tr ~= "boolean") then
			errors[tostring(key)] = "Unknown preference."
			hadError = true
		else
			local ok, v = Schema.Validate(field, raw)
			if ok then
				entry.stored[key] = v
				entry.dirty = true
			else
				errors[key] = v
				hadError = true
			end
		end
	end
	if hadError then
		return false, errors
	end
	return true
end

function PreferencesService.SaveAll()
	for userId in pairs(cache) do
		save(userId)
	end
end

return PreferencesService
]=])

add("ServerScriptService/FxieldServer/RateLimiter", "ModuleScript", [=[
local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(capacity, refillPerSecond)
	return setmetatable({
		capacity = capacity,
		rate = refillPerSecond,
		buckets = {},
	}, RateLimiter)
end

function RateLimiter:Take(key, cost)
	cost = cost or 1
	local now = os.clock()
	local bucket = self.buckets[key]
	if not bucket then
		bucket = { tokens = self.capacity, t = now }
		self.buckets[key] = bucket
	end
	bucket.tokens = math.min(self.capacity, bucket.tokens + (now - bucket.t) * self.rate)
	bucket.t = now
	if bucket.tokens >= cost then
		bucket.tokens -= cost
		return true
	end
	return false
end

function RateLimiter:Clear(key)
	self.buckets[key] = nil
end

return RateLimiter
]=])

add("ServerScriptService/FxieldServer/RuntimeModules/Movement/v1", "ModuleScript", [=[
local Players = game:GetService("Players")

local M = {
	Name = "Movement",
	Version = "1.0.0",
	ApiVersion = 1,
	ConfigKeys = { "gameplay.walkSpeed", "gameplay.jumpPower", "gameplay.speedMultiplier" },
}

local function apply(ctx, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local C = ctx.Config
	humanoid.WalkSpeed = C.Get("gameplay.walkSpeed") * C.Get("gameplay.speedMultiplier")
	humanoid.UseJumpPower = true
	humanoid.JumpPower = C.Get("gameplay.jumpPower")
end

function M.Start(ctx)
	local function hookPlayer(player)
		ctx:Connect(player.CharacterAdded, function(character)
			ctx:Spawn(function()
				local humanoid = character:WaitForChild("Humanoid", 10)
				if humanoid and ctx.alive then
					apply(ctx, character)
				end
			end)
		end)
		if player.Character then
			apply(ctx, player.Character)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		hookPlayer(player)
	end
	ctx:Connect(Players.PlayerAdded, hookPlayer)

	local function reapply()
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				apply(ctx, player.Character)
			end
		end
	end
	for _, key in ipairs(M.ConfigKeys) do
		ctx:OnConfig(key, reapply)
	end
end

function M.Stop(ctx)

end

return M
]=])

add("ServerScriptService/FxieldServer/RuntimeModules/Movement/v2", "ModuleScript", [=[
local Players = game:GetService("Players")

local M = {
	Name = "Movement",
	Version = "2.0.0",
	ApiVersion = 1,
	ConfigKeys = { "gameplay.walkSpeed", "gameplay.jumpPower", "gameplay.speedMultiplier", "gameplay.autoJump" },
}

function M.Validate(ctx)
	if type(ctx.Config.Get("gameplay.autoJump")) ~= "boolean" then
		return false, "gameplay.autoJump must be a boolean"
	end
	return true
end

local function apply(ctx, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local C = ctx.Config
	humanoid.WalkSpeed = C.Get("gameplay.walkSpeed") * C.Get("gameplay.speedMultiplier")
	humanoid.UseJumpPower = true
	humanoid.JumpPower = C.Get("gameplay.jumpPower")
	humanoid.AutoJumpEnabled = C.Get("gameplay.autoJump")
end

function M.Start(ctx)
	local function hookPlayer(player)
		ctx:Connect(player.CharacterAdded, function(character)
			ctx:Spawn(function()
				local humanoid = character:WaitForChild("Humanoid", 10)
				if humanoid and ctx.alive then
					apply(ctx, character)
				end
			end)
		end)
		if player.Character then
			apply(ctx, player.Character)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		hookPlayer(player)
	end
	ctx:Connect(Players.PlayerAdded, hookPlayer)

	local function reapply()
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				apply(ctx, player.Character)
			end
		end
	end
	for _, key in ipairs(M.ConfigKeys) do
		ctx:OnConfig(key, reapply)
	end
end

function M.Stop(ctx) end

return M
]=])

add("ServerScriptService/FxieldServer/RuntimeModules/Movement/v3_broken", "ModuleScript", [=[
local M = {
	Name = "Movement",
	Version = "3.0.0-broken",
	ApiVersion = 1,
	ConfigKeys = { "gameplay.walkSpeed" },
}

function M.Start(ctx)
	ctx:OnConfig("gameplay.walkSpeed", function() end)
	error("Simulated failure in Start")
end

function M.Stop(ctx) end

return M
]=])

add("ServerScriptService/FxieldServer/RuntimeModules/Movement/v4_incompatible", "ModuleScript", [=[
local M = {
	Name = "Movement",
	Version = "4.0.0-incompatible",
	ApiVersion = 99,
	ConfigKeys = { "gameplay.doesNotExist" },
}

function M.Start(ctx) end
function M.Stop(ctx) end

return M
]=])

add("ServerScriptService/FxieldServer/RuntimeModules/WorldSettings/v1", "ModuleScript", [=[
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local appliers = {
	["gameplay.gravity"] = function(v)
		workspace.Gravity = v
	end,
	["gameplay.respawnTime"] = function(v)
		Players.RespawnTime = v
	end,
	["world.clockTime"] = function(v)
		Lighting.ClockTime = v
	end,
	["world.brightness"] = function(v)
		Lighting.Brightness = v
	end,
	["world.exposure"] = function(v)
		Lighting.ExposureCompensation = v
	end,
	["world.fogEnd"] = function(v)
		Lighting.FogEnd = v
	end,
}

local keys = {}
for key in pairs(appliers) do
	table.insert(keys, key)
end

local M = {
	Name = "WorldSettings",
	Version = "1.0.0",
	ApiVersion = 1,
	ConfigKeys = keys,
}

function M.Start(ctx)
	for key, apply in pairs(appliers) do
		apply(ctx.Config.Get(key))
		ctx:OnConfig(key, function(_, value)
			apply(value)
		end)
	end
end

function M.Stop(ctx) end

return M
]=])

add("ServerScriptService/FxieldServer/ServerConfig", "ModuleScript", [=[
local ServerConfig = {
	OwnerUsername = "FxplayzOfficial",
	OwnerUserId = 0,
	StrictOwnerNameCheck = true,
	OwnerRequiresKey = true,

	AccessKey = "GrW5_12freekeys-17091gsk82kHoBqjsfDgjJE",
	MaxFailedAttempts = 3,
	RestrictionSeconds = 3600,
	FailClosedOnStoreError = true,

	ShowLauncherToGuests = true,
}

return ServerConfig
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/Bootstrap", "LocalScript", [=[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Fxield = ReplicatedStorage:WaitForChild("Fxield")

local Notifications = require(script.Parent.NotificationController)
local Startup = require(script.Parent.StartupController)
local CommandController = require(script.Parent.CommandController)
local UIController = require(script.Parent.UIController)

local REQUEST_TIMEOUT = 10
local READY_TIMEOUT = 20
local DEFAULT_KEYBIND = "Semicolon"
local REMOTE_NAMES = { "CommandRequest", "CommandResponse", "Notification", "ConfigUpdate", "ConfigRequest", "Session", "Auth" }

local remotes
local running = false
local locked = false

local function waitForServer(timeout)
	if Fxield:GetAttribute("Ready") then
		return true
	end
	local signal = Instance.new("BindableEvent")
	local connection = Fxield:GetAttributeChangedSignal("Ready"):Connect(function()
		if Fxield:GetAttribute("Ready") then
			signal:Fire(true)
		end
	end)
	task.delay(timeout, function()
		signal:Fire(false)
	end)
	local ready = signal.Event:Wait()
	connection:Disconnect()
	signal:Destroy()
	return ready
end

local function connectRemotes(timeout)
	if remotes then
		return remotes
	end
	if not waitForServer(timeout) then
		return nil, "The Fxield server did not respond in time. It may still be starting."
	end
	local folder = Fxield:WaitForChild("Remotes", 5)
	if not folder then
		return nil, "Fxield remotes are missing. Reinstall Fxield."
	end
	local found = {}
	for _, name in ipairs(REMOTE_NAMES) do
		local remote = folder:WaitForChild(name, 5)
		if not remote then
			return nil, "Fxield remote '" .. name .. "' is missing. Reinstall Fxield."
		end
		found[name] = remote
	end
	remotes = found
	Notifications.Attach(remotes)
	return remotes
end

local function invoke(remote, timeout, ...)
	local args = table.pack(...)
	local signal = Instance.new("BindableEvent")
	local done, success, value = false, false, nil
	task.spawn(function()
		local ok, result = pcall(function()
			return remote:InvokeServer(table.unpack(args, 1, args.n))
		end)
		if not done then
			done, success, value = true, ok, result
			signal:Fire()
		end
	end)
	task.delay(timeout, function()
		if not done then
			done, success, value = true, false, "timeout"
			signal:Fire()
		end
	end)
	if not done then
		signal.Event:Wait()
	end
	signal:Destroy()
	return success, value
end

local activate

local function failFlow(message)
	Startup.ShowLoadingError(message, function()
		running = false
		activate()
	end, function()
		Startup.HideLoading()
		running = false
	end)
end

local function promptForKey(status)
	local accepted = false
	local finished = Instance.new("BindableEvent")
	Startup.ShowKeyScreen(status, {
		submit = function(key)
			local ok, result = invoke(remotes.Auth, REQUEST_TIMEOUT, "submit", key)
			if ok and type(result) == "table" then
				return result
			end
			return nil
		end,
		onSuccess = function()
			accepted = true
			Startup.HideKeyScreen()
			finished:Fire()
		end,
		onClose = function()
			Startup.HideKeyScreen()
			finished:Fire()
		end,
	})
	finished.Event:Wait()
	finished:Destroy()
	return accepted
end

local function runFlow()
	Startup.ShowLoading()
	Startup.SetProgress(0.1, "Connecting to the server")
	local connected, connectError = connectRemotes(READY_TIMEOUT)
	if not connected then
		return failFlow(connectError)
	end

	Startup.SetProgress(0.3, "Checking access")
	local okStatus, status = invoke(remotes.Auth, REQUEST_TIMEOUT, "status")
	if not okStatus or type(status) ~= "table" or status.ok ~= true then
		return failFlow(status == "timeout" and "The server took too long to answer. Check your connection and retry." or "Could not check your access. Please retry.")
	end

	if status.state ~= "authenticated" then
		Startup.HideLoading()
		if not promptForKey(status) then
			running = false
			return
		end
		Startup.ShowLoading()
	end

	Startup.SetProgress(0.6, "Loading your session")
	local okSession, session = invoke(remotes.Session, REQUEST_TIMEOUT, "hello")
	if not okSession or type(session) ~= "table" or session.ok ~= true then
		if type(session) == "table" and session.code == "auth" then
			running = false
			return activate()
		end
		return failFlow(session == "timeout" and "The server took too long to answer. Check your connection and retry." or "Could not load your session. Please retry.")
	end

	if not UIController.IsBuilt() then
		Startup.SetProgress(0.8, "Building the interface")
		local built, buildError = pcall(function()
			CommandController.Init(session.commands, remotes)
			UIController.Init({ Remotes = remotes, session = session })
		end)
		if not built then
			warn("[Fxield] Interface failed to build: " .. tostring(buildError))
			UIController.Destroy()
			return failFlow("The interface could not be built. Details are in the Output window.")
		end
	end

	locked = false
	Startup.SetProgress(1, "Ready")
	task.wait(0.15)
	Startup.HideLoading()
	UIController.Show()
	running = false
end

activate = function()
	if running then
		return
	end
	if UIController.IsBuilt() and not locked then
		UIController.Toggle()
		return
	end
	running = true
	task.spawn(function()
		local ok, err = pcall(runFlow)
		if not ok then
			warn("[Fxield] Startup error: " .. tostring(err))
			failFlow("An unexpected error occurred. Details are in the Output window.")
		end
	end)
end

Startup.Init()
Notifications.Init()

Notifications.SetActionHandler(function(action)
	if action == "signout" then
		locked = true
		UIController.Hide()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UIController.IsCapturingKey() then
		return
	end
	local keybind = UIController.IsBuilt() and UIController.GetKeybind() or DEFAULT_KEYBIND
	if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name == keybind then
		activate()
	end
end)

task.spawn(function()
	local connected = connectRemotes(READY_TIMEOUT)
	if not connected then
		Startup.SetLauncher(true, activate)
		return
	end
	local ok, status = invoke(remotes.Auth, REQUEST_TIMEOUT, "status")
	local visible = true
	if ok and type(status) == "table" and status.showLauncher == false then
		visible = false
	end
	Startup.SetLauncher(visible, activate)
end)
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/CommandController", "ModuleScript", [=[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared"):WaitForChild("Constants"))

local CC = {}
CC.History = {}

local defs, byName = {}, {}
local remotes
local requests = {}
local responseConnection
local nextId = 0
local ui = { Print = function() end, Confirm = function() end, Actions = {} }

local MAX_HISTORY = 100

function CC.SetUI(handlers)
	ui = handlers
end

function CC.GetDefinitions()
	return defs
end

function CC.Names()
	local names = {}
	for name in pairs(byName) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

local function sendToServer(line, token)
	nextId += 1
	local id = nextId
	requests[id] = line
	remotes.CommandRequest:FireServer(id, line, token)
	task.delay(15, function()
		if requests[id] then
			requests[id] = nil
			ui.Print("No response from the server.", "error")
		end
	end)
end

local function onResponse(data)
	if type(data) ~= "table" or type(data.id) ~= "number" or not requests[data.id] then
		return
	end
	local line = requests[data.id]
	requests[data.id] = nil
	local message = tostring(data.message or "")
	if data.needsConfirm == true and type(data.token) == "string" then
		local token = data.token
		ui.Confirm(("%s\n\nRun: %s"):format(message, line), function()
			sendToServer(line, token)
		end)
		ui.Print("Confirmation required.", "warn")
		return
	end
	ui.Print(message, data.ok == true and "success" or "error")
end

local function describe(def)
	local lines = { def.name .. " - " .. def.description, "Usage: " .. def.usage }
	if def.aliases and #def.aliases > 0 then
		table.insert(lines, "Aliases: " .. table.concat(def.aliases, ", "))
	end
	table.insert(lines, ("Category: %s | Requires: %s"):format(def.category, Constants.LevelNames[def.level] or "?"))
	if def.confirm then
		table.insert(lines, "Asks for confirmation before running.")
	end
	return table.concat(lines, "\n")
end

local localHandlers = {}

function localHandlers.help(args)
	if args[1] then
		local def = byName[args[1]:lower()]
		if not def then
			return ui.Print("Unknown command '" .. args[1] .. "'.", "error")
		end
		return ui.Print(describe(def), "info")
	end
	ui.Print(
		"Type a command and press Enter. 'commands' lists what you can run, 'help <command>' explains one, 'search <text>' finds one.\n"
			.. "Tab autocompletes. Up/Down browse history. Players can be 'me', 'all', 'others' or part of a name.",
		"info"
	)
end

function localHandlers.commands(args)
	local wanted = args[1] and args[1]:lower()
	local byCategory, categories = {}, {}
	for _, def in ipairs(defs) do
		if not wanted or def.category:lower() == wanted then
			if not byCategory[def.category] then
				byCategory[def.category] = {}
				table.insert(categories, def.category)
			end
			table.insert(byCategory[def.category], ("  %s - %s"):format(def.name, def.description))
		end
	end
	if #categories == 0 then
		return ui.Print("No commands found.", "error")
	end
	table.sort(categories)
	local lines = {}
	for _, category in ipairs(categories) do
		table.insert(lines, category)
		for _, line in ipairs(byCategory[category]) do
			table.insert(lines, line)
		end
	end
	ui.Print(table.concat(lines, "\n"), "info")
end

function localHandlers.search(args)
	local needle = table.concat(args, " "):lower()
	if needle == "" then
		return ui.Print("Usage: search <text>", "error")
	end
	local lines = {}
	for _, def in ipairs(defs) do
		local hay = (def.name .. " " .. table.concat(def.aliases or {}, " ") .. " " .. def.description):lower()
		if hay:find(needle, 1, true) then
			table.insert(lines, ("%s - %s"):format(def.usage, def.description))
		end
	end
	ui.Print(#lines > 0 and table.concat(lines, "\n") or "Nothing matches.", "info")
end

function localHandlers.settings()
	ui.Actions.OpenTab("Settings")
end

function localHandlers.theme(args)
	if not args[1] then
		return ui.Print("Themes: dark, midnight, light.", "info")
	end
	local name = args[1]:lower()
	if name ~= "dark" and name ~= "midnight" and name ~= "light" then
		return ui.Print("Unknown theme. Use dark, midnight or light.", "error")
	end
	ui.Actions.SetPref("theme", name)
	ui.Print("Theme set to " .. name .. ".", "success")
end

function localHandlers.guiscale(args)
	if not args[1] then
		return ui.Print("Usage: guiscale <0.7 to 1.6>", "info")
	end
	local n = tonumber(args[1])
	if not n or n < 0.7 or n > 1.6 then
		return ui.Print("Scale must be a number from 0.7 to 1.6.", "error")
	end
	ui.Actions.SetPref("scale", n)
	ui.Print("Interface scale set to " .. n .. ".", "success")
end

function localHandlers.history()
	if #CC.History == 0 then
		return ui.Print("History is empty.", "info")
	end
	local lines = {}
	for i = math.max(1, #CC.History - 19), #CC.History do
		table.insert(lines, ("%d. %s"):format(i, CC.History[i]))
	end
	ui.Print(table.concat(lines, "\n"), "info")
end

function localHandlers.clearhistory()
	table.clear(CC.History)
	ui.Print("History cleared.", "success")
end

function CC.Execute(rawLine)
	local line = rawLine:match("^%s*(.-)%s*$")
	if line == "" then
		return
	end
	if #line > Constants.MaxCommandLength then
		return ui.Print("That command is too long.", "error")
	end
	if CC.History[#CC.History] ~= line then
		table.insert(CC.History, line)
		while #CC.History > MAX_HISTORY do
			table.remove(CC.History, 1)
		end
	end
	ui.Print("> " .. line, "echo")

	local tokens = {}
	for token in line:gsub("^[:;]", ""):gmatch("%S+") do
		table.insert(tokens, token)
	end
	local def = tokens[1] and byName[tokens[1]:lower()]
	if def and def.clientOnly then
		local handler = localHandlers[def.name]
		if handler then
			local args = { table.unpack(tokens, 2) }
			local ok, err = pcall(handler, args)
			if not ok then
				ui.Print("Command failed.", "error")
				warn("[Fxield] " .. tostring(err))
			end
		end
		return
	end
	sendToServer(line, nil)
end

function CC.Init(commandDefs, remotesTable)
	defs = commandDefs
	remotes = remotesTable
	for _, def in ipairs(defs) do
		byName[def.name] = def
		for _, alias in ipairs(def.aliases or {}) do
			byName[alias] = def
		end
	end
	if responseConnection then
		responseConnection:Disconnect()
	end
	responseConnection = remotes.CommandResponse.OnClientEvent:Connect(onResponse)
end

return CC
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/LiveEditorController", "ModuleScript", [=[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared"):WaitForChild("ConfigSchema"))
local Theme = require(script.Parent.ThemeController)
local UIKit = require(script.Parent.UIKit)

local LiveEditor = {}

local function fmt(v)
	if type(v) == "number" then
		return tostring(tonumber(string.format("%.4f", v)))
	end
	return tostring(v)
end

function LiveEditor.Mount(page, deps)
	local remotes, notifications, confirm = deps.Remotes, deps.Notifications, deps.Confirm
	local schema = deps.session.schema or {}
	local current = table.clone(deps.session.config or {})
	local draft = {}
	local invalid = {}
	local rows = {}
	local busy = false
	local buttons = {}

	local top = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 4), Parent = page })
	local status = UIKit.New("TextLabel", {
		BackgroundTransparency = 1, Text = "No pending changes.", Font = Enum.Font.Gotham, TextBase = 13,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 1, 0), Parent = top,
	})
	Theme.Bind(status, "TextColor3", "subtext")

	local list = UIKit.New("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 42),
		Size = UDim2.new(1, -16, 1, -42 - 58), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4, Parent = page,
	})
	UIKit.List(list, 8)

	local panel = UIKit.New("Frame", { Visible = false, Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -42 - 58), ZIndex = 5, Parent = page })
	Theme.Bind(panel, "BackgroundColor3", "panel")
	UIKit.Corner(panel, 8)
	UIKit.Stroke(panel, "stroke", 1)
	local panelTitle = UIKit.New("TextLabel", {
		BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextBase = 15, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -90, 0, 36), ZIndex = 6, Parent = panel,
	})
	Theme.Bind(panelTitle, "TextColor3", "text")
	local panelBody = UIKit.New("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 38), Size = UDim2.new(1, -16, 1, -46),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 6, Parent = panel,
	})
	UIKit.List(panelBody, 4)
	local closePanel = UIKit.Button(panel, "Close", function()
		panel.Visible = false
	end, "default", { Size = UDim2.fromOffset(70, 28), Position = UDim2.new(1, -78, 0, 4), ZIndex = 6 })

	local function showPanel(title, lines)
		panelTitle.Text = title
		for _, child in ipairs(panelBody:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for _, entry in ipairs(lines) do
			local label = UIKit.Label(panelBody, entry.text, 13, entry.role or "text", { ZIndex = 7 })
			label.Font = Enum.Font.Code
		end
		panel.Visible = true
	end

	local function updateStatus()
		local n, bad = 0, 0
		for _ in pairs(draft) do
			n += 1
		end
		for _ in pairs(invalid) do
			bad += 1
		end
		if bad > 0 then
			status.Text = ("%d change(s) pending, %d invalid."):format(n, bad)
		elseif n > 0 then
			status.Text = ("%d change(s) pending. Preview or Apply."):format(n)
		else
			status.Text = "No pending changes."
		end
	end

	local function setBusy(state)
		busy = state
		for _, b in ipairs(buttons) do
			b.Active = not state
			b.AutoButtonColor = not state
		end
	end

	local function call(action, payload)
		if busy then
			return nil
		end
		setBusy(true)
		local ok, res = pcall(function()
			return remotes.ConfigRequest:InvokeServer(action, payload)
		end)
		setBusy(false)
		if not ok or type(res) ~= "table" then
			notifications.Show("error", "The request failed. Try again.")
			return nil
		end
		return res
	end

	local function buildRow(field)
		local row, content, errorLabel = UIKit.Row(list, field.label, field.description)
		local stroke = UIKit.Stroke(row, "accent", 1.5)
		stroke.Enabled = false
		local control

		local function edited(v)
			local ok, parsed = Schema.Validate(field, v)
			if ok then
				invalid[field.key] = nil
				draft[field.key] = (parsed ~= current[field.key]) and parsed or nil
				errorLabel.Visible = false
			else
				invalid[field.key] = true
				draft[field.key] = v
				errorLabel.Text = parsed
				errorLabel.Visible = true
			end
			stroke.Enabled = draft[field.key] ~= nil
			updateStatus()
		end

		local value = current[field.key]
		if value == nil then
			value = field.default
		end
		local t = field.type
		if t == "boolean" then
			control = UIKit.Toggle(content, value, edited)
		elseif t == "number" and field.min and field.max and field.step and (field.max - field.min) / field.step <= 1000 then
			control = UIKit.Slider(content, field.min, field.max, field.step, value, edited, fmt)
		elseif t == "enum" then
			control = UIKit.Dropdown(content, field.options, value, edited)
		else
			local box = UIKit.TextInput(content, field.label, fmt(value), function(text)
				edited(text)
			end)
			control = {
				Set = function(v)
					box.Text = fmt(v)
				end,
			}
		end

		rows[field.key] = {
			set = function(v)
				control.Set(v)
				draft[field.key] = nil
				invalid[field.key] = nil
				errorLabel.Visible = false
				stroke.Enabled = false
			end,
			setError = function(message)
				errorLabel.Text = message or ""
				errorLabel.Visible = message ~= nil
			end,
		}
	end

	local seen = {}
	for _, field in ipairs(schema) do
		if not seen[field.category] then
			seen[field.category] = true
			UIKit.Label(list, string.upper(field.category), 12, "accent", { Font = Enum.Font.GothamBold })
		end
		buildRow(field)
	end

	local function refreshAll()
		table.clear(draft)
		table.clear(invalid)
		for key, row in pairs(rows) do
			row.set(current[key])
		end
		updateStatus()
	end

	local function showResultErrors(results)
		for _, r in ipairs(results or {}) do
			if not r.ok and rows[r.key] then
				rows[r.key].setError(r.error)
			end
		end
	end

	local function resultLines(results)
		local lines = {}
		for _, r in ipairs(results or {}) do
			if not r.ok then
				table.insert(lines, { text = ("%s: %s"):format(r.key, tostring(r.error)), role = "danger" })
			elseif r.unchanged then
				table.insert(lines, { text = ("%s: unchanged"):format(r.key), role = "subtext" })
			else
				table.insert(lines, { text = ("%s: %s -> %s"):format(r.key, fmt(r.old), fmt(r.new)), role = "text" })
			end
		end
		return lines
	end

	local function guardDraft()
		if next(draft) == nil then
			status.Text = "No pending changes."
			return false
		end
		if next(invalid) ~= nil then
			notifications.Show("error", "Fix the invalid values first.")
			return false
		end
		return true
	end

	local function adopt(res)
		if type(res.config) == "table" then
			current = res.config
		end
		refreshAll()
	end

	local function onPreview()
		if not guardDraft() then
			return
		end
		local res = call("preview", { changes = draft })
		if not res then
			return
		end
		showResultErrors(res.results)
		showPanel(res.ok and "Preview" or "Preview (has errors)", resultLines(res.results))
	end

	local function onApply()
		if not guardDraft() then
			return
		end
		local res = call("apply", { changes = draft })
		if not res then
			return
		end
		if res.ok then
			local n = 0
			for _, r in ipairs(res.results or {}) do
				if not r.unchanged then
					n += 1
				end
			end
			adopt(res)
			notifications.Show("success", n > 0 and (n .. " setting(s) applied.") or "Nothing changed.")
		else
			showResultErrors(res.results)
			notifications.Show("error", res.error or "Some values were rejected by the server.")
		end
	end

	local function onUndo()
		local res = call("undo")
		if not res then
			return
		end
		if res.ok then
			adopt(res)
			notifications.Show("success", "Last change undone.")
		else
			notifications.Show("error", res.error or "Nothing to undo.")
		end
	end

	local function onReset()
		confirm("Reset ALL settings to their defaults?", function()
			local res = call("reset", { confirm = true })
			if not res then
				return
			end
			if res.ok then
				adopt(res)
				notifications.Show("success", "All settings reset to defaults.")
			else
				notifications.Show("error", res.error or "Reset failed.")
			end
		end)
	end

	local function onHistory()
		local res = call("history")
		if not res or not res.ok then
			return
		end
		local lines = {}
		for _, e in ipairs(res.history or {}) do
			table.insert(lines, {
				text = ("#%d  %s UTC  %s  %s%s"):format(e.id, os.date("!%Y-%m-%d %H:%M:%S", e.time), e.actor, e.kind, e.undone and " (undone)" or ""),
				role = "accent",
			})
			for key, change in pairs(e.changes) do
				table.insert(lines, { text = ("   %s: %s -> %s"):format(key, fmt(change.old), fmt(change.new)), role = "text" })
			end
		end
		if #lines == 0 then
			table.insert(lines, { text = "No changes recorded yet.", role = "subtext" })
		end
		showPanel("Change history", lines)
	end

	table.insert(buttons, UIKit.Button(top, "History", onHistory, "default", {
		Size = UDim2.fromOffset(100, 28), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
	}))

	local bar = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 44), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -6), Parent = page })
	UIKit.List(bar, 6, true)
	local function barButton(text, cb, style)
		local b = UIKit.Button(bar, text, cb, style, { Size = UDim2.new(0.2, -5, 1, 0) })
		table.insert(buttons, b)
	end
	barButton("Preview", onPreview)
	barButton("Apply", onApply, "primary")
	barButton("Cancel", function()
		panel.Visible = false
		refreshAll()
	end)
	barButton("Undo", onUndo)
	barButton("Reset", onReset, "danger")

	local updateConnection = remotes.ConfigUpdate.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" or type(data.values) ~= "table" then
			return
		end
		for key, value in pairs(data.values) do
			if rows[key] then
				current[key] = value
				if draft[key] == nil then
					rows[key].set(value)
				elseif draft[key] == value then
					draft[key] = nil
					rows[key].set(value)
				end
			end
		end
		updateStatus()
	end)

	updateStatus()

	return function()
		updateConnection:Disconnect()
	end
end

return LiveEditor
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/NotificationController", "ModuleScript", [=[
local Players = game:GetService("Players")

local Theme = require(script.Parent.ThemeController)
local UIKit = require(script.Parent.UIKit)

local Notifications = {}

local MAX_TOASTS = 5
local container
local toasts = {}
local actionHandler
local attached = false

local kindRole = { info = "accent", success = "success", warn = "warn", error = "danger", announce = "accent" }

local function remove(toast)
	local i = table.find(toasts, toast)
	if i then
		table.remove(toasts, i)
	end
	if not toast.Parent then
		return
	end
	UIKit.Tween(toast, { GroupTransparency = 1 }, 0.2)
	task.delay(UIKit.ReducedMotion and 0 or 0.22, function()
		toast:Destroy()
	end)
end

function Notifications.Show(kind, text, title, duration)
	if not container then
		return
	end
	kind = kindRole[kind] and kind or "info"
	if #toasts >= MAX_TOASTS then
		remove(toasts[1])
	end

	local toast = UIKit.New("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, GroupTransparency = 1, Parent = container,
	})
	Theme.Bind(toast, "BackgroundColor3", "panel")
	UIKit.Corner(toast, 10)
	UIKit.Stroke(toast, kindRole[kind], 1.5)
	local inner = UIKit.New("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = toast,
	})
	UIKit.Padding(inner, 12)
	UIKit.List(inner, 3)
	if title and title ~= "" then
		UIKit.Label(inner, title, 14, kindRole[kind], { Font = Enum.Font.GothamBold, LayoutOrder = 1 })
	end
	UIKit.Label(inner, text, 13, "text", { LayoutOrder = 2 })

	local tap = UIKit.New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = toast })
	tap.Activated:Connect(function()
		remove(toast)
	end)

	table.insert(toasts, toast)
	UIKit.Tween(toast, { GroupTransparency = 0 }, 0.2)
	task.delay(duration or 5, function()
		if toast.Parent then
			remove(toast)
		end
	end)
end

function Notifications.SetActionHandler(handler)
	actionHandler = handler
end

function Notifications.Init()
	local gui = UIKit.New("ScreenGui", {
		Name = "FxieldNotifications", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 200,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	container = UIKit.New("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 56),
		Size = UDim2.new(0, 300, 1, -80), Parent = gui,
	})
	UIKit.List(container, 8)
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(300, math.huge), Parent = container })
end

function Notifications.Attach(remotes)
	if attached then
		return
	end
	attached = true
	remotes.Notification.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" or type(data.text) ~= "string" then
			return
		end
		Notifications.Show(data.kind, data.text, type(data.title) == "string" and data.title or nil)
		if data.action == "signout" and actionHandler then
			actionHandler("signout")
		end
	end)
end

return Notifications
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/StartupController", "ModuleScript", [=[
local Players = game:GetService("Players")

local Theme = require(script.Parent.ThemeController)
local UIKit = require(script.Parent.UIKit)

local Startup = {}

local gui
local launcher
local loading = {}
local keyScreen = {}
local countdownToken = 0

local function buildRoot()
	gui = UIKit.New("ScreenGui", {
		Name = "FxieldStartup",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 150,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
end

local function makeOverlay(name)
	local overlay = UIKit.New("CanvasGroup", {
		Name = name,
		Visible = false,
		GroupTransparency = 1,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	local blocker = UIKit.New("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = overlay,
	})
	local card = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = overlay,
	})
	Theme.Bind(card, "BackgroundColor3", "panel")
	UIKit.Corner(card, 14)
	UIKit.Stroke(card, "stroke", 1)
	UIKit.Padding(card, 20)
	UIKit.List(card, 12)
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(380, math.huge), Parent = card })
	return overlay, card, blocker
end

local function fadeIn(overlay)
	overlay.Visible = true
	UIKit.Tween(overlay, { GroupTransparency = 0 }, 0.2)
end

local function fadeOut(overlay)
	UIKit.Tween(overlay, { GroupTransparency = 1 }, 0.2)
	task.delay(UIKit.ReducedMotion and 0 or 0.22, function()
		if overlay.Parent and overlay.GroupTransparency >= 0.99 then
			overlay.Visible = false
		end
	end)
end

local function wordmark(parent, text)
	local label = UIKit.New("TextLabel", {
		BackgroundTransparency = 1,
		RichText = true,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextBase = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = 1,
		Parent = parent,
	})
	Theme.Bind(label, "TextColor3", "text")
	label.Text = ('<font color="#%s">%s</font>%s'):format(Theme.Color("accent"):ToHex(), text:sub(1, 1), text:sub(2))
	return label
end

local function buildLauncher()
	launcher = UIKit.New("TextButton", {
		Name = "Launcher",
		Text = "F",
		Font = Enum.Font.GothamBold,
		TextBase = 18,
		Visible = false,
		Size = UDim2.fromOffset(46, 46),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Parent = gui,
	})
	Theme.Bind(launcher, "BackgroundColor3", "accent")
	Theme.Bind(launcher, "TextColor3", "accentText")
	UIKit.Corner(launcher, 23)
end

local function buildLoading()
	local overlay, card = makeOverlay("Loading")
	wordmark(card, "Fxield")
	UIKit.Label(card, "Administration and utility", 13, "subtext", { LayoutOrder = 2 })

	local track = UIKit.New("Frame", { Size = UDim2.new(1, 0, 0, 6), LayoutOrder = 3, Parent = card })
	Theme.Bind(track, "BackgroundColor3", "panel3")
	UIKit.Corner(track, 3)
	local fill = UIKit.New("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = track })
	Theme.Bind(fill, "BackgroundColor3", "accent")
	UIKit.Corner(fill, 3)

	local step = UIKit.Label(card, "Starting", 13, "text", { LayoutOrder = 4 })
	local message = UIKit.Label(card, "", 13, "danger", { LayoutOrder = 5, Visible = false })

	local buttons = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 6, Visible = false, Parent = card })
	UIKit.List(buttons, 8, true)
	local retryButton = UIKit.Button(buttons, "Retry", nil, "primary", { Size = UDim2.new(0.5, -4, 1, 0) })
	local closeButton = UIKit.Button(buttons, "Close", nil, "default", { Size = UDim2.new(0.5, -4, 1, 0) })

	loading.overlay, loading.fill, loading.step, loading.message = overlay, fill, step, message
	loading.buttons, loading.retry, loading.close = buttons, retryButton, closeButton
	loading.onRetry, loading.onClose = nil, nil
	retryButton.Activated:Connect(function()
		if loading.onRetry then
			loading.onRetry()
		end
	end)
	closeButton.Activated:Connect(function()
		if loading.onClose then
			loading.onClose()
		end
	end)
end

local function buildKeyScreen()
	local overlay, card = makeOverlay("KeyScreen")
	wordmark(card, "Fxield")
	UIKit.Label(card, "Access key required", 16, "text", { Font = Enum.Font.GothamMedium, LayoutOrder = 2 })
	UIKit.Label(card, "Enter your access key to open Fxield. The key is checked by the server and is never stored in this script.", 13, "subtext", { LayoutOrder = 3 })

	local inputHolder = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 4, Parent = card })
	local box = UIKit.TextInput(inputHolder, "Access key", "", nil)
	box.Size = UDim2.new(1, 0, 1, 0)
	box.Font = Enum.Font.Code

	local message = UIKit.Label(card, "", 13, "subtext", { LayoutOrder = 5, Visible = false })

	local buttons = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 6, Parent = card })
	UIKit.List(buttons, 8, true)
	local submitButton = UIKit.Button(buttons, "Unlock", nil, "primary", { Size = UDim2.new(0.6, -4, 1, 0) })
	local closeButton = UIKit.Button(buttons, "Cancel", nil, "default", { Size = UDim2.new(0.4, -4, 1, 0) })

	keyScreen.overlay, keyScreen.box, keyScreen.message = overlay, box, message
	keyScreen.submit, keyScreen.close = submitButton, closeButton
	keyScreen.handlers = nil
	keyScreen.busy = false
	keyScreen.locked = false
end

local function setMessage(role, text)
	keyScreen.message.Visible = text ~= ""
	keyScreen.message.Text = text
	Theme.Bind(keyScreen.message, "TextColor3", role)
end

local function setInputEnabled(enabled)
	keyScreen.box.TextEditable = enabled
	keyScreen.submit.Active = enabled
	keyScreen.submit.AutoButtonColor = enabled
	keyScreen.submit.TextTransparency = enabled and 0 or 0.5
end

local function startCountdown(seconds)
	countdownToken += 1
	local token = countdownToken
	keyScreen.locked = true
	setInputEnabled(false)
	local untilTime = os.clock() + seconds
	task.spawn(function()
		while token == countdownToken and keyScreen.overlay.Visible do
			local remaining = math.ceil(untilTime - os.clock())
			if remaining <= 0 then
				break
			end
			local text
			if remaining >= 60 then
				text = ("Access is restricted. Try again in %d minute(s)."):format(math.ceil(remaining / 60))
			else
				text = ("Access is restricted. Try again in %d second(s)."):format(remaining)
			end
			setMessage("danger", text)
			task.wait(1)
		end
		if token == countdownToken then
			keyScreen.locked = false
			setInputEnabled(true)
			setMessage("subtext", "You can try again now.")
		end
	end)
end

local function submitKey()
	if keyScreen.busy or keyScreen.locked or not keyScreen.handlers then
		return
	end
	local text = keyScreen.box.Text
	if text == "" then
		setMessage("warn", "Enter your access key first.")
		return
	end
	keyScreen.busy = true
	setInputEnabled(false)
	setMessage("subtext", "Checking key...")
	local result = keyScreen.handlers.submit(text)
	keyScreen.box.Text = ""
	keyScreen.busy = false
	if not keyScreen.overlay.Visible then
		return
	end
	if type(result) ~= "table" then
		setInputEnabled(true)
		setMessage("danger", "Could not reach the server. Check your connection and try again.")
		return
	end
	if result.ok == true then
		setMessage("success", "Access granted.")
		task.delay(0.35, function()
			if keyScreen.handlers then
				keyScreen.handlers.onSuccess()
			end
		end)
		return
	end
	if result.code == "restricted" then
		startCountdown(tonumber(result.retryAfter) or 60)
		return
	end
	setInputEnabled(true)
	local role = (result.code == "rate_limited") and "warn" or "danger"
	setMessage(role, tostring(result.message or "Something went wrong. Please try again."))
end

function Startup.Init()
	buildRoot()
	buildLauncher()
	buildLoading()
	buildKeyScreen()
	keyScreen.submit.Activated:Connect(submitKey)
	keyScreen.box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submitKey()
		end
	end)
	keyScreen.close.Activated:Connect(function()
		if keyScreen.handlers then
			keyScreen.handlers.onClose()
		end
	end)
end

function Startup.SetLauncher(visible, onActivate)
	launcher.Visible = visible
	if onActivate and not launcher:GetAttribute("Bound") then
		launcher:SetAttribute("Bound", true)
		launcher.Activated:Connect(onActivate)
	end
end

function Startup.ShowLoading()
	loading.message.Visible = false
	loading.buttons.Visible = false
	loading.onRetry, loading.onClose = nil, nil
	Startup.SetProgress(0.05, "Starting")
	fadeIn(loading.overlay)
end

function Startup.SetProgress(fraction, text)
	loading.step.Text = text
	Theme.Bind(loading.step, "TextColor3", "text")
	UIKit.Tween(loading.fill, { Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0) }, 0.25)
end

function Startup.ShowLoadingError(message, onRetry, onClose)
	loading.step.Text = "Could not finish loading"
	loading.message.Text = message
	loading.message.Visible = true
	loading.buttons.Visible = true
	loading.onRetry, loading.onClose = onRetry, onClose
end

function Startup.HideLoading()
	fadeOut(loading.overlay)
end

function Startup.ShowKeyScreen(status, handlers)
	keyScreen.handlers = handlers
	keyScreen.busy = false
	keyScreen.locked = false
	keyScreen.box.Text = ""
	countdownToken += 1
	setInputEnabled(true)
	setMessage("subtext", "")
	fadeIn(keyScreen.overlay)
	if status and status.state == "restricted" then
		startCountdown(tonumber(status.retryAfter) or 60)
	elseif not UIKit.ReducedMotion then
		task.defer(function()
			keyScreen.box:CaptureFocus()
		end)
	end
end

function Startup.HideKeyScreen()
	countdownToken += 1
	keyScreen.handlers = nil
	fadeOut(keyScreen.overlay)
end

return Startup
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/ThemeController", "ModuleScript", [=[
local Theme = {}

local palettes = {
	dark = {
		bg = Color3.fromRGB(16, 17, 22), panel = Color3.fromRGB(24, 26, 33), panel2 = Color3.fromRGB(32, 35, 44),
		panel3 = Color3.fromRGB(44, 48, 60), stroke = Color3.fromRGB(58, 63, 78),
		text = Color3.fromRGB(232, 235, 242), subtext = Color3.fromRGB(150, 157, 173),
		danger = Color3.fromRGB(232, 84, 96), success = Color3.fromRGB(80, 200, 120), warn = Color3.fromRGB(240, 180, 70),
	},
	midnight = {
		bg = Color3.fromRGB(6, 8, 16), panel = Color3.fromRGB(11, 15, 28), panel2 = Color3.fromRGB(17, 23, 42),
		panel3 = Color3.fromRGB(27, 36, 64), stroke = Color3.fromRGB(40, 52, 88),
		text = Color3.fromRGB(225, 232, 250), subtext = Color3.fromRGB(130, 145, 185),
		danger = Color3.fromRGB(240, 90, 105), success = Color3.fromRGB(90, 210, 130), warn = Color3.fromRGB(245, 190, 80),
	},
	light = {
		bg = Color3.fromRGB(240, 242, 247), panel = Color3.fromRGB(250, 251, 253), panel2 = Color3.fromRGB(238, 241, 246),
		panel3 = Color3.fromRGB(224, 228, 237), stroke = Color3.fromRGB(200, 206, 220),
		text = Color3.fromRGB(24, 27, 36), subtext = Color3.fromRGB(95, 103, 122),
		danger = Color3.fromRGB(200, 50, 65), success = Color3.fromRGB(30, 150, 80), warn = Color3.fromRGB(200, 130, 20),
	},
}

Theme.Names = { "dark", "midnight", "light" }

local currentName = "dark"
local accent = Color3.fromHex("8B5CF6")
local highContrast = false
local bindings = setmetatable({}, { __mode = "k" })

local function luminance(c)
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

function Theme.Color(role)
	if role == "accent" then
		return accent
	elseif role == "accentText" then
		return luminance(accent) > 0.6 and Color3.fromRGB(16, 17, 22) or Color3.new(1, 1, 1)
	elseif role == "onDanger" then
		return Color3.new(1, 1, 1)
	end
	local palette = palettes[currentName]
	if highContrast then
		local light = currentName == "light"
		if role == "text" then
			return light and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		elseif role == "subtext" then
			return light and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(225, 225, 225)
		elseif role == "stroke" then
			return light and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		end
	end
	return palette[role] or palette.text
end

function Theme.Apply()
	for inst, props in pairs(bindings) do
		for prop, role in pairs(props) do
			inst[prop] = Theme.Color(role)
		end
	end
end

function Theme.Bind(inst, prop, role)
	local props = bindings[inst]
	if not props then
		props = {}
		bindings[inst] = props
	end
	props[prop] = role
	inst[prop] = Theme.Color(role)
end

function Theme.GetName()
	return currentName
end

function Theme.SetName(name)
	if palettes[name] then
		currentName = name
		Theme.Apply()
	end
end

function Theme.SetAccent(hex)
	local ok, color = pcall(Color3.fromHex, hex)
	if ok then
		accent = color
		Theme.Apply()
	end
end

function Theme.SetHighContrast(enabled)
	highContrast = enabled == true
	Theme.Apply()
end

return Theme
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/UIController", "ModuleScript", [=[
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Schema = require(Shared:WaitForChild("ConfigSchema"))
local PrefsSchema = require(Shared:WaitForChild("PrefsSchema"))

local Theme = require(script.Parent.ThemeController)
local UIKit = require(script.Parent.UIKit)
local CommandController = require(script.Parent.CommandController)
local LiveEditor = require(script.Parent.LiveEditorController)
local Notifications = require(script.Parent.NotificationController)

local UIController = {}

local TITLE_H, TAB_H = 40, 38
local MAX_LINES = 200
local ACCENTS = { "#8B5CF6", "#4F8CFF", "#EC4899", "#F59E0B", "#10B981", "#EF4444", "#06B6D4", "#F97316" }

local gui, window, scaleObj, titleLabel, consoleBox, output
local pages, tabButtons, controls = {}, {}, {}
local prefs, remotes
local designSize = Vector2.new(640, 420)
local winPos = Vector2.new(24, 64)
local state = { minimized = false, maximized = false }
local keybindName = "Semicolon"
local capturingKey = false
local keybindButton
local histIdx = 0
local lines = 0
local inputConnection
local liveEditorCleanup

local function layoutWindow()
	local vp = gui.AbsoluteSize
	if vp.X <= 0 or vp.Y <= 0 then
		return
	end
	local s = UIKit.Scale
	if state.maximized then
		window.Size = UDim2.fromOffset(vp.X / s, vp.Y / s)
		window.Position = UDim2.fromScale(0, 0)
		return
	end
	designSize = Vector2.new(
		math.clamp(designSize.X, 300, math.max(300, vp.X / s - 12)),
		math.clamp(designSize.Y, 240, math.max(240, vp.Y / s - 12))
	)
	local h = state.minimized and TITLE_H or designSize.Y
	window.Size = UDim2.fromOffset(designSize.X, h)
	winPos = Vector2.new(
		math.clamp(winPos.X, 0, math.max(0, vp.X - designSize.X * s)),
		math.clamp(winPos.Y, 0, math.max(0, vp.Y - h * s))
	)
	window.Position = UDim2.fromScale(winPos.X / vp.X, winPos.Y / vp.Y)
end

local kindRole = { echo = "subtext", info = "text", success = "success", error = "danger", warn = "warn" }

function UIController.Print(text, kind)
	kind = kindRole[kind] and kind or "info"
	if output then
		lines += 1
		local label = UIKit.Label(output, tostring(text), 13, kindRole[kind], { LayoutOrder = lines })
		label.Font = Enum.Font.Code
		if lines > MAX_LINES then
			local oldest, order = nil, math.huge
			for _, child in ipairs(output:GetChildren()) do
				if child:IsA("TextLabel") and child.LayoutOrder < order then
					oldest, order = child, child.LayoutOrder
				end
			end
			if oldest then
				oldest:Destroy()
				lines -= 1
			end
		end
		task.defer(function()
			output.CanvasPosition = Vector2.new(0, output.AbsoluteCanvasSize.Y)
		end)
	end
	if (kind == "success" or kind == "error") and not (window and window.Visible and not state.minimized) then
		Notifications.Show(kind, tostring(text))
	end
end

local pendingPrefs, saveScheduled = {}, false

local function queueSave(key, value)
	pendingPrefs[key] = value
	if saveScheduled then
		return
	end
	saveScheduled = true
	task.delay(1, function()
		saveScheduled = false
		local payload = pendingPrefs
		pendingPrefs = {}
		task.spawn(function()
			pcall(function()
				remotes.Session:InvokeServer("setPrefs", payload)
			end)
		end)
	end)
end

local function applyPref(key, value, save)
	if key == "theme" then
		Theme.SetName(value)
	elseif key == "accent" then
		Theme.SetAccent(value)
	elseif key == "scale" then
		UIKit.Scale = value
		scaleObj.Scale = value
		layoutWindow()
	elseif key == "textScale" then
		UIKit.SetTextScale(value)
	elseif key == "reducedMotion" then
		UIKit.ReducedMotion = value
	elseif key == "highContrast" then
		Theme.SetHighContrast(value)
	elseif key == "keybind" then
		keybindName = value
		if keybindButton then
			keybindButton.Text = "Toggle key: " .. value .. " (tap to change)"
		end
	end
	prefs[key] = value
	if controls[key] and controls[key].Set then
		controls[key].Set(value)
	end
	if save then
		queueSave(key, value)
	end
end

function UIController.Confirm(message, onYes)
	local overlay = UIKit.Overlay
	local blocker = UIKit.New("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1), ZIndex = 100, Parent = overlay,
	})
	local box = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 101, Parent = blocker,
	})
	Theme.Bind(box, "BackgroundColor3", "panel")
	UIKit.Corner(box, 12)
	UIKit.Stroke(box, "stroke", 1)
	UIKit.Padding(box, 14)
	UIKit.List(box, 12)
	UIKit.New("UIScale", { Scale = UIKit.Scale, Parent = box })
	UIKit.Label(box, "Are you sure?", 16, "text", { Font = Enum.Font.GothamBold, LayoutOrder = 1, ZIndex = 102 })
	UIKit.Label(box, message, 13, "subtext", { LayoutOrder = 2, ZIndex = 102 })
	local row = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 3, ZIndex = 102, Parent = box })
	UIKit.List(row, 8, true)
	UIKit.Button(row, "Cancel", function()
		blocker:Destroy()
	end, "default", { Size = UDim2.new(0.5, -4, 1, 0), ZIndex = 102 })
	UIKit.Button(row, "Confirm", function()
		blocker:Destroy()
		onYes()
	end, "primary", { Size = UDim2.new(0.5, -4, 1, 0), ZIndex = 102 })
end

local function selectTab(name)
	for tabName, page in pairs(pages) do
		page.Visible = tabName == name
	end
	for tabName, entry in pairs(tabButtons) do
		Theme.Bind(entry.label, "TextColor3", tabName == name and "accent" or "subtext")
		entry.underline.Visible = tabName == name
	end
end

function UIController.OpenTab(name)
	window.Visible = true
	state.minimized = false
	layoutWindow()
	if pages[name] then
		selectTab(name)
	end
end

function UIController.Toggle()
	window.Visible = not window.Visible
	if window.Visible then
		state.minimized = false
		layoutWindow()
		if consoleBox and pages.Console.Visible and not UIS.TouchEnabled then
			task.defer(function()
				consoleBox:CaptureFocus()
			end)
		end
	end
end

function UIController.SetTitle(text)
	if titleLabel then
		titleLabel.Text = tostring(text)
	end
end

local function buildConsole(page)
	output = UIKit.New("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -64),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, Parent = page,
	})
	UIKit.List(output, 2)

	local bar = UIKit.New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 42), Parent = page })
	local inputHolder = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -88, 1, 0), Parent = bar })
	consoleBox = UIKit.TextInput(inputHolder, "Type a command (try: help)", "", function(text, enter)
		if enter and text ~= "" then
			histIdx = 0
			consoleBox.Text = ""
			CommandController.Execute(text)
			consoleBox:CaptureFocus()
		end
	end)
	consoleBox.Size = UDim2.new(1, 0, 1, 0)
	consoleBox.Font = Enum.Font.Code
	UIKit.Button(bar, "Send", function()
		local text = consoleBox.Text
		if text ~= "" then
			histIdx = 0
			consoleBox.Text = ""
			CommandController.Execute(text)
		end
	end, "primary", { Size = UDim2.new(0, 80, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0) })
end

local function buildCommands(page)
	local search = UIKit.TextInput(page, "Search commands...", "")
	search.Position = UDim2.fromOffset(8, 8)
	search.Size = UDim2.new(1, -16, 0, 36)

	local chips = UIKit.New("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 50), Size = UDim2.new(1, -16, 0, 34),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X, Parent = page,
	})
	UIKit.List(chips, 6, true)

	local list = UIKit.New("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 90), Size = UDim2.new(1, -16, 1, -98),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, Parent = page,
	})
	UIKit.List(list, 6)

	local category = "All"
	local chipButtons = {}

	local function rebuild()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local needle = search.Text:lower()
		for i, def in ipairs(CommandController.GetDefinitions()) do
			local hay = (def.name .. " " .. table.concat(def.aliases or {}, " ") .. " " .. def.description):lower()
			if (category == "All" or def.category == category) and (needle == "" or hay:find(needle, 1, true)) then
				local row = UIKit.New("TextButton", {
					Text = "", AutoButtonColor = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = i, Parent = list,
				})
				Theme.Bind(row, "BackgroundColor3", "panel2")
				UIKit.Corner(row, 8)
				UIKit.Padding(row, 10)
				UIKit.List(row, 2)
				UIKit.Label(row, def.name, 15, "accent", { Font = Enum.Font.GothamBold, LayoutOrder = 1, Active = false })
				UIKit.Label(row, def.usage, 12, "subtext", { Font = Enum.Font.Code, LayoutOrder = 2 })
				UIKit.Label(row, def.description .. (def.confirm and " (asks to confirm)" or ""), 13, "text", { LayoutOrder = 3 })
				UIKit.Label(row, "Requires " .. (Constants.LevelNames[def.level] or "?"), 11, "subtext", { LayoutOrder = 4 })
				row.Activated:Connect(function()
					selectTab("Console")
					consoleBox.Text = def.name .. " "
					consoleBox:CaptureFocus()
				end)
			end
		end
	end

	local categories, seen = { "All" }, {}
	for _, def in ipairs(CommandController.GetDefinitions()) do
		if not seen[def.category] then
			seen[def.category] = true
			table.insert(categories, def.category)
		end
	end
	local function styleChips()
		for name, chip in pairs(chipButtons) do
			Theme.Bind(chip, "BackgroundColor3", name == category and "accent" or "panel3")
			Theme.Bind(chip, "TextColor3", name == category and "accentText" or "text")
		end
	end
	for _, name in ipairs(categories) do
		local chip = UIKit.Button(chips, name, function()
			category = name
			styleChips()
			rebuild()
		end, "default", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X })
		UIKit.Padding(chip, 12, 0)
		chipButtons[name] = chip
	end
	styleChips()
	search:GetPropertyChangedSignal("Text"):Connect(rebuild)
	rebuild()
end

local function buildSettings(page)
	local list = UIKit.New("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, Parent = page,
	})
	UIKit.List(list, 8)

	local _, c1 = UIKit.Row(list, "Theme", "Dark, midnight or light.")
	controls.theme = UIKit.Dropdown(c1, Theme.Names, prefs.theme, function(v)
		applyPref("theme", v, true)
	end)

	local _, c2 = UIKit.Row(list, "Accent color", "Pick a preset or type a hex color.")
	local grid = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = c2 })
	UIKit.New("UIGridLayout", { CellSize = UDim2.fromOffset(38, 38), CellPadding = UDim2.fromOffset(6, 6), Parent = grid })
	for _, hex in ipairs(ACCENTS) do
		local swatch = UIKit.New("TextButton", { Text = "", BackgroundColor3 = Color3.fromHex(hex:sub(2)), Parent = grid })
		UIKit.Corner(swatch, 19)
		swatch.Activated:Connect(function()
			applyPref("accent", hex, true)
		end)
	end
	controls.accent = { Set = function() end }
	UIKit.TextInput(c2, "#RRGGBB", prefs.accent, function(text)
		local ok, value = Schema.Validate(PrefsSchema.ByKey.accent, text)
		if ok then
			applyPref("accent", value, true)
		else
			Notifications.Show("error", value)
		end
	end)

	local _, c3 = UIKit.Row(list, "Interface scale", "Makes the whole window larger or smaller.")
	controls.scale = UIKit.Slider(c3, 0.7, 1.6, 0.05, prefs.scale, function(v)
		applyPref("scale", v, true)
	end, function(v)
		return ("%.2fx"):format(v)
	end)

	local _, c4 = UIKit.Row(list, "Text size", "Accessibility: scale all text.")
	controls.textScale = UIKit.Slider(c4, 0.8, 1.5, 0.05, prefs.textScale, function(v)
		applyPref("textScale", v, true)
	end, function(v)
		return ("%.2fx"):format(v)
	end)

	local _, c5 = UIKit.Row(list, "Reduce motion", "Turns off animations.")
	controls.reducedMotion = UIKit.Toggle(c5, prefs.reducedMotion, function(v)
		applyPref("reducedMotion", v, true)
	end)

	local _, c6 = UIKit.Row(list, "High contrast", "Stronger text and border contrast.")
	controls.highContrast = UIKit.Toggle(c6, prefs.highContrast, function(v)
		applyPref("highContrast", v, true)
	end)

	local _, c7 = UIKit.Row(list, "Keybind", "Keyboard key that opens or hides Fxield.")
	keybindButton = UIKit.Button(c7, "Toggle key: " .. prefs.keybind .. " (tap to change)", function()
		capturingKey = true
		keybindButton.Text = "Press a key... (Escape cancels)"
	end, "default", { Size = UDim2.new(1, 0, 0, 36) })
	controls.keybind = { Set = function() end }

	local _, c8 = UIKit.Row(list, "Reset appearance", "Restore theme, accent, scale and accessibility defaults.")
	UIKit.Button(c8, "Reset", function()
		for _, field in ipairs(PrefsSchema.Fields) do
			if field.key ~= "keybind" then
				local default = field.default
				if field.key == "accent" then
					default = "#8B5CF6"
				end
				applyPref(field.key, default, true)
			end
		end
	end, "default")
end

function UIController.Init(deps)
	remotes = deps.Remotes
	local session = deps.session
	prefs = session.prefs

	UIKit.ReducedMotion = prefs.reducedMotion
	UIKit.Scale = prefs.scale
	UIKit.SetTextScale(prefs.textScale)
	Theme.SetHighContrast(prefs.highContrast)
	Theme.SetName(prefs.theme)
	Theme.SetAccent(prefs.accent)
	keybindName = prefs.keybind

	gui = UIKit.New("ScreenGui", {
		Name = "Fxield", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	UIKit.Overlay = UIKit.New("Frame", { Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = gui })

	window = UIKit.New("Frame", { Name = "Window", Visible = false, ClipsDescendants = true, Parent = gui })
	Theme.Bind(window, "BackgroundColor3", "panel")
	UIKit.Corner(window, 12)
	UIKit.Stroke(window, "stroke", 1)
	scaleObj = UIKit.New("UIScale", { Scale = UIKit.Scale, Parent = window })

	local titleBar = UIKit.New("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, TITLE_H), BorderSizePixel = 0, Parent = window })
	Theme.Bind(titleBar, "BackgroundColor3", "panel2")
	titleLabel = UIKit.New("TextLabel", {
		BackgroundTransparency = 1, Text = tostring(session.title), Font = Enum.Font.GothamBold, TextBase = 15,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -150, 1, 0), Parent = titleBar,
	})
	Theme.Bind(titleLabel, "TextColor3", "text")
	local levelTag = UIKit.New("TextLabel", {
		BackgroundTransparency = 1, Text = session.levelName, Font = Enum.Font.Gotham, TextBase = 11,
		TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -250, 0, 0), Size = UDim2.fromOffset(95, TITLE_H), Parent = titleBar,
	})
	Theme.Bind(levelTag, "TextColor3", "subtext")

	local function titleButton(symbol, index, callback)
		local b = UIKit.New("TextButton", {
			Text = symbol, Font = Enum.Font.GothamBold, TextBase = 15, AutoButtonColor = true,
			Size = UDim2.fromOffset(34, 28), AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8 - (index - 1) * 38, 0.5, 0), Parent = titleBar,
		})
		Theme.Bind(b, "BackgroundColor3", "panel3")
		Theme.Bind(b, "TextColor3", "text")
		UIKit.Corner(b, 6)
		b.Activated:Connect(callback)
		return b
	end
	titleButton("x", 1, function()
		window.Visible = false
	end)
	titleButton("[]", 2, function()
		state.maximized = not state.maximized
		layoutWindow()
	end)
	titleButton("-", 3, function()
		state.minimized = not state.minimized
		state.maximized = false
		for _, page in pairs(pages) do
			page.Parent.Visible = not state.minimized
		end
		layoutWindow()
	end)

	UIKit.Drag(titleBar, function()
		return winPos
	end, function(start, delta)
		if not state.maximized then
			winPos = start + delta
			layoutWindow()
		end
	end)

	local body = UIKit.New("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TITLE_H), Size = UDim2.new(1, 0, 1, -TITLE_H), Parent = window })
	local tabBar = UIKit.New("Frame", { Size = UDim2.new(1, 0, 0, TAB_H), BorderSizePixel = 0, Parent = body })
	Theme.Bind(tabBar, "BackgroundColor3", "panel")
	UIKit.List(tabBar, 0, true)
	local pageHolder = UIKit.New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TAB_H), Size = UDim2.new(1, 0, 1, -TAB_H), Parent = body })

	local tabNames = { "Console", "Commands" }
	if session.schema then
		table.insert(tabNames, "Live Editor")
	end
	table.insert(tabNames, "Settings")

	for _, name in ipairs(tabNames) do
		local button = UIKit.New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1 / #tabNames, 0, 1, 0), Parent = tabBar })
		local label = UIKit.New("TextLabel", {
			BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextBase = 13, Size = UDim2.fromScale(1, 1), Parent = button,
		})
		local underline = UIKit.New("Frame", { Size = UDim2.new(1, -16, 0, 3), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), BorderSizePixel = 0, Visible = false, Parent = button })
		Theme.Bind(underline, "BackgroundColor3", "accent")
		UIKit.Corner(underline, 2)
		tabButtons[name] = { label = label, underline = underline }
		button.Activated:Connect(function()
			selectTab(name)
		end)
		pages[name] = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = pageHolder })
	end

	local handle = UIKit.New("TextButton", {
		Text = "//", Font = Enum.Font.GothamBold, TextBase = 12, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(30, 30), ZIndex = 20, Parent = window,
	})
	Theme.Bind(handle, "TextColor3", "subtext")
	UIKit.Drag(handle, function()
		return designSize
	end, function(start, delta)
		if not state.maximized and not state.minimized then
			designSize = start + delta / UIKit.Scale
			layoutWindow()
		end
	end)

	buildConsole(pages.Console)
	buildCommands(pages.Commands)
	buildSettings(pages.Settings)
	if session.schema then
		liveEditorCleanup = LiveEditor.Mount(pages["Live Editor"], {
			session = session, Remotes = remotes, Notifications = Notifications, Confirm = UIController.Confirm,
		})
	end

	CommandController.SetUI({
		Print = UIController.Print,
		Confirm = UIController.Confirm,
		Actions = {
			OpenTab = UIController.OpenTab,
			SetPref = function(key, value)
				local field = PrefsSchema.ByKey[key]
				local ok, clean = Schema.Validate(field, value)
				if ok then
					applyPref(key, clean, true)
				end
			end,
		},
	})


	inputConnection = UIS.InputBegan:Connect(function(input)
		if consoleBox and consoleBox:IsFocused() then
			local history = CommandController.History
			if input.KeyCode == Enum.KeyCode.Up and #history > 0 then
				histIdx = math.min(histIdx + 1, #history)
				consoleBox.Text = history[#history - histIdx + 1]
				consoleBox.CursorPosition = #consoleBox.Text + 1
			elseif input.KeyCode == Enum.KeyCode.Down then
				histIdx = math.max(histIdx - 1, 0)
				consoleBox.Text = histIdx == 0 and "" or history[#history - histIdx + 1]
				consoleBox.CursorPosition = #consoleBox.Text + 1
			elseif input.KeyCode == Enum.KeyCode.Tab then
				local prefix = consoleBox.Text:lower()
				if prefix ~= "" and not prefix:find("%s") then
					local matches = {}
					for _, name in ipairs(CommandController.Names()) do
						if name:sub(1, #prefix) == prefix then
							table.insert(matches, name)
						end
					end
					if #matches == 1 then
						consoleBox.Text = matches[1] .. " "
						consoleBox.CursorPosition = #consoleBox.Text + 1
					elseif #matches > 1 then
						UIController.Print(table.concat(matches, "  "), "info")
					end
				end
			end
			return
		end
		if capturingKey and input.UserInputType == Enum.UserInputType.Keyboard then
			capturingKey = false
			if input.KeyCode == Enum.KeyCode.Escape then
				keybindButton.Text = "Toggle key: " .. keybindName .. " (tap to change)"
			else
				applyPref("keybind", input.KeyCode.Name, true)
			end
			return
		end
	end)

	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutWindow)

	local vp = gui.AbsoluteSize
	if UIS.TouchEnabled and vp.X > 0 and vp.X < 900 then
		designSize = Vector2.new(vp.X / UIKit.Scale - 20, math.min(vp.Y / UIKit.Scale - 70, 420))
		winPos = Vector2.new(10, 44)
	elseif vp.X > 0 then
		winPos = Vector2.new(math.max(0, (vp.X - designSize.X * UIKit.Scale) / 2), math.max(0, (vp.Y - designSize.Y * UIKit.Scale) / 2))
	end
	layoutWindow()
	selectTab("Console")
	UIController.Print(("%s %s - signed in as %s. Type 'help' to begin."):format(Constants.Name, session.version, session.levelName), "info")
end

function UIController.IsBuilt()
	return gui ~= nil
end

function UIController.GetKeybind()
	return keybindName
end

function UIController.IsCapturingKey()
	return capturingKey
end

function UIController.Show()
	if not window then
		return
	end
	window.Visible = true
	state.minimized = false
	layoutWindow()
end

function UIController.Hide()
	if window then
		window.Visible = false
	end
end

function UIController.Destroy()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	if liveEditorCleanup then
		liveEditorCleanup()
		liveEditorCleanup = nil
	end
	if gui then
		gui:Destroy()
	end
	gui, window, scaleObj, titleLabel, consoleBox, output, keybindButton = nil, nil, nil, nil, nil, nil, nil
	table.clear(pages)
	table.clear(tabButtons)
	table.clear(controls)
	lines = 0
	state.minimized = false
	state.maximized = false
	capturingKey = false
	UIKit.Overlay = nil
end

return UIController
]=])

add("StarterPlayer/StarterPlayerScripts/FxieldClient/UIKit", "ModuleScript", [=[
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.ThemeController)

local UIKit = {}
UIKit.ReducedMotion = false
UIKit.Scale = 1
UIKit.Overlay = nil

local textScale = 1
local textRegistry = setmetatable({}, { __mode = "k" })

function UIKit.Tween(inst, goal, duration)
	if UIKit.ReducedMotion then
		for k, v in pairs(goal) do
			inst[k] = v
		end
		return
	end
	TweenService:Create(inst, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

function UIKit.Text(inst, baseSize)
	textRegistry[inst] = baseSize
	inst.TextSize = math.floor(baseSize * textScale + 0.5)
end

function UIKit.SetTextScale(scale)
	textScale = scale
	for inst, base in pairs(textRegistry) do
		inst.TextSize = math.floor(base * textScale + 0.5)
	end
end

function UIKit.New(className, props, children)
	local inst = Instance.new(className)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		elseif k == "TextBase" then
			UIKit.Text(inst, v)
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

function UIKit.Corner(parent, radius)
	return UIKit.New("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

function UIKit.Stroke(parent, role, thickness)
	local stroke = UIKit.New("UIStroke", {
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
	Theme.Bind(stroke, "Color", role or "stroke")
	return stroke
end

function UIKit.Padding(parent, px, py)
	py = py or px
	return UIKit.New("UIPadding", {
		PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, py), PaddingBottom = UDim.new(0, py),
		Parent = parent,
	})
end

function UIKit.List(parent, padding, horizontal)
	return UIKit.New("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function UIKit.Label(parent, text, size, role, props)
	local label = UIKit.New("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.Gotham,
		TextBase = size or 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Theme.Bind(label, "TextColor3", role or "text")
	for k, v in pairs(props or {}) do
		label[k] = v
	end
	return label
end

function UIKit.Drag(handle, onBegin, onMove, onEnd)
	local stopActive
	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if stopActive then
			stopActive()
		end
		local startPos = Vector2.new(input.Position.X, input.Position.Y)
		local state = onBegin(startPos)
		local moveConn, endConn
		local function stop()
			if not endConn then
				return
			end
			moveConn:Disconnect()
			endConn:Disconnect()
			moveConn, endConn, stopActive = nil, nil, nil
			if onEnd then
				onEnd(state)
			end
		end
		stopActive = stop
		moveConn = UIS.InputChanged:Connect(function(changed)
			if changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch then
				local pos = Vector2.new(changed.Position.X, changed.Position.Y)
				onMove(state, pos - startPos, pos)
			end
		end)
		endConn = UIS.InputEnded:Connect(function(ended)
			if ended.UserInputType == input.UserInputType then
				stop()
			end
		end)
	end)
	handle.Destroying:Connect(function()
		if stopActive then
			stopActive()
		end
	end)
end

function UIKit.Button(parent, text, onClick, style, props)
	style = style or "default"
	local bgRole = style == "primary" and "accent" or (style == "danger" and "danger" or "panel3")
	local textRole = style == "primary" and "accentText" or (style == "danger" and "onDanger" or "text")
	local button = UIKit.New("TextButton", {
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextBase = 14,
		AutoButtonColor = true,
		Size = UDim2.new(0, 100, 0, 36),
		Parent = parent,
	})
	Theme.Bind(button, "BackgroundColor3", bgRole)
	Theme.Bind(button, "TextColor3", textRole)
	UIKit.Corner(button, 8)
	for k, v in pairs(props or {}) do
		button[k] = v
	end
	button.Activated:Connect(function()
		if onClick then
			onClick()
		end
	end)
	return button
end

function UIKit.Toggle(parent, value, onChanged)
	local state = value and true or false
	local track = UIKit.New("TextButton", {
		Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(48, 26), Parent = parent,
	})
	UIKit.Corner(track, 13)
	local knob = UIKit.New("Frame", {
		Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track,
	})
	UIKit.Corner(knob, 10)

	local function render(animate)
		local goal = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
		if animate then
			UIKit.Tween(knob, { Position = goal }, 0.12)
		else
			knob.Position = goal
		end
		Theme.Bind(track, "BackgroundColor3", state and "accent" or "panel3")
	end
	render(false)

	track.Activated:Connect(function()
		state = not state
		render(true)
		if onChanged then
			onChanged(state)
		end
	end)
	return {
		Instance = track,
		Set = function(v)
			state = v and true or false
			render(false)
		end,
		Get = function()
			return state
		end,
	}
end

function UIKit.Slider(parent, min, max, step, value, onChanged, format)
	format = format or tostring
	local holder = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = parent })
	local valueLabel = UIKit.New("TextLabel", {
		BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextBase = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(0, 56, 1, 0), Position = UDim2.new(1, -56, 0, 0), Parent = holder,
	})
	Theme.Bind(valueLabel, "TextColor3", "subtext")
	local hit = UIKit.New("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Size = UDim2.new(1, -64, 1, 0), Parent = holder,
	})
	local track = UIKit.New("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), Parent = hit })
	Theme.Bind(track, "BackgroundColor3", "panel3")
	UIKit.Corner(track, 3)
	local fill = UIKit.New("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = track })
	Theme.Bind(fill, "BackgroundColor3", "accent")
	UIKit.Corner(fill, 3)
	local knob = UIKit.New("Frame", {
		Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), Parent = hit,
	})
	UIKit.Corner(knob, 9)

	local current = value or min
	local function render(v)
		local alpha = max > min and math.clamp((v - min) / (max - min), 0, 1) or 0
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = format(v)
	end
	local function setFromX(x)
		local width = hit.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = math.clamp((x - hit.AbsolutePosition.X) / width, 0, 1)
		local v = min + alpha * (max - min)
		if step and step > 0 then
			v = math.round(v / step) * step
		end
		v = tonumber(string.format("%.4f", math.clamp(v, min, max)))
		if v ~= current then
			current = v
			render(v)
			if onChanged then
				onChanged(v)
			end
		end
	end
	UIKit.Drag(hit, function(pos)
		setFromX(pos.X)
	end, function(_, _, pos)
		setFromX(pos.X)
	end)
	render(current)

	return {
		Instance = holder,
		Set = function(v)
			current = v
			render(v)
		end,
		Get = function()
			return current
		end,
	}
end

function UIKit.TextInput(parent, placeholder, text, onCommit, onChanged)
	local box = UIKit.New("TextBox", {
		Text = text or "", PlaceholderText = placeholder or "", ClearTextOnFocus = false,
		Font = Enum.Font.Gotham, TextBase = 14, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 36), Parent = parent,
	})
	Theme.Bind(box, "BackgroundColor3", "panel3")
	Theme.Bind(box, "TextColor3", "text")
	Theme.Bind(box, "PlaceholderColor3", "subtext")
	UIKit.Corner(box, 8)
	UIKit.Padding(box, 10, 0)
	box.FocusLost:Connect(function(enterPressed)
		if onCommit then
			onCommit(box.Text, enterPressed)
		end
	end)
	if onChanged then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			onChanged(box.Text)
		end)
	end
	return box
end

local activePopup

function UIKit.ClosePopup()
	if activePopup then
		activePopup:Destroy()
		activePopup = nil
	end
end

function UIKit.OpenPopup(anchor, options, current, onPick)
	UIKit.ClosePopup()
	local overlay = UIKit.Overlay
	if not overlay then
		return
	end
	local s = UIKit.Scale
	local rowHeight = 36 * s
	local height = math.min(#options * rowHeight, 220 * s)
	local pos = anchor.AbsolutePosition - overlay.AbsolutePosition
	local size = anchor.AbsoluteSize
	local y = pos.Y + size.Y + 4
	if y + height > overlay.AbsoluteSize.Y then
		y = math.max(0, pos.Y - height - 4)
	end

	local blocker = UIKit.New("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = overlay,
	})
	activePopup = blocker
	blocker.Activated:Connect(UIKit.ClosePopup)

	local list = UIKit.New("ScrollingFrame", {
		Position = UDim2.fromOffset(pos.X, y), Size = UDim2.fromOffset(size.X, height),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4, BorderSizePixel = 0, ZIndex = 51, Parent = blocker,
	})
	Theme.Bind(list, "BackgroundColor3", "panel2")
	UIKit.Corner(list, 8)
	UIKit.Stroke(list, "stroke", 1)
	UIKit.List(list, 0)
	for _, option in ipairs(options) do
		local row = UIKit.New("TextButton", {
			Text = option, Font = Enum.Font.Gotham, TextBase = 14 * s, AutoButtonColor = true,
			Size = UDim2.new(1, 0, 0, rowHeight), ZIndex = 52, Parent = list,
		})
		Theme.Bind(row, "BackgroundColor3", option == current and "panel3" or "panel2")
		Theme.Bind(row, "TextColor3", "text")
		row.Activated:Connect(function()
			UIKit.ClosePopup()
			onPick(option)
		end)
	end
end

function UIKit.Dropdown(parent, options, value, onChanged)
	local button = UIKit.New("TextButton", {
		Text = "", AutoButtonColor = true, Size = UDim2.new(1, 0, 0, 36), Parent = parent,
	})
	Theme.Bind(button, "BackgroundColor3", "panel3")
	UIKit.Corner(button, 8)
	local label = UIKit.New("TextLabel", {
		BackgroundTransparency = 1, Text = tostring(value), Font = Enum.Font.Gotham, TextBase = 14,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(10, 0),
		Parent = button,
	})
	Theme.Bind(label, "TextColor3", "text")
	local arrow = UIKit.New("TextLabel", {
		BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold, TextBase = 12,
		Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -28, 0, 0), Parent = button,
	})
	Theme.Bind(arrow, "TextColor3", "subtext")

	local current = value
	button.Activated:Connect(function()
		UIKit.OpenPopup(button, options, current, function(option)
			current = option
			label.Text = option
			if onChanged then
				onChanged(option)
			end
		end)
	end)
	return {
		Instance = button,
		Set = function(v)
			current = v
			label.Text = tostring(v)
		end,
		Get = function()
			return current
		end,
	}
end

function UIKit.Row(parent, title, description)
	local row = UIKit.New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent })
	Theme.Bind(row, "BackgroundColor3", "panel2")
	UIKit.Corner(row, 8)
	UIKit.Padding(row, 10)
	UIKit.List(row, 6)
	UIKit.Label(row, title, 14, "text", { Font = Enum.Font.GothamMedium, LayoutOrder = 1 })
	if description and description ~= "" then
		UIKit.Label(row, description, 12, "subtext", { LayoutOrder = 2 })
	end
	local content = UIKit.New("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3, Parent = row,
	})
	UIKit.List(content, 6)
	local errorLabel = UIKit.Label(row, "", 12, "danger", { LayoutOrder = 4, Visible = false })
	return row, content, errorLabel
end

return UIKit
]=])

local function resolveOwnerUserId()
	local function nameOf(userId)
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if ok and type(name) == "string" then
			return name
		end
		return nil
	end

	if OWNER_USER_ID_OVERRIDE > 0 then
		local name = nameOf(OWNER_USER_ID_OVERRIDE)
		if name and name:lower() == OWNER_USERNAME:lower() then
			return OWNER_USER_ID_OVERRIDE
		end
		return 0, "the override UserId does not belong to " .. OWNER_USERNAME
	end

	local ok, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(OWNER_USERNAME)
	end)
	if not ok or type(userId) ~= "number" or userId <= 0 then
		return 0, "Roblox could not resolve the username (are you online?)"
	end
	local name = nameOf(userId)
	if not name or name:lower() ~= OWNER_USERNAME:lower() then
		return 0, "the resolved UserId did not verify against the username"
	end
	return userId
end

local function getRoot(name)
	if name == "StarterPlayer" then
		return StarterPlayer
	end
	return game:GetService(name)
end

local function removeOld(parent, name)
	local old = parent and parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

removeOld(ReplicatedStorage, "Fxield")
removeOld(ServerScriptService, "FxieldServer")
removeOld(StarterPlayer:FindFirstChild("StarterPlayerScripts"), "FxieldClient")

local ownerUserId, ownerProblem = resolveOwnerUserId()

local folders = {}
local function ensureFolder(parent, name)
	local key = parent:GetFullName() .. "/" .. name
	if folders[key] and folders[key].Parent then
		return folders[key]
	end
	local existing = parent:FindFirstChild(name)
	if not existing then
		existing = Instance.new("Folder")
		existing.Name = name
		existing.Parent = parent
	end
	folders[key] = existing
	return existing
end

local created = 0
for _, entry in ipairs(ENTRIES) do
	local parts = string.split(entry.path, "/")
	local parent = getRoot(parts[1])
	local first = 2
	if parts[1] == "StarterPlayer" then
		parent = StarterPlayer:WaitForChild("StarterPlayerScripts")
		first = 3
	end
	for i = first, #parts - 1 do
		parent = ensureFolder(parent, parts[i])
	end
	local source = entry.source
	if entry.path == "ServerScriptService/FxieldServer/ServerConfig" then
		local before = source
		source = source:gsub("OwnerUserId = 0,", "OwnerUserId = " .. string.format("%d", ownerUserId) .. ",", 1)
		assert(source ~= before or ownerUserId == 0, "ServerConfig placeholder not found")
	end
	local instance = Instance.new(entry.class)
	instance.Name = parts[#parts]
	instance.Source = source
	instance.Parent = parent
	created += 1
end

ensureFolder(ReplicatedStorage:FindFirstChild("Fxield"), "Remotes")

print(("[Fxield] Installed %d scripts."):format(created))
if ownerUserId > 0 then
	print(("[Fxield] Owner %s verified with UserId %d and stored in ServerScriptService > FxieldServer > ServerConfig."):format(OWNER_USERNAME, ownerUserId))
else
	warn(("[Fxield] Owner %s could NOT be verified (%s). Administration stays disabled (fail closed). Fix: connect to the internet and run this file again, or set OWNER_USER_ID_OVERRIDE near the top of this file to the correct numeric UserId, or edit OwnerUserId in ServerConfig by hand."):format(OWNER_USERNAME, tostring(ownerProblem)))
end
print("[Fxield] Press Play. Open Fxield with the F button or the ; key. Read README.md for setup, key and testing notes.")

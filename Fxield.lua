local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	return
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
	Name = "Fxield",
	Version = "3.0.0",
	OwnerLabel = "FxplayzOfficial",
	DefaultTheme = "Midnight",
	GuiName = "FxieldUI",
	RunningAttribute = "FxieldRunning",
	MaxOutputLines = 120,
	HeaderHeight = 48,
	CompactBreakpoint = 640,
	Margin = 8,
	DefaultToggleKey = "RightControl",
}

if PlayerGui:GetAttribute(Config.RunningAttribute) then
	return
end

local Util = {}
local Janitor = { items = {}, threads = {} }
local Theme = {}
local Style = {}
local UI = {}
local Notify = {}
local Registry = {}
local Console = {}
local Session = {}
local View = {}
local App = {}
local Pages = {}
local Prefs = {}

local PrefDefaults = {
	theme = Config.DefaultTheme,
	accent = "",
	uiScale = 1,
	textScale = 1,
	transparency = 0,
	cornerRadius = 12,
	reduceMotion = false,
	compact = "auto",
	touchTargets = "normal",
	font = "Gotham",
	windowSize = "medium",
	notifications = true,
	notifySeconds = 4,
	notifyLimit = 4,
	notifyPosition = "topright",
	tooltips = true,
	autocomplete = true,
	prefix = ";",
	toggleKey = Config.DefaultToggleKey,
	historySize = 50,
	locked = false,
}

for key, value in pairs(PrefDefaults) do
	Prefs[key] = value
end

function Util.rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

function Util.trim(text)
	return text:match("^%s*(.-)%s*$")
end

function Util.clamp(n, low, high)
	return math.max(low, math.min(high, n))
end

function Util.round(n, places)
	local m = 10 ^ (places or 0)
	return math.floor(n * m + 0.5) / m
end

function Util.isFinite(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function Util.startsWith(text, prefix)
	return text:sub(1, #prefix) == prefix
end

function Util.formatNumber(n)
	local negative = n < 0
	local digits = string.format("%.0f", math.floor(math.abs(n) + 0.5))
	local reversed = digits:reverse():gsub("(%d%d%d)", "%1,")
	local formatted = reversed:reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return (negative and "-" or "") .. formatted
end

function Util.formatDuration(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return ("%dh %02dm %02ds"):format(h, m, s)
	elseif m > 0 then
		return ("%dm %02ds"):format(m, s)
	end
	return ("%ds"):format(s)
end

function Util.parseBool(token)
	if type(token) ~= "string" then
		return nil
	end
	local t = token:lower()
	if t == "on" or t == "true" or t == "yes" or t == "1" or t == "enable" or t == "enabled" then
		return true
	elseif t == "off" or t == "false" or t == "no" or t == "0" or t == "disable" or t == "disabled" then
		return false
	end
	return nil
end

function Util.parseHex(text)
	if type(text) ~= "string" then
		return nil
	end
	local hex = text:match("^#?(%x%x%x%x%x%x)$")
	if not hex then
		return nil
	end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	return Color3.fromRGB(r, g, b), "#" .. hex:upper()
end

function Util.titleCase(text)
	return (text:gsub("(%a)([%w']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

function Util.words(text)
	local list = {}
	for word in text:gmatch("%S+") do
		table.insert(list, word)
	end
	return list
end

function Util.distance(a, b)
	local la, lb = #a, #b
	if math.abs(la - lb) > 3 then
		return 99
	end
	local previous = {}
	for j = 0, lb do
		previous[j] = j
	end
	for i = 1, la do
		local current = { [0] = i }
		for j = 1, lb do
			local cost = (a:sub(i, i) == b:sub(j, j)) and 0 or 1
			current[j] = math.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
		end
		previous = current
	end
	return previous[lb]
end

function Util.tokenize(line)
	local tokens = {}
	local i, n = 1, #line
	while i <= n do
		local c = line:sub(i, i)
		if c:match("%s") then
			i += 1
		elseif c == '"' or c == "'" then
			local buffer = {}
			local closed = false
			i += 1
			while i <= n do
				local ch = line:sub(i, i)
				if ch == "\\" and i < n then
					table.insert(buffer, line:sub(i + 1, i + 1))
					i += 2
				elseif ch == c then
					closed = true
					i += 1
					break
				else
					table.insert(buffer, ch)
					i += 1
				end
			end
			if not closed then
				return nil, "A quotation mark was opened but never closed."
			end
			table.insert(tokens, table.concat(buffer))
		else
			local j = i
			while j <= n and not line:sub(j, j):match("%s") do
				j += 1
			end
			table.insert(tokens, line:sub(i, j - 1))
			i = j
		end
	end
	return tokens
end

Util.mathFunctions = {
	sqrt = math.sqrt,
	abs = math.abs,
	floor = math.floor,
	ceil = math.ceil,
	round = function(x)
		return math.floor(x + 0.5)
	end,
	sin = math.sin,
	cos = math.cos,
	tan = math.tan,
	asin = math.asin,
	acos = math.acos,
	atan = math.atan,
	log = function(x)
		return math.log(x, 10)
	end,
	ln = function(x)
		return math.log(x)
	end,
	exp = math.exp,
	deg = math.deg,
	rad = math.rad,
	sign = function(x)
		return x > 0 and 1 or (x < 0 and -1 or 0)
	end,
}

Util.mathMulti = { min = math.min, max = math.max }
Util.mathConstants = { pi = math.pi, e = math.exp(1) }

function Util.evaluate(expression)
	if #expression > 160 then
		return nil, "That expression is too long."
	end
	local tokens = {}
	local i, n = 1, #expression
	while i <= n do
		local c = expression:sub(i, i)
		if c:match("%s") then
			i += 1
		elseif c:match("[%d%.]") then
			local text = expression:match("^%d*%.?%d*", i)
			local value = tonumber(text)
			if not value then
				return nil, "Bad number '" .. text .. "'."
			end
			table.insert(tokens, { kind = "num", value = value })
			i += #text
		elseif c:match("[%a_]") then
			local word = expression:match("^[%a_][%w_]*", i)
			table.insert(tokens, { kind = "name", value = word:lower() })
			i += #word
		elseif c:match("[%+%-%*/%%%^%(%),]") then
			table.insert(tokens, { kind = "op", value = c })
			i += 1
		else
			return nil, "Unexpected character '" .. c .. "'."
		end
	end

	local position = 1
	local depth = 0
	local parseExpression

	local function peek()
		return tokens[position]
	end

	local function isOp(value)
		local t = tokens[position]
		return t ~= nil and t.kind == "op" and t.value == value
	end

	local function parsePrimary()
		local t = tokens[position]
		if not t then
			error("The expression ended unexpectedly.", 0)
		end
		if t.kind == "num" then
			position += 1
			return t.value
		elseif t.kind == "name" then
			position += 1
			if Util.mathConstants[t.value] and not isOp("(") then
				return Util.mathConstants[t.value]
			end
			local single = Util.mathFunctions[t.value]
			local multi = Util.mathMulti[t.value]
			if not (single or multi) then
				error("Unknown name '" .. t.value .. "'.", 0)
			end
			if not isOp("(") then
				error("Function '" .. t.value .. "' needs parentheses.", 0)
			end
			position += 1
			local values = {}
			if not isOp(")") then
				table.insert(values, parseExpression())
				while isOp(",") do
					position += 1
					table.insert(values, parseExpression())
				end
			end
			if not isOp(")") then
				error("Missing ')'.", 0)
			end
			position += 1
			if single then
				if #values ~= 1 then
					error(t.value .. " takes exactly one value.", 0)
				end
				return single(values[1])
			end
			if #values < 1 then
				error(t.value .. " needs at least one value.", 0)
			end
			return multi(table.unpack(values))
		elseif t.kind == "op" and t.value == "(" then
			position += 1
			local value = parseExpression()
			if not isOp(")") then
				error("Missing ')'.", 0)
			end
			position += 1
			return value
		end
		error("Unexpected '" .. tostring(t.value) .. "'.", 0)
	end

	local parseUnary

	local function parsePower()
		local base = parsePrimary()
		if isOp("^") then
			position += 1
			local exponent = parseUnary()
			return base ^ exponent
		end
		return base
	end

	parseUnary = function()
		if isOp("-") then
			position += 1
			return -parseUnary()
		elseif isOp("+") then
			position += 1
			return parseUnary()
		end
		return parsePower()
	end

	local function parseTerm()
		local value = parseUnary()
		while isOp("*") or isOp("/") or isOp("%") do
			local op = tokens[position].value
			position += 1
			local right = parseUnary()
			if op == "*" then
				value = value * right
			elseif op == "/" then
				value = value / right
			else
				value = value % right
			end
		end
		return value
	end

	parseExpression = function()
		depth += 1
		if depth > 40 then
			error("That expression is nested too deeply.", 0)
		end
		local value = parseTerm()
		while isOp("+") or isOp("-") do
			local op = tokens[position].value
			position += 1
			local right = parseTerm()
			value = (op == "+") and (value + right) or (value - right)
		end
		depth -= 1
		return value
	end

	local ok, result = pcall(function()
		local value = parseExpression()
		if peek() then
			error("Unexpected '" .. tostring(peek().value) .. "'.", 0)
		end
		return value
	end)
	if not ok then
		return nil, tostring(result)
	end
	if not Util.isFinite(result) then
		return nil, "The result is not a finite number (check for division by zero)."
	end
	return result
end

Util.base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function Util.base64Encode(data)
	local out = {}
	for i = 1, #data, 3 do
		local a, b, c = data:byte(i, i + 2)
		local triple = bit32.lshift(a, 16) + bit32.lshift(b or 0, 8) + (c or 0)
		local c1 = bit32.rshift(triple, 18) % 64
		local c2 = bit32.rshift(triple, 12) % 64
		local c3 = bit32.rshift(triple, 6) % 64
		local c4 = triple % 64
		table.insert(out, Util.base64Chars:sub(c1 + 1, c1 + 1))
		table.insert(out, Util.base64Chars:sub(c2 + 1, c2 + 1))
		table.insert(out, b and Util.base64Chars:sub(c3 + 1, c3 + 1) or "=")
		table.insert(out, c and Util.base64Chars:sub(c4 + 1, c4 + 1) or "=")
	end
	return table.concat(out)
end

function Util.base64Decode(text)
	text = text:gsub("%s", "")
	if #text % 4 ~= 0 or text:find("[^%w%+/=]") then
		return nil, "That is not valid Base64 text."
	end
	local out = {}
	for i = 1, #text, 4 do
		local values = {}
		local padding = 0
		for j = 0, 3 do
			local ch = text:sub(i + j, i + j)
			if ch == "=" then
				padding += 1
				values[j + 1] = 0
			else
				if padding > 0 then
					return nil, "That is not valid Base64 text."
				end
				local index = Util.base64Chars:find(ch, 1, true)
				if not index then
					return nil, "That is not valid Base64 text."
				end
				values[j + 1] = index - 1
			end
		end
		local triple = bit32.lshift(values[1], 18) + bit32.lshift(values[2], 12) + bit32.lshift(values[3], 6) + values[4]
		table.insert(out, string.char(bit32.rshift(triple, 16) % 256))
		if padding < 2 then
			table.insert(out, string.char(bit32.rshift(triple, 8) % 256))
		end
		if padding < 1 then
			table.insert(out, string.char(triple % 256))
		end
	end
	return table.concat(out)
end

function Janitor.add(item)
	table.insert(Janitor.items, item)
	return item
end

function Janitor.connect(signal, handler)
	return Janitor.add(signal:Connect(handler))
end

function Janitor.delay(seconds, handler)
	local thread
	thread = task.delay(seconds, function()
		Janitor.threads[thread] = nil
		handler()
	end)
	Janitor.threads[thread] = true
	return thread
end

function Janitor.cancel(thread)
	Janitor.threads[thread] = nil
	pcall(task.cancel, thread)
end

function Janitor.counts()
	local connections, instances = 0, 0
	for _, item in ipairs(Janitor.items) do
		if typeof(item) == "RBXScriptConnection" then
			connections += 1
		elseif typeof(item) == "Instance" then
			instances += 1
		end
	end
	local threads = 0
	for _ in pairs(Janitor.threads) do
		threads += 1
	end
	return connections, instances, threads
end

function Janitor.cleanup()
	for thread in pairs(Janitor.threads) do
		pcall(task.cancel, thread)
	end
	table.clear(Janitor.threads)
	for i = #Janitor.items, 1, -1 do
		local item = Janitor.items[i]
		local kind = typeof(item)
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "function" then
			pcall(item)
		end
	end
	table.clear(Janitor.items)
end

Theme.order = { "Midnight", "Violet", "Ocean", "Emerald", "Rose", "Light", "High Contrast" }

Theme.palettes = {
	Midnight = {
		bg = Util.rgb(15, 16, 20), surface = Util.rgb(22, 24, 30), surface2 = Util.rgb(30, 32, 40), surface3 = Util.rgb(41, 44, 55),
		border = Util.rgb(52, 56, 70), text = Util.rgb(234, 236, 242), textDim = Util.rgb(148, 154, 170),
		accent = Util.rgb(139, 92, 246), accentText = Util.rgb(255, 255, 255), onDanger = Util.rgb(255, 255, 255),
		success = Util.rgb(74, 198, 128), warning = Util.rgb(240, 178, 64), danger = Util.rgb(238, 92, 104),
	},
	Violet = {
		bg = Util.rgb(18, 14, 28), surface = Util.rgb(27, 21, 42), surface2 = Util.rgb(37, 29, 58), surface3 = Util.rgb(51, 40, 80),
		border = Util.rgb(70, 56, 108), text = Util.rgb(240, 235, 252), textDim = Util.rgb(166, 152, 196),
		accent = Util.rgb(167, 120, 255), accentText = Util.rgb(20, 12, 36), onDanger = Util.rgb(255, 255, 255),
		success = Util.rgb(92, 205, 140), warning = Util.rgb(244, 186, 80), danger = Util.rgb(242, 100, 120),
	},
	Ocean = {
		bg = Util.rgb(11, 18, 26), surface = Util.rgb(16, 27, 38), surface2 = Util.rgb(23, 38, 53), surface3 = Util.rgb(33, 52, 72),
		border = Util.rgb(45, 70, 96), text = Util.rgb(228, 238, 247), textDim = Util.rgb(135, 160, 184),
		accent = Util.rgb(56, 178, 224), accentText = Util.rgb(6, 20, 30), onDanger = Util.rgb(255, 255, 255),
		success = Util.rgb(70, 204, 140), warning = Util.rgb(240, 184, 80), danger = Util.rgb(240, 96, 108),
	},
	Emerald = {
		bg = Util.rgb(12, 19, 17), surface = Util.rgb(18, 29, 26), surface2 = Util.rgb(26, 41, 36), surface3 = Util.rgb(37, 58, 51),
		border = Util.rgb(50, 78, 68), text = Util.rgb(229, 244, 238), textDim = Util.rgb(137, 170, 157),
		accent = Util.rgb(52, 199, 140), accentText = Util.rgb(6, 26, 18), onDanger = Util.rgb(255, 255, 255),
		success = Util.rgb(96, 214, 150), warning = Util.rgb(240, 186, 80), danger = Util.rgb(240, 100, 110),
	},
	Rose = {
		bg = Util.rgb(22, 13, 17), surface = Util.rgb(33, 20, 26), surface2 = Util.rgb(45, 28, 36), surface3 = Util.rgb(61, 39, 50),
		border = Util.rgb(86, 55, 70), text = Util.rgb(248, 233, 238), textDim = Util.rgb(184, 145, 159),
		accent = Util.rgb(240, 98, 146), accentText = Util.rgb(40, 8, 20), onDanger = Util.rgb(255, 255, 255),
		success = Util.rgb(92, 205, 140), warning = Util.rgb(244, 188, 84), danger = Util.rgb(250, 110, 110),
	},
	Light = {
		bg = Util.rgb(242, 243, 247), surface = Util.rgb(252, 252, 254), surface2 = Util.rgb(240, 242, 247), surface3 = Util.rgb(226, 229, 238),
		border = Util.rgb(203, 208, 222), text = Util.rgb(26, 29, 38), textDim = Util.rgb(98, 106, 126),
		accent = Util.rgb(110, 70, 220), accentText = Util.rgb(255, 255, 255), onDanger = Util.rgb(255, 255, 255),
		success = Util.rgb(25, 140, 80), warning = Util.rgb(190, 120, 10), danger = Util.rgb(200, 48, 62),
	},
	["High Contrast"] = {
		bg = Util.rgb(0, 0, 0), surface = Util.rgb(8, 8, 8), surface2 = Util.rgb(20, 20, 20), surface3 = Util.rgb(44, 44, 44),
		border = Util.rgb(255, 255, 255), text = Util.rgb(255, 255, 255), textDim = Util.rgb(224, 224, 224),
		accent = Util.rgb(255, 214, 0), accentText = Util.rgb(0, 0, 0), onDanger = Util.rgb(0, 0, 0),
		success = Util.rgb(0, 255, 128), warning = Util.rgb(255, 170, 0), danger = Util.rgb(255, 96, 96),
	},
}

Theme.name = Config.DefaultTheme
Theme.previewName = nil
Theme.accentOverride = nil
Theme.bindings = setmetatable({}, { __mode = "k" })

function Theme.current()
	return Theme.palettes[Theme.previewName or Theme.name]
end

function Theme.luminance(color)
	return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
end

function Theme.color(role)
	local palette = Theme.current()
	if role == "accent" then
		return Theme.accentOverride or palette.accent
	elseif role == "accentText" then
		if Theme.accentOverride then
			return Theme.luminance(Theme.accentOverride) > 0.6 and Util.rgb(16, 17, 22) or Util.rgb(255, 255, 255)
		end
		return palette.accentText
	end
	return palette[role] or palette.text
end

function Theme.bind(inst, property, role)
	local props = Theme.bindings[inst]
	if not props then
		props = {}
		Theme.bindings[inst] = props
	end
	props[property] = role
	inst[property] = Theme.color(role)
end

function Theme.apply()
	for inst, props in pairs(Theme.bindings) do
		for property, role in pairs(props) do
			inst[property] = Theme.color(role)
		end
	end
	if App.onThemeChanged then
		App.onThemeChanged()
	end
end

function Theme.set(name)
	if not Theme.palettes[name] then
		return false
	end
	Theme.name = name
	Theme.previewName = nil
	Prefs.theme = name
	Theme.apply()
	return true
end

function Theme.preview(name)
	if not Theme.palettes[name] then
		return false
	end
	Theme.previewName = name
	Theme.apply()
	return true
end

function Theme.cancelPreview()
	if Theme.previewName then
		Theme.previewName = nil
		Theme.apply()
	end
end

function Theme.commitPreview()
	if Theme.previewName then
		return Theme.set(Theme.previewName)
	end
	return false
end

function Theme.setAccent(hex)
	if hex == nil or hex == "" then
		Theme.accentOverride = nil
		Prefs.accent = ""
	else
		local color, normalized = Util.parseHex(hex)
		if not color then
			return false
		end
		Theme.accentOverride = color
		Prefs.accent = normalized
	end
	Theme.apply()
	return true
end

function Theme.cycle(step)
	local index = table.find(Theme.order, Theme.name) or 1
	index = ((index - 1 + step) % #Theme.order) + 1
	Theme.set(Theme.order[index])
	return Theme.name
end

Style.textRegistry = setmetatable({}, { __mode = "k" })
Style.cornerRegistry = setmetatable({}, { __mode = "k" })
Style.touchRegistry = setmetatable({}, { __mode = "k" })
Style.fonts = {
	Gotham = { regular = Enum.Font.Gotham, medium = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold },
	SourceSans = { regular = Enum.Font.SourceSans, medium = Enum.Font.SourceSansSemibold, bold = Enum.Font.SourceSansBold },
	Arial = { regular = Enum.Font.Arial, medium = Enum.Font.Arial, bold = Enum.Font.ArialBold },
}
Style.familyOrder = { "Gotham", "SourceSans", "Arial" }

function Style.fontFor(weight)
	if weight == "mono" then
		return Enum.Font.Code
	end
	local family = Style.fonts[Prefs.font] or Style.fonts.Gotham
	return family[weight] or family.regular
end

function Style.registerText(inst, baseSize, weight)
	Style.textRegistry[inst] = { base = baseSize, weight = weight or "regular" }
	inst.TextSize = math.floor(baseSize * Prefs.textScale + 0.5)
	inst.Font = Style.fontFor(weight or "regular")
end

function Style.applyText()
	for inst, info in pairs(Style.textRegistry) do
		inst.TextSize = math.floor(info.base * Prefs.textScale + 0.5)
	end
end

function Style.applyFont()
	for inst, info in pairs(Style.textRegistry) do
		inst.Font = Style.fontFor(info.weight)
	end
end

function Style.registerCorner(corner, factor)
	Style.cornerRegistry[corner] = factor
	corner.CornerRadius = UDim.new(0, math.floor(Prefs.cornerRadius * factor + 0.5))
end

function Style.applyCorners()
	for corner, factor in pairs(Style.cornerRegistry) do
		corner.CornerRadius = UDim.new(0, math.floor(Prefs.cornerRadius * factor + 0.5))
	end
end

function Style.registerTouch(button, baseHeight)
	Style.touchRegistry[button] = baseHeight
	local scale = Prefs.touchTargets == "large" and 1.3 or 1
	button.Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0, math.floor(baseHeight * scale + 0.5))
end

function Style.applyTouch()
	local scale = Prefs.touchTargets == "large" and 1.3 or 1
	for button, baseHeight in pairs(Style.touchRegistry) do
		button.Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0, math.floor(baseHeight * scale + 0.5))
	end
end

function UI.wrapList(parent, gap)
	local layout = UI.list(parent, gap, true)
	local ok = pcall(function()
		layout.Wraps = true
	end)
	if not ok then
		layout.FillDirection = Enum.FillDirection.Vertical
	end
	return layout
end

function UI.new(className, props)
	local inst = Instance.new(className)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	inst.Parent = parent
	return inst
end

function UI.tween(inst, goal, seconds)
	if Prefs.reduceMotion then
		for key, value in pairs(goal) do
			inst[key] = value
		end
		return
	end
	TweenService:Create(inst, TweenInfo.new(seconds or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

function UI.corner(parent, factor)
	local corner = UI.new("UICorner", { Parent = parent })
	Style.registerCorner(corner, factor or 0.6)
	return corner
end

function UI.stroke(parent, role, thickness)
	local stroke = UI.new("UIStroke", {
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
	Theme.bind(stroke, "Color", role or "border")
	return stroke
end

function UI.padding(parent, left, top, right, bottom)
	top = top or left
	right = right or left
	bottom = bottom or top
	return UI.new("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		Parent = parent,
	})
end

function UI.list(parent, gap, horizontal)
	return UI.new("UIListLayout", {
		Padding = UDim.new(0, gap or 8),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function UI.label(parent, text, size, role, weight, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = false,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Style.registerText(label, size or 14, weight)
	Theme.bind(label, "TextColor3", role or "text")
	for key, value in pairs(props or {}) do
		label[key] = value
	end
	return label
end

function UI.setEnabled(button, enabled)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.TextTransparency = enabled and 0 or 0.55
end

function UI.button(parent, text, onClick, style, props)
	style = style or "default"
	local background = style == "primary" and "accent" or (style == "danger" and "danger" or (style == "ghost" and "surface" or "surface3"))
	local foreground = style == "primary" and "accentText" or (style == "danger" and "onDanger" or "text")
	local button = UI.new("TextButton", {
		Text = text,
		AutoButtonColor = true,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(0, 96, 0, 38),
		Parent = parent,
	})
	Style.registerText(button, 14, "medium")
	Theme.bind(button, "BackgroundColor3", background)
	Theme.bind(button, "TextColor3", foreground)
	UI.corner(button, 0.6)
	if style == "ghost" then
		UI.stroke(button, "border", 1)
	end
	for key, value in pairs(props or {}) do
		button[key] = value
	end
	Style.registerTouch(button, button.Size.Y.Offset)
	button.Activated:Connect(function()
		if onClick then
			local ok, err = pcall(onClick)
			if not ok then
				Notify.show("error", "Something went wrong: " .. tostring(err))
			end
		end
	end)
	return button
end

function UI.card(parent, title, subtitle, order)
	local card = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Theme.bind(card, "BackgroundColor3", "surface")
	card.BackgroundTransparency = Prefs.transparency
	App.glass[card] = true
	UI.corner(card, 0.8)
	UI.stroke(card, "border", 1)
	UI.padding(card, 14)
	UI.list(card, 10)
	if title then
		UI.label(card, title, 16, "text", "bold", { LayoutOrder = 1 })
	end
	if subtitle and subtitle ~= "" then
		UI.label(card, subtitle, 13, "textDim", "regular", { LayoutOrder = 2 })
	end
	local content = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = card,
	})
	UI.list(content, 8)
	return card, content
end

function UI.drag(handle, onBegin, onMove, onEnd)
	local stop
	Janitor.connect(handle.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if stop then
			stop()
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local state = onBegin(start)
		local moveConnection, endConnection
		stop = function()
			if moveConnection then
				moveConnection:Disconnect()
				moveConnection = nil
			end
			if endConnection then
				endConnection:Disconnect()
				endConnection = nil
			end
			stop = nil
			if onEnd then
				onEnd(state)
			end
		end
		moveConnection = UserInputService.InputChanged:Connect(function(changed)
			if changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch then
				local position = Vector2.new(changed.Position.X, changed.Position.Y)
				onMove(state, position - start, position)
			end
		end)
		endConnection = UserInputService.InputEnded:Connect(function(ended)
			if ended.UserInputType == input.UserInputType and stop then
				stop()
			end
		end)
	end)
	Janitor.add(function()
		if stop then
			stop()
		end
	end)
end

function UI.toggle(parent, value, onChanged)
	local state = value and true or false
	local track = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(52, 28),
		Parent = parent,
	})
	UI.corner(track, 1.2)
	local knob = UI.new("Frame", {
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Util.rgb(255, 255, 255),
		Parent = track,
	})
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local function render(animate)
		local goal = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
		if animate then
			UI.tween(knob, { Position = goal }, 0.12)
		else
			knob.Position = goal
		end
		Theme.bind(track, "BackgroundColor3", state and "accent" or "surface3")
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
		instance = track,
		set = function(v)
			state = v and true or false
			render(false)
		end,
		get = function()
			return state
		end,
	}
end

function UI.slider(parent, min, max, step, value, onChanged, format, onRelease)
	format = format or tostring
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Parent = parent })
	local valueLabel = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		Size = UDim2.new(0, 64, 1, 0),
		Position = UDim2.new(1, -64, 0, 0),
		Parent = holder,
	})
	Style.registerText(valueLabel, 13, "regular")
	Theme.bind(valueLabel, "TextColor3", "textDim")
	local hit = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -72, 1, 0),
		Parent = holder,
	})
	local track = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), Parent = hit })
	Theme.bind(track, "BackgroundColor3", "surface3")
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local fill = UI.new("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = track })
	Theme.bind(fill, "BackgroundColor3", "accent")
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local knob = UI.new("Frame", {
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Util.rgb(255, 255, 255),
		Parent = hit,
	})
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local current = value or min
	local function render(v)
		local alpha = max > min and Util.clamp((v - min) / (max - min), 0, 1) or 0
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = format(v)
	end
	local function setFromX(x)
		local width = hit.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = Util.clamp((x - hit.AbsolutePosition.X) / width, 0, 1)
		local v = min + alpha * (max - min)
		if step and step > 0 then
			v = math.floor(v / step + 0.5) * step
		end
		v = tonumber(string.format("%.4f", Util.clamp(v, min, max)))
		if v ~= current then
			current = v
			render(v)
			if onChanged then
				onChanged(v)
			end
		end
	end
	UI.drag(hit, function(position)
		setFromX(position.X)
	end, function(_, _, position)
		setFromX(position.X)
	end, function()
		if onRelease then
			onRelease(current)
		end
	end)
	render(current)
	return {
		instance = holder,
		set = function(v)
			current = v
			render(v)
		end,
		get = function()
			return current
		end,
	}
end

function UI.input(parent, placeholder, text, onCommit)
	local box = UI.new("TextBox", {
		Text = text or "",
		PlaceholderText = placeholder or "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = parent,
	})
	Style.registerText(box, 14, "regular")
	Theme.bind(box, "BackgroundColor3", "surface3")
	Theme.bind(box, "TextColor3", "text")
	Theme.bind(box, "PlaceholderColor3", "textDim")
	UI.corner(box, 0.6)
	UI.padding(box, 12, 0)
	Style.registerTouch(box, 40)
	Janitor.connect(box.FocusLost, function(enterPressed)
		if onCommit then
			onCommit(box.Text, enterPressed)
		end
	end)
	return box
end

function UI.closePopup()
	if UI.popup then
		UI.popup:Destroy()
		UI.popup = nil
	end
end

function UI.openPopup(anchor, options, current, onPick)
	UI.closePopup()
	local layer = App.popupLayer
	if not layer then
		return
	end
	local scale = Prefs.uiScale
	local rowHeight = math.floor(40 * scale * (Prefs.touchTargets == "large" and 1.2 or 1))
	local height = math.min(#options * rowHeight, math.floor(240 * scale))
	local position = anchor.AbsolutePosition - layer.AbsolutePosition
	local size = anchor.AbsoluteSize
	local y = position.Y + size.Y + 4
	if y + height > layer.AbsoluteSize.Y - Config.Margin then
		y = math.max(Config.Margin, position.Y - height - 4)
	end
	local width = math.min(size.X, layer.AbsoluteSize.X - Config.Margin * 2)
	local x = Util.clamp(position.X, Config.Margin, math.max(Config.Margin, layer.AbsoluteSize.X - width - Config.Margin))

	local blocker = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = layer,
	})
	UI.popup = blocker
	blocker.Activated:Connect(UI.closePopup)

	local list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(width, height),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		Parent = blocker,
	})
	Theme.bind(list, "BackgroundColor3", "surface2")
	UI.corner(list, 0.6)
	UI.stroke(list, "border", 1)
	UI.list(list, 0)
	for _, option in ipairs(options) do
		local row = UI.new("TextButton", {
			Text = tostring(option),
			AutoButtonColor = true,
			Size = UDim2.new(1, 0, 0, rowHeight),
			Parent = list,
		})
		Style.registerText(row, 14 * scale, "regular")
		Theme.bind(row, "BackgroundColor3", option == current and "surface3" or "surface2")
		Theme.bind(row, "TextColor3", "text")
		row.Activated:Connect(function()
			UI.closePopup()
			onPick(option)
		end)
	end
end

function UI.dropdown(parent, options, value, onChanged)
	local button = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = true,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = parent,
	})
	Theme.bind(button, "BackgroundColor3", "surface3")
	UI.corner(button, 0.6)
	Style.registerTouch(button, 40)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(value),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -36, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Parent = button,
	})
	Style.registerText(label, 14, "regular")
	Theme.bind(label, "TextColor3", "text")
	local arrow = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "v",
		Size = UDim2.new(0, 24, 1, 0),
		Position = UDim2.new(1, -28, 0, 0),
		Parent = button,
	})
	Style.registerText(arrow, 12, "bold")
	Theme.bind(arrow, "TextColor3", "textDim")

	local current = value
	button.Activated:Connect(function()
		UI.openPopup(button, options, current, function(option)
			current = option
			label.Text = tostring(option)
			if onChanged then
				onChanged(option)
			end
		end)
	end)
	return {
		instance = button,
		set = function(v)
			current = v
			label.Text = tostring(v)
		end,
		get = function()
			return current
		end,
	}
end

function UI.chip(parent, text, selected, onClick)
	local chip = UI.new("TextButton", {
		Text = text,
		AutoButtonColor = true,
		Size = UDim2.new(0, 0, 0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = parent,
	})
	Style.registerText(chip, 13, "medium")
	UI.corner(chip, 1.2)
	UI.padding(chip, 14, 0)
	local function render(isSelected)
		Theme.bind(chip, "BackgroundColor3", isSelected and "accent" or "surface3")
		Theme.bind(chip, "TextColor3", isSelected and "accentText" or "text")
	end
	render(selected)
	chip.Activated:Connect(function()
		if onClick then
			onClick()
		end
	end)
	return chip, render
end

function UI.confirm(message, onYes)
	local layer = App.popupLayer
	if not layer then
		return
	end
	UI.closePopup()
	local blocker = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Util.rgb(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Parent = layer,
	})
	UI.popup = blocker
	local box = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = blocker,
	})
	Theme.bind(box, "BackgroundColor3", "surface")
	UI.corner(box, 1)
	UI.stroke(box, "border", 1)
	UI.padding(box, 18)
	UI.list(box, 14)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(360, math.huge), Parent = box })
	UI.label(box, "Please confirm", 17, "text", "bold", { LayoutOrder = 1 })
	UI.label(box, message, 14, "textDim", "regular", { LayoutOrder = 2 })
	local buttons = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 3, Parent = box })
	UI.list(buttons, 10, true)
	UI.button(buttons, "Cancel", UI.closePopup, "default", { Size = UDim2.new(0.5, -5, 0, 40) })
	UI.button(buttons, "Confirm", function()
		UI.closePopup()
		onYes()
	end, "primary", { Size = UDim2.new(0.5, -5, 0, 40) })
end

Notify.toasts = {}
Notify.container = nil

function Notify.reposition()
	local container = Notify.container
	if not container then
		return
	end
	local position = Prefs.notifyPosition
	local layout = container:FindFirstChildOfClass("UIListLayout")
	if position == "topleft" then
		container.AnchorPoint = Vector2.new(0, 0)
		container.Position = UDim2.new(0, 12, 0, 12)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
	elseif position == "bottom" then
		container.AnchorPoint = Vector2.new(0.5, 1)
		container.Position = UDim2.new(0.5, 0, 1, -12)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	else
		container.AnchorPoint = Vector2.new(1, 0)
		container.Position = UDim2.new(1, -12, 0, 12)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
	end
end

function Notify.remove(toast)
	local index = table.find(Notify.toasts, toast)
	if index then
		table.remove(Notify.toasts, index)
	end
	if not toast.Parent then
		return
	end
	UI.tween(toast, { GroupTransparency = 1 }, 0.18)
	Janitor.delay(Prefs.reduceMotion and 0 or 0.2, function()
		toast:Destroy()
	end)
end

function Notify.clear()
	for i = #Notify.toasts, 1, -1 do
		Notify.remove(Notify.toasts[i])
	end
end

function Notify.show(kind, text, title)
	if not Prefs.notifications or not Notify.container then
		return
	end
	local roles = { info = "accent", success = "success", warning = "warning", error = "danger" }
	local role = roles[kind] or "accent"
	while #Notify.toasts >= Prefs.notifyLimit do
		Notify.remove(Notify.toasts[1])
	end
	local toast = UI.new("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		Parent = Notify.container,
	})
	Theme.bind(toast, "BackgroundColor3", "surface2")
	UI.corner(toast, 0.8)
	UI.stroke(toast, role, 1)
	local body = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = toast,
	})
	UI.padding(body, 14, 10)
	UI.list(body, 2)
	if title and title ~= "" then
		UI.label(body, title, 13, role, "bold", { LayoutOrder = 1 })
	end
	UI.label(body, tostring(text), 13, "text", "regular", { LayoutOrder = 2 })
	local tap = UI.new("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = toast,
	})
	tap.Activated:Connect(function()
		Notify.remove(toast)
	end)
	table.insert(Notify.toasts, toast)
	UI.tween(toast, { GroupTransparency = 0 }, 0.18)
	Janitor.delay(Prefs.notifySeconds, function()
		if toast.Parent then
			Notify.remove(toast)
		end
	end)
end

Registry.list = {}
Registry.byName = {}
Registry.categoryOrder = {}
Registry.categoryCounts = {}
Registry.favorites = {}
Registry.userAliases = {}
Registry.binds = {}
Registry.define = {}

function Util.normalizeKey(text)
	return (text:lower():gsub("[%s%-_]", ""))
end

function Util.resolveBool(value, current)
	if value == nil or value == "toggle" then
		return not current
	end
	return value
end

function Registry.buildUsage(def)
	local parts = { def.Name }
	for _, spec in ipairs(def.Args) do
		local label = spec[1]
		if spec[2] == "enum" and spec.opts and #spec.opts <= 6 then
			label = table.concat(spec.opts, "|")
		end
		table.insert(parts, spec.opt and ("[" .. label .. "]") or ("<" .. label .. ">"))
	end
	return table.concat(parts, " ")
end

function Registry.add(def)
	def.Aliases = def.Aliases or {}
	def.Args = def.Args or {}
	def.Usage = def.Usage or Registry.buildUsage(def)
	local names = { def.Name }
	for _, alias in ipairs(def.Aliases) do
		table.insert(names, alias)
	end
	for _, name in ipairs(names) do
		if Registry.byName[name:lower()] then
			warn("[Fxield] Duplicate command name or alias ignored: " .. name)
			return
		end
	end
	for _, name in ipairs(names) do
		Registry.byName[name:lower()] = def
	end
	table.insert(Registry.list, def)
	if not Registry.categoryCounts[def.Category] then
		Registry.categoryCounts[def.Category] = 0
		table.insert(Registry.categoryOrder, def.Category)
	end
	Registry.categoryCounts[def.Category] += 1
end

function Registry.addUnavailable(name, description, usage, reason)
	Registry.add({
		Name = name,
		Category = "Needs server",
		Description = description,
		Usage = usage,
		Unavailable = reason,
		Run = function()
			return false, reason
		end,
	})
end

function Registry.find(name)
	if type(name) ~= "string" then
		return nil
	end
	return Registry.byName[name:lower()]
end

function Registry.available()
	local count = 0
	for _, def in ipairs(Registry.list) do
		if not def.Unavailable then
			count += 1
		end
	end
	return count
end

function Registry.convert(spec, raw)
	local kind = spec[2]
	if kind == "number" or kind == "integer" then
		local n = tonumber(raw)
		if not Util.isFinite(n) then
			return false, "expected a number."
		end
		if kind == "integer" and n % 1 ~= 0 then
			return false, "expected a whole number."
		end
		if spec.min and n < spec.min then
			return false, ("must be at least %s."):format(tostring(spec.min))
		end
		if spec.max and n > spec.max then
			return false, ("must be at most %s."):format(tostring(spec.max))
		end
		return true, n
	elseif kind == "bool" then
		if raw:lower() == "toggle" then
			return true, "toggle"
		end
		local value = Util.parseBool(raw)
		if value == nil then
			return false, "use on, off or toggle."
		end
		return true, value
	elseif kind == "enum" then
		local wanted = Util.normalizeKey(raw)
		for _, option in ipairs(spec.opts) do
			if Util.normalizeKey(option) == wanted then
				return true, option
			end
		end
		return false, "choose one of: " .. table.concat(spec.opts, ", ") .. "."
	elseif kind == "string" then
		if #raw > (spec.max or 64) then
			return false, "that is too long."
		end
		return true, raw
	elseif kind == "text" then
		if #raw > (spec.max or 240) then
			return false, ("that is too long (maximum %d characters)."):format(spec.max or 240)
		end
		return true, raw
	elseif kind == "player" then
		local matches = Session.findPlayers(raw)
		if #matches == 0 then
			return false, ("no player matches '%s'."):format(raw)
		elseif #matches > 1 then
			return false, ("'%s' matches several players; be more specific."):format(raw)
		end
		return true, matches[1]
	elseif kind == "key" then
		local wanted = raw:lower()
		for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
			if item ~= Enum.KeyCode.Unknown and item.Name:lower() == wanted then
				return true, item.Name
			end
		end
		return false, "unknown key name (examples: F5, RightControl, Q)."
	elseif kind == "color" then
		local color, hex = Util.parseHex(raw)
		if not color then
			return false, "expected a hex color such as #8B5CF6."
		end
		return true, hex
	end
	return false, "unsupported argument type."
end

function Registry.parseArgs(def, tokens)
	local values = {}
	local index = 2
	for _, spec in ipairs(def.Args) do
		local token = tokens[index]
		if token == nil then
			if not spec.opt then
				return nil, ("Missing <%s>. Usage: %s"):format(spec[1], def.Usage)
			end
			break
		end
		local raw = token
		if spec[2] == "text" then
			raw = table.concat(tokens, " ", index)
			index = #tokens + 1
		else
			index += 1
		end
		local ok, value = Registry.convert(spec, raw)
		if not ok then
			return nil, ("<%s>: %s"):format(spec[1], value)
		end
		values[spec[1]] = value
	end
	if tokens[index] ~= nil then
		return nil, "Too many arguments. Usage: " .. def.Usage
	end
	return values
end

function Registry.toggleFavorite(name, state)
	local def = Registry.find(name)
	if not def then
		return false
	end
	if state == nil then
		state = not Registry.favorites[def.Name]
	end
	Registry.favorites[def.Name] = state or nil
	if Pages.refreshFavorites then
		Pages.refreshFavorites()
	end
	return state
end

function Registry.describe(def)
	local lines = { def.Name .. " - " .. def.Description, "Usage: " .. def.Usage }
	if #def.Aliases > 0 then
		table.insert(lines, "Aliases: " .. table.concat(def.Aliases, ", "))
	end
	table.insert(lines, "Category: " .. def.Category)
	if def.Unavailable then
		table.insert(lines, "Unavailable: " .. def.Unavailable)
	end
	return table.concat(lines, "\n")
end

Console.history = {}
Console.buffer = {}
Console.output = nil

function Console.print(text, kind)
	kind = kind or "output"
	table.insert(Console.buffer, { text = tostring(text), kind = kind })
	while #Console.buffer > Config.MaxOutputLines do
		table.remove(Console.buffer, 1)
	end
	if Pages.appendOutput then
		Pages.appendOutput(tostring(text), kind)
	end
end

function Console.feedback(kind, text)
	local homeVisible = App.windowVisible and Pages.current == "Home"
	if not homeVisible then
		Notify.show(kind, string.sub(text, 1, 220))
	end
end

function Console.fail(text)
	Console.print(text, "error")
	Console.feedback("error", text)
	return false
end

function Console.pushHistory(line)
	if Console.history[#Console.history] ~= line then
		table.insert(Console.history, line)
	end
	while #Console.history > Prefs.historySize do
		table.remove(Console.history, 1)
	end
end

function Console.didYouMean(word)
	local lowered = word:lower()
	local scored = {}
	for _, def in ipairs(Registry.list) do
		local best = Util.distance(lowered, def.Name)
		if Util.startsWith(def.Name, lowered) then
			best = 0
		end
		if best <= 2 then
			table.insert(scored, { def = def, score = best })
		end
	end
	table.sort(scored, function(a, b)
		if a.score ~= b.score then
			return a.score < b.score
		end
		return a.def.Name < b.def.Name
	end)
	local names = {}
	for i = 1, math.min(4, #scored) do
		table.insert(names, scored[i].def.Name)
	end
	return names
end

function Console.execute(rawLine, source)
	local line = Util.trim(rawLine or "")
	if line == "" then
		return false
	end
	if #line > 300 then
		return Console.fail("That line is too long (300 characters maximum).")
	end
	if source == "user" then
		Console.pushHistory(line)
	end
	Console.print("> " .. line, "echo")

	local prefix = Prefs.prefix
	if prefix ~= "" and Util.startsWith(line, prefix) then
		line = Util.trim(line:sub(#prefix + 1))
	end
	local tokens, tokenError = Util.tokenize(line)
	if not tokens then
		return Console.fail(tokenError)
	end
	if #tokens == 0 then
		return Console.fail("Type a command. Try 'help'.")
	end

	local depth = 0
	while Registry.userAliases[tokens[1]:lower()] and depth < 5 do
		local expanded = Util.tokenize(Registry.userAliases[tokens[1]:lower()])
		if not expanded or #expanded == 0 then
			break
		end
		for i = 2, #tokens do
			table.insert(expanded, tokens[i])
		end
		tokens = expanded
		depth += 1
	end

	local def = Registry.find(tokens[1])
	if not def then
		local suggestions = Console.didYouMean(tokens[1])
		local text = ("Unknown command '%s'."):format(tokens[1]:sub(1, 30))
		if #suggestions > 0 then
			text ..= " Did you mean: " .. table.concat(suggestions, ", ") .. "?"
		else
			text ..= " Try 'commands' or 'search <text>'."
		end
		return Console.fail(text)
	end
	if def.Unavailable then
		Console.print("Unavailable: " .. def.Unavailable, "warning")
		Console.feedback("warning", "Unavailable: this needs an authorized server API.")
		return false
	end

	local values, argError = Registry.parseArgs(def, tokens)
	if not values then
		return Console.fail(argError)
	end

	local ok, first, second = pcall(def.Run, { def = def, source = source }, values)
	if not ok then
		warn("[Fxield] Command '" .. def.Name .. "' errored: " .. tostring(first))
		return Console.fail("The command hit an unexpected error and was stopped. Details are in the Output window.")
	end
	if first == false then
		return Console.fail(second or "The command did not complete.")
	end
	local message = type(first) == "string" and first or (type(second) == "string" and second or "Done.")
	Console.print(message, "output")
	Console.feedback("success", message)
	return true
end

function Console.argHint(def, argIndex)
	local spec = def.Args[argIndex]
	if not spec then
		return "Usage: " .. def.Usage
	end
	local detail = spec[2]
	if spec[2] == "enum" and spec.opts then
		detail = table.concat(spec.opts, " | ")
	elseif spec.min and spec.max then
		detail = ("%s %s to %s"):format(spec[2], tostring(spec.min), tostring(spec.max))
	end
	return ("%s: <%s> %s%s"):format(def.Name, spec[1], detail, spec.opt and " (optional)" or "")
end

function Console.suggest(text)
	local trimmed = text:gsub("^%s+", "")
	local prefix = Prefs.prefix
	if prefix ~= "" and Util.startsWith(trimmed, prefix) then
		trimmed = trimmed:sub(#prefix + 1)
	end
	local first, rest = trimmed:match("^(%S*)(.*)$")
	if rest ~= "" then
		local def = Registry.find(first)
		if def then
			local count = #Util.words(rest)
			if rest:match("%s$") then
				count += 1
			end
			return {}, Console.argHint(def, math.max(1, count))
		end
		return {}, nil
	end
	if first == "" then
		return {}, nil
	end
	local lowered = first:lower()
	local results, seen = {}, {}
	for _, def in ipairs(Registry.list) do
		if Util.startsWith(def.Name, lowered) and not seen[def] then
			seen[def] = true
			table.insert(results, def)
		end
	end
	for _, def in ipairs(Registry.list) do
		if not seen[def] then
			for _, alias in ipairs(def.Aliases) do
				if Util.startsWith(alias, lowered) then
					seen[def] = true
					table.insert(results, def)
					break
				end
			end
		end
	end
	for _, def in ipairs(Registry.list) do
		if not seen[def] and def.Name:find(lowered, 1, true) then
			seen[def] = true
			table.insert(results, def)
		end
	end
	local limited = {}
	for i = 1, math.min(4, #results) do
		table.insert(limited, results[i])
	end
	local hint = nil
	if #limited == 1 and limited[1].Name == lowered then
		hint = "Usage: " .. limited[1].Usage
	end
	return limited, hint
end

Session.startClock = os.clock()

function Session.camera()
	return workspace.CurrentCamera
end

function Session.humanoid()
	local character = LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

function Session.root()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function Session.findPlayers(text)
	local lowered = text:lower()
	if lowered == "me" then
		return { LocalPlayer }
	end
	local exact, partial = {}, {}
	for _, player in ipairs(Players:GetPlayers()) do
		local name, display = player.Name:lower(), player.DisplayName:lower()
		if name == lowered or display == lowered then
			table.insert(exact, player)
		elseif Util.startsWith(name, lowered) or Util.startsWith(display, lowered) then
			table.insert(partial, player)
		end
	end
	if #exact > 0 then
		return exact
	end
	return partial
end

function Session.pingMs()
	local ok, value = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if ok and type(value) == "number" then
		return value
	end
	return nil
end

function Session.platform()
	local parts = {}
	if UserInputService.TouchEnabled then
		table.insert(parts, "touch")
	end
	if UserInputService.KeyboardEnabled then
		table.insert(parts, "keyboard")
	end
	if UserInputService.MouseEnabled then
		table.insert(parts, "mouse")
	end
	if UserInputService.GamepadEnabled then
		table.insert(parts, "gamepad")
	end
	if UserInputService.VREnabled then
		table.insert(parts, "VR")
	end
	if GuiService:IsTenFootInterface() then
		table.insert(parts, "console interface")
	end
	if #parts == 0 then
		return "unknown"
	end
	return table.concat(parts, ", ")
end

function Session.measureFps(seconds, callback)
	local frames = 0
	local connection = RunService.Heartbeat:Connect(function()
		frames += 1
	end)
	Janitor.add(connection)
	Janitor.delay(seconds, function()
		connection:Disconnect()
		callback(frames / seconds)
	end)
end

function Session.describePlayer(player)
	local team = player.Team and player.Team.Name or "none"
	return ("%s (@%s) | id %d | account age %d days | team %s"):format(player.DisplayName, player.Name, player.UserId, player.AccountAge, team)
end

View.defaults = nil

function View.captureDefaults()
	local camera = Session.camera()
	local ok, defaults = pcall(function()
		return {
			fov = camera and camera.FieldOfView or 70,
			zoomMax = LocalPlayer.CameraMaxZoomDistance,
			zoomMin = LocalPlayer.CameraMinZoomDistance,
			cameraMode = LocalPlayer.CameraMode,
			occlusion = LocalPlayer.DevCameraOcclusionMode,
			mouseLock = LocalPlayer.DevEnableMouseLock,
		}
	end)
	View.defaults = ok and defaults or { fov = 70, zoomMax = 128, zoomMin = 0.5, cameraMode = Enum.CameraMode.Classic, occlusion = Enum.DevCameraOcclusionMode.Zoom, mouseLock = true }
end

function View.effect(className, name)
	local existing = Lighting:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end
	local effect = Instance.new(className)
	effect.Name = name
	effect.Parent = Lighting
	Janitor.add(effect)
	return effect
end

View.coreTypes = {
	chat = Enum.CoreGuiType.Chat,
	playerlist = Enum.CoreGuiType.PlayerList,
	backpack = Enum.CoreGuiType.Backpack,
	health = Enum.CoreGuiType.Health,
	emotes = Enum.CoreGuiType.EmotesMenu,
	all = Enum.CoreGuiType.All,
}

function Registry.numberPref(name, key, aliases, min, max, description, category)
	Registry.add({
		Name = name,
		Aliases = aliases,
		Category = category or "Appearance",
		Description = description,
		Args = { { "value", "number", opt = true, min = min, max = max } },
		Run = function(_, a)
			if a.value == nil then
				return ("%s is %s (allowed %s to %s)."):format(name, tostring(Prefs[key]), tostring(min), tostring(max))
			end
			App.setPref(key, a.value)
			return ("%s set to %s."):format(name, tostring(a.value))
		end,
	})
end

function Registry.boolPref(name, key, aliases, category, description)
	Registry.add({
		Name = name,
		Aliases = aliases,
		Category = category,
		Description = description,
		Args = { { "state", "bool", opt = true } },
		Run = function(_, a)
			local value = Util.resolveBool(a.state, Prefs[key])
			App.setPref(key, value)
			return ("%s is now %s."):format(name, value and "on" or "off")
		end,
	})
end

function Registry.enumPref(name, key, aliases, category, description, options)
	Registry.add({
		Name = name,
		Aliases = aliases,
		Category = category,
		Description = description,
		Args = { { "value", "enum", opt = true, opts = options } },
		Run = function(_, a)
			if a.value == nil then
				return ("%s is %s. Options: %s."):format(name, tostring(Prefs[key]), table.concat(options, ", "))
			end
			App.setPref(key, a.value)
			return ("%s set to %s."):format(name, a.value)
		end,
	})
end

function Registry.define.navigation()
	local add = Registry.add

	local function pageCommand(name, page, aliases, description)
		add({
			Name = name,
			Aliases = aliases,
			Category = "Navigation",
			Description = description,
			Run = function()
				App.showWindow()
				Pages.show(page)
				return "Opened the " .. page .. " page."
			end,
		})
	end

	pageCommand("home", "Home", { "dashboard" }, "Open the Home page with the command console.")
	pageCommand("browse", "Commands", { "cmdbrowser" }, "Open the searchable command browser.")
	pageCommand("settings", "Settings", { "prefs" }, "Open the Settings page.")
	pageCommand("themespage", "Themes", { "themegallery" }, "Open the Themes page.")
	pageCommand("helppage", "Help", { "manual" }, "Open the Help page.")
	pageCommand("playerspage", "Players", { "roster" }, "Open the read-only Players page.")

	add({
		Name = "page",
		Category = "Navigation",
		Description = "Open any page by name.",
		Args = { { "name", "enum", opts = Pages.names } },
		Run = function(_, a)
			App.showWindow()
			Pages.show(a.name)
			return "Opened the " .. a.name .. " page."
		end,
	})
	add({
		Name = "open",
		Aliases = { "show" },
		Category = "Navigation",
		Description = "Show the Fxield window.",
		Run = function()
			App.showWindow()
			return "Fxield is open."
		end,
	})
	add({
		Name = "close",
		Aliases = { "hide" },
		Category = "Navigation",
		Description = "Hide the window. Reopen it with the launcher button or the toggle key.",
		Run = function()
			App.hideWindow()
			return "Fxield hidden. Use the launcher button or your toggle key to reopen it."
		end,
	})
	add({
		Name = "minimize",
		Aliases = { "min" },
		Category = "Navigation",
		Description = "Collapse the window to its title bar.",
		Run = function()
			App.setMinimized(true)
			return "Window minimized."
		end,
	})
	add({
		Name = "restore",
		Aliases = { "unminimize" },
		Category = "Navigation",
		Description = "Restore the window from minimized or maximized.",
		Run = function()
			App.showWindow()
			App.setMaximized(false)
			App.setMinimized(false)
			return "Window restored."
		end,
	})
	add({
		Name = "maximize",
		Aliases = { "max" },
		Category = "Navigation",
		Description = "Fill the screen (inside the safe area), or go back to normal size.",
		Args = { { "state", "bool", opt = true } },
		Run = function(_, a)
			App.showWindow()
			local value = Util.resolveBool(a.state, App.maximized)
			App.setMaximized(value)
			return value and "Window maximized." or "Window returned to normal size."
		end,
	})
	add({
		Name = "togglewindow",
		Aliases = { "toggle" },
		Category = "Navigation",
		Description = "Show the window if hidden, hide it if shown.",
		Run = function()
			App.toggleWindow()
			return App.windowVisible and "Fxield shown." or "Fxield hidden."
		end,
	})
	add({
		Name = "center",
		Category = "Navigation",
		Description = "Move the window back to the middle of the screen.",
		Run = function()
			App.centerWindow()
			return "Window centered."
		end,
	})
	add({
		Name = "resetwindow",
		Category = "Navigation",
		Description = "Reset window size, position, layout mode and lock.",
		Run = function()
			App.resetWindow()
			return "Window reset."
		end,
	})
	add({
		Name = "lockwindow",
		Category = "Navigation",
		Description = "Stop the window from being dragged.",
		Run = function()
			App.setPref("locked", true)
			return "Window locked in place."
		end,
	})
	add({
		Name = "unlockwindow",
		Category = "Navigation",
		Description = "Allow the window to be dragged again.",
		Run = function()
			App.setPref("locked", false)
			return "Window can be dragged again."
		end,
	})
	add({
		Name = "windowsize",
		Category = "Navigation",
		Description = "Choose a window size preset on wide screens.",
		Args = { { "size", "enum", opts = { "small", "medium", "large" } } },
		Run = function(_, a)
			App.setPref("windowSize", a.size)
			return "Window size set to " .. a.size .. "."
		end,
	})
	add({
		Name = "unload",
		Aliases = { "shutdown", "quit" },
		Category = "Navigation",
		Description = "Remove Fxield completely: GUI, connections, timers and visual filters.",
		Run = function()
			UI.confirm("Remove Fxield from this session? You will need to rejoin or restart the script to bring it back.", function()
				App.destroy()
			end)
			return "Waiting for your confirmation."
		end,
	})
end

function Registry.define.appearance()
	local add = Registry.add

	add({
		Name = "theme",
		Category = "Appearance",
		Description = "Show or switch the interface theme.",
		Args = { { "name", "enum", opt = true, opts = Theme.order } },
		Run = function(_, a)
			if not a.name then
				return ("Current theme: %s. Available: %s."):format(Theme.name, table.concat(Theme.order, ", "))
			end
			App.setPref("theme", a.name)
			return "Theme set to " .. a.name .. "."
		end,
	})
	add({
		Name = "themelist",
		Category = "Appearance",
		Description = "List all themes and mark the active one.",
		Run = function()
			local lines = {}
			for _, name in ipairs(Theme.order) do
				table.insert(lines, (name == Theme.name and "* " or "  ") .. name)
			end
			return table.concat(lines, "\n")
		end,
	})
	add({
		Name = "themenext",
		Category = "Appearance",
		Description = "Switch to the next theme.",
		Run = function()
			return "Theme: " .. Theme.cycle(1)
		end,
	})
	add({
		Name = "themeprev",
		Category = "Appearance",
		Description = "Switch to the previous theme.",
		Run = function()
			return "Theme: " .. Theme.cycle(-1)
		end,
	})
	add({
		Name = "themepreview",
		Category = "Appearance",
		Description = "Try a theme without keeping it. Use themeapply or themecancel afterwards.",
		Args = { { "name", "enum", opts = Theme.order } },
		Run = function(_, a)
			Theme.preview(a.name)
			return "Previewing " .. a.name .. ". Use themeapply to keep it or themecancel to go back."
		end,
	})
	add({
		Name = "themeapply",
		Category = "Appearance",
		Description = "Keep the theme you are previewing.",
		Run = function()
			if not Theme.previewName then
				return false, "No theme is being previewed."
			end
			local name = Theme.previewName
			Theme.commitPreview()
			return "Theme set to " .. name .. "."
		end,
	})
	add({
		Name = "themecancel",
		Category = "Appearance",
		Description = "Stop previewing and go back to the active theme.",
		Run = function()
			if not Theme.previewName then
				return false, "No theme is being previewed."
			end
			Theme.cancelPreview()
			return "Preview cancelled."
		end,
	})
	add({
		Name = "themereset",
		Category = "Appearance",
		Description = "Back to the default Midnight theme and accent.",
		Run = function()
			Theme.cancelPreview()
			App.setPref("theme", Config.DefaultTheme)
			App.setPref("accent", "")
			return "Theme reset to " .. Config.DefaultTheme .. "."
		end,
	})
	add({
		Name = "accent",
		Category = "Appearance",
		Description = "Show or set a custom accent color for the active theme.",
		Args = { { "hex", "color", opt = true } },
		Run = function(_, a)
			if not a.hex then
				return Prefs.accent == "" and "Using the theme's own accent color." or ("Custom accent: " .. Prefs.accent)
			end
			App.setPref("accent", a.hex)
			return "Accent set to " .. a.hex .. "."
		end,
	})
	add({
		Name = "accentreset",
		Category = "Appearance",
		Description = "Remove the custom accent and use the theme's own.",
		Run = function()
			App.setPref("accent", "")
			return "Accent reset."
		end,
	})

	Registry.numberPref("uiscale", "uiScale", { "guiscale", "scale" }, 0.7, 1.6, "Scale the whole interface (0.7 to 1.6).")
	Registry.numberPref("textscale", "textScale", { "fontscale" }, 0.8, 1.6, "Scale all text (0.8 to 1.6).")
	Registry.numberPref("transparency", "transparency", { "opacity" }, 0, 0.5, "Make the window background slightly see-through (0 to 0.5).")
	Registry.numberPref("cornerradius", "cornerRadius", { "rounding" }, 0, 20, "Set how rounded panels and buttons are (0 to 20).")
	Registry.boolPref("reducemotion", "reduceMotion", { "calm" }, "Appearance", "Turn animations off or on.")
	Registry.enumPref("compact", "compact", { "layoutmode" }, "Appearance", "Layout mode: auto picks by screen width, always forces the phone layout.", { "auto", "always", "never" })
	Registry.enumPref("touchtargets", "touchTargets", { "buttonsize" }, "Appearance", "Make buttons and inputs larger for touch.", { "normal", "large" })
	Registry.enumPref("font", "font", { "typeface" }, "Appearance", "Choose the interface font family.", Style.familyOrder)

	add({
		Name = "highcontrast",
		Category = "Appearance",
		Description = "Switch the High Contrast theme on or off.",
		Args = { { "state", "bool", opt = true } },
		Run = function(_, a)
			local on = Util.resolveBool(a.state, Theme.name == "High Contrast")
			if on then
				if Theme.name ~= "High Contrast" then
					App.previousTheme = Theme.name
				end
				App.setPref("theme", "High Contrast")
				return "High Contrast theme on."
			end
			App.setPref("theme", App.previousTheme or Config.DefaultTheme)
			return "High Contrast theme off."
		end,
	})
end

function Registry.define.accessibility()
	local add = Registry.add

	add({
		Name = "a11ypreset",
		Aliases = { "accessibility" },
		Category = "Accessibility",
		Description = "Apply a combined accessibility preset.",
		Args = { { "preset", "enum", opts = { "default", "large", "contrast", "reduced" } } },
		Run = function(_, a)
			if a.preset == "default" then
				App.setPref("textScale", 1)
				App.setPref("uiScale", 1)
				App.setPref("touchTargets", "normal")
				App.setPref("reduceMotion", false)
				App.setPref("theme", Config.DefaultTheme)
			elseif a.preset == "large" then
				App.setPref("textScale", 1.3)
				App.setPref("uiScale", 1.15)
				App.setPref("touchTargets", "large")
			elseif a.preset == "contrast" then
				App.setPref("theme", "High Contrast")
				App.setPref("textScale", 1.15)
				App.setPref("transparency", 0)
			else
				App.setPref("reduceMotion", true)
			end
			return "Applied the " .. a.preset .. " accessibility preset."
		end,
	})
	Registry.boolPref("tooltips", "tooltips", { "hints" }, "Accessibility", "Show hover tooltips on desktop.")
	Registry.boolPref("autocomplete", "autocomplete", { "suggestions" }, "Accessibility", "Show command suggestions while you type.")

	add({
		Name = "togglekey",
		Category = "Accessibility",
		Description = "Show or change the keyboard key that opens and hides Fxield.",
		Args = { { "key", "key", opt = true } },
		Run = function(_, a)
			if not a.key then
				return "The toggle key is " .. Prefs.toggleKey .. "."
			end
			if Registry.binds[a.key] then
				return false, a.key .. " is already used by a bind. Use unbind first."
			end
			App.setPref("toggleKey", a.key)
			return "Toggle key set to " .. a.key .. "."
		end,
	})
	add({
		Name = "prefix",
		Category = "Accessibility",
		Description = "Show or change the optional command prefix (up to 3 characters, or none).",
		Args = { { "value", "string", opt = true, max = 3 } },
		Run = function(_, a)
			if not a.value then
				return Prefs.prefix == "" and "No prefix is set." or ("The prefix is " .. Prefs.prefix)
			end
			if a.value:lower() == "none" then
				App.setPref("prefix", "")
				return "Prefix removed."
			end
			App.setPref("prefix", a.value)
			return "Prefix set to " .. a.value
		end,
	})
	add({
		Name = "bind",
		Category = "Accessibility",
		Description = "Run a command when you press a key (while no text box is focused).",
		Args = { { "key", "key" }, { "command", "text", max = 120 } },
		Run = function(_, a)
			if a.key == Prefs.toggleKey then
				return false, a.key .. " is the toggle key. Pick another key."
			end
			local count = 0
			for _ in pairs(Registry.binds) do
				count += 1
			end
			if count >= 20 and not Registry.binds[a.key] then
				return false, "You can have at most 20 binds."
			end
			local first = Util.words(a.command)[1]
			if not first or not (Registry.find(first) or Registry.userAliases[first:lower()]) then
				return false, "'" .. tostring(first) .. "' is not a known command."
			end
			Registry.binds[a.key] = a.command
			return ("%s now runs: %s"):format(a.key, a.command)
		end,
	})
	add({
		Name = "unbind",
		Category = "Accessibility",
		Description = "Remove the command bound to a key.",
		Args = { { "key", "key" } },
		Run = function(_, a)
			if not Registry.binds[a.key] then
				return false, a.key .. " has no bind."
			end
			Registry.binds[a.key] = nil
			return "Removed the bind on " .. a.key .. "."
		end,
	})
	add({
		Name = "binds",
		Category = "Accessibility",
		Description = "List your key binds.",
		Run = function()
			local lines = {}
			for key, command in pairs(Registry.binds) do
				table.insert(lines, key .. " -> " .. command)
			end
			table.sort(lines)
			return #lines > 0 and table.concat(lines, "\n") or "No binds yet. Try: bind F5 fps"
		end,
	})
	add({
		Name = "clearbinds",
		Category = "Accessibility",
		Description = "Remove every key bind.",
		Run = function()
			table.clear(Registry.binds)
			return "All binds removed."
		end,
	})
	add({
		Name = "alias",
		Category = "Accessibility",
		Description = "Create your own short name for a command line.",
		Args = { { "name", "string", max = 24 }, { "command", "text", max = 120 } },
		Run = function(_, a)
			if not a.name:match("^[%w_]+$") then
				return false, "Alias names may only use letters, numbers and underscores."
			end
			if Registry.byName[a.name:lower()] then
				return false, a.name .. " is already a command or alias name."
			end
			local count = 0
			for _ in pairs(Registry.userAliases) do
				count += 1
			end
			if count >= 30 and not Registry.userAliases[a.name:lower()] then
				return false, "You can have at most 30 aliases."
			end
			local first = Util.words(a.command)[1]
			if not first or not Registry.find(first) then
				return false, "The alias must start with a real command."
			end
			Registry.userAliases[a.name:lower()] = a.command
			return ("%s now runs: %s"):format(a.name, a.command)
		end,
	})
	add({
		Name = "unalias",
		Category = "Accessibility",
		Description = "Delete one of your aliases.",
		Args = { { "name", "string", max = 24 } },
		Run = function(_, a)
			if not Registry.userAliases[a.name:lower()] then
				return false, "You have no alias called " .. a.name .. "."
			end
			Registry.userAliases[a.name:lower()] = nil
			return "Alias removed."
		end,
	})
	add({
		Name = "aliases",
		Category = "Accessibility",
		Description = "List your aliases.",
		Run = function()
			local lines = {}
			for name, command in pairs(Registry.userAliases) do
				table.insert(lines, name .. " -> " .. command)
			end
			table.sort(lines)
			return #lines > 0 and table.concat(lines, "\n") or "No aliases yet. Try: alias sp \"playerinfo me\""
		end,
	})
	add({
		Name = "clearaliases",
		Category = "Accessibility",
		Description = "Delete every alias.",
		Run = function()
			table.clear(Registry.userAliases)
			return "All aliases removed."
		end,
	})
end

function Registry.define.console()
	local add = Registry.add

	add({
		Name = "help",
		Aliases = { "?" },
		Category = "Console",
		Description = "Show a short guide, or details for one command.",
		Args = { { "command", "string", opt = true } },
		Run = function(_, a)
			if not a.command then
				return table.concat({
					("Fxield %s runs only on your device."):format(Config.Version),
					"Type a command and press Enter or Run. Quotes group words, for example: notify \"hello there\".",
					"Useful: commands (all names), search <text>, category <name>, help <command>, theme <name>.",
					"Actions that change the shared game need an authorized server API and are listed as 'Needs server'.",
				}, "\n")
			end
			local def = Registry.find(a.command)
			if not def then
				local suggestions = Console.didYouMean(a.command)
				return false, "No command called '" .. a.command .. "'." .. (#suggestions > 0 and (" Did you mean: " .. table.concat(suggestions, ", ") .. "?") or "")
			end
			return Registry.describe(def)
		end,
	})
	add({
		Name = "commands",
		Aliases = { "cmds" },
		Category = "Console",
		Description = "List every command name, grouped by category.",
		Run = function()
			local lines = {}
			for _, category in ipairs(Registry.categoryOrder) do
				local names = {}
				for _, def in ipairs(Registry.list) do
					if def.Category == category then
						table.insert(names, def.Name)
					end
				end
				table.insert(lines, category .. ": " .. table.concat(names, ", "))
			end
			return table.concat(lines, "\n")
		end,
	})
	add({
		Name = "search",
		Aliases = { "find" },
		Category = "Console",
		Description = "Search command names, aliases, categories and descriptions.",
		Args = { { "text", "text", max = 60 } },
		Run = function(_, a)
			local needle = a.text:lower()
			local lines = {}
			for _, def in ipairs(Registry.list) do
				local haystack = (def.Name .. " " .. table.concat(def.Aliases, " ") .. " " .. def.Category .. " " .. def.Description):lower()
				if haystack:find(needle, 1, true) then
					table.insert(lines, def.Name .. " - " .. def.Description)
					if #lines >= 25 then
						table.insert(lines, "(showing the first 25 matches)")
						break
					end
				end
			end
			if #lines == 0 then
				return false, "Nothing matches '" .. a.text .. "'."
			end
			return table.concat(lines, "\n")
		end,
	})
	add({
		Name = "categories",
		Category = "Console",
		Description = "List command categories with how many commands each has.",
		Run = function()
			local lines = {}
			for _, category in ipairs(Registry.categoryOrder) do
				table.insert(lines, ("%s (%d)"):format(category, Registry.categoryCounts[category]))
			end
			return table.concat(lines, "\n")
		end,
	})
	add({
		Name = "category",
		Category = "Console",
		Description = "Show every command in one category with its description.",
		Args = { { "name", "string" } },
		Run = function(_, a)
			local wanted = Util.normalizeKey(a.name)
			local lines = {}
			for _, def in ipairs(Registry.list) do
				if Util.normalizeKey(def.Category) == wanted then
					table.insert(lines, def.Name .. " - " .. def.Description)
				end
			end
			if #lines == 0 then
				return false, "No category called '" .. a.name .. "'. Try: categories"
			end
			return table.concat(lines, "\n")
		end,
	})
	add({
		Name = "count",
		Category = "Console",
		Description = "Count registered commands and how many work on this device.",
		Run = function()
			local total = #Registry.list
			local available = Registry.available()
			return ("%d commands registered: %d work on this device, %d need an authorized server API."):format(total, available, total - available)
		end,
	})
	add({
		Name = "unavailable",
		Category = "Console",
		Description = "List the commands that are disabled and why.",
		Run = function()
			local names = {}
			local reason
			for _, def in ipairs(Registry.list) do
				if def.Unavailable then
					table.insert(names, def.Name)
					reason = reason or def.Unavailable
				end
			end
			return table.concat(names, ", ") .. "\n" .. tostring(reason)
		end,
	})
	add({
		Name = "history",
		Category = "Console",
		Description = "Show your most recent commands (up and down arrows also browse them).",
		Run = function()
			if #Console.history == 0 then
				return "History is empty."
			end
			local lines = {}
			for i = math.max(1, #Console.history - 19), #Console.history do
				table.insert(lines, ("%d. %s"):format(i, Console.history[i]))
			end
			return table.concat(lines, "\n")
		end,
	})
	add({
		Name = "clearhistory",
		Category = "Console",
		Description = "Forget your command history.",
		Run = function()
			table.clear(Console.history)
			return "History cleared."
		end,
	})
	add({
		Name = "run",
		Category = "Console",
		Description = "Run a numbered entry from your history again.",
		Args = { { "number", "integer", min = 1 } },
		Run = function(ctx, a)
			local line = Console.history[a.number]
			if not line then
				return false, "There is no history entry " .. a.number .. "."
			end
			local first = Util.words(line)[1] or ""
			if first:lower() == "run" or first:lower() == "repeat" then
				return false, "That entry would only repeat itself."
			end
			Console.execute(line, "history")
			return "Ran: " .. line
		end,
	})
	add({
		Name = "repeat",
		Aliases = { "again" },
		Category = "Console",
		Description = "Run your previous command again.",
		Run = function()
			local line = Console.history[#Console.history - 1]
			if not line then
				return false, "There is no earlier command to repeat."
			end
			local first = Util.words(line)[1] or ""
			if first:lower() == "run" or first:lower() == "repeat" or first:lower() == "again" then
				return false, "The previous command cannot be repeated."
			end
			Console.execute(line, "history")
			return "Repeated: " .. line
		end,
	})
	add({
		Name = "historysize",
		Category = "Console",
		Description = "Set how many commands history keeps (5 to 200).",
		Args = { { "count", "integer", opt = true, min = 5, max = 200 } },
		Run = function(_, a)
			if not a.count then
				return "History keeps " .. Prefs.historySize .. " commands."
			end
			App.setPref("historySize", a.count)
			while #Console.history > a.count do
				table.remove(Console.history, 1)
			end
			return "History size set to " .. a.count .. "."
		end,
	})
	add({
		Name = "fav",
		Aliases = { "star" },
		Category = "Console",
		Description = "Add a command to your favorites.",
		Args = { { "command", "string" } },
		Run = function(_, a)
			local def = Registry.find(a.command)
			if not def then
				return false, "No command called '" .. a.command .. "'."
			end
			Registry.toggleFavorite(def.Name, true)
			return def.Name .. " added to favorites."
		end,
	})
	add({
		Name = "unfav",
		Aliases = { "unstar" },
		Category = "Console",
		Description = "Remove a command from your favorites.",
		Args = { { "command", "string" } },
		Run = function(_, a)
			local def = Registry.find(a.command)
			if not def or not Registry.favorites[def.Name] then
				return false, "That command is not in your favorites."
			end
			Registry.toggleFavorite(def.Name, false)
			return def.Name .. " removed from favorites."
		end,
	})
	add({
		Name = "favorites",
		Aliases = { "favs" },
		Category = "Console",
		Description = "List your favorite commands.",
		Run = function()
			local names = {}
			for name in pairs(Registry.favorites) do
				table.insert(names, name)
			end
			table.sort(names)
			return #names > 0 and table.concat(names, ", ") or "No favorites yet. Use fav <command> or tap the star in the browser."
		end,
	})
	add({
		Name = "clearfavorites",
		Category = "Console",
		Description = "Remove every favorite.",
		Run = function()
			table.clear(Registry.favorites)
			Pages.refreshFavorites()
			return "Favorites cleared."
		end,
	})
	add({
		Name = "clear",
		Aliases = { "cls" },
		Category = "Console",
		Description = "Clear the console output on the Home page.",
		Run = function()
			table.clear(Console.buffer)
			Pages.clearOutput()
			return nil
		end,
	})
end

function Registry.define.notifications()
	local add = Registry.add

	local function toastCommand(name, kind, description)
		add({
			Name = name,
			Category = "Notifications",
			Description = description,
			Args = { { "text", "text", max = 160 } },
			Run = function(_, a)
				if not Prefs.notifications then
					return false, "Notifications are muted. Use: notifications on"
				end
				Notify.show(kind, a.text)
				return "Notification shown."
			end,
		})
	end

	toastCommand("notify", "info", "Show a local notification on your own screen.")
	toastCommand("notifysuccess", "success", "Show a green success notification locally.")
	toastCommand("notifywarn", "warning", "Show an amber warning notification locally.")
	toastCommand("notifyerror", "error", "Show a red error notification locally.")
	Registry.boolPref("notifications", "notifications", { "toasts" }, "Notifications", "Turn local notifications on or off.")
	Registry.numberPref("notifyduration", "notifySeconds", {}, 1, 30, "How long notifications stay (1 to 30 seconds).", "Notifications")
	Registry.numberPref("notifylimit", "notifyLimit", {}, 1, 8, "How many notifications can show at once (1 to 8).", "Notifications")
	Registry.enumPref("notifyposition", "notifyPosition", {}, "Notifications", "Where notifications appear.", { "topright", "topleft", "bottom" })
	add({
		Name = "clearnotifications",
		Aliases = { "dismissall" },
		Category = "Notifications",
		Description = "Dismiss every notification on screen.",
		Run = function()
			Notify.clear()
			return "Notifications cleared."
		end,
	})
end

Session.timers = {}
Session.nextTimer = 0
Session.stopwatch = { running = false, started = 0, elapsed = 0, laps = {} }

Util.units = {
	length = { mm = 0.001, cm = 0.01, m = 1, km = 1000, ["in"] = 0.0254, ft = 0.3048, yd = 0.9144, mi = 1609.344, stud = 0.28, studs = 0.28 },
	mass = { mg = 0.000001, g = 0.001, kg = 1, oz = 0.028349523125, lb = 0.45359237 },
	time = { ms = 0.001, s = 1, sec = 1, min = 60, h = 3600, d = 86400 },
}

function Util.convertUnits(value, from, to)
	from, to = from:lower(), to:lower()
	local temperature = { c = true, f = true, k = true }
	if temperature[from] and temperature[to] then
		local celsius = value
		if from == "f" then
			celsius = (value - 32) * 5 / 9
		elseif from == "k" then
			celsius = value - 273.15
		end
		if to == "f" then
			return celsius * 9 / 5 + 32
		elseif to == "k" then
			return celsius + 273.15
		end
		return celsius
	end
	for _, table_ in pairs(Util.units) do
		if table_[from] and table_[to] then
			return value * table_[from] / table_[to]
		end
	end
	return nil
end

function Util.parseNumbers(text)
	local numbers = {}
	for word in text:gmatch("[^%s,]+") do
		local n = tonumber(word)
		if not Util.isFinite(n) then
			return nil, "'" .. word .. "' is not a number."
		end
		table.insert(numbers, n)
		if #numbers > 200 then
			return nil, "Use at most 200 numbers."
		end
	end
	if #numbers == 0 then
		return nil, "Give at least one number."
	end
	return numbers
end

function Util.gcd(a, b)
	a, b = math.abs(a), math.abs(b)
	while b ~= 0 do
		a, b = b, a % b
	end
	return a
end

function Util.toBinary(n)
	if n == 0 then
		return "0"
	end
	local bits = {}
	while n > 0 do
		table.insert(bits, 1, tostring(n % 2))
		n = n // 2
	end
	return table.concat(bits)
end

function Session.timerCount()
	local count = 0
	for _ in pairs(Session.timers) do
		count += 1
	end
	return count
end

function Registry.define.session()
	local add = Registry.add

	add({
		Name = "me",
		Category = "Session",
		Description = "Show your own account details (read-only).",
		Run = function()
			return Session.describePlayer(LocalPlayer)
		end,
	})
	add({
		Name = "membership",
		Category = "Session",
		Description = "Show your Roblox membership type.",
		Run = function()
			local ok, value = pcall(function()
				return LocalPlayer.MembershipType.Name
			end)
			return ok and ("Membership: " .. value) or false, "Membership information is not available."
		end,
	})
	add({
		Name = "platform",
		Category = "Session",
		Description = "Show which input devices this device reports.",
		Run = function()
			return "Input devices: " .. Session.platform()
		end,
	})
	add({
		Name = "lastinput",
		Category = "Session",
		Description = "Show the kind of input you used most recently.",
		Run = function()
			return "Last input type: " .. UserInputService:GetLastInputType().Name
		end,
	})
	add({
		Name = "locale",
		Category = "Session",
		Description = "Show Roblox and system language settings.",
		Run = function()
			return ("Roblox locale: %s | System locale: %s"):format(LocalizationService.RobloxLocaleId, LocalizationService.SystemLocaleId)
		end,
	})
	add({
		Name = "ping",
		Category = "Session",
		Description = "Show your current network ping to the server.",
		Run = function()
			local ms = Session.pingMs()
			if not ms then
				return false, "Ping is not available right now."
			end
			return ("Ping: %.0f ms"):format(ms)
		end,
	})
	add({
		Name = "fps",
		Category = "Session",
		Description = "Measure your frame rate for one second.",
		Run = function()
			Session.measureFps(1, function(value)
				local text = ("Frame rate: %.0f FPS (measured over 1 second)."):format(value)
				Console.print(text, "output")
				Console.feedback("info", text)
			end)
			return "Measuring for one second..."
		end,
	})
	add({
		Name = "memory",
		Category = "Session",
		Description = "Show client memory use reported by Roblox.",
		Run = function()
			local ok, value = pcall(function()
				return Stats:GetTotalMemoryUsageMb()
			end)
			if not ok then
				return false, "Memory statistics are not available."
			end
			return ("Client memory: %.0f MB"):format(value)
		end,
	})
	add({
		Name = "playercount",
		Category = "Session",
		Description = "Show how many players are in this server.",
		Run = function()
			return ("%d of %d players"):format(#Players:GetPlayers(), Players.MaxPlayers)
		end,
	})
	add({
		Name = "players",
		Category = "Session",
		Description = "List the players in this server (read-only).",
		Run = function()
			local names = {}
			for _, player in ipairs(Players:GetPlayers()) do
				table.insert(names, player.DisplayName == player.Name and player.Name or (player.DisplayName .. " (@" .. player.Name .. ")"))
				if #names >= 40 then
					table.insert(names, "...")
					break
				end
			end
			return table.concat(names, "\n")
		end,
	})
	add({
		Name = "playerinfo",
		Aliases = { "pinfo" },
		Category = "Session",
		Description = "Show public details for one player (read-only).",
		Args = { { "player", "player" } },
		Run = function(_, a)
			if a.player.Parent == nil then
				return false, "That player already left."
			end
			return Session.describePlayer(a.player)
		end,
	})
	add({
		Name = "findplayer",
		Category = "Session",
		Description = "Find players whose name starts with some text.",
		Args = { { "text", "string" } },
		Run = function(_, a)
			local matches = Session.findPlayers(a.text)
			if #matches == 0 then
				return false, "No player matches '" .. a.text .. "'."
			end
			local names = {}
			for _, player in ipairs(matches) do
				table.insert(names, player.Name)
			end
			return table.concat(names, ", ")
		end,
	})
	add({
		Name = "placeid",
		Category = "Session",
		Description = "Show this place's PlaceId.",
		Run = function()
			return "PlaceId: " .. game.PlaceId
		end,
	})
	add({
		Name = "gameid",
		Category = "Session",
		Description = "Show this experience's GameId.",
		Run = function()
			return "GameId: " .. game.GameId
		end,
	})
	add({
		Name = "jobid",
		Category = "Session",
		Description = "Show the JobId of this server instance.",
		Run = function()
			return "JobId: " .. (game.JobId == "" and "(empty in Studio)" or game.JobId)
		end,
	})
	add({
		Name = "placeversion",
		Category = "Session",
		Description = "Show the published version of this place.",
		Run = function()
			return "Place version: " .. game.PlaceVersion
		end,
	})
	add({
		Name = "placename",
		Category = "Session",
		Description = "Look up this place's name from Roblox.",
		Run = function()
			task.spawn(function()
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfo(game.PlaceId)
				end)
				if ok and info and info.Name then
					Console.print("Place name: " .. info.Name, "output")
				else
					Console.print("Could not look up the place name (the place may be unpublished).", "warning")
				end
			end)
			return "Looking up the place name..."
		end,
	})
	add({
		Name = "servertype",
		Category = "Session",
		Description = "Say whether this is a standard, private or reserved server.",
		Run = function()
			if game.PrivateServerId == "" then
				return "Standard public server."
			elseif game.PrivateServerOwnerId ~= 0 then
				return "Private (VIP) server."
			end
			return "Reserved server."
		end,
	})
	add({
		Name = "servertime",
		Category = "Session",
		Description = "Show how long this server has been running (as seen by your client).",
		Run = function()
			return "Server time: " .. Util.formatDuration(workspace.DistributedGameTime)
		end,
	})
	add({
		Name = "sessiontime",
		Category = "Session",
		Description = "Show how long Fxield has been running for you.",
		Run = function()
			return "Fxield session time: " .. Util.formatDuration(os.clock() - Session.startClock)
		end,
	})
	add({
		Name = "localtime",
		Category = "Session",
		Description = "Show your device's local date and time.",
		Run = function()
			return os.date("%Y-%m-%d %H:%M:%S")
		end,
	})
	add({
		Name = "utctime",
		Category = "Session",
		Description = "Show the current UTC date and time.",
		Run = function()
			return os.date("!%Y-%m-%d %H:%M:%S") .. " UTC"
		end,
	})
	add({
		Name = "viewport",
		Category = "Session",
		Description = "Show the camera viewport size in pixels.",
		Run = function()
			local camera = Session.camera()
			if not camera then
				return false, "No camera is available."
			end
			local size = camera.ViewportSize
			return ("Viewport: %d x %d pixels"):format(size.X, size.Y)
		end,
	})
	add({
		Name = "safeinsets",
		Category = "Session",
		Description = "Show the top and bottom interface insets Roblox reports.",
		Run = function()
			local topLeft, bottomRight = GuiService:GetGuiInset()
			return ("Top-left inset: %d, %d | Bottom-right inset: %d, %d"):format(topLeft.X, topLeft.Y, bottomRight.X, bottomRight.Y)
		end,
	})
	add({
		Name = "quality",
		Category = "Session",
		Description = "Show your saved graphics quality setting (read-only).",
		Run = function()
			local ok, value = pcall(function()
				return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Name
			end)
			if not ok then
				return false, "Graphics settings are not readable here."
			end
			return "Saved quality level: " .. value
		end,
	})
	add({
		Name = "charstate",
		Category = "Session",
		Description = "Show your character's health and state (read-only).",
		Run = function()
			local humanoid = Session.humanoid()
			if not humanoid then
				return false, "You have no character right now."
			end
			return ("State: %s | Health: %.0f / %.0f | WalkSpeed: %.1f"):format(humanoid:GetState().Name, humanoid.Health, humanoid.MaxHealth, humanoid.WalkSpeed)
		end,
	})
	add({
		Name = "position",
		Category = "Session",
		Description = "Show where your character is (read-only).",
		Run = function()
			local root = Session.root()
			if not root then
				return false, "You have no character right now."
			end
			local p = root.Position
			return ("Position: %.1f, %.1f, %.1f"):format(p.X, p.Y, p.Z)
		end,
	})
end

function Registry.define.camera()
	local add = Registry.add

	add({
		Name = "fov",
		Category = "Camera",
		Description = "Show or set your field of view (30 to 120). Affects only your own view.",
		Args = { { "degrees", "number", opt = true, min = 30, max = 120 } },
		Run = function(_, a)
			local camera = Session.camera()
			if not camera then
				return false, "No camera is available."
			end
			if a.degrees == nil then
				return ("Field of view: %.0f"):format(camera.FieldOfView)
			end
			camera.FieldOfView = a.degrees
			return ("Field of view set to %.0f. The game's own camera scripts may change it again."):format(a.degrees)
		end,
	})
	add({
		Name = "fovreset",
		Category = "Camera",
		Description = "Put the field of view back to what it was when Fxield started.",
		Run = function()
			local camera = Session.camera()
			if not camera then
				return false, "No camera is available."
			end
			camera.FieldOfView = View.defaults.fov
			return ("Field of view restored to %.0f."):format(View.defaults.fov)
		end,
	})
	add({
		Name = "zoommax",
		Category = "Camera",
		Description = "Show or set how far you may zoom out (5 to 1000 studs), if the game allows it.",
		Args = { { "studs", "number", opt = true, min = 5, max = 1000 } },
		Run = function(_, a)
			if a.studs == nil then
				return "Maximum zoom distance: " .. LocalPlayer.CameraMaxZoomDistance
			end
			if a.studs < LocalPlayer.CameraMinZoomDistance then
				return false, "That is smaller than the minimum zoom distance."
			end
			LocalPlayer.CameraMaxZoomDistance = a.studs
			return "Maximum zoom distance set to " .. a.studs .. "."
		end,
	})
	add({
		Name = "zoommin",
		Category = "Camera",
		Description = "Show or set how close you may zoom in (0.5 to 100 studs), if the game allows it.",
		Args = { { "studs", "number", opt = true, min = 0.5, max = 100 } },
		Run = function(_, a)
			if a.studs == nil then
				return "Minimum zoom distance: " .. LocalPlayer.CameraMinZoomDistance
			end
			if a.studs > LocalPlayer.CameraMaxZoomDistance then
				return false, "That is larger than the maximum zoom distance."
			end
			LocalPlayer.CameraMinZoomDistance = a.studs
			return "Minimum zoom distance set to " .. a.studs .. "."
		end,
	})
	add({
		Name = "zoomreset",
		Category = "Camera",
		Description = "Restore the original zoom limits.",
		Run = function()
			LocalPlayer.CameraMinZoomDistance = View.defaults.zoomMin
			LocalPlayer.CameraMaxZoomDistance = View.defaults.zoomMax
			return "Zoom limits restored."
		end,
	})
	add({
		Name = "camerastyle",
		Category = "Camera",
		Description = "Choose classic third person or locked first person camera.",
		Args = { { "style", "enum", opts = { "classic", "firstperson" } } },
		Run = function(_, a)
			LocalPlayer.CameraMode = a.style == "classic" and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson
			return "Camera style set to " .. a.style .. "."
		end,
	})
	add({
		Name = "occlusion",
		Category = "Camera",
		Description = "Choose how the camera handles walls: zoom in, or see through them (invisicam).",
		Args = { { "mode", "enum", opts = { "zoom", "invisicam" } } },
		Run = function(_, a)
			LocalPlayer.DevCameraOcclusionMode = a.mode == "zoom" and Enum.DevCameraOcclusionMode.Zoom or Enum.DevCameraOcclusionMode.Invisicam
			return "Camera occlusion mode: " .. a.mode .. "."
		end,
	})
	add({
		Name = "shiftlock",
		Category = "Camera",
		Description = "Allow or disallow the shift lock (mouse lock) control for yourself.",
		Args = { { "state", "bool", opt = true } },
		Run = function(_, a)
			local value = Util.resolveBool(a.state, LocalPlayer.DevEnableMouseLock)
			LocalPlayer.DevEnableMouseLock = value
			return "Shift lock is " .. (value and "allowed." or "disallowed.")
		end,
	})
	add({
		Name = "camerareset",
		Category = "Camera",
		Description = "Restore field of view, zoom limits, camera style and occlusion mode.",
		Run = function()
			local camera = Session.camera()
			if camera then
				camera.FieldOfView = View.defaults.fov
			end
			LocalPlayer.CameraMinZoomDistance = View.defaults.zoomMin
			LocalPlayer.CameraMaxZoomDistance = View.defaults.zoomMax
			LocalPlayer.CameraMode = View.defaults.cameraMode
			LocalPlayer.DevCameraOcclusionMode = View.defaults.occlusion
			LocalPlayer.DevEnableMouseLock = View.defaults.mouseLock
			return "Camera preferences restored."
		end,
	})
	add({
		Name = "resetview",
		Category = "Camera",
		Description = "Point the camera back at your character.",
		Run = function()
			local camera = Session.camera()
			local humanoid = Session.humanoid()
			if not camera or not humanoid then
				return false, "There is no camera or character to reset."
			end
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
			return "Camera is following your character."
		end,
	})
	add({
		Name = "camerainfo",
		Category = "Camera",
		Description = "Show the camera's type, subject and field of view (read-only).",
		Run = function()
			local camera = Session.camera()
			if not camera then
				return false, "No camera is available."
			end
			local subject = camera.CameraSubject and camera.CameraSubject.ClassName or "none"
			return ("Type: %s | Subject: %s | FOV: %.0f | Zoom limits: %s to %s"):format(camera.CameraType.Name, subject, camera.FieldOfView, tostring(LocalPlayer.CameraMinZoomDistance), tostring(LocalPlayer.CameraMaxZoomDistance))
		end,
	})
	add({
		Name = "coregui",
		Category = "Camera",
		Description = "Show or hide a built-in Roblox interface element for yourself.",
		Args = { { "element", "enum", opts = { "chat", "playerlist", "backpack", "health", "emotes", "all" } }, { "state", "bool", opt = true } },
		Run = function(_, a)
			local coreType = View.coreTypes[a.element]
			local current = true
			local readable, value = pcall(function()
				return StarterGui:GetCoreGuiEnabled(coreType)
			end)
			if readable then
				current = value
			end
			local newState = Util.resolveBool(a.state, current)
			local ok, err = pcall(function()
				StarterGui:SetCoreGuiEnabled(coreType, newState)
			end)
			if not ok then
				return false, "Roblox did not accept that change right now: " .. tostring(err)
			end
			return ("%s is now %s."):format(a.element, newState and "shown" or "hidden")
		end,
	})
	add({
		Name = "mouseicon",
		Category = "Camera",
		Description = "Show or hide the mouse cursor icon.",
		Args = { { "state", "bool", opt = true } },
		Run = function(_, a)
			local value = Util.resolveBool(a.state, UserInputService.MouseIconEnabled)
			UserInputService.MouseIconEnabled = value
			return "Mouse icon " .. (value and "shown." or "hidden.")
		end,
	})
	add({
		Name = "hideui",
		Category = "Camera",
		Description = "Hide all of Fxield for a few seconds (for screenshots), then bring it back.",
		Args = { { "seconds", "integer", opt = true, min = 1, max = 60 } },
		Run = function(_, a)
			local seconds = a.seconds or 5
			App.hideTemporarily(seconds)
			return ("Fxield is hidden for %d seconds."):format(seconds)
		end,
	})
end

function Registry.define.filters()
	local add = Registry.add

	local function colorEffect()
		return View.effect("ColorCorrectionEffect", "FxieldColor")
	end

	add({
		Name = "fxsaturation",
		Category = "Visual filters",
		Description = "Make your view more or less colorful (-1 to 1). Local only.",
		Args = { { "value", "number", opt = true, min = -1, max = 1 } },
		Run = function(_, a)
			local effect = colorEffect()
			if a.value == nil then
				return "Saturation filter: " .. effect.Saturation
			end
			effect.Saturation = a.value
			return "Saturation filter set to " .. a.value .. "."
		end,
	})
	add({
		Name = "fxcontrast",
		Category = "Visual filters",
		Description = "Raise or lower contrast in your view (-1 to 1). Local only.",
		Args = { { "value", "number", opt = true, min = -1, max = 1 } },
		Run = function(_, a)
			local effect = colorEffect()
			if a.value == nil then
				return "Contrast filter: " .. effect.Contrast
			end
			effect.Contrast = a.value
			return "Contrast filter set to " .. a.value .. "."
		end,
	})
	add({
		Name = "fxbrightness",
		Category = "Visual filters",
		Description = "Brighten or darken your view slightly (-0.5 to 0.5). Local only.",
		Args = { { "value", "number", opt = true, min = -0.5, max = 0.5 } },
		Run = function(_, a)
			local effect = colorEffect()
			if a.value == nil then
				return "Brightness filter: " .. effect.Brightness
			end
			effect.Brightness = a.value
			return "Brightness filter set to " .. a.value .. "."
		end,
	})
	add({
		Name = "fxtint",
		Category = "Visual filters",
		Description = "Tint your view with a color, for example #FFD9A0 for a warm tone. Local only.",
		Args = { { "hex", "color" } },
		Run = function(_, a)
			colorEffect().TintColor = Util.parseHex(a.hex)
			return "Tint set to " .. a.hex .. "."
		end,
	})
	add({
		Name = "fxblur",
		Category = "Visual filters",
		Description = "Blur your view (0 to 24). Local only.",
		Args = { { "size", "number", opt = true, min = 0, max = 24 } },
		Run = function(_, a)
			local blur = View.effect("BlurEffect", "FxieldBlur")
			if a.size == nil then
				return "Blur filter: " .. blur.Size
			end
			blur.Size = a.size
			return "Blur filter set to " .. a.size .. "."
		end,
	})
	add({
		Name = "fxreset",
		Category = "Visual filters",
		Description = "Remove every Fxield visual filter.",
		Run = function()
			for _, name in ipairs({ "FxieldColor", "FxieldBlur" }) do
				local effect = Lighting:FindFirstChild(name)
				if effect then
					effect:Destroy()
				end
			end
			return "Visual filters removed."
		end,
	})
	add({
		Name = "fxinfo",
		Category = "Visual filters",
		Description = "Show which Fxield visual filters are active.",
		Run = function()
			local color = Lighting:FindFirstChild("FxieldColor")
			local blur = Lighting:FindFirstChild("FxieldBlur")
			if not color and not blur then
				return "No visual filters are active."
			end
			local lines = {}
			if color then
				table.insert(lines, ("Color: saturation %s, contrast %s, brightness %s"):format(tostring(color.Saturation), tostring(color.Contrast), tostring(color.Brightness)))
			end
			if blur then
				table.insert(lines, "Blur: " .. blur.Size)
			end
			return table.concat(lines, "\n")
		end,
	})
end

function Registry.define.utilities()
	local add = Registry.add
	local random = Random.new()

	add({
		Name = "calc",
		Aliases = { "math" },
		Category = "Utilities",
		Description = "Evaluate a math expression safely, for example: calc (2 + 3) * sqrt(16) ^ 2.",
		Args = { { "expression", "text", max = 160 } },
		Run = function(_, a)
			local value, err = Util.evaluate(a.expression)
			if not value then
				return false, err
			end
			return a.expression .. " = " .. tostring(Util.round(value, 8))
		end,
	})
	add({
		Name = "round",
		Category = "Utilities",
		Description = "Round a number to some decimal places.",
		Args = { { "value", "number" }, { "places", "integer", opt = true, min = 0, max = 10 } },
		Run = function(_, a)
			return tostring(Util.round(a.value, a.places or 0))
		end,
	})
	add({
		Name = "random",
		Aliases = { "rand" },
		Category = "Utilities",
		Description = "Pick a random whole number. One value means 1 to that number.",
		Args = { { "min", "integer", opt = true, min = -1000000000, max = 1000000000 }, { "max", "integer", opt = true, min = -1000000000, max = 1000000000 } },
		Run = function(_, a)
			local low, high = 1, 100
			if a.min and a.max then
				low, high = a.min, a.max
			elseif a.min then
				high = a.min
			end
			if low > high then
				return false, "The minimum is larger than the maximum."
			end
			return tostring(random:NextInteger(low, high))
		end,
	})
	add({
		Name = "roll",
		Category = "Utilities",
		Description = "Roll dice in NdM form, for example roll 2d6 or roll d20.",
		Args = { { "dice", "string", max = 12 } },
		Run = function(_, a)
			local count, sides = a.dice:lower():match("^(%d*)d(%d+)$")
			count = tonumber(count) or 1
			sides = tonumber(sides)
			if not sides or count < 1 or count > 100 or sides < 2 or sides > 1000 then
				return false, "Use NdM with 1 to 100 dice and 2 to 1000 sides, for example 2d6."
			end
			local rolls, total = {}, 0
			for _ = 1, count do
				local value = random:NextInteger(1, sides)
				total += value
				table.insert(rolls, value)
			end
			return ("%s: %s = %d"):format(a.dice, table.concat(rolls, " + "), total)
		end,
	})
	add({
		Name = "coin",
		Aliases = { "flip" },
		Category = "Utilities",
		Description = "Flip a coin.",
		Run = function()
			return random:NextInteger(0, 1) == 0 and "Heads" or "Tails"
		end,
	})
	add({
		Name = "pick",
		Aliases = { "choose" },
		Category = "Utilities",
		Description = "Pick one of several words at random.",
		Args = { { "options", "text", max = 200 } },
		Run = function(_, a)
			local words = Util.words(a.options)
			if #words < 2 then
				return false, "Give at least two options separated by spaces."
			end
			return "Picked: " .. words[random:NextInteger(1, #words)]
		end,
	})
	add({
		Name = "uuid",
		Category = "Utilities",
		Description = "Generate a random unique identifier.",
		Run = function()
			return HttpService:GenerateGUID(false)
		end,
	})
	add({
		Name = "echo",
		Category = "Utilities",
		Description = "Print some text back to the console.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return a.text
		end,
	})
	add({
		Name = "upper",
		Category = "Utilities",
		Description = "Turn text into UPPERCASE.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return a.text:upper()
		end,
	})
	add({
		Name = "lower",
		Category = "Utilities",
		Description = "Turn text into lowercase.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return a.text:lower()
		end,
	})
	add({
		Name = "titlecase",
		Category = "Utilities",
		Description = "Capitalize The First Letter Of Each Word.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return Util.titleCase(a.text)
		end,
	})
	add({
		Name = "reverse",
		Category = "Utilities",
		Description = "Reverse the characters in some text.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return a.text:reverse()
		end,
	})
	add({
		Name = "length",
		Category = "Utilities",
		Description = "Count the characters in some text.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return ("%d characters"):format(#a.text)
		end,
	})
	add({
		Name = "wordcount",
		Category = "Utilities",
		Description = "Count the words in some text.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return ("%d words"):format(#Util.words(a.text))
		end,
	})
	add({
		Name = "slug",
		Category = "Utilities",
		Description = "Turn text into a lowercase-with-dashes slug.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			local slug = a.text:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
			return slug
		end,
	})
	add({
		Name = "base64encode",
		Aliases = { "b64e" },
		Category = "Utilities",
		Description = "Encode text as Base64.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			return Util.base64Encode(a.text)
		end,
	})
	add({
		Name = "base64decode",
		Aliases = { "b64d" },
		Category = "Utilities",
		Description = "Decode Base64 text.",
		Args = { { "text", "text" } },
		Run = function(_, a)
			local decoded, err = Util.base64Decode(a.text)
			if not decoded then
				return false, err
			end
			return decoded
		end,
	})
	add({
		Name = "hex",
		Category = "Utilities",
		Description = "Convert a whole number to hexadecimal.",
		Args = { { "number", "integer", min = 0, max = 9007199254740991 } },
		Run = function(_, a)
			return string.format("%X", a.number)
		end,
	})
	add({
		Name = "fromhex",
		Category = "Utilities",
		Description = "Convert hexadecimal text to a number.",
		Args = { { "hex", "string", max = 14 } },
		Run = function(_, a)
			local cleaned = a.hex:gsub("^0[xX]", "")
			if not cleaned:match("^%x+$") then
				return false, "That is not hexadecimal."
			end
			return tostring(tonumber(cleaned, 16))
		end,
	})
	add({
		Name = "bin",
		Category = "Utilities",
		Description = "Convert a whole number to binary.",
		Args = { { "number", "integer", min = 0, max = 9007199254740991 } },
		Run = function(_, a)
			return Util.toBinary(a.number)
		end,
	})
	add({
		Name = "frombin",
		Category = "Utilities",
		Description = "Convert binary text to a number.",
		Args = { { "binary", "string", max = 53 } },
		Run = function(_, a)
			if not a.binary:match("^[01]+$") then
				return false, "Use only 0 and 1."
			end
			return tostring(tonumber(a.binary, 2))
		end,
	})
	add({
		Name = "rgb2hex",
		Category = "Utilities",
		Description = "Convert red, green and blue (0 to 255) to a hex color.",
		Args = { { "r", "integer", min = 0, max = 255 }, { "g", "integer", min = 0, max = 255 }, { "b", "integer", min = 0, max = 255 } },
		Run = function(_, a)
			return string.format("#%02X%02X%02X", a.r, a.g, a.b)
		end,
	})
	add({
		Name = "hex2rgb",
		Category = "Utilities",
		Description = "Convert a hex color to red, green and blue.",
		Args = { { "hex", "color" } },
		Run = function(_, a)
			local color = Util.parseHex(a.hex)
			return ("%s = %d, %d, %d"):format(a.hex, math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
		end,
	})
	add({
		Name = "colorpreview",
		Category = "Utilities",
		Description = "Show a hex color as a swatch on the Home page.",
		Args = { { "hex", "color" } },
		Run = function(_, a)
			Pages.setColorPreview(Util.parseHex(a.hex), a.hex)
			return "Color preview updated on the Home page: " .. a.hex
		end,
	})
	add({
		Name = "timer",
		Category = "Utilities",
		Description = "Start a local countdown timer that notifies you when it ends.",
		Args = { { "seconds", "number", min = 1, max = 86400 }, { "label", "text", opt = true, max = 60 } },
		Run = function(_, a)
			if Session.timerCount() >= 10 then
				return false, "You already have 10 timers running."
			end
			Session.nextTimer += 1
			local id = Session.nextTimer
			local label = a.label or ("Timer " .. id)
			local entry = { endsAt = os.clock() + a.seconds, label = label }
			entry.thread = Janitor.delay(a.seconds, function()
				Session.timers[id] = nil
				Console.print("Timer finished: " .. label, "output")
				Notify.show("success", label .. " finished.", "Timer")
			end)
			Session.timers[id] = entry
			return ("Started %s for %s."):format(label, Util.formatDuration(a.seconds))
		end,
	})
	add({
		Name = "timers",
		Category = "Utilities",
		Description = "List running timers and their time left.",
		Run = function()
			local lines = {}
			for id, entry in pairs(Session.timers) do
				table.insert(lines, ("#%d %s: %s left"):format(id, entry.label, Util.formatDuration(entry.endsAt - os.clock())))
			end
			table.sort(lines)
			return #lines > 0 and table.concat(lines, "\n") or "No timers are running."
		end,
	})
	add({
		Name = "canceltimers",
		Category = "Utilities",
		Description = "Stop every running timer.",
		Run = function()
			local count = 0
			for id, entry in pairs(Session.timers) do
				Janitor.cancel(entry.thread)
				Session.timers[id] = nil
				count += 1
			end
			return ("Cancelled %d timer(s)."):format(count)
		end,
	})
	add({
		Name = "stopwatch",
		Category = "Utilities",
		Description = "Start, stop, lap, reset or show a local stopwatch.",
		Args = { { "action", "enum", opt = true, opts = { "start", "stop", "lap", "reset", "show" } } },
		Run = function(_, a)
			local watch = Session.stopwatch
			local action = a.action or (watch.running and "show" or "start")
			local function elapsed()
				return watch.elapsed + (watch.running and (os.clock() - watch.started) or 0)
			end
			if action == "start" then
				if watch.running then
					return false, "The stopwatch is already running."
				end
				watch.running = true
				watch.started = os.clock()
				return "Stopwatch started."
			elseif action == "stop" then
				if not watch.running then
					return false, "The stopwatch is not running."
				end
				watch.elapsed = elapsed()
				watch.running = false
				return "Stopped at " .. Util.round(watch.elapsed, 2) .. " seconds."
			elseif action == "lap" then
				if not watch.running then
					return false, "Start the stopwatch first."
				end
				table.insert(watch.laps, elapsed())
				return ("Lap %d: %s seconds."):format(#watch.laps, tostring(Util.round(elapsed(), 2)))
			elseif action == "reset" then
				watch.running, watch.elapsed, watch.laps = false, 0, {}
				return "Stopwatch reset."
			end
			return ("Elapsed: %s seconds (%s)."):format(tostring(Util.round(elapsed(), 2)), watch.running and "running" or "stopped")
		end,
	})
	add({
		Name = "unix",
		Category = "Utilities",
		Description = "Show the current Unix timestamp.",
		Run = function()
			return tostring(os.time())
		end,
	})
	add({
		Name = "convert",
		Category = "Utilities",
		Description = "Convert units. Length: mm cm m km in ft yd mi studs. Mass: mg g kg oz lb. Time: ms s min h d. Temperature: c f k.",
		Args = { { "value", "number" }, { "from", "string", max = 8 }, { "to", "string", max = 8 } },
		Run = function(_, a)
			local result = Util.convertUnits(a.value, a.from, a.to)
			if not result then
				return false, "Those units cannot be converted into each other. Studs use 0.28 meters each."
			end
			return ("%s %s = %s %s"):format(tostring(a.value), a.from, tostring(Util.round(result, 6)), a.to)
		end,
	})
	add({
		Name = "percent",
		Category = "Utilities",
		Description = "Work out what percentage one number is of another.",
		Args = { { "part", "number" }, { "total", "number" } },
		Run = function(_, a)
			if a.total == 0 then
				return false, "The total cannot be zero."
			end
			return ("%s of %s = %s%%"):format(tostring(a.part), tostring(a.total), tostring(Util.round(a.part / a.total * 100, 4)))
		end,
	})
	add({
		Name = "average",
		Aliases = { "mean" },
		Category = "Utilities",
		Description = "Average a list of numbers separated by spaces or commas.",
		Args = { { "numbers", "text", max = 400 } },
		Run = function(_, a)
			local numbers, err = Util.parseNumbers(a.numbers)
			if not numbers then
				return false, err
			end
			local sum = 0
			for _, n in ipairs(numbers) do
				sum += n
			end
			return tostring(Util.round(sum / #numbers, 8))
		end,
	})
	add({
		Name = "sum",
		Category = "Utilities",
		Description = "Add up a list of numbers.",
		Args = { { "numbers", "text", max = 400 } },
		Run = function(_, a)
			local numbers, err = Util.parseNumbers(a.numbers)
			if not numbers then
				return false, err
			end
			local sum = 0
			for _, n in ipairs(numbers) do
				sum += n
			end
			return tostring(Util.round(sum, 8))
		end,
	})
	add({
		Name = "maxof",
		Category = "Utilities",
		Description = "Find the largest of a list of numbers.",
		Args = { { "numbers", "text", max = 400 } },
		Run = function(_, a)
			local numbers, err = Util.parseNumbers(a.numbers)
			if not numbers then
				return false, err
			end
			return tostring(math.max(table.unpack(numbers)))
		end,
	})
	add({
		Name = "minof",
		Category = "Utilities",
		Description = "Find the smallest of a list of numbers.",
		Args = { { "numbers", "text", max = 400 } },
		Run = function(_, a)
			local numbers, err = Util.parseNumbers(a.numbers)
			if not numbers then
				return false, err
			end
			return tostring(math.min(table.unpack(numbers)))
		end,
	})
	add({
		Name = "factorial",
		Category = "Utilities",
		Description = "Compute n factorial for n from 0 to 20.",
		Args = { { "n", "integer", min = 0, max = 20 } },
		Run = function(_, a)
			local result = 1
			for i = 2, a.n do
				result *= i
			end
			return ("%d! = %s"):format(a.n, Util.formatNumber(result))
		end,
	})
	add({
		Name = "isprime",
		Category = "Utilities",
		Description = "Check whether a whole number up to 10 billion is prime.",
		Args = { { "n", "integer", min = 0, max = 10000000000 } },
		Run = function(_, a)
			local n = a.n
			if n < 2 then
				return n .. " is not prime."
			end
			if n % 2 == 0 then
				return n .. (n == 2 and " is prime." or " is not prime (divisible by 2).")
			end
			for divisor = 3, math.floor(math.sqrt(n)), 2 do
				if n % divisor == 0 then
					return ("%d is not prime (divisible by %d)."):format(n, divisor)
				end
			end
			return n .. " is prime."
		end,
	})
	add({
		Name = "gcd",
		Category = "Utilities",
		Description = "Greatest common divisor of two whole numbers.",
		Args = { { "a", "integer", min = 0, max = 9007199254740991 }, { "b", "integer", min = 0, max = 9007199254740991 } },
		Run = function(_, a)
			return tostring(Util.gcd(a.a, a.b))
		end,
	})
	add({
		Name = "lcm",
		Category = "Utilities",
		Description = "Least common multiple of two whole numbers.",
		Args = { { "a", "integer", min = 1, max = 90000000 }, { "b", "integer", min = 1, max = 90000000 } },
		Run = function(_, a)
			return Util.formatNumber(a.a / Util.gcd(a.a, a.b) * a.b)
		end,
	})
	add({
		Name = "fib",
		Category = "Utilities",
		Description = "The nth Fibonacci number, for n from 0 to 70.",
		Args = { { "n", "integer", min = 0, max = 70 } },
		Run = function(_, a)
			local previous, current = 0, 1
			if a.n == 0 then
				return "0"
			end
			for _ = 2, a.n do
				previous, current = current, previous + current
			end
			return Util.formatNumber(current)
		end,
	})
end

function Registry.define.diagnostics()
	local add = Registry.add

	add({
		Name = "layoutcheck",
		Aliases = { "selftest" },
		Category = "Diagnostics",
		Description = "Check that the window fits the screen and that no text spills out of its box.",
		Run = function()
			return App.runLayoutCheck()
		end,
	})
	add({
		Name = "layoutinfo",
		Category = "Diagnostics",
		Description = "Show the current layout mode, window size and scale values.",
		Run = function()
			return App.layoutInfo()
		end,
	})
	add({
		Name = "debugbounds",
		Category = "Diagnostics",
		Description = "Draw an outline around every interface element to find overlap.",
		Args = { { "state", "bool", opt = true } },
		Run = function(_, a)
			local value = Util.resolveBool(a.state, App.debugBounds)
			App.setDebugBounds(value)
			return "Debug outlines " .. (value and "on." or "off.")
		end,
	})
	add({
		Name = "guicount",
		Category = "Diagnostics",
		Description = "Count the interface objects Fxield has created.",
		Run = function()
			local total, labels, buttons = 0, 0, 0
			for _, inst in ipairs(App.gui:GetDescendants()) do
				total += 1
				if inst:IsA("TextLabel") then
					labels += 1
				elseif inst:IsA("TextButton") then
					buttons += 1
				end
			end
			return ("%d objects (%d text labels, %d buttons)"):format(total, labels, buttons)
		end,
	})
	add({
		Name = "connections",
		Category = "Diagnostics",
		Description = "Show how many tracked connections, instances and tasks Fxield holds.",
		Run = function()
			local connections, instances, threads = Janitor.counts()
			return ("%d connections, %d instances, %d scheduled tasks are tracked for cleanup."):format(connections, instances, threads)
		end,
	})
	add({
		Name = "instancecount",
		Category = "Diagnostics",
		Description = "Count objects in Workspace as your client sees them.",
		Run = function()
			return ("Workspace holds %s objects."):format(Util.formatNumber(#workspace:GetDescendants()))
		end,
	})
	add({
		Name = "remotes",
		Category = "Diagnostics",
		Description = "List RemoteEvents and RemoteFunctions in ReplicatedStorage (names only, nothing is fired).",
		Run = function()
			local names = {}
			for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
				if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") or inst:IsA("UnreliableRemoteEvent") then
					table.insert(names, inst.ClassName .. ": " .. inst:GetFullName())
					if #names >= 40 then
						table.insert(names, "...")
						break
					end
				end
			end
			return #names > 0 and table.concat(names, "\n") or "No remotes found in ReplicatedStorage."
		end,
	})
	add({
		Name = "bandwidth",
		Category = "Diagnostics",
		Description = "Show data sent and received per second as reported by Roblox.",
		Run = function()
			local ok, sent, received = pcall(function()
				return Stats.DataSendKbps, Stats.DataReceiveKbps
			end)
			if not ok then
				return false, "Bandwidth statistics are not available."
			end
			return ("Sending %.1f KB/s, receiving %.1f KB/s"):format(sent, received)
		end,
	})
	add({
		Name = "version",
		Category = "Diagnostics",
		Description = "Show the Fxield version and what it can and cannot do.",
		Run = function()
			return ("Fxield %s | owner label: %s (display only, grants nothing) | runs on your device only; saves nothing between sessions."):format(Config.Version, Config.OwnerLabel)
		end,
	})
	add({
		Name = "diag",
		Category = "Diagnostics",
		Description = "Run a quick report: layout check, ping, memory and cleanup tracking.",
		Run = function()
			local ms = Session.pingMs()
			local connections, instances, threads = Janitor.counts()
			local okMemory, memory = pcall(function()
				return Stats:GetTotalMemoryUsageMb()
			end)
			return table.concat({
				App.runLayoutCheck(),
				ms and ("Ping: %.0f ms"):format(ms) or "Ping: unavailable",
				okMemory and ("Client memory: %.0f MB"):format(memory) or "Memory: unavailable",
				("Tracked for cleanup: %d connections, %d instances, %d tasks"):format(connections, instances, threads),
			}, "\n")
		end,
	})
end

function Registry.define.demo()
	local add = Registry.add

	add({
		Name = "demo20m",
		Aliases = { "demo20" },
		Category = "Demo",
		Description = "20M Demo Preview: sets only Fxield's own preview label. Demo only, not real game currency.",
		Run = function()
			Pages.setDemoBalance(20000000)
			return "Demo preview set to $20,000,000. Demo only - not real game currency, and nothing was sent to any game."
		end,
	})
	add({
		Name = "demobalance",
		Category = "Demo",
		Description = "Set the local demo preview label to any amount. Demo only, not real currency.",
		Args = { { "amount", "number", min = 0, max = 1000000000000 } },
		Run = function(_, a)
			Pages.setDemoBalance(a.amount)
			return "Demo preview set to $" .. Util.formatNumber(a.amount) .. ". Demo only - not real game currency."
		end,
	})
	add({
		Name = "demoreset",
		Category = "Demo",
		Description = "Reset the demo preview label to zero.",
		Run = function()
			Pages.setDemoBalance(0)
			return "Demo preview reset."
		end,
	})
end

function Registry.define.server()
	local reason = "This needs an authorized server API in an experience you own (a server Script that checks your numeric UserId against an allowlist). Fxield is a client script with no such connection, so nothing was sent and nothing changed."

	Registry.addUnavailable("serverkick", "Remove a player from the server.", "serverkick <player> [reason]", reason)
	Registry.addUnavailable("serverannounce", "Show a message to every player.", "serverannounce <message>", reason)
	Registry.addUnavailable("serverteleport", "Move players to another player.", "serverteleport <players> <destination>", reason)
	Registry.addUnavailable("serverbring", "Bring players to you.", "serverbring <players>", reason)
	Registry.addUnavailable("serverheal", "Restore other players' health.", "serverheal <players>", reason)
	Registry.addUnavailable("serverfreeze", "Anchor other players in place.", "serverfreeze <players>", reason)
	Registry.addUnavailable("serverrespawn", "Respawn other players.", "serverrespawn <players>", reason)
	Registry.addUnavailable("servergravity", "Change world gravity for everyone.", "servergravity <value>", reason)
	Registry.addUnavailable("servertimeofday", "Change the time of day for everyone.", "servertimeofday <hours>", reason)
	Registry.addUnavailable("serverlighting", "Change shared lighting for everyone.", "serverlighting <property> <value>", reason)
	Registry.addUnavailable("servermaintenance", "Turn maintenance mode on or off.", "servermaintenance [on|off]", reason)
	Registry.addUnavailable("serverconfig", "Edit live game configuration.", "serverconfig <action> [key] [value]", reason)
	Registry.addUnavailable("serverfeature", "Toggle shared feature flags.", "serverfeature <name> [on|off]", reason)
	Registry.addUnavailable("serverauditlog", "Read the server's admin audit log.", "serverauditlog [count]", reason)
	Registry.addUnavailable(
		"gamemoney",
		"Change a game's real in-game money.",
		"gamemoney <amount>",
		"Fxield cannot change any game's real money. Currency lives on that game's server and is not editable from a client script. Use demo20m for a local, clearly labeled preview only."
	)
end

Pages.names = { "Home", "Commands", "Settings", "Themes", "Help", "Players" }
Pages.shortNames = { Home = "Home", Commands = "Cmds", Settings = "Setup", Themes = "Themes", Help = "Help", Players = "Players" }
Pages.badges = { Home = "H", Commands = "C", Settings = "S", Themes = "T", Help = "?", Players = "P" }
Pages.frames = {}
Pages.navButtons = {}
Pages.current = "Home"

App.controls = {}
App.glass = setmetatable({}, { __mode = "k" })
App.windowVisible = false
App.minimized = false
App.maximized = false
App.compact = false
App.debugBounds = false
App.destroyed = false
App.center = Vector2.new(0, 0)
App.centerPending = true
App.capturingKey = false
App.sidebarWidth = 168
App.navHeight = 60

function Util.isShown(inst, root)
	local current = inst
	while current and current ~= root do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return true
end

function Util.rectsOverlap(a, b)
	local ap, as = a.AbsolutePosition, a.AbsoluteSize
	local bp, bs = b.AbsolutePosition, b.AbsoluteSize
	return ap.X < bp.X + bs.X - 1 and bp.X < ap.X + as.X - 1 and ap.Y < bp.Y + bs.Y - 1 and bp.Y < ap.Y + as.Y - 1
end

function UI.hideTooltip()
	if UI.tooltipLabel then
		UI.tooltipLabel:Destroy()
		UI.tooltipLabel = nil
	end
end

function UI.tooltip(target, text)
	target.MouseEnter:Connect(function()
		if not Prefs.tooltips or not UserInputService.MouseEnabled or not App.tooltipLayer then
			return
		end
		UI.hideTooltip()
		local layer = App.tooltipLayer
		local tip = UI.new("TextLabel", {
			Text = text,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = layer,
		})
		Style.registerText(tip, 12, "regular")
		Theme.bind(tip, "BackgroundColor3", "surface3")
		Theme.bind(tip, "TextColor3", "text")
		UI.padding(tip, 8, 5)
		UI.corner(tip, 0.5)
		UI.stroke(tip, "border", 1)
		UI.new("UISizeConstraint", { MaxSize = Vector2.new(220, math.huge), Parent = tip })
		local position = target.AbsolutePosition - layer.AbsolutePosition
		local centerX = Util.clamp(position.X + target.AbsoluteSize.X / 2, 120, math.max(120, layer.AbsoluteSize.X - 120))
		tip.Position = UDim2.fromOffset(centerX, position.Y + target.AbsoluteSize.Y + 6)
		UI.tooltipLabel = tip
	end)
	target.MouseLeave:Connect(UI.hideTooltip)
end

function App.setPref(key, value)
	Prefs[key] = value
	App.applyPref(key)
	local control = App.controls[key]
	if control and control.set then
		control.set(value)
	end
end

function App.applyTransparency()
	for inst in pairs(App.glass) do
		inst.BackgroundTransparency = Prefs.transparency
	end
end

function App.applyPref(key)
	local value = Prefs[key]
	if key == "theme" then
		Theme.set(value)
	elseif key == "accent" then
		Theme.setAccent(value)
	elseif key == "uiScale" or key == "compact" or key == "windowSize" then
		App.layout()
	elseif key == "textScale" then
		Style.applyText()
	elseif key == "transparency" then
		App.applyTransparency()
	elseif key == "cornerRadius" then
		Style.applyCorners()
	elseif key == "touchTargets" then
		Style.applyTouch()
		App.layout()
	elseif key == "font" then
		Style.applyFont()
	elseif key == "notifyPosition" then
		Notify.reposition()
	end
end

function App.navMetrics()
	local touchScale = Prefs.touchTargets == "large" and 1.15 or 1
	return math.floor(App.navHeight * touchScale + 0.5)
end

function App.layout()
	local gui = App.gui
	if not gui or not App.window or App.destroyed then
		return
	end
	local viewport = gui.AbsoluteSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return
	end
	local margin = Config.Margin
	local maxWidth = math.max(240, viewport.X - margin * 2)
	local maxHeight = math.max(180, viewport.Y - margin * 2)
	local mode = Prefs.compact
	App.compact = (mode == "always") or (mode == "auto" and viewport.X < Config.CompactBreakpoint)

	local width, height
	if App.compact or App.maximized then
		width, height = maxWidth, maxHeight
	else
		local presets = { small = { 0.5, 0.62 }, medium = { 0.62, 0.74 }, large = { 0.78, 0.86 } }
		local preset = presets[Prefs.windowSize] or presets.medium
		width = math.min(maxWidth, Util.clamp(viewport.X * preset[1], 560, 920))
		height = math.min(maxHeight, Util.clamp(viewport.Y * preset[2], 360, 640))
	end

	local scale = Prefs.uiScale
	if App.minimized and not App.maximized then
		height = Config.HeaderHeight * scale
	end
	App.size = Vector2.new(width, height)
	App.window.Size = UDim2.fromOffset(width, height)
	App.scalerObject.Scale = scale
	App.scaler.Size = UDim2.fromScale(1 / scale, 1 / scale)

	local halfWidth, halfHeight = width / 2, height / 2
	if App.centerPending or App.maximized then
		App.center = Vector2.new(viewport.X / 2, viewport.Y / 2)
		App.centerPending = false
	end
	local minX, maxX = margin + halfWidth, viewport.X - margin - halfWidth
	local minY, maxY = margin + halfHeight, viewport.Y - margin - halfHeight
	local x = minX > maxX and viewport.X / 2 or Util.clamp(App.center.X, minX, maxX)
	local y = minY > maxY and viewport.Y / 2 or Util.clamp(App.center.Y, minY, maxY)
	App.center = Vector2.new(x, y)
	App.window.Position = UDim2.fromOffset(x, y)

	App.applyNavMode()
	Pages.onLayout()
end

function App.applyNavMode()
	local compact = App.compact
	local navHeight = App.navMetrics()
	App.sidebar.Visible = not compact
	App.bottomNav.Visible = compact
	App.bodyLayout.FillDirection = compact and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
	App.sidebar.LayoutOrder = 1
	App.content.LayoutOrder = compact and 1 or 2
	App.bottomNav.LayoutOrder = 2
	App.sidebar.Size = UDim2.new(0, App.sidebarWidth, 1, 0)
	App.bottomNav.Size = UDim2.new(1, 0, 0, navHeight)
	App.content.Size = compact and UDim2.new(1, 0, 1, -navHeight) or UDim2.new(1, -App.sidebarWidth, 1, 0)
end

function App.showWindow()
	if App.destroyed then
		return
	end
	App.window.Visible = true
	App.windowVisible = true
	App.launcher.Visible = false
	App.layout()
	Pages.onShown(Pages.current)
end

function App.hideWindow()
	App.window.Visible = false
	App.windowVisible = false
	App.launcher.Visible = true
	UI.closePopup()
	UI.hideTooltip()
end

function App.toggleWindow()
	if App.windowVisible then
		App.hideWindow()
	else
		App.showWindow()
	end
end

function App.setMinimized(value)
	App.minimized = value
	if value then
		App.maximized = false
	end
	App.body.Visible = not value
	UI.closePopup()
	App.layout()
end

function App.setMaximized(value)
	App.maximized = value
	if value then
		App.minimized = false
		App.body.Visible = true
	end
	App.layout()
end

function App.centerWindow()
	App.centerPending = true
	App.layout()
end

function App.resetWindow()
	App.minimized = false
	App.maximized = false
	App.body.Visible = true
	App.setPref("compact", "auto")
	App.setPref("windowSize", "medium")
	App.setPref("locked", false)
	App.centerWindow()
end

function App.hideTemporarily(seconds)
	if App.hideThread then
		Janitor.cancel(App.hideThread)
	end
	App.gui.Enabled = false
	App.hideThread = Janitor.delay(seconds, function()
		App.hideThread = nil
		if App.gui then
			App.gui.Enabled = true
		end
	end)
end

function App.restoreGui()
	if App.hideThread then
		Janitor.cancel(App.hideThread)
		App.hideThread = nil
	end
	if App.gui then
		App.gui.Enabled = true
	end
end

function App.setDebugBounds(value)
	App.debugBounds = value
	for _, inst in ipairs(App.window:GetDescendants()) do
		if inst.Name == "FxieldDebug" and inst:IsA("UIStroke") then
			inst:Destroy()
		end
	end
	if not value then
		return
	end
	for _, inst in ipairs(App.window:GetDescendants()) do
		if inst:IsA("Frame") or inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") or inst:IsA("ScrollingFrame") then
			if not inst:FindFirstChild("FxieldDebug") then
				UI.new("UIStroke", {
					Name = "FxieldDebug",
					Color = Util.rgb(255, 0, 255),
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = inst,
				})
			end
		end
	end
end

function App.layoutInfo()
	if not App.window then
		return "The interface is not built."
	end
	local viewport = App.gui.AbsoluteSize
	return table.concat({
		("Viewport: %d x %d | Layout: %s | Compact setting: %s"):format(viewport.X, viewport.Y, App.compact and "phone (bottom navigation)" or "wide (sidebar)", Prefs.compact),
		("Window: %d x %d | Center: %d, %d | Minimized: %s | Maximized: %s"):format(App.size.X, App.size.Y, App.center.X, App.center.Y, tostring(App.minimized), tostring(App.maximized)),
		("UI scale: %s | Text scale: %s | Touch targets: %s | Touch device: %s"):format(tostring(Prefs.uiScale), tostring(Prefs.textScale), Prefs.touchTargets, tostring(UserInputService.TouchEnabled)),
	}, "\n")
end

function App.runLayoutCheck()
	if not App.window then
		return "The interface is not built."
	end
	local issues = {}
	local viewport = App.gui.AbsoluteSize
	local origin = App.gui.AbsolutePosition
	local position, size = App.window.AbsolutePosition - origin, App.window.AbsoluteSize
	if position.X < -1 or position.Y < -1 or position.X + size.X > viewport.X + 1 or position.Y + size.Y > viewport.Y + 1 then
		table.insert(issues, "The window extends outside the screen.")
	end

	local pairsToCheck = {
		{ "brand and page title", App.brand, App.pageTitle },
		{ "page title and window buttons", App.pageTitle, App.headerControls },
	}
	if App.compact then
		table.insert(pairsToCheck, { "content and bottom navigation", App.content, App.bottomNav })
	else
		table.insert(pairsToCheck, { "sidebar and content", App.sidebar, App.content })
	end
	if App.body.Visible then
		for _, item in ipairs(pairsToCheck) do
			if Util.rectsOverlap(item[2], item[3]) then
				table.insert(issues, "Overlap: " .. item[1] .. ".")
			end
		end
	end

	local spills = 0
	for _, inst in ipairs(App.window:GetDescendants()) do
		if (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) and inst.AbsoluteSize.X > 0 and Util.isShown(inst, App.window) then
			if not inst.TextWrapped and inst.TextTruncate == Enum.TextTruncate.None and inst.TextBounds.X > inst.AbsoluteSize.X + 2 then
				spills += 1
				if spills <= 6 then
					table.insert(issues, "Text spills out of its box: " .. inst.Name .. " (" .. inst.Text:sub(1, 24) .. ")")
				end
			end
		end
	end

	for name, page in pairs(Pages.frames) do
		if page.Visible and page.AbsoluteCanvasSize.X > page.AbsoluteSize.X + 2 then
			table.insert(issues, "The " .. name .. " page scrolls sideways.")
		end
	end

	local mode = App.compact and "phone layout" or "wide layout"
	if #issues == 0 then
		return ("Layout check passed (%s, viewport %d x %d): window inside the screen, no overlaps, no text spill."):format(mode, viewport.X, viewport.Y)
	end
	return ("Layout check found %d issue(s) (%s):\n%s"):format(#issues, mode, table.concat(issues, "\n"))
end

function View.restore()
	if not View.defaults then
		return
	end
	pcall(function()
		local camera = Session.camera()
		if camera then
			camera.FieldOfView = View.defaults.fov
		end
		LocalPlayer.CameraMinZoomDistance = View.defaults.zoomMin
		LocalPlayer.CameraMaxZoomDistance = View.defaults.zoomMax
		LocalPlayer.CameraMode = View.defaults.cameraMode
		LocalPlayer.DevCameraOcclusionMode = View.defaults.occlusion
		LocalPlayer.DevEnableMouseLock = View.defaults.mouseLock
	end)
end

function App.destroy()
	if App.destroyed then
		return
	end
	App.destroyed = true
	UI.closePopup()
	UI.hideTooltip()
	View.restore()
	Janitor.cleanup()
	if App.gui then
		App.gui:Destroy()
		App.gui = nil
	end
	PlayerGui:SetAttribute(Config.RunningAttribute, nil)
end

function Pages.createPage(name, parent)
	local page = UI.new("ScrollingFrame", {
		Name = name .. "Page",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = UserInputService.TouchEnabled and 3 or 5,
		Parent = parent,
	})
	UI.padding(page, 14, 12, 14, 14)
	UI.list(page, 12)
	Pages.frames[name] = page
	return page
end

function Pages.styleNav()
	for name, entry in pairs(Pages.navButtons) do
		local selected = name == Pages.current
		Theme.bind(entry.sidebar, "BackgroundColor3", selected and "surface3" or "surface")
		Theme.bind(entry.sidebarLabel, "TextColor3", selected and "text" or "textDim")
		Theme.bind(entry.sidebarBadge, "BackgroundColor3", selected and "accent" or "surface3")
		Theme.bind(entry.sidebarBadge, "TextColor3", selected and "accentText" or "textDim")
		Theme.bind(entry.bottomLabel, "TextColor3", selected and "accent" or "textDim")
		Theme.bind(entry.bottomBadge, "BackgroundColor3", selected and "accent" or "surface3")
		Theme.bind(entry.bottomBadge, "TextColor3", selected and "accentText" or "textDim")
	end
end

function Pages.show(name)
	if not Pages.frames[name] then
		return
	end
	Pages.current = name
	for pageName, frame in pairs(Pages.frames) do
		frame.Visible = pageName == name
	end
	App.pageTitle.Text = name
	Pages.styleNav()
	if App.windowVisible then
		Pages.onShown(name)
	end
end

function Pages.onShown(name)
	if name == "Commands" then
		Pages.ensureCommandRows()
	elseif name == "Players" then
		Pages.refreshPlayers()
	elseif name == "Home" then
		Pages.refreshStatus()
	elseif name == "Themes" then
		Pages.refreshThemes()
	end
end

function Pages.onLayout()
	Pages.styleNav()
end

function Pages.buildNav()
	local descriptions = {
		Home = "Command console and quick tools",
		Commands = "Search every command",
		Settings = "Appearance, layout, keys",
		Themes = "Preview and apply themes",
		Help = "How Fxield works",
		Players = "Read-only player list",
	}
	for index, name in ipairs(Pages.names) do
		local entry = {}

		entry.sidebar = UI.new("TextButton", {
			Name = "Nav" .. name,
			Text = "",
			AutoButtonColor = true,
			Size = UDim2.new(1, 0, 0, 44),
			LayoutOrder = index,
			Parent = App.sidebar,
		})
		UI.corner(entry.sidebar, 0.7)
		Style.registerTouch(entry.sidebar, 44)
		entry.sidebarBadge = UI.new("TextLabel", {
			Name = "Badge",
			Text = Pages.badges[name],
			Size = UDim2.fromOffset(26, 26),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Parent = entry.sidebar,
		})
		Style.registerText(entry.sidebarBadge, 13, "bold")
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = entry.sidebarBadge })
		entry.sidebarLabel = UI.new("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			Text = name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 46, 0, 0),
			Size = UDim2.new(1, -52, 1, 0),
			Parent = entry.sidebar,
		})
		Style.registerText(entry.sidebarLabel, 14, "medium")
		entry.sidebar.Activated:Connect(function()
			Pages.show(name)
		end)
		UI.tooltip(entry.sidebar, descriptions[name])

		entry.bottom = UI.new("TextButton", {
			Name = "NavBottom" .. name,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1 / #Pages.names, 0, 1, 0),
			LayoutOrder = index,
			Parent = App.bottomNav,
		})
		entry.bottomBadge = UI.new("TextLabel", {
			Name = "Badge",
			Text = Pages.badges[name],
			Size = UDim2.fromOffset(24, 24),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 7),
			Parent = entry.bottom,
		})
		Style.registerText(entry.bottomBadge, 12, "bold")
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = entry.bottomBadge })
		entry.bottomLabel = UI.new("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			Text = Pages.shortNames[name],
			TextWrapped = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, -5),
			Size = UDim2.new(1, 0, 0, 18),
			Parent = entry.bottom,
		})
		Style.registerText(entry.bottomLabel, 11, "medium")
		entry.bottom.Activated:Connect(function()
			Pages.show(name)
		end)

		Pages.navButtons[name] = entry
	end
	local note = UI.label(App.sidebar, "Client only. Nothing here changes the shared game.", 11, "textDim", "regular", { LayoutOrder = 99 })
	note.Size = UDim2.new(1, 0, 0, 0)
end

function Pages.appendOutput(text, kind)
	local output = Pages.output
	if not output or not output.Parent then
		return
	end
	local roles = { echo = "textDim", output = "text", error = "danger", warning = "warning" }
	Pages.lineCount = (Pages.lineCount or 0) + 1
	UI.label(output, text, 13, roles[kind] or "text", "mono", { LayoutOrder = Pages.lineCount })
	local lines = {}
	for _, child in ipairs(output:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(lines, child)
		end
	end
	if #lines > Config.MaxOutputLines then
		local oldest = lines[1]
		for _, line in ipairs(lines) do
			if line.LayoutOrder < oldest.LayoutOrder then
				oldest = line
			end
		end
		oldest:Destroy()
	end
	task.defer(function()
		if output.Parent then
			output.CanvasPosition = Vector2.new(0, output.AbsoluteCanvasSize.Y)
		end
	end)
end

function Pages.clearOutput()
	if not Pages.output then
		return
	end
	for _, child in ipairs(Pages.output:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

function Pages.refreshSuggestions()
	local box, area, hint = Pages.input, Pages.suggestionArea, Pages.hintLabel
	if not box or not area then
		return
	end
	for _, child in ipairs(area:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if not Prefs.autocomplete then
		hint.Visible = false
		return
	end
	local list, hintText = Console.suggest(box.Text)
	hint.Text = hintText or ""
	hint.Visible = hintText ~= nil
	for index, def in ipairs(list) do
		local button = UI.button(area, def.Name .. "  -  " .. def.Description, function()
			box.Text = def.Name .. " "
			if UserInputService.KeyboardEnabled then
				box:CaptureFocus()
			end
		end, "ghost", { Size = UDim2.new(1, 0, 0, 36), LayoutOrder = index, TextXAlignment = Enum.TextXAlignment.Left })
		UI.padding(button, 10, 0)
	end
end

function Pages.submitInput()
	local box = Pages.input
	local text = box.Text
	if Util.trim(text) == "" then
		return
	end
	box.Text = ""
	App.historyIndex = 0
	Console.execute(text, "user")
	if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
		box:CaptureFocus()
	end
end

function Pages.badgeLine(parent, text, order)
	return UI.label(parent, text, 13, "textDim", "regular", { LayoutOrder = order })
end

function Pages.setDemoBalance(amount)
	Pages.demoBalance = amount
	if Pages.demoLabel then
		Pages.demoLabel.Text = "Demo balance: $" .. Util.formatNumber(amount)
	end
end

function Pages.setColorPreview(color, hex)
	if Pages.colorSwatch then
		Pages.colorSwatch.BackgroundColor3 = color
		Pages.colorLabel.Text = hex
	end
end

function Pages.refreshStatus()
	if not Pages.statusLabel then
		return
	end
	local viewport = App.gui and App.gui.AbsoluteSize or Vector2.new(0, 0)
	local ms = Session.pingMs()
	Pages.statusLabel.Text = table.concat({
		("Theme: %s | Accent: %s"):format(Theme.name, Prefs.accent == "" and "theme default" or Prefs.accent),
		("Layout: %s | Viewport: %d x %d | UI scale: %s"):format(App.compact and "phone" or "wide", viewport.X, viewport.Y, tostring(Prefs.uiScale)),
		("Input: %s"):format(Session.platform()),
		("Ping: %s | Players: %d of %d"):format(ms and (math.floor(ms + 0.5) .. " ms") or "n/a", #Players:GetPlayers(), Players.MaxPlayers),
		("Session: %s | Commands: %d"):format(Util.formatDuration(os.clock() - Session.startClock), #Registry.list),
	}, "\n")
end

function Pages.refreshFavorites()
	if Pages.commandRows then
		for name, entry in pairs(Pages.commandRows) do
			local isFavorite = Registry.favorites[name] == true
			entry.fav.Text = isFavorite and "Faved" or "Fav"
			Theme.bind(entry.fav, "BackgroundColor3", isFavorite and "accent" or "surface3")
			Theme.bind(entry.fav, "TextColor3", isFavorite and "accentText" or "text")
		end
		if Pages.categoryFilter == "Favorites" then
			Pages.filterCommands()
		end
	end
	local area = Pages.favoriteArea
	if not area then
		return
	end
	for _, child in ipairs(area:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local names = {}
	for name in pairs(Registry.favorites) do
		table.insert(names, name)
	end
	table.sort(names)
	if #names == 0 then
		UI.label(area, "No favorites yet. Tap Fav on a command in the Commands page.", 13, "textDim", "regular", { LayoutOrder = 1 })
		return
	end
	for index, name in ipairs(names) do
		UI.chip(area, name, false, function()
			Console.execute(name, "button")
		end).LayoutOrder = index
	end
end

function Pages.buildHome(page)
	local _, welcome = UI.card(page, "Welcome to Fxield", "A polished toolbox that runs on your own device.", 1)
	Pages.badgeLine(welcome, "Client only: it never changes the shared game or other players.", 1)
	Pages.badgeLine(welcome, "Preferences last for this session only; nothing is saved.", 2)
	Pages.badgeLine(welcome, "Owner label: " .. Config.OwnerLabel .. " (display only, grants nothing).", 3)

	local _, consoleBody = UI.card(page, "Run a command", "Type a command and press Enter or Run. Try: help, theme violet, calc 2 + 2", 2)
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = consoleBody })
	local rowLayout = UI.list(row, 8, true)
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	local box = UI.input(row, "Command", "", function(_, enterPressed)
		if enterPressed then
			Pages.submitInput()
		end
	end)
	box.Name = "CommandInput"
	box.Size = UDim2.new(1, -96, 0, 40)
	box.Font = Enum.Font.Code
	Pages.input = box
	UI.button(row, "Run", Pages.submitInput, "primary", { Size = UDim2.fromOffset(88, 40), LayoutOrder = 2 })
	Janitor.connect(box:GetPropertyChangedSignal("Text"), Pages.refreshSuggestions)

	Pages.hintLabel = UI.label(consoleBody, "", 12, "accent", "mono", { LayoutOrder = 2, Visible = false })
	Pages.suggestionArea = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = consoleBody,
	})
	UI.list(Pages.suggestionArea, 4)

	local output = UI.new("ScrollingFrame", {
		Name = "Output",
		Size = UDim2.new(1, 0, 0, 190),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		LayoutOrder = 4,
		Parent = consoleBody,
	})
	Theme.bind(output, "BackgroundColor3", "surface2")
	UI.corner(output, 0.6)
	UI.padding(output, 10)
	UI.list(output, 3)
	Pages.output = output
	for _, entry in ipairs(Console.buffer) do
		Pages.appendOutput(entry.text, entry.kind)
	end

	local tools = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 5, Parent = consoleBody })
	UI.list(tools, 8, true)
	UI.button(tools, "Clear", function()
		Console.execute("clear", "button")
	end, "default", { Size = UDim2.new(0.33, -6, 0, 38), LayoutOrder = 1 })
	UI.button(tools, "History", function()
		Console.execute("history", "button")
	end, "default", { Size = UDim2.new(0.33, -6, 0, 38), LayoutOrder = 2 })
	UI.button(tools, "Help", function()
		Console.execute("help", "button")
	end, "default", { Size = UDim2.new(0.34, -6, 0, 38), LayoutOrder = 3 })

	local _, favoriteBody = UI.card(page, "Favorites", "One tap runs a favorite command.", 3)
	Pages.favoriteArea = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = favoriteBody })
	UI.wrapList(Pages.favoriteArea, 6)
	Pages.refreshFavorites()

	local _, statusBody = UI.card(page, "Status", "A snapshot of this session.", 4)
	Pages.statusLabel = UI.label(statusBody, "", 12, "text", "mono", { LayoutOrder = 1 })
	UI.button(statusBody, "Refresh", Pages.refreshStatus, "default", { Size = UDim2.new(1, 0, 0, 38), LayoutOrder = 2 })

	local _, toolsBody = UI.card(page, "Color preview", "Try: colorpreview #8B5CF6", 5)
	local swatchRow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = toolsBody })
	local swatchLayout = UI.list(swatchRow, 10, true)
	swatchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	Pages.colorSwatch = UI.new("Frame", { Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Theme.color("accent"), Parent = swatchRow })
	UI.corner(Pages.colorSwatch, 0.6)
	UI.stroke(Pages.colorSwatch, "border", 1)
	Pages.colorLabel = UI.label(swatchRow, "#8B5CF6", 14, "text", "mono", { Size = UDim2.new(1, -52, 0, 40), AutomaticSize = Enum.AutomaticSize.None, TextYAlignment = Enum.TextYAlignment.Center, LayoutOrder = 2 })

	local _, demoBody = UI.card(page, "20M Demo Preview", "A local, clearly labeled preview. It is not real game currency.", 6)
	Pages.demoLabel = UI.label(demoBody, "Demo balance: $0", 22, "accent", "bold", { LayoutOrder = 1 })
	local demoButtons = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = demoBody })
	UI.list(demoButtons, 8, true)
	UI.button(demoButtons, "20M Demo Preview", function()
		Console.execute("demo20m", "button")
	end, "primary", { Size = UDim2.new(0.6, -4, 0, 40), LayoutOrder = 1 })
	UI.button(demoButtons, "Reset", function()
		Console.execute("demoreset", "button")
	end, "default", { Size = UDim2.new(0.4, -4, 0, 40), LayoutOrder = 2 })
	Pages.badgeLine(demoBody, "Demo only. Fxield cannot change the real money in Lumber Tycoon 2 or any other game; that lives on the game's server.", 3)
	local applyButton = UI.button(demoBody, "Apply to game", nil, "default", { Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 4 })
	UI.setEnabled(applyButton, false)
	Pages.badgeLine(demoBody, "Unavailable: it would need an authorized server API in an experience you own.", 5)
	Pages.setDemoBalance(0)
end

function Pages.filterCommands()
	if not Pages.commandOrder then
		return
	end
	local needle = (Pages.commandSearch and Pages.commandSearch.Text or ""):lower()
	local shown = 0
	for _, entry in ipairs(Pages.commandOrder) do
		local def = entry.def
		local matches = true
		if Pages.categoryFilter == "Favorites" then
			matches = Registry.favorites[def.Name] == true
		elseif Pages.categoryFilter ~= "All" then
			matches = def.Category == Pages.categoryFilter
		end
		if matches and needle ~= "" then
			local haystack = (def.Name .. " " .. table.concat(def.Aliases, " ") .. " " .. def.Category .. " " .. def.Description):lower()
			matches = haystack:find(needle, 1, true) ~= nil
		end
		entry.frame.Visible = matches
		if matches then
			shown += 1
		end
	end
	Pages.commandCount.Text = ("%d of %d commands"):format(shown, #Pages.commandOrder)
end

function Pages.buildCommandRow(def, order)
	local frame = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = Pages.commandList })
	Theme.bind(frame, "BackgroundColor3", "surface")
	App.glass[frame] = true
	UI.corner(frame, 0.7)
	UI.stroke(frame, "border", 1)
	UI.padding(frame, 12)
	UI.list(frame, 6)

	local top = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 1, Parent = frame })
	local name = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = def.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -64, 1, 0),
		Parent = top,
	})
	Style.registerText(name, 16, "bold")
	Theme.bind(name, "TextColor3", def.Unavailable and "textDim" or "accent")
	local fav = UI.button(top, "Fav", function()
		Registry.toggleFavorite(def.Name)
	end, "default", { Size = UDim2.fromOffset(56, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) })

	UI.label(frame, def.Usage, 12, "textDim", "mono", { LayoutOrder = 2 })
	UI.label(frame, (def.Unavailable and "Needs server: " or "") .. def.Description, 13, def.Unavailable and "warning" or "text", "regular", { LayoutOrder = 3 })
	if #def.Aliases > 0 then
		UI.label(frame, "Aliases: " .. table.concat(def.Aliases, ", "), 12, "textDim", "regular", { LayoutOrder = 4 })
	end

	local needsArguments = false
	for _, spec in ipairs(def.Args) do
		if not spec.opt then
			needsArguments = true
		end
	end
	local buttons = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 5, Parent = frame })
	UI.list(buttons, 8, true)
	UI.button(buttons, "Use", function()
		Pages.show("Home")
		Pages.input.Text = def.Name .. " "
		if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
			Pages.input:CaptureFocus()
		end
	end, "default", { Size = UDim2.new(0.5, -4, 0, 36), LayoutOrder = 1 })
	local run = UI.button(buttons, "Run", function()
		Console.execute(def.Name, "button")
	end, "primary", { Size = UDim2.new(0.5, -4, 0, 36), LayoutOrder = 2 })
	if def.Unavailable or needsArguments then
		UI.setEnabled(run, false)
		run.Text = def.Unavailable and "Unavailable" or "Needs input"
	end

	local entry = { def = def, frame = frame, fav = fav }
	Pages.commandRows[def.Name] = entry
	table.insert(Pages.commandOrder, entry)
end

function Pages.ensureCommandRows()
	if Pages.commandsBuilding or Pages.commandsBuilt then
		return
	end
	Pages.commandsBuilding = true
	local index = 1
	local function step()
		if App.destroyed or not Pages.commandList then
			return
		end
		local stop = math.min(index + 14, #Registry.list)
		for i = index, stop do
			Pages.buildCommandRow(Registry.list[i], i)
		end
		index = stop + 1
		Pages.filterCommands()
		if index <= #Registry.list then
			Janitor.delay(0.02, step)
		else
			Pages.commandsBuilding = false
			Pages.commandsBuilt = true
			Pages.refreshFavorites()
		end
	end
	step()
end

function Pages.buildCommands(page)
	Pages.commandRows = {}
	Pages.commandOrder = {}
	Pages.categoryFilter = "All"

	local search = UI.input(page, "Search commands, aliases or descriptions", "", nil)
	search.LayoutOrder = 1
	Pages.commandSearch = search
	Janitor.connect(search:GetPropertyChangedSignal("Text"), Pages.filterCommands)

	local chips = UI.new("ScrollingFrame", {
		Name = "Categories",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		LayoutOrder = 2,
		Parent = page,
	})
	local chipLayout = UI.list(chips, 6, true)
	chipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	local renderers = {}
	local function select(name)
		Pages.categoryFilter = name
		for chipName, render in pairs(renderers) do
			render(chipName == name)
		end
		Pages.filterCommands()
	end
	local names = { "All", "Favorites" }
	for _, category in ipairs(Registry.categoryOrder) do
		table.insert(names, category)
	end
	for index, name in ipairs(names) do
		local chip, render = UI.chip(chips, name, name == "All", function()
			select(name)
		end)
		chip.LayoutOrder = index
		renderers[name] = render
	end

	Pages.commandCount = UI.label(page, "Loading commands...", 12, "textDim", "regular", { LayoutOrder = 3 })
	Pages.commandList = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Parent = page })
	UI.list(Pages.commandList, 8)
end

function Pages.toggleSetting(parent, title, description, key, onChange)
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent })
	local layout = UI.list(row, 12, true)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	local text = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -64, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row })
	UI.list(text, 2)
	UI.label(text, title, 14, "text", "medium", { LayoutOrder = 1 })
	if description then
		UI.label(text, description, 12, "textDim", "regular", { LayoutOrder = 2 })
	end
	local control = UI.toggle(row, key and Prefs[key] or false, function(value)
		if key then
			App.setPref(key, value)
		end
		if onChange then
			onChange(value)
		end
	end)
	control.instance.LayoutOrder = 2
	if key then
		App.controls[key] = control
	end
	return control
end

function Pages.sliderSetting(parent, title, description, key, min, max, step, format, applyOnRelease)
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent })
	UI.list(row, 4)
	UI.label(row, title, 14, "text", "medium", { LayoutOrder = 1 })
	if description then
		UI.label(row, description, 12, "textDim", "regular", { LayoutOrder = 2 })
	end
	local control
	if applyOnRelease then
		control = UI.slider(row, min, max, step, Prefs[key], nil, format, function(value)
			App.setPref(key, value)
		end)
	else
		control = UI.slider(row, min, max, step, Prefs[key], function(value)
			App.setPref(key, value)
		end, format)
	end
	control.instance.LayoutOrder = 3
	App.controls[key] = control
	return control
end

function Pages.dropdownSetting(parent, title, description, key, options)
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent })
	UI.list(row, 4)
	UI.label(row, title, 14, "text", "medium", { LayoutOrder = 1 })
	if description then
		UI.label(row, description, 12, "textDim", "regular", { LayoutOrder = 2 })
	end
	local control = UI.dropdown(row, options, Prefs[key], function(value)
		App.setPref(key, value)
	end)
	control.instance.LayoutOrder = 3
	App.controls[key] = control
	return control
end

function App.resetAllSettings()
	Theme.cancelPreview()
	for key, value in pairs(PrefDefaults) do
		App.setPref(key, value)
	end
	App.minimized = false
	App.maximized = false
	App.body.Visible = true
	App.centerWindow()
	Notify.show("success", "All settings were reset to their defaults.")
end

function Pages.buildSettings(page)
	local _, appearance = UI.card(page, "Appearance", "Changes apply immediately for this session.", 1)
	Pages.sliderSetting(appearance, "Interface scale", "Makes the whole window larger or smaller. Applies when you let go.", "uiScale", 0.7, 1.6, 0.05, function(v)
		return ("%.2fx"):format(v)
	end, true)
	Pages.sliderSetting(appearance, "Text size", "Scales every piece of text.", "textScale", 0.8, 1.6, 0.05, function(v)
		return ("%.2fx"):format(v)
	end)
	Pages.sliderSetting(appearance, "Window transparency", "Lets a little of the game show through panels.", "transparency", 0, 0.5, 0.05, function(v)
		return ("%d%%"):format(v * 100)
	end)
	Pages.sliderSetting(appearance, "Corner rounding", "How round panels and buttons are.", "cornerRadius", 0, 20, 1, function(v)
		return ("%d px"):format(v)
	end)
	Pages.dropdownSetting(appearance, "Font", "Interface font family.", "font", Style.familyOrder)

	local _, layout = UI.card(page, "Layout and touch", "Choose how Fxield fits your screen.", 2)
	Pages.dropdownSetting(layout, "Layout mode", "Auto uses the phone layout on narrow screens.", "compact", { "auto", "always", "never" })
	Pages.dropdownSetting(layout, "Window size", "Used on wide screens.", "windowSize", { "small", "medium", "large" })
	Pages.dropdownSetting(layout, "Touch targets", "Large makes buttons and inputs taller.", "touchTargets", { "normal", "large" })
	Pages.toggleSetting(layout, "Lock window position", "Stops the window from being dragged.", "locked")

	local _, comfort = UI.card(page, "Motion and hints", nil, 3)
	Pages.toggleSetting(comfort, "Reduce motion", "Turns off animations.", "reduceMotion")
	Pages.toggleSetting(comfort, "Tooltips", "Hover hints on desktop.", "tooltips")
	Pages.toggleSetting(comfort, "Command suggestions", "Suggest commands while you type.", "autocomplete")

	local _, notifications = UI.card(page, "Notifications", "Local toasts for command results.", 4)
	Pages.toggleSetting(notifications, "Show notifications", nil, "notifications")
	Pages.sliderSetting(notifications, "Duration", "How long each notification stays.", "notifySeconds", 1, 30, 1, function(v)
		return ("%d s"):format(v)
	end)
	Pages.sliderSetting(notifications, "Maximum on screen", nil, "notifyLimit", 1, 8, 1, function(v)
		return ("%d"):format(v)
	end)
	Pages.dropdownSetting(notifications, "Position", nil, "notifyPosition", { "topright", "topleft", "bottom" })

	local _, keys = UI.card(page, "Keys and commands", nil, 5)
	Pages.keyButton = UI.button(keys, "", function()
		App.capturingKey = true
		Pages.keyButton.Text = "Press a key... (Escape cancels)"
	end, "default", { Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1 })
	Pages.refreshKeyButton()
	UI.label(keys, "Command prefix (optional, up to 3 characters; leave empty for none)", 12, "textDim", "regular", { LayoutOrder = 2 })
	local prefix = UI.input(keys, "none", Prefs.prefix, function(text)
		local value = Util.trim(text)
		if #value > 3 or value:find("%s") then
			Notify.show("error", "A prefix is at most 3 characters with no spaces.")
			return
		end
		App.setPref("prefix", value)
	end)
	prefix.LayoutOrder = 3
	App.controls.prefix = {
		set = function(value)
			prefix.Text = value
		end,
	}

	local _, maintenance = UI.card(page, "Checks and reset", nil, 6)
	UI.button(maintenance, "Run layout check", function()
		Console.execute("layoutcheck", "button")
	end, "default", { Size = UDim2.new(1, 0, 0, 40) })
	Pages.toggleSetting(maintenance, "Debug outlines", "Outline every element to spot overlap.", nil, function(value)
		App.setDebugBounds(value)
	end)
	UI.button(maintenance, "Reset all settings", function()
		UI.confirm("Reset every Fxield setting to its default?", App.resetAllSettings)
	end, "danger", { Size = UDim2.new(1, 0, 0, 40) })
end

function Pages.refreshKeyButton()
	if Pages.keyButton then
		Pages.keyButton.Text = "Toggle key: " .. Prefs.toggleKey .. "  (tap to change)"
	end
end

function Pages.refreshThemes()
	if not Pages.themeStatus then
		return
	end
	Pages.themeStatus.Text = "Active theme: " .. Theme.name
	Pages.previewBanner.Visible = Theme.previewName ~= nil
	if Theme.previewName then
		Pages.previewLabel.Text = "Previewing " .. Theme.previewName .. ". Apply keeps it, Cancel goes back."
	end
	for name, entry in pairs(Pages.themeRows) do
		local isActive = name == Theme.name
		entry.stroke.Thickness = isActive and 2 or 1
		Theme.bind(entry.stroke, "Color", isActive and "accent" or "border")
		entry.apply.Text = isActive and "Active" or "Apply"
		UI.setEnabled(entry.apply, not isActive)
	end
end

function Pages.buildThemes(page)
	Pages.themeRows = {}
	local _, status = UI.card(page, "Current theme", nil, 1)
	Pages.themeStatus = UI.label(status, "", 14, "text", "medium", { LayoutOrder = 1 })
	Pages.previewBanner = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 2, Parent = status })
	Theme.bind(Pages.previewBanner, "BackgroundColor3", "surface3")
	UI.corner(Pages.previewBanner, 0.6)
	UI.padding(Pages.previewBanner, 12)
	UI.list(Pages.previewBanner, 8)
	Pages.previewLabel = UI.label(Pages.previewBanner, "", 13, "text", "regular", { LayoutOrder = 1 })
	local bannerButtons = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = Pages.previewBanner })
	UI.list(bannerButtons, 8, true)
	UI.button(bannerButtons, "Apply", function()
		Theme.commitPreview()
	end, "primary", { Size = UDim2.new(0.5, -4, 0, 38), LayoutOrder = 1 })
	UI.button(bannerButtons, "Cancel", function()
		Theme.cancelPreview()
	end, "default", { Size = UDim2.new(0.5, -4, 0, 38), LayoutOrder = 2 })

	local _, list = UI.card(page, "Themes", "Preview first, then apply.", 2)
	for index, name in ipairs(Theme.order) do
		local palette = Theme.palettes[name]
		local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = index, Parent = list })
		Theme.bind(row, "BackgroundColor3", "surface2")
		UI.corner(row, 0.7)
		local stroke = UI.stroke(row, "border", 1)
		UI.padding(row, 12)
		UI.list(row, 8)
		local top = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1, Parent = row })
		local topLayout = UI.list(top, 8, true)
		topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		for swatchIndex, color in ipairs({ palette.bg, palette.surface3, palette.accent, palette.text }) do
			local swatch = UI.new("Frame", { Size = UDim2.fromOffset(24, 24), BackgroundColor3 = color, LayoutOrder = swatchIndex, Parent = top })
			UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = swatch })
			UI.new("UIStroke", { Color = palette.border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = swatch })
		end
		local label = UI.new("TextLabel", {
			BackgroundTransparency = 1,
			Text = name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -140, 1, 0),
			LayoutOrder = 5,
			Parent = top,
		})
		Style.registerText(label, 15, "bold")
		Theme.bind(label, "TextColor3", "text")
		local buttons = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = row })
		UI.list(buttons, 8, true)
		UI.button(buttons, "Preview", function()
			Theme.preview(name)
		end, "default", { Size = UDim2.new(0.5, -4, 0, 36), LayoutOrder = 1 })
		local apply = UI.button(buttons, "Apply", function()
			App.setPref("theme", name)
		end, "primary", { Size = UDim2.new(0.5, -4, 0, 36), LayoutOrder = 2 })
		Pages.themeRows[name] = { stroke = stroke, apply = apply }
	end

	local _, accent = UI.card(page, "Accent color", "Overrides the accent of any theme.", 3)
	local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = accent })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(42, 42), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for index, hex in ipairs({ "#8B5CF6", "#6366F1", "#38BDF8", "#34D399", "#F59E0B", "#F97316", "#EF4444", "#EC4899" }) do
		local swatch = UI.new("TextButton", { Text = "", BackgroundColor3 = Util.parseHex(hex), LayoutOrder = index, Parent = grid })
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = swatch })
		swatch.Activated:Connect(function()
			App.setPref("accent", hex)
		end)
	end
	local hexInput = UI.input(accent, "#RRGGBB", "", function(text)
		if text == "" then
			return
		end
		local color, normalized = Util.parseHex(text)
		if not color then
			Notify.show("error", "Use a hex color such as #8B5CF6.")
			return
		end
		App.setPref("accent", normalized)
	end)
	hexInput.LayoutOrder = 2
	App.controls.accent = {
		set = function(value)
			hexInput.Text = value
		end,
	}
	UI.button(accent, "Reset accent", function()
		App.setPref("accent", "")
	end, "default", { Size = UDim2.new(1, 0, 0, 38), LayoutOrder = 3 })

	local _, reset = UI.card(page, "Reset", nil, 4)
	UI.button(reset, "Reset theme and accent", function()
		Console.execute("themereset", "button")
	end, "danger", { Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1 })
end

function Pages.buildHelp(page)
	local function section(title, lines, order)
		local _, body = UI.card(page, title, nil, order)
		for index, line in ipairs(lines) do
			UI.label(body, line, 13, "text", "regular", { LayoutOrder = index })
		end
	end
	section("Getting started", {
		"Type a command on the Home page and press Enter or Run. Type part of a name to see suggestions; tap one to fill it in.",
		"Browse everything in the Commands page: search, filter by category, tap Use to fill the console or Run to run it at once.",
		"Up and Down arrows browse your history. Tab completes a command name.",
	}, 1)
	section("Writing commands", {
		"Quotes group words: notify \"hello there\". A backslash escapes a quote inside quotes.",
		"alias lets you make your own short names, bind runs a command when you press a key, fav stars commands for one-tap use.",
		"The optional prefix (Settings) is stripped if you type it, so ;theme violet and theme violet both work.",
	}, 2)
	section("Keys and touch", {
		"Desktop: the toggle key (default RightControl) shows or hides Fxield. Change it in Settings or with togglekey.",
		"Phone: tap the round F button to reopen. On narrow screens navigation moves to a bar at the bottom, and Touch targets can make buttons larger.",
		"Drag the title bar to move the window. Use - to minimize, [] to maximize and x to hide.",
	}, 3)
	section("What Fxield cannot do", {
		"Fxield is one client script. It cannot kick, announce, teleport or heal other players, change shared lighting or gravity, edit game configuration, or change any game's money. Those commands are listed as Needs server and are disabled.",
		"The 20M Demo Preview only changes a label inside Fxield. It is not real currency and nothing is sent to any game.",
		"Preferences, history, aliases and binds last for this session only. There is nowhere safe to save them from a client script.",
	}, 4)
	section("Checking the layout", {
		"layoutcheck verifies the window fits the screen and that no text spills out or overlaps. debugbounds outlines every element. layoutinfo shows the current mode and sizes.",
		"unload removes Fxield completely, restoring camera preferences and removing visual filters.",
	}, 5)
end

function Pages.markPlayersDirty()
	Pages.playersDirty = true
	if App.windowVisible and Pages.current == "Players" and not Pages.playersPending then
		Pages.playersPending = true
		Janitor.delay(0.25, function()
			Pages.playersPending = false
			Pages.refreshPlayers()
		end)
	end
end

function Pages.refreshPlayers()
	local list = Pages.playerList
	if not list then
		return
	end
	Pages.playersDirty = false
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local needle = (Pages.playerSearch and Pages.playerSearch.Text or ""):lower()
	local shown = 0
	local players = Players:GetPlayers()
	table.sort(players, function(a, b)
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)
	for index, player in ipairs(players) do
		local haystack = (player.Name .. " " .. player.DisplayName):lower()
		if needle == "" or haystack:find(needle, 1, true) then
			shown += 1
			local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = index, Parent = list })
			Theme.bind(row, "BackgroundColor3", "surface")
			App.glass[row] = true
			UI.corner(row, 0.7)
			UI.stroke(row, "border", 1)
			UI.padding(row, 12)
			UI.list(row, 3)
			UI.label(row, player.DisplayName .. (player == LocalPlayer and "  (you)" or ""), 15, "text", "bold", { LayoutOrder = 1 })
			UI.label(row, "@" .. player.Name .. "  |  id " .. player.UserId, 12, "textDim", "mono", { LayoutOrder = 2 })
			UI.label(row, ("Account age %d days  |  Team: %s"):format(player.AccountAge, player.Team and player.Team.Name or "none"), 12, "textDim", "regular", { LayoutOrder = 3 })
		end
	end
	Pages.playerCount.Text = ("%d of %d players shown"):format(shown, #players)
end

function Pages.buildPlayers(page)
	local search = UI.input(page, "Search players", "", nil)
	search.LayoutOrder = 1
	Pages.playerSearch = search
	Janitor.connect(search:GetPropertyChangedSignal("Text"), Pages.refreshPlayers)
	Pages.playerCount = UI.label(page, "", 12, "textDim", "regular", { LayoutOrder = 2 })
	UI.label(page, "Read-only. Fxield shows public information only and cannot act on other players.", 12, "textDim", "regular", { LayoutOrder = 3 })
	Pages.playerList = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Parent = page })
	UI.list(Pages.playerList, 8)
end

function App.build()
	local old = PlayerGui:FindFirstChild(Config.GuiName)
	if old then
		old:Destroy()
	end
	local gui = UI.new("ScreenGui", {
		Name = Config.GuiName,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 200,
		IgnoreGuiInset = false,
		Parent = PlayerGui,
	})
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.CoreUISafe
	end)
	Janitor.add(gui)
	App.gui = gui

	local function layer(name, zIndex)
		return UI.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = zIndex,
			Parent = gui,
		})
	end
	App.windowLayer = layer("WindowLayer", 1)
	App.popupLayer = layer("PopupLayer", 20)
	App.tooltipLayer = layer("TooltipLayer", 30)
	App.toastLayer = layer("ToastLayer", 40)

	App.launcher = UI.new("TextButton", {
		Name = "Launcher",
		Text = "F",
		Visible = false,
		Size = UDim2.fromOffset(50, 50),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.4, 0),
		ZIndex = 5,
		Parent = gui,
	})
	Style.registerText(App.launcher, 20, "bold")
	Theme.bind(App.launcher, "BackgroundColor3", "accent")
	Theme.bind(App.launcher, "TextColor3", "accentText")
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = App.launcher })
	UI.stroke(App.launcher, "border", 1)
	App.launcher.Activated:Connect(App.showWindow)
	UI.tooltip(App.launcher, "Open Fxield")

	local window = UI.new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(600, 400),
		Parent = App.windowLayer,
	})
	Theme.bind(window, "BackgroundColor3", "bg")
	App.glass[window] = true
	UI.corner(window, 1.2)
	UI.stroke(window, "border", 1)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(940, 680), Parent = window })
	App.window = window

	App.scaler = UI.new("Frame", { Name = "Scaler", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = window })
	App.scalerObject = UI.new("UIScale", { Parent = App.scaler })

	local header = UI.new("Frame", {
		Name = "Header",
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Config.HeaderHeight),
		Parent = App.scaler,
	})
	Theme.bind(header, "BackgroundColor3", "surface")
	App.glass[header] = true
	App.header = header
	local divider = UI.new("Frame", {
		Name = "Divider",
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = header,
	})
	Theme.bind(divider, "BackgroundColor3", "border")

	App.brand = UI.new("TextLabel", {
		Name = "Brand",
		BackgroundTransparency = 1,
		Text = Config.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.fromOffset(70, Config.HeaderHeight),
		Parent = header,
	})
	Style.registerText(App.brand, 18, "bold")
	Theme.bind(App.brand, "TextColor3", "accent")

	App.pageTitle = UI.new("TextLabel", {
		Name = "PageTitle",
		BackgroundTransparency = 1,
		Text = "Home",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(88, 0),
		Size = UDim2.new(1, -244, 0, Config.HeaderHeight),
		Parent = header,
	})
	Style.registerText(App.pageTitle, 13, "medium")
	Theme.bind(App.pageTitle, "TextColor3", "textDim")

	App.headerControls = UI.new("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(138, 36),
		Parent = header,
	})
	UI.list(App.headerControls, 6, true)
	local minimizeButton = UI.button(App.headerControls, "-", function()
		App.setMinimized(not App.minimized)
	end, "default", { Size = UDim2.fromOffset(42, 36), LayoutOrder = 1 })
	local maximizeButton = UI.button(App.headerControls, "[]", function()
		App.setMaximized(not App.maximized)
	end, "default", { Size = UDim2.fromOffset(42, 36), LayoutOrder = 2 })
	local closeButton = UI.button(App.headerControls, "x", App.hideWindow, "default", { Size = UDim2.fromOffset(42, 36), LayoutOrder = 3 })
	UI.tooltip(minimizeButton, "Minimize")
	UI.tooltip(maximizeButton, "Maximize or restore")
	UI.tooltip(closeButton, "Hide (reopen with the F button)")

	UI.drag(header, function()
		return App.center
	end, function(startCenter, delta)
		if Prefs.locked or App.maximized then
			return
		end
		App.center = startCenter + delta
		App.layout()
	end)

	App.body = UI.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, Config.HeaderHeight),
		Size = UDim2.new(1, 0, 1, -Config.HeaderHeight),
		Parent = App.scaler,
	})
	App.bodyLayout = UI.list(App.body, 0, true)
	App.sidebar = UI.new("Frame", {
		Name = "Sidebar",
		BorderSizePixel = 0,
		Size = UDim2.new(0, App.sidebarWidth, 1, 0),
		LayoutOrder = 1,
		Parent = App.body,
	})
	Theme.bind(App.sidebar, "BackgroundColor3", "surface")
	App.glass[App.sidebar] = true
	UI.padding(App.sidebar, 10)
	UI.list(App.sidebar, 6)
	App.content = UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, -App.sidebarWidth, 1, 0),
		LayoutOrder = 2,
		Parent = App.body,
	})
	App.bottomNav = UI.new("Frame", {
		Name = "BottomNav",
		BorderSizePixel = 0,
		Visible = false,
		Size = UDim2.new(1, 0, 0, App.navHeight),
		LayoutOrder = 3,
		Parent = App.body,
	})
	Theme.bind(App.bottomNav, "BackgroundColor3", "surface")
	App.glass[App.bottomNav] = true
	UI.list(App.bottomNav, 0, true)

	Pages.buildNav()
	Pages.buildHome(Pages.createPage("Home", App.content))
	Pages.buildCommands(Pages.createPage("Commands", App.content))
	Pages.buildSettings(Pages.createPage("Settings", App.content))
	Pages.buildThemes(Pages.createPage("Themes", App.content))
	Pages.buildHelp(Pages.createPage("Help", App.content))
	Pages.buildPlayers(Pages.createPage("Players", App.content))

	Notify.container = UI.new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.92, 0, 1, -24),
		Parent = App.toastLayer,
	})
	UI.list(Notify.container, 8)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(340, math.huge), Parent = Notify.container })
	Notify.reposition()

	App.onThemeChanged = function()
		Pages.refreshThemes()
	end
end

function App.onInput(input, processed)
	if App.destroyed then
		return
	end
	local box = Pages.input
	if box and box:IsFocused() then
		local history = Console.history
		if input.KeyCode == Enum.KeyCode.Up and #history > 0 then
			App.historyIndex = math.min((App.historyIndex or 0) + 1, #history)
			box.Text = history[#history - App.historyIndex + 1]
			box.CursorPosition = #box.Text + 1
		elseif input.KeyCode == Enum.KeyCode.Down then
			App.historyIndex = math.max((App.historyIndex or 0) - 1, 0)
			box.Text = App.historyIndex == 0 and "" or history[#history - App.historyIndex + 1]
			box.CursorPosition = #box.Text + 1
		elseif input.KeyCode == Enum.KeyCode.Tab then
			local matches = Console.suggest(box.Text)
			if matches[1] then
				box.Text = matches[1].Name .. " "
				box.CursorPosition = #box.Text + 1
			end
		end
		return
	end
	if App.capturingKey and input.UserInputType == Enum.UserInputType.Keyboard then
		App.capturingKey = false
		if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then
			if Registry.binds[input.KeyCode.Name] then
				Notify.show("error", input.KeyCode.Name .. " is used by a bind. Use unbind first.")
			else
				App.setPref("toggleKey", input.KeyCode.Name)
				Notify.show("success", "Toggle key set to " .. input.KeyCode.Name .. ".")
			end
		end
		Pages.refreshKeyButton()
		return
	end
	if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	local keyName = input.KeyCode.Name
	if keyName == Prefs.toggleKey then
		App.toggleWindow()
		return
	end
	local bound = Registry.binds[keyName]
	if bound then
		Console.execute(bound, "bind")
	end
end

function App.bindEvents()
	Janitor.connect(App.gui:GetPropertyChangedSignal("AbsoluteSize"), App.layout)
	Janitor.connect(UserInputService.InputBegan, App.onInput)
	Janitor.connect(Players.PlayerAdded, Pages.markPlayersDirty)
	Janitor.connect(Players.PlayerRemoving, Pages.markPlayersDirty)
end

function App.init()
	PlayerGui:SetAttribute(Config.RunningAttribute, true)
	View.captureDefaults()
	local groups = { "navigation", "appearance", "accessibility", "console", "notifications", "session", "camera", "filters", "utilities", "diagnostics", "demo", "server" }
	for _, name in ipairs(groups) do
		Registry.define[name]()
	end
	App.build()
	App.bindEvents()
	Theme.apply()
	Pages.show("Home")
	local waited = 0
	while App.gui.AbsoluteSize.X <= 0 and waited < 2 do
		waited += task.wait()
	end
	Console.print(("Fxield %s is ready. Type help to begin."):format(Config.Version), "output")
	Console.print(("%d commands loaded: %d work on this device, %d are marked as needing a server."):format(#Registry.list, Registry.available(), #Registry.list - Registry.available()), "output")
	App.showWindow()
end

local started, startError = xpcall(App.init, debug.traceback)
if not started then
	warn("[Fxield] Failed to start:\n" .. tostring(startError))
	App.destroy()
end


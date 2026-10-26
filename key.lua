-- FXIELD | Key Gate
-- Use as a LocalScript in your own Roblox experience.
-- This client-side gate only hides the UI; it is not secure server authentication.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ACCESS_KEY = "GrW5_12freekeys-17091gsk82kHoBqjsfDgjJE"
local OWNER_USERNAME = "FxplayzOfficial"

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function round(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

local old = playerGui:FindFirstChild("FxieldKeyUI")
if old then old:Destroy() end

local gui = make("ScreenGui", {
    Name = "FxieldKeyUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 60,
}, playerGui)

local bg = Color3.fromRGB(18, 19, 25)
local panelColor = Color3.fromRGB(27, 29, 38)
local accent = Color3.fromRGB(132, 112, 255)
local textColor = Color3.fromRGB(245, 245, 250)
local muted = Color3.fromRGB(165, 168, 185)
local bad = Color3.fromRGB(255, 119, 130)
local good = Color3.fromRGB(105, 213, 158)

local panel = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 320, 0, 270),
    BackgroundColor3 = bg,
    BorderSizePixel = 0,
}, gui)
round(panel, 18)
make("UIStroke", {Color = Color3.fromRGB(54, 56, 70), Thickness = 1}, panel)

local logo = make("Frame", {
    Position = UDim2.new(0, 18, 0, 18),
    Size = UDim2.new(0, 42, 0, 42),
    BackgroundColor3 = accent,
    BorderSizePixel = 0,
}, panel)
round(logo, 13)
make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = Enum.Font.GothamBold,
    Text = "F",
    TextSize = 23,
    TextColor3 = Color3.new(1, 1, 1),
}, logo)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 70, 0, 18),
    Size = UDim2.new(1, -88, 0, 25),
    Font = Enum.Font.GothamBold,
    Text = "Fxield access",
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = textColor,
}, panel)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 70, 0, 43),
    Size = UDim2.new(1, -88, 0, 20),
    Font = Enum.Font.Gotham,
    Text = "Enter your key to continue",
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = muted,
}, panel)

local keyBox = make("TextBox", {
    Position = UDim2.new(0, 18, 0, 88),
    Size = UDim2.new(1, -36, 0, 44),
    BackgroundColor3 = panelColor,
    BorderSizePixel = 0,
    PlaceholderText = "Paste access key",
    PlaceholderColor3 = muted,
    Text = "",
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = textColor,
}, panel)
round(keyBox, 10)
make("UIPadding", {
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
}, keyBox)

local message = make("TextLabel", {
    Position = UDim2.new(0, 18, 0, 140),
    Size = UDim2.new(1, -36, 0, 34),
    BackgroundTransparency = 1,
    Text = "This check is local to this client.",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextWrapped = true,
    TextColor3 = muted,
}, panel)

local submit = make("TextButton", {
    Position = UDim2.new(0, 18, 1, -60),
    Size = UDim2.new(1, -36, 0, 42),
    BackgroundColor3 = accent,
    BorderSizePixel = 0,
    Text = "Verify and continue",
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextColor3 = Color3.new(1, 1, 1),
    AutoButtonColor = true,
}, panel)
round(submit, 11)

local busy = false
local function verify()
    if busy then return end
    if keyBox.Text ~= ACCESS_KEY then
        message.Text = "That key doesn't match. Check it and try again."
        message.TextColor3 = bad
        return
    end

    busy = true
    player:SetAttribute("FxieldSessionAuthorized", true)
    message.Text = "Key accepted. Opening Fxield..."
    message.TextColor3 = good

    task.wait(0.25)
    gui:Destroy()

    -- Executor-only: fetch and run the Fxield main script after key verification.
    local url = "https://raw.githubusercontent.com/bardahawale-debug/Fxield/refs/heads/main/main_script.lua"
    local ok, err = pcall(function()
        local source = game:HttpGet(url)
        local chunk, compileError = loadstring(source)
        if not chunk then
            error("Fxield main script compile error: " .. tostring(compileError))
        end
        chunk()
    end)

    if not ok then
        warn("Fxield failed to load: " .. tostring(err))
        message.Text = "Couldn't load Fxield. Check executor HTTP/loadstring support."
        message.TextColor3 = bad
    end
end

submit.Activated:Connect(verify)
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then verify() end
end)

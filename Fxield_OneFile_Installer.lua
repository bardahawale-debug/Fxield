local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local serverSource = [=[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local CONFIG = {
    OwnerUsername = "FxplayzOfficial",
    AccessKey = "GrW5_12freekeys-17091gsk82kHoBqjsfDgjJE",
    MaxFailedAttempts = 3,
    LockSeconds = 900,
    EnablePersistentRestrictions = false,
    RequestCooldown = 0.3,
    MaxRequestsPerMinute = 30
}

local ownerUserId
local restrictionStore
if CONFIG.EnablePersistentRestrictions then
    local ok, result = pcall(function()
        return DataStoreService:GetDataStore("FxieldRestrictions_v1")
    end)
    if ok then
        restrictionStore = result
    end
end

local sessions = {}
local auditLog = {}
local liveConfig = {
    Gravity = Workspace.Gravity,
    ClockTime = Lighting.ClockTime,
    GlobalAnnouncements = true
}

local function audit(player, action, detail)
    local item = {
        UserId = player and player.UserId or 0,
        Username = player and player.Name or "System",
        Action = tostring(action),
        Detail = tostring(detail or ""),
        Timestamp = os.time()
    }
    table.insert(auditLog, 1, item)
    while #auditLog > 200 do
        table.remove(auditLog)
    end
    print("[Fxield]", item.Username, item.Action, item.Detail)
end

local function resolveOwner()
    local ok, result = pcall(function()
        return Players:GetUserIdFromNameAsync(CONFIG.OwnerUsername)
    end)
    if ok and type(result) == "number" then
        ownerUserId = result
    else
        warn("[Fxield] Owner UserId could not be resolved. Admin access stays disabled.")
    end
end

local function isOwner(player)
    return ownerUserId ~= nil and player.UserId == ownerUserId
end

local function getSession(player)
    local session = sessions[player.UserId]
    if not session then
        session = {
            authenticated = false,
            failed = 0,
            lockedUntil = 0,
            requestTimes = {}
        }
        sessions[player.UserId] = session
    end
    return session
end

local function restricted(userId)
    if not restrictionStore then
        return false
    end
    local ok, value = pcall(function()
        return restrictionStore:GetAsync(tostring(userId))
    end)
    return ok and value == true
end

local function saveRestriction(userId, value)
    if not restrictionStore then
        return false
    end
    local ok = pcall(function()
        restrictionStore:SetAsync(tostring(userId), value == true)
    end)
    return ok
end

local function rateLimited(player, session)
    local now = os.clock()
    local recent = {}
    for _, timestamp in ipairs(session.requestTimes) do
        if now - timestamp < 60 then
            table.insert(recent, timestamp)
        end
    end
    session.requestTimes = recent
    if #recent >= CONFIG.MaxRequestsPerMinute then
        return true
    end
    if recent[#recent] and now - recent[#recent] < CONFIG.RequestCooldown then
        return true
    end
    table.insert(session.requestTimes, now)
    return false
end

local function getOrCreate(parent, className, name)
    local found = parent:FindFirstChild(name)
    if found then
        return found
    end
    local instance = Instance.new(className)
    instance.Name = name
    instance.Parent = parent
    return instance
end

local remotesRoot
local AuthenticateRemote
local CommandRemote
local ConfigRemote
local StatusRemote

local function setupRemotes()
    local root = getOrCreate(ReplicatedStorage, "Folder", "Fxield")
    remotesRoot = getOrCreate(root, "Folder", "Remotes")
    AuthenticateRemote = getOrCreate(remotesRoot, "RemoteFunction", "Authenticate")
    CommandRemote = getOrCreate(remotesRoot, "RemoteFunction", "RunCommand")
    ConfigRemote = getOrCreate(remotesRoot, "RemoteFunction", "UpdateConfig")
    StatusRemote = getOrCreate(remotesRoot, "RemoteFunction", "GetStatus")
end

local function safeNumber(value, minimum, maximum)
    local number = tonumber(value)
    if not number or number ~= number or number < minimum or number > maximum then
        return nil
    end
    return number
end

local function getTarget(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local lowered = string.lower(name)
    for _, target in ipairs(Players:GetPlayers()) do
        if string.lower(target.Name) == lowered or string.lower(target.DisplayName) == lowered then
            return target
        end
    end
    for _, target in ipairs(Players:GetPlayers()) do
        if string.sub(string.lower(target.Name), 1, #lowered) == lowered then
            return target
        end
    end
    return nil
end

local function command(player, line)
    if not isOwner(player) then
        return false, "Owner permission required."
    end
    if type(line) ~= "string" or #line > 300 then
        return false, "Invalid command."
    end

    local parts = {}
    for word in string.gmatch(line, "%S+") do
        table.insert(parts, word)
    end
    local name = string.lower(table.remove(parts, 1) or "")

    if name == "help" or name == "commands" then
        return true, "help | serverinfo | playerinfo name | announce message | kick name reason | heal name | freeze name | unfreeze name | setwalkspeed name value | setjumppower name value | setgravity value | settimeofday hour"
    elseif name == "serverinfo" then
        return true, "Players: " .. #Players:GetPlayers() .. " | PlaceId: " .. game.PlaceId .. " | Gravity: " .. Workspace.Gravity .. " | Time: " .. Lighting.ClockTime
    elseif name == "playerinfo" then
        local target = getTarget(parts[1])
        if not target then
            return false, "Usage: playerinfo player"
        end
        return true, target.Name .. " | UserId: " .. target.UserId .. " | Account age: " .. target.AccountAge .. " days"
    elseif name == "announce" then
        if not liveConfig.GlobalAnnouncements then
            return false, "Global announcements are disabled in the Live Editor."
        end
        local message = table.concat(parts, " ")
        if message == "" then
            return false, "Usage: announce message"
        end
        message = string.sub(message, 1, 180)
        local root = ReplicatedStorage:FindFirstChild("Fxield")
        root:SetAttribute("AnnouncementText", message)
        root:SetAttribute("AnnouncementNonce", os.clock())
        audit(player, name, message)
        return true, "Announcement broadcast."
    elseif name == "setgravity" then
        local value = safeNumber(parts[1], 0, 500)
        if not value then
            return false, "Usage: setgravity 0-500"
        end
        Workspace.Gravity = value
        liveConfig.Gravity = value
        audit(player, name, value)
        return true, "Gravity updated."
    elseif name == "settimeofday" then
        local value = safeNumber(parts[1], 0, 24)
        if not value then
            return false, "Usage: settimeofday 0-24"
        end
        Lighting.ClockTime = value
        liveConfig.ClockTime = value
        audit(player, name, value)
        return true, "Time updated."
    elseif name == "setwalkspeed" or name == "setjumppower" then
        local target = getTarget(parts[1])
        local value = safeNumber(parts[2], 0, name == "setwalkspeed" and 100 or 200)
        if not target or not value then
            return false, "Usage: " .. name .. " player value"
        end
        local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return false, "Target character is not ready."
        end
        if name == "setwalkspeed" then
            humanoid.WalkSpeed = value
        else
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
        audit(player, name, target.Name .. " = " .. value)
        return true, "Updated " .. target.Name .. "."
    elseif name == "heal" or name == "freeze" or name == "unfreeze" or name == "kick" then
        local target = getTarget(parts[1])
        if not target then
            return false, "Player not found."
        end
        if target == player and name == "kick" then
            return false, "You cannot kick yourself."
        end
        if name == "kick" then
            local reason = table.concat(parts, " ", 2)
            if reason == "" then
                reason = "Removed by the experience owner."
            end
            audit(player, name, target.Name .. ": " .. reason)
            target:Kick(string.sub(reason, 1, 160))
            return true, "Kicked " .. target.Name .. "."
        end
        local character = target.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid then
            return false, "Target character is not ready."
        end
        if name == "heal" then
            humanoid.Health = humanoid.MaxHealth
        elseif not rootPart then
            return false, "Target root part is unavailable."
        elseif name == "freeze" then
            rootPart.Anchored = true
        elseif name == "unfreeze" then
            rootPart.Anchored = false
        end
        audit(player, name, target.Name)
        return true, name .. " completed for " .. target.Name .. "."
    end

    return false, "Unknown command. Type help."
end

local function sendStatus(player, message)
    local root = ReplicatedStorage:FindFirstChild("Fxield")
    if root then
        root:SetAttribute("Status_" .. player.UserId, message)
    end
end

setupRemotes()

AuthenticateRemote.OnServerInvoke = function(player, key)
    local session = getSession(player)
    if session.lockedUntil > os.clock() then
        return {ok = false, locked = true, message = "Access temporarily locked after three failed attempts."}
    end
    if restricted(player.UserId) then
        return {ok = false, locked = true, message = "Fxield access is restricted. Contact the experience owner."}
    end
    if rateLimited(player, session) then
        return {ok = false, message = "Too many requests. Please wait."}
    end
    if type(key) ~= "string" or #key > 256 then
        return {ok = false, message = "Invalid key format."}
    end
    if key == CONFIG.AccessKey then
        session.authenticated = true
        session.failed = 0
        audit(player, "AUTH_SUCCESS", "Key accepted")
        return {ok = true, owner = isOwner(player), message = "Key accepted."}
    end
    session.failed += 1
    audit(player, "AUTH_FAILURE", "Attempt " .. session.failed)
    if session.failed >= CONFIG.MaxFailedAttempts then
        session.lockedUntil = os.clock() + CONFIG.LockSeconds
        session.authenticated = false
        saveRestriction(player.UserId, true)
        audit(player, "AUTH_LOCK", "Three failed attempts")
        return {ok = false, locked = true, message = "Three failed attempts. Fxield access is locked."}
    end
    return {ok = false, message = "Incorrect key. Attempts left: " .. (CONFIG.MaxFailedAttempts - session.failed)}
end

CommandRemote.OnServerInvoke = function(player, line)
    local session = getSession(player)
    if not session.authenticated then
        return {ok = false, message = "Enter the access key first."}
    end
    if session.lockedUntil > os.clock() or restricted(player.UserId) then
        return {ok = false, message = "Fxield access is locked."}
    end
    if rateLimited(player, session) then
        return {ok = false, message = "Rate limit reached. Wait a moment."}
    end
    local ok, success, message = pcall(command, player, line)
    if not ok then
        warn("[Fxield] Command error:", success)
        return {ok = false, message = "Command failed. Check server output."}
    end
    return {ok = success, message = message}
end

ConfigRemote.OnServerInvoke = function(player, setting, value)
    local session = getSession(player)
    if not session.authenticated or not isOwner(player) then
        audit(player, "DENIED_CONFIG_EDIT", tostring(setting))
        return {ok = false, message = "Owner authentication required."}
    end
    if rateLimited(player, session) then
        return {ok = false, message = "Rate limit reached."}
    end
    if setting == "Gravity" then
        local number = safeNumber(value, 0, 500)
        if not number then
            return {ok = false, message = "Gravity must be 0–500."}
        end
        liveConfig.Gravity = number
        Workspace.Gravity = number
    elseif setting == "ClockTime" then
        local number = safeNumber(value, 0, 24)
        if not number then
            return {ok = false, message = "ClockTime must be 0–24."}
        end
        liveConfig.ClockTime = number
        Lighting.ClockTime = number
    elseif setting == "GlobalAnnouncements" and type(value) == "boolean" then
        liveConfig.GlobalAnnouncements = value
    else
        return {ok = false, message = "Unsupported setting or invalid value."}
    end
    audit(player, "LIVE_CONFIG", setting .. " = " .. tostring(value))
    return {ok = true, message = "Updated " .. setting .. "."}
end

GetStatus.OnServerInvoke = function(player)
    local session = getSession(player)
    return {
        authenticated = session.authenticated,
        owner = isOwner(player),
        locked = session.lockedUntil > os.clock() or restricted(player.UserId),
        commands = {"help", "serverinfo", "playerinfo", "announce", "kick", "heal", "freeze", "unfreeze", "setwalkspeed", "setjumppower", "setgravity", "settimeofday"}
    }
end

Players.PlayerRemoving:Connect(function(player)
    sessions[player.UserId] = nil
end)

task.spawn(function()
    resolveOwner()
    print("[Fxield] Server core initialized. Owner-only commands remain disabled until owner verification succeeds.")
end)


print("[Fxield] Server core initialized.")
]=]
local clientSource = [=[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local remotes = ReplicatedStorage:WaitForChild("Fxield"):WaitForChild("Remotes")
local AuthenticateRemote = remotes:WaitForChild("Authenticate")
local CommandRemote = remotes:WaitForChild("RunCommand")
local ConfigRemote = remotes:WaitForChild("UpdateConfig")
local StatusRemote = remotes:WaitForChild("GetStatus")

local function buildUI(player)
    local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("FxieldUI") then
        return
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "FxieldUI"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 50
    screen.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Main"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(460, 390)
    panel.BackgroundColor3 = Color3.fromRGB(18, 20, 29)
    panel.BorderSizePixel = 0
    panel.Parent = screen
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(96, 112, 255)
    border.Thickness = 1.4
    border.Parent = panel

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = panel

    local function label(parent, text, pos, size, fontSize, color)
        local object = Instance.new("TextLabel")
        object.BackgroundTransparency = 1
        object.Text = text
        object.Position = pos
        object.Size = size
        object.Font = Enum.Font.Gotham
        object.TextSize = fontSize
        object.TextColor3 = color or Color3.fromRGB(235, 238, 255)
        object.TextWrapped = true
        object.TextXAlignment = Enum.TextXAlignment.Left
        object.Parent = parent
        return object
    end

    local function button(parent, text, pos, size, accent)
        local object = Instance.new("TextButton")
        object.Text = text
        object.Position = pos
        object.Size = size
        object.BackgroundColor3 = accent and Color3.fromRGB(91, 107, 255) or Color3.fromRGB(38, 42, 56)
        object.TextColor3 = Color3.fromRGB(250, 250, 255)
        object.Font = Enum.Font.GothamSemibold
        object.TextSize = 13
        object.AutoButtonColor = true
        object.Parent = parent
        Instance.new("UICorner", object).CornerRadius = UDim.new(0, 8)
        return object
    end

    local title = label(panel, "FXIELD", UDim2.fromOffset(20, 14), UDim2.new(1, -75, 0, 34), 25, Color3.fromRGB(133, 146, 255))
    title.Font = Enum.Font.GothamBold
    label(panel, "SECURE ADMIN CONSOLE", UDim2.fromOffset(22, 47), UDim2.new(1, -44, 0, 20), 10, Color3.fromRGB(142, 149, 173))

    local close = button(panel, "×", UDim2.new(1, -48, 0, 14), UDim2.fromOffset(30, 30), false)
    close.TextSize = 20
    close.Activated:Connect(function()
        panel.Visible = false
    end)

    local status = label(panel, "Enter your access key to continue.", UDim2.fromOffset(22, 75), UDim2.new(1, -44, 0, 32), 12, Color3.fromRGB(180, 185, 204))
    local keyBox = Instance.new("TextBox")
    keyBox.PlaceholderText = "Access key"
    keyBox.Text = ""
    keyBox.ClearTextOnFocus = false
    keyBox.Position = UDim2.fromOffset(22, 111)
    keyBox.Size = UDim2.new(1, -44, 0, 38)
    keyBox.BackgroundColor3 = Color3.fromRGB(31, 34, 47)
    keyBox.TextColor3 = Color3.fromRGB(245, 246, 255)
    keyBox.PlaceholderColor3 = Color3.fromRGB(133, 140, 164)
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 13
    keyBox.Parent = panel
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

    local authButton = button(panel, "UNLOCK FXIELD", UDim2.fromOffset(22, 157), UDim2.new(1, -44, 0, 38), true)
    local commandBox = Instance.new("TextBox")
    commandBox.PlaceholderText = "Command, e.g. help or setgravity 196.2"
    commandBox.Text = ""
    commandBox.ClearTextOnFocus = false
    commandBox.Position = UDim2.fromOffset(22, 111)
    commandBox.Size = UDim2.new(1, -44, 0, 38)
    commandBox.BackgroundColor3 = Color3.fromRGB(31, 34, 47)
    commandBox.TextColor3 = Color3.fromRGB(245, 246, 255)
    commandBox.PlaceholderColor3 = Color3.fromRGB(133, 140, 164)
    commandBox.Font = Enum.Font.Gotham
    commandBox.TextSize = 13
    commandBox.Visible = false
    commandBox.Parent = panel
    Instance.new("UICorner", commandBox).CornerRadius = UDim.new(0, 8)

    local runButton = button(panel, "RUN COMMAND", UDim2.fromOffset(22, 157), UDim2.new(1, -44, 0, 38), true)
    runButton.Visible = false

    local editorTitle = label(panel, "LIVE CONFIGURATION", UDim2.fromOffset(22, 207), UDim2.new(1, -44, 0, 20), 11, Color3.fromRGB(133, 146, 255))
    editorTitle.Visible = false

    local gravityBox = Instance.new("TextBox")
    gravityBox.PlaceholderText = "Gravity (0–500)"
    gravityBox.Text = tostring(Workspace.Gravity)
    gravityBox.Position = UDim2.fromOffset(22, 233)
    gravityBox.Size = UDim2.new(0.48, -5, 0, 34)
    gravityBox.BackgroundColor3 = Color3.fromRGB(31, 34, 47)
    gravityBox.TextColor3 = Color3.fromRGB(245, 246, 255)
    gravityBox.Font = Enum.Font.Gotham
    gravityBox.TextSize = 12
    gravityBox.Visible = false
    gravityBox.Parent = panel
    Instance.new("UICorner", gravityBox).CornerRadius = UDim.new(0, 7)

    local timeBox = Instance.new("TextBox")
    timeBox.PlaceholderText = "Time (0–24)"
    timeBox.Text = tostring(Lighting.ClockTime)
    timeBox.Position = UDim2.new(0.52, 0, 0, 233)
    timeBox.Size = UDim2.new(0.48, -22, 0, 34)
    timeBox.BackgroundColor3 = Color3.fromRGB(31, 34, 47)
    timeBox.TextColor3 = Color3.fromRGB(245, 246, 255)
    timeBox.Font = Enum.Font.Gotham
    timeBox.TextSize = 12
    timeBox.Visible = false
    timeBox.Parent = panel
    Instance.new("UICorner", timeBox).CornerRadius = UDim.new(0, 7)

    local applyGravity = button(panel, "APPLY GRAVITY", UDim2.fromOffset(22, 275), UDim2.new(0.48, -5, 0, 32), false)
    applyGravity.Visible = false
    local applyTime = button(panel, "APPLY TIME", UDim2.new(0.52, 0, 0, 275), UDim2.new(0.48, -22, 0, 32), false)
    applyTime.Visible = false

    local toggleEditor = button(panel, "SHOW LIVE EDITOR", UDim2.fromOffset(22, 325), UDim2.new(1, -44, 0, 34), false)
    toggleEditor.Visible = false

    local function setEditorVisible(visible)
        editorTitle.Visible = visible
        gravityBox.Visible = visible
        timeBox.Visible = visible
        applyGravity.Visible = visible
        applyTime.Visible = visible
        toggleEditor.Text = visible and "HIDE LIVE EDITOR" or "SHOW LIVE EDITOR"
    end

    local function invoke(remote, ...)
        local packed = table.pack(pcall(function(...)
            return remote:InvokeServer(...)
        end, ...))
        if not packed[1] then
            return {ok = false, message = "Server request failed."}
        end
        return packed[2]
    end

    authButton.Activated:Connect(function()
        authButton.Active = false
        authButton.Text = "CHECKING..."
        local result = invoke(AuthenticateRemote, keyBox.Text)
        authButton.Active = true
        authButton.Text = "UNLOCK FXIELD"
        status.Text = result.message or "Authentication failed."
        if result.ok then
            if result.owner then
                keyBox.Visible = false
                authButton.Visible = false
                commandBox.Visible = true
                runButton.Visible = true
                toggleEditor.Visible = true
                status.Text = "Owner verified. Fxield is ready."
                status.TextColor3 = Color3.fromRGB(126, 235, 174)
            else
                status.Text = "Key accepted, but this account is not the configured owner."
                status.TextColor3 = Color3.fromRGB(255, 193, 115)
            end
        else
            status.TextColor3 = Color3.fromRGB(255, 130, 140)
            if result.locked then
                keyBox.TextEditable = false
                authButton.Active = false
            end
        end
    end)

    runButton.Activated:Connect(function()
        local result = invoke(CommandRemote, commandBox.Text)
        status.Text = result.message or "No response."
        status.TextColor3 = result.ok and Color3.fromRGB(126, 235, 174) or Color3.fromRGB(255, 130, 140)
    end)

    toggleEditor.Activated:Connect(function()
        setEditorVisible(not editorTitle.Visible)
    end)

    applyGravity.Activated:Connect(function()
        local result = invoke(ConfigRemote, "Gravity", gravityBox.Text)
        status.Text = result.message or "No response."
        status.TextColor3 = result.ok and Color3.fromRGB(126, 235, 174) or Color3.fromRGB(255, 130, 140)
    end)

    applyTime.Activated:Connect(function()
        local result = invoke(ConfigRemote, "ClockTime", timeBox.Text)
        status.Text = result.message or "No response."
        status.TextColor3 = result.ok and Color3.fromRGB(126, 235, 174) or Color3.fromRGB(255, 130, 140)
    end)

    local dragging = false
    local dragStart
    local startPosition
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)

    local function fit()
        local camera = Workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            scale.Scale = math.min(1, (viewport.X - 24) / 460, (viewport.Y - 24) / 390)
        end
    end
    fit()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
    end

    local root = ReplicatedStorage:WaitForChild("Fxield")
    root:GetAttributeChangedSignal("AnnouncementNonce"):Connect(function()
        local message = root:GetAttribute("AnnouncementText")
        if type(message) == "string" and message ~= "" then
            status.Text = "ANNOUNCEMENT: " .. message
            status.TextColor3 = Color3.fromRGB(255, 220, 120)
        end
    end)

    panel.BackgroundTransparency = 1
    TweenService:Create(panel, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
end

local localPlayer = Players.LocalPlayer
task.spawn(buildUI, localPlayer)
print("[Fxield] Client UI loaded.")
]=]

local serverScript = ServerScriptService:FindFirstChild("FxieldMain")
if not serverScript then
    serverScript = Instance.new("Script")
    serverScript.Name = "FxieldMain"
    serverScript.Parent = ServerScriptService
end
serverScript.Source = serverSource

local starterScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local clientScript = starterScripts:FindFirstChild("FxieldClient")
if not clientScript then
    clientScript = Instance.new("LocalScript")
    clientScript.Name = "FxieldClient"
    clientScript.Parent = starterScripts
end
clientScript.Source = clientSource

print("Fxield installed. Runtime uses a secure server script and a client UI script.")
print("Configure the key and verified owner username at the top of FxieldMain.")

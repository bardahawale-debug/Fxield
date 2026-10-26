-- FXIELD | MainScript ModuleScript
-- Put this ModuleScript in ReplicatedStorage and name it MainScript.
-- UI-only client gate; use server-side checks for real authorization.

return function()
    -- FXIELD | Mobile-friendly standalone UI
    -- Place as a LocalScript in StarterPlayerScripts or StarterGui in your own Roblox experience.
    -- A client-only key check is for UI gating only; use server-side validation for real access control.

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- This is only a client-side UI gate, not secure authentication.
    if player:GetAttribute("FxieldSessionAuthorized") ~= true then
        warn("Fxield: key.lua authorization is required before opening the main UI.")
        return
    end

    local CONFIG = {
        AppName = "Fxield",
        OwnerUsername = "FxplayzOfficial",
        AccessKey = "GrW5_12freekeys-17091gsk82kHoBqjsfDgjJE",
        Theme = {
            Background = Color3.fromRGB(18, 19, 25),
            Panel = Color3.fromRGB(27, 29, 38),
            PanelSoft = Color3.fromRGB(35, 37, 48),
            Accent = Color3.fromRGB(132, 112, 255),
            AccentSoft = Color3.fromRGB(55, 48, 91),
            Text = Color3.fromRGB(245, 245, 250),
            Muted = Color3.fromRGB(165, 168, 185),
            Good = Color3.fromRGB(105, 213, 158),
            Bad = Color3.fromRGB(255, 119, 130),
            Border = Color3.fromRGB(54, 56, 70),
        }
    }

    local old = playerGui:FindFirstChild("FxieldUI")
    if old then old:Destroy() end

    local verifiedThisSession = false
    local isOwner = string.lower(player.Name) == string.lower(CONFIG.OwnerUsername)

    local function make(className, props, parent)
        local object = Instance.new(className)
        for key, value in pairs(props or {}) do
            object[key] = value
        end
        object.Parent = parent
        return object
    end

    local function round(parent, radius)
        make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
    end

    local function stroke(parent, color, transparency)
        make("UIStroke", {
            Color = color or CONFIG.Theme.Border,
            Transparency = transparency or 0,
            Thickness = 1
        }, parent)
    end

    local function pad(parent, left, right, top, bottom)
        make("UIPadding", {
            PaddingLeft = UDim.new(0, left or 0),
            PaddingRight = UDim.new(0, right or 0),
            PaddingTop = UDim.new(0, top or 0),
            PaddingBottom = UDim.new(0, bottom or 0),
        }, parent)
    end

    local gui = make("ScreenGui", {
        Name = "FxieldUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 50,
    }, playerGui)

    local shell = make("Frame", {
        Name = "Shell",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 360, 0, 430),
        BackgroundColor3 = CONFIG.Theme.Background,
        BorderSizePixel = 0,
    }, gui)
    round(shell, 18)
    stroke(shell, CONFIG.Theme.Border)
    make("UISizeConstraint", {
        MinSize = Vector2.new(300, 340),
        MaxSize = Vector2.new(430, 560),
    }, shell)

    local scale = make("UIScale", {Scale = 1}, shell)
    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local available = math.min(viewport.X - 24, viewport.Y - 70)
        scale.Scale = math.clamp(available / 430, 0.72, 1)
    end
    updateScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end

    local header = make("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = CONFIG.Theme.Panel,
        BorderSizePixel = 0,
    }, shell)
    round(header, 18)
    local headerMask = make("Frame", {
        Position = UDim2.new(0, 0, 1, -18),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundColor3 = CONFIG.Theme.Panel,
        BorderSizePixel = 0,
    }, header)

    local logo = make("Frame", {
        Position = UDim2.new(0, 14, 0, 13),
        Size = UDim2.new(0, 36, 0, 36),
        BackgroundColor3 = CONFIG.Theme.Accent,
        BorderSizePixel = 0,
    }, header)
    round(logo, 12)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        Text = "F",
        TextSize = 22,
        TextColor3 = Color3.new(1, 1, 1),
    }, logo)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 60, 0, 11),
        Size = UDim2.new(1, -145, 0, 23),
        Font = Enum.Font.GothamBold,
        Text = "Fxield",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = CONFIG.Theme.Text,
    }, header)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 60, 0, 33),
        Size = UDim2.new(1, -145, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "Your in-game helper",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = CONFIG.Theme.Muted,
    }, header)

    local minimize = make("TextButton", {
        Name = "Minimize",
        Position = UDim2.new(1, -78, 0, 15),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = CONFIG.Theme.PanelSoft,
        BorderSizePixel = 0,
        Text = "–",
        Font = Enum.Font.GothamBold,
        TextSize = 19,
        TextColor3 = CONFIG.Theme.Text,
        AutoButtonColor = true,
    }, header)
    round(minimize, 9)

    local close = make("TextButton", {
        Name = "Close",
        Position = UDim2.new(1, -42, 0, 15),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = Color3.fromRGB(73, 39, 49),
        BorderSizePixel = 0,
        Text = "×",
        Font = Enum.Font.Gotham,
        TextSize = 20,
        TextColor3 = CONFIG.Theme.Text,
        AutoButtonColor = true,
    }, header)
    round(close, 9)

    local body = make("Frame", {
        Name = "Body",
        Position = UDim2.new(0, 0, 0, 62),
        Size = UDim2.new(1, 0, 1, -62),
        BackgroundTransparency = 1,
    }, shell)
    pad(body, 14, 14, 12, 12)

    local pages = {}
    local activePage
    local function newPage(name)
        local page = make("ScrollingFrame", {
            Name = name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = CONFIG.Theme.Accent,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, body)
        make("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)
        pages[name] = page
        return page
    end

    local function showPage(name)
        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
        end
        activePage = pages[name]
    end

    local function label(parent, text, size, color, height)
        return make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, height or 24),
            Font = Enum.Font.Gotham,
            Text = text,
            TextSize = size or 13,
            TextColor3 = color or CONFIG.Theme.Text,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
        }, parent)
    end

    local function card(parent, height)
        local frame = make("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = CONFIG.Theme.Panel,
            BorderSizePixel = 0,
        }, parent)
        round(frame, 13)
        stroke(frame, CONFIG.Theme.Border, 0.35)
        pad(frame, 12, 12, 10, 10)
        return frame
    end

    local function button(parent, text, callback, height)
        local b = make("TextButton", {
            Size = UDim2.new(1, 0, 0, height or 42),
            BackgroundColor3 = CONFIG.Theme.AccentSoft,
            BorderSizePixel = 0,
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = CONFIG.Theme.Text,
            TextWrapped = true,
            AutoButtonColor = true,
        }, parent)
        round(b, 11)
        b.Activated:Connect(callback)
        return b
    end

    local function status(parent, message, good)
        local c = good and CONFIG.Theme.Good or CONFIG.Theme.Bad
        local box = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = good and Color3.fromRGB(28, 58, 47) or Color3.fromRGB(67, 35, 43),
            BorderSizePixel = 0,
            Text = message,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = c,
            TextWrapped = true,
        }, parent)
        round(box, 10)
        return box
    end

    local accessPage = newPage("Access")
    local accessCard = card(accessPage, 246)
    label(accessCard, "Welcome to Fxield", 19, CONFIG.Theme.Text, 28)
    label(accessCard, "Enter your access key to unlock this interface.", 12, CONFIG.Theme.Muted, 36)

    local keyBox = make("TextBox", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = CONFIG.Theme.PanelSoft,
        BorderSizePixel = 0,
        PlaceholderText = "Paste access key here",
        PlaceholderColor3 = CONFIG.Theme.Muted,
        Text = "",
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = CONFIG.Theme.Text,
    }, accessCard)
    round(keyBox, 10)
    pad(keyBox, 10, 10, 0, 0)

    local accessStatus = label(accessCard, "Access is checked locally in this standalone demo.", 11, CONFIG.Theme.Muted, 34)
    accessStatus.TextYAlignment = Enum.TextYAlignment.Center

    local unlock = button(accessCard, "Unlock Fxield", function() end, 42)
    unlock.Position = UDim2.new(0, 0, 1, -48)
    unlock.AnchorPoint = Vector2.new(0, 0)
    accessStatus.Position = UDim2.new(0, 0, 0, 114)
    keyBox.Position = UDim2.new(0, 0, 0, 74)

    local homePage = newPage("Home")
    local welcomeCard = card(homePage, 95)
    label(welcomeCard, "Hey, " .. player.DisplayName .. " 👋", 18, CONFIG.Theme.Text, 27)
    label(welcomeCard, "Choose a tool below, or ask the helper what it does.", 12, CONFIG.Theme.Muted, 40)

    local helperCard = card(homePage, 136)
    label(helperCard, "Fxield helper", 15, CONFIG.Theme.Text, 24)
    label(helperCard, "I can explain the interface and help you find settings. This built-in helper uses local tips, not a live AI connection.", 12, CONFIG.Theme.Muted, 54)
    button(helperCard, "Show beginner tips", function()
        showPage("Assistant")
    end, 38)

    local toolsCard = card(homePage, 126)
    label(toolsCard, "Quick tools", 15, CONFIG.Theme.Text, 24)
    button(toolsCard, "Movement help", function()
        showPage("Movement")
    end, 36)
    button(toolsCard, "Settings & information", function()
        showPage("Settings")
    end, 36)

    local movementPage = newPage("Movement")
    local movementCard = card(movementPage, 164)
    label(movementCard, "Movement help", 17, CONFIG.Theme.Text, 26)
    label(movementCard, "This page explains movement controls. It does not enable flight or alter the current game’s server state.", 12, CONFIG.Theme.Muted, 54)
    label(movementCard, "• Use your game’s normal movement controls.\n• Check the experience’s own settings for supported movement options.", 12, CONFIG.Theme.Text, 55)
    button(movementCard, "Back to home", function() showPage("Home") end, 36)

    local assistantPage = newPage("Assistant")
    local assistantCard = card(assistantPage, 275)
    label(assistantCard, "Ask Fxield", 17, CONFIG.Theme.Text, 26)
    label(assistantCard, "Choose a question and I’ll show a built-in answer.", 12, CONFIG.Theme.Muted, 34)
    local answer = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 76),
        BackgroundColor3 = CONFIG.Theme.PanelSoft,
        BorderSizePixel = 0,
        Text = "Hi! Pick a question below to get started.",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = CONFIG.Theme.Text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, assistantCard)
    round(answer, 10)
    pad(answer, 10, 10, 9, 9)

    local function setAnswer(text)
        answer.Text = text
    end

    button(assistantCard, "How do I use Fxield?", function()
        setAnswer("Open Home, then choose a tool. Use the top minus button to minimize the window, or X to close it.")
    end, 36)
    button(assistantCard, "Why is my key not working?", function()
        setAnswer("Check that the key has no extra spaces and matches exactly. This local check is not secure server authentication.")
    end, 36)
    button(assistantCard, "Is this a real AI?", function()
        setAnswer("No. This version has built-in help messages. A live AI assistant would need a separate, secure service.")
    end, 36)

    local settingsPage = newPage("Settings")
    local settingsCard = card(settingsPage, 184)
    label(settingsCard, "Settings & information", 17, CONFIG.Theme.Text, 27)
    label(settingsCard, "App: Fxield\nOwner label: " .. CONFIG.OwnerUsername .. "\nPlatform: Roblox Lua UI\nAccess: local session check only", 12, CONFIG.Theme.Muted, 76)
    button(settingsCard, "Back to home", function() showPage("Home") end, 36)
    label(settingsCard, "For a real owner-only gate, validate the user on the server. Never trust a client-only key.", 11, CONFIG.Theme.Bad, 42)

    local nav = make("Frame", {
        Name = "Navigation",
        Position = UDim2.new(0, 0, 1, -52),
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = CONFIG.Theme.Panel,
        BorderSizePixel = 0,
        Visible = false,
    }, body)
    round(nav, 13)
    pad(nav, 5, 5, 5, 5)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 5),
    }, nav)

    local function navButton(text, pageName)
        local b = make("TextButton", {
            Size = UDim2.new(0.25, -5, 1, 0),
            BackgroundColor3 = CONFIG.Theme.PanelSoft,
            BorderSizePixel = 0,
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = CONFIG.Theme.Text,
        }, nav)
        round(b, 9)
        b.Activated:Connect(function() showPage(pageName) end)
    end
    navButton("Home", "Home")
    navButton("Help", "Assistant")
    navButton("Move", "Movement")
    navButton("Settings", "Settings")

    local function unlockInterface()
        local supplied = keyBox.Text
        if supplied ~= CONFIG.AccessKey then
            accessStatus.Text = "That key doesn’t match. Check it and try again."
            accessStatus.TextColor3 = CONFIG.Theme.Bad
            return
        end

        verifiedThisSession = true
        nav.Visible = true
        body.Size = UDim2.new(1, 0, 1, -62)
        showPage("Home")

        if isOwner then
            accessStatus.Text = "Owner identity matched for this session."
            accessStatus.TextColor3 = CONFIG.Theme.Good
        end
    end

    unlock.Activated:Connect(unlockInterface)
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then unlockInterface() end
    end)

    local minimized = false
    local previousSize = shell.Size
    minimize.Activated:Connect(function()
        minimized = not minimized
        if minimized then
            previousSize = shell.Size
            TweenService:Create(shell, TweenInfo.new(0.18), {
                Size = UDim2.new(0, 240, 0, 62)
            }):Play()
            body.Visible = false
            minimize.Text = "+"
        else
            TweenService:Create(shell, TweenInfo.new(0.18), {
                Size = previousSize
            }):Play()
            body.Visible = true
            minimize.Text = "–"
        end
    end)

    close.Activated:Connect(function()
        gui:Destroy()
    end)

    local dragging = false
    local dragStart
    local startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = shell.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            shell.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    showPage("Access")

end

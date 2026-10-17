-- Main Scripts | ESP + Aimbot v30 — Fixed toggles + Platform hotbar
-- Executor required. Client-side only.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local GLASS = {
    bg = Color3.fromRGB(28, 32, 44),
    bgTransparency = 0.6,
    bgRow = Color3.fromRGB(45, 50, 68),
    bgRowTransparency = 0.65,
    bgFold = Color3.fromRGB(38, 42, 58),
    bgFoldTransparency = 0.58,
    strokeColor = Color3.fromRGB(255, 255, 255),
    strokeTransparency = 0.88,
    strokeThickness = 1.2,
    accent = Color3.fromRGB(255, 90, 90),
    accentOff = Color3.fromRGB(70, 76, 100),
    text = Color3.fromRGB(248, 248, 255),
    textDim = Color3.fromRGB(200, 205, 220),
}

local config = {
    highlight = false, hitbox = false, hp = false, toolname = false,
    distance = false, name = false, inventory = false, teamColor = false,
    aimbot = false, wallcheck = false, teamcheck = false, fovCircle = false,
    rainbowFov = false, targetHead = true, fov = 90,
}

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local maxHotbarSlots = isMobile and 3 or 10

local aimKey = nil
local aimMouse = nil
local aimHeld = false
local hidden = false
local closed = false
local notifiedOnce = false
local FAR_DISTANCE = 5000
local lockedTarget = nil

local parent = (gethui and gethui()) or CoreGui
local old = parent:FindFirstChild("MainScriptsUI")
if old then old:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "MainScriptsUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = parent

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0, 0)
main.Size = UDim2.new(0, 280, 0, 460)
main.Position = UDim2.new(0.5, -140, 0.75, -230)
main.BackgroundColor3 = GLASS.bg
main.BackgroundTransparency = GLASS.bgTransparency
main.BorderSizePixel = 0
main.Active = true
main.Draggable = false
main.ClipsDescendants = true
main.Parent = screen

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = GLASS.strokeColor
stroke.Thickness = GLASS.strokeThickness
stroke.Transparency = GLASS.strokeTransparency
stroke.Parent = main

local glassHighlight = Instance.new("Frame")
glassHighlight.Size = UDim2.new(1, 0, 0.5, 0)
glassHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glassHighlight.BackgroundTransparency = 0.92
glassHighlight.BorderSizePixel = 0
glassHighlight.ZIndex = 0
glassHighlight.Parent = main
Instance.new("UICorner", glassHighlight).CornerRadius = UDim.new(0, 16)

local highlightGrad = Instance.new("UIGradient")
highlightGrad.Rotation = 90
highlightGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1),
})
highlightGrad.Parent = glassHighlight

local notifShowing = false
local function showNotification(text, duration)
    duration = duration or 4
    if notifShowing then return end
    notifShowing = true
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 320, 0, 60)
    notif.Position = UDim2.new(1, 340, 1, -140)
    notif.BackgroundColor3 = GLASS.bg
    notif.BackgroundTransparency = GLASS.bgTransparency
    notif.BorderSizePixel = 0
    notif.ZIndex = 100
    notif.Parent = screen
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 14)
    local ns = Instance.new("UIStroke")
    ns.Color = GLASS.strokeColor
    ns.Thickness = 1.2
    ns.Transparency = 0.85
    ns.Parent = notif
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -16)
    accent.Position = UDim2.new(0, 8, 0, 8)
    accent.BackgroundColor3 = GLASS.accent
    accent.BorderSizePixel = 0
    accent.Parent = notif
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)
    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, -30, 1, 0)
    nl.Position = UDim2.new(0, 22, 0, 0)
    nl.BackgroundTransparency = 1
    nl.Text = text
    nl.TextColor3 = GLASS.text
    nl.Font = Enum.Font.GothamMedium
    nl.TextSize = 13
    nl.TextWrapped = true
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.Parent = notif
    TweenService:Create(notif, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -340, 1, -140)
    }):Play()
    task.delay(duration, function()
        local outTween = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 340, 1, -140)
        })
        outTween:Play()
        outTween.Completed:Connect(function()
            notif:Destroy()
            notifShowing = false
        end)
    end)
end

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1
header.Active = true
header.ZIndex = 3
header.Parent = main

local dragging = false
local dragOffset = Vector2.new(0, 0)
local blockDrag = false
local posX, posY = nil, nil
local targetX, targetY = nil, nil
local velX, velY = 0, 0

task.spawn(function()
    task.wait()
    posX = main.AbsolutePosition.X
    posY = main.AbsolutePosition.Y
    targetX = posX
    targetY = posY
end)

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if blockDrag then return end
        dragging = true
        local mouse = UserInputService:GetMouseLocation()
        if posX == nil then
            posX = main.AbsolutePosition.X
            posY = main.AbsolutePosition.Y
        end
        dragOffset = Vector2.new(mouse.X - posX, mouse.Y - posY)
        velX = 0
        velY = 0
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

local function setBlockDrag()
    blockDrag = true
    task.delay(0.05, function() blockDrag = false end)
end

RunService.RenderStepped:Connect(function()
    if closed then return end
    if posX == nil then return end
    if dragging then
        local mouse = UserInputService:GetMouseLocation()
        targetX = mouse.X - dragOffset.X
        targetY = mouse.Y - dragOffset.Y
    end
    local dx = targetX - posX
    local dy = targetY - posY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1.5 then
        posX = targetX
        posY = targetY
        velX = 0
        velY = 0
        main.Position = UDim2.new(0, posX, 0, posY)
        return
    end
    local wantVX = dx * 0.22
    local wantVY = dy * 0.22
    if dragging then
        velX = velX + (wantVX - velX) * 0.35
        velY = velY + (wantVY - velY) * 0.35
    else
        velX = velX * 0.82 + wantVX * 0.18
        velY = velY * 0.82 + wantVY * 0.18
    end
    local spd = math.sqrt(velX * velX + velY * velY)
    if spd > 80 then
        local k = 80 / spd
        velX = velX * k
        velY = velY * k
    end
    if not dragging and spd < 0.15 then
        posX = targetX
        posY = targetY
        velX = 0
        velY = 0
        main.Position = UDim2.new(0, posX, 0, posY)
        return
    end
    posX = posX + velX
    posY = posY + velY
    main.Position = UDim2.new(0, posX, 0, posY)
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 40)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Main Scripts"
title.TextColor3 = GLASS.text
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = main

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -62, 0, 9)
minimizeBtn.BackgroundColor3 = GLASS.bgRow
minimizeBtn.BackgroundTransparency = 0.5
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = GLASS.textDim
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.BorderSizePixel = 0
minimizeBtn.AutoButtonColor = false
minimizeBtn.ZIndex = 5
minimizeBtn.Parent = main
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)
minimizeBtn.MouseButton1Down:Connect(setBlockDrag)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 26, 0, 26)
close.Position = UDim2.new(1, -34, 0, 9)
close.BackgroundColor3 = GLASS.bgRow
close.BackgroundTransparency = 0.5
close.Text = "×"
close.TextColor3 = GLASS.textDim
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.ZIndex = 5
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
close.MouseButton1Down:Connect(setBlockDrag)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Size = UDim2.new(1, -20, 1, -58)
scroll.Position = UDim2.new(0, 10, 0, 48)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = GLASS.textDim
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarImageTransparency = 0.5
scroll.ZIndex = 2
scroll.Parent = main

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 6)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scroll

local toggleButtons = {}
local onToggleChanged = nil
local suppressToggleChange = false

local function setToggleVisual(key, state, animate)
    local t = toggleButtons[key]
    if not t then return end
    local targetBg = state and GLASS.accent or GLASS.accentOff
    local targetPos = state and UDim2.new(1, -20, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    if animate then
        TweenService:Create(t.btn, TweenInfo.new(0.15), {BackgroundColor3 = targetBg}):Play()
        TweenService:Create(t.knob, TweenInfo.new(0.15), {Position = targetPos}):Play()
    else
        t.btn.BackgroundColor3 = targetBg
        t.knob.Position = targetPos
    end
end

local function makeToggle(parent, labelText, key, order)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = GLASS.bgRow
    row.BackgroundTransparency = GLASS.bgRowTransparency
    row.Text = ""
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = GLASS.textDim
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 2
    lbl.Parent = row
    
    local knobBg = Instance.new("Frame")
    knobBg.Size = UDim2.new(0, 42, 0, 22)
    knobBg.Position = UDim2.new(1, -54, 0.5, -11)
    knobBg.BackgroundColor3 = GLASS.accentOff
    knobBg.BorderSizePixel = 0
    knobBg.ZIndex = 2
    knobBg.Parent = row
    Instance.new("UICorner", knobBg).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = knobBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    toggleButtons[key] = {btn = knobBg, knob = knob}
    
    row.MouseButton1Click:Connect(function()
        if key == "highlight" then
            if not config.highlight then
                config.highlight = true
                config.hitbox = false
                setToggleVisual("highlight", true, true)
                setToggleVisual("hitbox", false, true)
            else
                config.highlight = false
                setToggleVisual("highlight", false, true)
            end
        elseif key == "hitbox" then
            if not config.hitbox then
                config.hitbox = true
                config.highlight = false
                setToggleVisual("hitbox", true, true)
                setToggleVisual("highlight", false, true)
            else
                config.hitbox = false
                setToggleVisual("hitbox", false, true)
            end
        else
            config[key] = not config[key]
            setToggleVisual(key, config[key], true)
        end
        if onToggleChanged and not suppressToggleChange then
            onToggleChanged(key, config[key])
        end
    end)
    return row
end

local function makeFold(parent, titleText, order, defaultOpen)
    local open = defaultOpen == true
    local arrowText = open and "▼" or "▶"
    local foldHeader = Instance.new("TextButton")
    foldHeader.Size = UDim2.new(1, 0, 0, 34)
    foldHeader.BackgroundColor3 = GLASS.bgFold
    foldHeader.BackgroundTransparency = GLASS.bgFoldTransparency
    foldHeader.Text = ""
    foldHeader.BorderSizePixel = 0
    foldHeader.AutoButtonColor = false
    foldHeader.LayoutOrder = order
    foldHeader.Parent = parent
    Instance.new("UICorner", foldHeader).CornerRadius = UDim.new(0, 10)
    local foldLbl = Instance.new("TextLabel")
    foldLbl.Size = UDim2.new(1, -40, 1, 0)
    foldLbl.Position = UDim2.new(0, 14, 0, 0)
    foldLbl.BackgroundTransparency = 1
    foldLbl.Text = titleText
    foldLbl.TextColor3 = GLASS.text
    foldLbl.Font = Enum.Font.GothamBold
    foldLbl.TextSize = 14
    foldLbl.TextXAlignment = Enum.TextXAlignment.Left
    foldLbl.ZIndex = 2
    foldLbl.Parent = foldHeader
    local foldArrow = Instance.new("TextLabel")
    foldArrow.Size = UDim2.new(0, 20, 0, 20)
    foldArrow.Position = UDim2.new(1, -28, 0.5, -10)
    foldArrow.BackgroundTransparency = 1
    foldArrow.Text = arrowText
    foldArrow.TextColor3 = GLASS.textDim
    foldArrow.Font = Enum.Font.GothamBold
    foldArrow.TextSize = 12
    foldArrow.ZIndex = 2
    foldArrow.Parent = foldHeader
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 0)
    wrap.BackgroundTransparency = 1
    wrap.BorderSizePixel = 0
    wrap.ClipsDescendants = true
    wrap.LayoutOrder = order + 1
    wrap.Parent = parent
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 0, 0)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.Parent = wrap
    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 6)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body
    local function updateHeight()
        if not open then return end
        local h = bodyLayout.AbsoluteContentSize.Y
        wrap.Size = UDim2.new(1, 0, 0, h)
        body.Size = UDim2.new(1, 0, 0, h)
    end
    updateHeight()
    bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
    if not open then
        wrap.Size = UDim2.new(1, 0, 0, 0)
        body.Visible = false
    end
    foldHeader.MouseButton1Click:Connect(function()
        open = not open
        foldArrow.Text = open and "▼" or "▶"
        if open then
            body.Visible = true
            local targetH = bodyLayout.AbsoluteContentSize.Y
            TweenService:Create(wrap, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
                Size = UDim2.new(1, 0, 0, targetH)
            }):Play()
        else
            TweenService:Create(wrap, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            task.delay(0.28, function()
                if not open then body.Visible = false end
            end)
        end
    end)
    return body
end

local espBody = makeFold(scroll, "ESP", 1, false)
local aimBody = makeFold(scroll, "Aimbot", 3, false)

local mainEspRow = Instance.new("TextButton")
mainEspRow.Size = UDim2.new(1, 0, 0, 34)
mainEspRow.BackgroundColor3 = Color3.fromRGB(60, 30, 36)
mainEspRow.BackgroundTransparency = 0.6
mainEspRow.Text = ""
mainEspRow.BorderSizePixel = 0
mainEspRow.AutoButtonColor = false
mainEspRow.LayoutOrder = 1
mainEspRow.Parent = espBody
Instance.new("UICorner", mainEspRow).CornerRadius = UDim.new(0, 10)
local mainEspLbl = Instance.new("TextLabel")
mainEspLbl.Size = UDim2.new(1, -60, 1, 0)
mainEspLbl.Position = UDim2.new(0, 14, 0, 0)
mainEspLbl.BackgroundTransparency = 1
mainEspLbl.Text = "Main ESP"
mainEspLbl.TextColor3 = Color3.fromRGB(255, 180, 180)
mainEspLbl.Font = Enum.Font.GothamBold
mainEspLbl.TextSize = 13
mainEspLbl.TextXAlignment = Enum.TextXAlignment.Left
mainEspLbl.ZIndex = 2
mainEspLbl.Parent = mainEspRow
local mainEspIndicator = Instance.new("Frame")
mainEspIndicator.Size = UDim2.new(0, 20, 0, 20)
mainEspIndicator.Position = UDim2.new(1, -32, 0.5, -10)
mainEspIndicator.BackgroundColor3 = GLASS.accentOff
mainEspIndicator.BorderSizePixel = 0
mainEspIndicator.ZIndex = 2
mainEspIndicator.Parent = mainEspRow
Instance.new("UICorner", mainEspIndicator).CornerRadius = UDim.new(1, 0)

makeToggle(espBody, "Highlight (red)", "highlight", 2)
makeToggle(espBody, "Hitbox (white)", "hitbox", 3)
makeToggle(espBody, "Health", "hp", 4)
makeToggle(espBody, "Tool Name", "toolname", 5)
makeToggle(espBody, "Distance", "distance", 6)
makeToggle(espBody, "Name", "name", 7)
makeToggle(espBody, "Team Color", "teamColor", 8)
makeToggle(espBody, "Inventory", "inventory", 9)

local mainEspActive = false

local function setMainEspVisual(state, animate)
    local targetBg = state and GLASS.accent or GLASS.accentOff
    if animate then
        TweenService:Create(mainEspIndicator, TweenInfo.new(0.15), {BackgroundColor3 = targetBg}):Play()
    else
        mainEspIndicator.BackgroundColor3 = targetBg
    end
end

local function isFullMainEspState()
    return config.highlight == true and config.hitbox == false
        and config.hp == true and config.toolname == true
        and config.distance == true and config.name == true
end

onToggleChanged = function()
    if suppressToggleChange then return end
    local stillFull = isFullMainEspState()
    if mainEspActive and not stillFull then
        mainEspActive = false
        setMainEspVisual(false, true)
    elseif not mainEspActive and stillFull then
        mainEspActive = true
        setMainEspVisual(true, true)
    end
end

local function applyMainEsp(state)
    suppressToggleChange = true
    if state then
        config.highlight = true
        config.hitbox = false
        config.hp = true
        config.toolname = true
        config.distance = true
        config.name = true
    else
        config.highlight = false
        config.hitbox = false
        config.hp = false
        config.toolname = false
        config.distance = false
        config.name = false
    end
    setToggleVisual("highlight", config.highlight, true)
    setToggleVisual("hitbox", config.hitbox, true)
    setToggleVisual("hp", config.hp, true)
    setToggleVisual("toolname", config.toolname, true)
    setToggleVisual("distance", config.distance, true)
    setToggleVisual("name", config.name, true)
    suppressToggleChange = false
end

mainEspRow.MouseButton1Click:Connect(function()
    mainEspActive = not mainEspActive
    setMainEspVisual(mainEspActive, true)
    applyMainEsp(mainEspActive)
end)

makeToggle(aimBody, "Aimbot", "aimbot", 1)
makeToggle(aimBody, "Wallcheck", "wallcheck", 2)
makeToggle(aimBody, "Teamcheck", "teamcheck", 3)
makeToggle(aimBody, "FOV Circle", "fovCircle", 4)
makeToggle(aimBody, "Rainbow FOV", "rainbowFov", 5)

local aimKeyRow = Instance.new("Frame")
aimKeyRow.Size = UDim2.new(1, 0, 0, 34)
aimKeyRow.BackgroundColor3 = GLASS.bgRow
aimKeyRow.BackgroundTransparency = GLASS.bgRowTransparency
aimKeyRow.BorderSizePixel = 0
aimKeyRow.LayoutOrder = 6
aimKeyRow.Parent = aimBody
Instance.new("UICorner", aimKeyRow).CornerRadius = UDim.new(0, 10)

local aimKeyLbl = Instance.new("TextLabel")
aimKeyLbl.Size = UDim2.new(1, -90, 1, 0)
aimKeyLbl.Position = UDim2.new(0, 14, 0, 0)
aimKeyLbl.BackgroundTransparency = 1
aimKeyLbl.Text = "Aim key"
aimKeyLbl.TextColor3 = GLASS.textDim
aimKeyLbl.Font = Enum.Font.Gotham
aimKeyLbl.TextSize = 13
aimKeyLbl.TextXAlignment = Enum.TextXAlignment.Left
aimKeyLbl.ZIndex = 2
aimKeyLbl.Parent = aimKeyRow

local aimKeyBtn = Instance.new("TextButton")
aimKeyBtn.Size = UDim2.new(0, 70, 0, 22)
aimKeyBtn.Position = UDim2.new(1, -82, 0.5, -11)
aimKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
aimKeyBtn.BackgroundTransparency = 0.92
aimKeyBtn.Text = "..."
aimKeyBtn.TextColor3 = GLASS.text
aimKeyBtn.Font = Enum.Font.GothamMedium
aimKeyBtn.TextSize = 12
aimKeyBtn.BorderSizePixel = 0
aimKeyBtn.AutoButtonColor = false
aimKeyBtn.ZIndex = 2
aimKeyBtn.Parent = aimKeyRow
Instance.new("UICorner", aimKeyBtn).CornerRadius = UDim.new(0, 8)

local awaitingKey = false

local function formatKeyName(name)
    return name:gsub("^Enum.KeyCode.", ""):gsub("^Enum.UserInputType.", "")
end

local function updateAimKeyText()
    if aimKey then
        aimKeyBtn.Text = formatKeyName(tostring(aimKey))
    elseif aimMouse then
        if aimMouse == Enum.UserInputType.MouseButton1 then
            aimKeyBtn.Text = "LMB"
        elseif aimMouse == Enum.UserInputType.MouseButton2 then
            aimKeyBtn.Text = "RMB"
        elseif aimMouse == Enum.UserInputType.MouseButton3 then
            aimKeyBtn.Text = "MMB"
        else
            aimKeyBtn.Text = "Mouse"
        end
    else
        aimKeyBtn.Text = "..."
    end
end

aimKeyBtn.MouseButton1Click:Connect(function()
    awaitingKey = true
    aimKeyBtn.Text = "Press key..."
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not awaitingKey then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then return end
    if input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Enum.KeyCode.Escape then
        awaitingKey = false
        aimKey = nil
        aimMouse = nil
        updateAimKeyText()
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        awaitingKey = false
        aimKey = nil
        aimMouse = nil
        updateAimKeyText()
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        aimKey = input.KeyCode
        aimMouse = nil
    elseif input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3 then
        aimMouse = input.UserInputType
        aimKey = nil
    else
        awaitingKey = false
        updateAimKeyText()
        return
    end
    awaitingKey = false
    updateAimKeyText()
end)

updateAimKeyText()

local targetRow = Instance.new("Frame")
targetRow.Size = UDim2.new(1, 0, 0, 34)
targetRow.BackgroundColor3 = GLASS.bgRow
targetRow.BackgroundTransparency = GLASS.bgRowTransparency
targetRow.BorderSizePixel = 0
targetRow.LayoutOrder = 7
targetRow.Parent = aimBody
Instance.new("UICorner", targetRow).CornerRadius = UDim.new(0, 10)

local targetLbl = Instance.new("TextLabel")
targetLbl.Size = UDim2.new(1, -100, 1, 0)
targetLbl.Position = UDim2.new(0, 14, 0, 0)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = "Target part"
targetLbl.TextColor3 = GLASS.textDim
targetLbl.Font = Enum.Font.Gotham
targetLbl.TextSize = 13
targetLbl.TextXAlignment = Enum.TextXAlignment.Left
targetLbl.ZIndex = 2
targetLbl.Parent = targetRow

local targetBtn = Instance.new("TextButton")
targetBtn.Size = UDim2.new(0, 60, 0, 22)
targetBtn.Position = UDim2.new(1, -72, 0.5, -11)
targetBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
targetBtn.BackgroundTransparency = 0.92
targetBtn.Text = "head"
targetBtn.TextColor3 = GLASS.text
targetBtn.Font = Enum.Font.GothamMedium
targetBtn.TextSize = 12
targetBtn.BorderSizePixel = 0
targetBtn.AutoButtonColor = false
targetBtn.ZIndex = 2
targetBtn.Parent = targetRow
Instance.new("UICorner", targetBtn).CornerRadius = UDim.new(0, 8)

targetBtn.MouseButton1Click:Connect(function()
    config.targetHead = not config.targetHead
    targetBtn.Text = config.targetHead and "head" or "body"
end)

local fovRow = Instance.new("Frame")
fovRow.Size = UDim2.new(1, 0, 0, 54)
fovRow.BackgroundColor3 = GLASS.bgRow
fovRow.BackgroundTransparency = GLASS.bgRowTransparency
fovRow.BorderSizePixel = 0
fovRow.LayoutOrder = 8
fovRow.Parent = aimBody
Instance.new("UICorner", fovRow).CornerRadius = UDim.new(0, 10)

local fovLbl = Instance.new("TextLabel")
fovLbl.Size = UDim2.new(1, -100, 0, 18)
fovLbl.Position = UDim2.new(0, 14, 0, 6)
fovLbl.BackgroundTransparency = 1
fovLbl.Text = "FOV radius"
fovLbl.TextColor3 = GLASS.textDim
fovLbl.Font = Enum.Font.Gotham
fovLbl.TextSize = 13
fovLbl.TextXAlignment = Enum.TextXAlignment.Left
fovLbl.ZIndex = 2
fovLbl.Parent = fovRow

local fovInput = Instance.new("TextBox")
fovInput.Size = UDim2.new(0, 60, 0, 20)
fovInput.Position = UDim2.new(1, -72, 0, 4)
fovInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fovInput.BackgroundTransparency = 0.92
fovInput.Text = tostring(config.fov)
fovInput.TextColor3 = GLASS.text
fovInput.Font = Enum.Font.GothamMedium
fovInput.TextSize = 12
fovInput.BorderSizePixel = 0
fovInput.ClearTextOnFocus = false
fovInput.ZIndex = 2
fovInput.Parent = fovRow
Instance.new("UICorner", fovInput).CornerRadius = UDim.new(0, 8)

local FOV_MIN, FOV_MAX = 10, 500

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -28, 0, 6)
sliderBg.Position = UDim2.new(0, 14, 1, -16)
sliderBg.BackgroundColor3 = GLASS.accentOff
sliderBg.BorderSizePixel = 0
sliderBg.ZIndex = 2
sliderBg.Parent = fovRow
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((config.fov - FOV_MIN) / (FOV_MAX - FOV_MIN), 0, 1, 0)
sliderFill.BackgroundColor3 = GLASS.accent
sliderFill.BorderSizePixel = 0
sliderFill.ZIndex = 3
sliderFill.Parent = sliderBg
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new((config.fov - FOV_MIN) / (FOV_MAX - FOV_MIN), 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.ZIndex = 4
sliderKnob.Parent = sliderBg
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local sliderDragging = false

local function applyFov(value)
    value = math.clamp(math.floor(value), FOV_MIN, FOV_MAX)
    config.fov = value
    fovInput.Text = tostring(value)
    local rel = (value - FOV_MIN) / (FOV_MAX - FOV_MIN)
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    sliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
end

local function updateFovFromX(x)
    local rel = (x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
    rel = math.clamp(rel, 0, 1)
    applyFov(FOV_MIN + rel * (FOV_MAX - FOV_MIN))
end

sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        updateFovFromX(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not sliderDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        updateFovFromX(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

fovInput.FocusLost:Connect(function()
    local n = tonumber(fovInput.Text)
    if n then applyFov(n) else fovInput.Text = tostring(config.fov) end
end)

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FovCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Size = UDim2.new(0, config.fov * 2, 0, config.fov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.ZIndex = 1
fovCircle.Parent = screen

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1
fovStroke.Transparency = 0.4
fovStroke.Parent = fovCircle

Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)

local rainbowHue = 0

RunService.RenderStepped:Connect(function(dt)
    if closed then return end
    local mouseLoc = UserInputService:GetMouseLocation()
    fovCircle.Position = UDim2.new(0, mouseLoc.X, 0, mouseLoc.Y)
    fovCircle.Size = UDim2.new(0, config.fov * 2, 0, config.fov * 2)
    fovCircle.Visible = config.fovCircle and config.aimbot
    if config.rainbowFov and fovCircle.Visible then
        rainbowHue = (rainbowHue + dt * 0.5) % 1
        fovStroke.Color = Color3.fromHSV(rainbowHue, 1, 1)
        fovStroke.Transparency = 0.2
    else
        fovStroke.Color = Color3.fromRGB(255, 255, 255)
        fovStroke.Transparency = 0.4
    end
end)

local espData = {}
local COL_NAME = "rgb(255, 255, 255)"
local COL_HP   = "rgb(120, 255, 120)"
local COL_TOOL = "rgb(255, 220, 120)"
local COL_DIST = "rgb(180, 180, 255)"
local COL_SEP  = "rgb(120, 120, 120)"

local BODY_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

local function clearESP(player)
    local d = espData[player]
    if not d then return end
    if d.highlight then d.highlight:Destroy() end
    if d.hitboxParts then
        for _, p in ipairs(d.hitboxParts) do
            if p and p.Parent then p:Destroy() end
        end
    end
    if d.textLabel then d.textLabel:Destroy() end
    if d.invLabel then d.invLabel:Destroy() end
    espData[player] = nil
end

local function clearAllESP()
    for player, _ in pairs(espData) do clearESP(player) end
    espData = {}
end

local function getHighlightColor(player)
    if config.teamColor then
        local team = player.Team
        if team then return team.TeamColor.Color end
    end
    return Color3.fromRGB(255, 0, 0)
end

local function getHitboxColor(player)
    if config.teamColor then
        local team = player.Team
        if team then return team.TeamColor.Color end
    end
    return Color3.fromRGB(255, 255, 255)
end

local function ensureHighlight(player)
    local d = espData[player]
    local targetColor = getHighlightColor(player)
    if d.highlight then
        d.highlight.FillColor = targetColor
        d.highlight.OutlineColor = targetColor
        return d.highlight
    end
    local char = player.Character
    if not char then return nil end
    local h = Instance.new("Highlight")
    h.Name = "MS_Highlight"
    h.Adornee = char
    h.FillColor = targetColor
    h.FillTransparency = 0.7
    h.OutlineColor = targetColor
    h.OutlineTransparency = 0.2
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    d.highlight = h
    return h
end

local function clearHitbox(player)
    local d = espData[player]
    if not d or not d.hitboxParts then return end
    for _, p in ipairs(d.hitboxParts) do
        if p and p.Parent then p:Destroy() end
    end
    d.hitboxParts = nil
end

local function ensureHitbox(player)
    local d = espData[player]
    local targetColor = getHitboxColor(player)
    if d.hitboxParts then
        for _, box in ipairs(d.hitboxParts) do
            if box and box.Parent then box.Color3 = targetColor end
        end
        return
    end
    local char = player.Character
    if not char then return end
    d.hitboxParts = {}
    for _, name in ipairs(BODY_PARTS) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "MS_Hitbox"
            box.Adornee = part
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Size = part.Size
            box.Color3 = targetColor
            box.Transparency = 0.3
            box.Parent = part
            table.insert(d.hitboxParts, box)
        end
    end
end

local function ensureTextLabel(player)
    local d = espData[player]
    if d.textLabel then return d.textLabel end
    local lbl = Instance.new("TextLabel")
    lbl.Name = "MS_EspText_" .. player.Name
    lbl.BackgroundTransparency = 1
    lbl.AnchorPoint = Vector2.new(0.5, 1)
    lbl.Size = UDim2.new(0, 400, 0, 18)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.RichText = true
    lbl.TextStrokeTransparency = 0.5
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Bottom
    lbl.Text = ""
    lbl.Visible = false
    lbl.ZIndex = 2
    lbl.Parent = screen
    d.textLabel = lbl
    return lbl
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    if not espData[player] then espData[player] = {} end
    local function onChar(char)
        local d = espData[player]
        if not d then return end
        if d.highlight then d.highlight:Destroy() d.highlight = nil end
        clearHitbox(player)
        if d.invLabel then d.invLabel.Visible = false end
    end
    player.CharacterAdded:Connect(onChar)
    if player.Character then onChar(player.Character) end
end

local conns = {}
table.insert(conns, Players.PlayerAdded:Connect(setupPlayer))
table.insert(conns, Players.PlayerRemoving:Connect(function(p) clearESP(p) end))
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not config.aimbot then return end
    if aimKey and input.KeyCode == aimKey then aimHeld = true lockedTarget = nil end
    if aimMouse and input.UserInputType == aimMouse then aimHeld = true lockedTarget = nil end
end)

UserInputService.InputEnded:Connect(function(input)
    if aimKey and input.KeyCode == aimKey then aimHeld = false lockedTarget = nil end
    if aimMouse and input.UserInputType == aimMouse then aimHeld = false lockedTarget = nil end
end)

local function hasLineOfSight(fromPos, toPart)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, toPart.Parent}
    params.IgnoreWater = true
    local result = workspace:Raycast(fromPos, toPart.Position - fromPos, params)
    return result == nil
end

local function isEnemy(player)
    if not config.teamcheck then return true end
    local myTeam = LocalPlayer.Team
    if not myTeam then return true end
    return player.Team ~= myTeam
end

local function findTarget()
    local camPos = Camera.CFrame.Position
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    local mouse = UserInputService:GetMouseLocation()
    local targetX, targetY
    if config.fovCircle then
        targetX = mouse.X
        targetY = mouse.Y
    else
        targetX = centerX
        targetY = centerY
    end
    local best = nil
    local bestDist = config.fov
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")
                local targetPart = nil
                if humanoid and humanoid.Health > 0 then
                    if config.targetHead then
                        targetPart = head
                    else
                        targetPart = char:FindFirstChild("UpperTorso")
                            or char:FindFirstChild("Torso")
                            or char:FindFirstChild("HumanoidRootPart")
                    end
                end
                if targetPart then
                    if isEnemy(player) then
                        local visible = true
                        if config.wallcheck then
                            visible = hasLineOfSight(camPos, targetPart)
                        end
                        if visible then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            if onScreen then
                                local dx = screenPos.X - targetX
                                local dy = screenPos.Y - targetY
                                local dist = math.sqrt(dx * dx + dy * dy)
                                if dist < bestDist then
                                    bestDist = dist
                                    best = targetPart
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function isTargetValid(t)
    if not t or not t.Parent then return false end
    local humanoid = t.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return false end
    return true
end

RunService:BindToRenderStep("MS_AimbotLock", Enum.RenderPriority.Camera.Value + 1, function()
    if closed then return end
    if not config.aimbot then return end
    if not aimHeld then return end
    if not isTargetValid(lockedTarget) then
        lockedTarget = findTarget()
    end
    if not lockedTarget then return end
    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
    local camPos = Camera.CFrame.Position
    Camera.CFrame = CFrame.new(camPos, lockedTarget.Position)
end)

UserInputService.InputEnded:Connect(function(input)
    local wasHeld = false
    if aimKey and input.KeyCode == aimKey then wasHeld = true end
    if aimMouse and input.UserInputType == aimMouse then wasHeld = true end
    if wasHeld then
        aimHeld = false
        lockedTarget = nil
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

local FULL_W, FULL_H = 280, 460
local animState = nil
local animT = 0
local animFromW, animFromH = 0, 0
local animCenterX, animCenterY = 0, 0
local lastSizeW, lastSizeH = 280, 460

local function startHideAnim()
    if animState then return end
    animCenterX = posX + lastSizeW / 2
    animCenterY = posY + lastSizeH / 2
    animFromW = lastSizeW
    animFromH = lastSizeH
    animT = 0
    animState = "hiding"
end

local function startShowAnim()
    if animState then return end
    animCenterX = posX + lastSizeW / 2
    animCenterY = posY + lastSizeH / 2
    animFromW = lastSizeW
    animFromH = lastSizeH
    animT = 0
    animState = "showing"
end

RunService.RenderStepped:Connect(function(dt)
    if closed then return end
    if not animState then return end
    animT = animT + (dt / 0.3)
    if animT > 1 then animT = 1 end
    local e = 1 - (1 - animT) ^ 3
    local fromW = animFromW
    local fromH = animFromH
    local toW, toH
    if animState == "hiding" then
        toW = 2
        toH = 2
    else
        toW = FULL_W
        toH = FULL_H
    end
    local w = fromW + (toW - fromW) * e
    local h = fromH + (toH - fromH) * e
    posX = animCenterX - w / 2
    posY = animCenterY - h / 2
    targetX = posX
    targetY = posY
    lastSizeW = w
    lastSizeH = h
    main.Size = UDim2.new(0, w, 0, h)
    main.Position = UDim2.new(0, posX, 0, posY)
    if animState == "hiding" then
        main.BackgroundTransparency = GLASS.bgTransparency + e * (1 - GLASS.bgTransparency)
    else
        main.BackgroundTransparency = 1 - e * (1 - GLASS.bgTransparency)
    end
    if animT >= 1 then
        if animState == "hiding" then
            main.Visible = false
        else
            main.Visible = true
            main.BackgroundTransparency = GLASS.bgTransparency
        end
        animState = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if closed then return end
    if animState then return end
    local s = main.AbsoluteSize
    lastSizeW = s.X
    lastSizeH = s.Y
end)

local function hideMenu()
    if hidden or closed then return end
    if animState then return end
    hidden = true
    startHideAnim()
end

local function showMenu()
    if not hidden or closed then return end
    if animState then return end
    hidden = false
    main.Visible = true
    lastSizeW = 2
    lastSizeH = 2
    main.Size = UDim2.new(0, 2, 0, 2)
    main.Position = UDim2.new(0, posX, 0, posY)
    startShowAnim()
end

local function toggleVisibility()
    if closed then return end
    if hidden then showMenu() else hideMenu() end
end

local function fullClose()
    closed = true
    for key, _ in pairs(config) do
        if type(config[key]) == "boolean" then config[key] = false end
    end
    for key, _ in pairs(toggleButtons) do setToggleVisual(key, false, false) end
    setMainEspVisual(false, false)
    clearAllESP()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    for _, c in ipairs(conns) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    screen:Destroy()
end

minimizeBtn.MouseButton1Click:Connect(function()
    hideMenu()
    if not notifiedOnce then
        notifiedOnce = true
        showNotification("Press [G] to show/hide the menu", 4)
    end
end)

close.MouseButton1Click:Connect(fullClose)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then toggleVisibility() end
end)

RunService.RenderStepped:Connect(function()
    if closed then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position
    local camPos = Camera.CFrame.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local d = espData[player]
            if d then
                local char = player.Character
                local head = char and char:FindFirstChild("Head")
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if config.highlight and char then
                    local h = ensureHighlight(player)
                    if h then h.Adornee = char end
                else
                    if d.highlight then d.highlight:Destroy() d.highlight = nil end
                end
                if config.hitbox and char then
                    ensureHitbox(player)
                    if d.hitboxParts then
                        for _, box in ipairs(d.hitboxParts) do
                            if box.Adornee then box.Size = box.Adornee.Size end
                        end
                    end
                else
                    clearHitbox(player)
                end
                local needText = config.hp or config.toolname or config.distance or config.name
                if needText and head then
                    local lbl = ensureTextLabel(player)
                    local headPos = head.Position + Vector3.new(0, 2, 0)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
                    if onScreen then
                        local camDist = nil
                        if myPos then camDist = (camPos - head.Position).Magnitude end
                        local isFar = camDist and camDist > FAR_DISTANCE
                        if isFar then
                            if config.name then
                                lbl.Text = string.format('<font color="%s">%s</font>', COL_NAME, player.Name)
                                lbl.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                                lbl.Visible = true
                            else
                                lbl.Visible = false
                            end
                        else
                            local parts = {}
                            if config.name then
                                table.insert(parts, string.format('<font color="%s">%s</font>', COL_NAME, player.Name))
                            end
                            if config.hp and humanoid then
                                table.insert(parts, string.format('<font color="%s">HP: %d/%d</font>', COL_HP,
                                    math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)))
                            end
                            if config.toolname then
                                local tool = char:FindFirstChildOfClass("Tool")
                                local toolText = tool and ("Item: " .. tool.Name) or "No Item"
                                table.insert(parts, string.format('<font color="%s">%s</font>', COL_TOOL, toolText))
                            end
                            if config.distance and myPos and root then
                                local dist = (myPos - root.Position).Magnitude
                                table.insert(parts, string.format('<font color="%s">%d studs</font>', COL_DIST, math.floor(dist)))
                            end
                            if #parts > 0 then
                                local sep = string.format(' <font color="%s">|</font> ', COL_SEP)
                                lbl.Text = table.concat(parts, sep)
                                lbl.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                                lbl.Visible = true
                            else
                                lbl.Visible = false
                            end
                        end
                    else
                        lbl.Visible = false
                    end
                else
                    if d.textLabel then d.textLabel.Visible = false end
                end
                if config.inventory and char and head then
                    if not d.invLabel then
                        d.invLabel = Instance.new("TextLabel")
                        d.invLabel.Name = "MS_InvText_" .. player.Name
                        d.invLabel.BackgroundTransparency = 1
                        d.invLabel.AnchorPoint = Vector2.new(0.5, 1)
                        d.invLabel.Size = UDim2.new(0, 400, 0, 18)
                        d.invLabel.Font = Enum.Font.GothamBold
                        d.invLabel.TextSize = 13
                        d.invLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        d.invLabel.RichText = true
                        d.invLabel.TextStrokeTransparency = 0.5
                        d.invLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        d.invLabel.TextXAlignment = Enum.TextXAlignment.Center
                        d.invLabel.TextYAlignment = Enum.TextYAlignment.Bottom
                        d.invLabel.Text = ""
                        d.invLabel.Visible = false
                        d.invLabel.ZIndex = 2
                        d.invLabel.Parent = screen
                    end
                    local items = {}
                    local bp = player:FindFirstChild("Backpack")
                    if bp then
                        local idx = 0
                        for _, tool in ipairs(bp:GetChildren()) do
                            if tool:IsA("Tool") then
                                idx = idx + 1
                                if idx <= maxHotbarSlots then
                                    table.insert(items, tool.Name)
                                end
                            end
                        end
                    end
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") then
                            table.insert(items, tool.Name)
                        end
                    end
                    local headPosInv = head.Position + Vector3.new(0, 2, 0)
                    local screenPosInv, onScreenInv = Camera:WorldToViewportPoint(headPosInv)
                    if onScreenInv and #items > 0 then
                        local parts = {}
                        for _, name in ipairs(items) do
                            table.insert(parts, string.format('<font color="%s">%s</font>', COL_TOOL, name))
                        end
                        local sep = string.format(' <font color="%s">|</font> ', COL_SEP)
                        d.invLabel.Text = '🎒 ' .. table.concat(parts, sep)
                        d.invLabel.Position = UDim2.new(0, screenPosInv.X, 0, screenPosInv.Y - 20)
                        d.invLabel.Visible = true
                    else
                        d.invLabel.Visible = false
                    end
                else
                    if d.invLabel then d.invLabel.Visible = false end
                end
            end
        end
    end
end)

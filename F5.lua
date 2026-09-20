local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    Players.PlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10) or LocalPlayer.PlayerGui

-- Параметры
local espEnabled = false
local espColor = Color3.fromRGB(255, 60, 60)
local aimEnabled = false
local aimFov = 110
local aimSharpness = 0.25

local espHighlights = {}

-- ----------------------------------------------------
-- ИНТЕРФЕЙС
-- ----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheatMenuMobile"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- Круг FOV
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FovCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 1
fovCircle.Parent = screenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.4
fovStroke.Parent = fovCircle

-- ----------------------------------------------------
-- ПЛАВАЮЩАЯ КНОПКА
-- ----------------------------------------------------
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MenuCircleBtn"
toggleBtn.Size = UDim2.new(0, 58, 0, 58)
toggleBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
toggleBtn.Text = "⚙"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 24
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.Active = true
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(65, 65, 80)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggleBtn

-- ----------------------------------------------------
-- ГЛАВНОЕ ОКНО
-- ----------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.ZIndex = 20
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(50, 50, 65)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- Шапка
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 21
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "НАСТРОЙКИ"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 22
titleLabel.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 22
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

-- Контейнер карточек (теперь скроллящийся)
local cardsContainer = Instance.new("ScrollingFrame")
cardsContainer.Position = UDim2.new(0, 0, 0, 46)
cardsContainer.Size = UDim2.new(1, 0, 1, -46)
cardsContainer.BackgroundTransparency = 1
cardsContainer.BorderSizePixel = 0
cardsContainer.ScrollBarThickness = 3
cardsContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
cardsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
cardsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
cardsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
cardsContainer.ZIndex = 21
cardsContainer.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = cardsContainer

local containerPadding = Instance.new("UIPadding")
containerPadding.PaddingTop = UDim.new(0, 4)
containerPadding.PaddingBottom = UDim.new(0, 8)
containerPadding.Parent = cardsContainer

-- ----------------------------------------------------
-- КАРТОЧКИ
-- ----------------------------------------------------
local function createFeatureCard(name, order)
    local card = Instance.new("Frame")
    card.Name = name .. "Card"
    card.Size = UDim2.new(0.92, 0, 0, 46)
    card.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    card.ClipsDescendants = true
    card.LayoutOrder = order
    card.ZIndex = 22
    card.Parent = cardsContainer

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(42, 42, 54)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, 0, 0, 46)
    topRow.BackgroundTransparency = 1
    topRow.ZIndex = 23
    topRow.Parent = card

    local fTitle = Instance.new("TextLabel")
    fTitle.Size = UDim2.new(0.5, 0, 1, 0)
    fTitle.Position = UDim2.new(0, 12, 0, 0)
    fTitle.BackgroundTransparency = 1
    fTitle.Text = name
    fTitle.TextColor3 = Color3.fromRGB(235, 235, 245)
    fTitle.Font = Enum.Font.GothamMedium
    fTitle.TextSize = 13
    fTitle.TextXAlignment = Enum.TextXAlignment.Left
    fTitle.ZIndex = 24
    fTitle.Parent = topRow

    local arrow = Instance.new("TextButton")
    arrow.Size = UDim2.new(0, 36, 0, 36)
    arrow.Position = UDim2.new(1, -96, 0.5, -18)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▶"
    arrow.TextColor3 = Color3.fromRGB(160, 160, 180)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.ZIndex = 24
    arrow.Parent = topRow

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 46, 0, 26)
    switch.Position = UDim2.new(1, -54, 0.5, -13)
    switch.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    switch.Text = ""
    switch.ZIndex = 24
    switch.Parent = topRow

    local switchCorn = Instance.new("UICorner")
    switchCorn.CornerRadius = UDim.new(1, 0)
    switchCorn.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.ZIndex = 25
    knob.Parent = switch

    local knobCorn = Instance.new("UICorner")
    knobCorn.CornerRadius = UDim.new(1, 0)
    knobCorn.Parent = knob

    local subArea = Instance.new("Frame")
    subArea.Size = UDim2.new(1, -20, 0, 50)
    subArea.Position = UDim2.new(0, 10, 0, 46)
    subArea.BackgroundTransparency = 1
    subArea.ZIndex = 23
    subArea.Parent = card

    return card, switch, knob, arrow, subArea
end

local espCard, espSwitch, espKnob, espArrow, espSub = createFeatureCard("ESP (Подсветка)", 1)
local aimCard, aimSwitch, aimKnob, aimArrow, aimSub = createFeatureCard("Aim (Наведение)", 2)

-- Палитра цветов ESP
local colorList = Instance.new("UIListLayout")
colorList.FillDirection = Enum.FillDirection.Horizontal
colorList.HorizontalAlignment = Enum.HorizontalAlignment.Center
colorList.VerticalAlignment = Enum.VerticalAlignment.Center
colorList.Padding = UDim.new(0, 10)
colorList.Parent = espSub

local colors = {
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(60, 255, 120),
    Color3.fromRGB(60, 170, 255),
    Color3.fromRGB(255, 220, 60),
    Color3.fromRGB(200, 80, 255)
}

for _, col in ipairs(colors) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.BackgroundColor3 = col
    btn.Text = ""
    btn.ZIndex = 25
    btn.Parent = espSub

    local cCorn = Instance.new("UICorner")
    cCorn.CornerRadius = UDim.new(1, 0)
    cCorn.Parent = btn

    btn.Activated:Connect(function()
        espColor = col
        for _, hl in pairs(espHighlights) do
            if hl and hl.Parent then
                hl.FillColor = espColor
            end
        end
    end)
end

-- Настройки Aim
local aimList = Instance.new("UIListLayout")
aimList.FillDirection = Enum.FillDirection.Horizontal
aimList.HorizontalAlignment = Enum.HorizontalAlignment.Center
aimList.VerticalAlignment = Enum.VerticalAlignment.Center
aimList.Padding = UDim.new(0, 10)
aimList.Parent = aimSub

local function createAimSubBtn(txt, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 90, 0, 30)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(210, 210, 230)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 11
    b.ZIndex = 25
    b.Parent = aimSub

    local bCorn = Instance.new("UICorner")
    bCorn.CornerRadius = UDim.new(0, 6)
    bCorn.Parent = b

    b.Activated:Connect(fn)
    return b
end

local fovBtn = createAimSubBtn("FOV: 110", function()
    aimFov = (aimFov == 110) and 160 or 110
    fovBtn.Text = "FOV: " .. tostring(aimFov)
    fovCircle.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
end)

local sharpBtn = createAimSubBtn("Резкость: Ср", function()
    if aimSharpness == 0.25 then
        aimSharpness = 0.5
        sharpBtn.Text = "Резкость: Выс"
    elseif aimSharpness == 0.5 then
        aimSharpness = 0.1
        sharpBtn.Text = "Резкость: Мягк"
    else
        aimSharpness = 0.25
        sharpBtn.Text = "Резкость: Ср"
    end
end)

-- ----------------------------------------------------
-- АНИМАЦИЯ МЕНЮ (с защитой от гонки твинов)
-- ----------------------------------------------------
local isMenuOpen = false
local finalMenuSize = UDim2.new(0, 290, 0, 280)
local currentTween = nil

local function setMenuVisible(state)
    isMenuOpen = state
    
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    
    if isMenuOpen then
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 10, 0, 10)
        currentTween = TweenService:Create(
            mainFrame, 
            TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
            {Size = finalMenuSize}
        )
        currentTween:Play()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(45, 110, 240)
        }):Play()
    else
        currentTween = TweenService:Create(
            mainFrame, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        currentTween:Play()
        currentTween.Completed:Connect(function()
            if not isMenuOpen then
                mainFrame.Visible = false
            end
        end)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(22, 22, 26)
        }):Play()
    end
end

closeBtn.Activated:Connect(function()
    setMenuVisible(false)
end)

-- ----------------------------------------------------
-- DRAG И TAP ДЛЯ КНОПКИ (исправлено)
-- ----------------------------------------------------
local dragging = false
local dragStartPos = nil
local buttonStartPos = nil
local isMoved = false
local TAP_THRESHOLD = 8

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch 
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        isMoved = false
        dragStartPos = input.Position
        buttonStartPos = toggleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.Touch 
    or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        -- Двигаем кнопку только если реально тянем (> 8 px)
        if delta.Magnitude > TAP_THRESHOLD then
            isMoved = true
            toggleBtn.Position = UDim2.new(
                buttonStartPos.X.Scale,
                buttonStartPos.X.Offset + delta.X,
                buttonStartPos.Y.Scale,
                buttonStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch 
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging then
            dragging = false
            if not isMoved then
                setMenuVisible(not isMenuOpen)
            end
        end
    end
end)

-- ----------------------------------------------------
-- СВИТЧИ
-- ----------------------------------------------------
local function bindSwitch(switchBtn, knob, getState, setState, onStateChange)
    switchBtn.Activated:Connect(function()
        local newState = not getState()
        setState(newState)

        local targetPos = newState and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        local targetColor = newState and Color3.fromRGB(50, 130, 255) or Color3.fromRGB(45, 45, 55)

        TweenService:Create(knob, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(switchBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()

        onStateChange(newState)
    end)
end

bindSwitch(espSwitch, espKnob, function() return espEnabled end, function(v) espEnabled = v end, function(val)
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then
            hl.Enabled = val
        end
    end
end)

bindSwitch(aimSwitch, aimKnob, function() return aimEnabled end, function(v) aimEnabled = v end, function(val)
    fovCircle.Visible = val
end)

-- ----------------------------------------------------
-- АККОРДЕОН
-- ----------------------------------------------------
local function bindAccordion(card, arrow, targetH)
    local opened = false
    arrow.Activated:Connect(function()
        opened = not opened
        TweenService:Create(card, TweenInfo.new(0.2), {
            Size = UDim2.new(0.92, 0, 0, opened and targetH or 46)
        }):Play()
        TweenService:Create(arrow, TweenInfo.new(0.2), {
            Rotation = opened and 90 or 0
        }):Play()
    end)
end

bindAccordion(espCard, espArrow, 105)
bindAccordion(aimCard, aimArrow, 105)

-- ----------------------------------------------------
-- ESP (HIGHLIGHT)
-- ----------------------------------------------------
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        local highlight = char:FindFirstChild("PlayerHighlight") or Instance.new("Highlight")
        highlight.Name = "PlayerHighlight"
        highlight.FillColor = espColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.1
        highlight.Adornee = char
        highlight.Enabled = espEnabled
        highlight.Parent = char
        espHighlights[player] = highlight
    end

    if player.Character then
        setupChar(player.Character)
    end
    player.CharacterAdded:Connect(setupChar)
end

for _, p in ipairs(Players:GetPlayers()) do
    applyESP(p)
end
Players.PlayerAdded:Connect(applyESP)
Players.PlayerRemoving:Connect(function(p)
    espHighlights[p] = nil
end)

-- ----------------------------------------------------
-- AIM (с проверкой препятствий)
-- ----------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude  -- ✅ ИСПРАВЛЕНО
rayParams.IgnoreWater = true

local function isVisible(head)
    if not LocalPlayer.Character then return false end
    local camPos = Camera.CFrame.Position
    local dir = head.Position - camPos

    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, head.Parent}
    local hit = Workspace:Raycast(camPos, dir, rayParams)
    return hit == nil
end

RunService.RenderStepped:Connect(function()
    if not aimEnabled then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local minDistance = aimFov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist <= minDistance and isVisible(head) then
                        minDistance = dist
                        bestTarget = head
                    end
                end
            end
        end
    end

    if bestTarget then
        local curCF = Camera.CFrame
        local targetCF = CFrame.new(curCF.Position, bestTarget.Position)
        Camera.CFrame = curCF:Lerp(targetCF, math.clamp(aimSharpness, 0.05, 1))
    end
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Настройки модулей
local espEnabled = false
local espColor = Color3.fromRGB(255, 60, 60)
local aimFeatureEnabled = false -- Включен ли аим в меню
local aimActive = false         -- Активен ли захват по кнопке 🎯
local aimFov = 110
local aimSharpness = 0.25

local espHighlights = {}

-- ----------------------------------------------------
-- СОЗДАНИЕ GUI
-- ----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileCheatGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- Критично для мобильных тачей
screenGui.DisplayOrder = 100
screenGui.Parent = PlayerGui

-- Круг зоны наведения (FOV)
local fovCircle = Instance.new("Frame")
fovCircle.Name = "AimFovCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = screenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.35
fovStroke.Parent = fovCircle

-- ----------------------------------------------------
-- ФУНКЦИЯ СОЗДАНИЯ ПЕРЕМЕЩАЕМОЙ КНОПКИ-КРУЖКА
-- ----------------------------------------------------
local function makeDraggableCircle(name, text, startPos, onClick)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 54, 0, 54)
    btn.Position = startPos
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 22
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Active = true
    btn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 75)
    stroke.Thickness = 2
    stroke.Parent = btn

    local dragging = false
    local touchStartTime = 0
    local touchStartPos = Vector3.new()
    local btnStartPos = UDim2.new()

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            touchStartTime = tick()
            touchStartPos = input.Position
            btnStartPos = btn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - touchStartPos
            btn.Position = UDim2.new(
                btnStartPos.X.Scale,
                btnStartPos.X.Offset + delta.X,
                btnStartPos.Y.Scale,
                btnStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local touchDuration = tick() - touchStartTime
            local moveDist = (input.Position - touchStartPos).Magnitude
            dragging = false

            -- Если палец удерживался недолго и сдвинулся меньше 20px — это клик
            if touchDuration < 0.45 and moveDist < 20 then
                onClick()
            end
        end
    end)

    return btn
end

-- ----------------------------------------------------
-- ОСНОВНОЕ МЕНЮ
-- ----------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.ZIndex = 5
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(50, 50, 65)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 42)
title.Position = UDim2.new(0, 16, 0, 8)
title.BackgroundTransparency = 1
title.Text = "ПАНЕЛЬ УПРАВЛЕНИЯ"
title.TextColor3 = Color3.fromRGB(240, 240, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = mainFrame

local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 45)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 0
spacer.Parent = mainFrame

-- ----------------------------------------------------
-- КАРТОЧКИ ФУНКЦИЙ (ESP И AIM)
-- ----------------------------------------------------
local function createFeatureCard(name, order)
    local card = Instance.new("Frame")
    card.Name = name .. "Card"
    card.Size = UDim2.new(0.92, 0, 0, 46)
    card.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    card.ClipsDescendants = true
    card.LayoutOrder = order
    card.Active = true
    card.Parent = mainFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(40, 40, 52)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundTransparency = 1
    row.Parent = card

    local cardTitle = Instance.new("TextLabel")
    cardTitle.Size = UDim2.new(0.5, 0, 1, 0)
    cardTitle.Position = UDim2.new(0, 12, 0, 0)
    cardTitle.BackgroundTransparency = 1
    cardTitle.Text = name
    cardTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
    cardTitle.Font = Enum.Font.GothamMedium
    cardTitle.TextSize = 13
    cardTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardTitle.Parent = row

    local arrowBtn = Instance.new("TextButton")
    arrowBtn.Size = UDim2.new(0, 36, 0, 36)
    arrowBtn.Position = UDim2.new(1, -94, 0.5, -18)
    arrowBtn.BackgroundTransparency = 1
    arrowBtn.Text = "▶"
    arrowBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
    arrowBtn.Font = Enum.Font.GothamBold
    arrowBtn.TextSize = 13
    arrowBtn.Parent = row

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 46, 0, 26)
    switch.Position = UDim2.new(1, -54, 0.5, -13)
    switch.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    switch.Text = ""
    switch.Parent = row

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switch

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local subArea = Instance.new("Frame")
    subArea.Size = UDim2.new(1, -20, 0, 55)
    subArea.Position = UDim2.new(0, 10, 0, 46)
    subArea.BackgroundTransparency = 1
    subArea.Parent = card

    return card, switch, knob, arrowBtn, subArea
end

local espCard, espSwitch, espKnob, espArrow, espSub = createFeatureCard("ESP (Подсветка)", 1)
local aimCard, aimSwitch, aimKnob, aimArrow, aimSub = createFeatureCard("Aim (Наведение)", 2)

-- Палитра цветов ESP
local espColors = {
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(60, 255, 120),
    Color3.fromRGB(60, 170, 255),
    Color3.fromRGB(255, 220, 60),
    Color3.fromRGB(200, 80, 255)
}

local espSubLayout = Instance.new("UIListLayout")
espSubLayout.FillDirection = Enum.FillDirection.Horizontal
espSubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
espSubLayout.VerticalAlignment = Enum.VerticalAlignment.Center
espSubLayout.Padding = UDim.new(0, 10)
espSubLayout.Parent = espSub

for _, color in ipairs(espColors) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 28, 0, 28)
    cBtn.BackgroundColor3 = color
    cBtn.Text = ""
    cBtn.Parent = espSub

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(1, 0)
    cCorner.Parent = cBtn

    cBtn.Activated:Connect(function()
        espColor = color
        for _, hl in pairs(espHighlights) do
            if hl and hl.Parent then
                hl.FillColor = espColor
            end
        end
    end)
end

-- Настройки Aim в подменю
local aimSubLayout = Instance.new("UIListLayout")
aimSubLayout.FillDirection = Enum.FillDirection.Horizontal
aimSubLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
aimSubLayout.VerticalAlignment = Enum.VerticalAlignment.Center
aimSubLayout.Parent = aimSub

local function createAimOption(label, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 84, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(220, 220, 235)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = aimSub

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.Activated:Connect(onClick)
    return btn
end

local fovBtn = createAimOption("FOV: 110", function()
    aimFov = (aimFov == 110) and 160 or 110
    fovCircle.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
end)

createAimOption("Резкость", function()
    aimSharpness = (aimSharpness >= 0.5) and 0.15 or (aimSharpness + 0.15)
end)

-- ----------------------------------------------------
-- КНОПКИ УПРАВЛЕНИЯ И АНИМАЦИИ
-- ----------------------------------------------------
local isMenuOpen = false
local targetMenuSize = UDim2.new(0, 290, 0, 220)

local function toggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 20, 0, 20)
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetMenuSize
        }):Play()
    else
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            if not isMenuOpen then
                mainFrame.Visible = false
            end
        end)
    end
end

-- Создание главного кружка меню (⚙)
local menuBtn = makeDraggableCircle("MenuCircle", "⚙", UDim2.new(0, 25, 0.45, 0), toggleMenu)

-- Создание кружка Aim (🎯)
local aimTargetBtn = nil
local function toggleAimTarget()
    aimActive = not aimActive
    fovCircle.Visible = aimActive
    if aimTargetBtn then
        TweenService:Create(aimTargetBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = aimActive and Color3.fromRGB(230, 45, 75) or Color3.fromRGB(22, 22, 28)
        }):Play()
    end
end

aimTargetBtn = makeDraggableCircle("AimCircle", "🎯", UDim2.new(0, 25, 0.56, 0), toggleAimTarget)
aimTargetBtn.Visible = false

-- Переключатели в меню
local function setupToggle(switchBtn, knob, getState, setState, onToggle)
    switchBtn.Activated:Connect(function()
        local newState = not getState()
        setState(newState)

        local targetPos = newState and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        local targetColor = newState and Color3.fromRGB(50, 130, 255) or Color3.fromRGB(45, 45, 55)

        TweenService:Create(knob, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(switchBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()

        onToggle(newState)
    end)
end

setupToggle(espSwitch, espKnob, function() return espEnabled end, function(v) espEnabled = v end, function(enabled)
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then
            hl.Enabled = enabled
        end
    end
end)

setupToggle(aimSwitch, aimKnob, function() return aimFeatureEnabled end, function(v) aimFeatureEnabled = v end, function(enabled)
    aimTargetBtn.Visible = enabled
    if not enabled then
        aimActive = false
        fovCircle.Visible = false
        aimTargetBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    end
end)

-- Раскрытие карточек настроек
local function setupAccordion(card, arrow, targetHeight)
    local open = false
    arrow.Activated:Connect(function()
        open = not open
        TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0.92, 0, 0, open and targetHeight or 46)
        }):Play()
        TweenService:Create(arrow, TweenInfo.new(0.22), {
            Rotation = open and 90 or 0
        }):Play()
    end)
end

setupAccordion(espCard, espArrow, 110)
setupAccordion(aimCard, aimArrow, 110)

-- ----------------------------------------------------
-- ЛОГИКА ESP (HIGHLIGHT)
-- ----------------------------------------------------
local function applyESP(player)
    if player == LocalPlayer then return end

    local function onCharacter(char)
        local highlight = char:FindFirstChild("GameESP") or Instance.new("Highlight")
        highlight.Name = "GameESP"
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
        onCharacter(player.Character)
    end
    player.CharacterAdded:Connect(onCharacter)
end

for _, p in ipairs(Players:GetPlayers()) do
    applyESP(p)
end
Players.PlayerAdded:Connect(applyESP)
Players.PlayerRemoving:Connect(function(p)
    espHighlights[p] = nil
end)

-- ----------------------------------------------------
-- ЛОГИКА AIM И ПРОВЕРКА СТЕН (RAYCAST)
-- ----------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = RaycastParamsFilterType.Exclude
rayParams.IgnoreWater = true

local function isTargetVisible(head)
    if not LocalPlayer.Character then return false end
    local origin = Camera.CFrame.Position
    local direction = head.Position - origin

    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, head.Parent}
    local hit = Workspace:Raycast(origin, direction, rayParams)

    return hit == nil
end

RunService.RenderStepped:Connect(function()
    if not (aimFeatureEnabled and aimActive) then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestHead = nil
    local minDistance = aimFov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                    if dist <= minDistance and isTargetVisible(head) then
                        minDistance = dist
                        bestHead = head
                    end
                end
            end
        end
    end

    if bestHead then
        local camCF = Camera.CFrame
        local targetCF = CFrame.new(camCF.Position, bestHead.Position)
        Camera.CFrame = camCF:Lerp(targetCF, math.clamp(aimSharpness, 0.05, 1))
    end
end)

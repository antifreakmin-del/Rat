local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Параметры работы модулей
local espEnabled = false
local espColor = Color3.fromRGB(255, 55, 55)
local aimEnabled = false
local aimFov = 130
local aimSharpness = 0.2
local showFovCircle = true

-- Таблица для хранения объектов подсветки
local espHighlights = {}

-- ----------------------------------------------------
-- СОЗДАНИЕ ИНТЕРФЕЙСА
-- ----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomGameToolsGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Круг FOV для аима
local fovFrame = Instance.new("Frame")
fovFrame.Name = "FovCircle"
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false
fovFrame.Parent = screenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.4
fovStroke.Parent = fovFrame

-- Плавающая круглая кнопка открытия меню
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MenuToggleCircle"
toggleBtn.Size = UDim2.new(0, 52, 0, 52)
toggleBtn.Position = UDim2.new(0, 24, 0.5, -26)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
toggleBtn.Text = "⚙"
toggleBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(50, 50, 60)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggleBtn

-- Главное меню
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- Заголовок меню
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 0, 45)
titleLabel.Position = UDim2.new(0, 15, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "НАСТРОЙКИ ИГРОКА"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 10)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = mainFrame

local headerSpacer = Instance.new("Frame")
headerSpacer.Size = UDim2.new(1, 0, 0, 40)
headerSpacer.BackgroundTransparency = 1
headerSpacer.LayoutOrder = 0
headerSpacer.Parent = mainFrame

-- Вспомогательная функция для создания карточек функций
local function createFeatureCard(name, layoutOrder)
    local card = Instance.new("Frame")
    card.Name = name .. "Card"
    card.Size = UDim2.new(0.92, 0, 0, 48)
    card.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    card.ClipsDescendants = true
    card.LayoutOrder = layoutOrder
    card.Parent = mainFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(38, 38, 46)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, 0, 0, 48)
    topRow.BackgroundTransparency = 1
    topRow.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = Color3.fromRGB(230, 230, 230)
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topRow

    local arrowBtn = Instance.new("TextButton")
    arrowBtn.Size = UDim2.new(0, 32, 0, 32)
    arrowBtn.Position = UDim2.new(1, -85, 0.5, -16)
    arrowBtn.BackgroundTransparency = 1
    arrowBtn.Text = "▶"
    arrowBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
    arrowBtn.Font = Enum.Font.GothamBold
    arrowBtn.TextSize = 12
    arrowBtn.Parent = topRow

    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(0, 44, 0, 24)
    switchBtn.Position = UDim2.new(1, -52, 0.5, -12)
    switchBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    switchBtn.Text = ""
    switchBtn.Parent = topRow

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBtn

    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 18, 0, 18)
    switchKnob.Position = UDim2.new(0, 3, 0.5, -9)
    switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    switchKnob.Parent = switchBtn

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = switchKnob

    local subPanel = Instance.new("Frame")
    subPanel.Size = UDim2.new(1, -20, 0, 60)
    subPanel.Position = UDim2.new(0, 10, 0, 48)
    subPanel.BackgroundTransparency = 1
    subPanel.Parent = card

    return card, switchBtn, switchKnob, arrowBtn, subPanel
end

local espCard, espSwitch, espKnob, espArrow, espSub = createFeatureCard("ESP (Подсветка)", 1)
local aimCard, aimSwitch, aimKnob, aimArrow, aimSub = createFeatureCard("Aim (Наведение)", 2)

-- ----------------------------------------------------
-- НАСТРОЙКИ ПОДМЕНЮ ESP
-- ----------------------------------------------------
local espColors = {
    {Color3.fromRGB(255, 60, 60), "Красный"},
    {Color3.fromRGB(60, 255, 120), "Зеленый"},
    {Color3.fromRGB(60, 170, 255), "Синий"},
    {Color3.fromRGB(255, 220, 60), "Желтый"},
    {Color3.fromRGB(200, 80, 255), "Фиолетовый"}
}

local colorList = Instance.new("UIListLayout")
colorList.FillDirection = Enum.FillDirection.Horizontal
colorList.HorizontalAlignment = Enum.HorizontalAlignment.Center
colorList.VerticalAlignment = Enum.VerticalAlignment.Center
colorList.Padding = UDim.new(0, 8)
colorList.Parent = espSub

for _, item in ipairs(espColors) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 26, 0, 26)
    cBtn.BackgroundColor3 = item[1]
    cBtn.Text = ""
    cBtn.Parent = espSub

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(1, 0)
    cCorner.Parent = cBtn

    cBtn.MouseButton1Click:Connect(function()
        espColor = item[1]
        for _, hl in pairs(espHighlights) do
            if hl and hl.Parent then
                hl.FillColor = espColor
            end
        end
    end)
end

-- ----------------------------------------------------
-- НАСТРОЙКИ ПОДМЕНЮ AIM
-- ----------------------------------------------------
local aimLayout = Instance.new("UIListLayout")
aimLayout.FillDirection = Enum.FillDirection.Horizontal
aimLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
aimLayout.VerticalAlignment = Enum.VerticalAlignment.Center
aimLayout.Parent = aimSub

local function createOptionBtn(text, parent, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 85, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Parent = parent

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

createOptionBtn("FOV: 90", aimSub, function()
    aimFov = 90
    fovFrame.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
end)

createOptionBtn("FOV: 140", aimSub, function()
    aimFov = 140
    fovFrame.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
end)

createOptionBtn("Резкость", aimSub, function()
    aimSharpness = (aimSharpness >= 0.5) and 0.15 or (aimSharpness + 0.15)
end)

-- ----------------------------------------------------
-- АНИМАЦИИ И ПЕРЕКЛЮЧЕНИЕ ЭЛЕМЕНТОВ
-- ----------------------------------------------------
local isMenuOpen = false
local menuTargetSize = UDim2.new(0, 310, 0, 230)

local function toggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        mainFrame.Visible = true
        TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = menuTargetSize
        }):Play()
        TweenService:Create(toggleBtn, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(50, 110, 240)
        }):Play()
    else
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            if not isMenuOpen then
                mainFrame.Visible = false
            end
        end)
        TweenService:Create(toggleBtn, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        }):Play()
    end
end

toggleBtn.MouseButton1Click:Connect(toggleMenu)

local function setupToggle(switchBtn, switchKnob, getState, setState, onToggle)
    switchBtn.MouseButton1Click:Connect(function()
        local newState = not getState()
        setState(newState)

        local targetPos = newState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local targetColor = newState and Color3.fromRGB(50, 140, 255) or Color3.fromRGB(45, 45, 52)

        TweenService:Create(switchKnob, TweenInfo.new(0.2), {Position = targetPos}):Play()
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

setupToggle(aimSwitch, aimKnob, function() return aimEnabled end, function(v) aimEnabled = v end, function(enabled)
    fovFrame.Visible = enabled and showFovCircle
end)

local function setupAccordion(card, arrowBtn, expandedHeight)
    local isOpen = false
    arrowBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetHeight = isOpen and expandedHeight or 48
        local targetRot = isOpen and 90 or 0

        TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0.92, 0, 0, targetHeight)}):Play()
        TweenService:Create(arrowBtn, TweenInfo.new(0.25), {Rotation = targetRot}):Play()
    end)
end

setupAccordion(espCard, espArrow, 115)
setupAccordion(aimCard, aimArrow, 115)

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
-- ЛОГИКА AIM И ПРОВЕРКА ПРЕПЯТСТВИЙ (RAYCAST)
-- ----------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = RaycastParamsFilterType.Exclude
rayParams.IgnoreWater = true

local function isTargetVisible(targetHead)
    if not LocalPlayer.Character then return false end
    local camPos = Camera.CFrame.Position
    local dir = targetHead.Position - camPos

    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetHead.Parent}
    local hit = Workspace:Raycast(camPos, dir, rayParams)

    return hit == nil
end

RunService.RenderStepped:Connect(function()
    if not aimEnabled then return end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local minDistance = aimFov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            if hum and hum.Health > 0 and head then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                    if dist <= minDistance and isTargetVisible(head) then
                        minDistance = dist
                        bestTarget = head
                    end
                end
            end
        end
    end

    if bestTarget then
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, bestTarget.Position)
        Camera.CFrame = currentCF:Lerp(targetCF, math.clamp(aimSharpness, 0.05, 1))
    end
end)

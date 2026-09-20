-- [[ Modern Minimalist Dark UI Library / Hub - ESP + AIM Edition ]]
-- Place inside a LocalScript (e.g. StarterGui or StarterPlayerScripts)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Clean up existing instances if re-executed
local existingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DarkMenuHub")
if existingGui then
    existingGui:Destroy()
end

-- Cleanup old highlights from previous runs
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        local old = p.Character:FindFirstChild("PlayerHighlight")
        if old then old:Destroy() end
    end
end

-- ==================== SCREEN GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DarkMenuHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== THEME ====================
local Theme = {
    Background = Color3.fromRGB(18, 18, 22),
    Sidebar = Color3.fromRGB(14, 14, 17),
    Card = Color3.fromRGB(24, 24, 30),
    Accent = Color3.fromRGB(110, 86, 248),
    AccentHover = Color3.fromRGB(130, 108, 255),
    Text = Color3.fromRGB(245, 245, 245),
    SubText = Color3.fromRGB(140, 140, 150),
    Border = Color3.fromRGB(36, 36, 45),
    ToggleOff = Color3.fromRGB(35, 35, 42),
    ToggleOn = Color3.fromRGB(110, 86, 248)
}

-- ==================== STATE ====================
local State = {
    -- ESP
    espEnabled = false,
    espColor = Color3.fromRGB(255, 60, 60),
    espFillTransparency = 0.5,
    espOutlineTransparency = 0.1,
    espOutlineColor = Color3.fromRGB(255, 255, 255),
    espTeamCheck = false,
    espMaxDistance = 500,
    espShowNames = false,

    -- AIM
    aimEnabled = false,
    aimFov = 120,
    aimSharpness = 0.25,
    aimTargetPart = "Head",          -- Head / HumanoidRootPart / Nearest
    aimWallCheck = true,
    aimTeamCheck = false,
    aimMaxDistance = 300,
    aimSmooth = true,
    aimVisibleFov = true,
    aimFovColor = Color3.fromRGB(110, 86, 248),
}

local espHighlights = {}
local espBillboards = {}

-- ==================== HELPER: TAP/CLICK ====================
local function bindTap(guiObject, callback)
    local lastPress = 0
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            lastPress = tick()
        end
    end)
    guiObject.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if tick() - lastPress < 0.5 then
                callback()
            end
        end
    end)
end

-- ==================== HELPER: DRAG ====================
local function enableDrag(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==================== FOV CIRCLE ====================
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FovCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, State.aimFov * 2, 0, State.aimFov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 1
fovCircle.Parent = ScreenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = State.aimFovColor
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.4
fovStroke.Parent = fovCircle

-- ==================== TOGGLE BUTTON ====================
local CircleBtn = Instance.new("ImageButton")
CircleBtn.Name = "OpenCircleBtn"
CircleBtn.Size = UDim2.new(0, 54, 0, 54)
CircleBtn.Position = UDim2.new(0.04, 0, 0.45, 0)
CircleBtn.BackgroundColor3 = Theme.Background
CircleBtn.BorderSizePixel = 0
CircleBtn.AutoButtonColor = false
CircleBtn.ZIndex = 10
CircleBtn.Parent = ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = CircleBtn

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Color = Theme.Accent
CircleStroke.Thickness = 2
CircleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CircleStroke.Parent = CircleBtn

local CircleIcon = Instance.new("TextLabel")
CircleIcon.Size = UDim2.new(1, 0, 1, 0)
CircleIcon.BackgroundTransparency = 1
CircleIcon.Text = "⚡"
CircleIcon.TextColor3 = Theme.Accent
CircleIcon.TextSize = 22
CircleIcon.Font = Enum.Font.GothamBold
CircleIcon.Parent = CircleBtn

enableDrag(CircleBtn)

-- ==================== MAIN WINDOW ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainWindow"
MainFrame.Size = UDim2.new(0, 560, 0, 400)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.ZIndex = 20
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 42)
Topbar.BackgroundTransparency = 1
Topbar.ZIndex = 21
Topbar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "DARK HUB // <font color='rgb(110,86,248)'>ESP + AIM</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 22
TitleLabel.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.TextSize = 13
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 22
CloseBtn.Parent = Topbar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

enableDrag(MainFrame, Topbar)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 130, 1, -42)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 21
Sidebar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.Parent = Sidebar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 10)
TabPadding.Parent = Sidebar

-- Content
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -142, 1, -54)
ContentContainer.Position = UDim2.new(0, 136, 0, 48)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 21
ContentContainer.Parent = MainFrame

-- ==================== TAB SYSTEM ====================
local tabs = {}
local activeTab = nil

local function createTab(tabName, iconText)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "Btn"
    tabBtn.Size = UDim2.new(0, 114, 0, 36)
    tabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = "  " .. iconText .. "  " .. tabName
    tabBtn.TextColor3 = Theme.SubText
    tabBtn.Font = Enum.Font.GothamMedium
    tabBtn.TextSize = 13
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.AutoButtonColor = false
    tabBtn.ZIndex = 22
    tabBtn.Parent = Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Visible = false
    page.ZIndex = 22
    page.Parent = ContentContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingRight = UDim.new(0, 8)
    pagePadding.PaddingTop = UDim.new(0, 2)
    pagePadding.PaddingBottom = UDim.new(0, 8)
    pagePadding.Parent = page

    local tabData = { Button = tabBtn, Page = page }
    tabs[tabName] = tabData

    bindTap(tabBtn, function()
        if activeTab == tabData then return end

        for _, t in pairs(tabs) do
            TweenService:Create(t.Button, TweenInfo.new(0.2), {
                BackgroundTransparency = 1,
                TextColor3 = Theme.SubText
            }):Play()
            if t.Page.Visible then
                t.Page.Visible = false
            end
        end

        activeTab = tabData
        tabData.Page.Visible = true

        TweenService:Create(tabBtn, TweenInfo.new(0.25), {
            BackgroundColor3 = Theme.Card,
            BackgroundTransparency = 0,
            TextColor3 = Theme.Text
        }):Play()
    end)

    return page
end

-- ==================== UI BUILDERS ====================

-- Заголовок раздела
local function addSection(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = "— " .. text .. " —"
    label.TextColor3 = Theme.SubText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.ZIndex = 23
    label.Parent = parent
    return label
end

-- Тоггл
local function addToggle(parentPage, text, defaultState, callback)
    local state = defaultState or false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = Theme.Card
    frame.BorderSizePixel = 0
    frame.ZIndex = 23
    frame.Parent = parentPage

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 24
    label.Parent = frame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 42, 0, 22)
    switch.Position = UDim2.new(1, -54, 0.5, -11)
    switch.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
    switch.BorderSizePixel = 0
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.ZIndex = 24
    switch.Parent = frame

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.ZIndex = 25
    circle.Parent = switch

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local function updateToggle()
        local targetColor = state and Theme.ToggleOn or Theme.ToggleOff
        local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        if callback then task.spawn(callback, state) end
    end

    bindTap(switch, function()
        state = not state
        updateToggle()
    end)

    return {
        frame = frame,
        set = function(v) state = v; updateToggle() end,
        get = function() return state end
    }
end

-- Слайдер (с числом)
local function addSlider(parentPage, text, minVal, maxVal, defaultVal, isFloat, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3 = Theme.Card
    frame.BorderSizePixel = 0
    frame.ZIndex = 23
    frame.Parent = parentPage

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 0, 20)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 24
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 20)
    valueLabel.Position = UDim2.new(1, -72, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = isFloat and string.format("%.2f", defaultVal) or tostring(defaultVal)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 24
    valueLabel.Parent = frame

    -- Дорожка
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -28, 0, 6)
    bar.Position = UDim2.new(0, 14, 1, -16)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bar.BorderSizePixel = 0
    bar.ZIndex = 24
    bar.Parent = frame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 25
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 26
    knob.Parent = bar

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local currentVal = defaultVal
    local dragging = false
    local barAbsolute = nil

    local function updateFromX(x)
        if not barAbsolute then return end
        local rel = math.clamp((x - barAbsolute.X) / barAbsolute.Width, 0, 1)
        local val = minVal + (maxVal - minVal) * rel
        if not isFloat then val = math.floor(val + 0.5) end
        currentVal = val
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valueLabel.Text = isFloat and string.format("%.2f", val) or tostring(val)
        if callback then callback(val) end
    end

    local function startDrag(input)
        dragging = true
        barAbsolute = bar.AbsolutePosition
        updateFromX(input.Position.X)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch 
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {
        set = function(v)
            currentVal = v
            local rel = (v - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            valueLabel.Text = isFloat and string.format("%.2f", v) or tostring(v)
        end,
        get = function() return currentVal end
    }
end

-- Выпадающий список
local function addDropdown(parentPage, text, options, defaultOption, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = Theme.Card
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.ZIndex = 23
    frame.Parent = parentPage

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 24
    label.Parent = frame

    local current = defaultOption
    local valueLabel = Instance.new("TextButton")
    valueLabel.Size = UDim2.new(0, 90, 0, 26)
    valueLabel.Position = UDim2.new(1, -100, 0.5, -13)
    valueLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    valueLabel.BorderSizePixel = 0
    valueLabel.Text = current .. "  ▾"
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextSize = 11
    valueLabel.AutoButtonColor = false
    valueLabel.ZIndex = 24
    valueLabel.Parent = frame

    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 6)
    vCorner.Parent = valueLabel

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -20, 0, 0)
    listFrame.Position = UDim2.new(0, 10, 0, 44)
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    listFrame.BorderSizePixel = 0
    listFrame.ClipsDescendants = true
    listFrame.ZIndex = 30
    listFrame.Parent = frame

    local lCorner = Instance.new("UICorner")
    lCorner.CornerRadius = UDim.new(0, 6)
    lCorner.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = listFrame

    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.Parent = listFrame

    local opened = false

    local function rebuildList()
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, -8, 0, 24)
            ob.BackgroundColor3 = (opt == current) and Theme.Accent or Color3.fromRGB(30, 30, 38)
            ob.BorderSizePixel = 0
            ob.Text = opt
            ob.TextColor3 = (opt == current) and Color3.fromRGB(255, 255, 255) or Theme.Text
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 11
            ob.AutoButtonColor = false
            ob.ZIndex = 31
            ob.Parent = listFrame

            local oc = Instance.new("UICorner")
            oc.CornerRadius = UDim.new(0, 4)
            oc.Parent = ob

            bindTap(ob, function()
                current = opt
                valueLabel.Text = opt .. "  ▾"
                rebuildList()
                -- Закрываем список
                opened = false
                TweenService:Create(frame, TweenInfo.new(0.2), {
                    Size = UDim2.new(1, 0, 0, 42)
                }):Play()
                if callback then callback(opt) end
            end)
        end
    end

    bindTap(valueLabel, function()
        opened = not opened
        if opened then
            rebuildList()
            local h = 42 + 8 + #options * 26
            TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, h)
            }):Play()
        else
            TweenService:Create(frame, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 42)
            }):Play()
        end
    end)

    return {
        get = function() return current end,
        set = function(v) current = v; valueLabel.Text = v .. "  ▾" end
    }
end

-- Палитра цветов
local function addColorPicker(parentPage, text, defaultColor, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Theme.Card
    frame.BorderSizePixel = 0
    frame.ZIndex = 23
    frame.Parent = parentPage

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 24
    label.Parent = frame

    local palette = {
        Color3.fromRGB(255, 60, 60),
        Color3.fromRGB(60, 255, 120),
        Color3.fromRGB(60, 170, 255),
        Color3.fromRGB(255, 220, 60),
        Color3.fromRGB(200, 80, 255),
        Color3.fromRGB(255, 255, 255),
    }

    local row = Instance.new("Frame")
    row.Size = UDim2.new(0, 200, 0, 30)
    row.Position = UDim2.new(1, -210, 0.5, -15)
    row.BackgroundTransparency = 1
    row.ZIndex = 24
    row.Parent = frame

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout.Padding = UDim.new(0, 8)
    rowLayout.Parent = row

    for _, col in ipairs(palette) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 26, 0, 26)
        b.BackgroundColor3 = col
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.ZIndex = 25
        b.Parent = row

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = b

        bindTap(b, function()
            if callback then callback(col) end
        end)
    end

    return frame
end

-- ==================== CREATE TABS ====================
local espPage = createTab("ESP", "👁")
local aimPage = createTab("Aim", "🎯")
local infoPage = createTab("Info", "ℹ")

-- ============================================================
-- ESP НАСТРОЙКИ
-- ============================================================
addSection(espPage, "ОСНОВНОЕ")

local espToggle = addToggle(espPage, "Включить ESP", State.espEnabled, function(v)
    State.espEnabled = v
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl.Enabled = v end
    end
    for _, bb in pairs(espBillboards) do
        if bb and bb.Parent then bb.Enabled = v end
    end
end)

addSection(espPage, "ВНЕШНИЙ ВИД")

addColorPicker(espPage, "Цвет подсветки", State.espColor, function(col)
    State.espColor = col
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl.FillColor = col end
    end
end)

addSlider(espPage, "Прозрачность заливки", 0, 1, State.espFillTransparency, true, function(v)
    State.espFillTransparency = v
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl.FillTransparency = v end
    end
end)

addSlider(espPage, "Прозрачность обводки", 0, 1, State.espOutlineTransparency, true, function(v)
    State.espOutlineTransparency = v
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl.OutlineTransparency = v end
    end
end)

addSection(espPage, "ФИЛЬТРЫ")

local espNameToggle = addToggle(espPage, "Показывать ники", State.espShowNames, function(v)
    State.espShowNames = v
    for _, bb in pairs(espBillboards) do
        if bb and bb.Parent then bb.Enabled = v and State.espEnabled end
    end
end)

addToggle(espPage, "Игнорировать союзников", State.espTeamCheck, function(v)
    State.espTeamCheck = v
end)

addSlider(espPage, "Макс. дистанция (studs)", 50, 2000, State.espMaxDistance, false, function(v)
    State.espMaxDistance = v
end)

-- ============================================================
-- AIM НАСТРОЙКИ
-- ============================================================
addSection(aimPage, "ОСНОВНОЕ")

addToggle(aimPage, "Включить Aim", State.aimEnabled, function(v)
    State.aimEnabled = v
    if fovCircle then fovCircle.Visible = v and State.aimVisibleFov end
end)

addSection(aimPage, "ПРИЦЕЛИВАНИЕ")

addDropdown(aimPage, "Целиться в", {"Head", "HumanoidRootPart", "Nearest"}, State.aimTargetPart, function(v)
    State.aimTargetPart = v
end)

addSlider(aimPage, "FOV (радиус)", 20, 600, State.aimFov, false, function(v)
    State.aimFov = v
    fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

addSlider(aimPage, "Резкость / Плавность", 0.02, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end)

addSlider(aimPage, "Макс. дистанция (studs)", 50, 2000, State.aimMaxDistance, false, function(v)
    State.aimMaxDistance = v
end)

addSection(aimPage, "ДОПОЛНИТЕЛЬНО")

addToggle(aimPage, "Проверка стен", State.aimWallCheck, function(v)
    State.aimWallCheck = v
end)

addToggle(aimPage, "Игнорировать союзников", State.aimTeamCheck, function(v)
    State.aimTeamCheck = v
end)

addToggle(aimPage, "Показывать FOV круг", State.aimVisibleFov, function(v)
    State.aimVisibleFov = v
    fovCircle.Visible = v and State.aimEnabled
end)

addColorPicker(aimPage, "Цвет FOV круга", State.aimFovColor, function(col)
    State.aimFovColor = col
    fovStroke.Color = col
end)

-- ============================================================
-- INFO
-- ============================================================
addSection(infoPage, "СТАТИСТИКА")

local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Size = UDim2.new(1, 0, 0, 40)
playerCountLabel.BackgroundColor3 = Theme.Card
playerCountLabel.BorderSizePixel = 0
playerCountLabel.Text = "Игроков на сервере: " .. #Players:GetPlayers()
playerCountLabel.TextColor3 = Theme.Text
playerCountLabel.Font = Enum.Font.Gotham
playerCountLabel.TextSize = 13
playerCountLabel.ZIndex = 23
playerCountLabel.Parent = infoPage

local pcCorner = Instance.new("UICorner")
pcCorner.CornerRadius = UDim.new(0, 8)
pcCorner.Parent = playerCountLabel

Players.PlayerAdded:Connect(function()
    playerCountLabel.Text = "Игроков на сервере: " .. #Players:GetPlayers()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    playerCountLabel.Text = "Игроков на сервере: " .. #Players:GetPlayers()
end)

local nickLabel = Instance.new("TextLabel")
nickLabel.Size = UDim2.new(1, 0, 0, 30)
nickLabel.BackgroundTransparency = 1
nickLabel.Text = "Твой ник: " .. LocalPlayer.Name
nickLabel.TextColor3 = Theme.SubText
nickLabel.Font = Enum.Font.GothamMedium
nickLabel.TextSize = 12
nickLabel.ZIndex = 23
nickLabel.Parent = infoPage

-- ============================================================
-- МЕНЮ ОТКРЫТИЕ / ЗАКРЫТИЕ
-- ============================================================
local isOpen = false
local animating = false

local function openMenu()
    if animating or isOpen then return end
    animating = true
    isOpen = true

    TweenService:Create(CircleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Rotation = 90
    }):Play()

    task.delay(0.2, function()
        CircleBtn.Visible = false
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 520, 0, 360)
        MainFrame.BackgroundTransparency = 0.5

        local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 560, 0, 400),
            BackgroundTransparency = 0
        })
        openTween:Play()
        openTween.Completed:Connect(function()
            animating = false
        end)
    end)
end

local function closeMenu()
    if animating or not isOpen then return end
    animating = true
    isOpen = false

    local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 510, 0, 360),
        BackgroundTransparency = 1
    })
    closeTween:Play()

    closeTween.Completed:Connect(function()
        MainFrame.Visible = false
        CircleBtn.Visible = true
        CircleBtn.Rotation = -90

        local circleTween = TweenService:Create(CircleBtn, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 54, 0, 54),
            Rotation = 0
        })
        circleTween:Play()
        circleTween.Completed:Connect(function()
            animating = false
        end)
    end)
end

bindTap(CircleBtn, openMenu)
bindTap(CloseBtn, closeMenu)

-- Hover
CircleBtn.MouseEnter:Connect(function()
    TweenService:Create(CircleStroke, TweenInfo.new(0.2), {Color = Theme.AccentHover, Thickness = 2.5}):Play()
    TweenService:Create(CircleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
end)

CircleBtn.MouseLeave:Connect(function()
    TweenService:Create(CircleStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Thickness = 2}):Play()
    TweenService:Create(CircleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play()
end)

-- ============================================================
-- ESP: РЕАЛЬНАЯ ЛОГИКА
-- ============================================================
local function isTeammate(player)
    if not State.espTeamCheck then return false end
    return player.Team == LocalPlayer.Team and player.Team ~= nil
end

local function createNameBillboard(char)
    local bb = Instance.new("BillboardGui")
    bb.Name = "NameESP"
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2.6, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    bb.Parent = char

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = char.Name
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.TextStrokeTransparency = 0.3
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Parent = bb
    return bb
end

local function refreshHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    char:WaitForChild("Humanoid", 5)

    -- Удаляем старые
    local oldHl = espHighlights[player]
    if oldHl and oldHl.Parent then oldHl:Destroy() end
    local staleHl = char:FindFirstChild("PlayerHighlight")
    if staleHl then staleHl:Destroy() end

    local oldBb = espBillboards[player]
    if oldBb and oldBb.Parent then oldBb:Destroy() end
    local staleBb = char:FindFirstChild("NameESP")
    if staleBb then staleBb:Destroy() end

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "PlayerHighlight"
    hl.FillColor = State.espColor
    hl.OutlineColor = State.espOutlineColor
    hl.FillTransparency = State.espFillTransparency
    hl.OutlineTransparency = State.espOutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Enabled = State.espEnabled
    hl.Parent = char
    espHighlights[player] = hl

    -- Billboard с ником
    local bb = createNameBillboard(char)
    bb.Adornee = char:FindFirstChild("Head") or char:WaitForChild("Head", 5)
    bb.Enabled = State.espShowNames and State.espEnabled
    espBillboards[player] = bb
end

local function registerPlayer(player)
    if player == LocalPlayer then return end

    if player.Character then
        task.spawn(refreshHighlight, player)
    end
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        refreshHighlight(player)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do registerPlayer(p) end
Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(function(p)
    espHighlights[p] = nil
    espBillboards[p] = nil
end)

-- ============================================================
-- AIM: РЕАЛЬНАЯ ЛОГИКА
-- ============================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(targetPart)
    if not State.aimWallCheck then return true end
    if not LocalPlayer.Character then return false end
    local camPos = Camera.CFrame.Position
    local dir = targetPart.Position - camPos
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    local hit = Workspace:Raycast(camPos, dir, rayParams)
    return hit == nil
end

local function isAimTeammate(player)
    if not State.aimTeamCheck then return false end
    return player.Team == LocalPlayer.Team and player.Team ~= nil
end

local function getAimPart(character)
    if State.aimTargetPart == "Head" then
        return character:FindFirstChild("Head")
    elseif State.aimTargetPart == "HumanoidRootPart" then
        return character:FindFirstChild("HumanoidRootPart")
    else
        -- Nearest: ближайшая к камере часть
        local parts = {
            character:FindFirstChild("Head"),
            character:FindFirstChild("HumanoidRootPart"),
            character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        }
        local best, bestDist = nil, math.huge
        local camPos = Camera.CFrame.Position
        for _, p in ipairs(parts) do
            if p then
                local d = (p.Position - camPos).Magnitude
                if d < bestDist then bestDist = d; best = p end
            end
        end
        return best
    end
end

RunService.RenderStepped:Connect(function()
    if not State.aimEnabled then return end
    if not LocalPlayer.Character then return end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local bestTarget = nil
    local minDistance = State.aimFov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not isAimTeammate(player) then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = getAimPart(player.Character)

            if hum and hum.Health > 0 and targetPart then
                -- Проверка дистанции
                local dist3D = (targetPart.Position - Camera.CFrame.Position).Magnitude
                if dist3D <= State.aimMaxDistance then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist2D <= minDistance and isVisible(targetPart) then
                            minDistance = dist2D
                            bestTarget = targetPart
                        end
                    end
                end
            end
        end
    end

    if bestTarget then
        local curCF = Camera.CFrame
        local targetCF = CFrame.new(curCF.Position, bestTarget.Position)
        Camera.CFrame = curCF:Lerp(targetCF, math.clamp(State.aimSharpness, 0.02, 1))
    end
end)

-- ============================================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================================
task.defer(function()
    if tabs["ESP"] then
        tabs["ESP"].Button.BackgroundColor3 = Theme.Card
        tabs["ESP"].Button.BackgroundTransparency = 0
        tabs["ESP"].Button.TextColor3 = Theme.Text
        tabs["ESP"].Page.Visible = true
        activeTab = tabs["ESP"]
    end
end)

print("[DarkHub] ESP + AIM загружено успешно")

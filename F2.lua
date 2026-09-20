-- [[ DARK HUB // MOBILE EDITION v2 ]]
-- ESP + AIM + AUTO-SHOOT + SILENT + SPIN

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Cleanup
local existing = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DarkMenuHub")
if existing then existing:Destroy() end
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        local h = p.Character:FindFirstChild("PlayerHighlight")
        if h then h:Destroy() end
    end
end
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj.Name == "PlayerHighlight" or obj.Name == "NameESP" then obj:Destroy() end
end

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DarkMenuHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

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

local State = {
    -- ESP
    espEnabled = false,
    espPlayerColor = Color3.fromRGB(255, 60, 60),
    espBotColor = Color3.fromRGB(255, 210, 60),
    espFillTransparency = 0.5,
    espOutlineTransparency = 0.1,
    espShowNames = true,
    espTeamCheck = false,
    espMaxDistance = 500,

    -- AIM
    aimEnabled = false,
    aimFov = 120,
    aimSharpness = 0.25,
    aimTargetPart = "Head",
    aimWallCheck = true,
    aimTeamCheck = false,
    aimMaxDistance = 300,
    aimVisibleFov = true,
    aimFovColor = Color3.fromRGB(110, 86, 248),

    -- AUTO-SHOOT
    autoShoot = false,
    autoButtonPos = nil,       -- Vector2
    auto360 = true,
    autoView = "3rd",          -- "1st" / "3rd"
    autoSilent = false,
    autoDelay = 0.05,

    -- SPIN
    spinEnabled = false,
    spinSpeed = 180,
}

local espHighlights = {}   -- [model] = Highlight
local espBillboards = {}   -- [model] = BillboardGui
local botModels = {}       -- [model] = true

-- ==================== HELPERS ====================
local function bindTap(gui, cb)
    local t = 0
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            t = tick()
        end
    end)
    gui.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if tick() - t < 0.5 then cb() end
        end
    end)
end

local function enableDrag(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
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

local fovC = Instance.new("UICorner")
fovC.CornerRadius = UDim.new(1, 0)
fovC.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = State.aimFovColor
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.4
fovStroke.Parent = fovCircle

-- ==================== AUTO BUTTON MARKER ====================
local autoMarker = Instance.new("Frame")
autoMarker.Name = "AutoButtonMarker"
autoMarker.AnchorPoint = Vector2.new(0.5, 0.5)
autoMarker.Size = UDim2.new(0, 60, 0, 60)
autoMarker.BackgroundTransparency = 1
autoMarker.Visible = false
autoMarker.ZIndex = 5
autoMarker.Parent = ScreenGui

local amC = Instance.new("UICorner")
amC.CornerRadius = UDim.new(1, 0)
amC.Parent = autoMarker

local amS = Instance.new("UIStroke")
amS.Color = Color3.fromRGB(80, 255, 120)
amS.Thickness = 2
amS.Transparency = 0.2
amS.Parent = autoMarker

-- ==================== HINT LABEL ====================
local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "HintLabel"
hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
hintLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
hintLabel.Size = UDim2.new(0, 320, 0, 50)
hintLabel.BackgroundColor3 = Theme.Background
hintLabel.BackgroundTransparency = 0.1
hintLabel.Text = "НАЖМИ НА ЭКРАН, ГДЕ КНОПКА ВЫСТРЕЛА"
hintLabel.TextColor3 = Theme.Text
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 13
hintLabel.Visible = false
hintLabel.ZIndex = 100
hintLabel.Parent = ScreenGui

local hlC = Instance.new("UICorner")
hlC.CornerRadius = UDim.new(0, 10)
hlC.Parent = hintLabel

-- ==================== TOGGLE BUTTON ====================
local CircleBtn = Instance.new("TextButton")
CircleBtn.Name = "OpenCircleBtn"
CircleBtn.Size = UDim2.new(0, 46, 0, 46)
CircleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
CircleBtn.BackgroundColor3 = Theme.Background
CircleBtn.BorderSizePixel = 0
CircleBtn.Text = "⚡"
CircleBtn.TextColor3 = Theme.Accent
CircleBtn.TextSize = 20
CircleBtn.Font = Enum.Font.GothamBold
CircleBtn.AutoButtonColor = false
CircleBtn.ZIndex = 10
CircleBtn.Parent = ScreenGui

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(1, 0)
cc.Parent = CircleBtn

local cs = Instance.new("UIStroke")
cs.Color = Theme.Accent
cs.Thickness = 2
cs.Parent = CircleBtn

enableDrag(CircleBtn)

-- ==================== MAIN WINDOW ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainWindow"
MainFrame.Size = UDim2.new(0, 430, 0, 300)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.ZIndex = 20
MainFrame.Parent = ScreenGui

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 14)
mc.Parent = MainFrame

local ms = Instance.new("UIStroke")
ms.Color = Theme.Border
ms.Thickness = 1.2
ms.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 36)
Topbar.BackgroundTransparency = 1
Topbar.ZIndex = 21
Topbar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "DARK HUB // <font color='rgb(110,86,248)'>MOBILE</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 22
TitleLabel.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.TextSize = 12
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 22
CloseBtn.Parent = Topbar

local cc2 = Instance.new("UICorner")
cc2.CornerRadius = UDim.new(0, 7)
cc2.Parent = CloseBtn

enableDrag(MainFrame, Topbar)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 96, 1, -36)
Sidebar.Position = UDim2.new(0, 0, 0, 36)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 21
Sidebar.Parent = MainFrame

local SideList = Instance.new("UIListLayout")
SideList.Padding = UDim.new(0, 4)
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 6)
SidePad.Parent = Sidebar

-- Content
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -104, 1, -46)
ContentContainer.Position = UDim2.new(0, 100, 0, 42)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 21
ContentContainer.Parent = MainFrame

-- ==================== TAB SYSTEM ====================
local tabs = {}
local activeTab = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 86, 0, 30)
    btn.BackgroundTransparency = 1
    btn.Text = " " .. icon .. " " .. name
    btn.TextColor3 = Theme.SubText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 22
    btn.Parent = Sidebar

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 7)
    bc.Parent = btn

    local page = Instance.new("ScrollingFrame")
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

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = page

    local data = { Button = btn, Page = page }
    tabs[name] = data

    bindTap(btn, function()
        if activeTab == data then return end
        for _, t in pairs(tabs) do
            TweenService:Create(t.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = Theme.SubText}):Play()
            if t.Page.Visible then t.Page.Visible = false end
        end
        activeTab = data
        data.Page.Visible = true
        TweenService:Create(btn, TweenInfo.new(0.25), {
            BackgroundColor3 = Theme.Card, BackgroundTransparency = 0, TextColor3 = Theme.Text
        }):Play()
    end)
    return page
end

-- ==================== UI BUILDERS ====================
local function addSection(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = "— " .. text .. " —"
    l.TextColor3 = Theme.SubText
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.ZIndex = 23
    l.Parent = parent
end

local function addToggle(parent, text, default, cb)
    local state = default or false
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -60, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 12
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 38, 0, 20)
    sw.Position = UDim2.new(1, -48, 0.5, -10)
    sw.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.ZIndex = 24
    sw.Parent = f
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = sw

    local kn = Instance.new("Frame")
    kn.Size = UDim2.new(0, 14, 0, 14)
    kn.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    kn.BorderSizePixel = 0
    kn.ZIndex = 25
    kn.Parent = sw
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = kn

    local function update()
        TweenService:Create(sw, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff}):Play()
        TweenService:Create(kn, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        if cb then task.spawn(cb, state) end
    end

    bindTap(sw, function()
        state = not state
        update()
    end)

    return {
        frame = f,
        get = function() return state end,
        set = function(v) state = v; update() end
    }
end

-- SLIDER (исправлен touch через hitbox)
local function addSlider(parent, text, minV, maxV, defV, isFloat, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 52)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -70, 0, 18)
    lb.Position = UDim2.new(0, 10, 0, 4)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 12
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 55, 0, 18)
    vl.Position = UDim2.new(1, -63, 0, 4)
    vl.BackgroundTransparency = 1
    vl.Text = isFloat and string.format("%.2f", defV) or tostring(defV)
    vl.TextColor3 = Theme.Accent
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 11
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.ZIndex = 24
    vl.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 1, -14)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bar.BorderSizePixel = 0
    bar.ZIndex = 24
    bar.Parent = f
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 25
    fill.Parent = bar
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 26
    knob.Parent = bar
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    -- Невидимый hitbox на весь frame — фикс тапа на телефоне
    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.Active = true
    hitbox.ZIndex = 30
    hitbox.Parent = f

    local cur = defV
    local dragging = false

    local function updateFromX(absX)
        local bAbs = bar.AbsolutePosition
        local bW = bar.AbsoluteSize.X
        if bW <= 0 then return end
        local rel = math.clamp((absX - bAbs) / bW, 0, 1)
        local v = minV + (maxV - minV) * rel
        if not isFloat then v = math.floor(v + 0.5) end
        cur = v
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        vl.Text = isFloat and string.format("%.2f", v) or tostring(v)
        if cb then cb(v) end
    end

    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    hitbox.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(input.Position.X)
        end
    end)

    return {
        get = function() return cur end,
        set = function(v)
            cur = v
            local rel = (v - minV) / (maxV - minV)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            vl.Text = isFloat and string.format("%.2f", v) or tostring(v)
        end
    }
end

-- DROPDOWN
local function addDropdown(parent, text, options, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.5, 0, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 12
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local cur = def
    local vb = Instance.new("TextButton")
    vb.Size = UDim2.new(0, 80, 0, 22)
    vb.Position = UDim2.new(1, -88, 0.5, -11)
    vb.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    vb.BorderSizePixel = 0
    vb.Text = cur .. "  ▾"
    vb.TextColor3 = Theme.Accent
    vb.Font = Enum.Font.GothamMedium
    vb.TextSize = 10
    vb.AutoButtonColor = false
    vb.ZIndex = 24
    vb.Parent = f
    local vbc = Instance.new("UICorner"); vbc.CornerRadius = UDim.new(0, 6); vbc.Parent = vb

    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(1, -16, 0, 0)
    lf.Position = UDim2.new(0, 8, 0, 38)
    lf.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    lf.BorderSizePixel = 0
    lf.ClipsDescendants = true
    lf.ZIndex = 30
    lf.Parent = f
    local lfc = Instance.new("UICorner"); lfc.CornerRadius = UDim.new(0, 6); lfc.Parent = lf

    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 2)
    ll.Parent = lf

    local lp = Instance.new("UIPadding")
    lp.PaddingTop = UDim.new(0, 4)
    lp.PaddingBottom = UDim.new(0, 4)
    lp.Parent = lf

    local opened = false

    local function rebuild()
        for _, c2 in ipairs(lf:GetChildren()) do
            if c2:IsA("TextButton") then c2:Destroy() end
        end
        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, -8, 0, 22)
            ob.BackgroundColor3 = (opt == cur) and Theme.Accent or Color3.fromRGB(30, 30, 38)
            ob.BorderSizePixel = 0
            ob.Text = opt
            ob.TextColor3 = (opt == cur) and Color3.fromRGB(255, 255, 255) or Theme.Text
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 10
            ob.AutoButtonColor = false
            ob.ZIndex = 31
            ob.Parent = lf
            local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 4); oc.Parent = ob
            bindTap(ob, function()
                cur = opt
                vb.Text = opt .. "  ▾"
                opened = false
                TweenService:Create(f, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 36)}):Play()
                if cb then cb(opt) end
            end)
        end
    end

    bindTap(vb, function()
        opened = not opened
        if opened then
            rebuild()
            local h = 36 + 8 + #options * 24
            TweenService:Create(f, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, h)}):Play()
        else
            TweenService:Create(f, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 36)}):Play()
        end
    end)

    return { get = function() return cur end, set = function(v) cur = v; vb.Text = v .. "  ▾" end }
end

-- COLOR PICKER
local function addColorPicker(parent, text, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.5, 0, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 12
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local row = Instance.new("Frame")
    row.Size = UDim2.new(0, 180, 0, 26)
    row.Position = UDim2.new(1, -190, 0.5, -13)
    row.BackgroundTransparency = 1
    row.ZIndex = 24
    row.Parent = f

    local rl = Instance.new("UIListLayout")
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.VerticalAlignment = Enum.VerticalAlignment.Center
    rl.Padding = UDim.new(0, 6)
    rl.Parent = row

    local palette = {
        Color3.fromRGB(255, 60, 60),
        Color3.fromRGB(60, 255, 120),
        Color3.fromRGB(60, 170, 255),
        Color3.fromRGB(255, 220, 60),
        Color3.fromRGB(200, 80, 255),
        Color3.fromRGB(255, 255, 255),
    }

    for _, col in ipairs(palette) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 22, 0, 22)
        b.BackgroundColor3 = col
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.ZIndex = 25
        b.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = b
        bindTap(b, function() if cb then cb(col) end end)
    end
end

-- Кнопка-действие
local function addActionButton(parent, text, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = color or Theme.Accent
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.AutoButtonColor = false
    b.ZIndex = 24
    b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
    bindTap(b, cb)
    return b
end

-- Контейнер (для скрытия/показа целой группы)
local function createContainer(parent, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 0)
    c.BackgroundTransparency = 1
    c.LayoutOrder = order or 1
    c.ZIndex = 23
    c.Parent = parent
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = c
    local a = Instance.new("AutomaticSize")
    a.Parent = c
    return c
end

-- ==================== BUILD TABS ====================
local espPage = createTab("ESP", "👁")
local aimPage = createTab("Aim", "🎯")
local otherPage = createTab("Other", "✨")
local infoPage = createTab("Info", "ℹ")

-- ==================== ESP ====================
addSection(espPage, "ОСНОВНОЕ")

addToggle(espPage, "Включить ESP", State.espEnabled, function(v)
    State.espEnabled = v
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl.Enabled = v end
    end
    for _, bb in pairs(espBillboards) do
        if bb and bb.Parent then bb.Enabled = v and State.espShowNames end
    end
end)

addSection(espPage, "ЦВЕТА")

addColorPicker(espPage, "Цвет игроков", State.espPlayerColor, function(col)
    State.espPlayerColor = col
    for model, hl in pairs(espHighlights) do
        if hl and hl.Parent and Players:GetPlayerFromCharacter(model) then
            hl.FillColor = col
        end
    end
end)

addColorPicker(espPage, "Цвет ботов", State.espBotColor, function(col)
    State.espBotColor = col
    for model, hl in pairs(espHighlights) do
        if hl and hl.Parent and not Players:GetPlayerFromCharacter(model) then
            hl.FillColor = col
        end
    end
end)

addSection(espPage, "ВНЕШНИЙ ВИД")

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

addToggle(espPage, "Показывать ники / BOT", State.espShowNames, function(v)
    State.espShowNames = v
    for _, bb in pairs(espBillboards) do
        if bb and bb.Parent then bb.Enabled = v and State.espEnabled end
    end
end)

addToggle(espPage, "Игнорировать союзников", State.espTeamCheck, function(v)
    State.espTeamCheck = v
end)

addSlider(espPage, "Макс. дистанция", 50, 2000, State.espMaxDistance, false, function(v)
    State.espMaxDistance = v
end)

-- ==================== AIM ====================
addSection(aimPage, "РЕЖИМ")

local autoShootToggle = addToggle(aimPage, "Авто-выстрел", State.autoShoot, function(v)
    State.autoShoot = v
    if v then
        normalAimContainer.Visible = false
        autoAimContainer.Visible = true
        if fovCircle then fovCircle.Visible = false end
    else
        normalAimContainer.Visible = true
        autoAimContainer.Visible = false
        autoMarker.Visible = false
        if fovCircle then fovCircle.Visible = State.aimEnabled and State.aimVisibleFov end
    end
end)

-- Обычные настройки Aim
local normalAimContainer = createContainer(aimPage, 2)

addSection(normalAimContainer, "ОСНОВНОЕ")

addToggle(normalAimContainer, "Включить Aim", State.aimEnabled, function(v)
    State.aimEnabled = v
    if fovCircle then fovCircle.Visible = v and State.aimVisibleFov end
end)

addSection(normalAimContainer, "ПРИЦЕЛИВАНИЕ")

addDropdown(normalAimContainer, "Целиться в", {"Head", "HumanoidRootPart", "Nearest"}, State.aimTargetPart, function(v)
    State.aimTargetPart = v
end)

addSlider(normalAimContainer, "FOV", 20, 600, State.aimFov, false, function(v)
    State.aimFov = v
    fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

addSlider(normalAimContainer, "Плавность", 0.02, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end)

addSlider(normalAimContainer, "Макс. дистанция", 50, 2000, State.aimMaxDistance, false, function(v)
    State.aimMaxDistance = v
end)

addSection(normalAimContainer, "ДОПОЛНИТЕЛЬНО")

addToggle(normalAimContainer, "Проверка стен", State.aimWallCheck, function(v) State.aimWallCheck = v end)
addToggle(normalAimContainer, "Игнор союзников", State.aimTeamCheck, function(v) State.aimTeamCheck = v end)
addToggle(normalAimContainer, "Показывать FOV", State.aimVisibleFov, function(v)
    State.aimVisibleFov = v
    fovCircle.Visible = v and State.aimEnabled
end)

addColorPicker(normalAimContainer, "Цвет FOV", State.aimFovColor, function(col)
    State.aimFovColor = col
    fovStroke.Color = col
end)

-- Auto-Shoot настройки
local autoAimContainer = createContainer(aimPage, 3)
autoAimContainer.Visible = false

addSection(autoAimContainer, "AUTO-SHOOT")

local pickerCallback = nil
local function startPicking(callback)
    hintLabel.Visible = true
    MainFrame.Visible = false
    CircleBtn.Visible = false
    autoMarker.Visible = false
    pickerCallback = callback
end

local pickedBtnLabel = Instance.new("TextLabel")  -- заглушка для отображения позиции
pickedBtnLabel.Visible = false

addActionButton(autoAimContainer, "🎯 ВЫБРАТЬ КНОПКУ", Color3.fromRGB(50, 130, 255), function()
    startPicking(function(pos)
        State.autoButtonPos = pos
        autoMarker.Position = UDim2.new(0, pos.X, 0, pos.Y)
        autoMarker.Visible = true
    end)
end)

addActionButton(autoAimContainer, "❌ СБРОСИТЬ КНОПКУ", Color3.fromRGB(60, 60, 70), function()
    State.autoButtonPos = nil
    autoMarker.Visible = false
end)

addSection(autoAimContainer, "ПАРАМЕТРЫ")

addToggle(autoAimContainer, "Обзор 360°", State.auto360, function(v) State.auto360 = v end)

addDropdown(autoAimContainer, "Вид", {"1st", "3rd"}, State.autoView, function(v)
    State.autoView = v
    if v == "1st" then
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
    end
end)

addToggle(autoAimContainer, "Silent (визуально не поворачиваюсь)", State.autoSilent, function(v)
    State.autoSilent = v
end)

addSlider(autoAimContainer, "Задержка перед выстрелом", 0, 0.5, State.autoDelay, true, function(v)
    State.autoDelay = v
end)

addSlider(autoAimContainer, "Резкость захвата", 0.05, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end)

-- ==================== OTHER (SPIN) ====================
addSection(otherPage, "SPIN")

addToggle(otherPage, "Включить Spin", State.spinEnabled, function(v)
    State.spinEnabled = v
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = not v end
    end
end)

addSlider(otherPage, "Скорость (°/сек)", 30, 1440, State.spinSpeed, false, function(v)
    State.spinSpeed = v
end)

addToggle(otherPage, "Голова вниз", true, function(v)
    State.spinHeadDown = v
end)

-- ==================== INFO ====================
addSection(infoPage, "СТАТИСТИКА")

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, 0, 0, 34)
countLabel.BackgroundColor3 = Theme.Card
countLabel.BorderSizePixel = 0
countLabel.Text = "Игроков: " .. #Players:GetPlayers()
countLabel.TextColor3 = Theme.Text
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 12
countLabel.ZIndex = 23
countLabel.Parent = infoPage
local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0, 8); clc.Parent = countLabel

Players.PlayerAdded:Connect(function()
    countLabel.Text = "Игроков: " .. #Players:GetPlayers()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    countLabel.Text = "Игроков: " .. #Players:GetPlayers()
end)

local function updateBotCount()
    local n = 0
    for _ in pairs(botModels) do n = n + 1 end
    return n
end

local botCountLabel = Instance.new("TextLabel")
botCountLabel.Size = UDim2.new(1, 0, 0, 34)
botCountLabel.BackgroundColor3 = Theme.Card
botCountLabel.BorderSizePixel = 0
botCountLabel.Text = "Ботов: " .. updateBotCount()
botCountLabel.TextColor3 = Theme.Text
botCountLabel.Font = Enum.Font.Gotham
botCountLabel.TextSize = 12
botCountLabel.ZIndex = 23
botCountLabel.Parent = infoPage
local bcc = Instance.new("UICorner"); bcc.CornerRadius = UDim.new(0, 8); bcc.Parent = botCountLabel

local nickLabel = Instance.new("TextLabel")
nickLabel.Size = UDim2.new(1, 0, 0, 24)
nickLabel.BackgroundTransparency = 1
nickLabel.Text = "Ник: " .. LocalPlayer.Name
nickLabel.TextColor3 = Theme.SubText
nickLabel.Font = Enum.Font.GothamMedium
nickLabel.TextSize = 11
nickLabel.ZIndex = 23
nickLabel.Parent = infoPage

-- ==================== MENU OPEN/CLOSE ====================
local isOpen = false
local animating = false

local function openMenu()
    if animating or isOpen then return end
    animating = true
    isOpen = true
    TweenService:Create(CircleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0), Rotation = 90
    }):Play()
    task.delay(0.2, function()
        CircleBtn.Visible = false
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 400, 0, 270)
        MainFrame.BackgroundTransparency = 0.5
        local t = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 430, 0, 300),
            BackgroundTransparency = 0
        })
        t:Play()
        t.Completed:Connect(function() animating = false end)
    end)
end

local function closeMenu()
    if animating or not isOpen then return end
    animating = true
    isOpen = false
    local t = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 380, 0, 260), BackgroundTransparency = 1
    })
    t:Play()
    t.Completed:Connect(function()
        MainFrame.Visible = false
        CircleBtn.Visible = true
        CircleBtn.Rotation = -90
        local t2 = TweenService:Create(CircleBtn, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 46, 0, 46), Rotation = 0
        })
        t2:Play()
        t2.Completed:Connect(function() animating = false end)
    end)
end

bindTap(CircleBtn, openMenu)
bindTap(CloseBtn, closeMenu)

-- ==================== BUTTON PICKER LISTENER ====================
UserInputService.InputBegan:Connect(function(input, processed)
    if not pickerCallback then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        pickerCallback(pos)
        pickerCallback = nil
        hintLabel.Visible = false
        MainFrame.Visible = true
        CircleBtn.Visible = false
        -- Показать окно обратно
        if isOpen then
            MainFrame.Visible = true
        end
    end
end)

-- ==================== ESP LOGIC (игроки + боты) ====================
local function isTeammate(p)
    if not State.espTeamCheck then return false end
    return p.Team == LocalPlayer.Team and p.Team ~= nil
end

local function createBillboard(model, text)
    local bb = Instance.new("BillboardGui")
    bb.Name = "NameESP"
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2.6, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    bb.Parent = model

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.TextStrokeTransparency = 0.3
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Parent = bb
    return bb
end

local function refreshHighlight(model, isPlayer)
    if not model or not model.Parent then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then
        model:WaitForChild("Humanoid", 3)
        hum = model:FindFirstChildOfClass("Humanoid")
        if not hum then return end
    end

    -- Удалить старые
    local oldHl = espHighlights[model]
    if oldHl and oldHl.Parent then oldHl:Destroy() end
    local stale = model:FindFirstChild("PlayerHighlight")
    if stale then stale:Destroy() end
    local oldBb = espBillboards[model]
    if oldBb and oldBb.Parent then oldBb:Destroy() end
    local staleBb = model:FindFirstChild("NameESP")
    if staleBb then staleBb:Destroy() end

    -- Создаём Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "PlayerHighlight"
    hl.FillColor = isPlayer and State.espPlayerColor or State.espBotColor
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = State.espFillTransparency
    hl.OutlineTransparency = State.espOutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Enabled = State.espEnabled
    hl.Parent = model
    espHighlights[model] = hl

    -- Billboard
    local text
    if isPlayer then
        local plr = Players:GetPlayerFromCharacter(model)
        text = plr and plr.DisplayName or model.Name
    else
        text = "BOT"
    end
    local bb = createBillboard(model, text)
    bb.Adornee = model:FindFirstChild("Head") or model:WaitForChild("Head", 3)
    bb.Enabled = State.espEnabled and State.espShowNames
    espBillboards[model] = bb
end

-- Регистрация игроков
local function registerPlayer(player)
    if player == LocalPlayer then return end

    if player.Character then
        task.spawn(function() refreshHighlight(player.Character, true) end)
    end

    player.CharacterAdded:Connect(function(char)
        -- Ждём пока Humanoid появится
        char:WaitForChild("Humanoid", 5)
        task.wait(0.1)
        refreshHighlight(char, true)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do registerPlayer(p) end
Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then
        local hl = espHighlights[p.Character]
        if hl and hl.Parent then hl:Destroy() end
        espHighlights[p.Character] = nil
        local bb = espBillboards[p.Character]
        if bb and bb.Parent then bb:Destroy() end
        espBillboards[p.Character] = nil
    end
end)

-- Регистрация ботов (модели с Humanoid, не игроки)
local function tryRegisterBot(model)
    if not model:IsA("Model") then return end
    if Players:GetPlayerFromCharacter(model) then return end
    if espHighlights[model] then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    botModels[model] = true
    task.spawn(function()
        task.wait(0.2)
        refreshHighlight(model, false)
    end)
    model.AncestryChanged:Connect(function()
        if not model:IsDescendantOf(Workspace) then
            botModels[model] = nil
            espHighlights[model] = nil
            espBillboards[model] = nil
        end
    end)
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Model") then tryRegisterBot(obj) end
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then
        task.defer(tryRegisterBot, obj)
    elseif obj:IsA("Humanoid") and obj.Parent then
        task.defer(tryRegisterBot, obj.Parent)
    end
end)

-- ==================== AIM LOGIC ====================
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
        local parts = {
            character:FindFirstChild("Head"),
            character:FindFirstChild("HumanoidRootPart"),
        }
        local best, bd = nil, math.huge
        local camPos = Camera.CFrame.Position
        for _, p in ipairs(parts) do
            if p then
                local d = (p.Position - camPos).Magnitude
                if d < bd then bd = d; best = p end
            end
        end
        return best
    end
end

-- Найти лучшую цель
local function findBestTarget(useFullCircle)
    if not LocalPlayer.Character then return nil end
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local best, bestDist = nil, useFullCircle and math.huge or State.aimFov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not isAimTeammate(player) then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local part = getAimPart(player.Character)
            if hum and hum.Health > 0 and part then
                local d3 = (part.Position - Camera.CFrame.Position).Magnitude
                if d3 <= State.aimMaxDistance then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if useFullCircle or d2 <= bestDist then
                            if isVisible(part) then
                                if useFullCircle then
                                    if d2 < bestDist then bestDist = d2; best = part end
                                else
                                    if d2 <= bestDist then bestDist = d2; best = part end
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

-- Нажатие кнопки выстрела
local function pressAutoButton()
    if not State.autoButtonPos then return end
    local pos = State.autoButtonPos
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    -- Вспышка маркера
    if autoMarker.Visible then
        local origColor = amS.Color
        amS.Color = Color3.fromRGB(120, 255, 120)
        task.delay(0.15, function()
            if amS and amS.Parent then amS.Color = origColor end
        end)
    end
end

local autoShootCooldown = 0

RunService.RenderStepped:Connect(function(dt)
    -- Auto-shoot
    if State.autoShoot then
        autoShootCooldown = autoShootCooldown - dt
        local target = findBestTarget(State.auto360)

        if target then
            local curCF = Camera.CFrame
            local savedCF = curCF

            if State.autoSilent then
                -- "Silent": мгновенный снап, выстрел, возврат
                local targetCF = CFrame.new(curCF.Position, target.Position)
                Camera.CFrame = targetCF
                task.wait(0.02)
                if autoShootCooldown <= 0 then
                    pressAutoButton()
                    autoShootCooldown = State.autoDelay + 0.15
                end
                task.wait(0.01)
                Camera.CFrame = savedCF
            else
                -- Обычный aim: плавно наводимся
                local targetCF = CFrame.new(curCF.Position, target.Position)
                Camera.CFrame = curCF:Lerp(targetCF, math.clamp(State.aimSharpness, 0.05, 1))

                -- Проверка: прицел на голове?
                local head = target.Parent and target.Parent:FindFirstChild("Head")
                if head then
                    local sp = Camera:WorldToViewportPoint(head.Position)
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < 5 and autoShootCooldown <= 0 then
                        pressAutoButton()
                        autoShootCooldown = State.autoDelay + 0.15
                    end
                end
            end
        end
        return
    end

    -- Обычный Aim
    if not State.aimEnabled then return end
    local target = findBestTarget(false)
    if target then
        local curCF = Camera.CFrame
        local targetCF = CFrame.new(curCF.Position, target.Position)
        Camera.CFrame = curCF:Lerp(targetCF, math.clamp(State.aimSharpness, 0.02, 1))
    end
end)

-- ==================== SPIN LOGIC ====================
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.spinEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.AutoRotate = false
    spinAngle = spinAngle + math.rad(State.spinSpeed) * dt
    if spinAngle > math.pi * 2 then spinAngle = spinAngle - math.pi * 2 end

    local pos = hrp.Position
    local newCF = CFrame.new(pos) * CFrame.Angles(0, spinAngle, 0)
    if State.spinHeadDown then
        newCF = newCF * CFrame.Angles(math.rad(35), 0, 0)
    end
    hrp.CFrame = newCF
end)

-- Восстановить AutoRotate при выключении
task.spawn(function()
    while true do
        task.wait(0.5)
        if not State.spinEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and not hum.AutoRotate then hum.AutoRotate = true end
            end
        end
    end
end)

-- ==================== INIT ====================
task.defer(function()
    if tabs["ESP"] then
        tabs["ESP"].Button.BackgroundColor3 = Theme.Card
        tabs["ESP"].Button.BackgroundTransparency = 0
        tabs["ESP"].Button.TextColor3 = Theme.Text
        tabs["ESP"].Page.Visible = true
        activeTab = tabs["ESP"]
    end
end)

print("[DarkHub Mobile v2] Загружено")

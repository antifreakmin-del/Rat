-- [[ DARK HUB // MOBILE v3 - COMPACT + FIXED ]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("[DarkHub] start")

-- Cleanup
pcall(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    if pg then
        local ex = pg:FindFirstChild("DarkMenuHub")
        if ex then ex:Destroy() end
    end
end)

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DarkMenuHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) or LocalPlayer.PlayerGui

local Theme = {
    Background = Color3.fromRGB(18, 18, 22),
    Sidebar = Color3.fromRGB(14, 14, 17),
    Card = Color3.fromRGB(24, 24, 30),
    Accent = Color3.fromRGB(110, 86, 248),
    Text = Color3.fromRGB(245, 245, 245),
    SubText = Color3.fromRGB(140, 140, 150),
    Border = Color3.fromRGB(36, 36, 45),
    ToggleOff = Color3.fromRGB(35, 35, 42),
    ToggleOn = Color3.fromRGB(110, 86, 248)
}

local State = {
    espEnabled = false,
    espPlayerColor = Color3.fromRGB(255, 60, 60),
    espBotColor = Color3.fromRGB(255, 210, 60),
    espFillTransparency = 0.5,
    espOutlineTransparency = 0.1,
    espShowNames = true,
    espTeamCheck = false,
    espMaxDistance = 500,

    aimEnabled = false,
    aimFov = 120,
    aimSharpness = 0.25,
    aimTargetPart = "Head",
    aimWallCheck = true,
    aimTeamCheck = false,
    aimMaxDistance = 300,
    aimVisibleFov = true,
    aimFovColor = Color3.fromRGB(110, 86, 248),

    autoShoot = false,
    autoButtonPos = nil,
    auto360 = true,
    autoView = "3rd",
    autoSilent = false,
    autoDelay = 0.05,

    spinEnabled = false,
    spinSpeed = 180,
    spinHeadDown = true,
}

local espHighlights = {}
local espBillboards = {}
local botModels = {}

-- ==================== HELPERS ====================
-- Единый обработчик: drag + tap в одном месте
local function bindDragAndTap(frame, handle, onTap, tapThreshold)
    handle = handle or frame
    tapThreshold = tapThreshold or 8

    local dragging = false
    local dragStart = nil
    local startPos = nil
    local moved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > tapThreshold then
                moved = true
            end
            if moved then
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if not moved and onTap then
                    task.spawn(function()
                        local ok, err = pcall(onTap)
                        if not ok then warn("[Tap]", err) end
                    end)
                end
            end
        end
    end)
end

-- Простой тап для кнопок внутри GUI
local function bindTap(gui, cb)
    local pressTime = 0
    local pressed = false
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressTime = tick()
            pressed = true
        end
    end)
    gui.InputEnded:Connect(function(input)
        if not pressed then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressed = false
            if tick() - pressTime < 0.5 then
                task.spawn(function()
                    local ok, err = pcall(cb)
                    if not ok then warn("[Tap]", err) end
                end)
            end
        end
    end)
end

-- ==================== FOV CIRCLE ====================
local fovCircle = Instance.new("Frame")
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
autoMarker.AnchorPoint = Vector2.new(0.5, 0.5)
autoMarker.Size = UDim2.new(0, 56, 0, 56)
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
hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
hintLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
hintLabel.Size = UDim2.new(0, 300, 0, 44)
hintLabel.BackgroundColor3 = Theme.Background
hintLabel.BackgroundTransparency = 0.1
hintLabel.Text = "НАЖМИ, ГДЕ КНОПКА ВЫСТРЕЛА"
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
CircleBtn.Size = UDim2.new(0, 42, 0, 42)
CircleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
CircleBtn.BackgroundColor3 = Theme.Background
CircleBtn.BorderSizePixel = 0
CircleBtn.Text = "⚡"
CircleBtn.TextColor3 = Theme.Accent
CircleBtn.TextSize = 18
CircleBtn.Font = Enum.Font.GothamBold
CircleBtn.AutoButtonColor = false
CircleBtn.Active = true
CircleBtn.ZIndex = 10
CircleBtn.Parent = ScreenGui

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(1, 0)
cc.Parent = CircleBtn

local cs = Instance.new("UIStroke")
cs.Color = Theme.Accent
cs.Thickness = 2
cs.Parent = CircleBtn

-- ==================== MAIN WINDOW ====================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 260)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.ZIndex = 20
MainFrame.Parent = ScreenGui

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 12)
mc.Parent = MainFrame

local ms = Instance.new("UIStroke")
ms.Color = Theme.Border
ms.Thickness = 1.2
ms.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 32)
Topbar.BackgroundTransparency = 1
Topbar.ZIndex = 21
Topbar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "DARK HUB // <font color='rgb(110,86,248)'>MOBILE</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 22
TitleLabel.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.TextSize = 11
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 22
CloseBtn.Parent = Topbar

local cc2 = Instance.new("UICorner")
cc2.CornerRadius = UDim.new(0, 6)
cc2.Parent = CloseBtn

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 78, 1, -32)
Sidebar.Position = UDim2.new(0, 0, 0, 32)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 21
Sidebar.Parent = MainFrame

local SideList = Instance.new("UIListLayout")
SideList.Padding = UDim.new(0, 3)
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 4)
SidePad.Parent = Sidebar

-- Content
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -86, 1, -40)
ContentContainer.Position = UDim2.new(0, 82, 0, 36)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 21
ContentContainer.Parent = MainFrame

-- ==================== TAB SYSTEM ====================
local tabs = {}
local activeTab = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 68, 0, 26)
    btn.BackgroundTransparency = 1
    btn.Text = " " .. icon .. " " .. name
    btn.TextColor3 = Theme.SubText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 22
    btn.Parent = Sidebar

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Visible = false
    page.ZIndex = 22
    page.Parent = ContentContainer

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 5)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 5)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = page

    local data = { Button = btn, Page = page }
    tabs[name] = data

    bindTap(btn, function()
        if activeTab == data then return end
        for _, t in pairs(tabs) do
            TweenService:Create(t.Button, TweenInfo.new(0.2), {
                BackgroundTransparency = 1, TextColor3 = Theme.SubText
            }):Play()
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

-- ==================== BUILDERS ====================
local function addSection(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 14)
    l.BackgroundTransparency = 1
    l.Text = "— " .. text .. " —"
    l.TextColor3 = Theme.SubText
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.ZIndex = 23
    l.Parent = parent
end

local function addToggle(parent, text, default, cb)
    local state = default or false
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -52, 1, 0)
    lb.Position = UDim2.new(0, 9, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 11
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 34, 0, 18)
    sw.Position = UDim2.new(1, -42, 0.5, -9)
    sw.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.ZIndex = 24
    sw.Parent = f
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = sw

    local kn = Instance.new("Frame")
    kn.Size = UDim2.new(0, 12, 0, 12)
    kn.Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    kn.BorderSizePixel = 0
    kn.ZIndex = 25
    kn.Parent = sw
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = kn

    local function update()
        TweenService:Create(sw, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
        }):Play()
        TweenService:Create(kn, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
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

local function addSlider(parent, text, minV, maxV, defV, isFloat, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 44)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -60, 0, 16)
    lb.Position = UDim2.new(0, 9, 0, 3)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 11
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 50, 0, 16)
    vl.Position = UDim2.new(1, -57, 0, 3)
    vl.BackgroundTransparency = 1
    vl.Text = isFloat and string.format("%.2f", defV) or tostring(defV)
    vl.TextColor3 = Theme.Accent
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 10
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.ZIndex = 24
    vl.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -16, 0, 5)
    bar.Position = UDim2.new(0, 8, 1, -12)
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
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 26
    knob.Parent = bar
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    -- Невидимый hitbox на весь frame
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
        local rel = math.clamp((absX - bAbs.X) / bW, 0, 1)
        local v = minV + (maxV - minV) * rel
        if not isFloat then v = math.floor(v + 0.5) end
        cur = v
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        vl.Text = isFloat and string.format("%.2f", v) or tostring(v)
        if cb then pcall(cb, v) end
    end

    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    hitbox.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
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

local function addDropdown(parent, text, options, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.5, 0, 1, 0)
    lb.Position = UDim2.new(0, 9, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 11
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local cur = def
    local vb = Instance.new("TextButton")
    vb.Size = UDim2.new(0, 70, 0, 20)
    vb.Position = UDim2.new(1, -76, 0.5, -10)
    vb.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    vb.BorderSizePixel = 0
    vb.Text = cur .. " ▾"
    vb.TextColor3 = Theme.Accent
    vb.Font = Enum.Font.GothamMedium
    vb.TextSize = 10
    vb.AutoButtonColor = false
    vb.ZIndex = 24
    vb.Parent = f
    local vbc = Instance.new("UICorner"); vbc.CornerRadius = UDim.new(0, 5); vbc.Parent = vb

    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(1, -14, 0, 0)
    lf.Position = UDim2.new(0, 7, 0, 34)
    lf.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    lf.BorderSizePixel = 0
    lf.ClipsDescendants = true
    lf.ZIndex = 30
    lf.Parent = f
    local lfc = Instance.new("UICorner"); lfc.CornerRadius = UDim.new(0, 5); lfc.Parent = lf

    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 2)
    ll.Parent = lf

    local lp = Instance.new("UIPadding")
    lp.PaddingTop = UDim.new(0, 3)
    lp.PaddingBottom = UDim.new(0, 3)
    lp.Parent = lf

    local opened = false

    local function rebuild()
        for _, c2 in ipairs(lf:GetChildren()) do
            if c2:IsA("TextButton") then c2:Destroy() end
        end
        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, -6, 0, 20)
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
                vb.Text = opt .. " ▾"
                opened = false
                TweenService:Create(f, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 32)}):Play()
                if cb then pcall(cb, opt) end
            end)
        end
    end

    bindTap(vb, function()
        opened = not opened
        if opened then
            rebuild()
            local h = 32 + 6 + #options * 22
            TweenService:Create(f, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, h)
            }):Play()
        else
            TweenService:Create(f, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 32)
            }):Play()
        end
    end)

    return { get = function() return cur end, set = function(v) cur = v; vb.Text = v .. " ▾" end }
end

local function addColorPicker(parent, text, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 34)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.35, 0, 1, 0)
    lb.Position = UDim2.new(0, 9, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 10
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local row = Instance.new("Frame")
    row.Size = UDim2.new(0, 150, 0, 22)
    row.Position = UDim2.new(1, -156, 0.5, -11)
    row.BackgroundTransparency = 1
    row.ZIndex = 24
    row.Parent = f

    local rl = Instance.new("UIListLayout")
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.VerticalAlignment = Enum.VerticalAlignment.Center
    rl.Padding = UDim.new(0, 4)
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
        b.Size = UDim2.new(0, 20, 0, 20)
        b.BackgroundColor3 = col
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.ZIndex = 25
        b.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = b
        bindTap(b, function() if cb then pcall(cb, col) end end)
    end
end

local function addActionButton(parent, text, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = color or Theme.Accent
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = false
    b.ZIndex = 24
    b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = b
    bindTap(b, cb)
    return b
end

-- ==================== CREATE TABS ====================
local espPage   = createTab("ESP", "👁")
local aimPage   = createTab("Aim", "🎯")
local otherPage = createTab("Other", "✨")
local infoPage  = createTab("Info", "ℹ")

-- ==================== ESP TAB ====================
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

addColorPicker(espPage, "Игроки", State.espPlayerColor, function(col)
    State.espPlayerColor = col
    for model, hl in pairs(espHighlights) do
        if hl and hl.Parent and Players:GetPlayerFromCharacter(model) then
            hl.FillColor = col
        end
    end
end)

addColorPicker(espPage, "Боты", State.espBotColor, function(col)
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

addToggle(espPage, "Игнор союзников", State.espTeamCheck, function(v)
    State.espTeamCheck = v
end)

addSlider(espPage, "Макс. дистанция", 50, 2000, State.espMaxDistance, false, function(v)
    State.espMaxDistance = v
end)

-- ==================== AIM TAB ====================
-- Режим (верхний уровень)
local normalAimFrame = Instance.new("Frame")
normalAimFrame.Size = UDim2.new(1, 0, 0, 0)
normalAimFrame.BackgroundTransparency = 1
normalAimFrame.ZIndex = 23
normalAimFrame.Parent = aimPage

local nafLayout = Instance.new("UIListLayout")
nafLayout.Padding = UDim.new(0, 5)
nafLayout.Parent = normalAimFrame

local nafSize = Instance.new("AutomaticSize")
nafSize.Parent = normalAimFrame

local autoAimFrame = Instance.new("Frame")
autoAimFrame.Size = UDim2.new(1, 0, 0, 0)
autoAimFrame.BackgroundTransparency = 1
autoAimFrame.Visible = false
autoAimFrame.ZIndex = 23
autoAimFrame.Parent = aimPage

local aafLayout = Instance.new("UIListLayout")
aafLayout.Padding = UDim.new(0, 5)
aafLayout.Parent = autoAimFrame

local aafSize = Instance.new("AutomaticSize")
aafSize.Parent = autoAimFrame

addSection(aimPage, "РЕЖИМ")

addToggle(aimPage, "⚡ Авто-выстрел", State.autoShoot, function(v)
    State.autoShoot = v
    normalAimFrame.Visible = not v
    autoAimFrame.Visible = v
    fovCircle.Visible = (not v) and State.aimEnabled and State.aimVisibleFov
    if not v then autoMarker.Visible = false end
end)

-- === Обычные настройки Aim ===
addSection(normalAimFrame, "ОСНОВНОЕ")

addToggle(normalAimFrame, "Включить Aim", State.aimEnabled, function(v)
    State.aimEnabled = v
    if fovCircle then fovCircle.Visible = v and State.aimVisibleFov end
end)

addSection(normalAimFrame, "ПРИЦЕЛИВАНИЕ")

addDropdown(normalAimFrame, "Целиться в", {"Head", "HumanoidRootPart", "Nearest"}, State.aimTargetPart, function(v)
    State.aimTargetPart = v
end)

addSlider(normalAimFrame, "FOV", 20, 600, State.aimFov, false, function(v)
    State.aimFov = v
    fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

addSlider(normalAimFrame, "Плавность", 0.02, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end)

addSlider(normalAimFrame, "Макс. дистанция", 50, 2000, State.aimMaxDistance, false, function(v)
    State.aimMaxDistance = v
end)

addSection(normalAimFrame, "ДОПОЛНИТЕЛЬНО")

addToggle(normalAimFrame, "Проверка стен", State.aimWallCheck, function(v) State.aimWallCheck = v end)
addToggle(normalAimFrame, "Игнор союзников", State.aimTeamCheck, function(v) State.aimTeamCheck = v end)
addToggle(normalAimFrame, "Показывать FOV", State.aimVisibleFov, function(v)
    State.aimVisibleFov = v
    fovCircle.Visible = v and State.aimEnabled
end)

addColorPicker(normalAimFrame, "Цвет FOV", State.aimFovColor, function(col)
    State.aimFovColor = col
    fovStroke.Color = col
end)

-- === Auto-Shoot ===
addSection(autoAimFrame, "AUTO-SHOOT")

local pickerCallback = nil

local function startPicking(callback)
    hintLabel.Visible = true
    MainFrame.Visible = false
    CircleBtn.Visible = false
    pickerCallback = callback
end

addActionButton(autoAimFrame, "🎯 ВЫБРАТЬ КНОПКУ", Color3.fromRGB(50, 130, 255), function()
    startPicking(function(pos)
        State.autoButtonPos = pos
        autoMarker.Position = UDim2.new(0, pos.X, 0, pos.Y)
        autoMarker.Visible = true
    end)
end)

addActionButton(autoAimFrame, "❌ СБРОСИТЬ КНОПКУ", Color3.fromRGB(60, 60, 70), function()
    State.autoButtonPos = nil
    autoMarker.Visible = false
end)

addSection(autoAimFrame, "ПАРАМЕТРЫ")

addToggle(autoAimFrame, "Обзор 360°", State.auto360, function(v) State.auto360 = v end)

addDropdown(autoAimFrame, "Вид", {"1st", "3rd"}, State.autoView, function(v)
    State.autoView = v
    if v == "1st" then
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
    end
end)

addToggle(autoAimFrame, "Silent (без поворота камеры)", State.autoSilent, function(v)
    State.autoSilent = v
end)

addSlider(autoAimFrame, "Задержка", 0, 0.5, State.autoDelay, true, function(v)
    State.autoDelay = v
end)

addSlider(autoAimFrame, "Резкость захвата", 0.05, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end)

-- ==================== OTHER (SPIN) ====================
addSection(otherPage, "SPIN")

addToggle(otherPage, "Включить Spin", State.spinEnabled, function(v)
    State.spinEnabled = v
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
countLabel.Size = UDim2.new(1, 0, 0, 30)
countLabel.BackgroundColor3 = Theme.Card
countLabel.BorderSizePixel = 0
countLabel.Text = "Игроков: " .. #Players:GetPlayers()
countLabel.TextColor3 = Theme.Text
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 11
countLabel.ZIndex = 23
countLabel.Parent = infoPage
local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0, 7); clc.Parent = countLabel

Players.PlayerAdded:Connect(function()
    countLabel.Text = "Игроков: " .. #Players:GetPlayers()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    countLabel.Text = "Игроков: " .. #Players:GetPlayers()
end)

local nickLabel = Instance.new("TextLabel")
nickLabel.Size = UDim2.new(1, 0, 0, 22)
nickLabel.BackgroundTransparency = 1
nickLabel.Text = "Ник: " .. LocalPlayer.Name
nickLabel.TextColor3 = Theme.SubText
nickLabel.Font = Enum.Font.GothamMedium
nickLabel.TextSize = 10
nickLabel.ZIndex = 23
nickLabel.Parent = infoPage

-- ==================== MENU OPEN/CLOSE ====================
local isOpen = false
local animating = false

local function openMenu()
    if animating or isOpen then return end
    animating = true
    isOpen = true
    print("[DarkHub] open")
    TweenService:Create(CircleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0), Rotation = 90
    }):Play()
    task.delay(0.2, function()
        if not isOpen then animating = false; return end
        CircleBtn.Visible = false
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 320, 0, 240)
        MainFrame.BackgroundTransparency = 0.5
        local t = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 340, 0, 260),
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
    print("[DarkHub] close")
    local t = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 300, 0, 230), BackgroundTransparency = 1
    })
    t:Play()
    t.Completed:Connect(function()
        MainFrame.Visible = false
        CircleBtn.Visible = true
        CircleBtn.Rotation = -90
        local t2 = TweenService:Create(CircleBtn, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 42, 0, 42), Rotation = 0
        })
        t2:Play()
        t2.Completed:Connect(function() animating = false end)
    end)
end

-- ЕДИНЫЙ обработчик для кружка
bindDragAndTap(CircleBtn, nil, function()
    if isOpen then
        closeMenu()
    else
        openMenu()
    end
end)

bindTap(CloseBtn, function()
    closeMenu()
end)

-- ==================== PICKER LISTENER ====================
UserInputService.InputBegan:Connect(function(input)
    if not pickerCallback then return end
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local cb = pickerCallback
        pickerCallback = nil
        hintLabel.Visible = false
        MainFrame.Visible = isOpen
        CircleBtn.Visible = not isOpen
        cb(pos)
    end
end)

-- ==================== ESP LOGIC ====================
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
        pcall(function() model:WaitForChild("Humanoid", 3) end)
        hum = model:FindFirstChildOfClass("Humanoid")
        if not hum then return end
    end

    local oldHl = espHighlights[model]
    if oldHl and oldHl.Parent then oldHl:Destroy() end
    local stale = model:FindFirstChild("PlayerHighlight")
    if stale then stale:Destroy() end
    local oldBb = espBillboards[model]
    if oldBb and oldBb.Parent then oldBb:Destroy() end
    local staleBb = model:FindFirstChild("NameESP")
    if staleBb then staleBb:Destroy() end

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

    local text
    if isPlayer then
        local plr = Players:GetPlayerFromCharacter(model)
        text = plr and plr.DisplayName or model.Name
    else
        text = "BOT"
    end
    local bb = createBillboard(model, text)
    local head = model:FindFirstChild("Head")
    if not head then pcall(function() head = model:WaitForChild("Head", 3) end) end
    bb.Adornee = head or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    bb.Enabled = State.espEnabled and State.espShowNames
    espBillboards[model] = bb
end

local function registerPlayer(player)
    if player == LocalPlayer then return end

    if player.Character then
        task.spawn(function() refreshHighlight(player.Character, true) end)
    end

    player.CharacterAdded:Connect(function(char)
        task.wait(0.2)
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

local function tryRegisterBot(model)
    if not model or not model.Parent then return end
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
                        if (useFullCircle or d2 <= State.aimFov) and isVisible(part) then
                            if d2 < bestDist then
                                bestDist = d2
                                best = part
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function pressAutoButton()
    if not State.autoButtonPos then return end
    local pos = State.autoButtonPos
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    if autoMarker.Visible then
        local orig = amS.Color
        amS.Color = Color3.fromRGB(120, 255, 120)
        task.delay(0.15, function()
            if amS and amS.Parent then amS.Color = orig end
        end)
    end
end

local autoShootCooldown = 0

RunService.RenderStepped:Connect(function(dt)
    if State.autoShoot then
        autoShootCooldown = autoShootCooldown - dt
        local target = findBestTarget(State.auto360)
        if target then
            local curCF = Camera.CFrame
            if State.autoSilent then
                local savedCF = curCF
                local targetCF = CFrame.new(curCF.Position, target.Position)
                Camera.CFrame = targetCF
                if autoShootCooldown <= 0 then
                    pressAutoButton()
                    autoShootCooldown = State.autoDelay + 0.15
                end
                Camera.CFrame = savedCF
            else
                local targetCF = CFrame.new(curCF.Position, target.Position)
                Camera.CFrame = curCF:Lerp(targetCF, math.clamp(State.aimSharpness, 0.05, 1))
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

    local newCF = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
    if State.spinHeadDown then
        newCF = newCF * CFrame.Angles(math.rad(35), 0, 0)
    end
    hrp.CFrame = newCF
end)

-- Восстановление AutoRotate
task.spawn(function()
    while task.wait(0.5) do
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

print("[DarkHub Mobile v3] Загружено")

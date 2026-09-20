-- [[ DARK HUB // MOBILE v6 - ULTIMATE ENGINE ]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

-- Очистка старых копий
pcall(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
    if pg and pg:FindFirstChild("DarkMenuHub") then
        pg.DarkMenuHub:Destroy()
    end
end)

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj.Name == "PlayerHighlight" or obj.Name == "NameESP" then
        pcall(function() obj:Destroy() end)
    end
end

-- ScreenGui Setup
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
    -- ESP
    espEnabled = false,
    espPlayerColor = Color3.fromRGB(255, 60, 60),
    espBotColor = Color3.fromRGB(255, 210, 60),
    espFillTransparency = 0.5,
    espOutlineTransparency = 0.1,
    espShowNames = true,
    espTeamCheck = false,
    espMaxDistance = 800,

    -- AIM
    aimEnabled = false,
    aimBots = true,
    aimFov = 130,
    aimSharpness = 0.4,
    aimTargetPart = "Head",
    aimWallCheck = false,
    aimTeamCheck = false,
    aimMaxDistance = 500,
    aimVisibleFov = true,
    aimFovColor = Color3.fromRGB(110, 86, 248),

    -- AUTO-SHOOT
    autoShoot = false,
    autoMethod = "VirtualInput", -- VirtualInput, ToolActivate, FastTap
    autoButtonPos = nil,
    auto360 = true,
    autoSilent = false,
    autoDelay = 0.05,
    customDPad = false,

    -- THIRD PERSON BYPASS
    thirdPersonMode = "None", -- None, MinZoomFix, ManualOffset, ScriptOverride
    thirdPersonDistance = 14,

    -- SPIN
    spinEnabled = false,
    spinSpeed = 180,
    spinHeadDown = true,
}

local espHighlights = {}
local espBillboards = {}
local botList = {}

-- ==================== HELPERS ====================
local function bindTap(gui, cb)
    local pressPos = Vector2.zero
    local pressTime = 0
    local isDown = false

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDown = true
            pressTime = tick()
            pressPos = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    gui.InputEnded:Connect(function(input)
        if not isDown then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDown = false
            local curPos = Vector2.new(input.Position.X, input.Position.Y)
            if (curPos - pressPos).Magnitude < 15 and (tick() - pressTime) < 0.6 then
                task.spawn(function()
                    local ok, err = pcall(cb)
                    if not ok then warn("[Tap Error]", err) end
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

-- ==================== AUTO MARKER ====================
local autoMarker = Instance.new("Frame")
autoMarker.AnchorPoint = Vector2.new(0.5, 0.5)
autoMarker.Size = UDim2.new(0, 50, 0, 50)
autoMarker.BackgroundTransparency = 1
autoMarker.Visible = false
autoMarker.ZIndex = 50
autoMarker.Parent = ScreenGui

local amC = Instance.new("UICorner"); amC.CornerRadius = UDim.new(1, 0); amC.Parent = autoMarker
local amS = Instance.new("UIStroke"); amS.Color = Color3.fromRGB(80, 255, 120); amS.Thickness = 2; amS.Parent = autoMarker

-- ==================== HINT ====================
local hintLabel = Instance.new("TextLabel")
hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
hintLabel.Position = UDim2.new(0.5, 0, 0.12, 0)
hintLabel.Size = UDim2.new(0, 310, 0, 44)
hintLabel.BackgroundColor3 = Theme.Background
hintLabel.BackgroundTransparency = 0.15
hintLabel.Text = "НАЖМИ НА ЭКРАНЕ, ГДЕ КНОПКА ОГНЯ"
hintLabel.TextColor3 = Theme.Text
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 12
hintLabel.Visible = false
hintLabel.ZIndex = 200
hintLabel.Parent = ScreenGui

local hlC = Instance.new("UICorner"); hlC.CornerRadius = UDim.new(0, 10); hlC.Parent = hintLabel
local hlS = Instance.new("UIStroke"); hlS.Color = Theme.Accent; hlS.Thickness = 1.5; hlS.Parent = hintLabel

-- ==================== VIRTUAL D-PAD (FIX ХОДЬБЫ) ====================
local dpadFrame = Instance.new("Frame")
dpadFrame.Size = UDim2.new(0, 130, 0, 130)
dpadFrame.Position = UDim2.new(0.04, 0, 0.65, 0)
dpadFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
dpadFrame.BackgroundTransparency = 0.3
dpadFrame.BorderSizePixel = 0
dpadFrame.Visible = false
dpadFrame.ZIndex = 150
dpadFrame.Parent = ScreenGui
local dpadC = Instance.new("UICorner"); dpadC.CornerRadius = UDim.new(1, 0); dpadC.Parent = dpadFrame
local dpadS = Instance.new("UIStroke"); dpadS.Color = Theme.Accent; dpadS.Thickness = 1.5; dpadS.Parent = dpadFrame

local moveDir = Vector3.zero
local function createDpadBtn(txt, pos, dir)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 36, 0, 36)
    b.Position = pos
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundColor3 = Theme.Card
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.ZIndex = 151
    b.Parent = dpadFrame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = b

    local pressed = false
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressed = true
            moveDir = moveDir + dir
            b.BackgroundColor3 = Theme.Accent
        end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if pressed then
                pressed = false
                moveDir = moveDir - dir
                b.BackgroundColor3 = Theme.Card
            end
        end
    end)
end

createDpadBtn("▲", UDim2.new(0.5, 0, 0.2, 0), Vector3.new(0, 0, -1))
createDpadBtn("▼", UDim2.new(0.5, 0, 0.8, 0), Vector3.new(0, 0, 1))
createDpadBtn("◀", UDim2.new(0.2, 0, 0.5, 0), Vector3.new(-1, 0, 0))
createDpadBtn("▶", UDim2.new(0.8, 0, 0.5, 0), Vector3.new(1, 0, 0))

RunService.RenderStepped:Connect(function()
    if State.customDPad and moveDir.Magnitude > 0 and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:Move(moveDir, true)
        end
    end
end)

-- ==================== CIRCLE BUTTON ====================
local CircleBtn = Instance.new("TextButton")
CircleBtn.Size = UDim2.new(0, 44, 0, 44)
CircleBtn.Position = UDim2.new(0.06, 0, 0.4, 0)
CircleBtn.BackgroundColor3 = Theme.Background
CircleBtn.BorderSizePixel = 0
CircleBtn.Text = "⚡"
CircleBtn.TextColor3 = Theme.Accent
CircleBtn.TextSize = 18
CircleBtn.Font = Enum.Font.GothamBold
CircleBtn.AutoButtonColor = false
CircleBtn.Active = true
CircleBtn.ZIndex = 100
CircleBtn.Parent = ScreenGui

local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = CircleBtn
local cs = Instance.new("UIStroke"); cs.Color = Theme.Accent; cs.Thickness = 2; cs.Parent = CircleBtn

-- ==================== MAIN WINDOW ====================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 270)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.ZIndex = 20
MainFrame.Parent = ScreenGui

local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 12); mc.Parent = MainFrame
local ms = Instance.new("UIStroke"); ms.Color = Theme.Border; ms.Thickness = 1.2; ms.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 36)
Topbar.BackgroundTransparency = 1
Topbar.ZIndex = 21
Topbar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "DARK HUB // <font color='rgb(110,86,248)'>v6 MOBILE</font>"
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
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 22
CloseBtn.Parent = Topbar
local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0, 6); cc2.Parent = CloseBtn

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 84, 1, -36)
Sidebar.Position = UDim2.new(0, 0, 0, 36)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 21
Sidebar.Parent = MainFrame

local SideList = Instance.new("UIListLayout")
SideList.Padding = UDim.new(0, 5)
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 6)
SidePad.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -94, 1, -44)
ContentContainer.Position = UDim2.new(0, 88, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true
ContentContainer.ZIndex = 21
ContentContainer.Parent = MainFrame

-- ==================== DRAG & TOGGLE ====================
local isMenuOpen = false
local animating = false

local function setMenuVisible(state)
    if animating then return end
    animating = true
    isMenuOpen = state

    if state then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 10, 0, 10)
        local t = TweenService:Create(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 360, 0, 270)
        })
        t:Play()
        TweenService:Create(CircleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Theme.Accent,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        t.Completed:Connect(function() animating = false end)
    else
        local t = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        t:Play()
        TweenService:Create(CircleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Theme.Background,
            TextColor3 = Theme.Accent
        }):Play()
        t.Completed:Connect(function()
            if not isMenuOpen then MainFrame.Visible = false end
            animating = false
        end)
    end
end

do
    local dragging = false
    local dragStart = nil
    local frameStart = nil
    local moved = false
    local TAP_THRESHOLD = 10

    CircleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            dragStart = input.Position
            frameStart = CircleBtn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            if delta.Magnitude > TAP_THRESHOLD then moved = true end
            if moved then
                CircleBtn.Position = UDim2.new(
                    frameStart.X.Scale, frameStart.X.Offset + delta.X,
                    frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
                )
            end
        end
    end)

    CircleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                dragging = false
                if not moved then
                    setMenuVisible(not isMenuOpen)
                end
            end
        end
    end)
end

bindTap(CloseBtn, function() setMenuVisible(false) end)

-- ==================== TAB SYSTEM ====================
local tabs = {}
local activeTab = nil

local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 74, 0, 28)
    btn.BackgroundTransparency = 1
    btn.Text = " " .. icon .. " " .. name
    btn.TextColor3 = Theme.SubText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.LayoutOrder = order or 1
    btn.ZIndex = 22
    btn.Parent = Sidebar

    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
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
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = page

    local data = { Button = btn, Page = page }
    tabs[name] = data

    bindTap(btn, function()
        if activeTab == data then return end
        for _, t in pairs(tabs) do
            t.Button.BackgroundTransparency = 1
            t.Button.TextColor3 = Theme.SubText
            t.Page.Visible = false
        end
        activeTab = data
        data.Page.Visible = true
        btn.BackgroundColor3 = Theme.Card
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Theme.Text
    end)
    return page
end

-- ==================== UI BUILDERS ====================
local function addSection(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = "— " .. text .. " —"
    l.TextColor3 = Theme.SubText
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.ZIndex = 23
    l.Parent = parent
    return l
end

local function addToggle(parent, text, default, cb)
    local state = default or false
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -52, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 11
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 38, 0, 20)
    sw.Position = UDim2.new(1, -46, 0.5, -10)
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
        TweenService:Create(sw, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
        }):Play()
        TweenService:Create(kn, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        if cb then task.spawn(cb, state) end
    end

    bindTap(sw, function()
        state = not state
        update()
    end)

    return {
        Frame = f,
        get = function() return state end,
        set = function(v) state = v; update() end
    }
end

local function addSlider(parent, text, minV, maxV, defV, isFloat, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 42)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -60, 0, 16)
    lb.Position = UDim2.new(0, 10, 0, 3)
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
    vl.Position = UDim2.new(1, -56, 0, 3)
    vl.BackgroundTransparency = 1
    vl.Text = isFloat and string.format("%.2f", defV) or tostring(defV)
    vl.TextColor3 = Theme.Accent
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 10
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.ZIndex = 24
    vl.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -16, 0, 6)
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

    hitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(inp.Position.X)
        end
    end)

    hitbox.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(inp.Position.X)
        end
    end)

    return {
        Frame = f,
        get = function() return cur end,
        set = function(v)
            cur = v
            local rel = math.clamp((v - minV) / (maxV - minV), 0, 1)
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
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.48, 0, 0, 32)
    lb.Position = UDim2.new(0, 10, 0, 0)
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
    vb.Size = UDim2.new(0, 88, 0, 22)
    vb.Position = UDim2.new(1, -94, 0, 5)
    vb.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    vb.BorderSizePixel = 0
    vb.Text = cur .. " ▾"
    vb.TextColor3 = Theme.Accent
    vb.Font = Enum.Font.GothamMedium
    vb.TextSize = 10
    vb.AutoButtonColor = false
    vb.ZIndex = 24
    vb.Parent = f
    local vbc = Instance.new("UICorner"); vbc.CornerRadius = UDim.new(0, 6); vbc.Parent = vb

    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(1, -16, 0, #options * 22 + 4)
    lf.Position = UDim2.new(0, 8, 0, 34)
    lf.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    lf.BorderSizePixel = 0
    lf.ZIndex = 30
    lf.Visible = false
    lf.Parent = f
    local lfc = Instance.new("UICorner"); lfc.CornerRadius = UDim.new(0, 6); lfc.Parent = lf

    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 2)
    ll.Parent = lf

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 20)
        ob.BackgroundColor3 = (opt == cur) and Theme.Accent or Color3.fromRGB(28, 28, 36)
        ob.BorderSizePixel = 0
        ob.Text = opt
        ob.TextColor3 = Color3.fromRGB(255, 255, 255)
        ob.Font = Enum.Font.Gotham
        ob.TextSize = 10
        ob.ZIndex = 31
        ob.Parent = lf
        local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 4); oc.Parent = ob

        bindTap(ob, function()
            cur = opt
            vb.Text = opt .. " ▾"
            lf.Visible = false
            TweenService:Create(f, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 32)}):Play()
            if cb then pcall(cb, opt) end
        end)
    end

    bindTap(vb, function()
        local opened = not lf.Visible
        lf.Visible = opened
        local targetH = opened and (36 + #options * 22) or 32
        TweenService:Create(f, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetH)}):Play()
    end)

    return {
        Frame = f,
        get = function() return cur end,
        set = function(v) cur = v; vb.Text = v .. " ▾" end
    }
end

local function addColorPicker(parent, text, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.35, 0, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 10
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 24
    lb.Parent = f

    local row = Instance.new("Frame")
    row.Size = UDim2.new(0, 155, 0, 22)
    row.Position = UDim2.new(1, -160, 0.5, -11)
    row.BackgroundTransparency = 1
    row.ZIndex = 24
    row.Parent = f

    local rl = Instance.new("UIListLayout")
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.VerticalAlignment = Enum.VerticalAlignment.Center
    rl.Padding = UDim.new(0, 5)
    rl.Parent = row

    local palette = {
        Color3.fromRGB(255, 60, 60),
        Color3.fromRGB(60, 255, 120),
        Color3.fromRGB(60, 170, 255),
        Color3.fromRGB(255, 220, 60),
        Color3.fromRGB(200, 80, 255),
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

    return { Frame = f }
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
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
    bindTap(b, cb)
    return b
end

-- ==================== TABS CREATION ====================
local aimPage   = createTab("Aim", "🎯", 1)
local espPage   = createTab("ESP", "👁", 2)
local otherPage = createTab("Other", "✨", 3)

-- ============================================================
-- AIM TAB
-- ============================================================
local aimElements = {}

local function setGroupVisible(group, visible)
    for _, el in ipairs(group) do
        if typeof(el) == "Instance" then
            el.Visible = visible
        elseif typeof(el) == "table" and el.Frame then
            el.Frame.Visible = visible
        end
    end
end

aimElements.secMode = addSection(aimPage, "РЕЖИМ")

aimElements.modeToggle = addToggle(aimPage, "⚡ Авто-выстрел (Mobile)", State.autoShoot, function(v)
    State.autoShoot = v
    setGroupVisible(aimElements.normalGroup, not v)
    setGroupVisible(aimElements.autoGroup, v)
    fovCircle.Visible = (not v) and State.aimEnabled and State.aimVisibleFov
    if not v then autoMarker.Visible = false end
end)

-- --- Обычный Aim ---
aimElements.normalGroup = {}

table.insert(aimElements.normalGroup, addSection(aimPage, "ОСНОВНОЕ"))

table.insert(aimElements.normalGroup, addToggle(aimPage, "Включить Aim", State.aimEnabled, function(v)
    State.aimEnabled = v
    fovCircle.Visible = v and State.aimVisibleFov and not State.autoShoot
end))

table.insert(aimElements.normalGroup, addToggle(aimPage, "Аим на ботов/NPC", State.aimBots, function(v)
    State.aimBots = v
end))

table.insert(aimElements.normalGroup, addSection(aimPage, "ПРИЦЕЛИВАНИЕ"))

table.insert(aimElements.normalGroup, addDropdown(aimPage, "Цель", {"Head", "HumanoidRootPart", "Nearest"}, State.aimTargetPart, function(v)
    State.aimTargetPart = v
end))

table.insert(aimElements.normalGroup, addSlider(aimPage, "Радиус FOV", 40, 600, State.aimFov, false, function(v)
    State.aimFov = v
    fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end))

table.insert(aimElements.normalGroup, addSlider(aimPage, "Плавность / Доводка", 0.05, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end))

table.insert(aimElements.normalGroup, addSlider(aimPage, "Макс. дистанция", 50, 2000, State.aimMaxDistance, false, function(v)
    State.aimMaxDistance = v
end))

table.insert(aimElements.normalGroup, addSection(aimPage, "ДОПОЛНИТЕЛЬНО"))

table.insert(aimElements.normalGroup, addToggle(aimPage, "Проверка стен", State.aimWallCheck, function(v)
    State.aimWallCheck = v
end))

table.insert(aimElements.normalGroup, addToggle(aimPage, "Игнор союзников", State.aimTeamCheck, function(v)
    State.aimTeamCheck = v
end))

table.insert(aimElements.normalGroup, addToggle(aimPage, "Круг FOV", State.aimVisibleFov, function(v)
    State.aimVisibleFov = v
    fovCircle.Visible = v and State.aimEnabled and not State.autoShoot
end))

table.insert(aimElements.normalGroup, addColorPicker(aimPage, "Цвет FOV", State.aimFovColor, function(col)
    State.aimFovColor = col
    fovStroke.Color = col
end))

-- --- Auto-Shoot Group ---
aimElements.autoGroup = {}

local pickerCallback = nil
local function startPicking(callback)
    hintLabel.Visible = true
    MainFrame.Visible = false
    CircleBtn.Visible = false
    pickerCallback = callback
end

table.insert(aimElements.autoGroup, addSection(aimPage, "МЕТОД СТРЕЛЬБЫ"))

table.insert(aimElements.autoGroup, addDropdown(aimPage, "Метод", {"VirtualInput", "ToolActivate", "FastTap"}, State.autoMethod, function(v)
    State.autoMethod = v
end))

table.insert(aimElements.autoGroup, addToggle(aimPage, "Джойстик ходьбы (Fix)", State.customDPad, function(v)
    State.customDPad = v
    dpadFrame.Visible = v
end))

table.insert(aimElements.autoGroup, addSection(aimPage, "ПОЗИЦИЯ КНОПКИ ОГНЯ"))

table.insert(aimElements.autoGroup, addActionButton(aimPage, "🎯 ВЫБРАТЬ КНОПКУ ОГНЯ", Color3.fromRGB(50, 130, 255), function()
    startPicking(function(pos)
        State.autoButtonPos = pos
        autoMarker.Position = UDim2.new(0, pos.X, 0, pos.Y)
        autoMarker.Visible = true
    end)
end))

table.insert(aimElements.autoGroup, addActionButton(aimPage, "❌ СБРОСИТЬ КНОПКУ", Color3.fromRGB(60, 60, 70), function()
    State.autoButtonPos = nil
    autoMarker.Visible = false
end))

table.insert(aimElements.autoGroup, addSection(aimPage, "ПАРАМЕТРЫ"))

table.insert(aimElements.autoGroup, addToggle(aimPage, "Обзор 360°", State.auto360, function(v)
    State.auto360 = v
end))

table.insert(aimElements.autoGroup, addToggle(aimPage, "Silent (без дёргания)", State.autoSilent, function(v)
    State.autoSilent = v
end))

table.insert(aimElements.autoGroup, addSlider(aimPage, "Интервал стрельбы", 0.02, 0.5, State.autoDelay, true, function(v)
    State.autoDelay = v
end))

table.insert(aimElements.autoGroup, addSlider(aimPage, "Резкость наводки", 0.05, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end))

setGroupVisible(aimElements.normalGroup, true)
setGroupVisible(aimElements.autoGroup, false)

-- ============================================================
-- ESP TAB
-- ============================================================
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

addColorPicker(espPage, "Боты / NPC", State.espBotColor, function(col)
    State.espBotColor = col
    for model, hl in pairs(espHighlights) do
        if hl and hl.Parent and not Players:GetPlayerFromCharacter(model) then
            hl.FillColor = col
        end
    end
end)

addSection(espPage, "НАСТРОЙКИ")

addToggle(espPage, "Показывать ники / HP", State.espShowNames, function(v)
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

-- ============================================================
-- OTHER TAB (3rd Person Bypasses & Spin)
-- ============================================================
addSection(otherPage, "3-Е ЛИЦО (ОБХОД ОГРАНИЧЕНИЙ)")

addDropdown(otherPage, "Способ обхода", {"None", "MinZoomFix", "ManualOffset", "ScriptOverride"}, State.thirdPersonMode, function(mode)
    State.thirdPersonMode = mode
    if mode == "None" then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 400
    elseif mode == "MinZoomFix" then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = State.thirdPersonDistance
        LocalPlayer.CameraMaxZoomDistance = math.max(State.thirdPersonDistance + 10, 40)
    elseif mode == "ScriptOverride" then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        pcall(function()
            LocalPlayer.DevEnableMouseLock = true
            LocalPlayer.DevComputerCameraMovementMode = Enum.DevComputerCameraMovementMode.Follow
        end)
    end
end)

addSlider(otherPage, "Дистанция 3-го лица", 4, 30, State.thirdPersonDistance, false, function(v)
    State.thirdPersonDistance = v
    if State.thirdPersonMode == "MinZoomFix" then
        LocalPlayer.CameraMinZoomDistance = v
        LocalPlayer.CameraMaxZoomDistance = math.max(v + 10, 40)
    end
end)

addSection(otherPage, "SPINBOT")

addToggle(otherPage, "Включить Spin", State.spinEnabled, function(v)
    State.spinEnabled = v
    if not v and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end
end)

addSlider(otherPage, "Скорость вращения", 30, 720, State.spinSpeed, false, function(v)
    State.spinSpeed = v
end)

addToggle(otherPage, "Наклон вниз", State.spinHeadDown, function(v)
    State.spinHeadDown = v
end)

-- ==================== PICKER LISTENER ====================
UserInputService.InputBegan:Connect(function(input)
    if not pickerCallback then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local cb = pickerCallback
        pickerCallback = nil
        hintLabel.Visible = false
        MainFrame.Visible = isMenuOpen
        CircleBtn.Visible = not isMenuOpen
        cb(pos)
    end
end)

-- ==================== ESP & SCANNER ENGINE ====================
local function applyHighlight(model, isPlayer)
    if not model or not model.Parent then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if espHighlights[model] then pcall(function() espHighlights[model]:Destroy() end) end
    if espBillboards[model] then pcall(function() espBillboards[model]:Destroy() end) end
    local oldH = model:FindFirstChild("PlayerHighlight"); if oldH then pcall(function() oldH:Destroy() end) end
    local oldB = model:FindFirstChild("NameESP"); if oldB then pcall(function() oldB:Destroy() end) end

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

    local head = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Name = "NameESP"
        bb.Size = UDim2.new(0, 120, 0, 24)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = State.espEnabled and State.espShowNames
        bb.Adornee = head
        bb.Parent = model

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        if isPlayer then
            local plr = Players:GetPlayerFromCharacter(model)
            local hp = math.floor(hum.Health)
            txt.Text = string.format("%s [%d HP]", plr and plr.DisplayName or model.Name, hp)
        else
            txt.Text = string.format("BOT [%d HP]", math.floor(hum.Health))
        end
        txt.TextColor3 = isPlayer and State.espPlayerColor or State.espBotColor
        txt.TextStrokeTransparency = 0.2
        txt.Font = Enum.Font.GothamBold
        txt.TextScaled = true
        txt.Parent = bb

        espBillboards[model] = bb

        hum.HealthChanged:Connect(function(newHp)
            if txt and txt.Parent then
                local title = isPlayer and (Players:GetPlayerFromCharacter(model) and Players:GetPlayerFromCharacter(model).DisplayName or model.Name) or "BOT"
                txt.Text = string.format("%s [%d HP]", title, math.max(0, math.floor(newHp)))
            end
        end)
    end
end

local function scanEntities()
    -- 1. Считываем игроков
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.Parent then
            if not espHighlights[p.Character] then
                applyHighlight(p.Character, true)
            end
        end
    end

    -- 2. Считываем ботов / NPC
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local isPlr = Players:GetPlayerFromCharacter(obj) ~= nil
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if not isPlr then
                    botList[obj] = true
                    if not espHighlights[obj] then
                        applyHighlight(obj, false)
                    end
                end
            end
        end
    end
end

-- Периодический принудительный опрос Workspace (ловит перерождения и скрытых игроков)
task.spawn(function()
    while true do
        pcall(scanEntities)
        task.wait(1.5)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        applyHighlight(char, true)
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then
        if espHighlights[plr.Character] then pcall(function() espHighlights[plr.Character]:Destroy() end) end
        espHighlights[plr.Character] = nil
        if espBillboards[plr.Character] then pcall(function() espBillboards[plr.Character]:Destroy() end) end
        espBillboards[plr.Character] = nil
    end
end)

-- ==================== AIMBOT & TARGETING ====================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(part)
    if not State.aimWallCheck then return true end
    if not LocalPlayer.Character then return false end
    local camPos = Camera.CFrame.Position
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    local hit = Workspace:Raycast(camPos, part.Position - camPos, rayParams)
    return hit == nil
end

local function isTeammate(model)
    if not State.aimTeamCheck then return false end
    local plr = Players:GetPlayerFromCharacter(model)
    if plr and plr.Team and LocalPlayer.Team then
        return plr.Team == LocalPlayer.Team
    end
    return false
end

local function getTargetAimPart(model)
    if State.aimTargetPart == "Head" then
        return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    elseif State.aimTargetPart == "HumanoidRootPart" then
        return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
    else
        local h = model:FindFirstChild("Head")
        local r = model:FindFirstChild("HumanoidRootPart")
        if not h then return r end
        if not r then return h end
        local camPos = Camera.CFrame.Position
        return ((h.Position - camPos).Magnitude < (r.Position - camPos).Magnitude) and h or r
    end
end

local function findBestAimTarget(is360)
    if not LocalPlayer.Character then return nil end
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local bestPart = nil
    local bestDistance = is360 and math.huge or State.aimFov
    local camPos = Camera.CFrame.Position

    local candidates = {}

    -- Игроки
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.Parent and not isTeammate(p.Character) then
            table.insert(candidates, p.Character)
        end
    end

    -- Боты
    if State.aimBots then
        for botModel, _ in pairs(botList) do
            if botModel and botModel.Parent and not isTeammate(botModel) then
                table.insert(candidates, botModel)
            end
        end
    end

    for _, model in ipairs(candidates) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local part = getTargetAimPart(model)
        if hum and hum.Health > 0 and part then
            local dist3D = (part.Position - camPos).Magnitude
            if dist3D <= State.aimMaxDistance then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen or is360 then
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if (is360 or dist2D <= State.aimFov) and isVisible(part) then
                        if dist2D < bestDistance then
                            bestDistance = dist2D
                            bestPart = part
                        end
                    end
                end
            end
        end
    end

    return bestPart
end

-- ==================== AUTO SHOOT ENGINES ====================
local function fireWeapon()
    if State.autoMethod == "ToolActivate" then
        -- Активация тула без потери фокуса тачпада
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end
    elseif State.autoButtonPos then
        -- Нажатие через VirtualInputManager
        local pos = State.autoButtonPos
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            if State.autoMethod ~= "FastTap" then
                task.wait(0.03)
            end
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end)
    end

    if autoMarker.Visible then
        local orig = amS.Color
        amS.Color = Color3.fromRGB(255, 255, 255)
        task.delay(0.1, function()
            if amS and amS.Parent then amS.Color = orig end
        end)
    end
end

-- ==================== RUNTIME LOOPS ====================
local autoShootCooldown = 0

RunService.RenderStepped:Connect(function(dt)
    -- --- AUTO-SHOOT & AIMBOT ---
    if State.autoShoot then
        autoShootCooldown = autoShootCooldown - dt
        local target = findBestAimTarget(State.auto360)
        if target then
            local curCF = Camera.CFrame
            if State.autoSilent then
                local savedCF = curCF
                Camera.CFrame = CFrame.new(curCF.Position, target.Position)
                if autoShootCooldown <= 0 then
                    fireWeapon()
                    autoShootCooldown = State.autoDelay + 0.08
                end
                Camera.CFrame = savedCF
            else
                local targetCF = CFrame.new(curCF.Position, target.Position)
                local snap = math.clamp(State.aimSharpness * 1.5, 0.05, 1)
                Camera.CFrame = curCF:Lerp(targetCF, snap)

                local sp, onScreen = Camera:WorldToViewportPoint(target.Position)
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if onScreen and d < 20 and autoShootCooldown <= 0 then
                    fireWeapon()
                    autoShootCooldown = State.autoDelay + 0.08
                end
            end
        end
    elseif State.aimEnabled then
        local target = findBestAimTarget(false)
        if target then
            local curCF = Camera.CFrame
            local targetCF = CFrame.new(curCF.Position, target.Position)
            local snap = math.clamp(State.aimSharpness * 1.2, 0.05, 1)
            Camera.CFrame = curCF:Lerp(targetCF, snap)
        end
    end

    -- --- 3RD PERSON MANUAL OFFSET BYPASS ---
    if State.thirdPersonMode == "ManualOffset" and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local rot = Camera.CFrame - Camera.CFrame.Position
            local backOffset = -rot.LookVector * State.thirdPersonDistance + Vector3.new(0, 2.5, 0)
            Camera.CFrame = CFrame.new(hrp.Position + backOffset) * rot
        end
    end
end)

-- Spinbot
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

-- ==================== DEFAULT TAB INIT ====================
task.defer(function()
    if tabs["Aim"] then
        tabs["Aim"].Button.BackgroundColor3 = Theme.Card
        tabs["Aim"].Button.BackgroundTransparency = 0
        tabs["Aim"].Button.TextColor3 = Theme.Text
        tabs["Aim"].Page.Visible = true
        activeTab = tabs["Aim"]
    end
end)

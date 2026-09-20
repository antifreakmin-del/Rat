-- [[ DARK HUB // MOBILE v3 - FULLY FIXED & STABLE ]]
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

-- Очистка старых копий GUI
pcall(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
    if pg and pg:FindFirstChild("DarkMenuHub") then
        pg.DarkMenuHub:Destroy()
    end
end)

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

    spinEnabled = false,
    spinSpeed = 180,
    spinHeadDown = true,
}

local espHighlights = {}
local espBillboards = {}

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
Topbar.Size = UDim2.new(1, 0, 0, 34)
Topbar.BackgroundTransparency = 1
Topbar.ZIndex = 21
Topbar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
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
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 22
CloseBtn.Parent = Topbar

local cc2 = Instance.new("UICorner")
cc2.CornerRadius = UDim.new(0, 6)
cc2.Parent = CloseBtn

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 80, 1, -34)
Sidebar.Position = UDim2.new(0, 0, 0, 34)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 21
Sidebar.Parent = MainFrame

local SideList = Instance.new("UIListLayout")
SideList.Padding = UDim.new(0, 4)
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 4)
SidePad.Parent = Sidebar

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -88, 1, -42)
ContentContainer.Position = UDim2.new(0, 84, 0, 38)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 21
ContentContainer.Parent = MainFrame

-- ==================== TOGGLE BUTTON & DRAG LOGIC ====================
local CircleBtn = Instance.new("TextButton")
CircleBtn.Size = UDim2.new(0, 48, 0, 48)
CircleBtn.Position = UDim2.new(0.06, 0, 0.35, 0)
CircleBtn.BackgroundColor3 = Theme.Background
CircleBtn.BorderSizePixel = 0
CircleBtn.Text = "⚡"
CircleBtn.TextColor3 = Theme.Accent
CircleBtn.TextSize = 20
CircleBtn.Font = Enum.Font.GothamBold
CircleBtn.AutoButtonColor = false
CircleBtn.Active = true
CircleBtn.ZIndex = 50
CircleBtn.Parent = ScreenGui

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(1, 0)
cc.Parent = CircleBtn

local cs = Instance.new("UIStroke")
cs.Color = Theme.Accent
cs.Thickness = 2
cs.Parent = CircleBtn

local isMenuOpen = false
local animating = false

local function setMenuVisible(state)
    if animating then return end
    animating = true
    isMenuOpen = state

    if state then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 10, 0, 10)
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 340, 0, 260)
        }):Play()
        TweenService:Create(CircleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Theme.Accent,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        animating = false
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
            if not isMenuOpen then
                MainFrame.Visible = false
            end
            animating = false
        end)
    end
end

-- Перемещение кнопки с разграничением тапа и сдвига
local isDragging = false
local dragStartPos = nil
local frameStartPos = nil
local isMoved = false

CircleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        isMoved = false
        dragStartPos = input.Position
        frameStartPos = CircleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartPos
        if delta.Magnitude > 14 then
            isMoved = true
        end
        CircleBtn.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end
end)

CircleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isDragging then
            isDragging = false
            if not isMoved then
                setMenuVisible(not isMenuOpen)
            end
        end
    end
end)

CloseBtn.Activated:Connect(function()
    setMenuVisible(false)
end)

-- ==================== TAB SYSTEM ====================
local tabs = {}
local activeTab = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 72, 0, 28)
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
    bc.CornerRadius = UDim.new(0, 6)
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
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = page

    local data = { Button = btn, Page = page }
    tabs[name] = data

    btn.Activated:Connect(function()
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

-- ==================== BUILDERS ====================
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
end

local function addToggle(parent, text, default, cb)
    local state = default or false
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 34)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -56, 1, 0)
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
    sw.Size = UDim2.new(0, 42, 0, 22)
    sw.Position = UDim2.new(1, -50, 0.5, -11)
    sw.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.ZIndex = 24
    sw.Parent = f
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = sw

    local kn = Instance.new("Frame")
    kn.Size = UDim2.new(0, 16, 0, 16)
    kn.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
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
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        if cb then task.spawn(cb, state) end
    end

    sw.Activated:Connect(function()
        state = not state
        update()
    end)
end

local function addSlider(parent, text, minV, maxV, defV, isFloat, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 44)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -60, 0, 16)
    lb.Position = UDim2.new(0, 10, 0, 4)
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
    vl.Position = UDim2.new(1, -56, 0, 4)
    vl.BackgroundTransparency = 1
    vl.Text = isFloat and string.format("%.2f", defV) or tostring(defV)
    vl.TextColor3 = Theme.Accent
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 10
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.ZIndex = 24
    vl.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 1, -12)
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

    local touchBtn = Instance.new("TextButton")
    touchBtn.Size = UDim2.new(1, 0, 1, 0)
    touchBtn.BackgroundTransparency = 1
    touchBtn.Text = ""
    touchBtn.ZIndex = 27
    touchBtn.Parent = f

    local dragging = false
    local function updateFromInput(inputX)
        local rel = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = minV + (maxV - minV) * rel
        if not isFloat then val = math.floor(val + 0.5) end
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        vl.Text = isFloat and string.format("%.2f", val) or tostring(val)
        if cb then pcall(cb, val) end
    end

    touchBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromInput(inp.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            updateFromInput(inp.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function addDropdown(parent, text, options, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 34)
    f.BackgroundColor3 = Theme.Card
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    f.ZIndex = 23
    f.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.5, 0, 0, 34)
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
    vb.Size = UDim2.new(0, 80, 0, 22)
    vb.Position = UDim2.new(1, -86, 0, 6)
    vb.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    vb.BorderSizePixel = 0
    vb.Text = cur .. " ▾"
    vb.TextColor3 = Theme.Accent
    vb.Font = Enum.Font.GothamMedium
    vb.TextSize = 10
    vb.ZIndex = 24
    vb.Parent = f
    local vbc = Instance.new("UICorner"); vbc.CornerRadius = UDim.new(0, 6); vbc.Parent = vb

    local opened = false
    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(1, -16, 0, #options * 24 + 4)
    lf.Position = UDim2.new(0, 8, 0, 36)
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
        ob.Size = UDim2.new(1, 0, 0, 22)
        ob.BackgroundColor3 = (opt == cur) and Theme.Accent or Color3.fromRGB(28, 28, 36)
        ob.BorderSizePixel = 0
        ob.Text = opt
        ob.TextColor3 = Color3.fromRGB(255, 255, 255)
        ob.Font = Enum.Font.Gotham
        ob.TextSize = 10
        ob.ZIndex = 31
        ob.Parent = lf
        local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 4); oc.Parent = ob

        ob.Activated:Connect(function()
            cur = opt
            vb.Text = opt .. " ▾"
            opened = false
            lf.Visible = false
            TweenService:Create(f, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 34)}):Play()
            if cb then pcall(cb, opt) end
        end)
    end

    vb.Activated:Connect(function()
        opened = not opened
        lf.Visible = opened
        local targetH = opened and (38 + #options * 24) or 34
        TweenService:Create(f, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetH)}):Play()
    end)
end

local function addColorPicker(parent, text, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 34)
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
    row.Size = UDim2.new(0, 150, 0, 22)
    row.Position = UDim2.new(1, -156, 0.5, -11)
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
        b.Size = UDim2.new(0, 22, 0, 22)
        b.BackgroundColor3 = col
        b.BorderSizePixel = 0
        b.Text = ""
        b.ZIndex = 25
        b.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = b
        b.Activated:Connect(function()
            if cb then pcall(cb, col) end
        end)
    end
end

-- ==================== СТРАНИЦЫ МЕНЮ ====================
local espPage   = createTab("ESP", "👁")
local aimPage   = createTab("Aim", "🎯")
local otherPage = createTab("Other", "✨")

-- Вкладка ESP
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

addSection(espPage, "НАСТРОЙКИ")
addToggle(espPage, "Показывать ники", State.espShowNames, function(v)
    State.espShowNames = v
    for _, bb in pairs(espBillboards) do
        if bb and bb.Parent then bb.Enabled = v and State.espEnabled end
    end
end)
addToggle(espPage, "Игнор союзников", State.espTeamCheck, function(v) State.espTeamCheck = v end)
addSlider(espPage, "Макс. дистанция", 50, 1500, State.espMaxDistance, false, function(v) State.espMaxDistance = v end)

-- Вкладка Aim
addSection(aimPage, "ОСНОВНОЕ")
addToggle(aimPage, "Включить Aim", State.aimEnabled, function(v)
    State.aimEnabled = v
    fovCircle.Visible = v and State.aimVisibleFov
end)

addDropdown(aimPage, "Цель", {"Head", "HumanoidRootPart"}, State.aimTargetPart, function(v)
    State.aimTargetPart = v
end)

addSlider(aimPage, "Радиус FOV", 40, 400, State.aimFov, false, function(v)
    State.aimFov = v
    fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

addSlider(aimPage, "Плавность", 0.05, 1, State.aimSharpness, true, function(v)
    State.aimSharpness = v
end)

addToggle(aimPage, "Проверка стен", State.aimWallCheck, function(v) State.aimWallCheck = v end)
addToggle(aimPage, "Круг FOV", State.aimVisibleFov, function(v)
    State.aimVisibleFov = v
    fovCircle.Visible = v and State.aimEnabled
end)

-- Вкладка Other
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

-- ==================== ESP СИСТЕМА ====================
local function applyHighlight(model, isPlayer)
    if not model or not model.Parent then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if espHighlights[model] then espHighlights[model]:Destroy() end
    if espBillboards[model] then espBillboards[model]:Destroy() end

    local hl = Instance.new("Highlight")
    hl.FillColor = State.espPlayerColor
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = State.espFillTransparency
    hl.OutlineTransparency = State.espOutlineTransparency
    hl.Adornee = model
    hl.Enabled = State.espEnabled
    hl.Parent = model
    espHighlights[model] = hl

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = State.espEnabled and State.espShowNames
    bb.Adornee = model:FindFirstChild("Head") or model.PrimaryPart
    bb.Parent = model

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    local plr = Players:GetPlayerFromCharacter(model)
    txt.Text = plr and plr.DisplayName or model.Name
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.TextStrokeTransparency = 0.3
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Parent = bb

    espBillboards[model] = bb
end

local function registerPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then applyHighlight(player.Character, true) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        applyHighlight(char, true)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do registerPlayer(p) end
Players.PlayerAdded:Connect(registerPlayer)

-- ==================== AIMBOT ====================
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

RunService.RenderStepped:Connect(function()
    if not State.aimEnabled then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local minDistance = State.aimFov

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and (not State.aimTeamCheck or p.Team ~= LocalPlayer.Team) then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild(State.aimTargetPart)
            if hum and hum.Health > 0 and part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= minDistance and isVisible(part) then
                        minDistance = d
                        bestTarget = part
                    end
                end
            end
        end
    end

    if bestTarget then
        local curCF = Camera.CFrame
        local targetCF = CFrame.new(curCF.Position, bestTarget.Position)
        Camera.CFrame = curCF:Lerp(targetCF, math.clamp(State.aimSharpness, 0.05, 1))
    end
end)

-- ==================== SPINBOT ====================
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
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
end)

-- Открываем первую вкладку
task.defer(function()
    if tabs["ESP"] then
        tabs["ESP"].Button.BackgroundColor3 = Theme.Card
        tabs["ESP"].Button.BackgroundTransparency = 0
        tabs["ESP"].Button.TextColor3 = Theme.Text
        tabs["ESP"].Page.Visible = true
        activeTab = tabs["ESP"]
    end
end)

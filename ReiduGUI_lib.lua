--[[
    ReiduGUI v1.1 - Standalone GUI Library
    ========================================
    Added in v1.1:
      • Feature search bar (type to filter across all tabs)
      • Floating toggle button (always-visible, draggable)
      • AddColorPicker(section, label, defaultHex, callback)
      • Feature registry (all controls are searchable)

    USAGE:
        local GUI = loadstring(game:HttpGet("YOUR_URL"))()

        local win = GUI.new({
            title      = "My Script",
            version    = "v1.0",
            accent     = "7C5CBF",
            background = "0D0D0F",
            main       = "141418",
            outline    = "2A2A35",
            toggleKey  = Enum.KeyCode.Insert,
        })

        win:SetProgress(0.5, "loading...")

        local tab     = win:AddTab("Main", "o")
        local section = win:AddSection(tab, "FEATURES")

        local toggle = win:AddToggle(section, "Auto Farm", false, function(val)
            print("Auto Farm:", val)
        end)

        local slider = win:AddSlider(section, "Speed", 16, 100, 16, function(val)
            print("Speed:", val)
        end)

        local colorCtrl = win:AddColorPicker(section, "Accent Color", "7C5CBF", function(hex)
            print("New color:", hex)
        end)

        local setCoins = win:AddStatusLabel("Coins: 0", 1)
        setCoins("Coins: 1.2M")

        win:SetProgress(1.0, "ready!")
        win:Dismiss()
]]

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
-- MODULE
-- ============================================================
local ReiduGUI = {}
ReiduGUI.__index = ReiduGUI

-- ============================================================
-- PRIVATE HELPERS
-- ============================================================
local function HexToColor(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1,2), 16) or 0,
        tonumber(hex:sub(3,4), 16) or 0,
        tonumber(hex:sub(5,6), 16) or 0
    )
end

local function ColorToHex(c)
    return string.format("%02X%02X%02X",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

local function Tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local fast  = TweenInfo.new(0.2)
local quint = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ============================================================
-- CONSTRUCTOR
-- ============================================================
function ReiduGUI.new(cfg)
    cfg = cfg or {}

    local self = setmetatable({}, ReiduGUI)

    self._theme = {
        Background = cfg.background or "0D0D0F",
        Main       = cfg.main       or "141418",
        Accent     = cfg.accent     or "7C5CBF",
        Outline    = cfg.outline    or "2A2A35",
    }
    self._title     = cfg.title      or "ReiduGUI"
    self._version   = cfg.version    or "v1.0"
    self._toggleKey = cfg.toggleKey  or Enum.KeyCode.Insert

    self._tabs           = {}
    self._toastQueue     = {}
    self._toastRunning   = false
    self._featureRegistry = {}
    self._lastActiveTab  = nil

    self:_BuildLoader()
    self:_BuildMainFrame()
    self:_BuildToast()
    self:_BuildAmbient()
    self:_BuildFloatingButton()

    -- Toggle visibility hotkey
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == self._toggleKey then
            if self._mainFrame then
                self._mainFrame.Visible = not self._mainFrame.Visible
            end
        end
    end)

    return self
end

function ReiduGUI:T(key)
    return HexToColor(self._theme[key])
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================
function ReiduGUI:_BuildLoader()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ReiduLoader"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self._loadGui = gui

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.BackgroundColor3 = Color3.fromRGB(5,5,8)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1
    overlay.Parent = gui
    self._loadOverlay = overlay

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0,320,0,140)
    card.AnchorPoint = Vector2.new(0.5,0.5)
    card.Position = UDim2.new(0.5,0,0.5,0)
    card.BackgroundColor3 = Color3.fromRGB(14,14,20)
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(100,60,180)
    stroke.Thickness = 1
    self._loadCard   = card
    self._loadStroke = stroke

    local scan = Instance.new("Frame")
    scan.Size = UDim2.new(1,0,1,0)
    scan.BackgroundColor3 = Color3.fromRGB(100,60,180)
    scan.BackgroundTransparency = 0.95
    scan.BorderSizePixel = 0
    scan.ZIndex = 3
    scan.Parent = card
    Instance.new("UICorner", scan).CornerRadius = UDim.new(0,12)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = self._title
    titleLbl.Size = UDim2.new(1,-20,0,40)
    titleLbl.Position = UDim2.new(0,10,0,16)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = Color3.fromRGB(200,170,255)
    titleLbl.TextSize = 22
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.ZIndex = 4
    titleLbl.TextXAlignment = Enum.TextXAlignment.Center
    titleLbl.Parent = card
    self._loadTitle = titleLbl

    local sub = Instance.new("TextLabel")
    sub.Text = "initializing..."
    sub.Size = UDim2.new(1,-20,0,18)
    sub.Position = UDim2.new(0,10,0,54)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = Color3.fromRGB(100,85,140)
    sub.TextSize = 11
    sub.Font = Enum.Font.Gotham
    sub.ZIndex = 4
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.Parent = card
    self._loadSub = sub

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-40,0,4)
    track.Position = UDim2.new(0,20,0,88)
    track.BackgroundColor3 = Color3.fromRGB(25,20,45)
    track.BorderSizePixel = 0
    track.ZIndex = 4
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(0.5,0)
    self._loadTrack = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(140,80,255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5,0)
    local grad = Instance.new("UIGradient", fill)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(100,50,220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,130,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(100,50,220)),
    })
    self._loadFill = fill
    self._loadGrad = grad

    local ver = Instance.new("TextLabel")
    ver.Text = self._version
    ver.Size = UDim2.new(1,-20,0,16)
    ver.Position = UDim2.new(0,10,0,108)
    ver.BackgroundTransparency = 1
    ver.TextColor3 = Color3.fromRGB(55,45,85)
    ver.TextSize = 10
    ver.Font = Enum.Font.Gotham
    ver.ZIndex = 4
    ver.TextXAlignment = Enum.TextXAlignment.Center
    ver.Parent = card
    self._loadVer = ver

    Tween(overlay, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.4})
    Tween(card,    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0})

    task.spawn(function()
        local cols = {Color3.fromRGB(200,170,255), Color3.fromRGB(160,100,255), Color3.fromRGB(220,190,255)}
        local i = 1
        while gui.Parent do
            i = i%#cols + 1
            Tween(titleLbl, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {TextColor3 = cols[i]})
            task.wait(1.2)
        end
    end)

    task.spawn(function()
        local r = 0
        while gui.Parent do
            task.wait(0.05)
            r = (r+1)%360
            grad.Rotation = r
        end
    end)

    task.delay(20, function()
        if self._mainFrame and not self._mainFrame.Visible then
            self._mainFrame.Visible = true
            pcall(function() gui:Destroy() end)
        end
    end)
end

function ReiduGUI:SetProgress(pct, label)
    Tween(self._loadFill, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
        Size = UDim2.new(pct, 0, 1, 0)
    })
    if label then self._loadSub.Text = label end
end

function ReiduGUI:Dismiss()
    task.delay(0.3, function()
        if self._mainFrame then self._mainFrame.Visible = true end
    end)
    local c = self._loadCard
    Tween(c, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5,0,0.45,0),
    })
    for _, elem in ipairs({self._loadTitle, self._loadSub, self._loadVer}) do
        Tween(elem, TweenInfo.new(0.3), {TextTransparency = 1})
    end
    Tween(self._loadFill,    TweenInfo.new(0.3), {BackgroundTransparency = 1})
    Tween(self._loadTrack,   TweenInfo.new(0.3), {BackgroundTransparency = 1})
    Tween(self._loadStroke,  TweenInfo.new(0.3), {Transparency = 1})
    Tween(self._loadOverlay, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
    task.delay(0.7, function() self._loadGui:Destroy() end)
end

-- ============================================================
-- MAIN FRAME
-- ============================================================
function ReiduGUI:_BuildMainFrame()
    local sg = Instance.new("ScreenGui")
    sg.Name = self._title
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    local parent = (ok and cg) or LocalPlayer:WaitForChild("PlayerGui")
    pcall(function() sg.Parent = parent end)
    sg.AncestryChanged:Connect(function()
        if not sg.Parent then pcall(function() sg.Parent = parent end) end
    end)
    self._screenGui = sg

    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0,580,0,520)
    mf.AnchorPoint = Vector2.new(0.5,0.5)
    mf.Position = UDim2.new(0.5,0,0.5,0)
    mf.BackgroundColor3 = self:T("Background")
    mf.BorderSizePixel = 0
    mf.Visible = false
    mf.Parent = sg
    Instance.new("UICorner", mf).CornerRadius = UDim.new(0,8)
    self._mainFrame  = mf
    self._mainStroke = Instance.new("UIStroke", mf)
    self._mainStroke.Color = self:T("Outline")
    self._mainStroke.Thickness = 1

    local function PC(xS,yS,xO,yO)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,6,0,6)
        f.Position = UDim2.new(xS,xO,yS,yO)
        f.BackgroundColor3 = Color3.fromRGB(180,120,255)
        f.BorderSizePixel = 0; f.ZIndex = 10; f.Parent = mf
    end
    PC(0,0,2,2); PC(1,0,-8,2); PC(0,1,2,-8); PC(1,1,-8,-8)

    local scan = Instance.new("Frame")
    scan.Size = UDim2.new(1,0,1,0)
    scan.BackgroundTransparency = 0.97
    scan.BackgroundColor3 = Color3.fromRGB(120,80,200)
    scan.BorderSizePixel = 0; scan.ZIndex = 0; scan.Parent = mf

    self:_BuildTitleBar(mf)

    -- Nav sidebar
    local nav = Instance.new("Frame")
    nav.Size = UDim2.new(0,110,0,452)
    nav.Position = UDim2.new(0,0,0,40)
    nav.BackgroundColor3 = self:T("Main")
    nav.BorderSizePixel = 0
    nav.Parent = mf
    local nl = Instance.new("UIListLayout", nav)
    nl.SortOrder = Enum.SortOrder.LayoutOrder
    nl.Padding = UDim.new(0,2)
    local np = Instance.new("UIPadding", nav)
    np.PaddingTop = UDim.new(0,8)
    np.PaddingLeft = UDim.new(0,6)
    np.PaddingRight = UDim.new(0,6)
    self._navFrame = nav
    self:_HookDrag(nav)

    -- Tab container — sits below the search bar (y=72)
    local tc = Instance.new("Frame")
    tc.Size = UDim2.new(0,462,0,420)
    tc.Position = UDim2.new(0,114,0,72)
    tc.BackgroundTransparency = 1
    tc.BorderSizePixel = 0
    tc.Parent = mf
    self._tabContainer = tc

    -- Live / status bar
    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(1,0,0,28)
    lf.Position = UDim2.new(0,0,1,-28)
    lf.BackgroundColor3 = self:T("Main")
    lf.BorderSizePixel = 0
    lf.Parent = mf
    local ll = Instance.new("UIListLayout", lf)
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0,16)
    local lp = Instance.new("UIPadding", lf)
    lp.PaddingLeft = UDim.new(0,12); lp.PaddingTop = UDim.new(0,6)
    self._liveFrame  = lf
    self._liveLblIdx = 0
    self:_HookDrag(lf)

    -- Search bar (between title bar and tab content)
    self:_BuildSearch()

    -- Color picker popup (hidden, shared across all AddColorPicker rows)
    self:_BuildColorPicker()

    -- Avatar
    task.spawn(function()
        local af = Instance.new("Frame")
        af.Size = UDim2.new(0,54,0,54)
        af.Position = UDim2.new(0,28,1,-78)
        af.BackgroundColor3 = self:T("Main")
        af.BorderSizePixel = 0; af.ZIndex = 6; af.Parent = mf
        Instance.new("UICorner", af).CornerRadius = UDim.new(0.5,0)
        local afStroke = Instance.new("UIStroke", af)
        afStroke.Color = self:T("Accent"); afStroke.Thickness = 1.5
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1,0,1,0)
        img.BackgroundTransparency = 1; img.BorderSizePixel = 0; img.ZIndex = 7; img.Parent = af
        Instance.new("UICorner", img).CornerRadius = UDim.new(0.5,0)
        local ok2, url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok2 and url then img.Image = url end
    end)
end

function ReiduGUI:_BuildTitleBar(mf)
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1,0,0,36)
    tb.BackgroundColor3 = self:T("Main")
    tb.BorderSizePixel = 0; tb.Parent = mf
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,8)
    local fix = Instance.new("Frame")
    fix.Size = UDim2.new(1,0,0,8)
    fix.Position = UDim2.new(0,0,1,-8)
    fix.BackgroundColor3 = self:T("Main")
    fix.BorderSizePixel = 0; fix.Parent = tb
    self._titleBar    = tb
    self._titleBarFix = fix

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0,18,0,18)
    badge.Position = UDim2.new(0,10,0.5,-9)
    badge.BackgroundColor3 = Color3.fromRGB(130,70,220)
    badge.BorderSizePixel = 0; badge.Parent = tb
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0.5,0)
    local bi = Instance.new("Frame")
    bi.Size = UDim2.new(0,8,0,8); bi.Position = UDim2.new(0.5,-4,0.5,-4)
    bi.BackgroundColor3 = Color3.fromRGB(220,180,255)
    bi.BorderSizePixel = 0; bi.Parent = badge
    self._badge = badge

    local tl = Instance.new("TextLabel")
    tl.Text = self._title
    tl.Size = UDim2.new(1,-100,1,0); tl.Position = UDim2.new(0,34,0,0)
    tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(220,200,255)
    tl.TextSize = 13; tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Parent = tb
    self._titleLabel = tl

    local dt = Instance.new("TextLabel")
    dt.Size = UDim2.new(0,0,0,14); dt.AutomaticSize = Enum.AutomaticSize.X
    dt.Position = UDim2.new(0,152,0.5,-7)
    dt.BackgroundColor3 = Color3.fromRGB(60,35,110)
    dt.TextColor3 = Color3.fromRGB(190,160,255)
    dt.TextSize = 9; dt.Font = Enum.Font.GothamBold
    dt.BorderSizePixel = 0; dt.Parent = tb
    Instance.new("UICorner", dt).CornerRadius = UDim.new(0,3)
    local dp = Instance.new("UIPadding", dt)
    dp.PaddingLeft = UDim.new(0,5); dp.PaddingRight = UDim.new(0,5)
    task.spawn(function()
        while true do
            local d = os.date("*t")
            dt.Text = string.format("%02d/%02d/%04d  %02d:%02d:%02d  %s",
                d.day, d.month, d.year, d.hour, d.min, d.sec, LocalPlayer.Name)
            task.wait(1)
        end
    end)

    local al = Instance.new("Frame")
    al.Size = UDim2.new(1,0,0,1); al.Position = UDim2.new(0,0,1,0)
    al.BackgroundColor3 = Color3.fromRGB(140,80,255)
    al.BorderSizePixel = 0; al.Parent = tb
    local ag = Instance.new("UIGradient", al)
    ag.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(80,40,160)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,120,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(80,40,160)),
    })
    self._accentGrad = ag

    local close = Instance.new("TextButton")
    close.Text = "X"; close.Size = UDim2.new(0,28,0,28)
    close.Position = UDim2.new(1,-32,0,4)
    close.BackgroundColor3 = Color3.fromRGB(180,60,60)
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.TextSize = 12; close.Font = Enum.Font.GothamBold
    close.BorderSizePixel = 0; close.Parent = tb
    Instance.new("UICorner", close).CornerRadius = UDim.new(0,4)
    close.MouseButton1Click:Connect(function() self._mainFrame.Visible = false end)
    close.MouseEnter:Connect(function() Tween(close, fast, {BackgroundColor3 = Color3.fromRGB(220,80,80)}) end)
    close.MouseLeave:Connect(function() Tween(close, fast, {BackgroundColor3 = Color3.fromRGB(180,60,60)}) end)

    local min = Instance.new("TextButton")
    min.Text = "-"; min.Size = UDim2.new(0,28,0,28)
    min.Position = UDim2.new(1,-64,0,4)
    min.BackgroundColor3 = self:T("Outline")
    min.TextColor3 = Color3.fromRGB(180,180,200)
    min.TextSize = 14; min.Font = Enum.Font.GothamBold
    min.BorderSizePixel = 0; min.Parent = tb
    Instance.new("UICorner", min).CornerRadius = UDim.new(0,4)
    min.MouseEnter:Connect(function() Tween(min, fast, {BackgroundColor3 = Color3.fromRGB(80,80,95)}) end)
    min.MouseLeave:Connect(function() Tween(min, fast, {BackgroundColor3 = self:T("Outline")}) end)
    local minimized = false
    min.MouseButton1Click:Connect(function()
        minimized = not minimized
        if self._tabContainer then self._tabContainer.Visible = not minimized end
        if self._navFrame     then self._navFrame.Visible     = not minimized end
        if self._liveFrame    then self._liveFrame.Visible    = not minimized end
        if self._searchBox    then self._searchBox.Visible    = not minimized end
        self._mainFrame.Size = minimized
            and UDim2.new(0,580,0,36)
            or  UDim2.new(0,580,0,520)
    end)

    local drag = Instance.new("TextButton")
    drag.Size = UDim2.new(1,-80,1,0)
    drag.BackgroundTransparency = 1; drag.Text = ""
    drag.ZIndex = 5; drag.Parent = tb
    self:_HookDrag(drag)
    self:_HookDrag(tb)
end

function ReiduGUI:_HookDrag(f)
    local dragging, ds, fs = false, nil, nil
    f.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; ds = i.Position; fs = self._mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or
           i.UserInputType == Enum.UserInputType.Touch then
            local dx = i.Position.X - ds.X
            local dy = i.Position.Y - ds.Y
            self._mainFrame.Position = UDim2.new(
                fs.X.Scale, fs.X.Offset + dx,
                fs.Y.Scale, fs.Y.Offset + dy)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- SEARCH BAR  (new in v1.1)
-- ============================================================
function ReiduGUI:_BuildSearch()
    -- Results overlay (same position/size as tab container)
    local srFrame = Instance.new("ScrollingFrame")
    srFrame.Size = UDim2.new(1,0,1,0)
    srFrame.BackgroundTransparency = 1
    srFrame.BorderSizePixel = 0
    srFrame.ScrollBarThickness = 3
    srFrame.ScrollBarImageColor3 = self:T("Accent")
    srFrame.CanvasSize = UDim2.new(0,0,0,0)
    srFrame.Visible = false
    srFrame.ZIndex = 10
    srFrame.Parent = self._tabContainer
    local srLayout = Instance.new("UIListLayout", srFrame)
    srLayout.SortOrder = Enum.SortOrder.LayoutOrder
    srLayout.Padding = UDim.new(0,4)
    srLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        srFrame.CanvasSize = UDim2.new(0,0,0, srLayout.AbsoluteContentSize.Y + 15)
    end)
    local srPad = Instance.new("UIPadding", srFrame)
    srPad.PaddingTop = UDim.new(0,8)
    srPad.PaddingLeft = UDim.new(0,8)
    srPad.PaddingRight = UDim.new(0,12)
    self._searchResultsFrame = srFrame

    -- Search TextBox
    local sb = Instance.new("TextBox")
    sb.PlaceholderText = "search features..."
    sb.Text = ""
    sb.Size = UDim2.new(0,456,0,24)
    sb.Position = UDim2.new(0,116,0,44)
    sb.BackgroundColor3 = self:T("Background")
    sb.TextColor3 = Color3.fromRGB(235,232,255)
    sb.PlaceholderColor3 = Color3.fromRGB(140,130,165)
    sb.TextSize = 10
    sb.Font = Enum.Font.Gotham
    sb.TextXAlignment = Enum.TextXAlignment.Left
    sb.BorderSizePixel = 0
    sb.ClearTextOnFocus = false
    sb.Parent = self._mainFrame
    sb.ZIndex = 5
    Instance.new("UICorner", sb).CornerRadius = UDim.new(0,5)
    local sbPad = Instance.new("UIPadding", sb)
    sbPad.PaddingLeft = UDim.new(0,8)
    local sbStroke = Instance.new("UIStroke", sb)
    sbStroke.Color = self:T("Outline")
    sbStroke.Thickness = 0.5
    self._searchBox = sb

    sb.Focused:Connect(function()
        Tween(sbStroke, TweenInfo.new(0.15), {Color = self:T("Accent")})
    end)
    sb.FocusLost:Connect(function()
        if sb.Text == "" then
            Tween(sbStroke, TweenInfo.new(0.15), {Color = self:T("Outline")})
        end
    end)

    local function DoSearch(query)
        for _, c in pairs(srFrame:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
        query = query:lower():match("^%s*(.-)%s*$")
        if query == "" then
            srFrame.Visible = false
            if self._lastActiveTab then self:_SwitchTab(self._lastActiveTab) end
            return
        end
        srFrame.Visible = true
        for _, t in ipairs(self._tabs) do t.frame.Visible = false end

        local results = {}
        for _, entry in ipairs(self._featureRegistry) do
            if entry.labelLower:find(query, 1, true) then
                table.insert(results, entry)
            end
        end

        if #results == 0 then
            local noRes = Instance.new("TextLabel")
            noRes.Text = 'No results for "' .. query .. '"'
            noRes.Size = UDim2.new(1,0,0,30)
            noRes.BackgroundTransparency = 1
            noRes.TextColor3 = Color3.fromRGB(110,105,135)
            noRes.TextSize = 11; noRes.Font = Enum.Font.Gotham
            noRes.TextXAlignment = Enum.TextXAlignment.Left
            noRes.LayoutOrder = 1; noRes.Parent = srFrame
            return
        end

        for i, entry in ipairs(results) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1,0,0,34)
            row.BackgroundColor3 = self:T("Main")
            row.BorderSizePixel = 0; row.LayoutOrder = i
            row.Text = ""; row.AutoButtonColor = false
            row.Parent = srFrame
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)
            local rs = Instance.new("UIStroke", row)
            rs.Color = self:T("Outline"); rs.Thickness = 1

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = entry.label
            nameLbl.Size = UDim2.new(0.6,0,1,0)
            nameLbl.Position = UDim2.new(0,10,0,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3 = Color3.fromRGB(210,205,235)
            nameLbl.TextSize = 11; nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row

            local badge = Instance.new("TextLabel")
            badge.Text = entry.tabName
            badge.Size = UDim2.new(0,0,0,16)
            badge.AutomaticSize = Enum.AutomaticSize.X
            badge.AnchorPoint = Vector2.new(1,0.5)
            badge.Position = UDim2.new(1,-6,0.5,0)
            badge.BackgroundColor3 = self:T("Accent")
            badge.TextColor3 = Color3.fromRGB(255,255,255)
            badge.TextSize = 9; badge.Font = Enum.Font.GothamBold
            badge.BorderSizePixel = 0; badge.Parent = row
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0,3)
            local bp = Instance.new("UIPadding", badge)
            bp.PaddingLeft = UDim.new(0,5); bp.PaddingRight = UDim.new(0,5)

            row.MouseEnter:Connect(function()
                Tween(row, fast, {BackgroundColor3 = self:T("Background")})
                rs.Color = self:T("Accent")
            end)
            row.MouseLeave:Connect(function()
                Tween(row, fast, {BackgroundColor3 = self:T("Main")})
                rs.Color = self:T("Outline")
            end)

            local capTab = entry.tabName
            local capRow = entry.row
            row.MouseButton1Click:Connect(function()
                sb.Text = ""
                srFrame.Visible = false
                self._lastActiveTab = capTab
                self:_SwitchTab(capTab)
                if capRow and capRow.Parent then
                    task.spawn(function()
                        task.wait(0.05)
                        for _ = 1, 2 do
                            Tween(capRow, TweenInfo.new(0.12), {BackgroundColor3 = self:T("Accent")})
                            task.wait(0.18)
                            Tween(capRow, TweenInfo.new(0.12), {BackgroundColor3 = self:T("Main")})
                            task.wait(0.18)
                        end
                    end)
                end
            end)
        end
    end

    sb:GetPropertyChangedSignal("Text"):Connect(function()
        DoSearch(sb.Text)
    end)
end

-- Internal: register a feature row for search
function ReiduGUI:_RegisterFeature(label, section, row)
    local tabName = "?"
    pcall(function()
        for _, t in ipairs(self._tabs) do
            if section.Parent == t.frame then
                tabName = t.name
                break
            end
        end
    end)
    table.insert(self._featureRegistry, {
        label      = label,
        labelLower = label:lower(),
        tabName    = tabName,
        row        = row,
    })
end

-- ============================================================
-- FLOATING TOGGLE BUTTON  (new in v1.1)
-- ============================================================
function ReiduGUI:_BuildFloatingButton()
    local label = self._title
    local btn = Instance.new("TextButton")
    btn.Text = label .. " ▲"
    btn.Size = UDim2.new(0,90,0,24)
    btn.Position = UDim2.new(0,12,1,-36)
    btn.AnchorPoint = Vector2.new(0,1)
    btn.BackgroundColor3 = HexToColor("141418")
    btn.TextColor3 = Color3.fromRGB(180,140,255)
    btn.TextSize = 11; btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0; btn.ZIndex = 200
    btn.Parent = self._screenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = HexToColor("7C5CBF"); stroke.Thickness = 1
    self._floatingBtn = btn

    local togDragging, togDragStart, togBtnStart = false, nil, nil
    local wasDragged = false

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            togDragging = true; wasDragged = false
            togDragStart = input.Position
            togBtnStart  = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not togDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            local dx = input.Position.X - togDragStart.X
            local dy = input.Position.Y - togDragStart.Y
            if math.abs(dx) > 4 or math.abs(dy) > 4 then wasDragged = true end
            btn.Position = UDim2.new(
                togBtnStart.X.Scale, togBtnStart.X.Offset + dx,
                togBtnStart.Y.Scale, togBtnStart.Y.Offset + dy)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            togDragging = false
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if wasDragged then return end
        self._mainFrame.Visible = not self._mainFrame.Visible
        local visible = self._mainFrame.Visible
        btn.Text   = label .. (visible and " ▲" or " ▼")
        stroke.Color = visible and HexToColor("7C5CBF") or HexToColor("3A3A50")
    end)
    btn.MouseEnter:Connect(function()
        Tween(btn, fast, {BackgroundColor3 = HexToColor("1E1E2A")})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, fast, {BackgroundColor3 = HexToColor("141418")})
    end)
end

-- ============================================================
-- COLOR PICKER POPUP  (new in v1.1)
-- ============================================================
function ReiduGUI:_BuildColorPicker()
    -- Shared popup, shown/hidden per-row
    local pf = Instance.new("Frame")
    pf.Size = UDim2.new(0,260,0,196)
    pf.AnchorPoint = Vector2.new(0.5,0.5)
    pf.Position = UDim2.new(0.5,0,0.5,0)
    pf.BackgroundColor3 = HexToColor("1A1A24")
    pf.BorderSizePixel = 0
    pf.ZIndex = 50
    pf.Visible = false
    pf.Parent = self._tabContainer
    Instance.new("UICorner", pf).CornerRadius = UDim.new(0,8)
    local pfStroke = Instance.new("UIStroke", pf)
    pfStroke.Color = self:T("Accent"); pfStroke.Thickness = 1
    self._pickerFrame = pf

    local ptitle = Instance.new("TextLabel")
    ptitle.Text = "Pick Color"
    ptitle.Size = UDim2.new(1,-40,0,28); ptitle.Position = UDim2.new(0,10,0,4)
    ptitle.BackgroundTransparency = 1; ptitle.TextColor3 = Color3.fromRGB(210,200,240)
    ptitle.TextSize = 12; ptitle.Font = Enum.Font.GothamBold
    ptitle.TextXAlignment = Enum.TextXAlignment.Left
    ptitle.ZIndex = 51; ptitle.Parent = pf
    self._pickerTitle = ptitle

    local pclose = Instance.new("TextButton")
    pclose.Text = "X"; pclose.Size = UDim2.new(0,22,0,22)
    pclose.Position = UDim2.new(1,-26,0,4)
    pclose.BackgroundColor3 = Color3.fromRGB(160,50,50)
    pclose.TextColor3 = Color3.fromRGB(255,255,255)
    pclose.TextSize = 10; pclose.Font = Enum.Font.GothamBold
    pclose.BorderSizePixel = 0; pclose.ZIndex = 51; pclose.Parent = pf
    Instance.new("UICorner", pclose).CornerRadius = UDim.new(0,4)

    -- HSV sliders
    self._pickerH = 0; self._pickerS = 1; self._pickerV = 1

    local function MakeHSVSlider(labelChar, yPos, defaultVal)
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1,-20,0,18); bg.Position = UDim2.new(0,10,0,yPos)
        bg.BackgroundColor3 = HexToColor("2A2A38"); bg.BorderSizePixel = 0
        bg.ZIndex = 51; bg.Parent = pf
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0,4)
        local lc = Instance.new("TextLabel")
        lc.Text = labelChar; lc.Size = UDim2.new(0,12,1,0)
        lc.BackgroundTransparency = 1; lc.TextColor3 = Color3.fromRGB(170,160,200)
        lc.TextSize = 9; lc.Font = Enum.Font.GothamBold; lc.ZIndex = 52; lc.Parent = bg
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(defaultVal,0,1,0); fill.BackgroundColor3 = self:T("Accent")
        fill.BorderSizePixel = 0; fill.ZIndex = 52; fill.Parent = bg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0,12,0,12); knob.AnchorPoint = Vector2.new(0.5,0.5)
        knob.Position = UDim2.new(defaultVal,0,0.5,0)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.BorderSizePixel = 0; knob.ZIndex = 53; knob.Parent = bg
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5,0)
        return bg, fill, knob
    end

    local hTrack, hFill, hKnob = MakeHSVSlider("H", 36, 0)
    local sTrack, sFill, sKnob = MakeHSVSlider("S", 62, 1)
    local vTrack, vFill, vKnob = MakeHSVSlider("V", 88, 1)

    -- Preview swatch
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(1,-20,0,32); preview.Position = UDim2.new(0,10,0,114)
    preview.BackgroundColor3 = Color3.fromHSV(0,1,1); preview.BorderSizePixel = 0
    preview.ZIndex = 51; preview.Parent = pf
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0,5)
    local hexLbl = Instance.new("TextLabel")
    hexLbl.Text = "#7C5CBF"; hexLbl.Size = UDim2.new(0.7,0,1,0)
    hexLbl.BackgroundTransparency = 1; hexLbl.TextColor3 = Color3.fromRGB(220,215,240)
    hexLbl.TextSize = 11; hexLbl.Font = Enum.Font.Code
    hexLbl.ZIndex = 52; hexLbl.Parent = preview
    self._pickerPreview = preview
    self._pickerHexLbl  = hexLbl

    -- Apply button
    local applyBtn = Instance.new("TextButton")
    applyBtn.Text = "Apply"
    applyBtn.Size = UDim2.new(1,-20,0,22); applyBtn.Position = UDim2.new(0,10,0,154)
    applyBtn.BackgroundColor3 = self:T("Accent"); applyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    applyBtn.TextSize = 11; applyBtn.Font = Enum.Font.GothamBold
    applyBtn.BorderSizePixel = 0; applyBtn.ZIndex = 51; applyBtn.Parent = pf
    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0,5)

    -- Update preview colour
    local function RefreshPreview()
        local col = Color3.fromHSV(self._pickerH, self._pickerS, self._pickerV)
        preview.BackgroundColor3 = col
        hexLbl.Text = "#" .. ColorToHex(col)
        hFill.BackgroundColor3 = Color3.fromHSV(self._pickerH, 1, 1)
    end

    -- Drag helper for each slider track
    local function HookHSVSlider(track, fill, knob, onChange)
        local sliding = false
        local function SetX(px)
            local r = math.clamp(
                (px - track.AbsolutePosition.X - 14) / (track.AbsoluteSize.X - 14), 0, 1)
            fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,0,0.5,0)
            onChange(r); RefreshPreview()
        end
        local function MB1(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
        local function Mv(i)  return i.UserInputType==Enum.UserInputType.MouseMovement  or i.UserInputType==Enum.UserInputType.Touch end
        track.InputBegan:Connect(function(i)  if MB1(i) then sliding=true; SetX(i.Position.X) end end)
        track.InputEnded:Connect(function(i)  if MB1(i) then sliding=false end end)
        track.InputChanged:Connect(function(i) if sliding and Mv(i) then SetX(i.Position.X) end end)
        UserInputService.InputChanged:Connect(function(i) if sliding and Mv(i) then SetX(i.Position.X) end end)
        UserInputService.InputEnded:Connect(function(i)   if MB1(i) and sliding then sliding=false end end)
    end

    HookHSVSlider(hTrack, hFill, hKnob, function(v) self._pickerH = v end)
    HookHSVSlider(sTrack, sFill, sKnob, function(v) self._pickerS = v end)
    HookHSVSlider(vTrack, vFill, vKnob, function(v) self._pickerV = v end)

    self._pickerHTrack = hTrack; self._pickerHFill = hFill; self._pickerHKnob = hKnob
    self._pickerSTrack = sTrack; self._pickerSFill = sFill; self._pickerSKnob = sKnob
    self._pickerVTrack = vTrack; self._pickerVFill = vFill; self._pickerVKnob = vKnob
    self._pickerCallback = nil

    -- Close
    pclose.MouseButton1Click:Connect(function()
        pf.Visible = false
        self._pickerCallback = nil
    end)

    -- Apply
    applyBtn.MouseButton1Click:Connect(function()
        local col = Color3.fromHSV(self._pickerH, self._pickerS, self._pickerV)
        local hex = ColorToHex(col)
        if self._pickerApplyFn then self._pickerApplyFn(col, hex) end
        if self._pickerCallback then self._pickerCallback(hex) end
        pf.Visible = false
        self._pickerCallback = nil
        self._pickerApplyFn  = nil
    end)
end

-- Internal: open the color picker pointing to a hex default
function ReiduGUI:_OpenColorPicker(title, defaultHex, applyFn, callback)
    local col = HexToColor(defaultHex or "7C5CBF")
    self._pickerH, self._pickerS, self._pickerV = Color3.toHSV(col)

    -- Sync slider positions
    local function SyncSlider(fill, knob, v)
        fill.Size = UDim2.new(v,0,1,0); knob.Position = UDim2.new(v,0,0.5,0)
    end
    SyncSlider(self._pickerHFill, self._pickerHKnob, self._pickerH)
    SyncSlider(self._pickerSFill, self._pickerSKnob, self._pickerS)
    SyncSlider(self._pickerVFill, self._pickerVKnob, self._pickerV)

    self._pickerPreview.BackgroundColor3 = col
    self._pickerHexLbl.Text = "#" .. ColorToHex(col)
    self._pickerTitle.Text  = title or "Pick Color"
    self._pickerApplyFn  = applyFn
    self._pickerCallback = callback
    self._pickerFrame.Visible = true
end

-- ============================================================
-- TOAST SYSTEM
-- ============================================================
function ReiduGUI:_BuildToast()
    local tf = Instance.new("Frame")
    tf.Size = UDim2.new(0,240,0,36)
    tf.AnchorPoint = Vector2.new(1,0)
    tf.Position = UDim2.new(1,-10,1,60)
    tf.ClipsDescendants = false
    tf.Active = false
    tf.BackgroundColor3 = HexToColor("1A1A28")
    tf.BorderSizePixel = 0; tf.ZIndex = 200
    tf.Parent = self._screenGui
    Instance.new("UICorner", tf).CornerRadius = UDim.new(0,8)
    self._toastStroke = Instance.new("UIStroke", tf)
    self._toastStroke.Color = self:T("Accent"); self._toastStroke.Thickness = 1
    self._toastFrame = tf

    local lbl = Instance.new("TextLabel")
    lbl.Text = ""; lbl.Size = UDim2.new(1,-16,0,20)
    lbl.Position = UDim2.new(0,8,0,4)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(220,215,240)
    lbl.TextSize = 11; lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 201; lbl.Parent = tf
    self._toastLabel = lbl

    local tbt = Instance.new("Frame")
    tbt.Size = UDim2.new(1,-16,0,3); tbt.Position = UDim2.new(0,8,0,28)
    tbt.BackgroundColor3 = HexToColor("2A2A38"); tbt.BorderSizePixel = 0
    tbt.ZIndex = 201; tbt.Parent = tf
    Instance.new("UICorner", tbt).CornerRadius = UDim.new(0.5,0)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,0,1,0); bar.BackgroundColor3 = self:T("Accent")
    bar.BorderSizePixel = 0; bar.ZIndex = 202; bar.Parent = tbt
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0.5,0)
    self._toastBar = bar
end

function ReiduGUI:Toast(text, isEnabled)
    table.insert(self._toastQueue, {text=text, enabled=isEnabled})
    if self._toastRunning then return end
    self._toastRunning = true
    task.spawn(function()
        while #self._toastQueue > 0 do
            local item = table.remove(self._toastQueue, 1)
            local col, dot
            if item.enabled == true then
                col = Color3.fromRGB(120,220,120); dot = "[ON]  "
            elseif item.enabled == false then
                col = Color3.fromRGB(220,100,100); dot = "[OFF] "
            else
                col = self:T("Accent"); dot = "[ ]   "
            end
            self._toastLabel.Text = dot .. item.text
            self._toastLabel.TextColor3 = col
            self._toastStroke.Color = col
            self._toastBar.BackgroundColor3 = col
            self._toastBar.Size = UDim2.new(1,0,1,0)
            Tween(self._toastFrame,
                TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Position = UDim2.new(1,-10,1,-46)})
            task.wait(0.15)
            Tween(self._toastBar, TweenInfo.new(1.4, Enum.EasingStyle.Linear),
                {Size = UDim2.new(0,0,1,0)})
            task.wait(1.4)
            Tween(self._toastFrame,
                TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                {Position = UDim2.new(1,-10,1,60)})
            task.wait(0.15)
        end
        self._toastRunning = false
    end)
end

-- ============================================================
-- AMBIENT ANIMATIONS
-- ============================================================
function ReiduGUI:_BuildAmbient()
    task.spawn(function()
        local cols = {
            Color3.fromRGB(220,200,255), Color3.fromRGB(180,130,255),
            Color3.fromRGB(240,200,255), Color3.fromRGB(160,100,255),
        }
        local i = 1
        while self._titleLabel do
            task.wait(1.8)
            i = i%#cols + 1
            Tween(self._titleLabel, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {TextColor3 = cols[i]})
        end
    end)
    task.spawn(function()
        while self._badge do
            Tween(self._badge, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(200,100,255)})
            task.wait(0.6)
            Tween(self._badge, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(90,45,160)})
            task.wait(0.6)
        end
    end)
    task.spawn(function()
        local r = 0
        while self._accentGrad do
            task.wait(0.05)
            r = (r+1)%360
            self._accentGrad.Rotation = r
        end
    end)
end

-- ============================================================
-- LIVE STATUS BAR
-- ============================================================
function ReiduGUI:AddStatusLabel(default, order)
    self._liveLblIdx = (self._liveLblIdx or 0) + 1
    local lbl = Instance.new("TextLabel")
    lbl.Text = default or ""
    lbl.Size = UDim2.new(0,160,0,18)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(160,155,190)
    lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or self._liveLblIdx
    lbl.Parent = self._liveFrame
    return function(txt) lbl.Text = txt end
end

-- ============================================================
-- TAB
-- ============================================================
function ReiduGUI:AddTab(name, icon)
    local order = #self._tabs + 1
    icon = icon or "•"

    local btn = Instance.new("TextButton")
    btn.Text = icon .. "  " .. name
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.fromRGB(140,135,170)
    btn.TextSize = 11; btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0; btn.LayoutOrder = order
    btn.Parent = self._navFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    local bp = Instance.new("UIPadding", btn); bp.PaddingLeft = UDim.new(0,8)

    local acc = Instance.new("Frame")
    acc.Size = UDim2.new(0,3,0,0)
    acc.Position = UDim2.new(0,-6,0.15,0)
    acc.BackgroundColor3 = self:T("Accent")
    acc.BorderSizePixel = 0; acc.Visible = false; acc.Parent = btn
    Instance.new("UICorner", acc).CornerRadius = UDim.new(0,2)

    btn.MouseEnter:Connect(function()
        if btn.BackgroundTransparency > 0.5 then
            Tween(btn, fast, {TextColor3 = Color3.fromRGB(210,205,230)})
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundTransparency > 0.5 then
            Tween(btn, fast, {TextColor3 = Color3.fromRGB(140,135,170)})
        end
    end)

    local frame = Instance.new("ScrollingFrame")
    frame.Name = name
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 3
    frame.ScrollBarImageColor3 = self:T("Accent")
    frame.CanvasSize = UDim2.new(0,0,0,0)
    frame.Visible = false; frame.Parent = self._tabContainer
    local layout = Instance.new("UIListLayout", frame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 15)
    end)
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop = UDim.new(0,8); pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight = UDim.new(0,12)

    local tabObj = {name=name, frame=frame, btn=btn, acc=acc, _sectionCount=0}
    table.insert(self._tabs, tabObj)

    btn.MouseButton1Click:Connect(function()
        self._lastActiveTab = name
        self:_SwitchTab(name)
    end)

    if #self._tabs == 1 then
        self._lastActiveTab = name
        self:_SwitchTab(name)
    end

    return tabObj
end

function ReiduGUI:_SwitchTab(name)
    for _, t in ipairs(self._tabs) do
        local sel = (t.name == name)
        t.frame.Visible = sel
        if sel then
            Tween(t.btn, fast, {
                BackgroundTransparency = 0,
                BackgroundColor3 = self:T("Background"),
                TextColor3 = self:T("Accent"),
            })
            t.acc.Visible = true
            t.acc.Size = UDim2.new(0,3,0,0)
            Tween(t.acc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0,3,0.7,0)})
        else
            Tween(t.btn, fast, {
                BackgroundTransparency = 1,
                BackgroundColor3 = Color3.fromRGB(0,0,0),
                TextColor3 = Color3.fromRGB(140,135,170),
            })
            t.acc.Visible = false
        end
    end
end

-- ============================================================
-- SECTION
-- ============================================================
function ReiduGUI:AddSection(tab, title)
    tab._sectionCount = (tab._sectionCount or 0) + 1

    local section = Instance.new("Frame")
    section.Size = UDim2.new(1,0,0,28)
    section.BackgroundTransparency = 1
    section.LayoutOrder = tab._sectionCount * 100
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = tab.frame
    local sl = Instance.new("UIListLayout", section)
    sl.SortOrder = Enum.SortOrder.LayoutOrder
    sl.Padding = UDim.new(0,4)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,22)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 0; header.Parent = section
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,0.5,0)
    line.BackgroundColor3 = self:T("Outline"); line.BorderSizePixel = 0; line.Parent = header
    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Size = UDim2.new(0,0,1,0); lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.BackgroundColor3 = self:T("Background"); lbl.TextColor3 = self:T("Accent")
    lbl.TextSize = 10; lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BorderSizePixel = 0; lbl.Parent = header
    local hp = Instance.new("UIPadding", lbl)
    hp.PaddingLeft = UDim.new(0,4); hp.PaddingRight = UDim.new(0,4)

    section._rowCount = 0
    return section
end

local function NextRow(s)
    s._rowCount = (s._rowCount or 0) + 1
    return s._rowCount
end

function ReiduGUI:_Row(section, h)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,h or 30)
    row.BackgroundColor3 = self:T("Main")
    row.BorderSizePixel = 0
    row.LayoutOrder = NextRow(section)
    row.Parent = section
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)
    return row
end

-- ============================================================
-- TOGGLE
-- ============================================================
function ReiduGUI:AddToggle(section, label, default, callback)
    local row = self:_Row(section)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label; lbl.Size = UDim2.new(0.65,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200,195,220)
    lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local bg = Instance.new("TextButton")
    bg.Text = ""; bg.AutoButtonColor = false
    bg.Size = UDim2.new(0,36,0,18); bg.Position = UDim2.new(1,-46,0.5,-9)
    bg.BackgroundColor3 = self:T("Outline"); bg.BorderSizePixel = 0; bg.Parent = row
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0.5,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(160,155,185)
    knob.BorderSizePixel = 0; knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5,0)

    local value = default or false

    local function Refresh(v)
        Tween(bg, fast, {BackgroundColor3 = v and self:T("Accent") or self:T("Outline")})
        Tween(knob, quint, {
            Position = v and UDim2.new(0,20,0.5,-7) or UDim2.new(0,2,0.5,-7),
            BackgroundColor3 = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,155,185),
        })
    end
    Refresh(value)

    bg.MouseButton1Click:Connect(function()
        value = not value; Refresh(value)
        self:Toast(label, value)
        if callback then callback(value) end
    end)

    self:_RegisterFeature(label, section, row)

    return {
        Set = function(_, v) value = v; Refresh(v) end,
        Get = function(_)    return value end,
    }
end

-- ============================================================
-- SLIDER
-- ============================================================
function ReiduGUI:AddSlider(section, label, min, max, default, callback)
    local row = self:_Row(section, 46)
    row.Size = UDim2.new(1,0,0,46)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label; lbl.Size = UDim2.new(0.6,0,0,18)
    lbl.Position = UDim2.new(0,10,0,6); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200,195,220)
    lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Text = tostring(default); valLbl.Size = UDim2.new(0.35,-12,0,18)
    valLbl.Position = UDim2.new(0.65,0,0,6); valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = self:T("Accent")
    valLbl.TextSize = 11; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = row

    local track = Instance.new("TextButton")
    track.Text = ""; track.AutoButtonColor = false
    track.Size = UDim2.new(1,-20,0,4); track.Position = UDim2.new(0,10,0,32)
    track.BackgroundColor3 = self:T("Outline"); track.BorderSizePixel = 0; track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0.5,0)

    local rel0 = math.clamp((default - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(rel0,0,1,0); fill.BackgroundColor3 = self:T("Accent")
    fill.BorderSizePixel = 0; fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,12,0,12); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(rel0,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0; knob.ZIndex = 3; knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5,0)

    local value   = default
    local sliding = false
    local isFloat = (max - min) <= 10 or (math.floor(min) ~= min) or (math.floor(max) ~= max)

    local function ApplyX(px)
        local r = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + r*(max-min)
        v = isFloat and (math.floor(v*10)/10) or math.floor(v)
        value = v
        fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,0,0.5,0)
        valLbl.Text = tostring(v)
        if callback then callback(v) end
    end

    local function MB1(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
    local function Mv(i)  return i.UserInputType==Enum.UserInputType.MouseMovement  or i.UserInputType==Enum.UserInputType.Touch end
    track.InputBegan:Connect(function(i)  if MB1(i) then sliding=true; Tween(knob,TweenInfo.new(0.12),{Size=UDim2.new(0,16,0,16)}); ApplyX(i.Position.X) end end)
    track.InputEnded:Connect(function(i)  if MB1(i) then sliding=false; Tween(knob,TweenInfo.new(0.12),{Size=UDim2.new(0,12,0,12)}) end end)
    track.InputChanged:Connect(function(i) if sliding and Mv(i) then ApplyX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i)  if MB1(i) and sliding then sliding=false; Tween(knob,TweenInfo.new(0.12),{Size=UDim2.new(0,12,0,12)}) end end)
    UserInputService.InputChanged:Connect(function(i) if sliding and Mv(i) then ApplyX(i.Position.X) end end)

    self:_RegisterFeature(label, section, row)

    return {
        Set = function(_, v)
            value = v
            local r = math.clamp((v-min)/(max-min),0,1)
            fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,0,0.5,0)
            valLbl.Text = tostring(v)
        end,
        Get = function(_) return value end,
    }
end

-- ============================================================
-- DROPDOWN  (single select)
-- ============================================================
function ReiduGUI:AddDropdown(section, label, options, default, callback)
    local con = Instance.new("Frame")
    con.Size = UDim2.new(1,0,0,30); con.BackgroundColor3 = self:T("Main")
    con.BorderSizePixel = 0; con.LayoutOrder = NextRow(section)
    con.AutomaticSize = Enum.AutomaticSize.Y; con.Parent = section
    Instance.new("UICorner", con).CornerRadius = UDim.new(0,5)
    Instance.new("UIListLayout", con).SortOrder = Enum.SortOrder.LayoutOrder

    local hdr = Instance.new("TextButton")
    hdr.Size = UDim2.new(1,0,0,30); hdr.BackgroundTransparency = 1
    hdr.TextColor3 = Color3.fromRGB(200,195,220)
    hdr.TextSize = 11; hdr.Font = Enum.Font.Gotham
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.LayoutOrder = 0; hdr.Parent = con
    local hp = Instance.new("UIPadding", hdr); hp.PaddingLeft = UDim.new(0,10)

    local arrow = Instance.new("TextLabel")
    arrow.Text = "v"; arrow.Size = UDim2.new(0,20,1,0)
    arrow.Position = UDim2.new(1,-25,0,0); arrow.BackgroundTransparency = 1
    arrow.TextColor3 = self:T("Accent"); arrow.TextSize = 12
    arrow.Font = Enum.Font.GothamBold; arrow.Parent = hdr

    local dl = Instance.new("Frame")
    dl.BackgroundTransparency = 1; dl.Visible = false
    dl.LayoutOrder = 1; dl.AutomaticSize = Enum.AutomaticSize.Y
    dl.Size = UDim2.new(1,0,0,0); dl.Parent = con
    Instance.new("UIListLayout", dl).SortOrder = Enum.SortOrder.LayoutOrder

    local value = default or options[1]
    local function Refresh() hdr.Text = label .. ":  " .. tostring(value) end
    Refresh()

    local open = false
    hdr.MouseEnter:Connect(function() Tween(hdr,fast,{TextColor3=Color3.fromRGB(255,255,255)}) end)
    hdr.MouseLeave:Connect(function() Tween(hdr,fast,{TextColor3=Color3.fromRGB(200,195,220)}) end)

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1,0,0,26); ob.BackgroundColor3 = self:T("Background")
        ob.TextColor3 = opt==value and self:T("Accent") or Color3.fromRGB(170,165,195)
        ob.TextSize = 11; ob.Font = Enum.Font.Gotham
        ob.Text = "  "..opt; ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.BorderSizePixel = 0; ob.LayoutOrder = i; ob.Parent = dl
        ob.MouseButton1Click:Connect(function()
            value = opt; Refresh()
            dl.Visible = false; open = false; arrow.Text = "v"
            if callback then callback(opt) end
        end)
    end
    hdr.MouseButton1Click:Connect(function()
        open = not open; dl.Visible = open; arrow.Text = open and "^" or "v"
    end)

    self:_RegisterFeature(label, section, con)

    return {
        Set = function(_, v) value = v; Refresh() end,
        Get = function(_)    return value end,
    }
end

-- ============================================================
-- MULTI-DROPDOWN  (multi select)
-- ============================================================
function ReiduGUI:AddMultiDropdown(section, label, options, default, callback)
    local con = Instance.new("Frame")
    con.Size = UDim2.new(1,0,0,30); con.BackgroundColor3 = self:T("Main")
    con.BorderSizePixel = 0; con.LayoutOrder = NextRow(section)
    con.AutomaticSize = Enum.AutomaticSize.Y; con.Parent = section
    Instance.new("UICorner", con).CornerRadius = UDim.new(0,5)
    Instance.new("UIListLayout", con).SortOrder = Enum.SortOrder.LayoutOrder

    local hdr = Instance.new("TextButton")
    hdr.Size = UDim2.new(1,0,0,30); hdr.BackgroundTransparency = 1
    hdr.TextColor3 = Color3.fromRGB(200,195,220)
    hdr.TextSize = 11; hdr.Font = Enum.Font.Gotham
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.LayoutOrder = 0; hdr.Parent = con
    local hp = Instance.new("UIPadding", hdr); hp.PaddingLeft = UDim.new(0,10)

    local arrow = Instance.new("TextLabel")
    arrow.Text = "v"; arrow.Size = UDim2.new(0,20,1,0)
    arrow.Position = UDim2.new(1,-25,0,0); arrow.BackgroundTransparency = 1
    arrow.TextColor3 = self:T("Accent"); arrow.TextSize = 12
    arrow.Font = Enum.Font.GothamBold; arrow.Parent = hdr

    local dl = Instance.new("Frame")
    dl.BackgroundTransparency = 1; dl.Visible = false
    dl.LayoutOrder = 1; dl.AutomaticSize = Enum.AutomaticSize.Y
    dl.Size = UDim2.new(1,0,0,0); dl.Parent = con
    Instance.new("UIListLayout", dl).SortOrder = Enum.SortOrder.LayoutOrder

    local selected = {}
    if default then for _,v in ipairs(default) do selected[v]=true end end

    local optBtns = {}

    local function Refresh()
        local n = 0; for _ in pairs(selected) do n=n+1 end
        hdr.Text = label .. ":  " .. (n>0 and (n.." Selected") or "None")
    end
    Refresh()

    local open = false
    hdr.MouseEnter:Connect(function() Tween(hdr,fast,{TextColor3=Color3.fromRGB(255,255,255)}) end)
    hdr.MouseLeave:Connect(function() Tween(hdr,fast,{TextColor3=Color3.fromRGB(200,195,220)}) end)

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1,0,0,26); ob.BackgroundColor3 = self:T("Background")
        ob.TextColor3 = selected[opt] and self:T("Accent") or Color3.fromRGB(170,165,195)
        ob.TextSize = 11; ob.Font = Enum.Font.Gotham
        ob.Text = (selected[opt] and "[x]  " or "[ ]  ")..opt
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.BorderSizePixel = 0; ob.LayoutOrder = i; ob.Parent = dl
        optBtns[opt] = ob
        ob.MouseButton1Click:Connect(function()
            if selected[opt] then
                selected[opt] = nil
                ob.Text = "[ ]  "..opt; ob.TextColor3 = Color3.fromRGB(170,165,195)
            else
                selected[opt] = true
                ob.Text = "[x]  "..opt; ob.TextColor3 = self:T("Accent")
            end
            Refresh()
            if callback then
                local arr={}; for k in pairs(selected) do table.insert(arr,k) end
                callback(arr)
            end
        end)
    end
    hdr.MouseButton1Click:Connect(function()
        open = not open; dl.Visible = open; arrow.Text = open and "^" or "v"
    end)

    self:_RegisterFeature(label, section, con)

    return {
        Set = function(_, arr)
            selected = {}
            if arr then for _,v in ipairs(arr) do selected[v]=true end end
            for opt, ob in pairs(optBtns) do
                ob.Text = (selected[opt] and "[x]  " or "[ ]  ")..opt
                ob.TextColor3 = selected[opt] and self:T("Accent") or Color3.fromRGB(170,165,195)
            end
            Refresh()
        end,
        Get = function(_)
            local arr={}; for k in pairs(selected) do table.insert(arr,k) end
            return arr
        end,
    }
end

-- ============================================================
-- BUTTON
-- ============================================================
function ReiduGUI:AddButton(section, label, callback, color)
    local row = self:_Row(section)
    local btn = Instance.new("TextButton")
    btn.Text = label; btn.Size = UDim2.new(1,-20,0,22)
    btn.Position = UDim2.new(0,10,0.5,-11)
    btn.BackgroundColor3 = self:T("Main")
    btn.TextColor3 = color or Color3.fromRGB(220,215,240)
    btn.TextSize = 11; btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0; btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = self:T("Outline"); stroke.Thickness = 1
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    btn.MouseEnter:Connect(function() stroke.Color = self:T("Accent") end)
    btn.MouseLeave:Connect(function() stroke.Color = self:T("Outline") end)

    self:_RegisterFeature(label, section, row)
end

-- ============================================================
-- TEXT INPUT
-- ============================================================
function ReiduGUI:AddTextInput(section, label, placeholder, default, callback)
    local row = self:_Row(section, 46)
    row.Size = UDim2.new(1,0,0,46)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label; lbl.Size = UDim2.new(1,-10,0,18)
    lbl.Position = UDim2.new(0,10,0,4); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(160,155,185)
    lbl.TextSize = 10; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local box = Instance.new("TextBox")
    box.PlaceholderText = placeholder or ""; box.Text = default or ""
    box.Size = UDim2.new(1,-20,0,20); box.Position = UDim2.new(0,10,0,22)
    box.BackgroundColor3 = self:T("Background")
    box.TextColor3 = Color3.fromRGB(210,205,235)
    box.PlaceholderColor3 = Color3.fromRGB(100,95,125)
    box.TextSize = 11; box.Font = Enum.Font.Gotham
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.BorderSizePixel = 0; box.ClearTextOnFocus = false; box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)
    local ip = Instance.new("UIPadding", box); ip.PaddingLeft = UDim.new(0,6)
    box.FocusLost:Connect(function() if callback then callback(box.Text) end end)

    self:_RegisterFeature(label, section, row)

    return {
        Set = function(_, v) box.Text = v or "" end,
        Get = function(_)    return box.Text end,
    }
end

-- ============================================================
-- COLOR PICKER ROW  (new in v1.1)
-- ============================================================
-- Creates a row with a colour swatch and label.
-- Clicking the swatch opens the shared HSV picker popup.
-- callback(hex) fires when Apply is pressed.
-- Returns controller: { Set(hex), Get() -> hex }
function ReiduGUI:AddColorPicker(section, label, defaultHex, callback)
    defaultHex = (defaultHex or "7C5CBF"):gsub("#","")
    local currentHex = defaultHex

    local row = self:_Row(section)

    local lbl = Instance.new("TextLabel")
    lbl.Text = label; lbl.Size = UDim2.new(0.55,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200,195,220)
    lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    -- Hex label
    local hexLbl = Instance.new("TextLabel")
    hexLbl.Text = "#"..currentHex
    hexLbl.Size = UDim2.new(0.28,0,0,18)
    hexLbl.Position = UDim2.new(0.55,0,0.5,-9)
    hexLbl.BackgroundTransparency = 1
    hexLbl.TextColor3 = Color3.fromRGB(140,130,170)
    hexLbl.TextSize = 10; hexLbl.Font = Enum.Font.Code
    hexLbl.TextXAlignment = Enum.TextXAlignment.Left; hexLbl.Parent = row

    -- Swatch button
    local swatch = Instance.new("TextButton")
    swatch.Text = ""; swatch.AutoButtonColor = false
    swatch.Size = UDim2.new(0,22,0,22)
    swatch.Position = UDim2.new(1,-32,0.5,-11)
    swatch.BackgroundColor3 = HexToColor(currentHex)
    swatch.BorderSizePixel = 0; swatch.Parent = row
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0.5,0)
    local swStroke = Instance.new("UIStroke", swatch)
    swStroke.Color = Color3.fromRGB(100,80,150); swStroke.Thickness = 1

    swatch.MouseEnter:Connect(function()
        Tween(swStroke, TweenInfo.new(0.15), {Color=self:T("Accent"), Thickness=2})
    end)
    swatch.MouseLeave:Connect(function()
        Tween(swStroke, TweenInfo.new(0.15), {Color=Color3.fromRGB(100,80,150), Thickness=1})
    end)

    swatch.MouseButton1Click:Connect(function()
        self:_OpenColorPicker(
            "Color: " .. label,
            currentHex,
            function(col, hex) -- applyFn
                currentHex = hex
                swatch.BackgroundColor3 = col
                hexLbl.Text = "#"..hex
            end,
            callback
        )
    end)

    self:_RegisterFeature(label, section, row)

    return {
        Set = function(_, hex)
            hex = hex:gsub("#","")
            currentHex = hex
            swatch.BackgroundColor3 = HexToColor(hex)
            hexLbl.Text = "#"..hex
        end,
        Get = function(_) return currentHex end,
    }
end

-- ============================================================
-- LABEL
-- ============================================================
function ReiduGUI:AddLabel(section, text, color)
    local row = self:_Row(section)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text or ""; lbl.Size = UDim2.new(1,-20,1,0)
    lbl.Position = UDim2.new(0,10,0,0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(160,155,185)
    lbl.TextSize = 10; lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true; lbl.Parent = row
    return {
        Set      = function(_, v)  lbl.Text = v end,
        SetColor = function(_, c) lbl.TextColor3 = c end,
    }
end

-- ============================================================
-- SEPARATOR
-- ============================================================
function ReiduGUI:AddSeparator(section)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,1)
    row.BackgroundColor3 = self:T("Outline")
    row.BorderSizePixel = 0
    row.LayoutOrder = NextRow(section)
    row.Parent = section
end

-- ============================================================
-- THEME
-- ============================================================
function ReiduGUI:SetTheme(key, hex)
    self._theme[key] = hex:gsub("#","")
end

-- ============================================================
-- RETURN
-- ============================================================
return ReiduGUI

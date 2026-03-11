warn("[reidu] SCRIPT START - LINE 1")
local KEY_SERVER  = "https://reidu-key-server.onrender.com"
local KEY_FILE    = "reidu_session.json"
local TweenService = game:GetService("TweenService")
local LocalPlayer  = game:GetService("Players").LocalPlayer
local UserId       = tostring(LocalPlayer.UserId)
local HttpService  = game:GetService("HttpService")

local httprequest = (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request

local function LoadSession()
    local ok, raw = pcall(readfile, KEY_FILE)
    if not ok then return nil end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok2 or not data then return nil end
    if data.userId == UserId and os.time() * 1000 < data.expiresAt then
        return data
    end
    return nil
end

local function SaveSession(key, expiresAt)
    pcall(writefile, KEY_FILE, HttpService:JSONEncode({
        key = key, userId = UserId, expiresAt = expiresAt
    }))
end

local function ClearSession()
    pcall(delfile, KEY_FILE)
end

local function VerifyWithServer(key)
    if not httprequest then return false, "No httprequest" end
    local ok, resp = pcall(function()
        return httprequest({
            Url     = KEY_SERVER .. "/verify",
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode({ key = key, userId = UserId })
        })
    end)
    if not ok then return false, "Server unreachable" end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(resp.Body)
    end)
    if not ok2 then return false, "Bad response" end
    return data.valid == true, data.reason, data.expiresAt
end

local function ShowKeyGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ReiduKey"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 99999
    local guiParented = false
    pcall(function()
        gui.Parent = game:GetService("CoreGui")
        guiParented = true
    end)
    if not guiParented then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel = 0
    overlay.Parent = gui

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 360, 0, 220)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.6, 0)
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    card.BorderSizePixel = 0
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(100, 60, 180)
    stroke.Thickness = 1.5

    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()

    local function MakeLabel(text, yPos, size, color, font)
        local l = Instance.new("TextLabel")
        l.Text = text
        l.Size = UDim2.new(1, -20, 0, size or 20)
        l.Position = UDim2.new(0, 10, 0, yPos)
        l.BackgroundTransparency = 1
        l.TextColor3 = color or Color3.fromRGB(200, 195, 220)
        l.TextSize = size or 12
        l.Font = font or Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Center
        l.TextWrapped = true
        l.Parent = card
        return l
    end

    MakeLabel("reidu's scripts — Enter Key", 14, 14, Color3.fromRGB(200, 170, 255), Enum.Font.GothamBold)

    local sub = MakeLabel(
        "Run !getkey " .. UserId .. " in the Discord to get your key.",
        36, 10, Color3.fromRGB(100, 95, 130)
    )
    sub.Size = UDim2.new(1, -20, 0, 28)

    -- Copyable ID box
    local idBox = Instance.new("TextBox")
    idBox.Text = UserId
    idBox.Size = UDim2.new(1, -30, 0, 26)
    idBox.Position = UDim2.new(0, 15, 0, 68)
    idBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    idBox.TextColor3 = Color3.fromRGB(180, 140, 255)
    idBox.TextSize = 11
    idBox.Font = Enum.Font.Code
    idBox.TextXAlignment = Enum.TextXAlignment.Center
    idBox.BorderSizePixel = 0
    idBox.TextEditable = false
    idBox.Parent = card
    Instance.new("UICorner", idBox).CornerRadius = UDim.new(0, 6)
    local idLabel = Instance.new("TextLabel")
    idLabel.Text = "Your Roblox ID (click to copy)"
    idLabel.Size = UDim2.new(1, -20, 0, 12)
    idLabel.Position = UDim2.new(0, 10, 0, 57)
    idLabel.BackgroundTransparency = 1
    idLabel.TextColor3 = Color3.fromRGB(70, 65, 95)
    idLabel.TextSize = 9
    idLabel.Font = Enum.Font.Gotham
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.Parent = card

    local box = Instance.new("TextBox")
    box.PlaceholderText = "Paste your key here..."
    box.Size = UDim2.new(1, -30, 0, 32)
    box.Position = UDim2.new(0, 15, 0, 106)
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    box.TextColor3 = Color3.fromRGB(220, 215, 240)
    box.PlaceholderColor3 = Color3.fromRGB(90, 85, 115)
    box.TextSize = 11
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = card
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    local bp = Instance.new("UIPadding", box)
    bp.PaddingLeft = UDim.new(0, 8)
    local bStroke = Instance.new("UIStroke", box)
    bStroke.Color = Color3.fromRGB(55, 45, 90)
    bStroke.Thickness = 1
    box.Focused:Connect(function()
        TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(120, 70, 220)}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(55, 45, 90)}):Play()
    end)

    local status = MakeLabel("", 146, 10, Color3.fromRGB(220, 100, 100))
    status.Size = UDim2.new(1, -20, 0, 16)

    local btn = Instance.new("TextButton")
    btn.Text = "Verify Key"
    btn.Size = UDim2.new(1, -30, 0, 34)
    btn.Position = UDim2.new(0, 15, 0, 168)
    btn.BackgroundColor3 = Color3.fromRGB(100, 55, 185)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(130, 75, 220)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 55, 185)}):Play()
    end)

    getgenv()._reiduVerified = false

    local function SetStatus(text, color, loading)
        status.Text = text
        status.TextColor3 = color or Color3.fromRGB(220, 100, 100)
        btn.Text = loading and "Verifying..." or "Verify Key"
        btn.BackgroundColor3 = loading
            and Color3.fromRGB(55, 45, 90)
            or Color3.fromRGB(100, 55, 185)
        btn.Active = not loading
    end

    local function Shake()
        for _ = 1, 3 do
            TweenService:Create(card, TweenInfo.new(0.05), {Position = UDim2.new(0.5, 7, 0.5, 0)}):Play()
            task.wait(0.05)
            TweenService:Create(card, TweenInfo.new(0.05), {Position = UDim2.new(0.5, -7, 0.5, 0)}):Play()
            task.wait(0.05)
        end
        TweenService:Create(card, TweenInfo.new(0.05), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    end

    btn.MouseButton1Click:Connect(function()
        local key = box.Text:match("^%s*(.-)%s*$")
        if key == "" then
            SetStatus("❌ Paste your key first.", Color3.fromRGB(220, 100, 100))
            Shake()
            return
        end

        SetStatus("⏳ Checking...", Color3.fromRGB(200, 180, 100), true)

        task.spawn(function()
            local valid, reason, expiresAt = VerifyWithServer(key)

            if valid then
                SaveSession(key, expiresAt)
                SetStatus("✅ Accepted! Loading...", Color3.fromRGB(120, 220, 120), false)
                TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(80, 200, 80)}):Play()
                task.wait(0.8)
                TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(0.5, 0, 0.4, 0)
                }):Play()
                task.wait(0.3)
                gui:Destroy()
                getgenv()._reiduVerified = true
            else
                ClearSession()
                local msg = "❌ " .. (reason or "Invalid key.")
                if reason and reason:find("expired")     then msg = "⏰ Key expired. Run !getkey again." end
                if reason and reason:find("used")        then msg = "🔒 Key already used. Run !getkey for a new one." end
                if reason and reason:find("not registered") then msg = "🚫 This key is for a different account." end
                SetStatus(msg, Color3.fromRGB(220, 100, 100), false)
                Shake()
            end
        end)
    end)

    return function() return getgenv()._reiduVerified == true end
end

-- ── Auth flow ─────────────────────────────────────────────────
warn("[reidu] auth block reached")
local session = LoadSession()
warn("[reidu] session result: " .. tostring(session))
if not session then
    warn("[reidu] no session - showing key gui")
    getgenv()._reiduVerified = false
    local IsVerified = ShowKeyGui()
    warn("[reidu] gui shown - waiting for verify...")
    repeat task.wait(0.1) until getgenv()._reiduVerified == true
    warn("[reidu] verified! continuing...")
else
    local h = math.floor(((session.expiresAt / 1000) - os.time()) / 3600)
    warn(string.format("[reidu] session valid — expires in ~%dh", h))
end
warn("[reidu] auth done - loading script")
-- ── Rest of your script below ─────────────────────────────────



getgenv().ReiduScriptSource = [[loadstring(game:HttpGet("https://pastefy.app/d9w18U4l/raw"))()]]

print("[reidu's scripts] VERSION 8.1 LOADED")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- LOADING SCREEN
-- ============================================================
local LoadGui, LoadOverlay, LoadCard, cardStroke, LoadScan
local LoadTitle, LoadSub, LoadTrack, LoadFill, LoadGrad, LoadVersion

do
    LoadGui = Instance.new("ScreenGui")
    LoadGui.Name = "ReiduLoader"
    LoadGui.ResetOnSpawn = false
    LoadGui.DisplayOrder = 9999
    LoadGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() LoadGui.Parent = game:GetService("CoreGui") end)

    LoadOverlay = Instance.new("Frame")
    LoadOverlay.Size = UDim2.new(1, 0, 1, 0)
    LoadOverlay.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    LoadOverlay.BackgroundTransparency = 1
    LoadOverlay.BorderSizePixel = 0
    LoadOverlay.ZIndex = 1
    LoadOverlay.Parent = LoadGui

    LoadCard = Instance.new("Frame")
    LoadCard.Size = UDim2.new(0, 320, 0, 140)
    LoadCard.AnchorPoint = Vector2.new(0.5, 0.5)
    LoadCard.Position = UDim2.new(0.5, 0, 0.5, 0)
    LoadCard.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    LoadCard.BorderSizePixel = 0
    LoadCard.ZIndex = 2
    LoadCard.Parent = LoadGui
    Instance.new("UICorner", LoadCard).CornerRadius = UDim.new(0, 12)
    cardStroke = Instance.new("UIStroke", LoadCard)
    cardStroke.Color = Color3.fromRGB(100, 60, 180)
    cardStroke.Thickness = 1

    LoadScan = Instance.new("Frame")
    LoadScan.Size = UDim2.new(1, 0, 1, 0)
    LoadScan.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
    LoadScan.BackgroundTransparency = 0.95
    LoadScan.BorderSizePixel = 0
    LoadScan.ZIndex = 3
    LoadScan.Parent = LoadCard
    Instance.new("UICorner", LoadScan).CornerRadius = UDim.new(0, 12)

    LoadTitle = Instance.new("TextLabel")
    LoadTitle.Text = "reidu's scripts"
    LoadTitle.Size = UDim2.new(1, -20, 0, 40)
    LoadTitle.Position = UDim2.new(0, 10, 0, 16)
    LoadTitle.BackgroundTransparency = 1
    LoadTitle.TextColor3 = Color3.fromRGB(200, 170, 255)
    LoadTitle.TextSize = 22
    LoadTitle.Font = Enum.Font.GothamBold
    LoadTitle.ZIndex = 4
    LoadTitle.TextXAlignment = Enum.TextXAlignment.Center
    LoadTitle.Parent = LoadCard

    LoadSub = Instance.new("TextLabel")
    LoadSub.Text = "initializing..."
    LoadSub.Size = UDim2.new(1, -20, 0, 18)
    LoadSub.Position = UDim2.new(0, 10, 0, 54)
    LoadSub.BackgroundTransparency = 1
    LoadSub.TextColor3 = Color3.fromRGB(100, 85, 140)
    LoadSub.TextSize = 11
    LoadSub.Font = Enum.Font.Gotham
    LoadSub.ZIndex = 4
    LoadSub.TextXAlignment = Enum.TextXAlignment.Center
    LoadSub.Parent = LoadCard

    LoadTrack = Instance.new("Frame")
    LoadTrack.Size = UDim2.new(1, -40, 0, 4)
    LoadTrack.Position = UDim2.new(0, 20, 0, 88)
    LoadTrack.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
    LoadTrack.BorderSizePixel = 0
    LoadTrack.ZIndex = 4
    LoadTrack.Parent = LoadCard
    Instance.new("UICorner", LoadTrack).CornerRadius = UDim.new(0.5, 0)

    LoadFill = Instance.new("Frame")
    LoadFill.Size = UDim2.new(0, 0, 1, 0)
    LoadFill.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    LoadFill.BorderSizePixel = 0
    LoadFill.ZIndex = 5
    LoadFill.Parent = LoadTrack
    Instance.new("UICorner", LoadFill).CornerRadius = UDim.new(0.5, 0)

    LoadGrad = Instance.new("UIGradient", LoadFill)
    LoadGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 50, 220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 130, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 50, 220)),
    })

    LoadVersion = Instance.new("TextLabel")
    LoadVersion.Text = "v8.2"
    LoadVersion.Size = UDim2.new(1, -20, 0, 16)
    LoadVersion.Position = UDim2.new(0, 10, 0, 108)
    LoadVersion.BackgroundTransparency = 1
    LoadVersion.TextColor3 = Color3.fromRGB(55, 45, 85)
    LoadVersion.TextSize = 10
    LoadVersion.Font = Enum.Font.Gotham
    LoadVersion.ZIndex = 4
    LoadVersion.TextXAlignment = Enum.TextXAlignment.Center
    LoadVersion.Parent = LoadCard

    LoadCard.BackgroundTransparency = 1
    TweenService:Create(LoadCard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()

    task.spawn(function()
        local colors = {
            Color3.fromRGB(200, 170, 255),
            Color3.fromRGB(160, 100, 255),
            Color3.fromRGB(220, 190, 255),
        }
        local i = 1
        while LoadGui.Parent do
            i = i % #colors + 1
            TweenService:Create(LoadTitle, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {TextColor3 = colors[i]}):Play()
            task.wait(1.2)
        end
    end)

    task.spawn(function()
        local rot = 0
        while LoadGui.Parent do
            task.wait(0.05)
            rot = (rot + 1) % 360
            LoadGrad.Rotation = rot
        end
    end)
end

local function SetLoadProgress(pct, label)
    TweenService:Create(LoadFill, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
        Size = UDim2.new(pct, 0, 1, 0)
    }):Play()
    if label then LoadSub.Text = label end
end

local MainFrame  -- forward declared so DismissLoader can reference it

local function DismissLoader()
    task.delay(0.3, function() MainFrame.Visible = true end)
    TweenService:Create(LoadCard, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.45, 0)
    }):Play()
    TweenService:Create(LoadTitle, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(LoadSub, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(LoadVersion, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(LoadFill, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadTrack, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(cardStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
    TweenService:Create(LoadOverlay, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
    task.delay(0.7, function() LoadGui:Destroy() end)
end

task.delay(30, function()
    if MainFrame and not MainFrame.Visible then
        warn("[reidu] Failsafe triggered - DismissLoader stalled")
        MainFrame.Visible = true
        pcall(function() LoadGui:Destroy() end)
    end
end)

local TestWebhook
local ShowToast

local State = {
    WalkSpeed = 16, TeleportSpeed = 5, FlySpeed = 100,
    InfiniteJump = false, Noclip = false, Flying = false,
    AutoCollectCoins = false, CollectDelay = 1.0, EquipBestDelay = 15,
    WeatherFilter = "Any", BestDice = false, WorstDiceFilter = false, WorstDiceList = {},
    IsRolling = false, AutoEquipPotions = false, AutoRollMoneyPotion = false,
    AutoEquipBest = false, AutoTimeReward = false, AutoQuests = false, AutoIndex = false,
    AutoBuyDice = false, AutoBuyPotion = false,
    DicePurchaseDelay = 1.0, PotionPurchaseDelay = 1.0,
    SuppressAutoSell = false,
    SelectedDice = {}, SelectedPotion = {}, 
    AlwaysBuyMax = false, AutoMerchant = false, 
    AutoHopForNullity = false, HopDelay = 8,
    AutoBuyRareBox = false,
    AutoBuyBasicBox = false,
    NukeCutscenes = false,
    HatchDelay = 1.0, ExecutionMultiplier = 1,
    ActiveBuffCheck = true, PotionWeather = "Any",
    AutoUpgrade = false, UpgradeTargets = {},
    AutoRebirth = false,
    AutoRoll = false, RollDelay = 1.0,
    AutoDiceOnWeather = false,
    AutoSpin = false,
    GlobalWeatherFilter = {},
    AutoHatch = false, Hatch3x = false, SelectedEgg = "CatEgg",
    WebhookURL = "", UserID = "", WebhookRarities = {},
    StaffDetection = false, AntiAFK = false, AutoRejoin = false,
    Theme = { Background = "0D0D0F", Main = "141418", Accent = "7C5CBF", Outline = "2A2A35" },
    CoinsPerSecond = 0, SpinTimeRemaining = 0, CurrentCoins = 0,
}

-- Registry of UI refresh callbacks, called after any config load
local UIRefreshCallbacks = {}
local function RegisterRefresh(fn) table.insert(UIRefreshCallbacks, fn) end
local function RefreshAllUI()
    for _, fn in ipairs(UIRefreshCallbacks) do pcall(fn) end
end

SetLoadProgress(0.2, "building interface...")
task.wait(0.6)

-- ============================================================
-- AUTO-REJOIN
-- ============================================================
task.spawn(function()
    local TeleportService = game:GetService("TeleportService")

    local function DoRejoin()
        local queue = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
        if queue and getgenv().ReiduScriptSource then
            queue(getgenv().ReiduScriptSource)
        end
        
        local ok, Stats = pcall(function()
            local Http = game:GetService("HttpService")
            return Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        
        if ok and Stats and Stats.data then
            for _, server in pairs(Stats.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end

    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" and State.AutoRejoin then
            task.wait(2)
            DoRejoin()
        end
    end)

    local oldKick
    pcall(function()
        oldKick = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if self == LocalPlayer and method:lower() == "kick" and State.AutoRejoin then
                warn("[reidu's scripts] Intercepted kick request. Rejoining...")
                DoRejoin()
                return
            end
            return oldKick(self, ...)
        end)
    end)
end)

-- ============================================================
-- THEME / GUI HELPERS
-- ============================================================
local function HexToColor(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1,2), 16) or 0,
        tonumber(hex:sub(3,4), 16) or 0,
        tonumber(hex:sub(5,6), 16) or 0
    )
end
local function GetTheme(key) return HexToColor(State.Theme[key]) end

-- ============================================================
-- MAIN GUI FRAME
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "reidu's scripts"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
local guiParent = (ok and coreGui) or LocalPlayer:WaitForChild("PlayerGui")
pcall(function() ScreenGui.Parent = guiParent end)
ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then pcall(function() ScreenGui.Parent = guiParent end) end
end)

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 580, 0, 520)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = GetTheme("Background")
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = GetTheme("Outline")
MainStroke.Thickness = 1

-- ============================================================
-- TITLE BAR
-- ============================================================
local TitleBar, TitleFix, accentLine, accentGrad, badge, TitleLabel, dateTag, NavFrame
local TabContainer, LiveDataFrame

do
    TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 36)
    TitleBar.BackgroundColor3 = GetTheme("Main")
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
    TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 8)
    TitleFix.Position = UDim2.new(0, 0, 1, -8)
    TitleFix.BackgroundColor3 = GetTheme("Main")
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar

    local function MakePixelCorner(parent, xScale, yScale, xOffset, yOffset)
        local px = Instance.new("Frame")
        px.Size = UDim2.new(0, 6, 0, 6)
        px.Position = UDim2.new(xScale, xOffset, yScale, yOffset)
        px.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
        px.BorderSizePixel = 0
        px.ZIndex = 10
        px.Parent = parent
        return px
    end
    MakePixelCorner(MainFrame, 0, 0, 2, 2)
    MakePixelCorner(MainFrame, 1, 0, -8, 2)
    MakePixelCorner(MainFrame, 0, 1, 2, -8)
    MakePixelCorner(MainFrame, 1, 1, -8, -8)

    local scanline = Instance.new("Frame")
    scanline.Size = UDim2.new(1, 0, 1, 0)
    scanline.BackgroundTransparency = 0.97
    scanline.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    scanline.BorderSizePixel = 0
    scanline.ZIndex = 0
    scanline.Parent = MainFrame

    accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 1)
    accentLine.Position = UDim2.new(0, 0, 1, 0)
    accentLine.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    accentLine.BorderSizePixel = 0
    accentLine.Parent = TitleBar
    accentGrad = Instance.new("UIGradient", accentLine)
    accentGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 40, 160)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 40, 160)),
    })

    badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 18, 0, 18)
    badge.Position = UDim2.new(0, 10, 0.5, -9)
    badge.BackgroundColor3 = Color3.fromRGB(130, 70, 220)
    badge.BorderSizePixel = 0
    badge.Parent = TitleBar
    local badgeInner = Instance.new("Frame")
    badgeInner.Size = UDim2.new(0, 8, 0, 8)
    badgeInner.Position = UDim2.new(0.5, -4, 0.5, -4)
    badgeInner.BackgroundColor3 = Color3.fromRGB(220, 180, 255)
    badgeInner.BorderSizePixel = 0
    badgeInner.Parent = badge

    TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = "reidu's scripts"
    TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    TitleLabel.Position = UDim2.new(0, 34, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(220, 200, 255)
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    dateTag = Instance.new("TextLabel")
    dateTag.Size = UDim2.new(0, 0, 0, 14)
    dateTag.AutomaticSize = Enum.AutomaticSize.X
    dateTag.Position = UDim2.new(0, 34 + 115, 0.5, -7)
    dateTag.BackgroundColor3 = Color3.fromRGB(60, 35, 110)
    dateTag.TextColor3 = Color3.fromRGB(190, 160, 255)
    dateTag.TextSize = 9
    dateTag.Font = Enum.Font.GothamBold
    dateTag.BorderSizePixel = 0
    dateTag.Parent = TitleBar
    Instance.new("UICorner", dateTag).CornerRadius = UDim.new(0, 3)
    local datePad = Instance.new("UIPadding", dateTag)
    datePad.PaddingLeft = UDim.new(0, 5)
    datePad.PaddingRight = UDim.new(0, 5)

    local function UpdateClock()
        local d = os.date("*t")
        dateTag.Text = string.format("%02d/%02d/%04d - %02d:%02d:%02d  %s",
            d.day, d.month, d.year, d.hour, d.min, d.sec, LocalPlayer.Name)
    end
    UpdateClock()
    task.spawn(function()
        while true do task.wait(1) UpdateClock() end
    end)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "X"
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -32, 0, 4)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
    CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
    CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 80, 80)}):Play() end)
    CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 60, 60)}):Play() end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Text = "-"
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -64, 0, 4)
    MinBtn.BackgroundColor3 = GetTheme("Outline")
    MinBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    MinBtn.TextSize = 14
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TitleBar
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)
    MinBtn.MouseEnter:Connect(function() TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 80, 95)}):Play() end)
    MinBtn.MouseLeave:Connect(function() TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = GetTheme("Outline")}):Play() end)

    local DragButton = Instance.new("TextButton")
    DragButton.Size = UDim2.new(1, -80, 1, 0)
    DragButton.BackgroundTransparency = 1
    DragButton.Text = ""
    DragButton.ZIndex = 5
    DragButton.Parent = TitleBar

    local dragging = false
    local dragStartPos = nil
    local dragFrameStart = nil

    local function BeginDrag(pos)
        dragging = true
        dragStartPos = pos
        dragFrameStart = MainFrame.Position
    end
    local function UpdateDrag(pos)
        if not dragging or not dragStartPos then return end
        local dx = pos.X - dragStartPos.X
        local dy = pos.Y - dragStartPos.Y
        MainFrame.Position = UDim2.new(
            dragFrameStart.X.Scale, dragFrameStart.X.Offset + dx,
            dragFrameStart.Y.Scale, dragFrameStart.Y.Offset + dy
        )
    end
    local function EndDrag() dragging = false end

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            UpdateDrag(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            EndDrag()
        end
    end)

    local function HookDragSource(frame)
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                BeginDrag(input.Position)
            end
        end)
    end

    NavFrame = Instance.new("Frame")
    NavFrame.Size = UDim2.new(0, 110, 0, 452)
    NavFrame.Position = UDim2.new(0, 0, 0, 40)
    NavFrame.BackgroundColor3 = GetTheme("Main")
    NavFrame.BorderSizePixel = 0
    NavFrame.Parent = MainFrame
    local NavLayout = Instance.new("UIListLayout", NavFrame)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Padding = UDim.new(0, 2)
    local NavPad = Instance.new("UIPadding", NavFrame)
    NavPad.PaddingTop = UDim.new(0, 8)
    NavPad.PaddingLeft = UDim.new(0, 6)
    NavPad.PaddingRight = UDim.new(0, 6)

    TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 462, 0, 420)
    TabContainer.Position = UDim2.new(0, 114, 0, 72)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame

    LiveDataFrame = Instance.new("Frame")
    LiveDataFrame.Size = UDim2.new(1, 0, 0, 28)
    LiveDataFrame.Position = UDim2.new(0, 0, 1, -28)
    LiveDataFrame.BackgroundColor3 = GetTheme("Main")
    LiveDataFrame.BorderSizePixel = 0
    LiveDataFrame.Parent = MainFrame
    local LiveLayout = Instance.new("UIListLayout", LiveDataFrame)
    LiveLayout.FillDirection = Enum.FillDirection.Horizontal
    LiveLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LiveLayout.Padding = UDim.new(0, 16)
    local LivePad = Instance.new("UIPadding", LiveDataFrame)
    LivePad.PaddingLeft = UDim.new(0, 12)
    LivePad.PaddingTop = UDim.new(0, 6)

    HookDragSource(DragButton)
    HookDragSource(NavFrame)
    HookDragSource(LiveDataFrame)

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)
    -- Avatar in bottom-left nav corner
    task.spawn(function()
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Size = UDim2.new(0, 46, 0, 46)
        avatarFrame.Position = UDim2.new(0, 32, 1, -72)
        avatarFrame.BackgroundColor3 = GetTheme("Main")
        avatarFrame.BorderSizePixel = 0
        avatarFrame.ZIndex = 6
        avatarFrame.Parent = MainFrame
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(0.5, 0)
        local avatarStroke = Instance.new("UIStroke", avatarFrame)
        avatarStroke.Color = GetTheme("Accent")
        avatarStroke.Thickness = 1.5

        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Size = UDim2.new(1, 0, 1, 0)
        avatarImg.BackgroundTransparency = 1
        avatarImg.BorderSizePixel = 0
        avatarImg.ZIndex = 7
        avatarImg.Parent = avatarFrame
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(0.5, 0)

        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)
        if ok and img then avatarImg.Image = img end
    end)
end

-- ============================================================
-- LIVE DATA LABELS
-- ============================================================
local FuseLabel, SpinLabel, CoinsCurrentLabel, BestDiceLabel

do
    local function MakeLiveLabel(text, order)
        local lbl = Instance.new("TextLabel")
        lbl.Text = text
        lbl.Size = UDim2.new(0, 160, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(160, 155, 190)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = order
        lbl.Parent = LiveDataFrame
        return lbl
    end
    FuseLabel = MakeLiveLabel("Fuse: No", 1)
    SpinLabel = MakeLiveLabel("Spin: --:--", 2)
    CoinsCurrentLabel = MakeLiveLabel("Coins: 0", 3)
    BestDiceLabel = MakeLiveLabel("Dice: --", 4)
end

-- ============================================================
-- NAV + TAB SYSTEM
-- ============================================================
local tabFrames, navBtns, navAccents = {}, {}, {}

local lastActiveTab = "Player"
local FeatureRegistry = {}

local function MakeNavButton(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Text = icon .. "  " .. name
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.fromRGB(140, 135, 170)
    btn.TextSize = 11
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = NavFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local p = Instance.new("UIPadding", btn)
    p.PaddingLeft = UDim.new(0, 8)
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 0)
    accent.Position = UDim2.new(0, -6, 0.15, 0)
    accent.BackgroundColor3 = GetTheme("Accent")
    accent.BorderSizePixel = 0
    accent.Visible = false
    accent.Parent = btn
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)
    btn.MouseEnter:Connect(function()
        if btn.BackgroundTransparency > 0.5 then
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(210, 205, 230)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundTransparency > 0.5 then
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(140, 135, 170)}):Play()
        end
    end)
    return btn, accent
end

local function MakeTabFrame(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = name
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 3
    frame.ScrollBarImageColor3 = GetTheme("Accent")
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.Visible = false
    frame.Parent = TabContainer
    local layout = Instance.new("UIListLayout", frame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
    end)
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 12)
    return frame
end

local function MakeSection(parent, title, order)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = parent
    local sl = Instance.new("UIListLayout", section)
    sl.SortOrder = Enum.SortOrder.LayoutOrder
    sl.Padding = UDim.new(0, 4)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 0
    header.Parent = section
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = GetTheme("Outline")
    line.BorderSizePixel = 0
    line.Parent = header
    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.BackgroundColor3 = GetTheme("Background")
    lbl.TextColor3 = GetTheme("Accent")
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BorderSizePixel = 0
    lbl.Parent = header
    local hp = Instance.new("UIPadding", lbl)
    hp.PaddingLeft = UDim.new(0, 4)
    hp.PaddingRight = UDim.new(0, 4)
    return section
end

local function MakeRow(parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = GetTheme("Main")
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    return row
end

local function MakeToggle(parent, labelText, stateKey, order, callback)
    local row = MakeRow(parent, order)
    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 195, 220)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local toggleBg = Instance.new("TextButton")
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.Size = UDim2.new(0, 36, 0, 18)
    toggleBg.Position = UDim2.new(1, -46, 0.5, -9)
    toggleBg.BackgroundColor3 = GetTheme("Outline")
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(0.5, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(160, 155, 185)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5, 0)
    local function UpdateVisual(val)
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = val and GetTheme("Accent") or GetTheme("Outline")}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = val and UDim2.new(0, 20, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = val and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,155,185)
        }):Play()
    end
    UpdateVisual(State[stateKey])
    RegisterRefresh(function() UpdateVisual(State[stateKey]) end)
    toggleBg.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        UpdateVisual(State[stateKey])
        if ShowToast then ShowToast(labelText, State[stateKey]) end
        if callback then callback(State[stateKey]) end
    end)
    pcall(function()
        local tabName = "Unknown"
        local p = parent and parent.Parent
        if p then for n, f in pairs(tabFrames) do if p == f then tabName = n break end end end
        table.insert(FeatureRegistry, {label = labelText, labelLower = labelText:lower(), tabName = tabName, row = row})
    end)
    return row
end

local function MakeSlider(parent, labelText, stateKey, minVal, maxVal, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = GetTheme("Main")
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    local lbl = Instance.new("TextLabel")
    lbl.Text = labelText
    lbl.Size = UDim2.new(0.6, 0, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200, 195, 220)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local valLbl = Instance.new("TextLabel")
    valLbl.Text = tostring(State[stateKey])
    valLbl.Size = UDim2.new(0.35, -12, 0, 18)
    valLbl.Position = UDim2.new(0.65, 0, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = GetTheme("Accent")
    valLbl.TextSize = 11
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row
    local track = Instance.new("TextButton")
    track.Text = ""
    track.AutoButtonColor = false
    track.Size = UDim2.new(1, -20, 0, 4)
    track.Position = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = GetTheme("Outline")
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0.5, 0)
    local fill = Instance.new("Frame")
    local startRel = (State[stateKey] - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(startRel, 0, 1, 0)
    fill.BackgroundColor3 = GetTheme("Accent")
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(startRel, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5, 0)
    local sliding = false
    local function UpdateSliderAtX(posX)
        local rel = math.clamp((posX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = minVal + rel * (maxVal - minVal)
        if stateKey:find("Delay") then
            value = math.floor(value * 10) / 10
        elseif stateKey == "MinMutationChance" then
            value = math.clamp(math.round(value / 20) * 20, minVal, maxVal)
            rel = (value - minVal) / (maxVal - minVal)
        else
            value = math.floor(value)
        end
        State[stateKey] = value
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valLbl.Text = tostring(value)
        if callback then callback(value) end
    end
    local function IsTouchOrMouse1(input) return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch end
    local function IsMove(input) return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch end
    track.InputBegan:Connect(function(input)
        if IsTouchOrMouse1(input) then
            sliding = true
            TweenService:Create(knob, TweenInfo.new(0.15), {Size = UDim2.new(0, 16, 0, 16)}):Play()
            UpdateSliderAtX(input.Position.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if IsTouchOrMouse1(input) then
            sliding = false
            TweenService:Create(knob, TweenInfo.new(0.15), {Size = UDim2.new(0, 12, 0, 12)}):Play()
        end
    end)
    track.InputChanged:Connect(function(input)
        if sliding and IsMove(input) then UpdateSliderAtX(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if IsTouchOrMouse1(input) and sliding then
            sliding = false
            TweenService:Create(knob, TweenInfo.new(0.15), {Size = UDim2.new(0, 12, 0, 12)}):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and IsMove(input) then UpdateSliderAtX(input.Position.X) end
    end)
    pcall(function()
        local tabName = "Unknown"
        local p = parent and parent.Parent
        if p then for n, f in pairs(tabFrames) do if p == f then tabName = n break end end end
        table.insert(FeatureRegistry, {label = labelText, labelLower = labelText:lower(), tabName = tabName, row = row})
    end)
    return row
end

local function MakeDropdown(parent, labelText, options, stateKey, order, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundColor3 = GetTheme("Main")
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)
    local cl = Instance.new("UIListLayout", container)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.TextColor3 = Color3.fromRGB(200, 195, 220)
    header.TextSize = 11
    header.Font = Enum.Font.Gotham
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = 0
    header.Parent = container
    local hp = Instance.new("UIPadding", header)
    hp.PaddingLeft = UDim.new(0, 10)
    local arrow = Instance.new("TextLabel")
    arrow.Text = "v"
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = GetTheme("Accent")
    arrow.TextSize = 12
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = header
    local dropList = Instance.new("Frame")
    dropList.BackgroundTransparency = 1
    dropList.Visible = false
    dropList.LayoutOrder = 1
    dropList.AutomaticSize = Enum.AutomaticSize.Y
    dropList.Size = UDim2.new(1, 0, 0, 0)
    dropList.Parent = container
    local dl = Instance.new("UIListLayout", dropList)
    dl.SortOrder = Enum.SortOrder.LayoutOrder
    local function UpdateHeader() header.Text = labelText .. ":  " .. tostring(State[stateKey]) end
    UpdateHeader()
    local open = false
    header.MouseEnter:Connect(function() TweenService:Create(header, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
    header.MouseLeave:Connect(function() TweenService:Create(header, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 195, 220)}):Play() end)
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundColor3 = GetTheme("Background")
        optBtn.TextColor3 = option == State[stateKey] and GetTheme("Accent") or Color3.fromRGB(170,165,195)
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.Gotham
        optBtn.Text = "  " .. option
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.BorderSizePixel = 0
        optBtn.LayoutOrder = i
        optBtn.Parent = dropList
        optBtn.MouseButton1Click:Connect(function()
            State[stateKey] = option
            UpdateHeader()
            dropList.Visible = false
            open = false
            arrow.Text = "v"
            if callback then callback(option) end
        end)
    end
    header.MouseButton1Click:Connect(function()
        open = not open
        dropList.Visible = open
        arrow.Text = open and "^" or "v"
    end)
    return container
end

local function MakeMultiDropdown(parent, labelText, options, stateKey, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundColor3 = GetTheme("Main")
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)
    local cl = Instance.new("UIListLayout", container)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.TextColor3 = Color3.fromRGB(200, 195, 220)
    header.TextSize = 11
    header.Font = Enum.Font.Gotham
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = 0
    header.Parent = container
    local hp = Instance.new("UIPadding", header)
    hp.PaddingLeft = UDim.new(0, 10)
    local arrow = Instance.new("TextLabel")
    arrow.Text = "v"
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = GetTheme("Accent")
    arrow.TextSize = 12
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = header
    local dropList = Instance.new("Frame")
    dropList.BackgroundTransparency = 1
    dropList.Visible = false
    dropList.LayoutOrder = 1
    dropList.AutomaticSize = Enum.AutomaticSize.Y
    dropList.Size = UDim2.new(1, 0, 0, 0)
    dropList.Parent = container
    local dl = Instance.new("UIListLayout", dropList)
    dl.SortOrder = Enum.SortOrder.LayoutOrder
    local function UpdateHeader()
        local count = #State[stateKey]
        header.Text = labelText .. ":  " .. (count ~= 0 and (count .. " Selected") or "None")
    end
    UpdateHeader()
    local open = false
    header.MouseEnter:Connect(function() TweenService:Create(header, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
    header.MouseLeave:Connect(function() TweenService:Create(header, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200,195,220)}):Play() end)

    local optBtns = {}
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundColor3 = GetTheme("Background")
        local sel = table.find(State[stateKey], option) ~= nil
        optBtn.TextColor3 = sel and GetTheme("Accent") or Color3.fromRGB(170,165,195)
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.Gotham
        optBtn.Text = (sel and "[x]  " or "[ ]  ") .. option
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.BorderSizePixel = 0
        optBtn.LayoutOrder = i
        optBtn.Parent = dropList
        optBtns[option] = optBtn
        optBtn.MouseButton1Click:Connect(function()
            local idx = table.find(State[stateKey], option)
            if idx then
                table.remove(State[stateKey], idx)
                optBtn.Text = "[ ]  " .. option
                optBtn.TextColor3 = Color3.fromRGB(170,165,195)
            else
                table.insert(State[stateKey], option)
                optBtn.Text = "[x]  " .. option
                optBtn.TextColor3 = GetTheme("Accent")
            end
            UpdateHeader()
        end)
    end

    -- *** THIS is the missing piece - refresh visuals on config load ***
    RegisterRefresh(function()
        for _, option in ipairs(options) do
            local optBtn = optBtns[option]
            if optBtn then
                local sel = table.find(State[stateKey], option) ~= nil
                optBtn.Text = (sel and "[x]  " or "[ ]  ") .. option
                optBtn.TextColor3 = sel and GetTheme("Accent") or Color3.fromRGB(170,165,195)
            end
        end
        UpdateHeader()
    end)

    header.MouseButton1Click:Connect(function()
        open = not open
        dropList.Visible = open
        arrow.Text = open and "^" or "v"
    end)
    return container
end

local function MakeTextInput(parent, labelText, stateKey, placeholder, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = GetTheme("Main")
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    local lbl = Instance.new("TextLabel")
    lbl.Text = labelText
    lbl.Size = UDim2.new(1, -10, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(160, 155, 185)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local input = Instance.new("TextBox")
    input.PlaceholderText = placeholder
    input.Text = State[stateKey]
    input.Size = UDim2.new(1, -20, 0, 20)
    input.Position = UDim2.new(0, 10, 0, 22)
    input.BackgroundColor3 = GetTheme("Background")
    input.TextColor3 = Color3.fromRGB(210, 205, 235)
    input.PlaceholderColor3 = Color3.fromRGB(100, 95, 125)
    input.TextSize = 11
    input.Font = Enum.Font.Gotham
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.BorderSizePixel = 0
    input.ClearTextOnFocus = false
    input.Parent = row
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
    local ip = Instance.new("UIPadding", input)
    ip.PaddingLeft = UDim.new(0, 6)
    input.Changed:Connect(function(prop)
        if prop == "Text" then State[stateKey] = input.Text end
    end)
    input.FocusLost:Connect(function() State[stateKey] = input.Text end)
    RegisterRefresh(function() input.Text = State[stateKey] or "" end)
    return row
end

-- Build tabs
local tabDefs = {
    { name = "Player",   icon = "👤", order = 1 },
    { name = "Main",     icon = "🏠", order = 2 },
    { name = "Shop",     icon = "🛒", order = 3 },
    { name = "Eggs/Pot", icon = "🥚", order = 4 },
    { name = "Upgrade",  icon = "⬆️", order = 5 },
    { name = "Quick",    icon = "⚡", order = 6 },
    { name = "Webhook",  icon = "🔗", order = 7 },
    { name = "Settings", icon = "⚙️", order = 8 },
    { name = "Config",   icon = "💾", order = 9 },
    { name = "Info", icon = "ℹ️", order = 10 },
    { name = "Fuse", icon = "⚗️", order = 11 },
}
for _, def in ipairs(tabDefs) do
    tabFrames[def.name] = MakeTabFrame(def.name)
    navBtns[def.name], navAccents[def.name] = MakeNavButton(def.name, def.icon, def.order)
end

local function SwitchTab(name)
    for k, frame in pairs(tabFrames) do
        local isSelected = (k == name)
        frame.Visible = isSelected
        local btn = navBtns[k]
        local acc = navAccents[k]
        if isSelected then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = 0,
                BackgroundColor3 = GetTheme("Background"),
                TextColor3 = GetTheme("Accent")
            }):Play()
            acc.Visible = true
            acc.Size = UDim2.new(0, 3, 0, 0)
            TweenService:Create(acc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 3, 0.7, 0)
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = 1,
                BackgroundColor3 = Color3.fromRGB(0,0,0),
                TextColor3 = Color3.fromRGB(140, 135, 170)
            }):Play()
            acc.Visible = false
        end
    end
end
for name, btn in pairs(navBtns) do
    btn.MouseButton1Click:Connect(function()
        lastActiveTab = name
        SwitchTab(name)
    end)
end

local diceRank = {
    "Basic Dice","Silver Dice","Golden Dice","Aureline Dice","Crystallum Dice",
    "Diamond Dice","Nebulite Dice","Galaxion Dice","Quantum Dice","Devil Dice",
    "Heaven Dice","Nebula Dice","Singularity Dice","Aqua Dice","Lucky Dice",
    "Void Dice","Ethereal Dice","Celestial Dice","Solar Dice","Abyssal Dice",
    "Hell Dice","Infinity Dice","Blackhole Dice","Death Dice","Paradoxical Dice",
    "Soul Dice","Joker Dice","Reality Dice","Kraken Dice","Seraphic Dice",
    "Galactic Dice","Eldritch Dice","Emperor Dice","Annihilation Dice",
    "Disaster Dice","Impossible Dice","Limbo Dice","Chronos Dice","Yinyang Dice","Matrix Dice","Uriel Dice"
}

-- ============================================================
-- FEATURE SEARCH
-- ============================================================
do
    -- Search results overlay
    local searchResultsFrame = Instance.new("ScrollingFrame")
    searchResultsFrame.Size = UDim2.new(1, 0, 1, 0)
    searchResultsFrame.BackgroundTransparency = 1
    searchResultsFrame.BorderSizePixel = 0
    searchResultsFrame.ScrollBarThickness = 3
    searchResultsFrame.ScrollBarImageColor3 = GetTheme("Accent")
    searchResultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    searchResultsFrame.Visible = false
    searchResultsFrame.ZIndex = 10
    local srLayout = Instance.new("UIListLayout", searchResultsFrame)
    srLayout.SortOrder = Enum.SortOrder.LayoutOrder
    srLayout.Padding = UDim.new(0, 4)
    srLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        searchResultsFrame.CanvasSize = UDim2.new(0, 0, 0, srLayout.AbsoluteContentSize.Y + 15)
    end)
    local srPad = Instance.new("UIPadding", searchResultsFrame)
    srPad.PaddingTop = UDim.new(0, 8)
    srPad.PaddingLeft = UDim.new(0, 8)
    srPad.PaddingRight = UDim.new(0, 12)
    searchResultsFrame.Parent = TabContainer

    -- Search box at top of NavFrame
    local searchBox = Instance.new("TextBox")
    searchBox.PlaceholderText = "search features..."
    searchBox.Text = ""
    searchBox.Size = UDim2.new(1, 0, 0, 26)
    searchBox.BackgroundColor3 = GetTheme("Background")
    searchBox.TextColor3 = Color3.fromRGB(235, 232, 255)
    searchBox.PlaceholderColor3 = Color3.fromRGB(140, 130, 165)
    searchBox.TextSize = 10
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.Size = UDim2.new(0, 456, 0, 24)
    searchBox.Position = UDim2.new(0, 116, 0, 44)
    searchBox.Parent = MainFrame
    searchBox.ZIndex = 5
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)
    local sbp = Instance.new("UIPadding", searchBox)
    sbp.PaddingLeft = UDim.new(0, 8)
    local searchStroke = Instance.new("UIStroke", searchBox)
    searchStroke.Color = GetTheme("Outline")
    searchStroke.Thickness = 0.5
    searchBox.Focused:Connect(function()
        TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = GetTheme("Accent")}):Play()
    end)
    searchBox.FocusLost:Connect(function()
        if searchBox.Text == "" then
            TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = GetTheme("Outline")}):Play()
        end
    end)

    local function DoSearch(query)
        for _, c in pairs(searchResultsFrame:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
        query = query:lower():match("^%s*(.-)%s*$")
        if query == "" then
            searchResultsFrame.Visible = false
            SwitchTab(lastActiveTab)
            return
        end
        searchResultsFrame.Visible = true
        for _, frame in pairs(tabFrames) do frame.Visible = false end

        local results = {}
        for _, entry in ipairs(FeatureRegistry) do
            if entry.labelLower:find(query, 1, true) then
                table.insert(results, entry)
            end
        end

        if #results == 0 then
            local noRes = Instance.new("TextLabel")
            noRes.Text = 'No results for "' .. query .. '"'
            noRes.Size = UDim2.new(1, 0, 0, 30)
            noRes.BackgroundTransparency = 1
            noRes.TextColor3 = Color3.fromRGB(110, 105, 135)
            noRes.TextSize = 11
            noRes.Font = Enum.Font.Gotham
            noRes.TextXAlignment = Enum.TextXAlignment.Left
            noRes.LayoutOrder = 1
            noRes.Parent = searchResultsFrame
            return
        end

        for i, entry in ipairs(results) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 34)
            row.BackgroundColor3 = GetTheme("Main")
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Text = ""
            row.AutoButtonColor = false
            row.Parent = searchResultsFrame
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
            local rs = Instance.new("UIStroke", row)
            rs.Color = GetTheme("Outline")
            rs.Thickness = 1

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = entry.label
            nameLbl.Size = UDim2.new(0.6, 0, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3 = Color3.fromRGB(210, 205, 235)
            nameLbl.TextSize = 11
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row

            local tabBadge = Instance.new("TextLabel")
            tabBadge.Text = entry.tabName
            tabBadge.Size = UDim2.new(0, 0, 0, 16)
            tabBadge.AutomaticSize = Enum.AutomaticSize.X
            tabBadge.AnchorPoint = Vector2.new(1, 0.5)
            tabBadge.Position = UDim2.new(1, -6, 0.5, 0)
            tabBadge.BackgroundColor3 = GetTheme("Accent")
            tabBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabBadge.TextSize = 9
            tabBadge.Font = Enum.Font.GothamBold
            tabBadge.BorderSizePixel = 0
            tabBadge.Parent = row
            Instance.new("UICorner", tabBadge).CornerRadius = UDim.new(0, 3)
            local bp = Instance.new("UIPadding", tabBadge)
            bp.PaddingLeft = UDim.new(0, 5)
            bp.PaddingRight = UDim.new(0, 5)

            row.MouseEnter:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Background")}):Play()
                rs.Color = GetTheme("Accent")
            end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Main")}):Play()
                rs.Color = GetTheme("Outline")
            end)

            local capturedTab = entry.tabName
            local capturedRow = entry.row
            row.MouseButton1Click:Connect(function()
                searchBox.Text = ""
                searchResultsFrame.Visible = false
                lastActiveTab = capturedTab
                SwitchTab(capturedTab)
                -- Flash highlight the target row
                if capturedRow and capturedRow.Parent then
                    task.spawn(function()
                        task.wait(0.05)
                        local orig = GetTheme("Main")
                        for _ = 1, 2 do
                            TweenService:Create(capturedRow, TweenInfo.new(0.12), {BackgroundColor3 = GetTheme("Accent")}):Play()
                            task.wait(0.18)
                            TweenService:Create(capturedRow, TweenInfo.new(0.12), {BackgroundColor3 = orig}):Play()
                            task.wait(0.18)
                        end
                    end)
                end
            end)
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        DoSearch(searchBox.Text)
    end)
end

-- ============================================================
-- COIN TRACKING
-- ============================================================
local function ParseCoins(str)
    str = tostring(str):gsub(",", ""):upper()
    local num, suffix = str:match("^([%d%.]+)([KMBTQ]?)")
    if not num then return tonumber(str) or 0 end
    local suffixes = {K=1e3, M=1e6, B=1e9, T=1e12, Q=1e15}
    return tonumber(num) * (suffixes[suffix] or 1)
end
local function FormatCoins(n)
    n = n or 0
    if n >= 1e15 then return string.format("%.1fQ", n/1e15) end
    if n >= 1e12 then return string.format("%.1fT", n/1e12) end
    if n >= 1e9  then return string.format("%.1fB", n/1e9)  end
    if n >= 1e6  then return string.format("%.1fM", n/1e6)  end
    if n >= 1e3  then return string.format("%.1fK", n/1e3)  end
    return tostring(math.floor(n))
end

-- ============================================================
-- TAB CONTENT
-- ============================================================
do
    local playerTab = tabFrames["Player"]
    local physSection = MakeSection(playerTab, "PHYSICS", 1)
    MakeSlider(physSection, "Walk Speed", "WalkSpeed", 16, 100, 1, function(v)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end)
    MakeSlider(physSection, "Teleport Speed", "TeleportSpeed", 0, 20, 2)
    MakeSlider(physSection, "Fly Speed", "FlySpeed", 0, 500, 3)
    local moveSection = MakeSection(playerTab, "MOVEMENT", 4)
    MakeToggle(moveSection, "Infinite Jump", "InfiniteJump", 1)
    MakeToggle(moveSection, "Noclip", "Noclip", 2)
    MakeToggle(moveSection, "Fly", "Flying", 3)
end

do
    local mainTab = tabFrames["Main"]
    local weatherList = {
        "Rain","Blizzard","Golden Hour","Emerald Hurricane","Diamond Rush",
        "Candy Crush","Slime Rain","Rosefall Skies","Bee Swarm",
        "Twilight Oblivion","Solar Flare","Falling Stars","Aurora Borealis", "Epoch Terminus"
    }
    local collectSection = MakeSection(mainTab, "COLLECTION", 1)
    MakeToggle(collectSection, "Collect Coins", "AutoCollectCoins", 1)
    MakeSlider(collectSection, "Collect Delay (s)", "CollectDelay", 0.2, 5, 2)
    MakeSlider(collectSection, "Equip Best Delay (s)", "EquipBestDelay", 3, 60, 3)
    local filterSection = MakeSection(mainTab, "GLOBAL FILTERS", 4)
    MakeMultiDropdown(filterSection, "Global Weather Filter", weatherList, "GlobalWeatherFilter", 1)
    MakeToggle(filterSection, "Auto-Equip Best Baddies", "AutoEquipBest", 2)
    local rollSection = MakeSection(mainTab, "AUTO-ROLL", 5)
    MakeToggle(rollSection, "Auto Roll Dice", "AutoRoll", 1)
    MakeSlider(rollSection, "Roll Delay (s)", "RollDelay", 0.1, 5, 2)
    MakeToggle(rollSection, "Only Roll on Weather", "AutoDiceOnWeather", 3)
    MakeToggle(rollSection, "Best Dice Auto-Equip", "BestDice", 4)
    MakeToggle(rollSection, "Auto-Roll Worst Dice", "WorstDiceFilter", 5)
    MakeMultiDropdown(rollSection, "Worst Dice to Burn", diceRank, "WorstDiceList", 6)
    local exploitSection = MakeSection(mainTab, "REMOTE BYPASSES", 2) -- New section
    MakeToggle(exploitSection, "Nuke Cutscenes (Anti-Lock)", "NukeCutscenes", 1, function(val)
        if val then
            local questRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("QuestRemote")
            if questRemote then questRemote:InvokeServer("Cutscenes", false) end
        end
    end)
    local claimSection = MakeSection(mainTab, "AUTO-CLAIM", 6)
    MakeToggle(claimSection, "Time Rewards", "AutoTimeReward", 1)
    MakeToggle(claimSection, "Quests", "AutoQuests", 2)
    MakeToggle(claimSection, "Index Rewards", "AutoIndex", 3)
    MakeToggle(claimSection, "Spin Wheel (Auto)", "AutoSpin", 4)
end

do
    local shopTab = tabFrames["Shop"]
    local diceSection = MakeSection(shopTab, "DICE SHOP", 1)
    local diceList = {
        "Basic Dice","Silver Dice","Golden Dice","Aureline Dice","Crystallum Dice",
        "Diamond Dice","Nebulite Dice","Galaxion Dice","Quantum Dice","Devil Dice",
        "Heaven Dice","Nebula Dice","Singularity Dice","Aqua Dice","Lucky Dice",
        "Void Dice","Ethereal Dice","Celestial Dice","Solar Dice","Abyssal Dice",
        "Hell Dice","Infinity Dice","Blackhole Dice","Death Dice","Paradoxical Dice",
        "Soul Dice","Joker Dice","Reality Dice","Kraken Dice","Seraphic Dice",
        "Galactic Dice","Eldritch Dice","Emperor Dice","Annihilation Dice",
        "Disaster Dice","Impossible Dice","Limbo Dice","Chronos Dice","Yinyang Dice","Matrix Dice","Uriel Dice"
    }
    MakeMultiDropdown(diceSection, "Select Dice", diceList, "SelectedDice", 1)
    MakeSlider(diceSection, "Purchase Delay (s)", "DicePurchaseDelay", 0.5, 5, 2)
    MakeToggle(diceSection, "Always Buy Max", "AlwaysBuyMax", 3)
    MakeToggle(diceSection, "Auto-Buy Selected Dice", "AutoBuyDice", 4)

    local rebirthExploitRow = MakeRow(diceSection, 5)
    local rebirthExploitLbl = Instance.new("TextLabel")
    rebirthExploitLbl.Text = "!! [EXPLOIT] Rapid fire - ignores stock check"
    rebirthExploitLbl.Size = UDim2.new(0.75, 0, 1, 0)
    rebirthExploitLbl.Position = UDim2.new(0, 10, 0, 0)
    rebirthExploitLbl.BackgroundTransparency = 1
    rebirthExploitLbl.TextColor3 = Color3.fromRGB(255, 180, 60)
    rebirthExploitLbl.TextSize = 10
    rebirthExploitLbl.Font = Enum.Font.Gotham
    rebirthExploitLbl.TextXAlignment = Enum.TextXAlignment.Left
    rebirthExploitLbl.Parent = rebirthExploitRow
    State["RebirthBypass"] = false
    local rbToggleBg = Instance.new("TextButton")
    rbToggleBg.Text = ""
    rbToggleBg.AutoButtonColor = false
    rbToggleBg.Size = UDim2.new(0, 36, 0, 18)
    rbToggleBg.Position = UDim2.new(1, -46, 0.5, -9)
    rbToggleBg.BackgroundColor3 = GetTheme("Outline")
    rbToggleBg.BorderSizePixel = 0
    rbToggleBg.Parent = rebirthExploitRow
    Instance.new("UICorner", rbToggleBg).CornerRadius = UDim.new(0.5, 0)
    local rbKnob = Instance.new("Frame")
    rbKnob.Size = UDim2.new(0, 14, 0, 14)
    rbKnob.Position = UDim2.new(0, 2, 0.5, -7)
    rbKnob.BackgroundColor3 = Color3.fromRGB(160, 155, 185)
    rbKnob.BorderSizePixel = 0
    rbKnob.Parent = rbToggleBg
    Instance.new("UICorner", rbKnob).CornerRadius = UDim.new(0.5, 0)
    local function UpdateRbVisual(val)
        TweenService:Create(rbToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = val and Color3.fromRGB(220, 140, 30) or GetTheme("Outline")}):Play()
        TweenService:Create(rbKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = val and UDim2.new(0, 20, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = val and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,155,185)
        }):Play()
    end
    rbToggleBg.MouseButton1Click:Connect(function()
        State["RebirthBypass"] = not State["RebirthBypass"]
        UpdateRbVisual(State["RebirthBypass"])
    end)

    local potionSection = MakeSection(shopTab, "POTION SHOP", 6)
    local potionList = {
        "Luck Potion 1","Luck Potion 2","Luck Potion 3",
        "Money Potion 1","Money Potion 2","Money Potion 3",
        "No Consume Dice Potion 1",
        "Mutation Chance Potion 1"
    }
    MakeMultiDropdown(potionSection, "Select Potion(s)", potionList, "SelectedPotion", 1)
    MakeSlider(potionSection, "Purchase Delay (s)", "PotionPurchaseDelay", 0.5, 5, 2)
    MakeToggle(potionSection, "Auto-Buy Selected Potion(s)", "AutoBuyPotion", 3)
    local merchantSection = MakeSection(shopTab, "MERCHANT", 8)
    MakeToggle(merchantSection, "!! Auto-Merchant [BANNABLE]", "AutoMerchant", 1)
    local gemSection = MakeSection(shopTab, "GEM BOXES (NULLITY)", 9)
    MakeToggle(gemSection, "Auto-Buy Rare Box", "AutoBuyRareBox", 1)
    MakeToggle(gemSection, "Auto-Buy Basic Box", "AutoBuyBasicBox", 2)
end

do
    local potionTab = tabFrames["Eggs/Pot"]
    local hatchSection = MakeSection(potionTab, "EGG HATCHING", 1)
    local eggList = {"CatEgg","DogEgg","CubeEgg","SlimeEgg","NullEgg",
        "AquaEgg","MartianEgg","BackroomsEgg","AngelEgg","MechEgg"}
    MakeDropdown(hatchSection, "Select Egg", eggList, "SelectedEgg", 1)
    MakeSlider(hatchSection, "Hatch Delay (s)", "HatchDelay", 0.1, 5, 2)
    MakeSlider(hatchSection, "Execution Multiplier", "ExecutionMultiplier", 1, 50, 3)
    MakeToggle(hatchSection, "Hatch 3x Eggs", "Hatch3x", 3)
    MakeToggle(hatchSection, "Auto-Hatch", "AutoHatch", 4)
    local buffSection = MakeSection(potionTab, "POTION LOGIC", 3)
    MakeToggle(buffSection, "Auto-Equip Best Potions", "AutoEquipPotions", 1)
    MakeToggle(buffSection, "Check Active Buff First", "ActiveBuffCheck", 2)
    MakeToggle(buffSection, "Auto Roll Money Potions (Always)", "AutoRollMoneyPotion", 3)
end

-- Declared here so the Runtime block below can also access them
local upgradeOptNames = {
    "+Luck Boost", "+Coin Multiplier", "+Extra Dice Stock",
    "+Mutation Chance", "+Pet Luck Buff", "+Improved Mutations",
    "+Restock Chance", "+Secret Baddie Rate", "+Godly Baddie Rate",
    "+Quest/Index Gem Boost", "+Apex Baddie Rate"
}
local upgradeRowLabels = {}

do
    local upgradeTab = tabFrames["Upgrade"]
    local rebirthSection = MakeSection(upgradeTab, "REBIRTH", 1)
    MakeToggle(rebirthSection, "Auto-Rebirth", "AutoRebirth", 1)
    local upgradeSection = MakeSection(upgradeTab, "AUTO-UPGRADE", 2)
    MakeToggle(upgradeSection, "Enable Auto-Upgrade", "AutoUpgrade", 1)
    local upgradeTargetSection = MakeSection(upgradeTab, "TARGETS", 3)
    for i, opt in ipairs(upgradeOptNames) do
        State["Upgrade_"..i] = false
        State["UpgradeMaxed_"..i] = false
        local row = MakeToggle(upgradeTargetSection, opt, "Upgrade_"..i, i)
        for _, child in pairs(row:GetChildren()) do
            if child:IsA("TextLabel") then
                upgradeRowLabels[i] = child
                break
            end
        end
    end
end

do
    local webhookTab = tabFrames["Webhook"]
    local webhookSection = MakeSection(webhookTab, "DISCORD", 1)
    MakeTextInput(webhookSection, "Webhook URL", "WebhookURL", "https://discord.com/api/webhooks/...", 1)
    MakeTextInput(webhookSection, "User ID (for ping)", "UserID", "123456789012345678", 2)
    local raritySection = MakeSection(webhookTab, "NOTIFY ON RARITY", 3)
    for i, rarity in ipairs({"Common","Uncommon","Rare","Epic","Legendary","Mythic","Divine","Prismatic","Sacred","Secret","Godly","Cosmic","Apex","Primordial"}) do
        local key = "Rarity_"..rarity
        State[key] = rarity == "Primordial" or rarity == "Apex" or rarity == "Cosmic"
            or rarity == "Godly" or rarity == "Secret" or rarity == "Sacred"
            or rarity == "Divine" or rarity == "Prismatic"
        MakeToggle(raritySection, rarity, key, i)
    end
    local testBtnRow = MakeRow(webhookSection, 3)
    local testBtn = Instance.new("TextButton")
    testBtn.Text = "Send Test Webhook"
    testBtn.Size = UDim2.new(1, -20, 0, 22)
    testBtn.Position = UDim2.new(0, 10, 0.5, -11)
    testBtn.BackgroundColor3 = GetTheme("Main")
    testBtn.TextColor3 = Color3.fromRGB(120, 220, 120)
    testBtn.TextSize = 11
    testBtn.Font = Enum.Font.GothamBold
    testBtn.BorderSizePixel = 0
    testBtn.Parent = testBtnRow
    Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 4)
    local testStroke = Instance.new("UIStroke", testBtn)
    testStroke.Color = GetTheme("Outline")
    testStroke.Thickness = 1
    testBtn.MouseButton1Click:Connect(function() TestWebhook() end)
    testBtn.MouseEnter:Connect(function() testStroke.Color = Color3.fromRGB(120, 220, 120) end)
    testBtn.MouseLeave:Connect(function() testStroke.Color = GetTheme("Outline") end)
end

-- ============================================================
-- SETTINGS TAB + COLOR PICKER
-- ============================================================
do
    local settingsTab = tabFrames["Settings"]
    local safetySection = MakeSection(settingsTab, "SAFETY", 1)
    MakeToggle(safetySection, "Staff Detection (Auto-Leave)", "StaffDetection", 1)
    MakeToggle(safetySection, "Anti-AFK", "AntiAFK", 2)
    MakeToggle(safetySection, "Auto-Rejoin", "AutoRejoin", 3)
    MakeToggle(safetySection, "Suppress Auto-Sell Notif", "SuppressAutoSell", 4)

    local hopSection = MakeSection(settingsTab, "NULLITY HUNTER", 2)
    MakeToggle(hopSection, "Auto-Hop for Nullity", "AutoHopForNullity", 1)
    MakeSlider(hopSection, "Hop Delay (s)", "HopDelay", 8, 60, 2)

    local themeSection = MakeSection(settingsTab, "THEME", 4)

    local pickerTarget = nil
    local pickerFrame = Instance.new("Frame")
    pickerFrame.Size = UDim2.new(0, 260, 0, 190)
    pickerFrame.Position = UDim2.new(0.5, -130, 0.5, -95)
    pickerFrame.BackgroundColor3 = HexToColor("1A1A24")
    pickerFrame.BorderSizePixel = 0
    pickerFrame.ZIndex = 50
    pickerFrame.Visible = false
    pickerFrame.Parent = TabContainer
    Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 8)
    local pickerStroke = Instance.new("UIStroke", pickerFrame)
    pickerStroke.Color = GetTheme("Accent")
    pickerStroke.Thickness = 1

    local pickerTitle = Instance.new("TextLabel")
    pickerTitle.Text = "Pick Color"
    pickerTitle.Size = UDim2.new(1, -40, 0, 28)
    pickerTitle.Position = UDim2.new(0, 10, 0, 4)
    pickerTitle.BackgroundTransparency = 1
    pickerTitle.TextColor3 = Color3.fromRGB(210, 200, 240)
    pickerTitle.TextSize = 12
    pickerTitle.Font = Enum.Font.GothamBold
    pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
    pickerTitle.ZIndex = 51
    pickerTitle.Parent = pickerFrame

    local pickerClose = Instance.new("TextButton")
    pickerClose.Text = "X"
    pickerClose.Size = UDim2.new(0, 22, 0, 22)
    pickerClose.Position = UDim2.new(1, -26, 0, 4)
    pickerClose.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    pickerClose.TextColor3 = Color3.fromRGB(255,255,255)
    pickerClose.TextSize = 10
    pickerClose.Font = Enum.Font.GothamBold
    pickerClose.BorderSizePixel = 0
    pickerClose.ZIndex = 51
    pickerClose.Parent = pickerFrame
    Instance.new("UICorner", pickerClose).CornerRadius = UDim.new(0, 4)

    local pickerH, pickerS, pickerV = 0, 1, 1

    local function MakePickerSlider(label, yPos, defaultVal)
        local trackBg = Instance.new("Frame")
        trackBg.Size = UDim2.new(1, -20, 0, 18)
        trackBg.Position = UDim2.new(0, 10, 0, yPos)
        trackBg.BackgroundColor3 = HexToColor("2A2A38")
        trackBg.BorderSizePixel = 0
        trackBg.ZIndex = 51
        trackBg.Parent = pickerFrame
        Instance.new("UICorner", trackBg).CornerRadius = UDim.new(0, 4)
        local lbl2 = Instance.new("TextLabel")
        lbl2.Text = label
        lbl2.Size = UDim2.new(0, 12, 1, 0)
        lbl2.BackgroundTransparency = 1
        lbl2.TextColor3 = Color3.fromRGB(170, 160, 200)
        lbl2.TextSize = 9
        lbl2.Font = Enum.Font.GothamBold
        lbl2.ZIndex = 52
        lbl2.Parent = trackBg
        local fill2 = Instance.new("Frame")
        fill2.Size = UDim2.new(defaultVal, 0, 1, 0)
        fill2.BackgroundColor3 = GetTheme("Accent")
        fill2.BorderSizePixel = 0
        fill2.ZIndex = 52
        fill2.Parent = trackBg
        Instance.new("UICorner", fill2).CornerRadius = UDim.new(0, 4)
        local knob2 = Instance.new("Frame")
        knob2.Size = UDim2.new(0, 12, 0, 12)
        knob2.AnchorPoint = Vector2.new(0.5, 0.5)
        knob2.Position = UDim2.new(defaultVal, 0, 0.5, 0)
        knob2.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob2.BorderSizePixel = 0
        knob2.ZIndex = 53
        knob2.Parent = trackBg
        Instance.new("UICorner", knob2).CornerRadius = UDim.new(0.5, 0)
        return trackBg, fill2, knob2
    end

    local hTrack, hFill, hKnob = MakePickerSlider("H", 36, 0)
    local sTrack, sFill, sKnob = MakePickerSlider("S", 62, 1)
    local vTrack, vFill, vKnob = MakePickerSlider("V", 88, 1)

    local pickerPreview = Instance.new("Frame")
    pickerPreview.Size = UDim2.new(1, -20, 0, 36)
    pickerPreview.Position = UDim2.new(0, 10, 0, 114)
    pickerPreview.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
    pickerPreview.BorderSizePixel = 0
    pickerPreview.ZIndex = 51
    pickerPreview.Parent = pickerFrame
    Instance.new("UICorner", pickerPreview).CornerRadius = UDim.new(0, 5)

    local pickerHexLabel = Instance.new("TextLabel")
    pickerHexLabel.Text = "#FF0000"
    pickerHexLabel.Size = UDim2.new(0.6, 0, 1, 0)
    pickerHexLabel.BackgroundTransparency = 1
    pickerHexLabel.TextColor3 = Color3.fromRGB(220, 215, 240)
    pickerHexLabel.TextSize = 11
    pickerHexLabel.Font = Enum.Font.Code
    pickerHexLabel.ZIndex = 52
    pickerHexLabel.Parent = pickerPreview

    local pickerApply = Instance.new("TextButton")
    pickerApply.Text = "Apply"
    pickerApply.Size = UDim2.new(1, -20, 0, 22)
    pickerApply.Position = UDim2.new(0, 10, 0, 158)
    pickerApply.BackgroundColor3 = GetTheme("Accent")
    pickerApply.TextColor3 = Color3.fromRGB(255,255,255)
    pickerApply.TextSize = 11
    pickerApply.Font = Enum.Font.GothamBold
    pickerApply.BorderSizePixel = 0
    pickerApply.ZIndex = 51
    pickerApply.Parent = pickerFrame
    Instance.new("UICorner", pickerApply).CornerRadius = UDim.new(0, 5)

    local function ColorToHex(c)
        return string.format("%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
    end

    local function UpdatePickerColor()
        local col = Color3.fromHSV(pickerH, pickerS, pickerV)
        pickerPreview.BackgroundColor3 = col
        pickerHexLabel.Text = "#" .. ColorToHex(col)
        hFill.BackgroundColor3 = Color3.fromHSV(pickerH, 1, 1)
    end

    local function MakeSliderDrag(track, fill, knob, onChange)
        local sliding = false
        local function SetFromX(px)
            local rel = math.clamp((px - track.AbsolutePosition.X - 14) / (track.AbsoluteSize.X - 14), 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            onChange(rel)
            UpdatePickerColor()
        end
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                SetFromX(input.Position.X)
            end
        end)
        track.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                SetFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
    end

    MakeSliderDrag(hTrack, hFill, hKnob, function(v) pickerH = v end)
    MakeSliderDrag(sTrack, sFill, sKnob, function(v) pickerS = v end)
    MakeSliderDrag(vTrack, vFill, vKnob, function(v) pickerV = v end)

    local function OpenPicker(key, previewRef, hexRef)
        pickerTarget = {key = key, preview = previewRef, hex = hexRef}
        pickerTitle.Text = "Color: " .. key
        local col = HexToColor(State.Theme[key])
        pickerH, pickerS, pickerV = Color3.toHSV(col)
        hFill.Size = UDim2.new(pickerH, 0, 1, 0)
        hKnob.Position = UDim2.new(pickerH, 0, 0.5, 0)
        sFill.Size = UDim2.new(pickerS, 0, 1, 0)
        sKnob.Position = UDim2.new(pickerS, 0, 0.5, 0)
        vFill.Size = UDim2.new(pickerV, 0, 1, 0)
        vKnob.Position = UDim2.new(pickerV, 0, 0.5, 0)
        UpdatePickerColor()
        pickerFrame.Visible = true
    end

    pickerClose.MouseButton1Click:Connect(function()
        pickerFrame.Visible = false
        pickerTarget = nil
    end)

    pickerApply.MouseButton1Click:Connect(function()
        if not pickerTarget then return end
        local col = Color3.fromHSV(pickerH, pickerS, pickerV)
        local hex = ColorToHex(col)
        State.Theme[pickerTarget.key] = hex
        pickerTarget.preview.BackgroundColor3 = col
        pickerTarget.hex.Text = "#" .. hex
        pickerFrame.Visible = false
        local k = pickerTarget.key
        pickerTarget = nil
        if k == "Background" then
            MainFrame.BackgroundColor3 = col
        elseif k == "Main" then
            TitleBar.BackgroundColor3 = col
            TitleFix.BackgroundColor3 = col
            NavFrame.BackgroundColor3 = col
            LiveDataFrame.BackgroundColor3 = col
        elseif k == "Accent" then
            MainStroke.Color = col
            accentLine.BackgroundColor3 = col
        elseif k == "Outline" then
            MainStroke.Color = col
        end
    end)

    for i, key in ipairs({"Background","Main","Accent","Outline"}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = GetTheme("Main")
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = themeSection
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
        local lbl = Instance.new("TextLabel")
        lbl.Text = key
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(180,175,210)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        local previewBtn = Instance.new("TextButton")
        previewBtn.Text = ""
        previewBtn.AutoButtonColor = false
        previewBtn.Size = UDim2.new(0, 22, 0, 22)
        previewBtn.Position = UDim2.new(0.42, 0, 0.5, -11)
        previewBtn.BackgroundColor3 = HexToColor(State.Theme[key])
        previewBtn.BorderSizePixel = 0
        previewBtn.Parent = row
        Instance.new("UICorner", previewBtn).CornerRadius = UDim.new(0.5, 0)
        local previewStroke = Instance.new("UIStroke", previewBtn)
        previewStroke.Color = Color3.fromRGB(100, 80, 150)
        previewStroke.Thickness = 1
        local hexLabel = Instance.new("TextLabel")
        hexLabel.Text = "#" .. State.Theme[key]
        hexLabel.Size = UDim2.new(0.45, -30, 0, 22)
        hexLabel.Position = UDim2.new(0.42, 28, 0.5, -11)
        hexLabel.BackgroundTransparency = 1
        hexLabel.TextColor3 = Color3.fromRGB(160, 150, 200)
        hexLabel.TextSize = 10
        hexLabel.Font = Enum.Font.Code
        hexLabel.TextXAlignment = Enum.TextXAlignment.Left
        hexLabel.Parent = row
        previewBtn.MouseButton1Click:Connect(function()
            OpenPicker(key, previewBtn, hexLabel)
        end)
        previewBtn.MouseEnter:Connect(function()
            TweenService:Create(previewStroke, TweenInfo.new(0.15), {Color = GetTheme("Accent"), Thickness = 2}):Play()
        end)
        previewBtn.MouseLeave:Connect(function()
            TweenService:Create(previewStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(100, 80, 150), Thickness = 1}):Play()
        end)
    end
end

-- ============================================================
-- QUICK TAB
-- ============================================================
do
    local quickTab = tabFrames["Quick"]
    local shopAccessSection = MakeSection(quickTab, "SHOP ACCESS", 1)

    local function MakeQuickButton(parent, labelText, frameName, order)
        local row = MakeRow(parent, order)
        local btn = Instance.new("TextButton")
        btn.Text = "Open " .. labelText
        btn.Size = UDim2.new(1, -20, 0, 22)
        btn.Position = UDim2.new(0, 10, 0.5, -11)
        btn.BackgroundColor3 = GetTheme("Main")
        btn.TextColor3 = Color3.fromRGB(220, 215, 240)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = GetTheme("Outline")
        stroke.Thickness = 1
        btn.MouseButton1Click:Connect(function()
            local ui = LocalPlayer.PlayerGui:FindFirstChild("Main")
            local target = ui and ui:FindFirstChild(frameName)
            if target then target.Visible = not target.Visible end
        end)
        btn.MouseEnter:Connect(function() stroke.Color = GetTheme("Accent") end)
        btn.MouseLeave:Connect(function() stroke.Color = GetTheme("Outline") end)
        return row
    end

    MakeQuickButton(shopAccessSection, "Dice Shop", "Restock", 1)
    MakeQuickButton(shopAccessSection, "Merchant Shop", "MerchantShop", 2)
    MakeQuickButton(shopAccessSection, "Potion Shop", "Potions", 3)
    MakeQuickButton(shopAccessSection, "Upgrade Shop", "Upgrades", 4)
    MakeQuickButton(shopAccessSection, "Gem Shop", "GemShop", 5)
end

-- ============================================================
-- CONFIG SYSTEM
-- ============================================================
local CONFIG_FOLDER = "reidu_configs"
local AUTOLOAD_FILE = CONFIG_FOLDER .. "/_autoload.txt"

pcall(function() if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end end)

local SAVE_KEYS = {
    "WalkSpeed","TeleportSpeed","FlySpeed","InfiniteJump","Noclip","Flying",
    "AutoCollectCoins","CollectDelay","EquipBestDelay","BestDice","WorstDiceFilter", "WorstDiceList",
    "AutoEquipBest","AutoTimeReward","NukeCutscenes","AutoQuests","AutoIndex","AutoBuyDice","AutoBuyPotion",
    "DicePurchaseDelay","PotionPurchaseDelay","AutoHopForNullity","HopDelay","SelectedDice","SelectedPotion","AlwaysBuyMax",
    "AutoMerchant","HatchDelay","SuppressAutoSell","AutoBuyRareBox","ExecutionMultiplier","AutoBuyBasicBox","ActiveBuffCheck","AutoUpgrade","AutoRebirth","AutoRoll",
    "RollDelay","AutoDiceOnWeather","AutoSpin","GlobalWeatherFilter","AutoHatch","Hatch3x",
    "SelectedEgg","WebhookURL","UserID","AutoRollMoneyPotion","AutoEquipPotions","StaffDetection","AntiAFK","AutoRejoin","Theme",
    "RebirthBypass","Upgrade_1","Upgrade_2","Upgrade_3","Upgrade_4","Upgrade_5","Upgrade_6","Upgrade_7","Upgrade_8","Upgrade_9","Upgrade_10","Upgrade_11",
    "Rarity_Common","Rarity_Uncommon","Rarity_Rare","Rarity_Epic","Rarity_Legendary","Rarity_Mythic",
    "Rarity_Divine","Rarity_Prismatic","Rarity_Sacred","Rarity_Secret","Rarity_Godly","Rarity_Cosmic",
    "Rarity_Apex","Rarity_Primordial",
}

local function SaveConfig(name)
    local data = {}
    for _, k in ipairs(SAVE_KEYS) do data[k] = State[k] end
    pcall(function() writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
end

local function LoadConfig(name)
    local ok2, content = pcall(function() return readfile(CONFIG_FOLDER .. "/" .. name .. ".json") end)
    if not ok2 then return false end
    local ok3, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok3 then return false end
    for k, v in pairs(data) do State[k] = v end
    RefreshAllUI()
    return true
end

local function ListConfigs()
    local files = {}
    pcall(function()
        for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
            local name = f:match("([^/\\_][^/\\]+)%.json$")
            if name then table.insert(files, name) end
        end
    end)
    return files
end

local function GetAutoLoad()
    local ok2, c = pcall(function() return readfile(AUTOLOAD_FILE) end)
    if not ok2 or not c then return nil end
    c = c:match("^%s*(.-)%s*$") -- trim whitespace/newlines
    return c ~= "" and c or nil
end

local function SetAutoLoad(name)
    pcall(function() writefile(AUTOLOAD_FILE, name or "") end)
end

-- ============================================================
-- CONFIG TAB UI
-- ============================================================
local RefreshConfigList
do
    local configTab = tabFrames["Config"]
    local configSection = MakeSection(configTab, "SAVE / LOAD", 1)

    local nameInputRow = Instance.new("Frame")
    nameInputRow.Size = UDim2.new(1, 0, 0, 46)
    nameInputRow.BackgroundColor3 = GetTheme("Main")
    nameInputRow.BorderSizePixel = 0
    nameInputRow.LayoutOrder = 1
    nameInputRow.Parent = configSection
    Instance.new("UICorner", nameInputRow).CornerRadius = UDim.new(0, 5)
    local nameInputLbl = Instance.new("TextLabel")
    nameInputLbl.Text = "Config Name"
    nameInputLbl.Size = UDim2.new(1, -10, 0, 16)
    nameInputLbl.Position = UDim2.new(0, 10, 0, 4)
    nameInputLbl.BackgroundTransparency = 1
    nameInputLbl.TextColor3 = Color3.fromRGB(160, 155, 185)
    nameInputLbl.TextSize = 10
    nameInputLbl.Font = Enum.Font.Gotham
    nameInputLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameInputLbl.Parent = nameInputRow
    local nameInput = Instance.new("TextBox")
    nameInput.PlaceholderText = "my config..."
    nameInput.Text = ""
    nameInput.Size = UDim2.new(1, -20, 0, 20)
    nameInput.Position = UDim2.new(0, 10, 0, 22)
    nameInput.BackgroundColor3 = GetTheme("Background")
    nameInput.TextColor3 = Color3.fromRGB(210, 205, 235)
    nameInput.PlaceholderColor3 = Color3.fromRGB(100, 95, 125)
    nameInput.TextSize = 11
    nameInput.Font = Enum.Font.Gotham
    nameInput.TextXAlignment = Enum.TextXAlignment.Left
    nameInput.BorderSizePixel = 0
    nameInput.ClearTextOnFocus = false
    nameInput.Parent = nameInputRow
    Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 4)
    local nip = Instance.new("UIPadding", nameInput)
    nip.PaddingLeft = UDim.new(0, 6)

    local saveRow = MakeRow(configSection, 2)
    local saveBtn = Instance.new("TextButton")
    saveBtn.Text = "[S] Save / Override Config"
    saveBtn.Size = UDim2.new(1, -20, 0, 22)
    saveBtn.Position = UDim2.new(0, 10, 0.5, -11)
    saveBtn.BackgroundColor3 = GetTheme("Main")
    saveBtn.TextColor3 = Color3.fromRGB(120, 220, 120)
    saveBtn.TextSize = 11
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.BorderSizePixel = 0
    saveBtn.Parent = saveRow
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
    local saveBtnStroke = Instance.new("UIStroke", saveBtn)
    saveBtnStroke.Color = GetTheme("Outline")
    saveBtnStroke.Thickness = 1
    saveBtn.MouseEnter:Connect(function() saveBtnStroke.Color = Color3.fromRGB(120, 220, 120) end)
    saveBtn.MouseLeave:Connect(function() saveBtnStroke.Color = GetTheme("Outline") end)

    local listSection = MakeSection(configTab, "SAVED CONFIGS", 2)
    local selectedConfig = nil
    local configListRows = {}

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Text = ""
    statusLbl.Size = UDim2.new(1, 0, 0, 20)
    statusLbl.BackgroundTransparency = 1
    statusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
    statusLbl.TextSize = 10
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextXAlignment = Enum.TextXAlignment.Center
    statusLbl.LayoutOrder = 3
    statusLbl.Parent = configSection

    local function SetStatus(msg, isGood)
        statusLbl.Text = msg
        statusLbl.TextColor3 = isGood and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 100, 100)
        task.delay(2.5, function() statusLbl.Text = "" end)
    end

    local actionRow = Instance.new("Frame")
    actionRow.Size = UDim2.new(1, 0, 0, 30)
    actionRow.BackgroundTransparency = 1
    actionRow.LayoutOrder = 4
    actionRow.Parent = configSection
    local actionLayout = Instance.new("UIListLayout", actionRow)
    actionLayout.FillDirection = Enum.FillDirection.Horizontal
    actionLayout.Padding = UDim.new(0, 6)

    local function MakeActionBtn(text, color, order)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Size = UDim2.new(0, 130, 1, 0)
        btn.BackgroundColor3 = GetTheme("Main")
        btn.TextColor3 = color
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.LayoutOrder = order
        btn.Parent = actionRow
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local s = Instance.new("UIStroke", btn)
        s.Color = GetTheme("Outline")
        s.Thickness = 1
        btn.MouseEnter:Connect(function() s.Color = color end)
        btn.MouseLeave:Connect(function() s.Color = GetTheme("Outline") end)
        return btn
    end

    local loadBtn = MakeActionBtn("Load Selected", Color3.fromRGB(120, 180, 255), 1)
    local deleteBtn = MakeActionBtn("Delete Selected", Color3.fromRGB(220, 100, 100), 2)

    local autoLoadSection = MakeSection(configTab, "AUTO-LOAD", 3)
    local autoLoadRow = MakeRow(autoLoadSection, 1)
    local autoLoadLbl = Instance.new("TextLabel")
    autoLoadLbl.Text = "Auto-Load on Start:  " .. (GetAutoLoad() or "None")
    autoLoadLbl.Size = UDim2.new(0.7, 0, 1, 0)
    autoLoadLbl.Position = UDim2.new(0, 10, 0, 0)
    autoLoadLbl.BackgroundTransparency = 1
    autoLoadLbl.TextColor3 = Color3.fromRGB(200, 195, 220)
    autoLoadLbl.TextSize = 10
    autoLoadLbl.Font = Enum.Font.Gotham
    autoLoadLbl.TextXAlignment = Enum.TextXAlignment.Left
    autoLoadLbl.Parent = autoLoadRow
    local setAutoBtn = Instance.new("TextButton")
    setAutoBtn.Text = "Set"
    setAutoBtn.Size = UDim2.new(0, 40, 0, 20)
    setAutoBtn.Position = UDim2.new(1, -90, 0.5, -10)
    setAutoBtn.BackgroundColor3 = GetTheme("Accent")
    setAutoBtn.TextColor3 = Color3.fromRGB(255,255,255)
    setAutoBtn.TextSize = 10
    setAutoBtn.Font = Enum.Font.GothamBold
    setAutoBtn.BorderSizePixel = 0
    setAutoBtn.Parent = autoLoadRow
    Instance.new("UICorner", setAutoBtn).CornerRadius = UDim.new(0, 4)
    local clearAutoBtn = Instance.new("TextButton")
    clearAutoBtn.Text = "Clear"
    clearAutoBtn.Size = UDim2.new(0, 40, 0, 20)
    clearAutoBtn.Position = UDim2.new(1, -46, 0.5, -10)
    clearAutoBtn.BackgroundColor3 = GetTheme("Outline")
    clearAutoBtn.TextColor3 = Color3.fromRGB(200, 195, 220)
    clearAutoBtn.TextSize = 10
    clearAutoBtn.Font = Enum.Font.GothamBold
    clearAutoBtn.BorderSizePixel = 0
    clearAutoBtn.Parent = autoLoadRow
    Instance.new("UICorner", clearAutoBtn).CornerRadius = UDim.new(0, 4)

    RefreshConfigList = function()
        for _, r in ipairs(configListRows) do r:Destroy() end
        configListRows = {}
        selectedConfig = nil
        local configs = ListConfigs()
        local autoload = GetAutoLoad()
        for i, name in ipairs(configs) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 26)
            row.BackgroundColor3 = GetTheme("Background")
            row.TextColor3 = Color3.fromRGB(180, 175, 210)
            row.TextSize = 11
            row.Font = Enum.Font.Gotham
            row.Text = (autoload == name and "[*]  " or "    ") .. name
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = listSection
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            local rp = Instance.new("UIPadding", row)
            rp.PaddingLeft = UDim.new(0, 8)
            local rs = Instance.new("UIStroke", row)
            rs.Color = GetTheme("Outline")
            rs.Thickness = 1
            table.insert(configListRows, row)
            row.MouseButton1Click:Connect(function()
                selectedConfig = name
                nameInput.Text = name
                for _, r2 in ipairs(configListRows) do
                    TweenService:Create(r2, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Background")}):Play()
                end
                TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Main")}):Play()
                rs.Color = GetTheme("Accent")
            end)
        end
        if #configs == 0 then
            local empty = Instance.new("TextLabel")
            empty.Text = "No configs saved yet."
            empty.Size = UDim2.new(1, 0, 0, 26)
            empty.BackgroundTransparency = 1
            empty.TextColor3 = Color3.fromRGB(100, 95, 125)
            empty.TextSize = 10
            empty.Font = Enum.Font.Gotham
            empty.LayoutOrder = 1
            empty.Parent = listSection
            table.insert(configListRows, empty)
        end
    end

    saveBtn.MouseButton1Click:Connect(function()
        local name = nameInput.Text:match("^%s*(.-)%s*$")
        if name == "" then SetStatus("Enter a config name first!", false) return end
        SaveConfig(name)
        SetStatus("Saved: " .. name, true)
        RefreshConfigList()
    end)

    loadBtn.MouseButton1Click:Connect(function()
        if not selectedConfig then SetStatus("Select a config first!", false) return end
        local ok2 = LoadConfig(selectedConfig)
        SetStatus(ok2 and ("Loaded: " .. selectedConfig) or "Failed to load!", ok2)
    end)

    deleteBtn.MouseButton1Click:Connect(function()
        if not selectedConfig then SetStatus("Select a config first!", false) return end
        pcall(function() delfile(CONFIG_FOLDER .. "/" .. selectedConfig .. ".json") end)
        if GetAutoLoad() == selectedConfig then SetAutoLoad("") end
        SetStatus("Deleted: " .. selectedConfig, true)
        selectedConfig = nil
        RefreshConfigList()
    end)

    setAutoBtn.MouseButton1Click:Connect(function()
        if not selectedConfig then SetStatus("Select a config first!", false) return end
        SetAutoLoad(selectedConfig)
        autoLoadLbl.Text = "Auto-Load on Start:  " .. selectedConfig
        SetStatus("Auto-load set to: " .. selectedConfig, true)
        RefreshConfigList()
    end)

    clearAutoBtn.MouseButton1Click:Connect(function()
        SetAutoLoad("")
        autoLoadLbl.Text = "Auto-Load on Start:  None"
        RefreshConfigList()
    end)

    pcall(RefreshConfigList)
end

-- ============================================================
-- INFO TAB
-- ============================================================
do
    local infoTab = tabFrames["Info"]
    local ReplicaController
    pcall(function()
        ReplicaController = require(game:GetService("ReplicatedStorage"):WaitForChild("ReplicaController", 10))
    end)

    local function GetData()
        if _G.Profile and _G.Profile.Data then
            return _G.Profile.Data
        end
        return nil
    end

    local function MakeInfoRow(parent, labelText, order)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
        row.BackgroundColor3 = GetTheme("Main")
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
        local lbl = Instance.new("TextLabel")
        lbl.Text = labelText
        lbl.Size = UDim2.new(0.45, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(140, 135, 170)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        local val = Instance.new("TextLabel")
        val.Text = "--"
        val.Size = UDim2.new(0.5, -10, 1, 0)
        val.Position = UDim2.new(0.5, 0, 0, 0)
        val.BackgroundTransparency = 1
        val.TextColor3 = Color3.fromRGB(210, 205, 235)
        val.TextSize = 10
        val.Font = Enum.Font.GothamBold
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = row
        return val
    end

    -- STATS SECTION
    local statsSection = MakeSection(infoTab, "PROFILE STATS", 1)
    local coinsVal    = MakeInfoRow(statsSection, "Coins", 1)
    local coinsCpsVal = MakeInfoRow(statsSection, "Coins/s", 2)
    local gemsVal     = MakeInfoRow(statsSection, "Gems", 3)
    local rebirthsVal = MakeInfoRow(statsSection, "Rebirths", 4)
    local rollsVal    = MakeInfoRow(statsSection, "Rolls", 5)

    -- INDEX SECTION
    local indexSection = MakeSection(infoTab, "INDEX", 2)
    local indexVal = MakeInfoRow(indexSection, "Baddies Found", 1)

    -- BUFFS SECTION
    local buffsSection = MakeSection(infoTab, "ACTIVE BUFFS", 3)
    local buffsVal = Instance.new("TextLabel")
    buffsVal.Text = "None"
    buffsVal.Size = UDim2.new(1, -20, 0, 0)
    buffsVal.AutomaticSize = Enum.AutomaticSize.Y
    buffsVal.Position = UDim2.new(0, 10, 0, 0)
    buffsVal.BackgroundTransparency = 1
    buffsVal.TextColor3 = Color3.fromRGB(180, 220, 180)
    buffsVal.TextSize = 10
    buffsVal.Font = Enum.Font.Gotham
    buffsVal.TextXAlignment = Enum.TextXAlignment.Left
    buffsVal.TextWrapped = true
    buffsVal.LayoutOrder = 1
    buffsVal.Parent = buffsSection

    -- HOTBAR SECTION
    local hotbarSection = MakeSection(infoTab, "HOTBAR", 4)
    local hotbarVal = Instance.new("TextLabel")
    hotbarVal.Text = "Empty"
    hotbarVal.Size = UDim2.new(1, -20, 0, 0)
    hotbarVal.AutomaticSize = Enum.AutomaticSize.Y
    hotbarVal.Position = UDim2.new(0, 10, 0, 0)
    hotbarVal.BackgroundTransparency = 1
    hotbarVal.TextColor3 = Color3.fromRGB(180, 180, 220)
    hotbarVal.TextSize = 10
    hotbarVal.Font = Enum.Font.Gotham
    hotbarVal.TextXAlignment = Enum.TextXAlignment.Left
    hotbarVal.TextWrapped = true
    hotbarVal.LayoutOrder = 1
    hotbarVal.Parent = hotbarSection

    -- LAST ROLL SECTION
    local lastRollSection = MakeSection(infoTab, "LAST ROLL", 5)
    local lastRollName   = MakeInfoRow(lastRollSection, "Baddie", 1)
    local lastRollRarity = MakeInfoRow(lastRollSection, "Rarity", 2)
    local lastRollMut    = MakeInfoRow(lastRollSection, "Mutation", 3)

    -- Hook into roll result to update last roll
    local origHook = State._lastRollHook
    local function UpdateLastRoll(name, rarity, mutation, isNew)
        lastRollName.Text = name or "--"
        lastRollRarity.Text = rarity or "--"
        lastRollMut.Text = mutation or "Normal"
    end
    State._UpdateLastRoll = UpdateLastRoll
    State._SeenRolls = State._SeenRolls or {}

task.spawn(function()
    while true do
        if State._PendingRoll then
            local r = State._PendingRoll
            State._PendingRoll = nil
            pcall(function() UpdateLastRoll(r.name, r.rarity, r.mutation, r.isNew) end)
        end

        task.wait(2)

-- Coins, Rebirths, Rolls from leaderstats
        pcall(function()
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if not ls then return end
            local coins    = ls:FindFirstChild("Coins")
            local rebirths = ls:FindFirstChild("Rebirths")
            local rolls    = ls:FindFirstChild("Rolls")
            if coins    then coinsVal.Text    = FormatCoins(ParseCoins(tostring(coins.Value))) end
            coinsCpsVal.Text = FormatCoins(State.CoinsPerSecond) .. "/s"
            if rebirths then rebirthsVal.Text = tostring(rebirths.Value) end
            if rolls    then rollsVal.Text    = tostring(rolls.Value) end
        end)

        -- Gems: read from the gem HUD frame
        pcall(function()
            local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
            local gemFrame = main and main:FindFirstChild("gem")
            if gemFrame then
                for _, child in pairs(gemFrame:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Text ~= "" then
                        local stripped = tostring(child.Text):gsub("[^%d,%.KkMmBbTt]", "")
                        if stripped ~= "" then
                            gemsVal.Text = child.Text
                            break
                        end
                    end
                end
            end
        end)

-- Baddies Found: read CollectedCount label directly from Index frame
        pcall(function()
            local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
            local indexFrame = main and main:FindFirstChild("Index")
            if not indexFrame then return end
            local lbl = indexFrame:FindFirstChild("CollectedCount")
            if lbl then indexVal.Text = tostring(lbl.Text) end
        end)

        -- Buffs
        pcall(function()
            local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
            local buffsFrame = main and main:FindFirstChild("BUFFS")
            if not buffsFrame then return end
            local buffList = {}
            for _, b in pairs(buffsFrame:GetChildren()) do
                if (b:IsA("Frame") or b:IsA("TextLabel")) and b.Name ~= "" and b.Name ~= "Template" then
                    table.insert(buffList, b.Name)
                end
            end
            buffsVal.Text = #buffList > 0 and table.concat(buffList, "\n") or "None"
        end)

        -- Hotbar
        pcall(function()
            local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
            local diceFrame = main and main:FindFirstChild("Dice")
            if not diceFrame then return end
            local container = diceFrame:FindFirstChild("Container")
            if not container then return end
            local hotbarList = {}
            for _, f in pairs(container:GetChildren()) do
                if f:IsA("Frame") and f.Name ~= "" then
                    table.insert(hotbarList, f.Name)
                end
            end
            hotbarVal.Text = #hotbarList > 0 and table.concat(hotbarList, "\n") or "Empty"
        end)

        end
    end)
end

-- ============================================================
-- FUSE TAB v3 — multi-mutation group selection
-- Add to tabDefs: { name = "Fuse", icon = "⚗️", order = 11 },
-- Paste after your other tab do...end blocks
-- ============================================================

do
    local fuseTab = tabFrames["Fuse"]

    -- ============================================================
    -- REMOTES
    -- ============================================================
    local storeBaddie, removeBaddie, fuseRemote, collectFuse
    pcall(function()
        local Events = ReplicatedStorage:WaitForChild("Events", 10)
        storeBaddie  = Events:WaitForChild("storeBaddie", 10)
        removeBaddie = Events:WaitForChild("removeBaddie", 10)
        fuseRemote   = Events:WaitForChild("Fuse", 10)
        collectFuse  = Events:WaitForChild("CollectFuse", 10)
    end)

    -- ============================================================
    -- DATA ACCESS
    -- ============================================================
    local RC = nil
    pcall(function()
        RC = require(ReplicatedStorage:WaitForChild("ReplicaController", 10))
    end)

    local function GetReplica()
        if not RC then return nil end
        for _, replica in pairs(RC._replicas) do
            if replica.Class == "PlayerProfile" then return replica end
        end
        return nil
    end

    local function GetData()
        local r = GetReplica()
        return r and r.Data or nil
    end

    local function GetInventory()
        local d = GetData()
        return (d and d.inv and d.inv.unique) or {}
    end

    local function GetStoredFuse()
        local d = GetData()
        return (d and d.storedFuse) or {}
    end

    local function GetMergeData()
        local d = GetData()
        return d and d.mergedata
    end

    local function GetModifier(data)
        return data.modifier or "Normal"
    end

    local function GetMutation(data)
        return (data.m and data.m[1]) or "Normal"
    end

    -- ============================================================
    -- STATE
    -- ============================================================
    State.AutoFuse  = false
    State.FuseMode  = "Big"

    -- selectedGroups: list of { n, modifier, mutation, count, uids[] }
    -- all must share the same n + modifier, but can differ in mutation
    local selectedGroups = {}
    local fuseRows       = {}
    local rowGroupMap    = {} -- row → entry, for toggling
    local fuseRunning    = false

    local function TotalSelectedCount()
        local total = 0
        for _, g in ipairs(selectedGroups) do total += g.count end
        return total
    end

    local function IsGroupSelected(entry)
        for _, g in ipairs(selectedGroups) do
            if g.n == entry.n and g.modifier == entry.modifier and g.mutation == entry.mutation then
                return true
            end
        end
        return false
    end

    local function GetSelectedBaddieName()
        if #selectedGroups > 0 then return selectedGroups[1].n end
        return nil
    end

    local function GetSelectedModifier()
        if #selectedGroups > 0 then return selectedGroups[1].modifier end
        return nil
    end

    -- ============================================================
    -- SCAN
    -- ============================================================
    local function ScanInventory()
        local inv = GetInventory()
        local groups = {}
        for uid, data in pairs(inv) do
            local name     = data.n or "?"
            local modifier = GetModifier(data)
            local mutation = GetMutation(data)
            local key      = name .. "|" .. modifier .. "|" .. mutation
            if not groups[key] then
                groups[key] = { n = name, modifier = modifier, mutation = mutation, count = 0, uids = {} }
            end
            groups[key].count += 1
            table.insert(groups[key].uids, uid)
        end

        local modOrder = { Normal = 1, Big = 2, Huge = 3 }
        local list = {}
        for _, v in pairs(groups) do table.insert(list, v) end
        table.sort(list, function(a, b)
            if a.n ~= b.n then return a.n < b.n end
            if a.modifier ~= b.modifier then
                return (modOrder[a.modifier] or 0) < (modOrder[b.modifier] or 0)
            end
            return a.count > b.count
        end)
        return list
    end

    local function ClearMachine()
        local stored = GetStoredFuse()
        for uid, _ in pairs(stored) do
            pcall(function() removeBaddie:InvokeServer(uid) end)
            task.wait(0.25)
        end
    end

    -- ============================================================
    -- UI SECTIONS
    -- ============================================================
    local controlSection   = MakeSection(fuseTab, "FUSE CONTROL", 1)
    local inventorySection = MakeSection(fuseTab, "INVENTORY — SELECT GROUPS (same baddie)", 2)
    local statusSection    = MakeSection(fuseTab, "STATUS", 3)

    MakeDropdown(controlSection, "Fuse Mode", {"Big", "Huge"}, "FuseMode", 1, function()
        selectedGroups = {}
    end)

    local scanRow = MakeRow(controlSection, 2)
    local scanBtn = Instance.new("TextButton")
    scanBtn.Text = "🔍  Scan Inventory"
    scanBtn.Size = UDim2.new(1, -20, 0, 22)
    scanBtn.Position = UDim2.new(0, 10, 0.5, -11)
    scanBtn.BackgroundColor3 = GetTheme("Main")
    scanBtn.TextColor3 = Color3.fromRGB(180, 220, 255)
    scanBtn.TextSize = 11
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.BorderSizePixel = 0
    scanBtn.Parent = scanRow
    Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 4)
    local scanStroke = Instance.new("UIStroke", scanBtn)
    scanStroke.Color = GetTheme("Outline")
    scanStroke.Thickness = 1
    scanBtn.MouseEnter:Connect(function() scanStroke.Color = Color3.fromRGB(180, 220, 255) end)
    scanBtn.MouseLeave:Connect(function() scanStroke.Color = GetTheme("Outline") end)

    MakeToggle(controlSection, "Auto Fuse (uses selection)", "AutoFuse", 3)

    State.AutoBestFuse = false
    State.MinMutationChance = 60
    MakeToggle(controlSection, "Auto Best Fuse (fully automatic)", "AutoBestFuse", 4)
    MakeSlider(controlSection, "Min Mutation Chance %", "MinMutationChance", 20, 100, 5)
    State.AutoBestFuseMixMutations = false
    MakeToggle(controlSection, "Mix Mutations (fill slots with others)", "AutoBestFuseMixMutations", 6)

    -- ============================================================
    -- STATUS + TIMER
    -- ============================================================
    local statusRow = MakeRow(statusSection, 1)
    statusRow.Size = UDim2.new(1, 0, 0, 56)
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Text = "Idle. Scan inventory and select groups."
    statusLbl.Size = UDim2.new(1, -20, 1, 0)
    statusLbl.Position = UDim2.new(0, 10, 0, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.TextColor3 = Color3.fromRGB(160, 155, 190)
    statusLbl.TextSize = 10
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextWrapped = true
    statusLbl.Parent = statusRow

    local timerRow = MakeRow(statusSection, 2)
    local timerLbl = Instance.new("TextLabel")
    timerLbl.Text = ""
    timerLbl.Size = UDim2.new(1, -20, 1, 0)
    timerLbl.Position = UDim2.new(0, 10, 0, 0)
    timerLbl.BackgroundTransparency = 1
    timerLbl.TextColor3 = Color3.fromRGB(200, 180, 100)
    timerLbl.TextSize = 11
    timerLbl.Font = Enum.Font.GothamBold
    timerLbl.TextXAlignment = Enum.TextXAlignment.Left
    timerLbl.Parent = timerRow


    local function SetStatus(msg, color)
        statusLbl.Text = msg
        statusLbl.TextColor3 = color or Color3.fromRGB(160, 155, 190)
    end

    local collectBtnRow = MakeRow(statusSection, 3)
    local collectBtn = Instance.new("TextButton")
    collectBtn.Text = "📦  Collect Fuse Result"
    collectBtn.Size = UDim2.new(1, -20, 0, 22)
    collectBtn.Position = UDim2.new(0, 10, 0.5, -11)
    collectBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
    collectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    collectBtn.TextSize = 11
    collectBtn.Font = Enum.Font.GothamBold
    collectBtn.BorderSizePixel = 0
    collectBtn.Visible = false
    collectBtn.Parent = collectBtnRow
    Instance.new("UICorner", collectBtn).CornerRadius = UDim.new(0, 4)
    local collectStroke = Instance.new("UIStroke", collectBtn)
    collectStroke.Color = Color3.fromRGB(80, 200, 80)
    collectStroke.Thickness = 1
    collectBtn.MouseButton1Click:Connect(function()
    if not collectFuse then
        SetStatus("❌ Remote not found!", Color3.fromRGB(220, 100, 100))
        return
    end
    collectBtn.Text = "Collecting..."
    collectBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    collectBtn.Active = false
    task.spawn(function()
        local ok, res = pcall(function() return collectFuse:InvokeServer() end)
        if ok and type(res) == "table" then
            if res.success and res.outcome and res.outcome.success then
                local nd = res.outcome.newData
                SetStatus("✅ Got: " .. string.upper(nd.modifier or "?") .. " " .. (nd.n or "?") .. "!", Color3.fromRGB(120, 220, 120))
            elseif res.success then
                SetStatus("❌ Fuse RNG failed — no upgrade.", Color3.fromRGB(220, 100, 100))
            else
                SetStatus("❌ Server rejected: " .. tostring(res.reason or "?"), Color3.fromRGB(220, 100, 100))
            end
        else
            SetStatus("❌ Collect call failed: " .. tostring(res), Color3.fromRGB(220, 100, 100))
        end
        -- Always reset button no matter what happened
        collectBtn.Text = "📦  Collect Fuse Result"
        collectBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
        collectBtn.Active = true
        collectBtn.Visible = false
        end)
    end)


    local function UpdateSelectionStatus()
        if #selectedGroups == 0 then
            SetStatus("Idle. Tap rows to select groups (same baddie, any mutation).", Color3.fromRGB(160, 155, 190))
            return
        end
        local total = math.min(TotalSelectedCount(), 5)
        local chance = total * 20
        local mutList = {}
        for _, g in ipairs(selectedGroups) do
            table.insert(mutList, g.mutation .. " x" .. g.count)
        end
        SetStatus(
            "✅ " .. selectedGroups[1].n .. " | " .. table.concat(mutList, " + ")
            .. "\n→ Using " .. total .. " baddies | " .. chance .. "% fuse chance",
            chance >= 100 and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 180, 60)
        )
    end

    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                local md = GetMergeData()
                if md and md.timestamp and md.outcome then
                    local dur = md.duration or 900
                    local rem = md.timestamp + dur - os.time()
                    if rem > 0 then
                        timerLbl.Text = string.format("⏱ Fuse ready in: %d:%02d", math.floor(rem/60), rem%60)
                        collectBtn.Visible = false
                    else
                        timerLbl.Text = "✅ Ready to collect!"
                        collectBtn.Visible = true
                    end
                else
                    timerLbl.Text = ""
                end
            end)
        end
    end)

    -- ============================================================
    -- INVENTORY RENDERER
    -- ============================================================
    local function RenderInventory(list)
        for _, r in ipairs(fuseRows) do pcall(function() r:Destroy() end) end
        fuseRows = {}
        rowGroupMap = {}
        selectedGroups = {}

        if #list == 0 then
            local lbl = Instance.new("TextLabel")
            lbl.Text = "No baddies found."
            lbl.Size = UDim2.new(1, 0, 0, 26)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(100, 95, 125)
            lbl.TextSize = 10
            lbl.Font = Enum.Font.Gotham
            lbl.LayoutOrder = 1
            lbl.Parent = inventorySection
            table.insert(fuseRows, lbl)
            return
        end

        local requiredMod = State.FuseMode == "Big" and "Normal" or "Big"

        for i, entry in ipairs(list) do
            local isCompatible = (entry.modifier == requiredMod)

            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 34)
            row.BackgroundColor3 = isCompatible and GetTheme("Main") or GetTheme("Background")
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Text = ""
            row.AutoButtonColor = false
            row.Parent = inventorySection
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
            local rs = Instance.new("UIStroke", row)
            rs.Color = GetTheme("Outline")
            rs.Thickness = 1

            -- Count badge
            local countBadge = Instance.new("TextLabel")
            countBadge.Text = "x" .. entry.count
            countBadge.Size = UDim2.new(0, 28, 0, 20)
            countBadge.Position = UDim2.new(0, 6, 0.5, -10)
            countBadge.BackgroundColor3 = entry.count >= 5
                and Color3.fromRGB(60, 190, 90)
                or (entry.count >= 3
                    and Color3.fromRGB(210, 170, 30)
                    or Color3.fromRGB(180, 55, 55))
            countBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            countBadge.TextSize = 10
            countBadge.Font = Enum.Font.GothamBold
            countBadge.BorderSizePixel = 0
            countBadge.Parent = row
            Instance.new("UICorner", countBadge).CornerRadius = UDim.new(0, 4)

            -- Name
            local modTag = entry.modifier ~= "Normal" and (" [" .. entry.modifier:upper() .. "]") or ""
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = entry.n .. modTag
            nameLbl.Size = UDim2.new(0.52, 0, 1, 0)
            nameLbl.Position = UDim2.new(0, 40, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3 = isCompatible and Color3.fromRGB(210, 205, 235) or Color3.fromRGB(90, 85, 110)
            nameLbl.TextSize = 10
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row

            -- Mutation
            local mutLbl = Instance.new("TextLabel")
            mutLbl.Text = entry.mutation
            mutLbl.Size = UDim2.new(0.38, 0, 1, 0)
            mutLbl.Position = UDim2.new(0.52, 40, 0, 0)
            mutLbl.BackgroundTransparency = 1
            mutLbl.TextColor3 = entry.mutation ~= "Normal"
                and Color3.fromRGB(180, 140, 255)
                or Color3.fromRGB(90, 85, 110)
            mutLbl.TextSize = 10
            mutLbl.Font = Enum.Font.Gotham
            mutLbl.TextXAlignment = Enum.TextXAlignment.Left
            mutLbl.Parent = row

            -- Wrong size label
            if not isCompatible then
                local tag = Instance.new("TextLabel")
                tag.Text = entry.modifier
                tag.Size = UDim2.new(0, 40, 0, 14)
                tag.AnchorPoint = Vector2.new(1, 0.5)
                tag.Position = UDim2.new(1, -6, 0.5, 0)
                tag.BackgroundColor3 = Color3.fromRGB(80, 35, 35)
                tag.TextColor3 = Color3.fromRGB(200, 80, 80)
                tag.TextSize = 9
                tag.Font = Enum.Font.Gotham
                tag.BorderSizePixel = 0
                tag.Parent = row
                Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 3)
            end

            if isCompatible then
                rowGroupMap[row] = entry

                local function RefreshRowVisual(r, stroke, isSelected)
                    if isSelected then
                        TweenService:Create(r, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Accent")}):Play()
                        stroke.Color = Color3.fromRGB(220, 200, 255)
                    else
                        TweenService:Create(r, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Main")}):Play()
                        stroke.Color = GetTheme("Outline")
                    end
                end

                row.MouseEnter:Connect(function()
                    if not IsGroupSelected(entry) then
                        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Background")}):Play()
                    end
                end)
                row.MouseLeave:Connect(function()
                    if not IsGroupSelected(entry) then
                        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = GetTheme("Main")}):Play()
                    end
                end)

                local capturedEntry = entry
                row.MouseButton1Click:Connect(function()
                    -- Deselect if already selected
                    if IsGroupSelected(capturedEntry) then
                        for idx, g in ipairs(selectedGroups) do
                            if g.n == capturedEntry.n and g.modifier == capturedEntry.modifier and g.mutation == capturedEntry.mutation then
                                table.remove(selectedGroups, idx)
                                break
                            end
                        end
                        -- Restore original count badge
                        countBadge.Text = "x" .. capturedEntry.count
                        countBadge.BackgroundColor3 = capturedEntry.count >= 5
                            and Color3.fromRGB(60, 190, 90)
                            or (capturedEntry.count >= 3
                                and Color3.fromRGB(210, 170, 30)
                                or Color3.fromRGB(180, 55, 55))
                        RefreshRowVisual(row, rs, false)
                        UpdateSelectionStatus()
                        return
                    end

                    -- Hard cap check
                    local currentTotal = TotalSelectedCount()
                    if currentTotal >= 5 then
                        SetStatus("⚠ Already at 5 baddies (100% chance). Deselect one first.", Color3.fromRGB(220, 160, 60))
                        return
                    end

                    -- Must match existing selection's baddie name + modifier
                    local selName = GetSelectedBaddieName()
                    local selMod  = GetSelectedModifier()
                    if selName and (selName ~= capturedEntry.n or selMod ~= capturedEntry.modifier) then
                        SetStatus("⚠ Must select same baddie type! Deselect current to switch.", Color3.fromRGB(220, 100, 100))
                        return
                    end

                    -- How many slots are left and how many can we actually use
                    local remaining = 5 - currentTotal
                    local usable = math.min(capturedEntry.count, remaining)

                    local capped = {
                        n        = capturedEntry.n,
                        modifier = capturedEntry.modifier,
                        mutation = capturedEntry.mutation,
                        count    = usable,
                        uids     = {}
                    }
                    for i = 1, usable do
                        table.insert(capped.uids, capturedEntry.uids[i])
                    end
                    table.insert(selectedGroups, capped)

                    -- Update badge to show actual usable count (e.g. "x1/3")
                    if usable < capturedEntry.count then
                        countBadge.Text = "x" .. usable .. "/" .. capturedEntry.count
                        countBadge.BackgroundColor3 = Color3.fromRGB(130, 80, 200)
                    else
                        countBadge.Text = "x" .. usable
                        countBadge.BackgroundColor3 = Color3.fromRGB(60, 190, 90)
                    end

                    RefreshRowVisual(row, rs, true)
                    UpdateSelectionStatus()
                end)
            end

            table.insert(fuseRows, row)
        end

        SetStatus("Found " .. #list .. " group(s). Tap rows to select (same baddie, mix mutations ok).", Color3.fromRGB(160, 155, 190))
    end


    local function FindBestGroup(requiredMod)
        local inv = GetInventory()

        local BaddieData2 = {}
        pcall(function()
            BaddieData2 = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("BaddieData"))
        end)

        local function GetBaseCash(name)
            if BaddieData2 and BaddieData2[name] then
                return tonumber(BaddieData2[name].BaseCash) or 0
            end
            return 0
        end

        local minMutCount = math.max(1, math.floor(State.MinMutationChance / 20))

        local byName  = {}
        local byExact = {}

        for uid, data in pairs(inv) do
            local mod      = GetModifier(data)
            local mutation = GetMutation(data)
            if mod ~= requiredMod then continue end

            local cash = GetBaseCash(data.n)
            local nKey = data.n .. "|" .. mod
            if not byName[nKey] then
                byName[nKey] = { n = data.n, modifier = mod, cash = cash, uids = {}, byMutation = {} }
            end
            table.insert(byName[nKey].uids, uid)
            if not byName[nKey].byMutation[mutation] then
                byName[nKey].byMutation[mutation] = {}
            end
            table.insert(byName[nKey].byMutation[mutation], uid)

            local eKey = data.n .. "|" .. mod .. "|" .. mutation
            if not byExact[eKey] then
                byExact[eKey] = { n = data.n, modifier = mod, mutation = mutation, cash = cash, uids = {} }
            end
            table.insert(byExact[eKey].uids, uid)
        end

        local nameList = {}
        for _, g in pairs(byName) do table.insert(nameList, g) end
        table.sort(nameList, function(a, b) return a.cash > b.cash end)

        for _, group in ipairs(nameList) do
            local totalOwned = #group.uids
            if totalOwned == 0 then continue end
            local useCount = math.min(totalOwned, 5)

            -- Find mutation with most copies
            local bestMut, bestMutUids = "Normal", {}
            for mut, uids in pairs(group.byMutation) do
                if #uids > #bestMutUids then
                    bestMut = mut
                    bestMutUids = uids
                end
            end

            local sameMutCount = math.min(#bestMutUids, 5)
            local effectiveCount = State.AutoBestFuseMixMutations and math.min(totalOwned, 5) or sameMutCount
            if effectiveCount < minMutCount then continue end -- doesn't meet threshold, try next

            -- Build groups: fill with best mutation first, then others
            local groups = {}
            local usedUIDs = {}
            local primaryUIDs = {}
            for i = 1, sameMutCount do
                table.insert(primaryUIDs, bestMutUids[i])
                usedUIDs[bestMutUids[i]] = true
            end
            table.insert(groups, { n = group.n, modifier = group.modifier, mutation = bestMut, uids = primaryUIDs })

            local remaining = useCount - sameMutCount
            if State.AutoBestFuseMixMutations and remaining > 0 then
                for mut, uids in pairs(group.byMutation) do
                    if mut == bestMut then continue end
                    for _, uid in ipairs(uids) do
                        if remaining <= 0 then break end
                        if not usedUIDs[uid] then
                            local found = false
                            for _, g2 in ipairs(groups) do
                                if g2.mutation == mut then
                                    table.insert(g2.uids, uid)
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                table.insert(groups, { n = group.n, modifier = group.modifier, mutation = mut, uids = {uid} })
                            end
                            usedUIDs[uid] = true
                            remaining -= 1
                        end
                    end
                end
            end

            local mutChance = sameMutCount * 20
            local reason = string.format("$%s/s | %d%% fuse | %d%% %s mutation",
                tostring(group.cash), useCount * 20, mutChance, bestMut)
            return groups, reason
        end

        -- Nothing meets threshold
        return nil, "No baddies meet the " .. State.MinMutationChance .. "% mutation threshold"
    end

    -- AUTO BEST FUSE LOOP
    task.spawn(function()
        local bestFuseRunning = false
        while true do
            task.wait(3)
            if not State.AutoBestFuse then bestFuseRunning = false continue end
            if bestFuseRunning then continue end
            if not storeBaddie or not fuseRemote or not collectFuse then
                SetStatus("⚠ [AutoBest] Remotes not found!", Color3.fromRGB(220, 100, 100))
                continue
            end

            bestFuseRunning = true
            local requiredMod = State.FuseMode == "Big" and "Normal" or "Big"

            -- Collect if timer expired
            local md = GetMergeData()
            if md and md.timestamp and md.outcome then
                local dur = md.duration or 900
                local rem = md.timestamp + dur - os.time()
                if rem > 0 then
                    SetStatus(string.format("⏱ [AutoBest] Waiting %d:%02d...", math.floor(rem/60), rem%60), Color3.fromRGB(200, 180, 100))
                    task.wait(rem + 2)
                end
                SetStatus("📦 [AutoBest] Collecting...", Color3.fromRGB(180, 220, 255))
                local ok, res = pcall(function() return collectFuse:InvokeServer() end)
                if ok and res and res.success then
                    if res.outcome and res.outcome.success then
                        local nd = res.outcome.newData
                        SetStatus("✅ Got: " .. string.upper(nd.modifier or "?") .. " " .. (nd.n or "?") .. "! Finding next...", Color3.fromRGB(120, 220, 120))
                    else
                        SetStatus("❌ [AutoBest] Fuse RNG failed. Finding next...", Color3.fromRGB(220, 100, 100))
                    end
                end
                task.wait(1.5)
            end

            local groups, reason = FindBestGroup(requiredMod)
            if not groups then
                SetStatus("⚠ [AutoBest] " .. reason .. " — retrying in 30s...", Color3.fromRGB(220, 160, 60))
                task.wait(30)
                bestFuseRunning = false
                continue
            end

            local allUIDs = {}
            local names = {}
            for _, g in ipairs(groups) do
                for _, uid in ipairs(g.uids) do table.insert(allUIDs, uid) end
                table.insert(names, g.mutation .. " x" .. #g.uids)
            end
            local useCount = math.min(#allUIDs, 5)

            SetStatus(
                "🔄 [AutoBest] " .. groups[1].n .. " | " .. table.concat(names, " + ") .. "\n→ " .. reason,
                Color3.fromRGB(180, 220, 255)
            )

            ClearMachine()
            task.wait(0.5)

            local inserted = 0
            for i = 1, useCount do
                local ok, result = pcall(function() return storeBaddie:InvokeServer(allUIDs[i]) end)
                if ok and result and result.success then inserted += 1 end
                task.wait(0.3)
            end

            if inserted == 0 then
                SetStatus("❌ [AutoBest] Failed to insert baddies!", Color3.fromRGB(220, 100, 100))
                bestFuseRunning = false
                continue
            end

            task.wait(0.5)
            local ok2, fuseResult = pcall(function() return fuseRemote:InvokeServer(State.FuseMode) end)
            if not ok2 or not fuseResult or not fuseResult.success then
                SetStatus("❌ [AutoBest] Fuse failed: " .. tostring(fuseResult and fuseResult.reason or "?"), Color3.fromRGB(220, 100, 100))
                bestFuseRunning = false
                continue
            end

            SetStatus(
                "✅ [AutoBest] Fusing " .. inserted .. "x " .. groups[1].n
                .. " → " .. State.FuseMode .. " | " .. reason .. " | Waiting...",
                Color3.fromRGB(120, 220, 120)
            )
            bestFuseRunning = false
        end
    end)


    scanBtn.MouseButton1Click:Connect(function()
        SetStatus("Scanning...", Color3.fromRGB(180, 220, 255))
        task.spawn(function()
            selectedGroups = {}
            local list = ScanInventory()
            RenderInventory(list)
        end)
    end)

end
-- ============================================================
-- FLOATING TOGGLE BUTTON (always visible)
-- ============================================================
do
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Text = "reidu ▲"
    toggleBtn.Size = UDim2.new(0, 90, 0, 24)
    toggleBtn.Position = UDim2.new(0, 12, 1, -36)
    toggleBtn.AnchorPoint = Vector2.new(0, 1)
    toggleBtn.BackgroundColor3 = HexToColor("141418")
    toggleBtn.TextColor3 = Color3.fromRGB(180, 140, 255)
    toggleBtn.TextSize = 11
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.ZIndex = 200
    toggleBtn.Parent = ScreenGui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
    local toggleStroke = Instance.new("UIStroke", toggleBtn)
    toggleStroke.Color = HexToColor("7C5CBF")
    toggleStroke.Thickness = 1

    -- Drag support for the toggle button itself
    local togDragging, togDragStart, togBtnStart = false, nil, nil
    local wasDragged = false

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            togDragging = true
            wasDragged = false
            togDragStart = input.Position
            togBtnStart = toggleBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if togDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local dx = input.Position.X - togDragStart.X
            local dy = input.Position.Y - togDragStart.Y
            if math.abs(dx) > 4 or math.abs(dy) > 4 then wasDragged = true end
            toggleBtn.Position = UDim2.new(
                togBtnStart.X.Scale, togBtnStart.X.Offset + dx,
                togBtnStart.Y.Scale, togBtnStart.Y.Offset + dy
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            togDragging = false
        end
    end)

    local function ToggleGUI()
        MainFrame.Visible = not MainFrame.Visible
        toggleBtn.Text = MainFrame.Visible and "reidu ▲" or "reidu ▼"
        toggleStroke.Color = MainFrame.Visible and HexToColor("7C5CBF") or HexToColor("3A3A50")
    end

    toggleBtn.MouseButton1Click:Connect(function()
        if wasDragged then return end -- ignore click if it was a drag
        ToggleGUI()
    end)

    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = HexToColor("1E1E2A")
        }):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = HexToColor("141418")
        }):Play()
    end)

    -- Ctrl key shortcut (in addition to Insert)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.LeftControl
        or input.KeyCode == Enum.KeyCode.RightControl then
            ToggleGUI()
        end
    end)
end

SwitchTab("Player")

-- ============================================================
-- TOAST SYSTEM
-- ============================================================
do
    local toastFrame = Instance.new("Frame")
    toastFrame.Size = UDim2.new(0, 240, 0, 36)
    toastFrame.AnchorPoint = Vector2.new(1, 0)
    toastFrame.Position = UDim2.new(1, -10, 1, 60)
    toastFrame.ClipsDescendants = false
    toastFrame.Active = false
    toastFrame.BackgroundColor3 = HexToColor("1A1A28")
    toastFrame.BorderSizePixel = 0
    toastFrame.ZIndex = 100
    toastFrame.Parent = ScreenGui
    Instance.new("UICorner", toastFrame).CornerRadius = UDim.new(0, 8)
    local toastStroke = Instance.new("UIStroke", toastFrame)
    toastStroke.Color = GetTheme("Accent")
    toastStroke.Thickness = 1

    local toastLabel = Instance.new("TextLabel")
    toastLabel.Text = ""
    toastLabel.Size = UDim2.new(1, -16, 0, 20)
    toastLabel.Position = UDim2.new(0, 8, 0, 4)
    toastLabel.BackgroundTransparency = 1
    toastLabel.TextColor3 = Color3.fromRGB(220, 215, 240)
    toastLabel.TextSize = 11
    toastLabel.Font = Enum.Font.GothamBold
    toastLabel.TextXAlignment = Enum.TextXAlignment.Left
    toastLabel.ZIndex = 101
    toastLabel.Parent = toastFrame

    local toastBarTrack = Instance.new("Frame")
    toastBarTrack.Size = UDim2.new(1, -16, 0, 3)
    toastBarTrack.Position = UDim2.new(0, 8, 0, 28)
    toastBarTrack.BackgroundColor3 = HexToColor("2A2A38")
    toastBarTrack.BorderSizePixel = 0
    toastBarTrack.ZIndex = 101
    toastBarTrack.Parent = toastFrame
    Instance.new("UICorner", toastBarTrack).CornerRadius = UDim.new(0.5, 0)

    local toastBar = Instance.new("Frame")
    toastBar.Size = UDim2.new(1, 0, 1, 0)
    toastBar.BackgroundColor3 = GetTheme("Accent")
    toastBar.BorderSizePixel = 0
    toastBar.ZIndex = 102
    toastBar.Parent = toastBarTrack
    Instance.new("UICorner", toastBar).CornerRadius = UDim.new(0.5, 0)

    local toastQueue = {}
    local toastRunning = false

    ShowToast = function(text, isEnabled)
        table.insert(toastQueue, {text = text, enabled = isEnabled})
        if toastRunning then return end
        toastRunning = true
        task.spawn(function()
            while #toastQueue > 0 do
                local item = table.remove(toastQueue, 1)
                local onColor  = Color3.fromRGB(120, 220, 120)
                local offColor = Color3.fromRGB(220, 100, 100)
                local dotColor = item.enabled and onColor or offColor
                local dot      = item.enabled and "[ON] " or "[OFF] "
                toastLabel.Text = dot .. item.text
                toastLabel.TextColor3 = dotColor
                toastStroke.Color = dotColor
                toastBar.BackgroundColor3 = dotColor
                toastBar.Size = UDim2.new(1, 0, 1, 0)
                TweenService:Create(toastFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(1, -10, 1, -46)
                }):Play()
                task.wait(0.15)
                TweenService:Create(toastBar, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(0, 0, 1, 0)
                }):Play()
                task.wait(1.2)
                TweenService:Create(toastFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, -10, 1, 60)
                }):Play()
                task.wait(0.15)
            end
            toastRunning = false
        end)
    end
end

-- ============================================================
-- AMBIENT ANIMATIONS
-- ============================================================
do
    task.spawn(function()
        local colors = {
            Color3.fromRGB(220, 200, 255), Color3.fromRGB(180, 130, 255),
            Color3.fromRGB(240, 200, 255), Color3.fromRGB(160, 100, 255),
            Color3.fromRGB(220, 200, 255),
        }
        local idx = 1
        while true do
            task.wait(1.8)
            idx = idx % #colors + 1
            TweenService:Create(TitleLabel, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {TextColor3 = colors[idx]}):Play()
        end
    end)

    task.spawn(function()
        while true do
            TweenService:Create(badge, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(200, 100, 255)}):Play()
            task.wait(0.6)
            TweenService:Create(badge, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(90, 45, 160)}):Play()
            task.wait(0.6)
        end
    end)

    task.spawn(function()
        local rot = 0
        while true do
            task.wait(0.05)
            rot = (rot + 1) % 360
            accentGrad.Rotation = rot
        end
    end)
end

do
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local rewards = LocalPlayer:FindFirstChild("rewards")
    local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
    local spintimeValue = rewards and rewards:FindFirstChild("spintime")
    local spinCountValue = rewards and rewards:FindFirstChild("SpinCount")

    if coinsValue then
        State.CurrentCoins = ParseCoins(coinsValue.Value)
        coinsValue:GetPropertyChangedSignal("Value"):Connect(function()
            State.CurrentCoins = ParseCoins(coinsValue.Value)
        end)
    end

    task.spawn(function()
        local samples = {}
        local MAX_SAMPLES = 10
        local prevCoins = State.CurrentCoins
        while task.wait(1) do
            local curr = State.CurrentCoins
            local gained = curr - prevCoins
            prevCoins = curr
            table.insert(samples, math.max(0, gained))
            if #samples > MAX_SAMPLES then table.remove(samples, 1) end
            local total = 0
            for _, v in ipairs(samples) do total = total + v end
            State.CoinsPerSecond = total / #samples
        end
    end)

    RunService.Heartbeat:Connect(function()
        if spintimeValue and spinCountValue then
            local spinSecs = spintimeValue.Value
            local spinCount = spinCountValue.Value
            if spinSecs == 0 then
                SpinLabel.Text = tostring(spinCount) .. " spin(s) ready!"
            else
                SpinLabel.Text = string.format("Spin: %02d:%02d", math.floor(spinSecs/60), math.floor(spinSecs%60))
            end
        end
        CoinsCurrentLabel.Text = FormatCoins(State.CurrentCoins)
        -- Fuse timer in bottom bar
        pcall(function()
            local RC2 = require(ReplicatedStorage:WaitForChild("ReplicaController", 1))
            local replica = nil
            for _, r in pairs(RC2._replicas) do
                if r.Class == "PlayerProfile" then replica = r break end
            end
            local md = replica and replica.Data and replica.Data.mergedata
            if md and md.timestamp and md.outcome then
                local dur = md.duration or 900
                local rem = md.timestamp + dur - os.time()
                if rem > 0 then
                    FuseLabel.Text = string.format("Fuse: %d:%02d", math.floor(rem/60), rem%60)
                    FuseLabel.TextColor3 = Color3.fromRGB(200, 180, 100)
                else
                    FuseLabel.Text = "Fuse: Collect!"
                    FuseLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
                end
            else
                FuseLabel.Text = "Fuse: No"
                FuseLabel.TextColor3 = Color3.fromRGB(160, 155, 190)
            end
        end)
    end)
end

SetLoadProgress(0.5, "connecting remotes...")
task.wait(0.5)

-- ============================================================
-- SHARED UTILITY
-- ============================================================

local function GetCurrentWeather()
    local w = nil
    local isEnding = false
    
    pcall(function()
        local wc = LocalPlayer.PlayerGui.Main:FindFirstChild("WeatherContainer")
        if not wc then return end
        
        local f = wc:FindFirstChildOfClass("Frame")
        if not f or not f.Visible then return end
        
        -- FIXED: Using string.find so it ignores hidden spaces or rich-text tags!
        local timerLabel = f:FindFirstChild("Timer")
        if timerLabel then
            local tmrText = tostring(timerLabel.Text)
            if tmrText:find("0:01") or tmrText:find("0:00") then
                isEnding = true
            end
        end
        
        local t = f:FindFirstChild("Title")
        if not t then return end
        
        local txt = t.Text:gsub("<[^>]+>",""):match("^%s*(.-)%s*$")
        if txt and txt ~= "" and txt ~= "Template" then 
            w = txt 
        end
    end)
    
    if isEnding then w = nil end

    return w, isEnding
end


-- SHARED PARSESTOCK (used by dice, potions, equip logic)
-- ============================================================
local function ParseStock(txt)
    if not txt or txt == "NO STOCK" then return 0 end
    local n = txt:match("x(%d+)")
    return n and tonumber(n) or 0
end

local function GetBestOwnedDice()
    local owned = {}
    pcall(function()
        local dg = LocalPlayer.PlayerGui.Main.Dice
        local c = dg:FindFirstChild("Container")
        if c then
            for _, f in pairs(c:GetChildren()) do
                if f:IsA("Frame") then owned[f.Name] = true end
            end
        end
        local t = dg:FindFirstChild("title")
        if t and t.Text ~= "" then owned[t.Text] = true end
    end)
    for i = #diceRank, 1, -1 do
        if owned[diceRank[i]] then return diceRank[i] end
    end
    return nil
end

local function GetWorstOwnedDice()
    if #State.WorstDiceList == 0 then return nil end
    local owned = {}
    pcall(function()
        local dg = LocalPlayer.PlayerGui.Main.Dice
        local c = dg:FindFirstChild("Container")
        if c then
            for _, f in pairs(c:GetChildren()) do
                if f:IsA("Frame") then owned[f.Name] = true end
            end
        end
        local t = dg:FindFirstChild("title")
        if t and t.Text ~= "" then owned[t.Text] = true end
    end)
    -- Return first selected worst dice the player still owns
    for _, diceName in ipairs(State.WorstDiceList) do
        if owned[diceName] then return diceName end
    end
    return nil -- none of the selected dice are owned → stop
end

-- ============================================================
-- RUNTIME LOOPS
-- ============================================================
UserInputService.JumpRequest:Connect(function()
    if not State.InfiniteJump then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

do
    local flyBodyVel, flyBodyGyro
    local function StartFly(root)
        if flyBodyVel then flyBodyVel:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.Velocity = Vector3.new(0,0,0)
        flyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
        flyBodyVel.Parent = root
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
        flyBodyGyro.P = 1e4
        flyBodyGyro.Parent = root
    end
    local function StopFly()
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    end
    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and not State.Flying then hum.WalkSpeed = State.WalkSpeed end
        if State.Flying and root then
            if not flyBodyVel or flyBodyVel.Parent ~= root then StartFly(root) end
            local cam = workspace.CurrentCamera
            if flyBodyGyro then flyBodyGyro.CFrame = cam.CFrame end
            if flyBodyVel then
                local dir = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
                flyBodyVel.Velocity = dir.Magnitude ~= 0 and dir.Unit * State.FlySpeed or Vector3.new(0,0,0)
            end
        else
            if flyBodyVel then StopFly() end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(State.CollectDelay)
        if State.AutoCollectCoins then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if char and root then
                pcall(function()
                    local plots = workspace.Map.Plots
                    for _, plot in pairs(plots:GetChildren()) do
                        local slots = plot:FindFirstChild("Slots")
                        if slots then
                            for _, slot in pairs(slots:GetChildren()) do
                                local collect = slot:FindFirstChild("Collect")
                                if collect then
                                    local touch = collect:FindFirstChild("Touch")
                                    if touch and touch:IsA("BasePart") then
                                        firetouchinterest(root, touch, 0)
                                        task.wait(0.01)
                                        firetouchinterest(root, touch, 1)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end)

task.spawn(function()
    local buyRemote
    pcall(function() buyRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("buy", 10) end)
    if not buyRemote then warn("[reidu] buy remote not found") return end

    local function GetStockLabel(diceName)
        local lbl = nil
        pcall(function()
            local sf = LocalPlayer.PlayerGui.Main:FindFirstChild("Restock")
            sf = sf and sf:FindFirstChild("ScrollingFrame")
            if sf then
                local frame = sf:FindFirstChild(diceName)
                if frame then lbl = frame:FindFirstChild("stock") end
            end
        end)
        return lbl
    end

    local connections = {}
    local bought = {}

    local function ConnectDice(diceName)
        local lbl = GetStockLabel(diceName)
        if not lbl then
            warn("[reidu] stock label not found for: " .. diceName .. " (is Restock frame open?)")
            return
        end
        if connections[diceName] then connections[diceName]:Disconnect() end

        local stock = ParseStock(lbl.Text)
        warn("[reidu] ConnectDice: " .. diceName .. " stock=" .. stock .. " bought=" .. tostring(bought[diceName]))

        -- Immediate buy if stock available right now
        if stock > 0 and State.AutoBuyDice and not bought[diceName] then
            bought[diceName] = true
            warn("[reidu] Buying immediately: " .. diceName)
            local amount = State.RebirthBypass and 99 or (State.AlwaysBuyMax and stock or 1)
            local ok = pcall(function() buyRemote:InvokeServer(diceName, amount, "dice") end)
            if not ok then bought[diceName] = false end -- reset on failure so it retries
        end

        local wasZero = stock == 0
        connections[diceName] = lbl:GetPropertyChangedSignal("Text"):Connect(function()
            if not State.AutoBuyDice then return end
            local s = ParseStock(lbl.Text)
            if s == 0 then
                wasZero = true
                bought[diceName] = false
            elseif s > 0 and wasZero and not bought[diceName] then
                wasZero = false
                bought[diceName] = true
                task.spawn(function()
                    task.wait(0.5)
                    warn("[reidu] Buying on restock: " .. diceName .. " amount=" .. tostring(s))
                    local amount = State.RebirthBypass and 99 or (State.AlwaysBuyMax and s or 1)
                    local ok = pcall(function() buyRemote:InvokeServer(diceName, amount, "dice") end)
                    if not ok then bought[diceName] = false end
                end)
            end
        end)
    end

    while true do
        task.wait(2)
        if State.AutoBuyDice then
            for _, diceName in ipairs(State.SelectedDice) do
                if not connections[diceName] or not connections[diceName].Connected then
                    ConnectDice(diceName)
                end
            end
        end
        for diceName, conn in pairs(connections) do
            if not table.find(State.SelectedDice, diceName) then
                conn:Disconnect()
                connections[diceName] = nil
                bought[diceName] = nil
            end
        end
    end
end)

task.spawn(function()
    local buyRemote
    pcall(function() buyRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("buy", 10) end)
    if not buyRemote then return end
    local function GetStockLabel(potionName)
        local lbl = nil
        pcall(function()
            local sf = LocalPlayer.PlayerGui.Main.Potions:FindFirstChild("ScrollingFrame")
            if sf then
                local frame = sf:FindFirstChild(potionName)
                if frame then lbl = frame:FindFirstChild("stock") end
            end
        end)
        return lbl
    end
    local connections = {}
    local bought = {}
    local function ConnectPotion(potionName)
        local lbl = GetStockLabel(potionName)
        if not lbl then return end
        local stock = ParseStock(lbl.Text)
        if stock > 0 and State.AutoBuyPotion and not bought[potionName] then
            bought[potionName] = true
            pcall(function() buyRemote:InvokeServer(potionName, stock, "potion") end)
        end
        if connections[potionName] then connections[potionName]:Disconnect() end
        connections[potionName] = lbl:GetPropertyChangedSignal("Text"):Connect(function()
            if not State.AutoBuyPotion then return end
            local s = ParseStock(lbl.Text)
            if s > 0 and not bought[potionName] then
                bought[potionName] = true
                pcall(function() buyRemote:InvokeServer(potionName, s, "potion") end)
            elseif s == 0 then
                bought[potionName] = false
            end
        end)
    end
    while true do
        task.wait(2)
        if State.AutoBuyPotion then
            for _, potionName in ipairs(State.SelectedPotion) do
                if not connections[potionName] then ConnectPotion(potionName) end
            end
        end
        for potionName, conn in pairs(connections) do
            if not table.find(State.SelectedPotion, potionName) then
                conn:Disconnect()
                connections[potionName] = nil
                bought[potionName] = nil
            end
        end
    end
end)

task.spawn(function()
    local equipRemote
    local VirtualInputManager = game:GetService("VirtualInputManager")
    pcall(function() equipRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("equip", 10) end)
    if not equipRemote then return end

    local function ClickFloor()
        local cam = workspace.CurrentCamera
        local x = cam.ViewportSize.X * 0.5
        local y = cam.ViewportSize.Y - 2
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end

task.spawn(function()
    local updateDiceRemote
    pcall(function() updateDiceRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("updateRollingDice", 10) end)
    if not updateDiceRemote then return end
    while true do
        task.wait(State.EquipBestDelay)
        local weather = GetCurrentWeather()
        local hasWeatherFilter = #State.GlobalWeatherFilter > 0

        -- For roll gating: no filter = always counts as valid, filter = only matching weather
        local isFilteredWeather = (not hasWeatherFilter) or (weather ~= nil and table.find(State.GlobalWeatherFilter, weather) ~= nil)

        -- For dice priority: good weather only counts if weather is ACTUALLY active right now
        local isGoodWeatherActive = weather ~= nil and (not hasWeatherFilter or table.find(State.GlobalWeatherFilter, weather) ~= nil)

        -- Same priority as auto-roll: best on good weather, worst otherwise
        if isGoodWeatherActive and State.BestDice then
        local best = GetBestOwnedDice()
        if best then
            pcall(function() updateDiceRemote:FireServer(best) end)
            if BestDiceLabel then
                BestDiceLabel.Text = best:gsub(" Dice","")
                BestDiceLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
            end
        end
        elseif State.WorstDiceFilter and #State.WorstDiceList > 0 then
            local worst = GetWorstOwnedDice()
            if worst then
                pcall(function() updateDiceRemote:FireServer(worst) end)
                if BestDiceLabel then
                    BestDiceLabel.Text = worst:gsub(" Dice","")
                    BestDiceLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
                end
            end
        end
    end
end)

task.spawn(function()
    local equipRemote
    pcall(function() equipRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("equip", 10) end)
    if not equipRemote then return end

    local POTION_PRIORITY = {
        { "Luck Potion 3", "Luck Potion 2", "Luck Potion 1" },
        { "Money Potion 3", "Money Potion 2", "Money Potion 1" },
        { "No Consume Dice Potion 1" },
        { "Mutation Chance Potion 1" },
    }

    -- Money potions run on their own separate track (weather-independent)
    local MONEY_POTIONS = { "Money Potion 3", "Money Potion 2", "Money Potion 1" }

    local function GetOwned(potionName)
        local count = 0
        pcall(function()
            local sf = LocalPlayer.PlayerGui.Main.Potions:FindFirstChild("ScrollingFrame")
            if sf then
                local frame = sf:FindFirstChild(potionName)
                local lbl = frame and frame:FindFirstChild("stock")
                if lbl then count = ParseStock(lbl.Text) end
            end
        end)
        return count
    end

    local function HasBuff(potionName)
        local found = false
        pcall(function()
            local buffs = LocalPlayer.PlayerGui.Main:FindFirstChild("BUFFS")
            if buffs then
                local searchStr = potionName:lower()
                if searchStr:find("luck") then searchStr = "luck"
                elseif searchStr:find("money") then searchStr = "coin"
                elseif searchStr:find("no consume") then searchStr = "consume"
                elseif searchStr:find("mutation") then searchStr = "mutation"
                end
                for _, b in pairs(buffs:GetChildren()) do
                    if b.Name:lower():find(searchStr, 1, true) then
                        found = true
                        break
                    end
                end
            end
        end)
        return found
    end

    local function GetBestOwned(tierList)
        for _, name in ipairs(tierList) do
            if GetOwned(name) > 0 then return name end
        end
        return nil
    end

    local lastEquipped = {}

    local function TryEquipSingle(potionName, force)
        local now = tick()
        local last = lastEquipped[potionName] or 0
        if now - last < 4 then return end
        local buffActive = State.ActiveBuffCheck and HasBuff(potionName)
        if force or not buffActive then
            local result = nil
            pcall(function() result = equipRemote:InvokeServer(potionName, true) end)
            if result then
                task.wait(0.3)
                ClickFloor()
                lastEquipped[potionName] = now
            end
            task.wait(0.4)
        end
    end

    local function TryEquipPotions(force)
        for _, tierList in ipairs(POTION_PRIORITY) do
            -- Skip money potions here — handled separately
            if tierList == MONEY_POTIONS then continue end
            local best = GetBestOwned(tierList)
            if not best then continue end
            TryEquipSingle(best, force)
        end
    end

    -- SEPARATE LOOP: Money potions, always active regardless of weather
    task.spawn(function()
        while true do
            task.wait(3)
            if State.AutoRollMoneyPotion then
                local best = GetBestOwned(MONEY_POTIONS)
                if best then
                    TryEquipSingle(best, false)
                end
            end
        end
    end)

    local lastWeather = nil
        while true do
            task.wait(3)
            if not State.AutoEquipPotions then continue end

            local weather = GetCurrentWeather()
            local hasFilter = #State.GlobalWeatherFilter ~= 0

            -- Mirror dice logic exactly
            local isGoodWeather = weather ~= nil
                and hasFilter
                and table.find(State.GlobalWeatherFilter, weather) ~= nil

            local weatherJustChanged = weather ~= lastWeather
            lastWeather = weather

            if isGoodWeather then
                -- Good weather active: always try to equip, force on weather change
                TryEquipPotions(weatherJustChanged)
            elseif not hasFilter then
                -- No filter set: always equip regardless
                TryEquipPotions(false)
            end
            -- If filter is set but no matching weather: do nothing (same as dice not rolling)
        end
    end)
end)

-- ============================================================


-- ============================================================
-- UPGRADE & REBIRTH RUNTIME
-- ============================================================
do
    local upgradeRemote, rebirthRemote
    pcall(function()
        upgradeRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("upgrade", 10)
        rebirthRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("rebirth", 10)
    end)

    local UPGRADE_MAP = {
        ["Upgrade_1"]  = { remote = "PlayerLuck",        frame = "PlayerLuck"      },
        ["Upgrade_2"]  = { remote = "GlobalIncome",      frame = "GlobalIncome"    },
        ["Upgrade_3"]  = { remote = "ShopStock",         frame = "ShopStock"       },
        ["Upgrade_4"]  = { remote = "MutationChance",    frame = "MutationChance"  },
        ["Upgrade_5"]  = { remote = "PetLuck",           frame = "PetLuckBoost"    },
        ["Upgrade_6"]  = { remote = "ImprovedMutations", frame = "MutationQuality" },
        ["Upgrade_7"]  = { remote = "RestockChance",     frame = "RestockChance"   },
        ["Upgrade_8"]  = { remote = "SecretRate",        frame = "SecretChance"    },
        ["Upgrade_9"]  = { remote = "GodlyRate",         frame = "GodlyChance"     },
        ["Upgrade_10"] = { remote = "GemBoost",          frame = "CosmicChance"    },
        ["Upgrade_11"] = { remote = "ApexRate",          frame = "ApexChance"      },
    }

    local function GetSuffixLabel(frameName)
        local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
        local upgrades = main and main:FindFirstChild("Upgrades")
        local sf = upgrades and upgrades:FindFirstChild("ScrollingFrame")
        local upgradeFrame = sf and sf:FindFirstChild(frameName)
        return upgradeFrame and upgradeFrame:FindFirstChild("suffix") or nil
    end

    local function IsMaxed(frameName)
        local suffix = GetSuffixLabel(frameName)
        if not suffix then return false end
        return tostring(suffix.Text):find("%(MAX%)", 1, false) ~= nil
    end

    -- Stores the animated [MAX] labels so we don't create duplicates
    local upgradeMaxAnimLabels = {}

    local function StartRainbowAnimation(label)
        local colors = {
            Color3.fromRGB(255, 80,  80),
            Color3.fromRGB(255, 165, 40),
            Color3.fromRGB(255, 255, 60),
            Color3.fromRGB(80,  255, 80),
            Color3.fromRGB(60,  220, 255),
            Color3.fromRGB(120, 100, 255),
            Color3.fromRGB(200, 80,  255),
        }
        task.spawn(function()
            local i = 1
            while label and label.Parent do
                i = i % #colors + 1
                TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
                    TextColor3 = colors[i]
                }):Play()
                task.wait(0.4)
            end
        end)
    end

    local function UpdateMaxLabels()
        for stateKey, info in pairs(UPGRADE_MAP) do
            local idx = tonumber(stateKey:match("%d+"))
            if not idx then continue end

            if IsMaxed(info.frame) then
                State["UpgradeMaxed_"..idx] = true

                -- Restore plain name on the main label
                local lbl = upgradeRowLabels[idx]
                if lbl then
                    lbl.Text = upgradeOptNames[idx]
                    lbl.TextColor3 = Color3.fromRGB(200, 195, 220)
                end

                -- Create the animated [MAX] label only once
                if not upgradeMaxAnimLabels[idx] and lbl and lbl.Parent then
                    local maxLbl = Instance.new("TextLabel")
                    maxLbl.Text = "[MAX]"
                    maxLbl.Size = UDim2.new(0, 50, 1, 0)
                    maxLbl.Position = UDim2.new(0.65, -55, 0, 0)
                    maxLbl.BackgroundTransparency = 1
                    maxLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
                    maxLbl.TextSize = 11
                    maxLbl.Font = Enum.Font.GothamBold
                    maxLbl.TextXAlignment = Enum.TextXAlignment.Right
                    maxLbl.Parent = lbl.Parent
                    upgradeMaxAnimLabels[idx] = maxLbl
                    StartRainbowAnimation(maxLbl)
                end
            else
                -- Not maxed: remove anim label if it exists
                if upgradeMaxAnimLabels[idx] then
                    upgradeMaxAnimLabels[idx]:Destroy()
                    upgradeMaxAnimLabels[idx] = nil
                end
                State["UpgradeMaxed_"..idx] = false
                local lbl = upgradeRowLabels[idx]
                if lbl then
                    lbl.Text = upgradeOptNames[idx]
                    lbl.TextColor3 = Color3.fromRGB(200, 195, 220)
                end
            end
        end
    end

    -- ALWAYS-ON: scan for MAX regardless of AutoUpgrade toggle
    task.spawn(function()
        while true do
            task.wait(2)
            UpdateMaxLabels()
        end
    end)

    -- Rebirth loop
    task.spawn(function()
        if not rebirthRemote then return end
        while true do
            task.wait(5)
            if State.AutoRebirth then
                pcall(function() rebirthRemote:InvokeServer() end)
            end
        end
    end)

    -- Upgrade loop — only fires remotes when AutoUpgrade is ON
    task.spawn(function()
        if not upgradeRemote then return end
        while true do
            task.wait(1.5)
            if not State.AutoUpgrade then continue end
            for stateKey, info in pairs(UPGRADE_MAP) do
                local idx = tonumber(stateKey:match("%d+"))
                if not idx then continue end
                if State["UpgradeMaxed_"..idx] then continue end
                if State[stateKey] then
                    pcall(function() upgradeRemote:InvokeServer(info.remote) end)
                end
            end
        end
    end)
end

SetLoadProgress(0.8, "starting loops...")
task.wait(0.6)

-- ============================================================
-- WEBHOOK & AUTO-ROLL
-- ============================================================
do
    local RARITY_COLORS = {
        Common = 10197915, Uncommon = 5763719, Rare = 5614830,
        Epic = 10181046, Legendary = 16766720, Mythic = 15548997,
        Divine = 16769280, Prismatic = 11141375, Sacred = 16777180,
        Secret = 16711935, Godly = 16777215, Cosmic = 6750054,
        Apex = 16753920, Primordial = 16711680, Unknown = 8421504,
        -- Special overrides (used dynamically below)
        ApexRare = 0xFFD700,   -- gold
        PrimordialSpecial = 0xFF00FF, -- magenta/pink
    }
    local RARITY_EMOJIS = {
        Common = "⚪", Uncommon = "🟢", Rare = "🔵",
        Epic = "🟣", Legendary = "🟡", Mythic = "🔴",
        Divine = "👑", Prismatic = "🌈", Sacred = "🌟",
        Secret = "🔮", Godly = "⚡", Cosmic = "✨",
        Apex = "🔥", Primordial = "🌌", Unknown = "❔"
    }

    local BaddieData = {}
    pcall(function()
        BaddieData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("BaddieData"))
    end)

    local httprequest = nil
    pcall(function() httprequest = syn and syn.request end)
    if not httprequest then pcall(function() httprequest = http and http.request end) end
    if not httprequest then pcall(function() httprequest = http_request end) end
    if not httprequest then pcall(function() httprequest = fluxus and fluxus.request end) end
    if not httprequest then pcall(function() httprequest = request end) end
    warn("[reidu] httprequest: " .. tostring(httprequest))

    local function FormatCommas(n)
        local formatted = tostring(n)
        while true do
            local k
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end

    local function GetPing()
        if State.UserID ~= "" then
            local cleanID = tostring(State.UserID):match("%d+")
            if cleanID then return "<@" .. cleanID .. ">" end
        end
        return nil
    end

    local webhookQueue = {}
    local webhookProcessing = false

    local function ProcessWebhookQueue()
        if webhookProcessing then return end
        webhookProcessing = true
        task.spawn(function()
            while #webhookQueue > 0 do
                local item = table.remove(webhookQueue, 1)
                if httprequest then
                    local ok, response = pcall(function()
                        return httprequest({
                            Url = item.url,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = item.body
                        })
                    end)
                    -- If rate limited, put it back at the front and wait
                    if ok and response and response.StatusCode == 429 then
                        table.insert(webhookQueue, 1, item)
                        task.wait(2)
                    else
                        task.wait(0.6) -- ~1.6 sends/sec, well under Discord's limit
                    end
                end
            end
            webhookProcessing = false
        end)
    end

    local function SendEmbed(contentStr, embedData)
        if State.WebhookURL == "" then return end
        local payload = {
            content = contentStr,
            embeds = { embedData },
            allowed_mentions = { parse = { "users" } }
        }
        local ok, jsonData = pcall(function() return HttpService:JSONEncode(payload) end)
        if not ok then return end
        table.insert(webhookQueue, { url = State.WebhookURL, body = jsonData })
        ProcessWebhookQueue()
    end

    TestWebhook = function()
        SendEmbed(GetPing(), {
            title = "🧪 Webhook Test: SUCCESS!",
            color = 5025616,
            description = "Your reidu's scripts connection is working perfectly!",
            fields = {
                { name = "👤 Testing User", value = "`" .. LocalPlayer.Name .. "`", inline = true },
                { name = "💸 Format Check", value = "`$" .. FormatCommas(1250000) .. "`", inline = true }
            },
            footer = { text = "reidu's scripts • v8.2" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        })
    end

    local function SendBaddieWebhook(baddyName, rarity, cashPerSec, chance, mutation)
    local formatRarity = "Unknown"
    -- Trim whitespace before any comparison
    local rarityLower = tostring(rarity):lower():match("^%s*(.-)%s*$")

    local knownRarities = {
        "Common","Uncommon","Rare","Epic","Legendary",
        "Mythic","Divine","Prismatic","Sacred","Secret",
        "Godly","Cosmic","Apex","Primordial"
    }
    for _, known in ipairs(knownRarities) do
        -- Special case: "cosmic" matches both "Cosmic" and "Cosmical" from game
        local searchKey = known == "Cosmical" and "cosmic" or known:lower()
        if rarityLower:find(searchKey, 1, true) then
            formatRarity = known
            break
        end
    end

    -- Debug: uncomment this line to see what rarity string is actually coming in
    print("[WebhookDebug] Raw rarity: '" .. tostring(rarity) .. "' → resolved: " .. formatRarity)

    -- Detect special cases FIRST, before the rarity filter 
    local isPrimordial = formatRarity == "Primordial" 

    -- Added all the requested mutations here
    local rareApexMutations = { 
        candy = true, 
        slime = true, 
        honey = true, 
        lunar = true, 
        solar = true, 
        celestial = true, 
        void = true 
    }

    local mutationLower = tostring(mutation or ""):lower() 
    local cashNum = tonumber((tostring(cashPerSec):gsub(",",""))) or 0 

    -- Changed > to >= so it includes exactly 1,000,000,000 and anything above it
    local isRareApex = formatRarity == "Apex" and (rareApexMutations[mutationLower] or cashNum >= 1000000000) 

    -- Special cases BYPASS the rarity filter — always send 
    -- Normal baddies respect the toggle 
    if not isPrimordial and not isRareApex then 
        if formatRarity ~= "Unknown" and not State["Rarity_" .. formatRarity] then 
            return 
        end 
    end


        local emoji = RARITY_EMOJIS[formatRarity] or "❔"

        -- Pick color and title based on special status
        local color, title, footerExtra
        if isPrimordial then
            color = 0xFF00FF
            title = "🌌🌌 " .. tostring(baddyName) .. " 🌌🌌"
            footerExtra = " • ⚠️ PRIMORDIAL"
        elseif isRareApex then
            color = 0xFFD700
            title = "🔥⭐ " .. tostring(baddyName) .. " ⭐🔥"
            footerExtra = " • ⭐ RARE APEX"
        else
            color = RARITY_COLORS[formatRarity] or 8421504
            title = emoji .. " " .. tostring(baddyName)
            footerExtra = ""
        end

        local weather = GetCurrentWeather() or "☀️ Clear"
        local displayChance = chance ~= "?" and FormatCommas(chance) or "?"
        local displayCash = cashPerSec ~= "?" and FormatCommas(cashPerSec) or "?"

        SendEmbed(GetPing(), {
            title = title,
            color = color,
            description = isPrimordial
                and "⚠️ **PRIMORDIAL ROLLED** ⚠️\n**Obtained:** `" .. tostring(baddyName) .. "`"
                    .. (mutationLower ~= "" and mutationLower ~= "normal"
                        and "\n🧬 **Mutation:** `" .. tostring(mutation) .. "`" or "")
                or (isRareApex
                    and "🌟 **RARE APEX ALERT!**\n**Obtained:** `" .. tostring(baddyName) .. "`"
                        .. (rareApexMutations[mutationLower]
                            and "\n🧬 **Special Mutation:** `" .. tostring(mutation) .. "`" or "")
                        .. (cashNum > 1000000
                            and "\n💸 **High Value:** `$" .. displayCash .. "`" or "")
                    or "**Obtained:** `" .. tostring(baddyName) .. "`"),
            fields = {
                { name = emoji .. " Rarity",   value = "`" .. formatRarity .. "`",              inline = true },
                { name = "🧬 Mutation",        value = "`" .. tostring(mutation or "Normal") .. "`", inline = true },
                { name = "🎲 Chance",          value = "`1 in " .. displayChance .. "`",        inline = true },
                { name = "💸 Base Cash",       value = "`$" .. displayCash .. "`",              inline = true },
                { name = "☁️ Weather",         value = "`" .. weather .. "`",                   inline = true },
                { name = "👤 Player",          value = "`" .. LocalPlayer.Name .. "`",          inline = true },
            },
            footer = { text = "reidu's scripts • v8.2" .. footerExtra },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        })
    end

    local function SendWeatherWebhook(weather)
        SendEmbed(GetPing(), {
            title = "⛈️ Weather Event: " .. tostring(weather) .. " ⛈️",
            color = 7506394,
            description = "**A new weather event has started!**\nMake sure your auto-rolls and spins are ready! 🎲",
            fields = {
                { name = "☁️ Active Weather", value = "`" .. tostring(weather) .. "`", inline = true },
                { name = "👤 Player", value = "`" .. LocalPlayer.Name .. "`", inline = true }
            },
            footer = { text = "reidu's scripts • v8.2" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        })
    end

    local rollRemote = nil
    local diceEquipRemote = nil
    pcall(function()
        rollRemote = LocalPlayer.PlayerGui:WaitForChild("Main", 10):WaitForChild("Dice", 10):WaitForChild("RollState", 10)
        diceEquipRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("updateRollingDice", 10)
    end)

  if rollRemote then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if self == rollRemote and method == "InvokeServer" then
                
                -- SAFETY LOCK: Tell the Auto-Sell script that we are currently rolling!
                State.IsRolling = true 
                
                local result = oldNamecall(self, ...)
                if type(result) == "table" then
                    for k, v in pairs(result) do
                        warn("[RollDebug] key=" .. tostring(k) .. " val=" .. tostring(v))
                    end
                end
                
                -- SAFETY UNLOCK: Roll is finished.
                State.IsRolling = false 
                
                if type(result) == "table" and result.outcome then
                    task.spawn(function()
                        local name = result.outcome
                        local mutation = result.mutation
                        local isAutoSold = result.autoSold
                        if name then
                            local rarity = "Unknown"
                            local chance = "?"
                            local cash = "?"
                            if BaddieData and type(BaddieData) == "table" and BaddieData[name] then
                                rarity = BaddieData[name].Rarity or "Unknown"
                                chance = BaddieData[name].Chance or "?"
                                cash = BaddieData[name].BaseCash or "?"
                            end
                            SendBaddieWebhook(name, rarity, cash, chance, mutation)
                            if State._UpdateLastRoll then
                                local rollKey = tostring(name) .. "|" .. tostring(mutation or "Normal")
                                local isNew = not State._SeenRolls[rollKey]
                                State._SeenRolls[rollKey] = true
                                State._PendingRoll = {name=name, rarity=rarity, mutation=mutation, isNew=isNew}
                            end
                        end
                    end)
                end
                return result
            end
            return oldNamecall(self, ...)
        end)
    end

    task.spawn(function()
    while true do
        task.wait(State.RollDelay)
        if State.AutoRoll then
            
            -- Smart Check: Keep looking for the buttons if the game loaded slowly!
            if not rollRemote then
                pcall(function() rollRemote = LocalPlayer.PlayerGui.Main.Dice:FindFirstChild("RollState") end)
            end
            if not diceEquipRemote then
                pcall(function() diceEquipRemote = ReplicatedStorage.Events:FindFirstChild("updateRollingDice") end)
            end
            
            if rollRemote then
                local shouldRoll = true
                local weather = GetCurrentWeather()
                local hasWeatherFilter = #State.GlobalWeatherFilter > 0

                -- For roll gating: no filter = always counts as valid, filter = only matching weather
                local isFilteredWeather = (not hasWeatherFilter) or (weather ~= nil and table.find(State.GlobalWeatherFilter, weather) ~= nil)

                -- For dice priority: good weather only counts if weather is ACTUALLY active right now
                local isGoodWeatherActive = weather ~= nil and (not hasWeatherFilter or table.find(State.GlobalWeatherFilter, weather) ~= nil)

                -- Good weather = something active AND it matches your filter list
                local isGoodWeather = weather ~= nil
                    and #State.GlobalWeatherFilter > 0
                    and table.find(State.GlobalWeatherFilter, weather) ~= nil

                -- AutoDiceOnWeather only blocks rolling when there's no good weather
                -- (it should NEVER block worst dice burns)
                if State.AutoDiceOnWeather and not isGoodWeather then
                    shouldRoll = false
                end

                local useWorstDice = false
                if State.WorstDiceFilter and #State.WorstDiceList > 0 then
                    if isGoodWeather then
                        -- Good weather active → use best dice, keep shouldRoll as-is
                        useWorstDice = false
                    else
                        -- No weather or bad weather → burn worst dice, ALWAYS roll
                        local worst = GetWorstOwnedDice()
                        if worst then
                            useWorstDice = true
                            shouldRoll = true -- override any weather gate
                        end
                    end
                end

                if shouldRoll then
                    if useWorstDice and diceEquipRemote then
                        local worst = GetWorstOwnedDice()
                        if worst then
                            pcall(function() diceEquipRemote:FireServer(worst) end)
                            if BestDiceLabel then
                                BestDiceLabel.Text = worst:gsub(" Dice","")
                                BestDiceLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
                            end
                            task.wait(0.05)
                        end
                    elseif isGoodWeatherActive and State.BestDice and diceEquipRemote then
                        local best = GetBestOwnedDice()
                        if best then
                            pcall(function() diceEquipRemote:FireServer(best) end)
                            if BestDiceLabel then
                                BestDiceLabel.Text = best:gsub(" Dice","")
                                BestDiceLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
                            end
                            task.wait(0.05)
                        end
                    end
                    pcall(function() rollRemote:InvokeServer() end)
                end
            end
        end
    end
end)

    task.spawn(function()
        local spinRemote
        pcall(function() spinRemote = ReplicatedStorage:WaitForChild("Events", 10) and ReplicatedStorage.Events:WaitForChild("spinrequest", 10) end)
        if not spinRemote then return end
        local function GetSpinCount()
            local count = 0
            pcall(function()
                local r = LocalPlayer:FindFirstChild("rewards")
                if r and r:FindFirstChild("SpinCount") then count = r.SpinCount.Value end
            end)
            return count
        end
        local spunThisWeather, lastWeather = false, nil
        while true do
            task.wait(2)
            if State.AutoSpin then
                local weather = GetCurrentWeather()
                if weather ~= lastWeather then spunThisWeather = false lastWeather = weather end
                local count = GetSpinCount()
                local hasFilter = #State.GlobalWeatherFilter ~= 0
                local weatherMatches = weather and hasFilter and table.find(State.GlobalWeatherFilter, weather)
                if weatherMatches then
                    if count > 0 then
                        for _ = 1, count do
                            pcall(function() spinRemote:InvokeServer() end)
                            task.wait(0.5)
                        end
                    end
                else
                    if count >= 5 then
                        pcall(function() spinRemote:InvokeServer() end)
                        task.wait(1)
                    end
                end
            end
        end
    end)

    task.spawn(function()
        local lastNotifiedWeather = nil
        while true do
            task.wait(3)
            if State.WebhookURL ~= "" then
                local weather = GetCurrentWeather()
                if weather and weather ~= lastNotifiedWeather then
                    lastNotifiedWeather = weather
                    local hasFilter = #State.GlobalWeatherFilter ~= 0
                    local passes = not hasFilter or table.find(State.GlobalWeatherFilter, weather)
                    if passes then SendWeatherWebhook(weather) end
                elseif not weather then
                    lastNotifiedWeather = nil
                end
            end
        end
    end)
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
task.spawn(function()
    if not getgenv().ReiduAntiAFKActive then
        getgenv().ReiduAntiAFKActive = true
        task.spawn(function()
            while true do
                task.wait(1)
                if not State.AntiAFK then continue end
                pcall(function()
                    if getconnections then
                        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                            if conn["Disable"] then conn:Disable() end
                        end
                    end
                end)
                pcall(function()
                    local Events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
                    if Events then
                        local remote = Events:FindFirstChild("RejoinRemote")
                        if remote then remote:Destroy() end
                    end
                end)
                pcall(function()
                    local rejoinLocal = LocalPlayer.PlayerScripts:FindFirstChild("RejoinLocal")
                    if rejoinLocal then rejoinLocal.Disabled = true end
                end)
                pcall(function()
                    local starterRejoin = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("RejoinLocal")
                    if starterRejoin then starterRejoin.Disabled = true end
                end)
            end
        end)
    end
end)
-- ============================================================
-- SUPPRESS AUTO-SELL NOTIFICATIONS
-- ============================================================
task.spawn(function()
    local bot_not = LocalPlayer.PlayerGui:WaitForChild("bot_not", 10)
    if not bot_not then return end
    local frame = bot_not:WaitForChild("Frame", 10)
    if not frame then return end
    frame.ChildAdded:Connect(function(child)
        if child.Name == "ActiveNotification" and State.SuppressAutoSell then
            child:Destroy()
        end
    end)
end)

-- ============================================================
-- AUTO-MERCHANT
-- ============================================================
task.spawn(function()
    local merchantBuy, merchantRequest = nil, nil
    pcall(function()
        merchantBuy     = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("MerchantBuy", 10)
        merchantRequest = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("MerchantRequest", 10)
    end)
    if not merchantBuy then return end

    local function GetNPCPos(npc)
        if npc:IsA("Model") then return npc:GetPivot().Position
        elseif npc:IsA("BasePart") then return npc.Position end
        return nil
    end

    local function RunMerchant(npc)
        local npcPos = GetNPCPos(npc)
        if not npcPos then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local savedCF = root.CFrame
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = {workspace.Terrain}
        local rayResult = workspace:Raycast(Vector3.new(npcPos.X, npcPos.Y + 100, npcPos.Z), Vector3.new(0, -500, 0), rayParams)
        local groundY = rayResult and rayResult.Position.Y or (npcPos.Y - 8)
        root.CFrame = CFrame.new(npcPos.X, groundY - 12, npcPos.Z)
        local bv = Instance.new("BodyVelocity")
        bv.Name = "_MerchantAnchor"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Parent = root
        task.wait(0.5)
        for _, v in pairs(npc:GetDescendants()) do
            if v:IsA("ProximityPrompt") then fireproximityprompt(v) break end
            if v:IsA("ClickDetector") then fireclickdetector(v) break end
        end
        task.wait(0.3)
        for _ = 1, 3 do
            pcall(function() merchantRequest:InvokeServer() end)
            task.wait(0.2)
        end
        for slot = 1, 3 do
            for _ = 1, 20 do
                pcall(function() merchantBuy:InvokeServer(slot) end)
            end
            task.wait(0.08)
        end
        -- Gem box purchases
        local gemRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("gemPurchase")
        if gemRemote then
            if State.AutoBuyRareBox then
                pcall(function() gemRemote:InvokeServer("RareBox") end)
            end
            if State.AutoBuyBasicBox then
                pcall(function() gemRemote:InvokeServer("BasicBox") end)
            end
        end
        local anchor = root:FindFirstChild("_MerchantAnchor")
        if anchor then anchor:Destroy() end
        root.CFrame = savedCF
    end

    local merchantBusy = false

    local function HandleNullityFolder(folder)
        if merchantBusy then return end
        merchantBusy = true
        task.spawn(function()
            -- Wait for the Model to appear inside the Folder
            local npcModel = folder:FindFirstChildOfClass("Model")
            local waited = 0
            while not npcModel and waited < 5 do
                task.wait(0.2)
                waited += 0.2
                npcModel = folder:FindFirstChildOfClass("Model")
            end
            if not npcModel then
                merchantBusy = false
                return
            end
            -- Wait for HumanoidRootPart to be ready
            local root = npcModel:WaitForChild("HumanoidRootPart", 5)
            if not root then
                merchantBusy = false
                return
            end
            task.wait(0.5) -- small buffer for position to settle
            RunMerchant(npcModel)
            merchantBusy = false
        end)
    end

    -- Watch for the Nullity Folder being added to workspace
    workspace.ChildAdded:Connect(function(v)
        if not State.AutoMerchant then return end
        if v.Name == "Nullity" and v:IsA("Folder") then
            HandleNullityFolder(v)
        end
    end)

    -- Also handle if Nullity folder already exists when script loads
    local existing = workspace:FindFirstChild("Nullity")
    if existing and existing:IsA("Folder") then
        HandleNullityFolder(existing)
    end
end)

-- ============================================================
-- STAFF DETECTION & MISC
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    if not State.StaffDetection then return end
    task.wait(1)
    pcall(function()
        if player:GetRankInGroup(551763520) >= 2 then
            LocalPlayer:Kick("[REIDU SAFEGUARD] Staff/High-Rank Detected: " .. player.Name)
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Insert then
    MainFrame.Visible = not MainFrame.Visible
    -- toggle button text will drift here unless you extract ToggleGUI to outer scope
    -- simplest: just leave it, or move the toggleBtn/ToggleGUI block to outer scope
    end
end)

task.spawn(function()
    local claimRemote
    pcall(function() claimRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("claimAll", 10) end)
    if not claimRemote then return end
    local function DoClaim()
        if claimRemote:IsA("RemoteEvent") then
            pcall(function() claimRemote:FireServer() end)
        else
            pcall(function() claimRemote:InvokeServer() end)
        end
    end
    while true do
        task.wait(2)
        if State.AutoIndex then
            DoClaim()
            task.wait(598)
        end
    end
end)

task.spawn(function()
    local eggRemote
    pcall(function() eggRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("RegularPet", 10) end)
    if not eggRemote then return end
    
    while true do
        task.wait(State.HatchDelay)
        if State.AutoHatch and State.SelectedEgg then
            local amountToHatch = State.Hatch3x and 3 or 1
            
            -- Fires the remote multiple times simultaneously based on your slider!
            for i = 1, (State.ExecutionMultiplier or 1) do
                task.spawn(function()
                    pcall(function() eggRemote:InvokeServer(State.SelectedEgg, amountToHatch) end)
                end)
            end
        end
    end
end)

task.spawn(function()
    local questRemote
    pcall(function() questRemote = ReplicatedStorage:WaitForChild("Events", 10):WaitForChild("QuestRemote", 10) end)
    if not questRemote then return end
    while true do
        task.wait(300)
        if State.AutoQuests then
            for slot = 1, 6 do
                pcall(function() questRemote:InvokeServer("ClaimReward", slot) end)
                task.wait(1)
            end
        end
    end
end)


SetLoadProgress(1.0, "ready!")
task.wait(1.0)
DismissLoader()

task.spawn(function()
    local autoloadName = GetAutoLoad()
    if autoloadName and autoloadName ~= "" then
        LoadConfig(autoloadName)
        RefreshAllUI()
    end
end)

-- ============================================================
-- CUTSCENE NUKER RUNTIME
-- ============================================================
task.spawn(function()
    local questRemote = nil
    while not questRemote do
        questRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("QuestRemote")
        task.wait(1)
    end

    questRemote.OnClientInvoke = function(action, ...)
    if State.NukeCutscenes and tostring(action):lower():find("cutscene") then
        return true
    end
end

    -- Also nuke any cutscene GUI that slips through
    task.spawn(function()
        while true do
            task.wait(0.2)
            if not State.NukeCutscenes then continue end
            pcall(function()
                local gui = LocalPlayer.PlayerGui:FindFirstChild("Main")
                if not gui then return end
                for _, frame in pairs(gui:GetChildren()) do
                    if frame.Name:lower():find("cutscene") then
                        frame.Visible = false
                    end
                end
            end)
        end
    end)
end)
-- ============================================================
-- NULLITY SERVER HOPPER
-- ============================================================
task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService     = game:GetService("HttpService")

    -- How long to wait after joining before declaring "no Nullity"
    local SCAN_WINDOW    = 12  -- seconds to watch for Nullity to spawn
    local MIN_HOP_DELAY  = 3   -- minimum seconds before we can hop again
    local lastHopTime    = 0

    -- Randomise a value ±jitter% to avoid pattern detection
    local function Jitter(base, pct)
        pct = pct or 0.25
        local range = base * pct
        return base + math.random(-math.floor(range * 10), math.floor(range * 10)) / 10
    end

    -- Fetch server list and pick the best candidate
    local function FetchServers()
        local servers = {}
        local ok, data = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet(
                    "https://games.roblox.com/v1/games/"
                    .. game.PlaceId
                    .. "/servers/Public?sortOrder=Asc&limit=100"
                )
            )
        end)
        if not ok or not data or not data.data then return servers end

        for _, s in ipairs(data.data) do
            -- Skip current server, full servers, and nearly-empty servers (bots)
            if s.id ~= game.JobId
            and s.playing >= 2                    -- not a ghost server
            and s.playing < s.maxPlayers          -- has room
            then
                table.insert(servers, s)
            end
        end

        -- Shuffle to avoid always hitting the same servers in the same order
        for i = #servers, 2, -1 do
            local j = math.random(i)
            servers[i], servers[j] = servers[j], servers[i]
        end

        return servers
    end

    local function DoHop()
        local now = tick()
        if now - lastHopTime < MIN_HOP_DELAY then return end
        lastHopTime = now

        -- Queue re-execution on next server
        local queue = (syn and syn.queue_on_teleport)
            or queue_on_teleport
            or (fluxus and fluxus.queue_on_teleport)
        if queue and getgenv().ReiduScriptSource then
            queue(getgenv().ReiduScriptSource)
        end

        local servers = FetchServers()
        if #servers == 0 then
            -- No good servers found, fall back to fresh instance
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            return
        end

        -- Pick a random server from the shuffled list rather than always index 1
        local pick = servers[math.random(math.min(#servers, 5))]
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
        end)
    end

    -- Watch for Nullity to appear in workspace
    local nullityFound  = false
    local scanStartTime = tick()

    -- Connection fires immediately if Nullity spawns while we're here
    local nullityConn
    nullityConn = workspace.ChildAdded:Connect(function(child)
        if child.Name == "Nullity" and child:IsA("Folder") then
            nullityFound = true
        end
    end)

    -- Also catch it if it already existed when we joined
    if workspace:FindFirstChild("Nullity") then
        nullityFound = true
    end

    while true do
        -- Jitter the wait slightly so hop cadence isn't perfectly regular
        task.wait(Jitter(1.0))

        if not State.AutoHopForNullity then
            nullityFound  = false
            scanStartTime = tick()
            continue
        end

        -- Nullity found! Let AutoMerchant handle it — stop hopping
        if nullityFound then
            print("[NullityHunter] Nullity spotted! Stopping hops.")
            -- Reset after a generous window so we hop again once merchant is done
            task.wait(Jitter(45))
            nullityFound  = false
            scanStartTime = tick()
            continue
        end

        -- Still within scan window — keep waiting
        local elapsed = tick() - scanStartTime
        if elapsed < SCAN_WINDOW then continue end

        -- Scan window expired, no Nullity — hop with jittered delay
        local hopWait = Jitter(State.HopDelay)
        print("[NullityHunter] No Nullity after " .. math.floor(elapsed) .. "s. Hopping in " .. string.format("%.1f", hopWait) .. "s...")
        task.wait(hopWait)

        -- Re-check in case it spawned while we were waiting
        if not nullityFound and State.AutoHopForNullity then
            DoHop()
        end

        -- Reset scan window for next server
        nullityFound  = false
        scanStartTime = tick()
    end
end)

print("[reidu's scripts] Loaded. Press INSERT to toggle.")

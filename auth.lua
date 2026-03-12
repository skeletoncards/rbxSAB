-- ============================================================
-- reidu's scripts — Auth Wrapper v8.2
-- Verifies key then loads main script from GitHub
-- ============================================================

local KEY_SERVER  = "https://reidu-key-server.onrender.com"
local KEY_FILE    = "reidu_session.json"
local SCRIPT_URL  = "https://raw.githubusercontent.com/skeletoncards/rbxSAB/refs/heads/main/ReiduSAB.lua"

local TweenService = game:GetService("TweenService")
local LocalPlayer  = game:GetService("Players").LocalPlayer
local UserId       = tostring(LocalPlayer.UserId)
local HttpService  = game:GetService("HttpService")

local httprequest = (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request

-- Queue script for re-execution on rejoin/teleport
getgenv().ReiduScriptSource = [[loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()]]

-- ── Session helpers ───────────────────────────────────────────
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

-- ── Key GUI ───────────────────────────────────────────────────
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

    -- Blurred dark overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.Parent = gui

    -- Main card — taller to breathe
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 380, 0, 270)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.65, 0)
    card.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    card.BorderSizePixel = 0
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    -- Outer glow stroke (animated later)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(110, 55, 200)
    stroke.Thickness = 1.5

    -- Coloured header band at the top
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 52)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(22, 16, 38)
    header.BorderSizePixel = 0
    header.Parent = card
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)
    -- Bottom corners square so it blends into the card body
    local headerCover = Instance.new("Frame")
    headerCover.Size = UDim2.new(1, 0, 0, 14)
    headerCover.Position = UDim2.new(0, 0, 1, -14)
    headerCover.BackgroundColor3 = Color3.fromRGB(22, 16, 38)
    headerCover.BorderSizePixel = 0
    headerCover.Parent = header

    -- Gradient shimmer across header
    local hGrad = Instance.new("UIGradient", header)
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(18, 10, 38)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 22, 72)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(18, 10, 38)),
    })
    hGrad.Rotation = 90

    -- Slowly rotate the gradient for a subtle shimmer
    task.spawn(function()
        local r = 0
        while gui.Parent do
            task.wait(0.05)
            r = (r + 0.5) % 360
            hGrad.Rotation = r
        end
    end)

    -- Title
    local title = Instance.new("TextLabel")
    title.Text = "reidu's scripts"
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(210, 180, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "Key Verification"
    subtitle.Size = UDim2.new(1, -20, 0, 16)
    subtitle.Position = UDim2.new(0, 10, 0, 30)
    subtitle.BackgroundTransparency = 1
    subtitle.TextColor3 = Color3.fromRGB(100, 80, 150)
    subtitle.TextSize = 10
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    subtitle.Parent = header

    -- Thin accent divider line below header
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -40, 0, 1)
    divider.Position = UDim2.new(0, 20, 0, 52)
    divider.BackgroundColor3 = Color3.fromRGB(60, 35, 110)
    divider.BorderSizePixel = 0
    divider.Parent = card

    -- Instruction text
    local sub = Instance.new("TextLabel")
    sub.Text = "Press  Get Key  in the Discord server to get your key."
    sub.Size = UDim2.new(1, -30, 0, 26)
    sub.Position = UDim2.new(0, 15, 0, 62)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = Color3.fromRGB(105, 90, 140)
    sub.TextSize = 10
    sub.Font = Enum.Font.Gotham
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.TextWrapped = true
    sub.Parent = card

    -- ── Roblox ID row ─────────────────────────────────────────
    local idCaption = Instance.new("TextLabel")
    idCaption.Text = "ROBLOX ID  •  auto-detected"
    idCaption.Size = UDim2.new(1, -30, 0, 11)
    idCaption.Position = UDim2.new(0, 15, 0, 95)
    idCaption.BackgroundTransparency = 1
    idCaption.TextColor3 = Color3.fromRGB(80, 65, 115)
    idCaption.TextSize = 9
    idCaption.Font = Enum.Font.GothamBold
    idCaption.TextXAlignment = Enum.TextXAlignment.Left
    idCaption.Parent = card

    local idDisplay = Instance.new("TextLabel")   -- TextLabel — cannot be focused or edited
    idDisplay.Text = UserId
    idDisplay.Size = UDim2.new(1, -30, 0, 28)
    idDisplay.Position = UDim2.new(0, 15, 0, 108)
    idDisplay.BackgroundColor3 = Color3.fromRGB(18, 14, 30)
    idDisplay.TextColor3 = Color3.fromRGB(170, 130, 255)
    idDisplay.TextSize = 11
    idDisplay.Font = Enum.Font.Code
    idDisplay.TextXAlignment = Enum.TextXAlignment.Center
    idDisplay.BorderSizePixel = 0
    idDisplay.Parent = card
    Instance.new("UICorner", idDisplay).CornerRadius = UDim.new(0, 6)
    local idStroke = Instance.new("UIStroke", idDisplay)
    idStroke.Color = Color3.fromRGB(50, 35, 85)
    idStroke.Thickness = 1

    -- ── Key input ──────────────────────────────────────────────
    local keyCaption = Instance.new("TextLabel")
    keyCaption.Text = "ENTER KEY"
    keyCaption.Size = UDim2.new(1, -30, 0, 11)
    keyCaption.Position = UDim2.new(0, 15, 0, 146)
    keyCaption.BackgroundTransparency = 1
    keyCaption.TextColor3 = Color3.fromRGB(80, 65, 115)
    keyCaption.TextSize = 9
    keyCaption.Font = Enum.Font.GothamBold
    keyCaption.TextXAlignment = Enum.TextXAlignment.Left
    keyCaption.Parent = card

    local box = Instance.new("TextBox")
    box.Text = ""                                  -- FIX: explicitly blank so Roblox doesn't show "TextBox"
    box.PlaceholderText = "Paste your key here..."
    box.Size = UDim2.new(1, -30, 0, 30)
    box.Position = UDim2.new(0, 15, 0, 159)
    box.BackgroundColor3 = Color3.fromRGB(18, 14, 30)
    box.TextColor3 = Color3.fromRGB(220, 210, 245)
    box.PlaceholderColor3 = Color3.fromRGB(75, 60, 110)
    box.TextSize = 11
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = card
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    local bPad = Instance.new("UIPadding", box)
    bPad.PaddingLeft = UDim.new(0, 10)
    local bStroke = Instance.new("UIStroke", box)
    bStroke.Color = Color3.fromRGB(50, 35, 85)
    bStroke.Thickness = 1
    box.Focused:Connect(function()
        TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(130, 70, 240)}):Play()
        TweenService:Create(box,    TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 17, 38)}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(50, 35, 85)}):Play()
        TweenService:Create(box,    TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 14, 30)}):Play()
    end)

    -- Status line
    local status = Instance.new("TextLabel")
    status.Text = ""
    status.Size = UDim2.new(1, -30, 0, 14)
    status.Position = UDim2.new(0, 15, 0, 196)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(220, 90, 90)
    status.TextSize = 10
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.TextWrapped = true
    status.Parent = card

    -- Verify button
    local btn = Instance.new("TextButton")
    btn.Text = "Verify Key"
    btn.Size = UDim2.new(1, -30, 0, 36)
    btn.Position = UDim2.new(0, 15, 0, 220)
    btn.BackgroundColor3 = Color3.fromRGB(100, 50, 195)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    -- Button gradient
    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(130, 70, 230)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(80,  35, 165)),
    })
    btnGrad.Rotation = 90

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 65, 220)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 50, 195)}):Play()
    end)

    -- Animate card in
    TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()

    -- Idle stroke pulse
    task.spawn(function()
        local colors = {
            Color3.fromRGB(110, 55, 200),
            Color3.fromRGB(150, 80, 240),
            Color3.fromRGB(110, 55, 200),
        }
        local i = 0
        while gui.Parent do
            i = i % #colors + 1
            TweenService:Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Color = colors[i]}):Play()
            task.wait(1.5)
        end
    end)

    getgenv()._reiduVerified = false

    local function SetStatus(text, color, loading)
        status.Text = text
        status.TextColor3 = color or Color3.fromRGB(220, 90, 90)
        btn.Text = loading and "Verifying..." or "Verify Key"
        btn.BackgroundColor3 = loading
            and Color3.fromRGB(40, 30, 65)
            or  Color3.fromRGB(100, 50, 195)
        btn.Active = not loading
    end

    local function Shake()
        for _ = 1, 3 do
            TweenService:Create(card, TweenInfo.new(0.05), {Position = UDim2.new(0.5, 8, 0.5, 0)}):Play()
            task.wait(0.05)
            TweenService:Create(card, TweenInfo.new(0.05), {Position = UDim2.new(0.5, -8, 0.5, 0)}):Play()
            task.wait(0.05)
        end
        TweenService:Create(card, TweenInfo.new(0.05), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    end

    btn.MouseButton1Click:Connect(function()
        local key = box.Text:match("^%s*(.-)%s*$")
        if key == "" then
            SetStatus("❌ Paste your key first.", Color3.fromRGB(220, 90, 90))
            Shake()
            return
        end

        SetStatus("⏳ Checking...", Color3.fromRGB(200, 175, 90), true)

        task.spawn(function()
            local valid, reason, expiresAt = VerifyWithServer(key)

            if valid then
                SaveSession(key, expiresAt)
                SetStatus("✅ Accepted! Loading...", Color3.fromRGB(110, 220, 120), false)
                TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(70, 210, 100)}):Play()
                task.wait(0.9)
                TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(0.5, 0, 0.42, 0),
                    BackgroundTransparency = 1,
                }):Play()
                task.wait(0.35)
                gui:Destroy()
                getgenv()._reiduVerified = true
            else
                ClearSession()
                local msg = "❌ " .. (reason or "Invalid key.")
                if reason and reason:find("expired")        then msg = "⏰ Key expired — press Get Key in Discord." end
                if reason and reason:find("used")           then msg = "🔒 Key already used — press Get Key in Discord." end
                if reason and reason:find("not registered") then msg = "🚫 This key belongs to a different account." end
                SetStatus(msg, Color3.fromRGB(220, 90, 90), false)
                TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(200, 60, 60)}):Play()
                task.delay(0.8, function()
                    TweenService:Create(stroke, TweenInfo.new(0.4), {Color = Color3.fromRGB(110, 55, 200)}):Play()
                end)
                Shake()
            end
        end)
    end)

    return function() return getgenv()._reiduVerified == true end
end

-- ── Auth flow ─────────────────────────────────────────────────
local session = LoadSession()
if not session then
    getgenv()._reiduVerified = false
    ShowKeyGui()
    repeat task.wait(0.1) until getgenv()._reiduVerified == true
else
    local h = math.floor(((session.expiresAt / 1000) - os.time()) / 3600)
    warn(string.format("[reidu] session valid — expires in ~%dh", h))
end

-- ── Load main script ──────────────────────────────────────────
loadstring(game:HttpGet(SCRIPT_URL))()

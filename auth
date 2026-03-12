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

    -- FIX 1: No more !getkey reference
    local sub = MakeLabel(
        "Press  Get Key  in the Discord server to receive your key.",
        36, 10, Color3.fromRGB(100, 95, 130)
    )
    sub.Size = UDim2.new(1, -20, 0, 28)

    -- FIX 2: Pure TextLabel — auto-detected from LocalPlayer, cannot be edited
    local idCaptionLabel = Instance.new("TextLabel")
    idCaptionLabel.Text = "Your Roblox ID (auto-detected)"
    idCaptionLabel.Size = UDim2.new(1, -20, 0, 12)
    idCaptionLabel.Position = UDim2.new(0, 10, 0, 57)
    idCaptionLabel.BackgroundTransparency = 1
    idCaptionLabel.TextColor3 = Color3.fromRGB(70, 65, 95)
    idCaptionLabel.TextSize = 9
    idCaptionLabel.Font = Enum.Font.Gotham
    idCaptionLabel.TextXAlignment = Enum.TextXAlignment.Left
    idCaptionLabel.Parent = card

    local idDisplay = Instance.new("TextLabel")  -- TextLabel, NOT TextBox
    idDisplay.Text = UserId                       -- locked to LocalPlayer.UserId
    idDisplay.Size = UDim2.new(1, -30, 0, 26)
    idDisplay.Position = UDim2.new(0, 15, 0, 68)
    idDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    idDisplay.TextColor3 = Color3.fromRGB(180, 140, 255)
    idDisplay.TextSize = 11
    idDisplay.Font = Enum.Font.Code
    idDisplay.TextXAlignment = Enum.TextXAlignment.Center
    idDisplay.BorderSizePixel = 0
    idDisplay.Parent = card
    Instance.new("UICorner", idDisplay).CornerRadius = UDim.new(0, 6)

    -- Key input box
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
                if reason and reason:find("expired")        then msg = "⏰ Key expired. Press Get Key in Discord." end
                if reason and reason:find("used")           then msg = "🔒 Key already used. Press Get Key in Discord." end
                if reason and reason:find("not registered") then msg = "🚫 This key is for a different account." end
                SetStatus(msg, Color3.fromRGB(220, 100, 100), false)
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

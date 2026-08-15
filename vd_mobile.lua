-- [[ STABLE SCRIPT: TOGGLE ESP & PRECISION SKILL CHECK ]] --
-- Credits: Rxmmy modified by Hamster Kaget
-- Controls: V Key (Toggle ESP) | Skill Check: Always ON

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local localPlayer = Players.LocalPlayer

-- Detect if running on mobile or PC
local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

----------------------------------------------------------------
-- SETTINGS & CONFIGURATION
----------------------------------------------------------------
local Config = {
    ESP = {
        Enabled = true,
        Players = {
            ["Killer"] = {Color = Color3.fromRGB(255, 93, 108)},
            ["Survivor"] = {Color = Color3.fromRGB(64, 224, 255)}
        },
        -- hapus komen kalau mau menampilkan ESP untuk objek tertentu, tapi hati-hati karena bisa bikin lag dan ganggu visual
       --[[ Objects = {
            {Name = "Generator", Color = Color3.fromRGB(210, 87, 255)},
            {Name = "Gate", Color = Color3.fromRGB(255, 255, 255)},
            {Name = "Palletwrong", Color = Color3.fromRGB(74, 255, 181)},
            {Name = "Window", Color = Color3.fromRGB(74, 255, 181)},
            {Name = "Hook", Color = Color3.fromRGB(132, 255, 169)}
        } --]]
    }
}

----------------------------------------------------------------
-- TOGGLE SYSTEM (V KEY)
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.V then
        SetESPEnabled(not Config.ESP.Enabled)
    end
end)

-- Central setter so both PC (V) and mobile button use the same logic
local MobileToggleGui = nil
local function SetESPEnabled(enabled)
    Config.ESP.Enabled = enabled
    for _, obj in ipairs(workspace:GetDescendants()) do
        local h = obj:FindFirstChild("RxmmyESP")
        if h then h.Enabled = enabled end
        local g = obj:FindFirstChild("RxmmyESPGui")
        if g and g:IsA("BillboardGui") then g.Enabled = enabled end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("RxmmyESP")
            if h then h.Enabled = enabled end
            local g = p.Character:FindFirstChild("RxmmyESPGui")
            if g and g:IsA("BillboardGui") then g.Enabled = enabled end
        end
    end
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ESP Status",
        Text = enabled and "ESP has been ENABLED." or "ESP has been DISABLED.",
        Duration = 3
    })
    warn("ESP Status: " .. (enabled and "ENABLED" or "DISABLED"))
    if MobileToggleGui and MobileToggleGui:FindFirstChild("ToggleESPButton") then
        MobileToggleGui.ToggleESPButton.Text = enabled and "ESP: ON" or "ESP: OFF"
    end
end

local function SetupMobileToggle()
    if not UserInputService.TouchEnabled then return end
    local PlayerGui = localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui")
    if PlayerGui:FindFirstChild("RxmmyMobileToggleGui") then
        MobileToggleGui = PlayerGui:FindFirstChild("RxmmyMobileToggleGui")
        return
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "RxmmyMobileToggleGui"
    screen.ResetOnSpawn = false
    screen.Parent = PlayerGui
    MobileToggleGui = screen

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleESPButton"
    btn.Size = UDim2.new(0,140,0,42)
    btn.Position = UDim2.new(1, -150, 1, -90)
    btn.AnchorPoint = Vector2.new(0,0)
    btn.BackgroundTransparency = 0.2
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Text = Config.ESP.Enabled and "ESP: ON" or "ESP: OFF"
    btn.Parent = screen
    -- Make button draggable (supports touch and mouse)
    btn.Active = true
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            -- clamp to screen bounds
            local screenW, screenH = tonumber(game:GetService("Workspace")) and 0 or (math.max(0, tonumber(game:GetService("GuiService") and 0) or 0))
            btn.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        SetESPEnabled(not Config.ESP.Enabled)
    end)
end

----------------------------------------------------------------
-- ESP SYSTEM (STABLE - NO SELF HIGHLIGHT)
----------------------------------------------------------------
local function ApplyHighlight(obj, color)
    if not obj or obj == localPlayer.Character or obj:FindFirstChild("RxmmyESP") then return end
    
    local h = Instance.new("Highlight")
    h.Name = "RxmmyESP"
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = Color3.new(1, 1, 1)
    h.FillTransparency = 0.7
    h.OutlineTransparency = 0.2
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled = Config.ESP.Enabled
    h.Parent = obj
    
    -- If this is a character model, add a BillboardGui showing username and distance
    if typeof(obj) == "Instance" and obj:IsA("Model") then
        local player = Players:GetPlayerFromCharacter(obj)
        local attachPart = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
        if attachPart then
            local existingGui = attachPart:FindFirstChild("RxmmyESPGui") or obj:FindFirstChild("RxmmyESPGui")
            if existingGui then existingGui:Destroy() end

            local gui = Instance.new("BillboardGui")
            gui.Name = "RxmmyESPGui"
            gui.Adornee = attachPart
            gui.Size = UDim2.new(0, 160, 0, 28)
            gui.StudsOffset = Vector3.new(0, 2.6, 0)
            gui.AlwaysOnTop = true
            gui.Enabled = Config.ESP.Enabled
            gui.Parent = attachPart

            local lbl = Instance.new("TextLabel")
            lbl.Name = "RxmmyESPLabel"
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextScaled = true
            lbl.TextColor3 = player and GetPlayerESPColor(player) or Color3.new(1,1,1)
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
            lbl.TextStrokeTransparency = 0.5
            lbl.Font = Enum.Font.SourceSansBold
            lbl.Parent = gui

            -- updater loop
            task.spawn(function()
                while gui and gui.Parent do
                    local nameText = player and player.Name or (obj.Name or "Player")
                    local dist = 0
                    if localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and attachPart and attachPart.Position then
                        dist = math.floor((localPlayer.Character.HumanoidRootPart.Position - attachPart.Position).Magnitude)
                    end
                    lbl.Text = string.format("%s | %d studs", nameText, dist)
                    lbl.TextColor3 = player and GetPlayerESPColor(player) or Color3.new(1,1,1)
                    task.wait(0.12)
                end
            end)
        end
    end
end

local function GetRole(p)
    if p.Team and localPlayer.Team then
        local teamName = p.Team.Name:lower()
        local myTeam = localPlayer.Team.Name:lower()

        if teamName:find("killer") or teamName:find("murderer") or teamName:find("hunter") or teamName:find("slasher") or teamName:find("beast") then 
            return "Killer" 
        end

        if myTeam:find("survivor") and teamName ~= myTeam then
            return "Killer"
        end
    end
    return "Survivor"
end

local function GetPlayerESPColor(p)
    local role = p and GetRole(p) or "Survivor"
    local config = Config.ESP.Players[role]
    return config and config.Color or Color3.fromRGB(255, 255, 255)
end

local function SetupPlayerESP(p)
    if p == localPlayer then return end
    
    local function Refresh()
        if p.Character then
            local existing = p.Character:FindFirstChild("RxmmyESP")
            if existing then existing:Destroy() end
            local existingGui = p.Character:FindFirstChild("RxmmyESPGui")
            if existingGui then existingGui:Destroy() end
            task.wait(1)
            ApplyHighlight(p.Character, Config.ESP.Players[GetRole(p)].Color)
        end
    end

    p.CharacterAdded:Connect(Refresh)
    p:GetPropertyChangedSignal("Team"):Connect(Refresh)
    Refresh()
end

local function SetupObjectESP()
    task.spawn(function()
        while true do
            for _, obj in ipairs(workspace:GetDescendants()) do
                for _, data in ipairs(Config.ESP.Objects) do
                    if obj.Name == data.Name then ApplyHighlight(obj, data.Color) end
                end
            end
            task.wait(5)
        end
    end)
end

----------------------------------------------------------------
-- ANTI-CRASH AUTO SKILL CHECK
----------------------------------------------------------------
local function StartSkillCheckLogic()
    local function ConnectUI()
        local PlayerGui = localPlayer:WaitForChild("PlayerGui")
        local CheckGui = PlayerGui:WaitForChild("SkillCheckPromptGui", 10)
        if not CheckGui then return end
        
        local Check = CheckGui:WaitForChild("Check")
        local Line = Check:WaitForChild("Line")
        local Goal = Check:WaitForChild("Goal")
        local HeartbeatConn = nil

        Check:GetPropertyChangedSignal("Visible"):Connect(function()
            if Check.Visible and localPlayer.Team and localPlayer.Team.Name:lower():find("survivor") then
                if HeartbeatConn then HeartbeatConn:Disconnect(); HeartbeatConn = nil end

                local lastHandledTime = 0
                local prevLR = (Line and Line.Rotation or 0) % 360
                local lastGoalRotation = nil
                local goalChangedTime = 0
                local goalIgnoreWindow = 0.02 -- ignore detection for this many seconds after goal changes

                local function normalizeIntervals(s,e)
                    if s <= e then return { {s,e} } end
                    return { {s,360}, {0,e} }
                end

                local function intervalsOverlap(a1,a2,b1,b2)
                    local ai = normalizeIntervals(a1,a2)
                    local bi = normalizeIntervals(b1,b2)
                    for _,A in ipairs(ai) do
                        for _,B in ipairs(bi) do
                            if not (A[2] < B[1] or B[2] < A[1]) then
                                return true
                            end
                        end
                    end
                    return false
                end

                HeartbeatConn = RunService.Stepped:Connect(function()
                    if not Check.Visible then 
                        if HeartbeatConn then HeartbeatConn:Disconnect(); HeartbeatConn = nil end
                        return 
                    end

                    if not Line or not Goal or not Line.Parent or not Goal.Parent then return end

                    local okG, gr = pcall(function() return Goal.Rotation end)
                    local okL, lr = pcall(function() return Line.Rotation end)
                    if not okG or not okL or not gr or not lr then return end

                    gr = gr % 360
                    -- detect goal rotation changes and set a short ignore window
                    if not lastGoalRotation or math.abs(((gr - lastGoalRotation + 180) % 360) - 180) > 0.5 then
                        lastGoalRotation = gr
                        goalChangedTime = tick()
                    end
                    lr = lr % 360
                    local gs, ge = (gr + 104) % 360, (gr + 114) % 360

                    local diff = ((lr - prevLR + 540) % 360) - 180
                    local moveStart, moveEnd
                    if diff >= 0 then
                        moveStart = prevLR
                        moveEnd = (prevLR + diff) % 360
                    else
                        moveStart = (prevLR + diff) % 360
                        moveEnd = prevLR
                    end

                    -- expand movement interval slightly to catch very fast passes
                    moveStart = (moveStart - 3) % 360
                    moveEnd = (moveEnd + 3) % 360

                    local now = tick()
                    -- if goal just changed, ignore immediate triggers to avoid early misses
                    if (now - goalChangedTime) < goalIgnoreWindow then
                        prevLR = lr
                        return
                    end
                    -- very short debounce to allow rapid successive checks
                    if (now - lastHandledTime) < 0.008 then
                        prevLR = lr
                        return
                    end

                    -- Trigger when the needle crosses the goal CENTER (more robust for stacked checks)
                    local center = (gr + 109) % 360

                    local function pointInInterval(pt, s, e)
                        if s <= e then return pt >= s and pt <= e end
                        return pt >= s or pt <= e
                    end

                    local crossed = false
                    if pointInInterval(center, moveStart, moveEnd) then
                        crossed = true
                    else
                        -- fallback: if needle is currently inside goal arc
                        if pointInInterval(lr, gs, ge) then crossed = true end
                    end

                    if crossed then
                        lastHandledTime = now
                        if IsMobile then
                            -- For mobile: simulate click/tap on the Check element
                            local function simulateClick(guiObject)
                                if guiObject:IsA("GuiButton") or guiObject:IsA("TextButton") or guiObject:IsA("ImageButton") then
                                    guiObject:TriggerEvent("MouseButton1Click")
                                else
                                    -- For other GUI types, try to trigger InputBegan event
                                    local UserInput = UserInputService
                                    guiObject:TriggerEvent("InputBegan", {UserInputType = Enum.UserInputType.Touch})
                                end
                            end
                            simulateClick(Check)
                        else
                            -- For PC: send Space key
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        end
                    end

                    prevLR = lr
                end)
            elseif HeartbeatConn then
                HeartbeatConn:Disconnect(); HeartbeatConn = nil
            end
        end)
    end

    localPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        ConnectUI()
    end)
    ConnectUI()
end

----------------------------------------------------------------
-- INITIALIZE
----------------------------------------------------------------
task.spawn(StartSkillCheckLogic)
for _, p in ipairs(Players:GetPlayers()) do SetupPlayerESP(p) end
Players.PlayerAdded:Connect(SetupPlayerESP)
SetupObjectESP()
SetupMobileToggle()

warn("Script by Rxmmy Loaded!")
warn("ESP: Toggle V | Anti-Disconnect Fix Applied")

----------------------------------------------------------------
-- NOTIFICATION POP-UP (ENGLISH)
----------------------------------------------------------------
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Hamster Kaget",
    Text = "ESP & Skill Check loaded successfully!",
    Duration = 5
})

-- Savannah Life: Kill Aura + ESP + Fly + Noclip (MOBILE FLY FIXED)
-- Press T → Kill Aura (40 studs)
-- Press Y → Fly (UNIVERSAL - works on all executors)
-- Press U → ESP
-- Press Z → Godmode
-- Press X → Noclip
-- Press / (slash) → Open Command Bar
-- MOBILE: Tap buttons on screen! (▲▼ for fly up/down)

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- REMOTES
local BasicAttack = RS:WaitForChild("AttackHandlerRemoteEvent")
local SpecialAttack = RS:WaitForChild("SpecialAttackRemoteEvent_RegularAttack")
local ChargedAttack = RS:WaitForChild("SpecialAttackRemoteEvent_ChargedAttack")
local PlayerDamageSelf = RS:WaitForChild("PlayerDamageSelfRemoteEvent")

local aura = false
local fly = false
local esp = false
local noclip = false
local flySpeed = 60
local viewingPlayer = nil

-- FLY VARIABLES
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

-- MOBILE FLY VARIABLES - Track which movement keys are pressed on mobile
local mobileKeysPressed = {
    W = false,
    A = false,
    S = false,
    D = false,
    Space = false,
    Ctrl = false
}

-- NOCLIP VARIABLES
local noclipConnection = nil
local originalCollisions = {}

-- SAFE NOTIFICATION FUNCTION
local function sendNotification(title, text, duration)
    for i = 1, 10 do
        local success = pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = duration or 5
            })
        end)
        if success then break end
        task.wait(0.5)
    end
end

-- STARTUP MESSAGE
sendNotification("Mr.Pig says hello", "The script has launched successfully", 5)
print("Mr.Pig says hello - Script loaded!")

-- Create startup screen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MrPigStartup"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true

local bgFrame = Instance.new("Frame")
bgFrame.Parent = screenGui
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.Position = UDim2.new(0, 0, 0, 0)
bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bgFrame.BackgroundTransparency = 0.2
bgFrame.BorderSizePixel = 0
bgFrame.ZIndex = 10

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = bgFrame
titleLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
titleLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐷 MR. PIG SAYS HELLO 🐷"
titleLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
titleLabel.TextSize = 60
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextStrokeTransparency = 0.5
titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.ZIndex = 11

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Parent = bgFrame
subtitleLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
subtitleLabel.Position = UDim2.new(0.1, 0, 0.5, 0)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "The script has launched successfully!"
subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitleLabel.TextSize = 36
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextStrokeTransparency = 0.5
subtitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subtitleLabel.ZIndex = 11

local controlsLabel = Instance.new("TextLabel")
controlsLabel.Parent = bgFrame
controlsLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
controlsLabel.Position = UDim2.new(0.1, 0, 0.65, 0)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Text = "T = Aura | Y = Fly | U = ESP | X = Noclip | / = Commands"
controlsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
controlsLabel.TextSize = 24
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.TextStrokeTransparency = 0.5
controlsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
controlsLabel.ZIndex = 11

screenGui.Parent = player:WaitForChild("PlayerGui")

task.delay(5, function()
    if screenGui then
        screenGui:Destroy()
    end
end)

-- ==========================================
-- UNIVERSAL FLY FUNCTION WITH MOBILE SUPPORT
-- ==========================================
local function startFly()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    
    -- Clean up old fly objects
    local oldBV = root:FindFirstChild("FlyVelocity")
    local oldBG = root:FindFirstChild("FlyGyro")
    if oldBV then oldBV:Destroy() end
    if oldBG then oldBG:Destroy() end
    
    -- Disable default controls
    hum.PlatformStand = true
    
    -- Create BodyVelocity
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root
    
    -- Create BodyGyro
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.D = 100
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
    
    -- Fly loop - checks both keyboard AND mobile keys
    flyConnection = RunService.Heartbeat:Connect(function()
        if not fly then return end
        if not char or not char.Parent then
            stopFly()
            return
        end
        if not root or not root.Parent then
            stopFly()
            return
        end
        
        local camera = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)
        
        -- Get input from BOTH keyboard and mobile buttons
        if UIS:IsKeyDown(Enum.KeyCode.W) or mobileKeysPressed.W then
            moveDir = moveDir + camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) or mobileKeysPressed.S then
            moveDir = moveDir - camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) or mobileKeysPressed.A then
            moveDir = moveDir - camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) or mobileKeysPressed.D then
            moveDir = moveDir + camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or mobileKeysPressed.Space then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or mobileKeysPressed.Ctrl then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end
        
        -- Apply movement
        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir.Unit * flySpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Face camera direction
        bodyGyro.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector)
    end)
    
    print("Fly ON")
    sendNotification("Fly", "ON - WASD + Space/Ctrl", 3)
end

local function stopFly()
    -- Disconnect loop
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    -- Remove fly objects
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
    -- Also check character for leftover objects
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if root then
            local oldBV = root:FindFirstChild("FlyVelocity")
            local oldBG = root:FindFirstChild("FlyGyro")
            if oldBV then oldBV:Destroy() end
            if oldBG then oldBG:Destroy() end
        end
        
        -- Re-enable controls
        if hum then
            hum.PlatformStand = false
        end
    end
    
    print("Fly OFF")
    sendNotification("Fly", "OFF", 3)
end

local function toggleFly()
    fly = not fly
    if fly then
        startFly()
    else
        stopFly()
    end
end

-- Fix fly on respawn
player.CharacterAdded:Connect(function(char)
    if fly then
        task.wait(0.5)
        startFly()
    end
end)

-- ==========================================
-- NOCLIP FUNCTIONS
-- ==========================================
local function startNoclip()
    local char = player.Character
    if not char then return end
    
    -- Store original collision groups
    originalCollisions = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
            part.CanCollide = false
        end
    end
    
    noclipConnection = RunService.Heartbeat:Connect(function()
        if not noclip or not char or not char.Parent then return end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    
    print("Noclip ON")
    sendNotification("Noclip", "ON", 3)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    local char = player.Character
    if char then
        for part, collide in pairs(originalCollisions) do
            if part and part.Parent then
                part.CanCollide = collide
            end
        end
    end
    
    originalCollisions = {}
    print("Noclip OFF")
    sendNotification("Noclip", "OFF", 3)
end

local function toggleNoclip()
    noclip = not noclip
    if noclip then
        startNoclip()
    else
        stopNoclip()
    end
end

player.CharacterAdded:Connect(function(char)
    if noclip then
        task.wait(0.5)
        startNoclip()
    end
end)

-- ==========================================
-- VIEW PLAYER FUNCTION
-- ==========================================
local function viewPlayer(targetName)
    local targetPlayer = nil
    
    -- Try to find exact match first
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower() == targetName:lower() then
            targetPlayer = p
            break
        end
    end
    
    -- Try partial match if no exact match
    if not targetPlayer then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():find(targetName:lower()) then
                targetPlayer = p
                break
            end
        end
    end
    
    if targetPlayer and targetPlayer ~= player then
        if targetPlayer.Character then
            viewingPlayer = targetPlayer
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                workspace.CurrentCamera.CFrame = targetRoot.CFrame + targetRoot.CFrame.LookVector * 10
                sendNotification("Viewing", "Now viewing " .. targetPlayer.Name, 3)
                return true
            end
        end
    end
    
    sendNotification("View Player", "Player not found!", 3)
    return false
end

local function stopViewing()
    if player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            workspace.CurrentCamera.Focus = root.CFrame
            workspace.CurrentCamera.CFrame = root.CFrame + root.CFrame.LookVector * 10
        end
    end
    viewingPlayer = nil
    sendNotification("Viewing", "Stopped viewing", 3)
end

-- Update viewing camera
spawn(function()
    while task.wait(0.1) do
        if viewingPlayer and viewingPlayer.Character then
            local targetRoot = viewingPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                workspace.CurrentCamera.CFrame = targetRoot.CFrame + targetRoot.CFrame.LookVector * 10
            end
        end
    end
end)

-- ==========================================
-- RESET FUNCTION
-- ==========================================
local function resetPlayer()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
            sendNotification("Reset", "Respawning...", 2)
        end
    end
end

-- ==========================================
-- COMMAND BAR
-- ==========================================
local commandBarOpen = false
local commandGui = nil

local function createCommandBar()
    if commandGui then commandGui:Destroy() end
    
    commandGui = Instance.new("ScreenGui")
    commandGui.Name = "CommandBar"
    commandGui.ResetOnSpawn = false
    commandGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local bgFrame = Instance.new("Frame")
    bgFrame.Parent = commandGui
    bgFrame.Size = UDim2.new(0, 500, 0, 50)
    bgFrame.Position = UDim2.new(0.5, -250, 0.5, -25)
    bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bgFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bgFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = bgFrame
    stroke.Color = Color3.fromRGB(255, 105, 180)
    stroke.Thickness = 2
    
    local textBox = Instance.new("TextBox")
    textBox.Parent = bgFrame
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 18
    textBox.Font = Enum.Font.GothamBold
    textBox.PlaceholderText = "Commands: speed <number>, view <player>, reset, stop"
    textBox.Text = ""
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local cmd = textBox.Text:lower():gsub("^%s+|%s+$", "")
            local parts = cmd:split(" ")
            local command = parts[1]
            
            if command == "speed" then
                local newSpeed = tonumber(parts[2])
                if newSpeed then
                    flySpeed = newSpeed
                    sendNotification("Speed", "Set to " .. newSpeed, 3)
                else
                    sendNotification("Speed", "Usage: speed <number>", 3)
                end
            elseif command == "view" then
                local targetName = table.concat(parts, " ", 2)
                if targetName and targetName ~= "" then
                    viewPlayer(targetName)
                else
                    sendNotification("View", "Usage: view <player>", 3)
                end
            elseif command == "stop" then
                stopViewing()
            elseif command == "reset" then
                resetPlayer()
            else
                sendNotification("Command", "Unknown command: " .. command, 3)
            end
            
            commandGui:Destroy()
            commandGui = nil
            commandBarOpen = false
        end
    end)
    
    commandGui.Parent = player:WaitForChild("PlayerGui")
    task.wait(0.1)
    textBox:CaptureFocus()
end

local function toggleCommandBar()
    if commandBarOpen then
        if commandGui then
            commandGui:Destroy()
            commandGui = nil
        end
        commandBarOpen = false
    else
        commandBarOpen = true
        createCommandBar()
    end
end

-- ==========================================
-- MOBILE GUI (CLICKABLE BUTTONS WITH FLY CONTROLS)
-- ==========================================
local mobileGui = Instance.new("ScreenGui")
mobileGui.Name = "MrPigMobileGUI"
mobileGui.ResetOnSpawn = false
mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mobileGui.IgnoreGuiInset = true

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Parent = mobileGui
mainFrame.Size = UDim2.new(0, 60, 0, 400)
mainFrame.Position = UDim2.new(1, -70, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Parent = mainFrame
mainStroke.Color = Color3.fromRGB(255, 105, 180)
mainStroke.Thickness = 2

-- Title
local mobileTitle = Instance.new("TextLabel")
mobileTitle.Parent = mainFrame
mobileTitle.Size = UDim2.new(1, 0, 0, 25)
mobileTitle.Position = UDim2.new(0, 0, 0, 5)
mobileTitle.BackgroundTransparency = 1
mobileTitle.Text = "🐷"
mobileTitle.TextColor3 = Color3.fromRGB(255, 105, 180)
mobileTitle.TextSize = 18
mobileTitle.Font = Enum.Font.FredokaOne

-- Button creation function
local function createButton(name, position, defaultColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = mainFrame
    btn.Size = UDim2.new(0, 50, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = defaultColor or Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    return btn
end

-- Create buttons
local auraBtn = createButton("Aura", UDim2.new(0.5, -25, 0, 32))
local flyBtn = createButton("Fly", UDim2.new(0.5, -25, 0, 77))
local espBtn = createButton("ESP", UDim2.new(0.5, -25, 0, 122))
local noclipBtn = createButton("Clip", UDim2.new(0.5, -25, 0, 212))
local cmdBtn = createButton("Cmd", UDim2.new(0.5, -25, 0, 257))

-- MOBILE FLY MOVEMENT BUTTONS (D-Pad style)
-- Arrow keys: ▲▼◄► for movement
-- W/A/S/D equivalents
local flyUpBtn = createButton("▲", UDim2.new(0.5, -25, 0, 302))      -- W (forward)
local flyDownBtn = createButton("▼", UDim2.new(0.5, -25, 0, 347))    -- S (backward)
local flyLeftBtn = createButton("◄", UDim2.new(0, 5, 0, 325))        -- A (left)
local flyRightBtn = createButton("►", UDim2.new(1, -55, 0, 325))     -- D (right)
local flyUpAltBtn = createButton("↑", UDim2.new(0, 65, 0, 302))      -- Space (ascend)
local flyDownAltBtn = createButton("↓", UDim2.new(0, 65, 0, 347))    -- Ctrl (descend)

-- Function to update button colors
local function updateButtonColors()
    auraBtn.BackgroundColor3 = aura and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
    flyBtn.BackgroundColor3 = fly and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
    espBtn.BackgroundColor3 = esp and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
    noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
end

-- Button click handlers
auraBtn.MouseButton1Click:Connect(function()
    aura = not aura
    updateButtonColors()
end)

flyBtn.MouseButton1Click:Connect(function()
    toggleFly()
    updateButtonColors()
end)

espBtn.MouseButton1Click:Connect(function()
    esp = not esp
    updateButtonColors()
end)

noclipBtn.MouseButton1Click:Connect(function()
    toggleNoclip()
    updateButtonColors()
end)

cmdBtn.MouseButton1Click:Connect(function()
    toggleCommandBar()
end)

-- MOBILE FLY MOVEMENT BUTTON HANDLERS - These control the mobileKeysPressed table
flyUpBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.Space = true
end)

flyUpBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.Space = false
end)

flyDownBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.Ctrl = true
end)

flyDownBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.Ctrl = false
end)

flyUpBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.W = true
end)

flyUpBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.W = false
end)

flyDownBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.S = true
end)

flyDownBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.S = false
end)

flyLeftBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.A = true
end)

flyLeftBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.A = false
end)

flyRightBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.D = true
end)

flyRightBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.D = false
end)

flyUpAltBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.Space = true
end)

flyUpAltBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.Space = false
end)

flyDownAltBtn.MouseButton1Down:Connect(function()
    mobileKeysPressed.Ctrl = true
end)

flyDownAltBtn.MouseButton1Up:Connect(function()
    mobileKeysPressed.Ctrl = false
end)

mobileGui.Parent = player:WaitForChild("PlayerGui")

-- ==========================================
-- KEYBIND DISPLAY (BOTTOM)
-- ==========================================
local keybindGui = Instance.new("ScreenGui")
keybindGui.Name = "KeybindDisplay"
keybindGui.ResetOnSpawn = false
keybindGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local keybindFrame = Instance.new("Frame")
keybindFrame.Parent = keybindGui
keybindFrame.Size = UDim2.new(0, 600, 0, 80)
keybindFrame.Position = UDim2.new(0.5, -300, 1, -90)
keybindFrame.BackgroundTransparency = 1
keybindFrame.BorderSizePixel = 0

local keybindText = Instance.new("TextLabel")
keybindText.Parent = keybindFrame
keybindText.Size = UDim2.new(1, 0, 1, 0)
keybindText.BackgroundTransparency = 1
keybindText.TextColor3 = Color3.fromRGB(255, 255, 255)
keybindText.TextSize = 16
keybindText.Font = Enum.Font.GothamBold
keybindText.TextStrokeTransparency = 0.5
keybindText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
keybindText.Text = "Loading..."

keybindGui.Parent = player:WaitForChild("PlayerGui")

-- MR. PIG WATERMARK
local pigLabel = Instance.new("TextLabel")
pigLabel.Parent = keybindGui
pigLabel.Size = UDim2.new(0, 120, 0, 30)
pigLabel.Position = UDim2.new(0, 10, 0, 10)
pigLabel.BackgroundTransparency = 1
pigLabel.BorderSizePixel = 0
pigLabel.Text = "Mr.Pig 🐷"
pigLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
pigLabel.TextSize = 20
pigLabel.Font = Enum.Font.FredokaOne
pigLabel.TextStrokeTransparency = 0.5
pigLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

-- Function to update keybind display
local function updateKeybindDisplay()
    local auraColor = aura and "🟢" or "🔴"
    local flyColor = fly and "🟢" or "🔴"
    local espColor = esp and "🟢" or "🔴"
    local godColor = godmode and "🟢" or "🔴"
    local noclipColor = noclip and "🟢" or "🔴"
    
    keybindText.Text = string.format(
        "%s T-Aura | %s Y-Fly | %s U-ESP | %s Z-God | %s X-Clip | /-Cmd",
        auraColor, flyColor, espColor, godColor, noclipColor
    )
    
    updateButtonColors()
end

-- Update display loop
spawn(function()
    while task.wait(0.5) do
        updateKeybindDisplay()
    end
end)

-- ==========================================
-- KEYBINDS (PC)
-- ==========================================
UIS.InputBegan:Connect(function(k, gp)
    if gp then return end
    if UIS:GetFocusedTextBox() then return end
    
    if k.KeyCode == Enum.KeyCode.T then
        aura = not aura
        local msg = aura and "Kill Aura ON" or "Kill Aura OFF"
        sendNotification("Kill Aura", msg, 3)
        updateKeybindDisplay()
    end

    if k.KeyCode == Enum.KeyCode.Y then
        toggleFly()
        updateKeybindDisplay()
    end

    if k.KeyCode == Enum.KeyCode.U then
        esp = not esp
        local msg = esp and "ESP ON" or "ESP OFF"
        sendNotification("ESP", msg, 3)
        updateKeybindDisplay()
    end
    
    if k.KeyCode == Enum.KeyCode.X then
        toggleNoclip()
        updateKeybindDisplay()
    end
    
    if k.KeyCode == Enum.KeyCode.Slash then
        toggleCommandBar()
    end
end)

-- ==========================================
-- CHAT COMMANDS
-- ==========================================
player.Chatted:Connect(function(message)
    if message:lower() == "!rejoin" then
        sendNotification("Rejoining", "Rejoining server...", 3)
        task.wait(0.5)
        local TeleportService = game:GetService("TeleportService")
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
        TeleportService:Teleport(game.PlaceId, player)
    end
end)

-- ==========================================
-- INFINITE STAMINA LOOP
-- ==========================================
spawn(function()
    while task.wait(0.1) do
        if player.Character then
            pcall(function()
                player.Character:SetAttribute("Stamina", 100)
            end)
        end
    end
end)

-- ==========================================
-- KILL AURA LOOP
-- ==========================================
spawn(function()
    while task.wait(0.1) do
        if not aura or not player.Character then continue end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local closestPlayer = nil
        local closestDistance = 40

        for _, v in pairs(Players:GetPlayers()) do
            if v == player then continue end
            local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
            local hrp = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local distance = (root.Position - hrp.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = {humanoid = hum, distance = distance}
                end
            end
        end

        if closestPlayer then
            pcall(function()
                BasicAttack:FireServer(closestPlayer.humanoid)
            end)
            pcall(function()
                SpecialAttack:FireServer(closestPlayer.humanoid)
            end)
        end
    end
end)

-- ==========================================
-- ESP SYSTEM
-- ==========================================
local function createESP(character)
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    
    local oldESP = root:FindFirstChild("PlayerESP")
    if oldESP then oldESP:Destroy() end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerESP"
    billboard.Parent = root
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = billboard
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = character.Name
    nameLabel.TextStrokeTransparency = 0.5
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Parent = billboard
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.new(0, 1, 0)
    healthLabel.TextSize = 12
    healthLabel.Font = Enum.Font.SourceSans
    healthLabel.TextStrokeTransparency = 0.5
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not esp or not character or not character.Parent or not humanoid or not humanoid.Parent then
            if billboard then billboard:Destroy() end
            if connection then connection:Disconnect() end
            return
        end
        
        local health = math.floor(humanoid.Health)
        local maxHealth = math.floor(humanoid.MaxHealth)
        healthLabel.Text = health .. "/" .. maxHealth .. " HP"
        
        local healthPercent = health / maxHealth
        if healthPercent > 0.5 then
            healthLabel.TextColor3 = Color3.new(0, 1, 0)
        elseif healthPercent > 0.25 then
            healthLabel.TextColor3 = Color3.new(1, 1, 0)
        else
            healthLabel.TextColor3 = Color3.new(1, 0, 0)
        end
    end)
end

local function updateESP()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local root = v.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local hasESP = root:FindFirstChild("PlayerESP")
                if esp and not hasESP then
                    createESP(v.Character)
                elseif not esp and hasESP then
                    hasESP:Destroy()
                end
            end
        end
    end
end

Players.PlayerAdded:Connect(function(v)
    v.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if esp then createESP(char) end
    end)
end)

for _, v in pairs(Players:GetPlayers()) do
    if v ~= player then
        v.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if esp then createESP(char) end
        end)
        if v.Character and esp then
            createESP(v.Character)
        end
    end
end

spawn(function()
    while task.wait(1) do
        updateESP()
    end
end)

print("==========================================")
print("🐷 MR.PIG SCRIPT LOADED 🐷")
print("")
print("T = Kill Aura")
print("Y = Fly (WASD + Space/Ctrl)")
print("U = ESP")
print("X = Noclip")
print("/ = Command Bar")
print("")
print("MOBILE FLY CONTROLS: Use ▲ ▼ buttons to fly up/down!")
print("")
print("Commands:")
print("  speed <number> - Change fly speed")
print("  view <player> - View another player's camera")
print("  stop - Stop viewing")
print("  reset - Reset instantly")
print("")
print("!rejoin = Rejoin server")
print("==========================================" )

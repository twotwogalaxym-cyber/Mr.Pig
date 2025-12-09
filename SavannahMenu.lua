-- Savannah Life: Kill Aura + ESP + Fly
-- Press T → Kill Aura (40 studs)
-- Press Y → Fly
-- Press U → ESP
-- Press L → Teleport to location
-- Chat: ;goto playername → Teleport to player
-- Chat: !rejoin → Rejoin server
-- MOBILE: Tap buttons on screen!

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- REMOTES
local BasicAttack = RS:WaitForChild("AttackHandlerRemoteEvent")
local SpecialAttack = RS:WaitForChild("SpecialAttackRemoteEvent_RegularAttack")

local aura = false
local fly = false
local esp = false
local flySpeed = 60

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

-- FIND PLAYER BY PARTIAL NAME
local function findPlayer(name)
    name = name:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
                return p
            end
        end
    end
    return nil
end

-- RAGDOLL TELEPORT TO PLAYER FUNCTION
local function ragdollTeleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        sendNotification("Teleport Failed", "Player not found or has no character!", 3)
        return
    end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        sendNotification("Teleport Failed", "Target has no HumanoidRootPart!", 3)
        return
    end
    
    local char = player.Character
    if not char or not char.PrimaryPart then
        sendNotification("Teleport Failed", "You have no character!", 3)
        return
    end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    sendNotification("Teleporting", "Teleporting to " .. targetPlayer.Name .. "...", 3)
    print("Teleporting to: " .. targetPlayer.Name)
    
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    
    for i = 1, 25 do
        if char and char.PrimaryPart and targetRoot and targetRoot.Parent then
            local targetPos = targetRoot.Position + Vector3.new(5, 0, 5)
            char:SetPrimaryPartCFrame(CFrame.new(targetPos))
        end
        task.wait()
    end
    
    task.wait(1)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    
    for _ = 1, 10 do
        char:SetAttribute("MovementDisabled", false)
        task.wait(0.1)
    end
    
    sendNotification("Teleport Complete", "Arrived at " .. targetPlayer.Name, 3)
end

-- TELEPORT TO LOCATION FUNCTION
local function teleportToLocation(teleportCoordinates)
    local char = player.Character or player.CharacterAdded:Wait()
    if not char or not char.PrimaryPart then 
        return 
    end
    local humanoid = char:WaitForChild("Humanoid")
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    for i = 1, 25 do
        if char and char.PrimaryPart then
            char:SetPrimaryPartCFrame(CFrame.new(teleportCoordinates))
        end
        task.wait()
    end
    task.wait(1)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    for _ = 1, 10 do
        char:SetAttribute("MovementDisabled", false)
        task.wait(0.1)
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
controlsLabel.Text = "T = Aura | Y = Fly | U = ESP | L = TP | ;goto name"
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
-- MOBILE GUI (CLICKABLE BUTTONS)
-- ==========================================
local mobileGui = Instance.new("ScreenGui")
mobileGui.Name = "MrPigMobileGUI"
mobileGui.ResetOnSpawn = false
mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main container on left side
local mainFrame = Instance.new("Frame")
mainFrame.Parent = mobileGui
mainFrame.Size = UDim2.new(0, 70, 0, 320)
mainFrame.Position = UDim2.new(0, 10, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0

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
mobileTitle.Size = UDim2.new(1, 0, 0, 30)
mobileTitle.Position = UDim2.new(0, 0, 0, 5)
mobileTitle.BackgroundTransparency = 1
mobileTitle.Text = "🐷"
mobileTitle.TextColor3 = Color3.fromRGB(255, 105, 180)
mobileTitle.TextSize = 20
mobileTitle.Font = Enum.Font.FredokaOne

-- Button creation function
local function createButton(name, position, defaultColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = mainFrame
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = position
    btn.BackgroundColor3 = defaultColor or Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    return btn
end

-- Create buttons
local auraBtn = createButton("Aura", UDim2.new(0.5, -25, 0, 40))
local flyBtn = createButton("Fly", UDim2.new(0.5, -25, 0, 95))
local espBtn = createButton("ESP", UDim2.new(0.5, -25, 0, 150))
local tpBtn = createButton("TP", UDim2.new(0.5, -25, 0, 205))
local rejoinBtn = createButton("Rejoin", UDim2.new(0.5, -25, 0, 260))
rejoinBtn.TextSize = 10

-- Function to update button colors
local function updateButtonColors()
    auraBtn.BackgroundColor3 = aura and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
    flyBtn.BackgroundColor3 = fly and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
    espBtn.BackgroundColor3 = esp and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
end

-- Button click handlers
auraBtn.MouseButton1Click:Connect(function()
    aura = not aura
    local msg = aura and "Kill Aura ON" or "Kill Aura OFF"
    print(msg)
    sendNotification("Kill Aura", msg, 3)
    updateButtonColors()
end)

flyBtn.MouseButton1Click:Connect(function()
    fly = not fly
    if fly then
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "FlyVelocity"
                bv.Parent = root
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(0, 0, 0)
                
                local bg = Instance.new("BodyGyro")
                bg.Name = "FlyGyro"
                bg.Parent = root
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.CFrame = root.CFrame
                
                local connection
                connection = RunService.Heartbeat:Connect(function()
                    if not fly or not char or not root or not root.Parent then
                        if bv then bv:Destroy() end
                        if bg then bg:Destroy() end
                        if connection then connection:Disconnect() end
                        return
                    end
                    
                    if UIS:GetFocusedTextBox() then
                        bv.Velocity = Vector3.new(0, 0, 0)
                        return
                    end
                    
                    local cam = workspace.CurrentCamera
                    local speed = flySpeed
                    local move = Vector3.new(0, 0, 0)
                    
                    if UIS:IsKeyDown(Enum.KeyCode.W) then
                        move = move + (cam.CFrame.LookVector * speed)
                    end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then
                        move = move - (cam.CFrame.LookVector * speed)
                    end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then
                        move = move + (cam.CFrame.RightVector * speed)
                    end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then
                        move = move - (cam.CFrame.RightVector * speed)
                    end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then
                        move = move + Vector3.new(0, speed, 0)
                    end
                    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                        move = move - Vector3.new(0, speed, 0)
                    end
                    
                    bv.Velocity = move
                    bg.CFrame = cam.CFrame
                end)
                print("Fly ON")
            end
        end
    else
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local bv = root:FindFirstChild("FlyVelocity")
                local bg = root:FindFirstChild("FlyGyro")
                if bv then bv:Destroy() end
                if bg then bg:Destroy() end
            end
        end
        print("Fly OFF")
    end
    updateButtonColors()
end)

espBtn.MouseButton1Click:Connect(function()
    esp = not esp
    local msg = esp and "ESP ON" or "ESP OFF"
    print(msg)
    sendNotification("ESP", msg, 3)
    updateButtonColors()
end)

tpBtn.MouseButton1Click:Connect(function()
    print("Teleporting...")
    sendNotification("Teleporting", "Teleporting to location...", 3)
    spawn(function()
        teleportToLocation(Vector3.new(-6405, 3, 4551))
    end)
end)

rejoinBtn.MouseButton1Click:Connect(function()
    sendNotification("Rejoining", "Rejoining server...", 3)
    print("Rejoining server...")
    task.wait(0.5)
    local TeleportService = game:GetService("TeleportService")
    local success, errorMsg = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end)
    if not success then
        TeleportService:Teleport(game.PlaceId, player)
    end
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
keybindText.TextSize = 18
keybindText.Font = Enum.Font.GothamBold
keybindText.TextStrokeTransparency = 0.5
keybindText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
keybindText.Text = "Loading..."

keybindGui.Parent = player:WaitForChild("PlayerGui")

-- MR. PIG WATERMARK (top right)
local pigLabel = Instance.new("TextLabel")
pigLabel.Parent = keybindGui
pigLabel.Size = UDim2.new(0, 150, 0, 40)
pigLabel.Position = UDim2.new(1, -160, 0, 10)
pigLabel.BackgroundTransparency = 1
pigLabel.BorderSizePixel = 0
pigLabel.Text = "Mr.Pig 🐷"
pigLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
pigLabel.TextSize = 24
pigLabel.Font = Enum.Font.FredokaOne
pigLabel.TextStrokeTransparency = 0.5
pigLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

-- CHAT COMMAND HINT (below watermark)
local chatHintLabel = Instance.new("TextLabel")
chatHintLabel.Parent = keybindGui
chatHintLabel.Size = UDim2.new(0, 200, 0, 40)
chatHintLabel.Position = UDim2.new(1, -210, 0, 50)
chatHintLabel.BackgroundTransparency = 1
chatHintLabel.BorderSizePixel = 0
chatHintLabel.Text = ";goto name = TP to player\n!rejoin = Rejoin server"
chatHintLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
chatHintLabel.TextSize = 14
chatHintLabel.Font = Enum.Font.Gotham
chatHintLabel.TextStrokeTransparency = 0.5
chatHintLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

-- Function to update keybind display
local function updateKeybindDisplay()
    local auraText = aura and "[ON]" or "[OFF]"
    local flyText = fly and "[ON]" or "[OFF]"
    local espText = esp and "[ON]" or "[OFF]"
    
    local auraColor = aura and "🟢" or "🔴"
    local flyColor = fly and "🟢" or "🔴"
    local espColor = esp and "🟢" or "🔴"
    
    keybindText.Text = string.format(
        "%s T-Aura %s | %s Y-Fly %s | %s U-ESP %s | L-TP",
        auraColor, auraText,
        flyColor, flyText,
        espColor, espText
    )
    
    updateButtonColors()
end

-- Update display every 0.5 seconds
spawn(function()
    while task.wait(0.5) do
        updateKeybindDisplay()
    end
end)

-- KEYBINDS (for PC users)
UIS.InputBegan:Connect(function(k)
    if UIS:GetFocusedTextBox() then return end
    
    if k.KeyCode == Enum.KeyCode.T then
        aura = not aura
        local msg = aura and "Kill Aura ON" or "Kill Aura OFF"
        print(msg)
        sendNotification("Kill Aura", msg, 3)
        updateKeybindDisplay()
    end

    if k.KeyCode == Enum.KeyCode.Y then
        fly = not fly
        if fly then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "FlyVelocity"
                    bv.Parent = root
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bv.Velocity = Vector3.new(0, 0, 0)
                    
                    local bg = Instance.new("BodyGyro")
                    bg.Name = "FlyGyro"
                    bg.Parent = root
                    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    bg.CFrame = root.CFrame
                    
                    local connection
                    connection = RunService.Heartbeat:Connect(function()
                        if not fly or not char or not root or not root.Parent then
                            if bv then bv:Destroy() end
                            if bg then bg:Destroy() end
                            if connection then connection:Disconnect() end
                            return
                        end
                        
                        if UIS:GetFocusedTextBox() then
                            bv.Velocity = Vector3.new(0, 0, 0)
                            return
                        end
                        
                        local cam = workspace.CurrentCamera
                        local speed = flySpeed
                        local move = Vector3.new(0, 0, 0)
                        
                        if UIS:IsKeyDown(Enum.KeyCode.W) then
                            move = move + (cam.CFrame.LookVector * speed)
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.S) then
                            move = move - (cam.CFrame.LookVector * speed)
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.D) then
                            move = move + (cam.CFrame.RightVector * speed)
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.A) then
                            move = move - (cam.CFrame.RightVector * speed)
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.Space) then
                            move = move + Vector3.new(0, speed, 0)
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                            move = move - Vector3.new(0, speed, 0)
                        end
                        
                        bv.Velocity = move
                        bg.CFrame = cam.CFrame
                    end)
                    print("Fly ON")
                end
            end
        else
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local bv = root:FindFirstChild("FlyVelocity")
                    local bg = root:FindFirstChild("FlyGyro")
                    if bv then bv:Destroy() end
                    if bg then bg:Destroy() end
                end
            end
            print("Fly OFF")
        end
        updateKeybindDisplay()
    end

    if k.KeyCode == Enum.KeyCode.U then
        esp = not esp
        local msg = esp and "ESP ON" or "ESP OFF"
        print(msg)
        sendNotification("ESP", msg, 3)
        updateKeybindDisplay()
    end
    
    if k.KeyCode == Enum.KeyCode.L then
        print("Teleporting...")
        sendNotification("Teleporting", "Teleporting to location...", 3)
        spawn(function()
            teleportToLocation(Vector3.new(-6405, 3, 4551))
        end)
    end
end)

-- CHAT COMMANDS
player.Chatted:Connect(function(message)
    if message:lower() == "!rejoin" then
        sendNotification("Rejoining", "Rejoining server...", 3)
        print("Rejoining server...")
        task.wait(0.5)
        local TeleportService = game:GetService("TeleportService")
        local success, errorMsg = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
        if not success then
            TeleportService:Teleport(game.PlaceId, player)
        end
    end
    
    if message:lower():sub(1, 6) == ";goto " then
        local targetName = message:sub(7)
        if targetName ~= "" then
            local targetPlayer = findPlayer(targetName)
            if targetPlayer then
                spawn(function()
                    ragdollTeleportToPlayer(targetPlayer)
                end)
            else
                sendNotification("Teleport Failed", "Player '" .. targetName .. "' not found!", 3)
            end
        end
    end
end)

-- INFINITE STAMINA LOOP
spawn(function()
    while task.wait(0.1) do
        if player.Character then
            player.Character:SetAttribute("Stamina", 100)
        end
    end
end)

-- KILL AURA LOOP
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
            if tick() - (player.Character:GetAttribute("LastBasicAttack") or 0) >= 0.05 then
                BasicAttack:FireServer(closestPlayer.humanoid)
                player.Character:SetAttribute("LastBasicAttack", tick())
            end
            if tick() - (player.Character:GetAttribute("LastSpecialAttack") or 0) >= 0.1 then
                SpecialAttack:FireServer(closestPlayer.humanoid)
                player.Character:SetAttribute("LastSpecialAttack", tick())
            end
        end
    end
end)

-- ESP SYSTEM
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
        if esp then
            createESP(char)
        end
    end)
end)

for _, v in pairs(Players:GetPlayers()) do
    if v ~= player then
        v.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if esp then
                createESP(char)
            end
        end)
        if v.Character then
            if esp then
                createESP(v.Character)
            end
        end
    end
end

spawn(function()
    while task.wait(1) do
        updateESP()
    end
end)

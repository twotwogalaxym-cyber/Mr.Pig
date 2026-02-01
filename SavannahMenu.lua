-- Savannah Life: Godmode + Kill Aura + Fly (FIXED COMMAND BOX – DEC 2025)
-- FIX: Removed 'local' from outputFrame and commandGui creation
-- Added Daytime Command + Aura Speed Control + Pounce Kill
-- Press Z → Godmode
-- Press T → Kill Aura (40 studs, safe delays, no kicks, targets closest)
-- Press Y → Fly (UNIVERSAL - works on all executors)
-- Press U → ESP
-- Press P → Circle Mode
-- Press O → Give Godmode to Others
-- Press K → Quick Kill (while being pounced or grabbed)
-- Press V → Auto-Retaliate (kill attackers instantly)
-- Press L → Teleport
-- Press M → Toggle Command Box
-- Press ; → Open Command Box and start typing
-- Chat: ;goto playername → Teleport to player
-- Chat: ;day → Toggle Daytime (always noon)
-- Cmd: aura [speed] → Set kill aura speed (0.01-5)

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- REMOTES
local DamageSelf = RS:WaitForChild("PlayerDamageSelfRemoteEvent")
local RespawnFunc = RS:WaitForChild("SpawnAsCharacterRemoteFunction")
local BasicAttack = RS:WaitForChild("AttackHandlerRemoteEvent")
local SpecialAttack = RS:WaitForChild("SpecialAttackRemoteEvent_RegularAttack")

-- NOTE: Godmode remotes available:
-- - PlayerDamageSelfRemoteEvent (fires with 0/0 for NaN health)
-- - SpecialAttackRemoteEvent_ChargedAttack (alternative godmode - fires with 0/0)
-- - AttackHandlerRemoteEvent (basic attacks)
-- - SpecialAttackRemoteEvent_RegularAttack (regular special attacks)
-- 
-- If basic godmode is patched, try:
-- 1. SpecialAttackRemoteEvent_Dash or other special attack variants
-- 2. Blocking damage by modifying humanoid properties
-- 3. Using CharacterAdded to reapply godmode instantly
-- 4. Combining multiple NaN fires simultaneously

local godmode = false
local aura = false
local fly = false
local esp = false
local flySpeed = 60
local circleMode = false
local circleAngle = 0
local circleRadius = 30
local soundSpamActive = false
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil
local commandBoxVisible = false
local viewingPlayer = nil
local originalCameraSubject = nil
local noclip = false
local looptp = false
local looptpPlayer = nil
local killMode = false
local killModeTarget = nil
local whitelistedPlayers = {}
local noclipConnection = nil
local originalCollisions = {}
local looptpConnection = nil
local killModeConnection = nil
local daytimeActive = false
local daytimeConnection = nil
local Lighting = game:GetService("Lighting")
local auraSpeed = 0.1  -- Default aura speed for kill aura
local autoRetaliate = false  -- Auto-kill when damaged
local lastDamageTime = 0
local damageCooldown = 0.5  -- Prevent spam kills
local ragdollEnabled = false -- NEW: Ragdoll toggle state

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

-- OUTPUT/UI VARIABLES (defined early to avoid scope issues)
local commandGui = nil
local outputFrame = nil
local outputCount = 0

-- OUTPUT FUNCTION
local function addOutput(text, color)
    if not outputFrame then 
        print("Output: " .. text)
        return 
    end
    
    outputCount = outputCount + 1
    local label = Instance.new("TextLabel")
    label.Name = "Output" .. outputCount
    label.Parent = outputFrame
    label.Size = UDim2.new(1, -16, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = "> " .. text
    label.TextColor3 = color or Color3.fromRGB(100, 255, 100)
    label.TextSize = 12
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.LayoutOrder = outputCount
    label.AutomaticSize = Enum.AutomaticSize.Y
    
    task.wait()
    if outputFrame then
        outputFrame.CanvasPosition = Vector2.new(0, outputFrame.AbsoluteCanvasSize.Y)
    end
    
    local children = outputFrame:GetChildren()
    local labelCount = 0
    for _, child in pairs(children) do
        if child:IsA("TextLabel") then
            labelCount = labelCount + 1
        end
    end
    if labelCount > 50 then
        for _, child in pairs(children) do
            if child:IsA("TextLabel") then
                child:Destroy()
                break
            end
        end
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

-- VIEW PLAYER FUNCTIONS
local function viewPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        sendNotification("View Failed", "Player not found or has no character!", 3)
        return false
    end
    
    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid then
        sendNotification("View Failed", "Target has no humanoid!", 3)
        return false
    end
    
    local camera = workspace.CurrentCamera
    
    if not viewingPlayer then
        originalCameraSubject = camera.CameraSubject
    end
    
    camera.CameraSubject = targetHumanoid
    viewingPlayer = targetPlayer
    
    sendNotification("Viewing", "Now viewing: " .. targetPlayer.Name, 3)
    return true
end

local function unviewPlayer()
    if not viewingPlayer then
        sendNotification("View", "Not viewing anyone!", 3)
        return
    end
    
    local camera = workspace.CurrentCamera
    
    if originalCameraSubject then
        camera.CameraSubject = originalCameraSubject
    else
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                camera.CameraSubject = hum
            end
        end
    end
    
    sendNotification("View", "Stopped viewing " .. viewingPlayer.Name, 3)
    viewingPlayer = nil
    originalCameraSubject = nil
end

Players.PlayerRemoving:Connect(function(p)
    if viewingPlayer == p then
        unviewPlayer()
    end
end)

-- DAYTIME TOGGLE FUNCTION
local function toggleDaytime()
    daytimeActive = not daytimeActive
    
    if daytimeActive then
        -- Start the daytime spam
        if daytimeConnection then daytimeConnection:Disconnect() end
        daytimeConnection = RunService.Heartbeat:Connect(function()
            if daytimeActive then
                Lighting.ClockTime = 12
            end
        end)
        sendNotification("Daytime", "ON - Always noon", 3)
        addOutput("Daytime enabled!", Color3.fromRGB(100, 255, 100))
    else
        -- Stop the daytime spam
        if daytimeConnection then
            daytimeConnection:Disconnect()
            daytimeConnection = nil
        end
        sendNotification("Daytime", "OFF", 3)
        addOutput("Daytime disabled!", Color3.fromRGB(100, 255, 100))
    end
end

-- NOCLIP FUNCTIONS
local function startNoclip()
    local char = player.Character
    if not char then 
        addOutput("Noclip: No character!", Color3.fromRGB(255, 100, 100))
        return 
    end
    
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
    
    addOutput("Noclip: ON - Walk through walls", Color3.fromRGB(100, 255, 100))
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
    addOutput("Noclip: OFF", Color3.fromRGB(255, 100, 100))
end

local function toggleNoclip()
    noclip = not noclip
    if noclip then
        startNoclip()
    else
        stopNoclip()
    end
end

-- LOOPGOTO FUNCTIONS
local loopgotoConnection = nil

local function startLoopGoto(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        addOutput("LoopGoto Failed: Player not found!", Color3.fromRGB(255, 100, 100))
        return
    end
    
    looptpPlayer = targetPlayer
    looptp = true
    
    addOutput("LoopGoto: Now following " .. targetPlayer.Name, Color3.fromRGB(100, 255, 100))
    sendNotification("LoopGoto", "Following " .. targetPlayer.Name, 3)
    
    loopgotoConnection = RunService.Heartbeat:Connect(function()
        if not looptp or not looptpPlayer or not looptpPlayer.Character then
            looptp = false
            looptpPlayer = nil
            if loopgotoConnection then
                loopgotoConnection:Disconnect()
                loopgotoConnection = nil
            end
            addOutput("LoopGoto: Target lost", Color3.fromRGB(255, 100, 100))
            return
        end
        
        local char = player.Character
        if not char or not char.PrimaryPart then return end
        
        local targetRoot = looptpPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot or not targetRoot.Parent then return end
        
        local targetPos = targetRoot.Position + Vector3.new(5, 0, 5)
        char:SetPrimaryPartCFrame(CFrame.new(targetPos))
    end)
end

local function stopLoopGoto()
    looptp = false
    looptpPlayer = nil
    
    if loopgotoConnection then
        loopgotoConnection:Disconnect()
        loopgotoConnection = nil
    end
    
    addOutput("LoopGoto: Stopped", Color3.fromRGB(255, 100, 100))
    sendNotification("LoopGoto", "Stopped", 2)
end

-- KILL MODE FUNCTIONS
local killModeConnection = nil

local function startKillMode(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        addOutput("Kill Mode Failed: Player not found!", Color3.fromRGB(255, 100, 100))
        return
    end
    
    killModeTarget = targetPlayer
    killMode = true
    aura = true
    
    addOutput("Kill Mode: Hunting " .. targetPlayer.Name, Color3.fromRGB(255, 0, 0))
    sendNotification("Kill Mode", "Hunting " .. targetPlayer.Name, 3)
    
    killModeConnection = RunService.Heartbeat:Connect(function()
        if not killMode or not killModeTarget or not killModeTarget.Character then
            killMode = false
            killModeTarget = nil
            aura = false
            
            if killModeConnection then
                killModeConnection:Disconnect()
                killModeConnection = nil
            end
            
            addOutput("Kill Mode: Target eliminated!", Color3.fromRGB(100, 255, 100))
            sendNotification("Kill Mode", "Target eliminated!", 2)
            return
        end
        
        local char = player.Character
        if not char or not char.PrimaryPart then return end
        
        local targetHum = killModeTarget.Character:FindFirstChildOfClass("Humanoid")
        local targetRoot = killModeTarget.Character:FindFirstChild("HumanoidRootPart")
        
        if not targetHum or not targetRoot or not targetRoot.Parent or targetHum.Health <= 0 then
            killMode = false
            killModeTarget = nil
            aura = false
            if killModeConnection then
                killModeConnection:Disconnect()
                killModeConnection = nil
            end
            addOutput("Kill Mode: Target dead!", Color3.fromRGB(100, 255, 100))
            return
        end
        
        local targetPos = targetRoot.Position + Vector3.new(5, 0, 5)
        char:SetPrimaryPartCFrame(CFrame.new(targetPos))
    end)
end

local function stopKillMode()
    killMode = false
    killModeTarget = nil
    aura = false
    
    if killModeConnection then
        killModeConnection:Disconnect()
        killModeConnection = nil
    end
    
    addOutput("Kill Mode: Stopped", Color3.fromRGB(255, 100, 100))
    sendNotification("Kill Mode", "Stopped", 2)
end

-- RESET PLAYER
local function resetPlayer()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
            addOutput("Reset: Respawning...", Color3.fromRGB(255, 255, 100))
            sendNotification("Reset", "Respawning...", 2)
        end
    end
end

-- SOUND SPAM FUNCTION
local function PlaySound()
    local char = player.Character
    if not char or not char.PrimaryPart then return end
    local rootPos = char.PrimaryPart.Position
    local newPos
    local r = math.random(0,1)
    if r == 1 then
        newPos = rootPos + Vector3.new(math.random(5, 50), math.random(5, 50) / 4, math.random(5, 50))
    else
        newPos = rootPos - Vector3.new(math.random(5, 50), math.random(5, 50) / 4, math.random(5, 50))
    end
    
    local Event = RS:FindFirstChild("ReplicateEffectsRemoteEvent")
    if Event then
        Event:FireServer("EmoteSound", newPos, {
            AnimalType = "Mammals",
            AnimalName = "Elephant",
            AnimalAge = "Adult",
            EmoteName = "LongTrumpet",
        })
    end
end

local function StartSoundSpam()
    if soundSpamActive then return end
    
    soundSpamActive = true
    sendNotification("Sound Spam", "Playing sounds for 30 seconds...", 3)
    
    spawn(function()
        local start = os.time()
        while task.wait(0.05) do
            if os.time() - start > 30 then break end
            if not soundSpamActive then break end
            PlaySound()
        end
        soundSpamActive = false
        sendNotification("Sound Spam", "Finished!", 3)
    end)
end

-- TELEPORT FUNCTION
local function teleportToLocation(teleportCoordinates)
    local char = player.Character or player.CharacterAdded:Wait()
    if not char or not char.PrimaryPart then return end
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

-- RAGDOLL TOGGLE FUNCTION - NEW
local function toggleRagdoll()
    ragdollEnabled = not ragdollEnabled
    
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            if ragdollEnabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                addOutput("Ragdoll: ON", Color3.fromRGB(100, 255, 100))
                sendNotification("Ragdoll", "ON - You're now in ragdoll mode", 3)
            else
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                addOutput("Ragdoll: OFF", Color3.fromRGB(255, 100, 100))
                sendNotification("Ragdoll", "OFF", 3)
            end
        else
            addOutput("Ragdoll: No humanoid found", Color3.fromRGB(255, 100, 100))
        end
    else
        addOutput("Ragdoll: No character found", Color3.fromRGB(255, 100, 100))
    end
end

-- FLY FUNCTIONS
local function startFly()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    
    local oldBV = root:FindFirstChild("FlyVelocity")
    local oldBG = root:FindFirstChild("FlyGyro")
    if oldBV then oldBV:Destroy() end
    if oldBG then oldBG:Destroy() end
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    hum.PlatformStand = true
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.D = 100
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not fly then return end
        if not char or not char.Parent or not root or not root.Parent then
            stopFly()
            return
        end
        
        if UIS:GetFocusedTextBox() then
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            return
        end
        
        local camera = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)
        
        if UIS:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end
        
        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir.Unit * flySpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        bodyGyro.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector)
    end)
    
    sendNotification("Fly", "ON - Speed: " .. flySpeed, 3)
end

local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
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
        
        if hum then
            hum.PlatformStand = false
        end
    end
    
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

player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if fly then
        startFly()
    end
    if viewingPlayer and viewingPlayer.Character then
        local hum = viewingPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
        end
    end
    
    -- Setup damage listener for auto-retaliation
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(function(newHealth)
            if autoRetaliate and newHealth < humanoid.MaxHealth and humanoid.Health > 0 then
                local currentTime = tick()
                if currentTime - lastDamageTime > damageCooldown then
                    lastDamageTime = currentTime
                    
                    -- Find attacker (closest player)
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local closestPlayer = nil
                        local closestDistance = 100
                        
                        for _, v in pairs(Players:GetPlayers()) do
                            if v ~= player and v.Character then
                                local vhum = v.Character:FindFirstChildOfClass("Humanoid")
                                local vhrp = v.Character:FindFirstChild("HumanoidRootPart")
                                if vhum and vhrp and vhum.Health > 0 then
                                    local distance = (root.Position - vhrp.Position).Magnitude
                                    if distance < closestDistance then
                                        closestDistance = distance
                                        closestPlayer = {humanoid = vhum, player = v, hrp = vhrp}
                                    end
                                end
                            end
                        end
                        
                        if closestPlayer then
                            -- Enable kill aura if not already on
                            if not aura then
                                aura = true
                                auraBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                            end
                            
                            -- Instantly kill with health = 0
                            pcall(function()
                                closestPlayer.humanoid.Health = 0
                            end)
                            addOutput("AUTO-RETALIATE: Killed " .. closestPlayer.player.Name, Color3.fromRGB(0, 255, 100))
                            sendNotification("Retaliate!", "Killed " .. closestPlayer.player.Name, 2)
                            updateKeybindDisplay()
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- COMMAND BOX GUI (FIXED VERSION)
-- ==========================================
commandGui = Instance.new("ScreenGui")
commandGui.Name = "MrPigCommandBox"
commandGui.ResetOnSpawn = false
commandGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = commandGui
mainFrame.Size = UDim2.new(0, 500, 0, 450)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 105, 180)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Parent = mainFrame
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
titleBar.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Parent = titleBar
titleFix.Size = UDim2.new(1, 0, 0, 15)
titleFix.Position = UDim2.new(0, 0, 1, -15)
titleFix.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
titleFix.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = titleBar
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐷 Mr.Pig Commands"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = titleBar
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local inputFrame = Instance.new("Frame")
inputFrame.Parent = mainFrame
inputFrame.Size = UDim2.new(1, -20, 0, 40)
inputFrame.Position = UDim2.new(0, 10, 0, 50)
inputFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
inputFrame.BorderSizePixel = 0

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputFrame

local commandInput = Instance.new("TextBox")
commandInput.Name = "CommandInput"
commandInput.Parent = inputFrame
commandInput.Size = UDim2.new(1, -20, 1, 0)
commandInput.Position = UDim2.new(0, 10, 0, 0)
commandInput.BackgroundTransparency = 1
commandInput.Text = ""
commandInput.PlaceholderText = "Type a command... (press ; to quick open)"
commandInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
commandInput.TextColor3 = Color3.fromRGB(255, 255, 255)
commandInput.TextSize = 14
commandInput.Font = Enum.Font.Gotham
commandInput.TextXAlignment = Enum.TextXAlignment.Left
commandInput.ClearTextOnFocus = false

outputFrame = Instance.new("ScrollingFrame")
outputFrame.Name = "OutputFrame"
outputFrame.Parent = mainFrame
outputFrame.Size = UDim2.new(1, -20, 0, 320)
outputFrame.Position = UDim2.new(0, 10, 0, 110)
outputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
outputFrame.BorderSizePixel = 0
outputFrame.ScrollBarThickness = 6
outputFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 105, 180)
outputFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
outputFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local outputCorner = Instance.new("UICorner")
outputCorner.CornerRadius = UDim.new(0, 8)
outputCorner.Parent = outputFrame

local outputLayout = Instance.new("UIListLayout")
outputLayout.Parent = outputFrame
outputLayout.SortOrder = Enum.SortOrder.LayoutOrder
outputLayout.Padding = UDim.new(0, 2)

local outputPadding = Instance.new("UIPadding")
outputPadding.Parent = outputFrame
outputPadding.PaddingLeft = UDim.new(0, 8)
outputPadding.PaddingRight = UDim.new(0, 8)
outputPadding.PaddingTop = UDim.new(0, 5)
outputPadding.PaddingBottom = UDim.new(0, 5)

-- Draggable
local dragging = false
local dragStart = nil
local startPos = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

outputCount = 0

local allCommands = {
    "god", "aura", "fly", "esp", "circle", "day", "noclip", "give",
    "reset", "loopgoto", "stoploopgoto", "kill", "stopkill", "skill", "stopskill", "sgoto", "stopsgoto",
    "whitelist", "unwhitelist",
    "speed", "radius", "view", "unview", "players",
    "goto", "tp", "play", "stop", "rejoin", "fix", "help", "ragdoll" -- Added "ragdoll" to commands list
}

local function populateCommandList()
    if not outputFrame then return end
    
    for _, child in pairs(outputFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Parent = outputFrame
    header.Size = UDim2.new(1, -16, 0, 25)
    header.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    header.BackgroundTransparency = 0.2
    header.Text = "=== AVAILABLE COMMANDS ==="
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 13
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Center
    header.LayoutOrder = 0
    header.BorderSizePixel = 0
    
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 4)
    hc.Parent = header
    
    for i, cmd in ipairs(allCommands) do
        local label = Instance.new("TextLabel")
        label.Name = "Cmd" .. i
        label.Parent = outputFrame
        label.Size = UDim2.new(1, -16, 0, 20)
        label.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        label.BackgroundTransparency = 0.5
        label.BorderSizePixel = 0
        label.Text = "  " .. cmd
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        label.TextSize = 12
        label.Font = Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.LayoutOrder = i
        
        local lc = Instance.new("UICorner")
        lc.CornerRadius = UDim.new(0, 4)
        lc.Parent = label
    end
end

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    commandBoxVisible = false
end)

local function toggleCommandBox()
    commandBoxVisible = not commandBoxVisible
    mainFrame.Visible = commandBoxVisible
    if commandBoxVisible then
        populateCommandList()
        commandInput.Text = ""
        commandInput:CaptureFocus()
    end
end

local function openCommandBoxAndFocus()
    commandBoxVisible = true
    mainFrame.Visible = true
    commandInput.Text = ""
    populateCommandList()
    commandInput:CaptureFocus()
end

local function isWhitelisted(playerName)
    return whitelistedPlayers[playerName:lower()] == true
end

-- COMMAND PROCESSOR
local function processCommand(cmd)
    cmd = cmd:lower():gsub("^%s*(.-)%s*$", "%1")
    if cmd == "" then return end
    
    addOutput("CMD: " .. cmd, Color3.fromRGB(150, 150, 150))
    
    -- NEW RAGDOLL COMMAND
    if cmd == "ragdoll" then
        toggleRagdoll()
        return
    end
    
    local loopgotoMatch = cmd:match("^loopgoto%s+(.+)$")
    if loopgotoMatch then
        local targetPlayer = findPlayer(loopgotoMatch)
        if targetPlayer then
            startLoopGoto(targetPlayer)
        else
            addOutput("Player not found: " .. loopgotoMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    if cmd == "stoploopgoto" or cmd == "stoplg" then
        stopLoopGoto()
        return
    end
    
    local killMatch = cmd:match("^kill%s+(.+)$")
    if killMatch then
        local targetPlayer = findPlayer(killMatch)
        if targetPlayer then
            startKillMode(targetPlayer)
        else
            addOutput("Player not found: " .. killMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    if cmd == "stopkill" or cmd == "killstop" then
        stopKillMode()
        return
    end
    
    local skillMatch = cmd:match("^skill%s+(.+)$")
    if skillMatch then
        local targetPlayer = findPlayer(skillMatch)
        if targetPlayer then
            killModeTarget = targetPlayer
            killMode = true
            aura = true
            addOutput("SKill Mode: Hunting " .. targetPlayer.Name .. " (UNDERGROUND)", Color3.fromRGB(255, 0, 0))
            sendNotification("SKill Mode", "Hunting " .. targetPlayer.Name, 3)
            
            skillModeConnection = RunService.Heartbeat:Connect(function()
                if not killMode or not killModeTarget or not killModeTarget.Character then
                    killMode = false
                    killModeTarget = nil
                    aura = false
                    if skillModeConnection then
                        skillModeConnection:Disconnect()
                        skillModeConnection = nil
                    end
                    addOutput("SKill Mode: Target eliminated!", Color3.fromRGB(100, 255, 100))
                    sendNotification("SKill Mode", "Target eliminated!", 2)
                    return
                end
                
                local char = player.Character
                if not char or not char.PrimaryPart then return end
                
                local targetHum = killModeTarget.Character:FindFirstChildOfClass("Humanoid")
                local targetRoot = killModeTarget.Character:FindFirstChild("HumanoidRootPart")
                
                if not targetHum or not targetRoot or not targetRoot.Parent or targetHum.Health <= 0 then
                    killMode = false
                    killModeTarget = nil
                    aura = false
                    if skillModeConnection then
                        skillModeConnection:Disconnect()
                        skillModeConnection = nil
                    end
                    addOutput("SKill Mode: Target dead!", Color3.fromRGB(100, 255, 100))
                    return
                end
                
                local targetPos = targetRoot.Position + Vector3.new(5, -20, 5)
                char:SetPrimaryPartCFrame(CFrame.new(targetPos))
            end)
        else
            addOutput("Player not found: " .. skillMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    if cmd == "stopskill" or cmd == "skillstop" then
        killMode = false
        killModeTarget = nil
        aura = false
        if skillModeConnection then
            skillModeConnection:Disconnect()
            skillModeConnection = nil
        end
        addOutput("SKill Mode: Stopped - Teleporting", Color3.fromRGB(255, 100, 100))
        sendNotification("SKill Mode", "Stopped - Teleporting", 2)
        spawn(function() teleportToLocation(Vector3.new(-6405, 3, 4551)) end)
        return
    end
    
    local sgotoMatch = cmd:match("^sgoto%s+(.+)$")
    if sgotoMatch then
        local targetPlayer = findPlayer(sgotoMatch)
        if targetPlayer then
            sgotoPlayer = targetPlayer
            sgoto = true
            addOutput("Sgoto: Now following " .. targetPlayer.Name .. " (UNDERGROUND)", Color3.fromRGB(100, 255, 100))
            sendNotification("Sgoto", "Following " .. targetPlayer.Name, 3)
            
            sgotoConnection = RunService.Heartbeat:Connect(function()
                if not sgoto or not sgotoPlayer or not sgotoPlayer.Character then
                    sgoto = false
                    sgotoPlayer = nil
                    if sgotoConnection then
                        sgotoConnection:Disconnect()
                        sgotoConnection = nil
                    end
                    addOutput("Sgoto: Target lost", Color3.fromRGB(255, 100, 100))
                    return
                end
                
                local char = player.Character
                if not char or not char.PrimaryPart then return end
                
                local targetRoot = sgotoPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not targetRoot or not targetRoot.Parent then return end
                
                local targetPos = targetRoot.Position + Vector3.new(5, -20, 5)
                char:SetPrimaryPartCFrame(CFrame.new(targetPos))
            end)
        else
            addOutput("Player not found: " .. sgotoMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    if cmd == "stopsgoto" or cmd == "sgotostop" then
        sgoto = false
        sgotoPlayer = nil
        if sgotoConnection then
            sgotoConnection:Disconnect()
            sgotoConnection = nil
        end
        addOutput("Sgoto: Stopped - Teleporting", Color3.fromRGB(255, 100, 100))
        sendNotification("Sgoto", "Stopped - Teleporting", 2)
        spawn(function() teleportToLocation(Vector3.new(-6405, 3, 4551)) end)
        return
    end
    
    -- AURA SPEED COMMAND
    local auraSpeedMatch = cmd:match("^aura%s+(%d+%.?%d*)$")
    if auraSpeedMatch then
        local newSpeed = tonumber(auraSpeedMatch)
        if newSpeed and newSpeed >= 0.01 and newSpeed <= 5 then
            auraSpeed = newSpeed
            addOutput("Aura speed set to: " .. auraSpeed, Color3.fromRGB(100, 255, 100))
            if aura then
                sendNotification("Aura Speed", "Set to " .. auraSpeed, 3)
            end
        else
            addOutput("Aura speed must be between 0.01 and 5", Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    if cmd == "god" or cmd == "godmode" then
        godmode = not godmode
        local status = godmode and "ON" or "OFF"
        addOutput("Godmode: " .. status, godmode and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        sendNotification("Godmode", status, 3)
        return
    end
    
    if cmd == "aura" or cmd == "killaura" then
        aura = not aura
        local status = aura and "ON (Speed: " .. auraSpeed .. ")" or "OFF"
        addOutput("Kill Aura: " .. status, aura and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        sendNotification("Kill Aura", status, 3)
        return
    end
    
    if cmd == "fly" then
        toggleFly()
        local status = fly and "ON (Speed: " .. flySpeed .. ")" or "OFF"
        addOutput("Fly: " .. status, fly and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        return
    end
    
    if cmd == "esp" then
        esp = not esp
        local status = esp and "ON" or "OFF"
        addOutput("ESP: " .. status, esp and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        sendNotification("ESP", status, 3)
        return
    end
    
    if cmd == "circle" or cmd == "circlemode" then
        circleMode = not circleMode
        local status = circleMode and "ON" or "OFF"
        addOutput("Circle Mode: " .. status, circleMode and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        sendNotification("Circle Mode", status, 3)
        return
    end
    
    if cmd == "day" or cmd == "daytime" then
        toggleDaytime()
        local status = daytimeActive and "ON (Always Noon)" or "OFF"
        addOutput("Daytime: " .. status, daytimeActive and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        return
    end
    
    if cmd == "noclip" then
        toggleNoclip()
        return
    end
    
    if cmd == "give" or cmd == "givegod" then
        if player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local closestPlayer = nil
                local closestDistance = 50
                
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= player and v.Character then
                        local hum = v.Character:FindFirstChildOfClass("Humanoid")
                        local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp then
                            local distance = (root.Position - hrp.Position).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = {humanoid = hum, player = v}
                            end
                        end
                    end
                end
                
                if closestPlayer then
                    pcall(function()
                        RS:WaitForChild("SpecialAttackRemoteEvent_ChargedAttack"):FireServer(closestPlayer.humanoid, 0/0)
                    end)
                    addOutput("Gave godmode to: " .. closestPlayer.player.Name, Color3.fromRGB(100, 255, 100))
                    sendNotification("Godmode Given", closestPlayer.player.Name, 3)
                else
                    addOutput("No players nearby!", Color3.fromRGB(255, 100, 100))
                end
            end
        end
        return
    end
    
    if cmd == "reset" then
        resetPlayer()
        return
    end
    
    if cmd == "rejoin" then
        addOutput("Rejoining server...", Color3.fromRGB(255, 255, 100))
        sendNotification("Rejoining", "Rejoining server...", 3)
        task.wait(0.5)
        local TeleportService = game:GetService("TeleportService")
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
        return
    end
    
    if cmd == "play" or cmd == "sound" or cmd == "spam" then
        StartSoundSpam()
        addOutput("Sound spam started (30 sec)", Color3.fromRGB(100, 255, 100))
        return
    end
    
    if cmd == "stop" or cmd == "stopsound" then
        -- Stop all active modes
        soundSpamActive = false
        looptp = false
        looptpPlayer = nil
        killMode = false
        killModeTarget = nil
        sgoto = false
        sgotoPlayer = nil
        aura = false
        
        -- Disconnect all connections
        if loopgotoConnection then
            loopgotoConnection:Disconnect()
            loopgotoConnection = nil
        end
        if killModeConnection then
            killModeConnection:Disconnect()
            killModeConnection = nil
        end
        if skillModeConnection then
            skillModeConnection:Disconnect()
            skillModeConnection = nil
        end
        if sgotoConnection then
            sgotoConnection:Disconnect()
            sgotoConnection = nil
        end
        
        addOutput("All modes stopped (loopgoto, kill, skill, sgoto)", Color3.fromRGB(100, 255, 100))
        sendNotification("Stop", "All modes stopped!", 2)
        return
    end
    
    if cmd == "tp" or cmd == "teleport" then
        addOutput("Teleporting to saved location...", Color3.fromRGB(255, 255, 100))
        spawn(function() teleportToLocation(Vector3.new(-6405, 3, 4551)) end)
        return
    end
    
    if cmd == "players" or cmd == "list" or cmd == "who" then
        addOutput("=== Players Online ===", Color3.fromRGB(255, 105, 180))
        for _, p in pairs(Players:GetPlayers()) do
            local isYou = p == player and " (YOU)" or ""
            local isViewing = p == viewingPlayer and " [VIEWING]" or ""
            addOutput(p.Name .. isYou .. isViewing, Color3.fromRGB(200, 200, 200))
        end
        addOutput("Total: " .. #Players:GetPlayers() .. " players", Color3.fromRGB(150, 150, 150))
        return
    end
    
    if cmd == "unview" or cmd == "stopview" then
        if viewingPlayer then
            unviewPlayer()
            addOutput("Stopped viewing player", Color3.fromRGB(100, 255, 100))
        else
            addOutput("Not viewing anyone", Color3.fromRGB(255, 255, 100))
        end
        return
    end
    
    local speedMatch = cmd:match("^speed%s+(%d+)$")
    if speedMatch then
        local newSpeed = tonumber(speedMatch)
        if newSpeed and newSpeed >= 1 and newSpeed <= 500 then
            flySpeed = newSpeed
            addOutput("Fly speed set to: " .. flySpeed, Color3.fromRGB(100, 255, 100))
        else
            addOutput("Speed must be between 1 and 500", Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    local radiusMatch = cmd:match("^radius%s+(%d+)$")
    if radiusMatch then
        local newRadius = tonumber(radiusMatch)
        if newRadius and newRadius >= 5 and newRadius <= 100 then
            circleRadius = newRadius
            addOutput("Circle radius set to: " .. circleRadius, Color3.fromRGB(100, 255, 100))
        else
            addOutput("Radius must be between 5 and 100", Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    local viewMatch = cmd:match("^view%s+(.+)$")
    if viewMatch then
        local targetPlayer = findPlayer(viewMatch)
        if targetPlayer then
            if viewPlayer(targetPlayer) then
                addOutput("Now viewing: " .. targetPlayer.Name, Color3.fromRGB(100, 255, 100))
            end
        else
            addOutput("Player not found: " .. viewMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    local gotoMatch = cmd:match("^goto%s+(.+)$")
    if gotoMatch then
        local targetPlayer = findPlayer(gotoMatch)
        if targetPlayer then
            addOutput("Teleporting to: " .. targetPlayer.Name, Color3.fromRGB(255, 255, 100))
            spawn(function() ragdollTeleportToPlayer(targetPlayer) end)
        else
            addOutput("Player not found: " .. gotoMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    local whitelistMatch = cmd:match("^whitelist%s+(.+)$")
    if whitelistMatch then
        if whitelistMatch == "reset" then
            whitelistedPlayers = {}
            addOutput("Whitelist cleared", Color3.fromRGB(255, 255, 100))
            return
        end
        local targetPlayer = findPlayer(whitelistMatch)
        if targetPlayer then
            local playerLower = targetPlayer.Name:lower()
            if whitelistedPlayers[playerLower] then
                addOutput(targetPlayer.Name .. " already whitelisted", Color3.fromRGB(255, 255, 100))
            else
                whitelistedPlayers[playerLower] = true
                addOutput("Whitelisted: " .. targetPlayer.Name, Color3.fromRGB(100, 255, 100))
            end
        else
            addOutput("Player not found: " .. whitelistMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    local unwhitelistMatch = cmd:match("^unwhitelist%s+(.+)$")
    if unwhitelistMatch then
        local nameLower = unwhitelistMatch:lower()
        if whitelistedPlayers[nameLower] then
            whitelistedPlayers[nameLower] = nil
            addOutput("Removed from whitelist: " .. unwhitelistMatch, Color3.fromRGB(100, 255, 100))
        else
            addOutput("Not whitelisted: " .. unwhitelistMatch, Color3.fromRGB(255, 100, 100))
        end
        return
    end
    
    if cmd == "whitelist" then
        addOutput("=== WHITELISTED PLAYERS ===", Color3.fromRGB(255, 105, 1... (34 KB left)

-- Savannah Life: Kill Aura + ESP + Fly
-- Press T → Kill Aura (40 studs)
-- Press Y → Fly
-- Press U → ESP

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- REMOTES
local BasicAttack = RS:WaitForChild("AttackHandlerRemoteEvent")
local SpecialAttack = RS:WaitForChild("SpecialAttackRemoteEvent_RegularAttack")

local aura = false
local fly = false
local esp = false
local flySpeed = 60

-- STARTUP MESSAGE
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Mr.Pig says hello",
    Text = "The script has launched successfully",
    Duration = 5
})
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
controlsLabel.Text = "T = Kill Aura | Y = Fly | U = ESP"
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

-- PERMANENT KEYBIND DISPLAY
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

-- Function to update keybind display
local function updateKeybindDisplay()
    local auraText = aura and "[ON]" or "[OFF]"
    local flyText = fly and "[ON]" or "[OFF]"
    local espText = esp and "[ON]" or "[OFF]"
    
    local auraColor = aura and "🟢" or "🔴"
    local flyColor = fly and "🟢" or "🔴"
    local espColor = esp and "🟢" or "🔴"
    
    keybindText.Text = string.format(
        "%s T-Aura %s | %s Y-Fly %s | %s U-ESP %s",
        auraColor, auraText,
        flyColor, flyText,
        espColor, espText
    )
end

-- Update display every 0.5 seconds
spawn(function()
    while task.wait(0.5) do
        updateKeybindDisplay()
    end
end)

-- KEYBINDS
UIS.InputBegan:Connect(function(k)
    if UIS:GetFocusedTextBox() then return end
    
    if k.KeyCode == Enum.KeyCode.T then
        aura = not aura
        local msg = aura and "Kill Aura ON" or "Kill Aura OFF"
        print(msg)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Kill Aura",
            Text = msg,
            Duration = 3
        })
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
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ESP",
            Text = msg,
            Duration = 3
        })
        updateKeybindDisplay()
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
message.txt
15 KB
message.txt
15 KB

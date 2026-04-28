--[[
    ===================================================================
    Mr Pig Auto Grower — Key GUI Wrapper
    ===================================================================
    This is the script users run. It shows a key GUI in-game,
    lets them copy the get-key link, paste their key back,
    then loads the Luarmor-protected loader which validates the key.

    HOW TO DISTRIBUTE:
      Give users this one-liner:

      loadstring(game:HttpGet("https://YOUR-PASTEBIN-OR-RAW-URL/wrapper.lua"))()

      (Upload this file to pastebin / github raw / anywhere that
       returns plain text, then put that URL in the loadstring.)
    ===================================================================
]]

-- ============== CONFIG ==============
local GET_KEY_LINK   = "https://ads.luarmor.net/get_key?for=Mr_Pig_Access-GuWOTnEJVWia"
local LUARMOR_LOADER = "https://api.luarmor.net/files/v4/loaders/25f01dafc3de5c7db2835412f26d4d1c.lua"
local SCRIPT_NAME    = "Mr Pig Auto Grower"
-- ====================================

-- Clean up any old key GUI from previous runs
local existing = game:GetService("CoreGui"):FindFirstChild("MrPigKeyGui")
if existing then existing:Destroy() end

local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- BUILD GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "MrPigKeyGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

-- Dim background
local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.4
dim.BorderSizePixel = 0
dim.Parent = gui

-- Main card
local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(360, 240)
card.Position = UDim2.new(0.5, -180, 0.5, -120)
card.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
card.BorderSizePixel = 0
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

-- Subtle stroke
local stroke = Instance.new("UIStroke", card)
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 1
stroke.Transparency = 0.3

-- Drop shadow (cheap fake using a second darker frame behind)
local shadow = Instance.new("Frame")
shadow.Size = UDim2.fromOffset(370, 250)
shadow.Position = UDim2.new(0.5, -185, 0.5, -123)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.ZIndex = card.ZIndex - 1
shadow.Parent = gui
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
titleBar.BorderSizePixel = 0
titleBar.Parent = card
local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 10)

-- Cover bottom rounded corners of titlebar
local titleCover = Instance.new("Frame")
titleCover.Size = UDim2.new(1, 0, 0.5, 0)
titleCover.Position = UDim2.new(0, 0, 0.5, 0)
titleCover.BackgroundColor3 = titleBar.BackgroundColor3
titleCover.BorderSizePixel = 0
titleCover.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "🔑  " .. SCRIPT_NAME .. " — Authentication"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Subtitle / instructions
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -30, 0, 30)
subtitle.Position = UDim2.fromOffset(15, 50)
subtitle.BackgroundTransparency = 1
subtitle.Text = "1. Click 'Copy Link'  →  2. Paste in browser  →  3. Get key  →  4. Paste below"
subtitle.TextColor3 = Color3.fromRGB(170, 170, 185)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextWrapped = true
subtitle.Parent = card

-- Key input box
local inputBg = Instance.new("Frame")
inputBg.Size = UDim2.new(1, -30, 0, 36)
inputBg.Position = UDim2.fromOffset(15, 90)
inputBg.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
inputBg.BorderSizePixel = 0
inputBg.Parent = card
Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -20, 1, 0)
input.Position = UDim2.fromOffset(10, 0)
input.BackgroundTransparency = 1
input.PlaceholderText = "Paste your key here..."
input.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
input.Text = ""
input.TextColor3 = Color3.fromRGB(240, 240, 250)
input.Font = Enum.Font.Gotham
input.TextSize = 13
input.TextXAlignment = Enum.TextXAlignment.Left
input.ClearTextOnFocus = false
input.Parent = inputBg

-- Copy link button
local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.5, -20, 0, 36)
copyBtn.Position = UDim2.fromOffset(15, 140)
copyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
copyBtn.BorderSizePixel = 0
copyBtn.Text = "📋  Copy Get-Key Link"
copyBtn.TextColor3 = Color3.fromRGB(15, 25, 20)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 12
copyBtn.AutoButtonColor = false
copyBtn.Parent = card
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

-- Submit button
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0.5, -20, 0, 36)
submitBtn.Position = UDim2.new(0.5, 5, 0, 140)
submitBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 230)
submitBtn.BorderSizePixel = 0
submitBtn.Text = "✓  Submit Key"
submitBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextSize = 12
submitBtn.AutoButtonColor = false
submitBtn.Parent = card
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 6)

-- Status label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 0, 30)
status.Position = UDim2.fromOffset(15, 188)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(200, 200, 215)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextWrapped = true
status.Parent = card

-- Close (X) button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- ============================================================
-- HOVER EFFECTS
-- ============================================================
local function hover(btn, normal, hovered)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hovered}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
    end)
end
hover(copyBtn,   Color3.fromRGB(80, 200, 120), Color3.fromRGB(100, 220, 140))
hover(submitBtn, Color3.fromRGB(80, 130, 230), Color3.fromRGB(100, 150, 250))
hover(closeBtn,  Color3.fromRGB(220, 70, 70),  Color3.fromRGB(240, 90, 90))

-- ============================================================
-- DRAG SUPPORT
-- ============================================================
do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = card.Position
            shadow.Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset - 5, card.Position.Y.Scale, card.Position.Y.Offset - 3)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            shadow.Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset - 5, card.Position.Y.Scale, card.Position.Y.Offset - 3)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- BUTTON LOGIC
-- ============================================================
copyBtn.MouseButton1Click:Connect(function()
    local ok = pcall(function()
        if setclipboard then
            setclipboard(GET_KEY_LINK)
        elseif toclipboard then
            toclipboard(GET_KEY_LINK)
        else
            error("no clipboard function")
        end
    end)
    if ok then
        copyBtn.Text = "✓  Copied! Open in browser"
        status.Text = "Link copied. Paste it in your browser, get your key, then paste it above."
        status.TextColor3 = Color3.fromRGB(120, 220, 150)
        task.wait(2.5)
        copyBtn.Text = "📋  Copy Get-Key Link"
    else
        status.Text = "Your executor doesn't support clipboard. Link: " .. GET_KEY_LINK
        status.TextColor3 = Color3.fromRGB(255, 180, 80)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    shadow:Destroy()
end)

-- Submit triggers either via button or Enter key
local submitted = false
local userKey = nil

local function trySubmit()
    if submitted then return end
    local k = input.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if k == "" then
        status.Text = "Please paste your key first."
        status.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end
    submitted = true
    userKey = k
    status.Text = "Validating key with Luarmor..."
    status.TextColor3 = Color3.fromRGB(180, 180, 220)
    submitBtn.Text = "Validating..."
    submitBtn.AutoButtonColor = false
end

submitBtn.MouseButton1Click:Connect(trySubmit)
input.FocusLost:Connect(function(enterPressed)
    if enterPressed then trySubmit() end
end)

-- ============================================================
-- WAIT FOR KEY, THEN VALIDATE + LOAD
-- ============================================================
repeat task.wait() until submitted

-- Luarmor loaders read `script_key` global to validate
-- (this is the standard variable name Luarmor's loader expects)
getgenv().script_key = userKey

-- Load Luarmor's protected loader — it will use script_key automatically
local loaderSource
local ok, err = pcall(function()
    loaderSource = game:HttpGet(LUARMOR_LOADER)
end)

if not ok or not loaderSource then
    status.Text = "Couldn't reach Luarmor. Check your internet & try again."
    status.TextColor3 = Color3.fromRGB(255, 120, 120)
    submitBtn.Text = "✓  Submit Key"
    submitted = false
    return
end

local runOk, runErr = pcall(function()
    local fn, parseErr = loadstring(loaderSource)
    if not fn then error(parseErr) end
    fn()
end)

if runOk then
    -- Loader handled everything. Close the GUI.
    gui:Destroy()
    if shadow and shadow.Parent then shadow:Destroy() end
else
    status.Text = "Key invalid or expired. Get a new one and try again."
    status.TextColor3 = Color3.fromRGB(255, 120, 120)
    submitBtn.Text = "✓  Submit Key"
    submitted = false
    -- Reset key so they can try again
    getgenv().script_key = nil
end

-- LocalScript (StarterPlayerScripts หรือ PlayerGui)
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player reference
local player = Players.LocalPlayer
if not player then return end

local character = player.Character
local rootPart
local function updateCharacter(char)
    character = char
    rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end
if character then updateCharacter(character) end
player.CharacterAdded:Connect(updateCharacter)

-- GUI setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProspectingGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 290)
Frame.Position = UDim2.new(0, 20, 0.35, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0.15
Frame.BorderSizePixel = 0
Frame.Visible = true
Frame.Parent = ScreenGui
Frame.ClipsDescendants = true

local function createLabel(name, text, posY, color)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = UDim2.new(0, 240, 0, 24)
    lbl.Position = UDim2.new(0, 10, 0, posY)
    lbl.BackgroundTransparency = 0.5
    lbl.TextScaled = true
    lbl.TextColor3 = color or Color3.new(1, 1, 1)
    lbl.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    lbl.BorderSizePixel = 0
    lbl.Text = text
    lbl.Parent = Frame
    return lbl
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 28)
title.Position = UDim2.new(0, 5, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Auto Prospecting"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Frame

local sandLabel = createLabel("SandLabel", "Sand: [Not set]", 40)
local waterLabel = createLabel("WaterLabel", "Water: [Not set]", 70)
local autofarmStatus = createLabel("AutoFarmStatus", "AutoFarm: OFF", 100, Color3.fromRGB(0,255,0))
autofarmStatus.Size = UDim2.new(0, 240, 0, 22)
autofarmStatus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

-- AutoSell Section
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local shopFolder = remotesFolder:WaitForChild("Shop")
local sellAllFunction = shopFolder:WaitForChild("SellAll")

local autosellEnabled = false
local autosellInterval = 30
local autosellThread

local autosellStatus = createLabel("AutoSellStatus", "AutoSell: OFF", 310, Color3.fromRGB(0,200,255))
autosellStatus.Size = UDim2.new(0, 240, 0, 22)
autosellStatus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

-- Saved positions
local sandPos, waterPos

-- Helper: teleport safely
local function teleportTo(position)
    if not position then return end
    if rootPart and rootPart.Parent then
        rootPart.CFrame = CFrame.new(position)
    end
end

-- Button factory
local function createButton(name, text, positionY, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 240, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, positionY)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.TextScaled = true
    btn.AutoButtonColor = true
    btn.Parent = Frame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Save positions
createButton("SaveSandBtn", "Save Sand Position", 130, function()
    if rootPart then
        sandPos = rootPart.Position
        sandLabel.Text = string.format("Sand: (%.1f, %.1f, %.1f)", sandPos.X, sandPos.Y, sandPos.Z)
    else
        warn("Character root not available to save sand")
    end
end)

createButton("SaveWaterBtn", "Save Water Position", 165, function()
    if rootPart then
        waterPos = rootPart.Position
        waterLabel.Text = string.format("Water: (%.1f, %.1f, %.1f)", waterPos.X, waterPos.Y, waterPos.Z)
    else
        warn("Character root not available to save water")
    end
end)

-- AutoFarm logic
local autofarmEnabled = false
local autofarmThread

local function setAutoFarmStatus(enabled)
    autofarmEnabled = enabled
    if enabled then
        autofarmStatus.Text = "AutoFarm: ON"
        autofarmStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        autofarmStatus.Text = "AutoFarm: OFF"
        autofarmStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function stopAutoFarm()
    autofarmEnabled = false
    if autofarmThread then
        autofarmThread:Disconnect()
        autofarmThread = nil
    end
    setAutoFarmStatus(false)
end

local function toggleAutoFarm()
    if autofarmEnabled then
        stopAutoFarm()
        return
    end
    if not sandPos or not waterPos then
        warn("ทั้ง Sand และ Water ต้องถูกเซฟก่อนเริ่ม AutoFarm")
        return
    end
    setAutoFarmStatus(true)
    autofarmThread = RunService.Heartbeat:Connect(function()
        if not autofarmEnabled then return end
        -- Teleport to sand
        if sandPos then
            teleportTo(sandPos)
            task.wait(1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.5)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            task.wait(2)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.5)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        task.wait(2)
        -- Teleport ไป water หลายรอบ
        if waterPos then
            teleportTo(waterPos)
            task.wait(1)
            for i = 1, 30 do
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.2)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
        task.wait(2)
    end)
end

createButton("FarmButton", "Toggle AutoFarm", 270, toggleAutoFarm)

-- Close / Open UI
local uiVisible = true
local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.new(0, 100, 0, 30)
openButton.Position = UDim2.new(0, 20, 1, -40)
openButton.Text = "Open UI"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
openButton.BorderSizePixel = 0
openButton.Parent = ScreenGui
openButton.Visible = false
openButton.AutoButtonColor = true

local function toggleUI()
    uiVisible = not uiVisible
    Frame.Visible = uiVisible
    openButton.Visible = not uiVisible
end

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
closeButton.BorderSizePixel = 0
closeButton.Parent = Frame
closeButton.AutoButtonColor = true
closeButton.MouseButton1Click:Connect(toggleUI)
openButton.MouseButton1Click:Connect(toggleUI)

-- Dragging support
local dragging, dragStart, startPos = false, nil, nil
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if dragging and dragStart and startPos and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- AutoSell logic
local function stopAutoSell()
    autosellEnabled = false
    if autosellThread then
        task.cancel(autosellThread)
        autosellThread = nil
    end
    autosellStatus.Text = "AutoSell: OFF"
    autosellStatus.TextColor3 = Color3.fromRGB(100, 100, 100)
end

local function setAutoSellStatus(enabled)
    autosellEnabled = enabled
    if enabled then
        autosellStatus.Text = "AutoSell: ON ("..tostring(autosellInterval).."s)"
        autosellStatus.TextColor3 = Color3.fromRGB(0, 200, 255)
    else
        autosellStatus.Text = "AutoSell: OFF"
        autosellStatus.TextColor3 = Color3.fromRGB(100, 100, 100)
    end
end

local function toggleAutoSell()
    if autosellEnabled then
        stopAutoSell()
        return
    end
    setAutoSellStatus(true)
    autosellThread = task.spawn(function()
        while autosellEnabled do
            pcall(function()
                sellAllFunction:InvokeServer()
            end)
            for i = 1, autosellInterval do
                if not autosellEnabled then break end
                task.wait(1)
            end
        end
        setAutoSellStatus(false)
    end)
end

createButton("SellButton", "Toggle AutoSell", 340, toggleAutoSell)

-- ช่องกรอกเวลาขาย (วินาที)
local intervalBox = Instance.new("TextBox")
intervalBox.Name = "IntervalBox"
intervalBox.Size = UDim2.new(0, 100, 0, 24)
intervalBox.Position = UDim2.new(0, 150, 0, 310)
intervalBox.Text = tostring(autosellInterval)
intervalBox.TextColor3 = Color3.new(1, 1, 1)
intervalBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
intervalBox.BorderSizePixel = 0
intervalBox.TextScaled = true
intervalBox.Parent = Frame

intervalBox.FocusLost:Connect(function()
    local val = tonumber(intervalBox.Text)
    if val and val >= 5 then
        autosellInterval = math.floor(val)
        if autosellEnabled then
            autosellStatus.Text = "AutoSell: ON ("..tostring(autosellInterval).."s)"
        end
    else
        intervalBox.Text = tostring(autosellInterval)
    end
end)

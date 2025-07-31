-- LocalScript (เช่นใส่ไว้ใน StarterPlayerScripts หรือใน PlayerGui เมื่อโหลด)
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Player reference (รองรับการโหลดตัวละครใหม่)
local player = Players.LocalPlayer
if not player then return end

local character = player.Character
local rootPart
local function updateCharacter(char)
    character = char
    rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end
if character then
    updateCharacter(character)
end
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
Frame.Rotation = 0

-- Title
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

-- Status labels
local sandLabel = Instance.new("TextLabel")
sandLabel.Size = UDim2.new(0, 240, 0, 24)
sandLabel.Position = UDim2.new(0, 10, 0, 40)
sandLabel.BackgroundTransparency = 0.5
sandLabel.TextScaled = true
sandLabel.TextColor3 = Color3.new(1, 1, 1)
sandLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sandLabel.BorderSizePixel = 0
sandLabel.Text = "Sand: [Not set]"
sandLabel.Parent = Frame

local waterLabel = Instance.new("TextLabel")
waterLabel.Size = UDim2.new(0, 240, 0, 24)
waterLabel.Position = UDim2.new(0, 10, 0, 70)
waterLabel.BackgroundTransparency = 0.5
waterLabel.TextScaled = true
waterLabel.TextColor3 = Color3.new(1, 1, 1)
waterLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
waterLabel.BorderSizePixel = 0
waterLabel.Text = "Water: [Not set]"
waterLabel.Parent = Frame

local autofarmStatus = Instance.new("TextLabel")
autofarmStatus.Size = UDim2.new(0, 240, 0, 22)
autofarmStatus.Position = UDim2.new(0, 10, 0, 100)
autofarmStatus.BackgroundTransparency = 0.5
autofarmStatus.TextScaled = true
autofarmStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
autofarmStatus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
autofarmStatus.BorderSizePixel = 0
autofarmStatus.Text = "AutoFarm: OFF"
autofarmStatus.Parent = Frame

-- Saved positions
local sandPos = nil
local waterPos = nil

-- Helper: teleport safely
local function teleportTo(position)
    if not position then return end
    if rootPart then
        -- Direct set (could be replaced with tween if needed)
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

-- Teleport buttons
createButton("TeleportSandBtn", "Teleport to Sand", 200, function()
    if sandPos then
        teleportTo(sandPos)
    else
        warn("Sand position not set.")
    end
end)

createButton("TeleportWaterBtn", "Teleport to Water", 235, function()
    if waterPos then
        teleportTo(waterPos)
    else
        warn("Water position not set.")
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

local function toggleAutoFarm()
    if autofarmEnabled then
        setAutoFarmStatus(false)
        return
    end
    if not sandPos or not waterPos then
        warn("ทั้ง Sand และ Water ต้องถูกเซฟก่อนเริ่ม AutoFarm")
        return
    end
    setAutoFarmStatus(true)
    autofarmThread = task.spawn(function()
        while autofarmEnabled do
            -- Teleport to sand
            if sandPos then
                teleportTo(sandPos)
                task.wait(1) -- ปรับได้ตามต้องการ
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.5)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                task.wait(2)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.5)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end

            task.wait(3)

            -- Teleport ไป water หลายรอบ (เลียนแบบเดิม)
            if waterPos then
                teleportTo(waterPos)
                task.wait(1) -- ปรับได้ตามต้องการ
                for i = 1, 30 do
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.2)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end
            end

            -- รอบถัดไป
            task.wait(5)
        end
        setAutoFarmStatus(false)
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

-- Close button (X)
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

-- Dragging support (optional, simple)
local dragging = false
local dragStart = nil
local startPos = nil

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

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
Frame.Size = UDim2.new(0, 300, 0, 440)
Frame.Position = UDim2.new(0, 20, 0.35, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0.15
Frame.BorderSizePixel = 0
Frame.Visible = true
Frame.Parent = ScreenGui
Frame.ClipsDescendants = true
Frame.Rotation = 0
Frame.AnchorPoint = Vector2.new(0, 0)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 30)
title.Position = UDim2.new(0, 5, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Auto Prospecting"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Frame

-- Separator function (optional visual divider)
local function makeSeparator(parent, yOffset)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -10, 0, 1)
    sep.Position = UDim2.new(0, 5, 0, yOffset)
    sep.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    sep.BorderSizePixel = 0
    sep.Parent = parent
    return sep
end

-- Status container
local statusContainer = Instance.new("Frame")
statusContainer.Name = "StatusContainer"
statusContainer.Size = UDim2.new(1, -10, 0, 120)
statusContainer.Position = UDim2.new(0, 5, 0, 40)
statusContainer.BackgroundTransparency = 1
statusContainer.Parent = Frame

local statusLayout = Instance.new("UIListLayout")
statusLayout.FillDirection = Enum.FillDirection.Vertical
statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusLayout.VerticalAlignment = Enum.VerticalAlignment.Top
statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
statusLayout.Padding = UDim.new(0, 6)
statusLayout.Parent = statusContainer

-- Status labels
local function makeStatusLabel(text, textColor)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 0.5
    lbl.TextScaled = true
    lbl.TextColor3 = textColor or Color3.new(1, 1, 1)
    lbl.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    lbl.BorderSizePixel = 0
    lbl.Text = text
    lbl.Font = Enum.Font.SourceSans
    lbl.Parent = statusContainer
    return lbl
end

local sandLabel = makeStatusLabel("Sand: [Not set]", Color3.new(1,1,1))
local waterLabel = makeStatusLabel("Water: [Not set]", Color3.new(1,1,1))
local autofarmStatus = makeStatusLabel("AutoFarm: OFF", Color3.fromRGB(0, 1, 0))
local autosellStatus = makeStatusLabel("AutoSell: OFF", Color3.fromRGB(0, 200/255, 1))

-- Controls container
local controlsContainer = Instance.new("Frame")
controlsContainer.Name = "ControlsContainer"
controlsContainer.Size = UDim2.new(1, -10, 0, 220)
controlsContainer.Position = UDim2.new(0, 5, 0, 170)
controlsContainer.BackgroundTransparency = 1
controlsContainer.Parent = Frame

local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Vertical
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
controlsLayout.Padding = UDim.new(0, 10)
controlsLayout.Parent = controlsContainer

-- Button factory (ปรับให้รับ parent)
local function createButton(parent, name, text, sizeX, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, sizeX or 140, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Save positions row (horizontal)
local saveRow = Instance.new("Frame")
saveRow.Size = UDim2.new(1, 0, 0, 40)
saveRow.BackgroundTransparency = 1
saveRow.Parent = controlsContainer

local saveLayout = Instance.new("UIListLayout")
saveLayout.FillDirection = Enum.FillDirection.Horizontal
saveLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
saveLayout.SortOrder = Enum.SortOrder.LayoutOrder
saveLayout.Padding = UDim.new(0, 8)
saveLayout.Parent = saveRow

local SaveSandBtn = createButton(saveRow, "SaveSandBtn", "Save Sand", 135, function()
    if rootPart then
        sandPos = rootPart.Position
        sandLabel.Text = string.format("Sand: (%.1f, %.1f, %.1f)", sandPos.X, sandPos.Y, sandPos.Z)
    else
        warn("Character root not available to save sand")
    end
end)

local SaveWaterBtn = createButton(saveRow, "SaveWaterBtn", "Save Water", 135, function()
    if rootPart then
        waterPos = rootPart.Position
        waterLabel.Text = string.format("Water: (%.1f, %.1f, %.1f)", waterPos.X, waterPos.Y, waterPos.Z)
    else
        warn("Character root not available to save water")
    end
end)

-- AutoFarm toggle row
local farmRow = Instance.new("Frame")
farmRow.Size = UDim2.new(1, 0, 0, 40)
farmRow.BackgroundTransparency = 1
farmRow.Parent = controlsContainer

local farmLayout = Instance.new("UIListLayout")
farmLayout.FillDirection = Enum.FillDirection.Horizontal
farmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
farmLayout.SortOrder = Enum.SortOrder.LayoutOrder
farmLayout.Padding = UDim.new(0, 8)
farmLayout.Parent = farmRow

local FarmButton = createButton(farmRow, "FarmButton", "Toggle AutoFarm", 280, function()
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

            -- Teleport ไป water หลายรอบ (เลียนแบบเดิม)
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
        end
        setAutoFarmStatus(false)
    end)
end)

-- AutoSell row (Sell button + interval)
local autosellRow = Instance.new("Frame")
autosellRow.Size = UDim2.new(1, 0, 0, 40)
autosellRow.BackgroundTransparency = 1
autosellRow.Parent = controlsContainer

local autosellLayout = Instance.new("UIListLayout")
autosellLayout.FillDirection = Enum.FillDirection.Horizontal
autosellLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
autosellLayout.SortOrder = Enum.SortOrder.LayoutOrder
autosellLayout.Padding = UDim.new(0, 8)
autosellLayout.Parent = autosellRow

local SellButton = createButton(autosellRow, "SellButton", "Toggle AutoSell", 160, function()
    if autosellEnabled then
        setAutoSellStatus(false)
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
end)

-- Interval input box
local intervalBox = Instance.new("TextBox")
intervalBox.Name = "IntervalBox"
intervalBox.Size = UDim2.new(0, 100, 0, 32)
intervalBox.Text = tostring(30)
intervalBox.TextColor3 = Color3.new(1, 1, 1)
intervalBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
intervalBox.BorderSizePixel = 0
intervalBox.TextScaled = true
intervalBox.Font = Enum.Font.SourceSans
intervalBox.Parent = autosellRow

local intervalLabel = Instance.new("TextLabel")
intervalLabel.Size = UDim2.new(0, 60, 0, 32)
intervalLabel.BackgroundTransparency = 1
intervalLabel.Text = "Interval"
intervalLabel.TextColor3 = Color3.new(1, 1, 1)
intervalLabel.TextScaled = true
intervalLabel.Font = Enum.Font.SourceSans
intervalLabel.Parent = autosellRow

intervalBox.FocusLost:Connect(function(enter)
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

-- AutoFarm / AutoSell status helpers
local autofarmEnabled = false
local autofarmThread
local autosellEnabled = false
local autosellThread
local autosellInterval = 30 -- ค่าเริ่มต้น 30 วินาที

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

-- AutoSell logic dependencies (ต้องอยู่ข้างล่างเพราะใช้ฟังก์ชันข้างบน)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local shopFolder = remotesFolder:WaitForChild("Shop")
local sellAllFunction = shopFolder:WaitForChild("SellAll")

-- Saved positions
local sandPos = nil
local waterPos = nil

-- Helper: teleport safely
local function teleportTo(position)
    if not position then return end
    if rootPart then
        rootPart.CFrame = CFrame.new(position)
    end
end

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
openButton.Font = Enum.Font.SourceSansBold

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
closeButton.AnchorPoint = Vector2.new(0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
closeButton.BorderSizePixel = 0
closeButton.Parent = Frame
closeButton.AutoButtonColor = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.MouseButton1Click:Connect(toggleUI)
openButton.MouseButton1Click:Connect(toggleUI)

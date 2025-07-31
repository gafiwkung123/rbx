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
if character then
    updateCharacter(character)
end
player.CharacterAdded:Connect(updateCharacter)

-- Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local shopFolder = remotesFolder:WaitForChild("Shop")
local sellAllFunction = shopFolder:WaitForChild("SellAll")

-- State
local sandPos, waterPos = nil, nil
local autofarmEnabled = false
local autosellEnabled = false
local autosellInterval = 30
local autofarmThread, autosellThread

-- Colors / Styling
local BG_COLOR = Color3.fromRGB(30, 30, 30)
local SECTION_BG = Color3.fromRGB(40, 40, 40)
local BUTTON_COLOR = Color3.fromRGB(60, 60, 60)
local LABEL_BG = Color3.fromRGB(50, 50, 50)

-- GUI setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProspectingGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 300, 0, 410)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = BG_COLOR
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui
Frame.Rotation = 0

-- UI rounding (optional, can be removed if undesired)
local function applyUICorner(inst, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = inst
end
applyUICorner(Frame, 10)

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundTransparency = 0
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame
applyUICorner(TitleBar, 8)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Auto Prospecting"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = TitleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 28, 0, 24)
closeButton.Position = UDim2.new(1, -34, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.TextScaled = true
closeButton.AutoButtonColor = true
closeButton.Parent = TitleBar
applyUICorner(closeButton, 4)

-- Collapse/Open logic
local contentVisible = true
local contentHolder = Instance.new("Frame")
contentHolder.Name = "Content"
contentHolder.Size = UDim2.new(1, -10, 1, -42)
contentHolder.Position = UDim2.new(0, 5, 0, 37)
contentHolder.BackgroundTransparency = 1
contentHolder.Parent = Frame

-- Layout inside content
local mainList = Instance.new("UIListLayout")
mainList.Padding = UDim.new(0, 8)
mainList.FillDirection = Enum.FillDirection.Vertical
mainList.VerticalAlignment = Enum.VerticalAlignment.Top
mainList.SortOrder = Enum.SortOrder.LayoutOrder
mainList.Parent = contentHolder

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 4)
contentPadding.PaddingBottom = UDim.new(0, 4)
contentPadding.PaddingLeft = UDim.new(0, 4)
contentPadding.PaddingRight = UDim.new(0, 4)
contentPadding.Parent = contentHolder

-- Utility: section creator
local function createSection(titleText)
    local section = Instance.new("Frame")
    section.Name = titleText:gsub("%s","").."Section"
    section.Size = UDim2.new(1, 0, 0, 0) -- automatic with layout
    section.BackgroundColor3 = SECTION_BG
    section.BorderSizePixel = 0
    section.Parent = contentHolder
    applyUICorner(section, 6)

    local secPadding = Instance.new("UIPadding")
    secPadding.PaddingTop = UDim.new(0, 8)
    secPadding.PaddingBottom = UDim.new(0, 8)
    secPadding.PaddingLeft = UDim.new(0, 8)
    secPadding.PaddingRight = UDim.new(0, 8)
    secPadding.Parent = section

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = section

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.SourceSansBold
    header.Text = titleText
    header.TextColor3 = Color3.new(1,1,1)
    header.TextScaled = true
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = section

    return section
end

-- Positions section
local positionsSection = createSection("Saved Positions")
-- Labels container
local posLabels = Instance.new("Frame")
posLabels.Name = "Labels"
posLabels.Size = UDim2.new(1, 0, 0, 60)
posLabels.BackgroundTransparency = 1
posLabels.Parent = positionsSection

local labelsLayout = Instance.new("UIListLayout")
labelsLayout.FillDirection = Enum.FillDirection.Vertical
labelsLayout.SortOrder = Enum.SortOrder.LayoutOrder
labelsLayout.Padding = UDim.new(0, 4)
labelsLayout.Parent = posLabels

-- Sand label
local sandLabel = Instance.new("TextLabel")
sandLabel.Name = "SandLabel"
sandLabel.Size = UDim2.new(1, 0, 0, 24)
sandLabel.BackgroundColor3 = LABEL_BG
sandLabel.BorderSizePixel = 0
sandLabel.Text = "Sand: [Not set]"
sandLabel.TextScaled = true
sandLabel.TextColor3 = Color3.new(1,1,1)
sandLabel.Font = Enum.Font.SourceSans
sandLabel.Parent = posLabels
applyUICorner(sandLabel, 4)

-- Water label
local waterLabel = Instance.new("TextLabel")
waterLabel.Name = "WaterLabel"
waterLabel.Size = UDim2.new(1, 0, 0, 24)
waterLabel.BackgroundColor3 = LABEL_BG
waterLabel.BorderSizePixel = 0
waterLabel.Text = "Water: [Not set]"
waterLabel.TextScaled = true
waterLabel.TextColor3 = Color3.new(1,1,1)
waterLabel.Font = Enum.Font.SourceSans
waterLabel.Parent = posLabels
applyUICorner(waterLabel, 4)

-- Save buttons row
local saveButtonsRow = Instance.new("Frame")
saveButtonsRow.Name = "SaveButtonsRow"
saveButtonsRow.Size = UDim2.new(1, 0, 0, 36)
saveButtonsRow.BackgroundTransparency = 1
saveButtonsRow.Parent = positionsSection

local saveLayout = Instance.new("UIListLayout")
saveLayout.FillDirection = Enum.FillDirection.Horizontal
saveLayout.SortOrder = Enum.SortOrder.LayoutOrder
saveLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
saveLayout.Padding = UDim.new(0, 8)
saveLayout.Parent = saveButtonsRow

local function makeSmallButton(name, text, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.5, -4, 1, 0)
    btn.BackgroundColor3 = BUTTON_COLOR
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSansBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.AutoButtonColor = true
    btn.Parent = saveButtonsRow
    applyUICorner(btn, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

makeSmallButton("SaveSandBtn", "Save Sand", 0, function()
    if rootPart then
        sandPos = rootPart.Position
        sandLabel.Text = string.format("Sand: (%.1f, %.1f, %.1f)", sandPos.X, sandPos.Y, sandPos.Z)
    else
        warn("Character root not available to save sand")
    end
end)

makeSmallButton("SaveWaterBtn", "Save Water", 0, function()
    if rootPart then
        waterPos = rootPart.Position
        waterLabel.Text = string.format("Water: (%.1f, %.1f, %.1f)", waterPos.X, waterPos.Y, waterPos.Z)
    else
        warn("Character root not available to save water")
    end
end)

-- AutoFarm section
local autofarmSection = createSection("AutoFarm")
local autofarmStatus = Instance.new("TextLabel")
autofarmStatus.Name = "AutoFarmStatus"
autofarmStatus.Size = UDim2.new(1, 0, 0, 24)
autofarmStatus.BackgroundColor3 = Color3.fromRGB(50,50,50)
autofarmStatus.BorderSizePixel = 0
autofarmStatus.Text = "AutoFarm: OFF"
autofarmStatus.TextScaled = true
autofarmStatus.Font = Enum.Font.SourceSansSemibold
autofarmStatus.TextColor3 = Color3.fromRGB(255,100,100)
autofarmStatus.Parent = autofarmSection
applyUICorner(autofarmStatus, 4)

local farmButton = Instance.new("TextButton")
farmButton.Name = "FarmButton"
farmButton.Size = UDim2.new(1, 0, 0, 34)
farmButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
farmButton.BorderSizePixel = 0
farmButton.Text = "Toggle AutoFarm"
farmButton.TextScaled = true
farmButton.Font = Enum.Font.SourceSansBold
farmButton.TextColor3 = Color3.new(1,1,1)
farmButton.AutoButtonColor = true
farmButton.Parent = autofarmSection
applyUICorner(farmButton, 6)

-- AutoSell section
local autosellSection = createSection("AutoSell")
local autosellStatus = Instance.new("TextLabel")
autosellStatus.Name = "AutoSellStatus"
autosellStatus.Size = UDim2.new(1, 0, 0, 24)
autosellStatus.BackgroundColor3 = Color3.fromRGB(50,50,50)
autosellStatus.BorderSizePixel = 0
autosellStatus.Text = "AutoSell: OFF"
autosellStatus.TextScaled = true
autosellStatus.Font = Enum.Font.SourceSansSemibold
autosellStatus.TextColor3 = Color3.fromRGB(100,100,100)
autosellStatus.Parent = autosellSection
applyUICorner(autosellStatus, 4)

-- Interval + toggle row
local autosellControls = Instance.new("Frame")
autosellControls.Name = "AutoSellControls"
autosellControls.Size = UDim2.new(1, 0, 0, 40)
autosellControls.BackgroundTransparency = 1
autosellControls.Parent = autosellSection

local sellLayout = Instance.new("UIListLayout")
sellLayout.FillDirection = Enum.FillDirection.Horizontal
sellLayout.SortOrder = Enum.SortOrder.LayoutOrder
sellLayout.Padding = UDim.new(0, 10)
sellLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
sellLayout.VerticalAlignment = Enum.VerticalAlignment.Center
sellLayout.Parent = autosellControls

-- Interval label
local intervalLabel = Instance.new("TextLabel")
intervalLabel.Name = "IntervalLabel"
intervalLabel.Size = UDim2.new(0, 110, 1, 0)
intervalLabel.BackgroundTransparency = 0
intervalLabel.BackgroundColor3 = LABEL_BG
intervalLabel.BorderSizePixel = 0
intervalLabel.Text = "Interval (s):"
intervalLabel.TextScaled = true
intervalLabel.Font = Enum.Font.SourceSans
intervalLabel.TextColor3 = Color3.new(1,1,1)
intervalLabel.Parent = autosellControls
applyUICorner(intervalLabel, 4)

-- Interval box
local intervalBox = Instance.new("TextBox")
intervalBox.Name = "IntervalBox"
intervalBox.Size = UDim2.new(0, 70, 1, 0)
intervalBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
intervalBox.BorderSizePixel = 0
intervalBox.Text = tostring(autosellInterval)
intervalBox.TextScaled = true
intervalBox.Font = Enum.Font.SourceSans
intervalBox.TextColor3 = Color3.new(1,1,1)
intervalBox.ClearTextOnFocus = false
intervalBox.Parent = autosellControls
applyUICorner(intervalBox, 4)

-- Sell toggle button
local sellToggleBtn = Instance.new("TextButton")
sellToggleBtn.Name = "SellToggleBtn"
sellToggleBtn.Size = UDim2.new(0, 140, 1, 0)
sellToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
sellToggleBtn.BorderSizePixel = 0
sellToggleBtn.Text = "Toggle AutoSell"
sellToggleBtn.TextScaled = true
sellToggleBtn.Font = Enum.Font.SourceSansBold
sellToggleBtn.TextColor3 = Color3.new(1,1,1)
sellToggleBtn.AutoButtonColor = true
sellToggleBtn.Parent = autosellControls
applyUICorner(sellToggleBtn, 6)

-- Helpers
local function teleportTo(position)
    if not position then return end
    if rootPart then
        rootPart.CFrame = CFrame.new(position)
    end
end

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
end

-- Connections
farmButton.MouseButton1Click:Connect(toggleAutoFarm)
sellToggleBtn.MouseButton1Click:Connect(toggleAutoSell)

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

-- Close/collapse behavior
closeButton.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    contentHolder.Visible = contentVisible
    if contentVisible then
        closeButton.Text = "X"
        Frame.Size = UDim2.new(0, 300, 0, 410)
    else
        closeButton.Text = "▶"
        Frame.Size = UDim2.new(0, 140, 0, 40)
    end
end)

-- Dragging via title bar
local dragging = false
local dragStart = nil
local startPos = nil

TitleBar.InputBegan:Connect(function(input)
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

TitleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

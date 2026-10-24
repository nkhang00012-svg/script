-- Cấu hình
local HELICOPTER_MODEL_ID = 12180722690
local SOUND_ID = "rbxassetid://99103708154004"
local DISTANCE_FRONT = 20  
local TARGET_HEIGHT = 30   
local START_HEIGHT = 200   

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- 0. DỌN DẸP UI CŨ TRƯỚC KHI TẠO MỚI
--------------------------------------------------------------------------------
local uiNames = {"WalkieTalkieGui", "MissileControlUI", "KamikazeHUD", "CrashErrorUI", "TargetSelectGui"}
for _, name in ipairs(uiNames) do
    if CoreGui:FindFirstChild(name) then CoreGui[name]:Destroy() end
end
if Workspace:FindFirstChild("KamikazeFlySound") then Workspace.KamikazeFlySound:Destroy() end
if Workspace:FindFirstChild("KamikazeCrashSound") then Workspace.KamikazeCrashSound:Destroy() end

-- Biến trạng thái
local isHelicopterActive = false
local isFollowing = false
local currentModel = nil
local hoverConnection = nil
local followConnection = nil
local soundConnection = nil
local originalTransparencies = {}
local originalColors = {}

-- Hệ thống Slot Bom & FPV[cite: 1]
local loadedMissiles = {nil, nil, nil} 
local pendingMissile = nil
local readyMissile = nil
local isControlling = false

-- Color Palette (Bảng màu Modern Cyber/Tactical)
local COLOR_BG = Color3.fromRGB(15, 20, 25)
local COLOR_CARD = Color3.fromRGB(24, 32, 40)
local COLOR_ACCENT = Color3.fromRGB(0, 255, 136) -- Neon Green
local COLOR_ACCENT_DIM = Color3.fromRGB(0, 180, 100)
local COLOR_DANGER = Color3.fromRGB(255, 65, 84)
local COLOR_TEXT = Color3.fromRGB(230, 240, 255)
local COLOR_TEXT_MUTED = Color3.fromRGB(130, 150, 170)

local flySound = Instance.new("Sound")
flySound.Name = "KamikazeFlySound"
flySound.SoundId = "rbxassetid://136704576012970"
flySound.Volume = 0.5
flySound.Looped = true
flySound.Parent = Workspace

local crashSound = Instance.new("Sound")
crashSound.Name = "KamikazeCrashSound"
crashSound.SoundId = "rbxassetid://133122797031364"
crashSound.Volume = 1
crashSound.Looped = false
crashSound.Parent = Workspace

-- Kết nối GrabEvents từ script FPV gốc[cite: 1]
local GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 5)
local createEvent = GrabEvents and GrabEvents:WaitForChild("CreateGrabLine", 5)
local destroyEvent = GrabEvents and GrabEvents:WaitForChild("DestroyGrabLine", 5)

if createEvent and destroyEvent then
    createEvent.OnClientEvent:Connect(function(p, grabbedPart)
        if p == player or p == player.Name or (typeof(p) == "Instance" and p.Name == player.Name) then
            if grabbedPart then
                local model = grabbedPart:FindFirstAncestorOfClass("Model")
                if model and model.Name == "BombMissile" then pendingMissile = model end
            end
        end
    end)

    destroyEvent.OnClientEvent:Connect(function(p)
        if p == player or p == player.Name or (typeof(p) == "Instance" and p.Name == player.Name) then
            if pendingMissile and pendingMissile.Name == "BombMissile" then
                readyMissile = pendingMissile
                pendingMissile = nil
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- HÀM HỖ TRỢ XỬ LÝ MODEL ID 15377453991 & TÀNG HÌNH PART FLAMES (GIỮ HIỆU ỨNG x10)
--------------------------------------------------------------------------------
local function processSpecialExplosionEffect(worldPosition)
    task.spawn(function()
        local success, objects = pcall(function()
            return game:GetObjects("rbxassetid://15377453991")
        end)
        if success and objects then
            for _, obj in ipairs(objects) do
                local function scanAndModify(item)
                    if item:IsA("Model") or item:IsA("Folder") then
                        for _, child in ipairs(item:GetChildren()) do
                            scanAndModify(child)
                        end
                    elseif item:IsA("BasePart") then
                        if item.Name == "Flames" then
                            item.Parent = Workspace
                            item.Anchored = true
                            item.CanCollide = false
                            item.Position = worldPosition
                            item.Size = item.Size * 10 -- Phóng to x10 lần vụ nổ
                            item.Transparency = 1      -- Tàng hình part 100%, giữ lại hiệu ứng bên trong
                            
                            task.delay(5, function()
                                if item and item.Parent then
                                    item:Destroy()
                                end
                            end)
                        end
                    end
                end
                scanAndModify(obj)
                obj:Destroy()
            end
        end
    end)
end

local function createMissileESP(bombPart, targetRoot)
    local espGui = Instance.new("BillboardGui")
    espGui.Size = UDim2.new(0, 100, 0, 30)
    espGui.AlwaysOnTop = true
    espGui.StudsOffset = Vector3.new(0, 2, 0)
    espGui.Parent = bombPart

    local textLabel = Instance.new("TextLabel", espGui)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "MISSILE LOCK"
    textLabel.TextColor3 = COLOR_DANGER
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 12

    local att0 = Instance.new("Attachment", bombPart)
    local att1 = Instance.new("Attachment", targetRoot)
    
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Color = ColorSequence.new(COLOR_DANGER)
    beam.Width0 = 0.3
    beam.Width1 = 0.3
    beam.FaceCamera = true
    beam.Parent = bombPart

    return function()
        if espGui then espGui:Destroy() end
        if beam then beam:Destroy() end
        if att0 then att0:Destroy() end
        if att1 then att1:Destroy() end
    end
end

--------------------------------------------------------------------------------
-- UTILS: HÀM TẠO ANIMATION HOVER & MỞ/ĐÓNG UI
--------------------------------------------------------------------------------
local function applyButtonHover(btn, normalBg, hoverBg)
    local originalSize = btn.Size
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverBg
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = normalBg
        }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        btn:TweenSize(UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 4, originalSize.Y.Scale, originalSize.Y.Offset - 2), "Out", "Quad", 0.05, true)
    end)
    btn.MouseButton1Up:Connect(function()
        btn:TweenSize(originalSize, "Out", "Quad", 0.1, true)
    end)
end

local function animateIn(frame)
    frame.Visible = true
    frame.UIScale.Scale = 0.8
    frame.GroupTransparency = 1
    TweenService:Create(frame.UIScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
end

local function animateOut(frame)
    local t1 = TweenService:Create(frame.UIScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.85})
    local t2 = TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
    t1:Play()
    t2:Play()
    t2.Completed:Connect(function()
        frame.Visible = false
    end)
end

--------------------------------------------------------------------------------
-- 1. GIAO DIỆN BỘ ĐÀM (WALKIE-TALKIE MODERN UI)
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WalkieTalkieGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999

if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
elseif gethui then
    screenGui.Parent = gethui()
else
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local toggleWalkieBtn = Instance.new("TextButton")
toggleWalkieBtn.Name = "ToggleWalkieBtn"
toggleWalkieBtn.Size = UDim2.new(0, 52, 0, 52)
toggleWalkieBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
toggleWalkieBtn.BackgroundColor3 = COLOR_BG
toggleWalkieBtn.TextColor3 = COLOR_ACCENT
toggleWalkieBtn.Text = "📻"
toggleWalkieBtn.TextSize = 22
toggleWalkieBtn.Parent = screenGui
Instance.new("UICorner", toggleWalkieBtn).CornerRadius = UDim.new(0, 14)

local btnStroke = Instance.new("UIStroke", toggleWalkieBtn)
btnStroke.Color = COLOR_ACCENT
btnStroke.Thickness = 1.5

applyButtonHover(toggleWalkieBtn, COLOR_BG, COLOR_CARD)

local WalkieFrame = Instance.new("CanvasGroup")
WalkieFrame.Name = "WalkieFrame"
WalkieFrame.Size = UDim2.new(0, 260, 0, 430)
WalkieFrame.Position = UDim2.new(0.02, 60, 0.35, 0)
WalkieFrame.BackgroundColor3 = COLOR_BG
WalkieFrame.BorderSizePixel = 0
WalkieFrame.Visible = false
WalkieFrame.Active = true
WalkieFrame.Draggable = true
WalkieFrame.Parent = screenGui
Instance.new("UICorner", WalkieFrame).CornerRadius = UDim.new(0, 16)
Instance.new("UIScale", WalkieFrame)

local walkieStroke = Instance.new("UIStroke", WalkieFrame)
walkieStroke.Color = Color3.fromRGB(45, 60, 75)
walkieStroke.Thickness = 1.5

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "WALKIE - TALKIE v2.0"
TitleLabel.TextColor3 = COLOR_ACCENT
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.Parent = WalkieFrame

local ScreenLCD = Instance.new("Frame")
ScreenLCD.Size = UDim2.new(0.9, 0, 0, 130)
ScreenLCD.Position = UDim2.new(0.05, 0, 0, 40)
ScreenLCD.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
ScreenLCD.Parent = WalkieFrame
Instance.new("UICorner", ScreenLCD).CornerRadius = UDim.new(0, 10)

local lcdStroke = Instance.new("UIStroke", ScreenLCD)
lcdStroke.Color = Color3.fromRGB(25, 45, 35)

local StatusDisplay = Instance.new("TextLabel")
StatusDisplay.Size = UDim2.new(1, -16, 1, -12)
StatusDisplay.Position = UDim2.new(0, 8, 0, 6)
StatusDisplay.BackgroundTransparency = 1
StatusDisplay.Text = "SYSTEM: READY\nHELI: OFF\nSLOT 1: [ EMPTY ]\nSLOT 2: [ EMPTY ]\nSLOT 3: [ EMPTY ]"
StatusDisplay.TextColor3 = COLOR_ACCENT
StatusDisplay.Font = Enum.Font.Code
StatusDisplay.TextSize = 11
StatusDisplay.TextXAlignment = Enum.TextXAlignment.Left
StatusDisplay.TextYAlignment = Enum.TextYAlignment.Top
StatusDisplay.TextWrapped = true
StatusDisplay.Parent = ScreenLCD

local function createButton(text, pos, bg, textCol)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.Position = pos
    btn.BackgroundColor3 = bg
    btn.TextColor3 = textCol
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = WalkieFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local ToggleHeliBtn = createButton("SPAWN TRỰC THĂNG: TẮT", UDim2.new(0.05, 0, 0, 180), COLOR_CARD, COLOR_DANGER)
local LoadMissileBtn = createButton("NẠP ĐẠN: CHƯA CÓ", UDim2.new(0.05, 0, 0, 224), COLOR_CARD, COLOR_TEXT_MUTED)
local FollowBtn = createButton("FOLLOW ME: TẮT", UDim2.new(0.05, 0, 0, 268), COLOR_CARD, COLOR_ACCENT_DIM)
local FireMissileBtn = createButton("KHAI HỎA TÊN LỬA", UDim2.new(0.05, 0, 0, 312), Color3.fromRGB(45, 20, 25), COLOR_DANGER)

applyButtonHover(ToggleHeliBtn, COLOR_CARD, Color3.fromRGB(32, 42, 52))
applyButtonHover(LoadMissileBtn, COLOR_CARD, Color3.fromRGB(32, 42, 52))
applyButtonHover(FollowBtn, COLOR_CARD, Color3.fromRGB(32, 42, 52))
applyButtonHover(FireMissileBtn, Color3.fromRGB(45, 20, 25), Color3.fromRGB(65, 25, 30))

local CloseWalkieBtn = createButton("ĐÓNG BỘ ĐÀM", UDim2.new(0.05, 0, 1, -42), Color3.fromRGB(20, 25, 30), COLOR_TEXT_MUTED)
applyButtonHover(CloseWalkieBtn, Color3.fromRGB(20, 25, 30), Color3.fromRGB(30, 35, 42))

--------------------------------------------------------------------------------
-- 2. GIAO DIỆN CHỌN MỤC TIÊU (TARGET SELECTOR MODERN UI - CÓ HIỂN THỊ AVATAR)
--------------------------------------------------------------------------------
local TargetGui = Instance.new("ScreenGui")
TargetGui.Name = "TargetSelectGui"
TargetGui.ResetOnSpawn = false
TargetGui.Enabled = false
TargetGui.DisplayOrder = 9999999
TargetGui.Parent = CoreGui

local TargetFrame = Instance.new("CanvasGroup", TargetGui)
TargetFrame.Size = UDim2.new(0, 320, 0, 420)
TargetFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
TargetFrame.BackgroundColor3 = COLOR_BG
TargetFrame.Active = true
TargetFrame.Draggable = true
TargetFrame.Parent = TargetGui
Instance.new("UICorner", TargetFrame).CornerRadius = UDim.new(0, 16)
Instance.new("UIScale", TargetFrame)

local targetStroke = Instance.new("UIStroke", TargetFrame)
targetStroke.Color = COLOR_ACCENT
targetStroke.Thickness = 1.5

local TargetTitle = Instance.new("TextLabel", TargetFrame)
TargetTitle.Size = UDim2.new(1, 0, 0, 45)
TargetTitle.BackgroundTransparency = 1
TargetTitle.Text = "🎯 CHỌN MỤC TIÊU TẤN CÔNG"
TargetTitle.TextColor3 = COLOR_ACCENT
TargetTitle.Font = Enum.Font.GothamBold
TargetTitle.TextSize = 13

local CloseTargetBtn = Instance.new("TextButton", TargetFrame)
CloseTargetBtn.Size = UDim2.new(0, 28, 0, 28)
CloseTargetBtn.Position = UDim2.new(1, -36, 0, 9)
CloseTargetBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
CloseTargetBtn.TextColor3 = COLOR_DANGER
CloseTargetBtn.Text = "✕"
CloseTargetBtn.Font = Enum.Font.GothamBold
CloseTargetBtn.TextSize = 12
Instance.new("UICorner", CloseTargetBtn).CornerRadius = UDim.new(0, 8)
applyButtonHover(CloseTargetBtn, Color3.fromRGB(35, 20, 25), Color3.fromRGB(55, 25, 30))

local ScrollingList = Instance.new("ScrollingFrame", TargetFrame)
ScrollingList.Size = UDim2.new(1, -24, 1, -60)
ScrollingList.Position = UDim2.new(0, 12, 0, 50)
ScrollingList.BackgroundTransparency = 1
ScrollingList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingList.ScrollBarThickness = 4
ScrollingList.ScrollBarImageColor3 = COLOR_ACCENT

local UIListLayout = Instance.new("UIListLayout", ScrollingList)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

local function refreshPlayerList(onSelectCallback)
    for _, child in ipairs(ScrollingList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            count = count + 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 54)
            btn.BackgroundColor3 = COLOR_CARD
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.Parent = ScrollingList
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

            -- Hiển thị Avatar của người chơi
            local icon = Instance.new("ImageLabel", btn)
            icon.Size = UDim2.new(0, 38, 0, 38)
            icon.Position = UDim2.new(0, 8, 0.5, -19)
            icon.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
            icon.BackgroundTransparency = 0.5
            Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
            
            local iconStroke = Instance.new("UIStroke", icon)
            iconStroke.Color = COLOR_ACCENT
            iconStroke.Thickness = 1

            task.spawn(function()
                local success, thumbContent = pcall(function()
                    return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size42x42)
                end)
                if success and icon and icon.Parent then 
                    icon.Image = thumbContent 
                end
            end)

            local nameLabel = Instance.new("TextLabel", btn)
            nameLabel.Size = UDim2.new(1, -58, 1, 0)
            nameLabel.Position = UDim2.new(0, 54, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = string.format("<b>%s</b>\n<font color=\"#8296AA\">@%s</font>", p.DisplayName, p.Name)
            nameLabel.RichText = true
            nameLabel.TextColor3 = COLOR_TEXT
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 11
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left

            applyButtonHover(btn, COLOR_CARD, Color3.fromRGB(32, 44, 56))

            btn.MouseButton1Click:Connect(function()
                animateOut(TargetFrame)
                task.delay(0.2, function() TargetGui.Enabled = false end)
                if onSelectCallback then onSelectCallback(p) end
            end)
        end
    end
    ScrollingList.CanvasSize = UDim2.new(0, 0, 0, count * 62)
end

CloseTargetBtn.MouseButton1Click:Connect(function()
    animateOut(TargetFrame)
    task.delay(0.2, function() TargetGui.Enabled = false end)
end)

--------------------------------------------------------------------------------
-- 3. HUD KAMIKAZE FPV MODERN
--------------------------------------------------------------------------------
local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "KamikazeHUD"
HUDGui.ResetOnSpawn = false
HUDGui.Enabled = false
HUDGui.DisplayOrder = 9999999
HUDGui.Parent = CoreGui

local BatteryOuterBorder = Instance.new("Frame", HUDGui)
BatteryOuterBorder.Size = UDim2.new(0, 20, 0, 180)
BatteryOuterBorder.Position = UDim2.new(0, 30, 0.45, -90)
BatteryOuterBorder.BackgroundColor3 = COLOR_BG
BatteryOuterBorder.BorderSizePixel = 0
Instance.new("UICorner", BatteryOuterBorder).CornerRadius = UDim.new(0, 6)

local outerStroke = Instance.new("UIStroke", BatteryOuterBorder)
outerStroke.Color = COLOR_ACCENT
outerStroke.Thickness = 1.5

local BatteryFill = Instance.new("Frame", BatteryOuterBorder)
BatteryFill.Size = UDim2.new(1, -4, 1, -4)
BatteryFill.Position = UDim2.new(0, 2, 0, 2)
BatteryFill.BackgroundColor3 = COLOR_ACCENT
BatteryFill.BorderSizePixel = 0
Instance.new("UICorner", BatteryFill).CornerRadius = UDim.new(0, 4)

local BatteryPercentText = Instance.new("TextLabel", HUDGui)
BatteryPercentText.Size = UDim2.new(0, 60, 0, 20)
BatteryPercentText.Position = UDim2.new(0, 58, 0.45, -10)
BatteryPercentText.BackgroundTransparency = 1
BatteryPercentText.Text = "100%"
BatteryPercentText.TextColor3 = COLOR_ACCENT
BatteryPercentText.Font = Enum.Font.GothamBold
BatteryPercentText.TextSize = 13
BatteryPercentText.TextXAlignment = Enum.TextXAlignment.Left

--------------------------------------------------------------------------------
-- 4. ÂM THANH & HOVER / FOLLOW ANIMATION
--------------------------------------------------------------------------------
local function setupHelicopterSound(model)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = SOUND_ID
    sound.Looped = true
    sound.Volume = 0
    sound.Parent = model
    sound:Play()

    sound.Ended:Connect(function()
        if sound and sound.Parent then sound:Play() end
    end)

    local rootPart = character.HumanoidRootPart
    local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return end

    if soundConnection then soundConnection:Disconnect() end

    soundConnection = RunService.RenderStepped:Connect(function()
        if not model or not model.Parent or not sound.IsPlaying then
            if soundConnection then soundConnection:Disconnect() end
            return
        end
        local distance = (targetPart.Position - rootPart.Position).Magnitude
        local maxDistance = 100 
        if distance <= maxDistance then
            local volumeFactor = (1 - (distance / maxDistance)) * 2.5
            sound.Volume = math.clamp(volumeFactor, 0, 2.5)
        else
            sound.Volume = 0
        end
    end)
end

local function startHoverAnimation(model, baseCFrame)
    if hoverConnection then hoverConnection:Disconnect() end
    local startTime = tick()
    hoverConnection = RunService.RenderStepped:Connect(function()
        if isFollowing or not model or not model.Parent then return end
        
        local elapsed = tick() - startTime
        local offsetY = math.sin(elapsed * 2) * 1.5           
        local roll = math.sin(elapsed * 1.5) * math.rad(2.5)  
        local pitch = math.cos(elapsed * 1.2) * math.rad(1.5) 
        
        local animatedCFrame = baseCFrame * CFrame.new(0, offsetY, 0) * CFrame.Angles(pitch, 0, roll)
        if model.PrimaryPart then
            model:SetPrimaryPartCFrame(animatedCFrame)
        else
            model:PivotTo(animatedCFrame)
        end

        local offsets = { CFrame.new(-10, 4, 0), CFrame.new(0, 4, 0), CFrame.new(10, 4, 0) }
        for i, bomb in ipairs(loadedMissiles) do
            if bomb and bomb.Parent then bomb:PivotTo(animatedCFrame * offsets[i]) end
        end
    end)
end

local function startFollowAnimation(model)
    if followConnection then followConnection:Disconnect() end
    local startTime = tick()
    followConnection = RunService.RenderStepped:Connect(function(dt)
        if not isFollowing or not model or not model.Parent then 
            if followConnection then followConnection:Disconnect() end
            return 
        end

        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local rootPart = character.HumanoidRootPart

        local camLook = camera.CFrame.LookVector
        local flatLook = Vector3.new(camLook.X, 0, camLook.Unit.Z).Unit
        local rightVector = Vector3.new(-flatLook.Z, 0, flatLook.X)

        local targetPos = rootPart.Position + (rightVector * 20) + Vector3.new(0, TARGET_HEIGHT, 0)
        local elapsed = tick() - startTime
        targetPos = targetPos + Vector3.new(0, math.sin(elapsed * 3) * 1.0, 0)

        local currentPivot = model:GetPivot()
        local newPos = currentPivot.Position:Lerp(targetPos, math.min(dt * 7, 1))
        
        local moveDelta = (targetPos - currentPivot.Position)
        local roll = math.clamp(-moveDelta.X * 0.05, -math.rad(15), math.rad(15))
        local pitch = math.clamp(moveDelta.Z * 0.05, -math.rad(10), math.rad(10))

        local targetCFrame = CFrame.new(newPos, newPos + flatLook) * CFrame.Angles(pitch, 0, roll)

        if model.PrimaryPart then model:SetPrimaryPartCFrame(targetCFrame)
        else model:PivotTo(targetCFrame) end

        local offsets = { CFrame.new(-10, 4, 0), CFrame.new(0, 4, 0), CFrame.new(10, 4, 0) }
        for i, bomb in ipairs(loadedMissiles) do
            if bomb and bomb.Parent then
                local targetBombCF = targetCFrame * offsets[i]
                bomb:PivotTo(targetBombCF)
                local bRoot = bomb.PrimaryPart or bomb:FindFirstChildWhichIsA("BasePart")
                if bRoot then
                    bRoot.AssemblyLinearVelocity = (targetBombCF.Position - bRoot.Position) / dt
                    bRoot.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end

local function cacheAndSetupModel(model)
    originalTransparencies = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
            originalTransparencies[part] = part.Transparency
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Anchored = true
            end
        end
    end
end

local function updateDynamicTransparency(model, progress)
    for part, origTrans in pairs(originalTransparencies) do
        if part and part.Parent then
            if origTrans >= 0.99 then part.Transparency = 1
            else part.Transparency = math.clamp(1 - (1 - origTrans) * progress, origTrans, 1) end
        end
    end
end

local function updateFadeOutTransparency(model, progress)
    for part, origTrans in pairs(originalTransparencies) do
        if part and part.Parent then
            if origTrans >= 0.99 then part.Transparency = 1
            else part.Transparency = math.clamp(origTrans + (1 - origTrans) * progress, origTrans, 1) end
        end
    end
end

--------------------------------------------------------------------------------
-- 5. SPAWN & REMOVE TRỰC THĂNG
--------------------------------------------------------------------------------
local function spawnHelicopter()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart

    local success, objects = pcall(function() return game:GetObjects("rbxassetid://" .. HELICOPTER_MODEL_ID) end)
    if not success or not objects or #objects == 0 then return end

    local model = objects[1]
    if not model:IsA("Model") then
        local wrapper = Instance.new("Model")
        model.Parent = wrapper
        model = wrapper
    end

    currentModel = model
    cacheAndSetupModel(model)
    for part, _ in pairs(originalTransparencies) do part.Transparency = 1 end

    local targetCFrame = rootPart.CFrame * CFrame.new(0, TARGET_HEIGHT, -DISTANCE_FRONT)
    local startCFrame = targetCFrame * CFrame.new(0, START_HEIGHT, 0)

    model:PivotTo(startCFrame)
    model.Parent = Workspace
    setupHelicopterSound(model)

    local cframeValue = Instance.new("CFrameValue")
    cframeValue.Value = startCFrame
    cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
        if model and model.Parent then model:PivotTo(cframeValue.Value) end
    end)

    local duration = 3.5
    local moveTween = TweenService:Create(cframeValue, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = targetCFrame})
    moveTween:Play()

    task.spawn(function()
        local startTime = tick()
        while isHelicopterActive and currentModel == model do
            local progress = math.clamp((tick() - startTime) / duration, 0, 1)
            updateDynamicTransparency(model, progress)
            if progress >= 1 then break end
            task.wait()
        end
        if currentModel == model then updateDynamicTransparency(model, 1) end
    end)

    moveTween.Completed:Connect(function()
        cframeValue:Destroy()
        if isHelicopterActive and currentModel == model then
            if isFollowing then startFollowAnimation(model)
            else startHoverAnimation(model, targetCFrame) end
        end
    end)
end

local function removeHelicopter()
    if hoverConnection then hoverConnection:Disconnect() hoverConnection = nil end
    if followConnection then followConnection:Disconnect() followConnection = nil end
    if soundConnection then soundConnection:Disconnect() soundConnection = nil end

    local model = currentModel
    currentModel = nil
    isFollowing = false
    loadedMissiles = {nil, nil, nil} 

    if not model or not model.Parent then return end

    local startCFrame = model:GetPivot()
    local targetCFrame = startCFrame * CFrame.new(0, START_HEIGHT, 0)

    local cframeValue = Instance.new("CFrameValue")
    cframeValue.Value = startCFrame
    cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
        if model and model.Parent then model:PivotTo(cframeValue.Value) end
    end)

    local duration = 2
    local moveTween = TweenService:Create(cframeValue, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Value = targetCFrame})
    moveTween:Play()

    task.spawn(function()
        local startTime = tick()
        while true do
            local progress = math.clamp((tick() - startTime) / duration, 0, 1)
            updateFadeOutTransparency(model, progress)
            if progress >= 1 then break end
            task.wait()
        end
    end)

    moveTween.Completed:Connect(function()
        cframeValue:Destroy()
        model:Destroy()
    end)
end

--------------------------------------------------------------------------------
-- 6. CẬP NHẬT TRẠNG THÁI BỘ ĐÀM
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local hasBomb = (readyMissile and readyMissile.Parent) or (pendingMissile and pendingMissile.Parent)
    local heliStatusStr = isHelicopterActive and "ACTIVE" or "OFFLINE"
    
    local filledCount = 0
    for _, m in ipairs(loadedMissiles) do
        if m and m.Parent then filledCount = filledCount + 1 end
    end

    local slot1Str = loadedMissiles[1] and loadedMissiles[1].Parent and "[ LOADED ]" or "[ EMPTY ]"
    local slot2Str = loadedMissiles[2] and loadedMissiles[2].Parent and "[ LOADED ]" or "[ EMPTY ]"
    local slot3Str = loadedMissiles[3] and loadedMissiles[3].Parent and "[ LOADED ]" or "[ EMPTY ]"

    StatusDisplay.Text = string.format("SYSTEM: ONLINE\nHELI: %s\nSLOT 1: %s\nSLOT 2: %s\nSLOT 3: %s", heliStatusStr, slot1Str, slot2Str, slot3Str)
    
    if not isHelicopterActive then
        LoadMissileBtn.TextColor3 = COLOR_TEXT_MUTED
        LoadMissileBtn.Text = "HÃY BẬT TRỰC THĂNG"
    elseif filledCount >= 3 then
        LoadMissileBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
        LoadMissileBtn.Text = "ĐÃ ĐẦY 3/3 QUẢ BOM!"
    elseif hasBomb then
        LoadMissileBtn.TextColor3 = COLOR_ACCENT
        LoadMissileBtn.Text = string.format("NẠP ĐẠN (%d/3)", filledCount)
    else
        LoadMissileBtn.TextColor3 = COLOR_TEXT_MUTED
        LoadMissileBtn.Text = string.format("CHƯA CẦM BOMB (%d/3)", filledCount)
    end
end)

--------------------------------------------------------------------------------
-- 7. KHAI HỎA TÊN LỬA TỚI MỤC TIÊU[cite: 1]
--------------------------------------------------------------------------------
local function launchMissileAtTarget(targetPlayer)
    local targetSlotIndex = nil
    local selectedBomb = nil
    for i = 1, 3 do
        if loadedMissiles[i] and loadedMissiles[i].Parent then
            targetSlotIndex = i
            selectedBomb = loadedMissiles[i]
            break
        end
    end

    if not selectedBomb then return end

    animateOut(WalkieFrame)
    loadedMissiles[targetSlotIndex] = nil

    local heliPivot = currentModel and currentModel:GetPivot() or (player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 30, -20))
    local startCF = heliPivot * CFrame.new(0, 4, -10)
    selectedBomb:PivotTo(startCF)

    for _, part in ipairs(selectedBomb:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        end
    end

    task.spawn(function()
        local bRoot = selectedBomb.PrimaryPart or selectedBomb:FindFirstChildWhichIsA("BasePart")
        if not bRoot then return end

        local targetCF = CFrame.new(Vector3.new(103.03, 606.51, 38.35))
        local cfVal = Instance.new("CFrameValue")
        cfVal.Value = startCF
        cfVal:GetPropertyChangedSignal("Value"):Connect(function()
            if selectedBomb and selectedBomb.Parent then selectedBomb:PivotTo(cfVal.Value) end
        end)

        local tween = TweenService:Create(cfVal, TweenInfo.new(3.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = targetCF})
        tween:Play()
        tween.Completed:Wait()
        cfVal:Destroy()

        for _, part in ipairs(selectedBomb:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = false end
        end

        isControlling = false
        HUDGui.Enabled = false

        if flySound then
            flySound.Volume = 0.8
            flySound:Play()
        end

        local cleanupESP = nil
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            cleanupESP = createMissileESP(bRoot, targetPlayer.Character.HumanoidRootPart)
        end

        local connection
        local speed = 180

        connection = RunService.RenderStepped:Connect(function(dt)
            if not selectedBomb or not selectedBomb.Parent or not bRoot or not targetPlayer.Character then
                if connection then connection:Disconnect() end
                if cleanupESP then cleanupESP() end
                if flySound then flySound:Stop() end
                if crashSound then crashSound:Play() end
                return
            end

            local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not tRoot then
                if connection then connection:Disconnect() end
                if cleanupESP then cleanupESP() end
                if flySound then flySound:Stop() end
                return
            end

            local currentPos = bRoot.Position
            local targetPos = tRoot.Position
            local direction = (targetPos - currentPos).Unit

            if (targetPos - currentPos).Magnitude < 6 then
                if connection then connection:Disconnect() end
                if cleanupESP then cleanupESP() end
                if flySound then flySound:Stop() end
                if crashSound then crashSound:Play() end
                
                processSpecialExplosionEffect(currentPos)

                selectedBomb:Destroy()
                return
            end

            local newPos = currentPos + (direction * speed * dt)
            selectedBomb:PivotTo(CFrame.new(newPos, targetPos) * CFrame.Angles(-math.pi / 2, 0, 0))
            bRoot.AssemblyLinearVelocity = direction * speed
        end)
    end)
end

--------------------------------------------------------------------------------
-- 8. SỰ KIỆN NÚT BẤM BỘ ĐÀM
--------------------------------------------------------------------------------
toggleWalkieBtn.MouseButton1Click:Connect(function()
    if WalkieFrame.Visible then animateOut(WalkieFrame)
    else animateIn(WalkieFrame) end
end)

CloseWalkieBtn.MouseButton1Click:Connect(function()
    animateOut(WalkieFrame)
end)

ToggleHeliBtn.MouseButton1Click:Connect(function()
    isHelicopterActive = not isHelicopterActive
    if isHelicopterActive then
        ToggleHeliBtn.Text = "SPAWN TRỰC THĂNG: BẬT"
        ToggleHeliBtn.TextColor3 = COLOR_ACCENT
        spawnHelicopter()
    else
        ToggleHeliBtn.Text = "SPAWN TRỰC THĂNG: TẮT"
        ToggleHeliBtn.TextColor3 = COLOR_DANGER
        removeHelicopter()
    end
end)

FollowBtn.MouseButton1Click:Connect(function()
    if not isHelicopterActive or not currentModel then return end

    isFollowing = not isFollowing
    if isFollowing then
        FollowBtn.Text = "FOLLOW ME: BẬT"
        FollowBtn.TextColor3 = COLOR_ACCENT
        startFollowAnimation(currentModel)
    else
        FollowBtn.Text = "FOLLOW ME: TẮT"
        FollowBtn.TextColor3 = COLOR_ACCENT_DIM
        if followConnection then followConnection:Disconnect() end
        local baseCFrame = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) and (player.Character.HumanoidRootPart.CFrame * CFrame.new(0, TARGET_HEIGHT, -DISTANCE_FRONT)) or currentModel:GetPivot()
        startHoverAnimation(currentModel, baseCFrame)
    end
end)

FireMissileBtn.MouseButton1Click:Connect(function()
    if not isHelicopterActive or not currentModel then return end
    local hasLoaded = false
    for _, m in ipairs(loadedMissiles) do
        if m and m.Parent then hasLoaded = true break end
    end
    if not hasLoaded then return end

    refreshPlayerList(function(selectedPlayer)
        launchMissileAtTarget(selectedPlayer)
    end)
    TargetGui.Enabled = true
    animateIn(TargetFrame)
end)

LoadMissileBtn.MouseButton1Click:Connect(function()
    if not isHelicopterActive or not currentModel then return end

    local emptySlotIndex = nil
    for i = 1, 3 do
        if not loadedMissiles[i] or not loadedMissiles[i].Parent then
            emptySlotIndex = i
            break
        end
    end
    if not emptySlotIndex then return end

    local targetBomb = readyMissile or pendingMissile
    if targetBomb and targetBomb.Parent then
        local bombRoot = targetBomb.PrimaryPart or targetBomb:FindFirstChildWhichIsA("BasePart")
        if not bombRoot then return end

        local startCFrame = bombRoot.CFrame
        local offsets = { CFrame.new(-10, 4, 0), CFrame.new(0, 4, 0), CFrame.new(10, 4, 0) }
        local baseCFrame = currentModel.PrimaryPart and currentModel.PrimaryPart.CFrame or currentModel:GetPivot()
        local finalTargetCFrame = baseCFrame * offsets[emptySlotIndex]

        loadedMissiles[emptySlotIndex] = targetBomb

        for _, part in ipairs(targetBomb:GetDescendants()) do
            if part:IsA("BasePart") then
                originalColors[part] = part.Color
                part.Color = Color3.fromRGB(255, 255, 255)
            end
        end

        local cframeValue = Instance.new("CFrameValue")
        cframeValue.Value = startCFrame
        cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
            if targetBomb and targetBomb.Parent then targetBomb:PivotTo(cframeValue.Value) end
        end)

        local moveTween = TweenService:Create(cframeValue, TweenInfo.new(3.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = finalTargetCFrame})
        moveTween:Play()

        moveTween.Completed:Connect(function()
            cframeValue:Destroy()
            for _, part in ipairs(targetBomb:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = false
                end
            end
        end)
    end
end)
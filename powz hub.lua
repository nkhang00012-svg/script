local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- NHẮM VÀO SPAWNLOCATION: ĐỔI DECAL, ẨN NỀN & XOAY TẠI CHỖ
-- ==========================================
task.spawn(function()
    pcall(function()
        local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")

        if not spawnLocation then
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("SpawnLocation") then
                    spawnLocation = desc
                    break
                end
            end
        end

        if spawnLocation then
            -- Cố định vật thể để game không kéo đi
            spawnLocation.Anchored = true
            -- Ẩn nền SpawnLocation (Transparency = 1)
            spawnLocation.Transparency = 1

            -- Tìm hoặc tạo Decal bên trong SpawnLocation
            local targetDecal = spawnLocation:FindFirstChildOfClass("Decal")
            if not targetDecal then
                targetDecal = Instance.new("Decal")
                targetDecal.Parent = spawnLocation
            end
            
            -- Gán ID decal & giữ hiện rõ nét (Transparency = 0)
            targetDecal.Texture = "rbxassetid://130631112307885"
            targetDecal.Transparency = 0
            
            -- Xoay SpawnLocation tại chỗ chuẩn xác
            local rotationSpeed = 20 -- Tốc độ xoay (độ/giây)
            local currentAngle = 0
            
            RunService.Heartbeat:Connect(function(dt)
                if spawnLocation and spawnLocation.Parent then
                    currentAngle = (currentAngle + rotationSpeed * dt) % 360
                    spawnLocation.CFrame = CFrame.new(spawnLocation.Position) * CFrame.Angles(0, math.rad(currentAngle), 0)
                end
            end)
            
            print("Đã tìm thấy SpawnLocation và kích hoạt xoay thành công!")
        else
            warn("Không tìm thấy SpawnLocation nào trong Workspace!")
        end
    end)
end)

-- ==========================================
-- DỌN SẠCH SẼ TẤT CẢ CÁC UI CŨ ĐÃ TỒN TẠI TRƯỚC ĐÓ
-- ==========================================
local function cleanupOldUIs()
    pcall(function()
        local targetParent = (gethui and gethui()) or CoreGui
        for _, child in ipairs(targetParent:GetChildren()) do
            if child.Name == "POWZ_HUB_TOYMODS" or child.Name == "InfiniteRotatingCrosshair" then
                child:Destroy()
            end
        end
        for _, child in ipairs(PlayerGui:GetChildren()) do
            if child.Name == "POWZ_HUB_TOYMODS" or child.Name == "InfiniteRotatingCrosshair" then
                child:Destroy()
            end
        end
    end)
end
cleanupOldUIs()


-- ==========================================
-- PHẦN 1: TÂM CROSSHAIR XOAY VĨNH VIỄN
-- ==========================================
local CROSSHAIR_DECAL_ID = "90099090341547"
local CROSSHAIR_SIZE = 47
local CROSSHAIR_ROTATION_SPEED = 200

task.spawn(function()
    while true do
        pcall(function()
            local oldGui = PlayerGui:FindFirstChild("Crosshairs")
            if oldGui and oldGui.Enabled then
                oldGui.Enabled = false
            end
        end)
        task.wait(1)
    end
end)

local targetParent = (gethui and gethui()) or CoreGui
local CrosshairScreenGui = Instance.new("ScreenGui")
CrosshairScreenGui.Name = "InfiniteRotatingCrosshair"
CrosshairScreenGui.IgnoreGuiInset = true
CrosshairScreenGui.ResetOnSpawn = false
CrosshairScreenGui.Parent = targetParent

local Crosshair = Instance.new("ImageLabel")
Crosshair.Parent = CrosshairScreenGui
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
Crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
Crosshair.Size = UDim2.new(0, CROSSHAIR_SIZE, 0, CROSSHAIR_SIZE)
Crosshair.BackgroundTransparency = 1
Crosshair.Image = "rbxassetid://" .. tostring(CROSSHAIR_DECAL_ID)
Crosshair.ScaleType = Enum.ScaleType.Fit

local crosshairRotation = 0
RunService.RenderStepped:Connect(function(dt)
    if Crosshair and Crosshair.Parent then
        crosshairRotation = (crosshairRotation + CROSSHAIR_ROTATION_SPEED * dt) % 360
        Crosshair.Rotation = crosshairRotation
    end
end)


-- ==========================================
-- PHẦN 2: MOD GIAO DIỆN COINS (ĐÃ GỠ BỎ VIỀN LED RGB ĐỂ GIẢM LAG)
-- ==========================================
local OLD_DECAL_ID = "8659337867"
local NEW_DECAL_ID = "90034667735355"
local COIN_ROTATION_SPEED = 200

local function applyCoinModifications()
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            local currentImage = tostring(obj.Image)
            if string.find(currentImage, OLD_DECAL_ID) or obj.Name == "CoinImage" then
                obj.BackgroundTransparency = 1
                obj.ScaleType = Enum.ScaleType.Fit
                obj.Image = "rbxassetid://" .. tostring(NEW_DECAL_ID)

                if not obj:GetAttribute("IsRotating") then
                    obj:SetAttribute("IsRotating", true)
                    local currentCoinRot = 0
                    RunService.RenderStepped:Connect(function(dt)
                        if obj and obj.Parent then
                            currentCoinRot = (currentCoinRot + COIN_ROTATION_SPEED * dt) % 360
                            obj.Rotation = currentCoinRot
                        end
                    end)
                end
            end
        end

        -- Giữ lại màu chữ và viền đen cơ bản cho text coins (nếu có)
        if (obj.Name == "Blank" or obj.Name == "Coins") and obj:IsA("TextLabel") then
            obj.TextColor3 = Color3.fromRGB(255, 255, 255)
            if not obj:FindFirstChild("TextBlackStroke") then
                local tStroke = Instance.new("UIStroke")
                tStroke.Name = "TextBlackStroke"
                tStroke.Thickness = 2
                tStroke.Color = Color3.fromRGB(0, 0, 0)
                tStroke.Parent = obj
            end
        end
    end
end

applyCoinModifications()
task.spawn(function()
    while true do
        task.wait(1)
        pcall(applyCoinModifications)
    end
end)


-- ==========================================
-- PHẦN 3: GIAO DIỆN CHÍNH POWZ HUB TOYMODS
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POWZ_HUB_TOYMODS"
screenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    screenGui.Parent = targetParent
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 300)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "POWZ HUB TOYMODS"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeButton"
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(1, 0)
minCorner.Parent = minimizeBtn

local floatBtn = Instance.new("TextButton")
floatBtn.Name = "FloatButton"
floatBtn.Size = UDim2.new(0, 50, 0, 50)
floatBtn.Position = UDim2.new(0.85, 0, 0.5, -25)
floatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
floatBtn.BorderSizePixel = 0
floatBtn.Text = "POWZ"
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.TextSize = 11
floatBtn.Font = Enum.Font.SourceSansBold
floatBtn.Visible = false
floatBtn.Active = true
floatBtn.Draggable = true
floatBtn.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatBtn

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(80, 80, 80)
floatStroke.Thickness = 2
floatStroke.Parent = floatBtn

-- ==================== ANIMATION THU NHỎ / MỞ RỘNG UI ====================
local animTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

minimizeBtn.MouseButton1Click:Connect(function()
    local shrinkTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = mainFrame.Position + UDim2.new(0, 100, 0, 150)
    })
    shrinkTween:Play()
    shrinkTween.Completed:Wait()
    mainFrame.Visible = false
    mainFrame.Size = UDim2.new(0, 200, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)

    floatBtn.Size = UDim2.new(0, 0, 0, 0)
    floatBtn.Visible = true
    TweenService:Create(floatBtn, animTweenInfo, {Size = UDim2.new(0, 50, 0, 50)}):Play()
end)

floatBtn.MouseButton1Click:Connect(function()
    local popTween = TweenService:Create(floatBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    })
    popTween:Play()
    popTween.Completed:Wait()
    floatBtn.Visible = false
    floatBtn.Size = UDim2.new(0, 50, 0, 50)

    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Visible = true
    TweenService:Create(mainFrame, animTweenInfo, {
        Size = UDim2.new(0, 200, 0, 300),
        Position = UDim2.new(0.5, -100, 0.5, -150)
    }):Play()
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -12, 1, -45)
scrollFrame.Position = UDim2.new(0, 6, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = scrollFrame

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

local function createCategoryHeader(name, order)
    local header = Instance.new("TextLabel")
    header.Name = "Header_" .. name
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundTransparency = 1
    header.Text = "------------ " .. name .. " ------------"
    header.TextColor3 = Color3.fromRGB(150, 150, 150)
    header.TextSize = 12
    header.Font = Enum.Font.SourceSansBold
    header.LayoutOrder = order
    header.Parent = scrollFrame
end

local function createButton(btnText, order, onClickCallback)
    local btn = Instance.new("TextButton")
    btn.Name = btnText .. "Btn"
    btn.Size = UDim2.new(0.92, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.Text = btnText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextWrapped = true
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = scrollFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local normalColor = Color3.fromRGB(50, 50, 50)
    local hoverColor = Color3.fromRGB(75, 75, 75)
    local clickColor = Color3.fromRGB(35, 35, 35)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, tweenInfo, {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, tweenInfo, {BackgroundColor3 = normalColor}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, tweenInfo, {BackgroundColor3 = clickColor}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, tweenInfo, {BackgroundColor3 = hoverColor}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        task.spawn(onClickCallback)
    end)

    return btn
end

local function createSubNote(noteText, order)
    local note = Instance.new("TextLabel")
    note.Name = "NoteLabel"
    note.Size = UDim2.new(0.92, 0, 0, 16)
    note.BackgroundTransparency = 1
    note.Text = noteText
    note.TextColor3 = Color3.fromRGB(170, 170, 170)
    note.TextSize = 10
    note.Font = Enum.Font.SourceSansItalic
    note.TextWrapped = true
    note.LayoutOrder = order
    note.Parent = scrollFrame
end

-- ==================== CẤU TRÚC DANH MỤC ====================

createCategoryHeader("MAIN", 1)

createButton("powz control", 2, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/bonbonaimbot/refs/heads/main/powzcontrol.lua"))()
end)

createButton("Fpv drone (free)", 3, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/bonbonhub/refs/heads/main/fpvdrone.lua"))()
end)

createSubNote("nếu muốn fpv drone vip hãy xin owner ;)", 4)

createButton("powz ftap script ( free plan & no vip)", 5, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/script/refs/heads/main/powz.lua"))()
end)

createCategoryHeader("MISC", 6)

createButton("fov 120", 7, function()
    local workspace = game:GetService("Workspace")
    local camera = workspace.CurrentCamera

    if camera then
        camera.FieldOfView = 120
    end

    camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if camera.FieldOfView ~= 120 then
            camera.FieldOfView = 120
        end
    end)
end)

createButton("góc nhìn thứ 3", 8, function()
    local player = game:GetService("Players").LocalPlayer
    if player then
        player.CameraMaxZoomDistance = 99999
        player.CameraMinZoomDistance = 0.5
        player.CameraMode = Enum.CameraMode.Classic
         
        task.spawn(function()
            while true do
                pcall(function()
                    local character = player.Character
                    if character then
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.LocalTransparencyModifier = 0
                            end
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    end
end)

createButton("aimbot", 9, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/bonbonhub/refs/heads/main/rageaimbot.lua"))()
end)

createCategoryHeader("VISUAL", 10)

createButton("Helicopter", 11, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/script/refs/heads/main/gemini-code-1792870828601.lua"))()
end)

createButton("winter sky", 12, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/script/refs/heads/main/Script%20%2314.lua"))()
end)

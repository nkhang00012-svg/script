local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Xoá UI cũ nếu đã tồn tại
local targetParent = gethui and gethui() or CoreGui
if targetParent:FindFirstChild("POWZ_HUB_TOYMODS") then
    targetParent:FindFirstChild("POWZ_HUB_TOYMODS"):Destroy()
end

-- Tạo ScreenGui mới
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POWZ_HUB_TOYMODS"
screenGui.ResetOnSpawn = false

-- Đưa UI vào CoreGui hoặc gethui
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    screenGui.Parent = targetParent
end

-- Khung chính (200 x 300)
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

-- Tiêu đề POWZ HUB TOYMODS
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

-- Nút Thu Nhỏ (-)
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
minCorner.CornerRadius = UDim.new(1, 0) -- Bo tròn thành hình tròn
minCorner.Parent = minimizeBtn

-- Tạo Cục Tròn (Floating Ball) để mở lại UI khi thu nhỏ
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
floatBtn.Draggable = true -- Có thể di chuyển cục tròn
floatBtn.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatBtn

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(80, 80, 80)
floatStroke.Thickness = 2
floatStroke.Parent = floatBtn

-- Sự kiện thu nhỏ / mở rộng UI
minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
    floatBtn.Visible = false
    mainFrame.Visible = true
end)

-- Khung cuộn chứa nội dung (ScrollingFrame)
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

-- Cập nhật kích thước cuộn tự động
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- Hàm tạo tiêu đề phân cách
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

-- Hàm tạo Nút bấm bo góc + Animation
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

    -- Hiệu ứng Hover / Click
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

-- Hàm tạo Ghi chú nhỏ bên dưới nút
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

-- 1. MỤC MAIN
createCategoryHeader("MAIN", 1)

-- Ô: Powz Control
createButton("powz control", 2, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/bonbonaimbot/refs/heads/main/powzcontrol.lua"))()
end)

-- Ô: Fpv drone (free)
createButton("Fpv drone (free)", 3, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/bonbonhub/refs/heads/main/fpvdrone.lua"))()
end)

-- Ghi chú cho Fpv drone (free)
createSubNote("nếu muốn fpv drone vip hãy xin owner ;)", 4)

-- Ô: Powz FTAP Script (Free Plan & No VIP)
createButton("powz ftap script ( free plan & no vip)", 5, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/script/refs/heads/main/powz.lua"))()
end)

-- 2. MỤC MISC
createCategoryHeader("MISC", 6)

-- Ô: FOV 120
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

-- Ô: Góc nhìn thứ 3
createButton("góc nhìn thứ 3", 8, function()
    local player = game:GetService("Players").LocalPlayer
    if player then
        player.CameraMaxZoomDistance = 99999
        player.CameraMode = Enum.CameraMode.Classic
    end
end)

-- Ô: Aimbot
createButton("aimbot", 9, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nkhang00012-svg/bonbonhub/refs/heads/main/rageaimbot.lua"))()
end)

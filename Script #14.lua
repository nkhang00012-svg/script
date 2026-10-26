-- Tải thư viện UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Auto PVP (Remote Event) - Red vs Blue", "DarkTheme")

-- Services & LocalPlayer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Cấu hình
local CONFIG = {
    Enabled = false,
    TeleportDistance = 1.5, -- Khoảng cách TP ra sau lưng (studs)
    CheckInterval = 0.1,    -- Tốc độ cập nhật Teleport
    FastAttack = true       -- Spam RemoteEvent siêu nhanh
}

local currentTarget = nil

-- Tìm RemoteEvent Sword trong ReplicatedStorage -> Combat -> Sword
local function getSwordRemote()
    local combatFolder = ReplicatedStorage:FindFirstChild("Combat")
    if combatFolder then
        return combatFolder:FindFirstChild("Sword")
    end
    return nil
end

local swordRemote = getSwordRemote()

-- Hàm nhận diện team đối địch (Bỏ qua team Out)
local function getEnemyTeamName()
    local myTeam = LocalPlayer.Team
    if not myTeam then return nil end
    
    local teamName = myTeam.Name:lower()
    if teamName:find("red") then
        return "blue"
    elseif teamName:find("blue") then
        return "red"
    end
    return nil -- Đang ở team Out hoặc Neutral
end

-- Tìm kẻ địch gần nhất thuộc team đối địch
local function findTarget(enemyColor)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = character.HumanoidRootPart.Position
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team then
            local pTeamName = player.Team.Name:lower()
            if pTeamName:find(enemyColor) and not pTeamName:find("out") then
                local pChar = player.Character
                if pChar and pChar:FindFirstChild("HumanoidRootPart") then
                    local humanoid = pChar:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local dist = (myPos - pChar.HumanoidRootPart.Position).Magnitude
                        if dist < shortestDistance then
                            shortestDistance = dist
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- Hàm cầm Tool 1 nếu cần
local function equipFirstTool()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    
    if not character or not backpack then return end
    if character:FindFirstChildOfClass("Tool") then return end
    
    local firstTool = backpack:FindFirstChildOfClass("Tool")
    if firstTool then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(firstTool)
        end
    end
end

-- Vòng lặp Teleport ra sau lưng
task.spawn(function()
    while true do
        task.wait(CONFIG.CheckInterval)
        
        if CONFIG.Enabled then
            local enemyColor = getEnemyTeamName()
            if enemyColor then
                currentTarget = findTarget(enemyColor)
                
                if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
                    local myChar = LocalPlayer.Character
                    local targetChar = currentTarget.Character
                    
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        local myRoot = myChar.HumanoidRootPart
                        local targetRoot = targetChar.HumanoidRootPart
                        
                        equipFirstTool()
                        
                        -- TP ra sau lưng đối thủ
                        local targetCFrame = targetRoot.CFrame
                        local backPosition = targetCFrame * CFrame.new(0, 0, CONFIG.TeleportDistance)
                        myRoot.CFrame = CFrame.new(backPosition.Position, targetRoot.Position)
                    end
                end
            else
                currentTarget = nil
            end
        end
    end
end)

-- Vòng lặp Spam RemoteEvent Đánh Liên Tục (Không Cooldown)
task.spawn(function()
    while true do
        task.wait() -- Chạy theo khung hình (gần như 0s delay)
        if CONFIG.Enabled and currentTarget then
            -- Nếu không tìm thấy bằng đường dẫn trực tiếp, thử tìm lại
            if not swordRemote then
                swordRemote = getSwordRemote()
            end
            
            if swordRemote then
                -- Bắn RemoteEvent liên tục lên Server
                swordRemote:FireServer()
            end
        end
    end
end)

-- Giao diện UI
local Tab = Window:NewTab("Auto Fast Attack")
local Section = Tab:NewSection("Remote Event Spam")

Section:NewToggle("Bật Auto TP & Fast Attack", "Spam RemoteEvent Sword không delay", function(state)
    CONFIG.Enabled = state
end)

Section:NewSlider("Khoảng cách sau lưng (Studs)", "Khoảng cách đứng sau lưng target", 5, 1, function(s)
    CONFIG.TeleportDistance = s
end)

local SettingsTab = Window:NewTab("Cài Đặt")
local SettingsSection = SettingsTab:NewSection("Giao Diện")

SettingsSection:NewKeybind("Phím Ẩn/Hiện Menu", "Nhấn phím để ẩn/hiện UI", Enum.KeyCode.RightControl, function()
    Library:ToggleUI()
end)
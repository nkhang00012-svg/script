local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

--------------------------------------------------------------------------------
-- 1. XỬ LÝ SKY & ÁNH SÁNG CHUẨN ROBLOX STUDIO MỚI
--------------------------------------------------------------------------------
local function setupCleanWinterLighting()
	-- Xóa toàn bộ Sky / Atmosphere / Fog cũ trong Lighting
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("Fog") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- Tạo đối tượng Sky mới
	local sky = Instance.new("Sky")
	sky.Name = "CustomWinterSky"
	
	-- Gán đúng định dạng 6 mặt (Sử dụng bộ ID Skybox chuẩn không gian của Roblox)
	sky.SkyboxBk = "rbxassetid://4495864450"
	sky.SkyboxDn = "rbxassetid://4495864887"
	sky.SkyboxFt = "rbxassetid://4495865458"
	sky.SkyboxLf = "rbxassetid://4495866035"
	sky.SkyboxRt = "rbxassetid://4495866584"
	sky.SkyboxUp = "rbxassetid://4495867486"
	
	-- Đồng thời gán luôn cho các thuộc tính Content mới (nếu Studio của bạn yêu cầu)
	pcall(function()
		sky.SkyboxBackContent = "rbxassetid://4495864450"
		sky.SkyboxDownContent = "rbxassetid://4495864887"
		sky.SkyboxFrontContent = "rbxassetid://4495865458"
		sky.SkyboxLeftContent = "rbxassetid://4495866035"
		sky.SkyboxRightContent = "rbxassetid://4495866584"
		sky.SkyboxUpContent = "rbxassetid://4495867486"
	end)
	
	sky.Parent = Lighting

	-- Chỉnh ánh sáng tông lạnh trong trẻo
	Lighting.Ambient = Color3.fromRGB(160, 175, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(200, 210, 220)
	Lighting.ColorShift_Top = Color3.fromRGB(230, 242, 255)
	Lighting.Brightness = 1.3
	Lighting.ClockTime = 12

	Lighting.FogEnd = 100000 
	Lighting.FogStart = 0
	
	-- Chống game tự ý chèn Sky khác vào
	Lighting.ChildAdded:Connect(function(child)
		if child:IsA("Sky") and child ~= sky then
			child:Destroy()
		end
	end)
end

--------------------------------------------------------------------------------
-- 2. HÀM LỌC PART (GIỮ NGUYÊN CODE CỦA BẠN)
--------------------------------------------------------------------------------
local function shouldProcessPart(part)
	if not part:IsA("BasePart") or part:IsA("Terrain") then 
		return false 
	end
	if not part.Anchored then 
		return false 
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return false
	end
	return true
end

--------------------------------------------------------------------------------
-- 3. CHUYỂN ĐỔI MÀU SẮC (XÁM - TRẮNG - ĐEN - XANH BĂNG SIÊU NHẠT)
--------------------------------------------------------------------------------
local function applyStrictWinterPalette(part)
	if not shouldProcessPart(part) then return end

	local color = part.Color
	local _, _, v = color:ToHSV()

	if v < 0.15 then
		part.Color = Color3.fromRGB(20, 25, 30)
	elseif v > 0.75 then
		part.Color = Color3.fromRGB(245, 248, 252)
	else
		local hash = (math.floor(part.Position.X) + math.floor(part.Position.Y) + math.floor(part.Position.Z)) % 2
		if hash == 1 then
			part.Color = Color3.fromRGB(215, 230, 245)
		else
			local grayVal = math.clamp(math.floor(v * 200), 60, 170)
			part.Color = Color3.fromRGB(grayVal, grayVal + 5, grayVal + 12)
		end
	end

	if part.Material == Enum.Material.Ice or part.Material == Enum.Material.Glass then
		part.Reflectance = 0.3
	end
end

--------------------------------------------------------------------------------
-- KÍCH HOẠT
--------------------------------------------------------------------------------
print("[WinterFilter] Đang khởi chạy hệ thống...")

setupCleanWinterLighting()

local count = 0
for _, desc in ipairs(Workspace:GetDescendants()) do
	if desc:IsA("BasePart") then
		pcall(function()
			if shouldProcessPart(desc) then
				applyStrictWinterPalette(desc)
				count += 1
			end
		end)
	end
end

Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("BasePart") then
		task.wait(0.05)
		pcall(function()
			applyStrictWinterPalette(desc)
		end)
	end
end)

print("[WinterFilter] Hoàn tất! Đã cập nhật Sky chuẩn và đổi màu thành công cho " .. count .. " part.")

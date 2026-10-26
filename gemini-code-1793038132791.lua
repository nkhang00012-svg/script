-- Local Script: Superman Skin Ultimate VIP v11.0 (PC Edition: Bấm F Bắn Laser + Giữ G Boost + Bay Nằm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function applyUltimateSuperman()
    local realChar = LocalPlayer.Character
    if not realChar then return end
    
    local realRoot = realChar:WaitForChild("HumanoidRootPart", 5)
    local realHumanoid = realChar:WaitForChild("Humanoid", 5)
    if not realRoot or not realHumanoid then return end

    -- 1. Load Model Superman
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://11280832210")
    end)

    if not success or not objects or #objects == 0 then
        warn("Không thể load Model ID 11280832210!")
        return
    end

    local visualModel = objects[1]
    visualModel.Name = "UltimateSuperman_" .. LocalPlayer.Name

    local visualHumanoid = visualModel:FindFirstChildOfClass("Humanoid")
    local visualRoot = visualModel:FindFirstChild("HumanoidRootPart") or visualModel.PrimaryPart or visualModel:FindFirstChildWhichIsA("BasePart")
    if not visualRoot then return end

    -- 2. Tắt va chạm vật lý model hiển thị
    for _, part in ipairs(visualModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Anchored = false
            part.Massless = true
        end
    end

    if visualHumanoid then
        pcall(function()
            visualHumanoid.EvaluateStateMachine = false
            visualHumanoid.RequiresNeck = false
        end)
    end

    -- 3. CĂN CHỈNH KHỚP CỔ
    local head = visualModel:FindFirstChild("Head", true)
    local torso = visualModel:FindFirstChild("UpperTorso", true) or visualModel:FindFirstChild("Torso", true) or visualRoot
    local neckMotor = nil

    if head and torso then
        for _, obj in ipairs(visualModel:GetDescendants()) do
            if obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") then
                if obj.Part1 == head or obj.Part0 == head then
                    obj:Destroy()
                end
            end
        end
        head.Anchored = false

        neckMotor = Instance.new("Motor6D")
        neckMotor.Name = "CustomNeck"
        neckMotor.Part0 = torso
        neckMotor.Part1 = head
        neckMotor.C0 = CFrame.new(0, (torso.Size.Y / 2) - 0.05, 0)
        neckMotor.C1 = CFrame.new(0, -head.Size.Y / 2.5, 0)
        neckMotor.Parent = torso
    end

    -- 4. Ẩn Player gốc hoàn toàn
    for _, part in ipairs(realChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.LocalTransparencyModifier = 1
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end

    -- 5. Spawn Model và Hàn dính RootPart
    visualModel:PivotTo(realRoot.CFrame)
    visualModel.Parent = Workspace

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = realRoot
    weld.Part1 = visualRoot
    weld.Parent = visualRoot

    -- 6. TẠO GIAO DIỆN UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UltimateSupermanPCGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Nút Laser
    local laserToggleBtn = Instance.new("ImageButton")
    laserToggleBtn.Size = UDim2.new(0, 48, 0, 48)
    laserToggleBtn.Position = UDim2.new(0, 15, 0, 55)
    laserToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    laserToggleBtn.BackgroundTransparency = 0.2
    laserToggleBtn.BorderSizePixel = 0
    laserToggleBtn.Parent = screenGui

    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 10)
    btnCorner1.Parent = laserToggleBtn

    local btnStroke1 = Instance.new("UIStroke")
    btnStroke1.Color = Color3.fromRGB(80, 80, 90)
    btnStroke1.Thickness = 1.5
    btnStroke1.Parent = laserToggleBtn

    local eyeIcon = Instance.new("ImageLabel")
    eyeIcon.Size = UDim2.new(0, 32, 0, 32)
    eyeIcon.Position = UDim2.new(0.5, -16, 0.5, -16)
    eyeIcon.BackgroundTransparency = 1
    eyeIcon.Image = "rbxassetid://10723376114"
    eyeIcon.ImageColor3 = Color3.fromRGB(150, 40, 40)
    eyeIcon.Parent = laserToggleBtn

    local statusIndicator1 = Instance.new("Frame")
    statusIndicator1.Size = UDim2.new(0, 5, 0, 28)
    statusIndicator1.Position = UDim2.new(1, 4, 0.5, -14)
    statusIndicator1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    statusIndicator1.BorderSizePixel = 0
    statusIndicator1.Parent = laserToggleBtn

    local ledCorner1 = Instance.new("UICorner")
    ledCorner1.CornerRadius = UDim.new(1, 0)
    ledCorner1.Parent = statusIndicator1

    -- Nút Bay Nằm
    local flyToggleBtn = Instance.new("ImageButton")
    flyToggleBtn.Size = UDim2.new(0, 48, 0, 48)
    flyToggleBtn.Position = UDim2.new(0, 15, 0, 115)
    flyToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    flyToggleBtn.BackgroundTransparency = 0.2
    flyToggleBtn.BorderSizePixel = 0
    flyToggleBtn.Parent = screenGui

    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 10)
    btnCorner2.Parent = flyToggleBtn

    local btnStroke2 = Instance.new("UIStroke")
    btnStroke2.Color = Color3.fromRGB(80, 80, 90)
    btnStroke2.Thickness = 1.5
    btnStroke2.Parent = flyToggleBtn

    local flyIcon = Instance.new("ImageLabel")
    flyIcon.Size = UDim2.new(0, 30, 0, 30)
    flyIcon.Position = UDim2.new(0.5, -15, 0.5, -15)
    flyIcon.BackgroundTransparency = 1
    flyIcon.Image = "rbxassetid://10734951475"
    flyIcon.ImageColor3 = Color3.fromRGB(80, 140, 200)
    flyIcon.Parent = flyToggleBtn

    local statusIndicator2 = Instance.new("Frame")
    statusIndicator2.Size = UDim2.new(0, 5, 0, 28)
    statusIndicator2.Position = UDim2.new(1, 4, 0.5, -14)
    statusIndicator2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    statusIndicator2.BorderSizePixel = 0
    statusIndicator2.Parent = flyToggleBtn

    local ledCorner2 = Instance.new("UICorner")
    ledCorner2.CornerRadius = UDim.new(1, 0)
    ledCorner2.Parent = statusIndicator2

    -- Dấu cộng (Crosshair)
    local crosshairFrame = Instance.new("Frame")
    crosshairFrame.Size = UDim2.new(0, 16, 0, 16)
    crosshairFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    crosshairFrame.BackgroundTransparency = 1
    crosshairFrame.Visible = false
    crosshairFrame.Parent = screenGui

    local lineH = Instance.new("Frame")
    lineH.Size = UDim2.new(1, 0, 0, 2)
    lineH.Position = UDim2.new(0, 0, 0.5, -1)
    lineH.BackgroundColor3 = Color3.fromRGB(255, 50, 0)
    lineH.BorderSizePixel = 0
    lineH.Parent = crosshairFrame

    local lineV = Instance.new("Frame")
    lineV.Size = UDim2.new(0, 2, 1, 0)
    lineV.Position = UDim2.new(0.5, -1, 0, 0)
    lineV.BackgroundColor3 = Color3.fromRGB(255, 50, 0)
    lineV.BorderSizePixel = 0
    lineV.Parent = crosshairFrame

    -- 7. TẠO TRAIL XANH NGANG
    local flyTrailAtt0 = Instance.new("Attachment", realRoot)
    flyTrailAtt0.Position = Vector3.new(-1.2, 0, 0)
    local flyTrailAtt1 = Instance.new("Attachment", realRoot)
    flyTrailAtt1.Position = Vector3.new(1.2, 0, 0)

    local speedTrail = Instance.new("Trail")
    speedTrail.Attachment0 = flyTrailAtt0
    speedTrail.Attachment1 = flyTrailAtt1
    speedTrail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 80))
    })
    speedTrail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    })
    speedTrail.Lifetime = 0.3
    speedTrail.MaxLength = 10
    speedTrail.Enabled = false
    speedTrail.Parent = realRoot

    -- TẠO TIA LASER
    local laserPart1 = Instance.new("Part")
    laserPart1.Shape = Enum.PartType.Cylinder
    laserPart1.Material = Enum.Material.Neon
    laserPart1.Color = Color3.fromRGB(255, 90, 0)
    laserPart1.Transparency = 1
    laserPart1.Anchored = true
    laserPart1.CanCollide = false
    laserPart1.CanQuery = false
    laserPart1.Parent = Workspace

    local laserPart2 = Instance.new("Part")
    laserPart2.Shape = Enum.PartType.Cylinder
    laserPart2.Material = Enum.Material.Neon
    laserPart2.Color = Color3.fromRGB(255, 190, 80)
    laserPart2.Transparency = 1
    laserPart2.Anchored = true
    laserPart2.CanCollide = false
    laserPart2.CanQuery = false
    laserPart2.Parent = Workspace

    local targetPart = Instance.new("Part")
    targetPart.Size = Vector3.new(0.1, 0.1, 0.1)
    targetPart.Transparency = 1
    targetPart.Anchored = true
    targetPart.CanCollide = false
    targetPart.CanQuery = false
    targetPart.Parent = Workspace

    local attTrailA = Instance.new("Attachment", targetPart)
    attTrailA.Position = Vector3.new(0, 0.4, 0)
    local attTrailB = Instance.new("Attachment", targetPart)
    attTrailB.Position = Vector3.new(0, -0.4, 0)

    local laserTrail = Instance.new("Trail")
    laserTrail.Attachment0 = attTrailA
    laserTrail.Attachment1 = attTrailB
    laserTrail.Color = ColorSequence.new(Color3.fromRGB(255, 180, 50), Color3.fromRGB(255, 40, 0))
    laserTrail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
    laserTrail.Lifetime = 0.25
    laserTrail.Enabled = false
    laserTrail.Parent = targetPart

    -- Vụ nổ
    local function spawnVIPExplosion(worldPosition)
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
                                item.CanQuery = false
                                item.CanTouch = false
                                item.Position = worldPosition
                                item.Size = item.Size * 10
                                item.Transparency = 1
                                
                                task.delay(0.18, function()
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

    -- Mắt sáng
    local eyeParticleLeft, eyeParticleRight
    if head then
        local eyeAttL = Instance.new("Attachment")
        eyeAttL.Position = Vector3.new(-0.2, 0.15, -0.55)
        eyeAttL.Parent = head

        local eyeAttR = Instance.new("Attachment")
        eyeAttR.Position = Vector3.new(0.2, 0.15, -0.55)
        eyeAttR.Parent = head

        local function createEyeGlow(att)
            local p = Instance.new("ParticleEmitter")
            p.Color = ColorSequence.new(Color3.fromRGB(255, 140, 30))
            p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.1)})
            p.Texture = "rbxassetid://258127463"
            p.Lifetime = NumberRange.new(0.05, 0.15)
            p.Rate = 0
            p.Speed = NumberRange.new(0, 2)
            p.Parent = att
            return p
        end

        eyeParticleLeft = createEyeGlow(eyeAttL)
        eyeParticleRight = createEyeGlow(eyeAttR)
    end

    local laserActive = false
    local isFiring = false
    local flyActive = false

    local bodyGyro, bodyVelocity

    -- SỰ KIỆN NÚT LASER
    laserToggleBtn.MouseButton1Click:Connect(function()
        laserActive = not laserActive
        crosshairFrame.Visible = laserActive
        if laserActive then
            statusIndicator1.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            btnStroke1.Color = Color3.fromRGB(0, 255, 100)
            eyeIcon.ImageColor3 = Color3.fromRGB(255, 30, 30)
        else
            statusIndicator1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btnStroke1.Color = Color3.fromRGB(80, 80, 90)
            eyeIcon.ImageColor3 = Color3.fromRGB(150, 40, 40)
            isFiring = false
            laserPart1.Transparency = 1
            laserPart2.Transparency = 1
            laserTrail.Enabled = false
            if eyeParticleLeft then eyeParticleLeft.Rate = 0 end
            if eyeParticleRight then eyeParticleRight.Rate = 0 end
            if neckMotor then
                neckMotor.C0 = CFrame.new(0, (torso.Size.Y / 2) - 0.05, 0)
            end
        end
    end)

    -- SỰ KIỆN NÚT BAY NẰM
    flyToggleBtn.MouseButton1Click:Connect(function()
        flyActive = not flyActive
        if flyActive then
            statusIndicator2.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            btnStroke2.Color = Color3.fromRGB(0, 255, 100)
            flyIcon.ImageColor3 = Color3.fromRGB(100, 220, 255)

            realHumanoid.PlatformStand = true

            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.P = 20000
            bodyGyro.D = 800
            bodyGyro.MaxTorque = Vector3.new(50000, 50000, 50000)
            bodyGyro.CFrame = realRoot.CFrame
            bodyGyro.Parent = realRoot

            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.P = 4000
            bodyVelocity.MaxForce = Vector3.new(50000, 50000, 50000)
            bodyVelocity.Parent = realRoot
        else
            statusIndicator2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btnStroke2.Color = Color3.fromRGB(80, 80, 90)
            flyIcon.ImageColor3 = Color3.fromRGB(80, 140, 200)

            speedTrail.Enabled = false
            realHumanoid.PlatformStand = false
            realHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            if bodyGyro then bodyGyro:Destroy() end
            if bodyVelocity then bodyVelocity:Destroy() end
        end
    end)

    -- BẬT CƠ CHẾ BẮN LASER BẰNG PHÍM F VÀ CHUỘT TRÁI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if (input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1) and laserActive then
            isFiring = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isFiring = false
        end
    end)

    -- 8. VÒNG LẶP RENDER + CHỐNG ANTI-CHEAT
    local animMap = {}
    local renderConn
    local hoverCounter = 0
    local currentVelocity = Vector3.new(0, 0, 0)
    local antiKickTimer = 0

    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not realChar or not realChar.Parent or realHumanoid.Health <= 0 then
            visualModel:Destroy()
            screenGui:Destroy()
            laserPart1:Destroy()
            laserPart2:Destroy()
            targetPart:Destroy()
            speedTrail:Destroy()
            if bodyGyro then bodyGyro:Destroy() end
            if bodyVelocity then bodyVelocity:Destroy() end
            renderConn:Disconnect()
            return
        end

        if flyActive and bodyGyro and bodyVelocity then
            antiKickTimer = antiKickTimer + dt
            if antiKickTimer >= 3.0 then
                antiKickTimer = 0
                pcall(function()
                    realHumanoid:ChangeState(Enum.HumanoidStateType.Running)
                    task.defer(function()
                        if flyActive then
                            realHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                        end
                    end)
                end)
            end

            realHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            realHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            realHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

            local isBoost = UserInputService:IsKeyDown(Enum.KeyCode.G)
            local targetSpeed = isBoost and 90 or 35

            speedTrail.Enabled = isBoost

            local camCF = Camera.CFrame
            local moveInput = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveInput = moveInput + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveInput = moveInput - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveInput = moveInput - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveInput = moveInput + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveInput = moveInput + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveInput = moveInput - Vector3.new(0, 1, 0) end

            local targetVel = Vector3.new(0, 0, 0)
            if moveInput.Magnitude > 0 then
                targetVel = moveInput.Unit * targetSpeed
            else
                hoverCounter = hoverCounter + 0.05
                targetVel = Vector3.new(0, math.sin(hoverCounter * 3) * 0.6, 0)
            end

            currentVelocity = currentVelocity:Lerp(targetVel, math.clamp(dt * 5, 0, 1))
            bodyVelocity.Velocity = currentVelocity

            if moveInput.Magnitude > 0 then
                bodyGyro.CFrame = CFrame.new(realRoot.Position, realRoot.Position + moveInput) * CFrame.Angles(math.rad(-90), 0, 0)
            else
                bodyGyro.CFrame = CFrame.new(realRoot.Position, realRoot.Position + camCF.LookVector) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        else
            speedTrail.Enabled = false
            currentVelocity = Vector3.new(0, 0, 0)
            antiKickTimer = 0
        end

        local realAnimator = realHumanoid:FindFirstChildOfClass("Animator")
        if realAnimator then
            pcall(function()
                for _, track in ipairs(realAnimator:GetPlayingAnimationTracks()) do
                    local animId = track.Animation.AnimationId
                    if not animMap[animId] then
                        local visAnimator = visualHumanoid and (visualHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", visualHumanoid))
                        if visAnimator then
                            local visTrack = visAnimator:LoadAnimation(track.Animation)
                            visTrack:Play()
                            visTrack:AdjustSpeed(track.Speed)
                            visTrack.Priority = track.Priority
                            animMap[animId] = visTrack
                        end
                    else
                        animMap[animId]:AdjustSpeed(track.Speed)
                    end
                end

                for animId, visTrack in pairs(animMap) do
                    local isStillPlaying = false
                    for _, track in ipairs(realAnimator:GetPlayingAnimationTracks()) do
                        if track.Animation.AnimationId == animId then
                            isStillPlaying = true
                            break
                        end
                    end
                    if not isStillPlaying then
                        visTrack:Stop()
                        animMap[animId] = nil
                    end
                end
            end)
        end

        if laserActive and head and torso and neckMotor then
            local mousePos = UserInputService:GetMouseLocation()
            crosshairFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)

            local mouseRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {realChar, visualModel, laserPart1, laserPart2, targetPart}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local raycastResult = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 500, raycastParams)

            local targetPos = raycastResult and raycastResult.Position or (mouseRay.Origin + mouseRay.Direction * 500)

            local neckWorldPos = torso.Position + Vector3.new(0, (torso.Size.Y / 2) - 0.05, 0)
            local lookAtCFrame = CFrame.new(neckWorldPos, targetPos)
            local localCFrame = torso.CFrame:ToObjectSpace(lookAtCFrame)
            
            local x, y, z = localCFrame:ToOrientation()
            x = math.clamp(x, -0.9, 0.9) 
            y = math.clamp(y, -1.0, 1.0)
            local limitedCFrame = CFrame.new(localCFrame.Position) * CFrame.fromOrientation(x, y, 0)

            neckMotor.C0 = neckMotor.C0:Lerp(limitedCFrame, 0.35)

            local leftEyePos = head.Position + (head.CFrame.RightVector * -0.2) + (head.CFrame.LookVector * 0.55)
            local rightEyePos = head.Position + (head.CFrame.RightVector * 0.2) + (head.CFrame.LookVector * 0.55)
            targetPart.CFrame = CFrame.new(targetPos)

            if isFiring then
                local tickCounter = tickCounter or 0
                tickCounter = tickCounter + 0.25
                local pulse = math.sin(tickCounter * 12) * 0.06

                local dist1 = (targetPos - leftEyePos).Magnitude
                local dist2 = (targetPos - rightEyePos).Magnitude

                laserPart1.Size = Vector3.new(dist1, 0.28 + pulse, 0.28 + pulse)
                laserPart1.CFrame = CFrame.new(leftEyePos, targetPos) * CFrame.new(0, 0, -dist1 / 2) * CFrame.Angles(0, math.rad(90), 0)
                laserPart1.Transparency = 0

                laserPart2.Size = Vector3.new(dist2, 0.22 + pulse, 0.22 + pulse)
                laserPart2.CFrame = CFrame.new(rightEyePos, targetPos) * CFrame.new(0, 0, -dist2 / 2) * CFrame.Angles(0, math.rad(90), 0)
                laserPart2.Transparency = 0

                laserTrail.Enabled = true
                spawnVIPExplosion(targetPos)

                if eyeParticleLeft then eyeParticleLeft.Rate = 60 end
                if eyeParticleRight then eyeParticleRight.Rate = 60 end
            else
                laserPart1.Transparency = 1
                laserPart2.Transparency = 1
                laserTrail.Enabled = false
                if eyeParticleLeft then eyeParticleLeft.Rate = 0 end
                if eyeParticleRight then eyeParticleRight.Rate = 0 end
            end
        else
            laserPart1.Transparency = 1
            laserPart2.Transparency = 1
            laserTrail.Enabled = false
            if eyeParticleLeft then eyeParticleLeft.Rate = 0 end
            if eyeParticleRight then eyeParticleRight.Rate = 0 end
        end
    end)

    Camera.CameraSubject = realHumanoid
    print("Superman VIP v11.0: Đã bật phím F và Chuột trái để bắn Laser!")
end

applyUltimateSuperman()
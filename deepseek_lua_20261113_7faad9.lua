--!nocheck
-- ============================================================
-- TIME STOP + LINE LAG SPAM + COUNTDOWN (ONE-SHOT ON EXECUTE)
-- Execute → chạy 1 lần → xong tự dừng, không phím, không lặp
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local SoundService      = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
if env.CombinedCleanup then pcall(env.CombinedCleanup) end

print("[Combo] Loading...")

-- ============================================================
-- CONFIG
-- ============================================================
local INTRO_SOUND      = "rbxassetid://134121369092456"
local TICK_SOUND       = "rbxassetid://128707491647978"
local END_SOUND        = "rbxassetid://97280437833993"
local END_SOUND_LEN    = 3

local INTRO_TIME       = 4
local DURATION         = 20
local GRAY_FADE_TIME   = 1.2
local FREEZE_ANCHORED_PARTS = false
local PAUSE_SOUNDS     = true
local HIGHLIGHT_SELF   = true
local LAG_LINES        = 11

-- ============================================================
-- REMOTE
-- ============================================================
local GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 10)
local CreateGrabLine, DestroyGrabLine
if GrabEvents then
    CreateGrabLine  = GrabEvents:WaitForChild("CreateGrabLine", 5)
    DestroyGrabLine = GrabEvents:FindFirstChild("DestroyGrabLine")
end
print("[Combo] CreateGrabLine:", CreateGrabLine)

local SpawnLocation = workspace:FindFirstChild("SpawnLocation")
    or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))

-- ============================================================
-- LINE LAG SPAM
-- ============================================================
local SpamRunning = false

local function BuildLagCFrame()
    local m = -2 ^ (20 + LAG_LINES)
    return CFrame.new(m, 0, m)
end

local function SpamLoop()
    while SpamRunning do
        local anchor = SpawnLocation
        if not anchor or not anchor.Parent then
            anchor = workspace:FindFirstChild("SpawnLocation")
                or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        end
        if anchor and CreateGrabLine then
            local cframe = BuildLagCFrame()
            pcall(function() CreateGrabLine:FireServer(anchor, cframe) end)
        end
        RunService.Heartbeat:Wait()
    end
end

local function StartSpam()
    if SpamRunning then return end
    if not CreateGrabLine then
        warn("[Combo] Không có CreateGrabLine, skip spam")
        return
    end
    SpamRunning = true
    task.spawn(SpamLoop)
end

local function StopSpam()
    SpamRunning = false
    if DestroyGrabLine and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() DestroyGrabLine:FireServer(hrp) end) end
    end
end

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "TimeStopGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FILL_TRANSPARENCY = 0.4

local function makeRing(fillColor, strokeColor, zindex, thickness)
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = UDim2.fromScale(0.5, 0.5)
    f.Size = UDim2.fromOffset(0, 0)
    f.BackgroundColor3 = fillColor
    f.BackgroundTransparency = FILL_TRANSPARENCY
    f.BorderSizePixel = 0
    f.ZIndex = zindex
    f.Visible = false
    f.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = f
    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor
    stroke.Thickness = thickness
    stroke.Transparency = 0
    stroke.Parent = f
    return f, stroke
end

local white, whiteStroke = makeRing(Color3.new(1,1,1), Color3.new(0,0,0), 1, 8)
local black, blackStroke = makeRing(Color3.new(0,0,0), Color3.new(1,1,1), 2, 6)
local core,  coreStroke  = makeRing(Color3.new(1,1,1), Color3.new(0,0,0), 3, 4)
local circles = {white, black, core}
local strokes = {whiteStroke, blackStroke, coreStroke}

-- === COUNTDOWN: font mảnh, vàng sáng, không viền ===
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.AnchorPoint = Vector2.new(0.5, 0)
countdownLabel.Position = UDim2.new(0.5, 0, 0, 24)
countdownLabel.Size = UDim2.new(0, 300, 0, 110)
countdownLabel.BackgroundTransparency = 1
countdownLabel.BorderSizePixel = 0
countdownLabel.Text = ""
countdownLabel.TextColor3 = Color3.fromRGB(255, 240, 100)
countdownLabel.TextStrokeTransparency = 1
countdownLabel.TextTransparency = 0
countdownLabel.Font = Enum.Font.Gotham
countdownLabel.TextScaled = false
countdownLabel.TextSize = 90
countdownLabel.ZIndex = 100
countdownLabel.Visible = false
countdownLabel.Parent = gui

-- ============================================================
-- COLOR CORRECTION
-- ============================================================
local cc = nil

local function createCC()
    if cc then cc:Destroy() end
    cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "TimeStopCC"
    cc.Saturation = 0
    cc.Contrast = 0
    cc.Brightness = 0
    cc.TintColor = Color3.new(1,1,1)
    cc.Parent = Lighting
    return cc
end

local function destroyCC()
    if cc then cc:Destroy() cc = nil end
end

-- ============================================================
-- ĐÓNG BĂNG
-- ============================================================
local pinned, trackSpeed, emitters, pausedSounds = {}, {}, {}, {}
local freezeConns = {}
local pinConn = nil
local highlight = nil

local function isMine(inst)
    local char = LocalPlayer.Character
    if char and inst:IsDescendantOf(char) then return true end
    if camera and inst:IsDescendantOf(camera) then return true end
    return false
end

local function freezeTrack(track)
    if trackSpeed[track] == nil then trackSpeed[track] = track.Speed end
    track:AdjustSpeed(0)
end

local function hookAnimator(animator)
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        freezeTrack(track)
    end
    table.insert(freezeConns, animator.AnimationPlayed:Connect(freezeTrack))
end

local function freezeWorld()
    for _, inst in ipairs(workspace:GetDescendants()) do
        if not isMine(inst) then
            if inst:IsA("BasePart") and not inst:IsA("Terrain") then
                local root = inst.AssemblyRootPart
                if root and pinned[root] == nil and not isMine(root)
                    and (FREEZE_ANCHORED_PARTS or not root.Anchored) then
                    pinned[root] = root.CFrame
                end
            elseif inst:IsA("Animator") then
                hookAnimator(inst)
            elseif inst:IsA("ParticleEmitter") then
                emitters[inst] = inst.TimeScale
                inst.TimeScale = 0
            elseif PAUSE_SOUNDS and inst:IsA("Sound") and inst.Playing then
                pausedSounds[inst] = true
                inst:Pause()
            end
        end
    end

    pinConn = RunService.RenderStepped:Connect(function()
        for root, cf in pairs(pinned) do
            if root.Parent then
                root.CFrame = cf
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            else
                pinned[root] = nil
            end
        end
    end)

    if HIGHLIGHT_SELF and LocalPlayer.Character then
        highlight = Instance.new("Highlight")
        highlight.Adornee = LocalPlayer.Character
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = LocalPlayer.Character
    end
end

local function unfreezeWorld()
    if pinConn then pinConn:Disconnect() pinConn = nil end
    for _, c in ipairs(freezeConns) do c:Disconnect() end
    table.clear(freezeConns)
    table.clear(pinned)
    for track, speed in pairs(trackSpeed) do
        pcall(function() track:AdjustSpeed(speed) end)
    end
    table.clear(trackSpeed)
    for e, ts in pairs(emitters) do
        pcall(function() e.TimeScale = ts end)
    end
    table.clear(emitters)
    for s in pairs(pausedSounds) do
        pcall(function() s:Resume() end)
    end
    table.clear(pausedSounds)
    if highlight then highlight:Destroy() highlight = nil end
end

-- ============================================================
-- ÂM THANH
-- ============================================================
local function playSound(id, parent, volume)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 1
    s.Parent = parent or SoundService
    s:Play()
    return s
end

-- ============================================================
-- SKILL
-- ============================================================
local function castComboInternal()
    local startTime = os.clock()
    StartSpam()

    local viewport = gui.AbsoluteSize
    local diag = math.sqrt(viewport.X^2 + viewport.Y^2) * 1.15
    local origFOV = camera.FieldOfView

    local introSound = playSound(INTRO_SOUND, gui, 1)

    for i, c in ipairs(circles) do
        c.Size = UDim2.fromOffset(0, 0)
        c.BackgroundTransparency = FILL_TRANSPARENCY
        strokes[i].Transparency = 0
        c.Visible = true
    end

    TweenService:Create(white,
        TweenInfo.new(INTRO_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.fromOffset(diag, diag)}):Play()
    TweenService:Create(black,
        TweenInfo.new(INTRO_TIME * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, INTRO_TIME * 0.08),
        {Size = UDim2.fromOffset(diag * 0.85, diag * 0.85)}):Play()
    TweenService:Create(core,
        TweenInfo.new(INTRO_TIME * 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, INTRO_TIME * 0.25),
        {Size = UDim2.fromOffset(diag * 0.55, diag * 0.55)}):Play()
    TweenService:Create(camera,
        TweenInfo.new(INTRO_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
        {FieldOfView = origFOV - 10}):Play()

    task.wait(INTRO_TIME - GRAY_FADE_TIME)
    local myCC = createCC()
    TweenService:Create(myCC,
        TweenInfo.new(GRAY_FADE_TIME, Enum.EasingStyle.Sine),
        {Saturation = -1, Contrast = 0.4}):Play()
    task.wait(GRAY_FADE_TIME)

    freezeWorld()

    for i, c in ipairs(circles) do
        TweenService:Create(c, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 1}):Play()
        TweenService:Create(strokes[i], TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Transparency = 1}):Play()
    end
    TweenService:Create(camera,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {FieldOfView = origFOV}):Play()

    task.wait(0.8)
    for i, c in ipairs(circles) do
        c.Visible = false
        c.BackgroundTransparency = FILL_TRANSPARENCY
        strokes[i].Transparency = 0
    end

    -- ===== COUNTDOWN =====
    local endPhaseStart = DURATION - END_SOUND_LEN
    countdownLabel.Visible = true

    local lastSecond = -1
    while true do
        local elapsed = os.clock() - startTime
        if elapsed >= endPhaseStart then break end

        local remain = math.ceil(endPhaseStart - elapsed)
        if remain ~= lastSecond then
            lastSecond = remain
            countdownLabel.Text = tostring(remain)
            playSound(TICK_SOUND, gui, 1)
        end
        RunService.Heartbeat:Wait()
    end

    countdownLabel.Visible = false
    countdownLabel.Text = ""

    -- ===== KẾT THÚC 3s =====
    if highlight then highlight:Destroy() highlight = nil end

    local endSound = playSound(END_SOUND, gui, 1)

    if myCC and myCC.Parent then
        TweenService:Create(myCC,
            TweenInfo.new(END_SOUND_LEN, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Saturation = 0, Contrast = 0}):Play()
    end

    task.wait(END_SOUND_LEN)

    unfreezeWorld()
    StopSpam()
    destroyCC()
    if introSound then introSound:Destroy() end
    if endSound then endSound:Destroy() end
end

-- ============================================================
-- CLEANUP
-- ============================================================
env.CombinedCleanup = function()
    StopSpam()
    unfreezeWorld()
    if gui then gui:Destroy() end
    destroyCC()
end

-- ============================================================
-- CHẠY 1 LẦN NGAY KHI EXECUTE
-- ============================================================
print("[Combo] Loaded. Chạy 1 lần...")

task.wait(0.5)   -- đợi GUI + character ổn định
print("[Combo] Bắt đầu")
local ok, err = pcall(castComboInternal)
if not ok then
    warn("[Combo] LỖI:", err)
    pcall(unfreezeWorld)
    pcall(StopSpam)
    pcall(destroyCC)
end
print("[Combo] Xong.")

-- Tự dọn GUI sau khi hoàn tất
task.wait(0.2)
if gui then gui:Destroy() end

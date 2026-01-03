    -- Auto Farm
    AutoFarm = {
        Enabled = false,
        TargetPlayer = nil,
        TeleportConnection = nil,
        ESpamConnection = nil,
        DamageCheckConnection = nil,
        RespawnCooldown = false,
        MaxHealth = 115,
        IsRespawning = false
    },

local SAVECUBE_COORDINATES = Vector3.new(-4185.1, 102.6, 283.6)
local UNDERGROUND_COORDINATES = Vector3.new(-5048.8, -258.8, -129.8)
local SAVEVIBECHECK_COORDINATES = Vector3.new(-4878.1, -165.5, -921.2)

local function updateCameraSettings()
    if State.Camera.NoclipEnabled then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end
end

local function findTargetPlayer(playerName)
    for _, player in pairs(Players:GetPlayers()) do
        if string.lower(player.Name) == string.lower(playerName) or 
           string.lower(player.DisplayName) == string.lower(playerName) then
            return player
        end
    end
    return nil
end

local function getHumanoidRootPart(character)
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart
    end
    return nil
end

local function toggleFists()
    local character = LocalPlayer.Character
    if not character then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = backpack
            task.wait(0.2)
            tool.Parent = character
            break
        end
    end
end

local function enableNoClip(character)
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function startESpam()
    if State.AutoFarm.ESpamConnection then
        State.AutoFarm.ESpamConnection:Disconnect()
    end
    
    State.AutoFarm.ESpamConnection = RunService.Heartbeat:Connect(function()
        if Library.Unloaded then 
            if State.AutoFarm.ESpamConnection then
                State.AutoFarm.ESpamConnection:Disconnect()
                State.AutoFarm.ESpamConnection = nil
            end
            return 
        end
        
        if not State.AutoFarm.Enabled or State.AutoFarm.IsRespawning then return end
        
        local character = LocalPlayer.Character
        if character then
            local virtualInput = game:GetService("VirtualInputManager")
            virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

local function forceRespawn()
    if State.AutoFarm.RespawnCooldown or State.AutoFarm.IsRespawning then return end
    
    State.AutoFarm.RespawnCooldown = true
    State.AutoFarm.IsRespawning = true
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end
    
    local virtualInput = game:GetService("VirtualInputManager")
    
    virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    
    task.wait(0.3)
    virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    
    task.wait(0.2)
    virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    
    task.wait(0.5)
    State.AutoFarm.RespawnCooldown = false
    State.AutoFarm.IsRespawning = false
end

local function startDamageDetection()
    if State.AutoFarm.DamageCheckConnection then
        State.AutoFarm.DamageCheckConnection:Disconnect()
    end
    
    State.AutoFarm.DamageCheckConnection = RunService.Heartbeat:Connect(function()
        if Library.Unloaded then 
            if State.AutoFarm.DamageCheckConnection then
                State.AutoFarm.DamageCheckConnection:Disconnect()
                State.AutoFarm.DamageCheckConnection = nil
            end
            return 
        end
        
        if not State.AutoFarm.Enabled or State.AutoFarm.IsRespawning then return end
        
        local character = LocalPlayer.Character
        if not character then return end
    
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        if humanoid.MaxHealth > State.AutoFarm.MaxHealth then
            State.AutoFarm.MaxHealth = humanoid.MaxHealth
        end
        
        if humanoid.Health < State.AutoFarm.MaxHealth then
            forceRespawn()
        end
    end)
end

local function teleportToTarget()
    if Library.Unloaded then return end
    if not State.AutoFarm.Enabled or State.AutoFarm.IsRespawning then return end
    
    local myCharacter = LocalPlayer.Character
    if not myCharacter or not State.AutoFarm.TargetPlayer then return end
    
    local targetCharacter = State.AutoFarm.TargetPlayer.Character
    if not targetCharacter then return end
    
    local myRoot = getHumanoidRootPart(myCharacter)
    if not myRoot then return end
    
    enableNoClip(myCharacter)
    
    local targetRoot = getHumanoidRootPart(targetCharacter)
    if not targetRoot then return end
    
    local lookVector = targetRoot.CFrame.LookVector
    local targetPosition = targetRoot.Position + (lookVector * 2.5) + Vector3.new(0, 0.5, 0)
    
    local backCFrame = CFrame.new(targetPosition) * CFrame.Angles(0, math.pi, 0)
    myRoot.CFrame = backCFrame
end

local function teleportToSaveCube()
    if Library.Unloaded then return end
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = getHumanoidRootPart(character)
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(SAVECUBE_COORDINATES)
    Library:Notify("Teleported to Save Cube", 2)
end

local function teleportToUnderground()
    if Library.Unloaded then return end
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = getHumanoidRootPart(character)
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(UNDERGROUND_COORDINATES)
    Library:Notify("Teleported to Underground", 2)
end

local function teleportToSaveVibecheck()
    if Library.Unloaded then return end
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = getHumanoidRootPart(character)
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(SAVEVIBECHECK_COORDINATES)
    Library:Notify("Teleported to Save Vibecheck", 2)
end

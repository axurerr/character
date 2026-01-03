-- ============================================
-- AUTO FARM SYSTEM (ПОЛНЫЙ МОДУЛЬ)
-- ============================================

-- Координаты телепортов
local SAVECUBE_COORDINATES = Vector3.new(-4185.1, 102.6, 283.6)
local UNDERGROUND_COORDINATES = Vector3.new(-5048.8, -258.8, -129.8)
local SAVEVIBECHECK_COORDINATES = Vector3.new(-4878.1, -165.5, -921.2)

-- Состояние AutoFarm в общей таблице State
local State = {
    -- Auto Farm
    AutoFarm = {
        Enabled = false,
        TargetPlayer = nil,
        TeleportConnection = nil,
        ESpamConnection = nil,
        DamageCheckConnection = nil,
        RespawnCooldown = false,
        MaxHealth = 115,
        IsRespawning = false,
        AutoFarmCharacterAddedConnection = nil
    },
    
    -- Collector (Auto Pick Money)
    Collector = {
        Enabled = false,
        Signal = nil,
        Task = nil
    }
}

local Settings = { IsDead = false }
local CoolDowns = { AutoPickUps = { MoneyCooldown = false } }

-- Вспомогательные функции
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

-- Auto Farm функции
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

-- Телепорты
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

-- Auto Pick Money (Collector)
local function CollectorCoreLogic()
    local RSS = RunService
    local RSRep = ReplicatedStorage
    local WS = Workspace
    local function RunCollectorLogic()
        if not State.Collector.Enabled or Settings.IsDead then return end
        local breadContainer = WS.Filter:FindFirstChild("SpawnedBread")
        local pickupRemote = RSRep.Events:FindFirstChild("CZDPZUS")
        if not breadContainer then return end
        if not pickupRemote then return end
        local pchar = LocalPlayer.Character
        local rootpart = pchar and pchar:FindFirstChild("HumanoidRootPart")
        if not rootpart or CoolDowns.AutoPickUps.MoneyCooldown then return end
        local currentpos = rootpart.Position
        for _, item in ipairs(breadContainer:GetChildren()) do
            local distsq = (currentpos - item.Position).Magnitude^2
            if distsq < 25 and not CoolDowns.AutoPickUps.MoneyCooldown then
                CoolDowns.AutoPickUps.MoneyCooldown = true
                pcall(function()
                    pickupRemote:FireServer(item)
                end)
                task.wait(1.1)
                CoolDowns.AutoPickUps.MoneyCooldown = false
                break
            end
        end
    end
    State.Collector.Signal = RSS.RenderStepped:Connect(RunCollectorLogic)
end

local function CollectorActivate()
    if State.Collector.Enabled then return end
    State.Collector.Enabled = true
    if State.Collector.Signal then
        State.Collector.Signal:Disconnect()
        State.Collector.Signal = nil
    end
    if State.Collector.Task then
        coroutine.close(State.Collector.Task)
        State.Collector.Task = nil
    end
    State.Collector.Task = coroutine.create(CollectorCoreLogic)
    coroutine.resume(State.Collector.Task)
    Library:Notify("Auto Pick Money enabled!", 3)
end

local function CollectorDeactivate()
    if not State.Collector.Enabled then return end
    State.Collector.Enabled = false
    if State.Collector.Signal then
        State.Collector.Signal:Disconnect()
        State.Collector.Signal = nil
    end
    if CoolDowns and CoolDowns.AutoPickUps then
        CoolDowns.AutoPickUps.MoneyCooldown = false
    end
    Library:Notify("Auto Pick Money disabled!", 3)
end

-- UI для AutoFarm
local FarmLeft = Tabs.Farm:AddLeftGroupbox("Auto Farm")
local FarmRight = Tabs.Farm:AddRightGroupbox("Auto Pick Money")

local targetNameBox = FarmLeft:AddInput("TargetName", {
    Text = "Target Name",
    Placeholder = "Enter username...",
    Default = "",
    Callback = function(value)
        -- Callback может быть пустым, так как значение используется только при включении
    end
})

FarmLeft:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(state)
        State.AutoFarm.Enabled = state
        
        if State.AutoFarm.Enabled then
            local targetName = targetNameBox.Value
            if targetName == "" then
                Toggles.AutoFarm:SetValue(false)
                Library:Notify("Enter target name first!", 3)
                return
            end
            
            State.AutoFarm.TargetPlayer = findTargetPlayer(targetName)
            if not State.AutoFarm.TargetPlayer then
                Toggles.AutoFarm:SetValue(false)
                Library:Notify("Player not found!", 3)
                return
            end
            
            toggleFists()
            
            if not State.AutoFarmCharacterAddedConnection then
                State.AutoFarmCharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
                    task.wait(0.2)
                    if State.AutoFarm.Enabled then
                        toggleFists()
                        Library:Notify("Auto fists after death", 2)
                    end
                end)
            end
            
            startESpam()
            startDamageDetection()
            State.AutoFarm.TeleportConnection = RunService.Heartbeat:Connect(teleportToTarget)
            Library:Notify("Auto Farm started!", 3)
            
        else
            if State.AutoFarm.TeleportConnection then State.AutoFarm.TeleportConnection:Disconnect() end
            if State.AutoFarm.ESpamConnection then State.AutoFarm.ESpamConnection:Disconnect() end
            if State.AutoFarm.DamageCheckConnection then State.AutoFarm.DamageCheckConnection:Disconnect() end
            
            if State.AutoFarmCharacterAddedConnection then
                State.AutoFarmCharacterAddedConnection:Disconnect()
                State.AutoFarmCharacterAddedConnection = nil
            end
            
            State.AutoFarm.TargetPlayer = nil
            State.AutoFarm.RespawnCooldown = false
            State.AutoFarm.IsRespawning = false
            State.AutoFarm.MaxHealth = 115
            Library:Notify("Auto Farm stopped!", 3)
        end
    end
})

FarmLeft:AddDivider()
FarmLeft:AddLabel("Teleports:")

FarmLeft:AddButton({
    Text = "SaveCube",
    Func = teleportToSaveCube
})

FarmLeft:AddButton({
    Text = "Underground",
    Func = teleportToUnderground
})

FarmLeft:AddButton({
    Text = "SaveVibecheck",
    Func = teleportToSaveVibecheck
})

-- UI для Auto Pick Money
FarmRight:AddToggle("AutoPickMoney", {
    Text = "Auto Pick Money",
    Default = false,
    Callback = function(value)
        if value then
            CollectorActivate()
        else
            CollectorDeactivate()
        end
    end
})

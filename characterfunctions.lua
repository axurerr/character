local function noclipLoop()
    while State.Noclip.Enabled do
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
        RunService.RenderStepped:Wait()
    end
end

local function toggleNoclip(state)
    State.Noclip.Enabled = state
    _G.NoclipPersistent = state
    
    if State.Noclip.Enabled then
        Library:Notify("Noclip enabled", 2)
        noclipLoop()
        
        local function onCharacterAdded(char)
            task.wait(0.5)
            if State.Noclip.Enabled then
                noclipLoop()
            end
        end
        
        if LocalPlayer.Character then
            onCharacterAdded(LocalPlayer.Character)
        end
        LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    else
        if State.Noclip.Connection then
            State.Noclip.Connection:Disconnect()
            State.Noclip.Connection = nil
        end
        Library:Notify("Noclip disabled", 2)
    end
end

local function stopNeckMovement()
    if LocalPlayer.Character then
        LocalPlayer.Character:SetAttribute("NoNeckMovement", true)
    end
end

local function restoreNeckMovement()
    if LocalPlayer.Character then
        LocalPlayer.Character:SetAttribute("NoNeckMovement", false)
    end
end

local function toggleStopNeckMove(state)
    State.StopNeckMove.Enabled = state
    
    if State.StopNeckMove.Enabled then
        stopNeckMovement()
        Library:Notify("Stop Neck Move enabled", 2)
        
        local connection = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if State.StopNeckMove.Enabled then
                stopNeckMovement()
            end
        end)
        
        if State.StopNeckMove.Connection then
            State.StopNeckMove.Connection:Disconnect()
        end
        State.StopNeckMove.Connection = connection
    else
        restoreNeckMovement()
        if State.StopNeckMove.Connection then
            State.StopNeckMove.Connection:Disconnect()
            State.StopNeckMove.Connection = nil
        end
        Library:Notify("Stop Neck Move disabled", 2)
    end
end

local function setupUnbreakLimbs()
    local charStats = ReplicatedStorage.CharStats
    if not charStats then return end
    
    local myStats = charStats:FindFirstChild(LocalPlayer.Name)
    if not myStats then return end
    
    local limbsFolder = myStats:FindFirstChild("HealthValues")
    if not limbsFolder then return end
    
    local function unbreakAllLimbs()
        for _, limb in pairs(limbsFolder:GetChildren()) do
            local brokenValue = limb:FindFirstChild("Broken")
            if brokenValue then
                brokenValue.Value = false
                local connection = brokenValue:GetPropertyChangedSignal("Value"):Connect(function()
                    brokenValue.Value = false
                end)
                table.insert(State.UnbreakLimbs.Connections, connection)
            end
        end
    end
    
    unbreakAllLimbs()
    
    local childAddedConnection = limbsFolder.ChildAdded:Connect(function()
        task.wait(0.1)
        if State.UnbreakLimbs.Enabled then
            unbreakAllLimbs()
        end
    end)
    table.insert(State.UnbreakLimbs.Connections, childAddedConnection)
end

local function toggleUnbreakLimbs(state)
    State.UnbreakLimbs.Enabled = state
    
    if State.UnbreakLimbs.Enabled then
        setupUnbreakLimbs()
        Library:Notify("Unbreak Limbs enabled", 2)
        
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if State.UnbreakLimbs.Enabled then
                setupUnbreakLimbs()
            end
        end)
    else
        for _, connection in pairs(State.UnbreakLimbs.Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        State.UnbreakLimbs.Connections = {}
        Library:Notify("Unbreak Limbs disabled", 2)
    end
end

local function setupFakeDown()
    if not LocalPlayer.Character then return end
    
    local charStats = ReplicatedStorage.CharStats
    if not charStats then return end
    
    local myStats = charStats:FindFirstChild(LocalPlayer.Name)
    if not myStats then return end
    
    local downedValue = myStats:FindFirstChild("Downed")
    if not downedValue then return end
    
    State.FakeDowned.DownedStatObject = downedValue
    State.FakeDowned.OriginalDownedValue = downedValue.Value
    
    if downedValue.Value ~= true then
        downedValue.Value = true
    end
    
    State.FakeDowned.Connection = downedValue:GetPropertyChangedSignal("Value"):Connect(function()
        if downedValue.Value ~= true then
            downedValue.Value = true
        end
    end)
end

local function restoreOriginalDowned()
    if State.FakeDowned.DownedStatObject and State.FakeDowned.OriginalDownedValue ~= nil then
        if State.FakeDowned.Connection then
            State.FakeDowned.Connection:Disconnect()
            State.FakeDowned.Connection = nil
        end
        State.FakeDowned.DownedStatObject.Value = State.FakeDowned.OriginalDownedValue
        State.FakeDowned.DownedStatObject = nil
        State.FakeDowned.OriginalDownedValue = nil
    end
end

local function toggleFakeDowned(state)
    State.FakeDowned.Enabled = state
    
    if State.FakeDowned.Enabled then
        setupFakeDown()
        Library:Notify("Fake Downed enabled", 2)
        
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if State.FakeDowned.Enabled then
                setupFakeDown()
            end
        end)
    else
        restoreOriginalDowned()
        Library:Notify("Fake Downed disabled", 2)
    end
end

local function addForceField(character)
    if character then
        for _, obj in pairs(character:GetChildren()) do
            if obj:IsA("ForceField") and obj.Visible == false then
                obj:Destroy()
            end
        end
        
        local ff = Instance.new("ForceField")
        ff.Parent = character
        ff.Visible = false
        
        local connection = character.ChildAdded:Connect(function(child)
            if child:IsA("ForceField") and child.Visible == false then
                task.wait(0.1)
                if State.NoFallDamage.Enabled then
                    child.Visible = false
                end
            end
        end)
        table.insert(State.NoFallDamage.Connections, connection)
    end
end

local function toggleNoFallDamage(state)
    State.NoFallDamage.Enabled = state
    
    if State.NoFallDamage.Enabled then
        if LocalPlayer.Character then
            addForceField(LocalPlayer.Character)
        end
        Library:Notify("No Fall Damage enabled", 2)
        
        local connection = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if State.NoFallDamage.Enabled then
                addForceField(char)
            end
        end)
        table.insert(State.NoFallDamage.Connections, connection)
    else
        for _, connection in pairs(State.NoFallDamage.Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        State.NoFallDamage.Connections = {}
        
        if LocalPlayer.Character then
            for _, obj in pairs(LocalPlayer.Character:GetChildren()) do
                if obj:IsA("ForceField") and obj.Visible == false then
                    obj:Destroy()
                end
            end
        end
        Library:Notify("No Fall Damage disabled", 2)
    end
end

local function disableBarriers()
    local filterFolder = Workspace:FindFirstChild("Filter")
    if not filterFolder then return end
    
    local partsFolder = filterFolder:FindFirstChild("Parts")
    if not partsFolder then return end
    
    local fParts = partsFolder:FindFirstChild("F_Parts")
    if not fParts then return end
    
    for _, descendant in pairs(fParts:GetDescendants()) do
        if descendant:IsA("Part") or descendant:IsA("MeshPart") then
            descendant.CanTouch = false
        end
    end
    
    State.NoSpike.Connection = fParts.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Part") or descendant:IsA("MeshPart") then
            descendant.CanTouch = false
        end
    end)
end

local function toggleNoSpike(state)
    State.NoSpike.Enabled = state
    
    if State.NoSpike.Enabled then
        if Workspace:FindFirstChild("Filter") then
            disableBarriers()
        else
            local workspaceConnection = Workspace.ChildAdded:Connect(function(child)
                if child.Name == "Filter" then
                    task.wait(0.5)
                    if State.NoSpike.Enabled then
                        disableBarriers()
                    end
                    workspaceConnection:Disconnect()
                end
            end)
        end
        
        Library:Notify("No Spike enabled", 2)
    else
        if State.NoSpike.Connection then
            State.NoSpike.Connection:Disconnect()
            State.NoSpike.Connection = nil
        end
        
        local filterFolder = Workspace:FindFirstChild("Filter")
        if filterFolder then
            local partsFolder = filterFolder:FindFirstChild("Parts")
            if partsFolder then
                local fParts = partsFolder:FindFirstChild("F_Parts")
                if fParts then
                    for _, descendant in pairs(fParts:GetDescendants()) do
                        if descendant:IsA("Part") or descendant:IsA("MeshPart") then
                            descendant.CanTouch = true
                        end
                    end
                end
            end
        end
        
        Library:Notify("No Spike disabled", 2)
    end
end

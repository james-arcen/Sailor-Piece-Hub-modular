-- ========================================================================
-- 📦 MÓDULO: AUTO QUEST (UNITÁRIA) COM TELEPORTE INTELIGENTE
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local TeleportService = Import("Modules/Teleport") -- Nosso serviço global!

local Module = {
    NoToggle = true -- Controle manual do layout na UI
}

function Module:Init()
    self.IsRunning = false
    self.MoveLoop = nil
    self.AttackLoop = nil
    self.FarmTarget = nil
    self.OrbitAngle = 0

    -- BANCO DE DADOS BRUTO
    local QuestDataMap = {
        ["Starter"] = {{Name = "Quest 1: Mobs (Thief)", NPC = "QuestNPC1", Target = "Thief", Type = "Mob"}, {Name = "Quest 2: Boss (Thief Boss)", NPC = "QuestNPC2", Target = "ThiefBoss", Type = "Boss"}},
        ["Jungle"] = {{Name = "Quest 3: Mobs (Monkey)", NPC = "QuestNPC3", Target = "Monkey", Type = "Mob"}, {Name = "Quest 4: Boss (Monkey Boss)", NPC = "QuestNPC4", Target = "MonkeyBoss", Type = "Boss"}},
        ["Desert"] = {{Name = "Quest 5: Mobs (Bandits)", NPC = "QuestNPC5", Target = "DesertBandit", Type = "Mob"}, {Name = "Quest 6: Boss (Desert Boss)", NPC = "QuestNPC6", Target = "DesertBoss", Type = "Boss"}},
        ["Snow"] = {{Name = "Quest 7: Mobs (Frost Rogue)", NPC = "QuestNPC7", Target = "FrostRogue", Type = "Mob"}, {Name = "Quest 8: Boss (Snow Boss)", NPC = "QuestNPC8", Target = "SnowBoss", Type = "Boss"}},
        ["Sailor"] = {{Name = "Âncora Sailor", NPC = "JinwooMovesetNPC", Target = "Nenhum", Type = "Mob"}},
        ["Shibuya"] = {{Name = "Quest 9: Mobs (Sorcerer)", NPC = "QuestNPC9", Target = "Sorcerer", Type = "Mob"}, {Name = "Quest 10: Mobs (Panda Sorcerer)", NPC = "QuestNPC10", Target = "PandaMiniBoss", Type = "Boss"}},
        ["Hueco Mundo"] = {{Name = "Quest 11: Mobs (Hollow)", NPC = "QuestNPC11", Target = "Hollow", Type = "Mob"}},
        ["Shinjuku"] = {{Name = "Quest 12: Mobs", NPC = "QuestNPC12", Target = "StrongSorcerer", Type = "Mob"}, {Name = "Quest 13: Mobs", NPC = "QuestNPC13", Target = "Curse", Type = "Mob"}},
        ["Slime"] = {{Name = "Quest 14: Mobs (Slime)", NPC = "QuestNPC14", Target = "Slime", Type = "Mob"}},
        ["Academy"] = {{Name = "Quest 15: Mobs (Teacher)", NPC = "QuestNPC15", Target = "AcademyTeacher", Type = "Mob"}},
        ["Judgement"] = {{Name = "Quest 16: Mobs", NPC = "QuestNPC16", Target = "Swordsman", Type = "Mob"}},
        ["Soul Society"] = {{Name = "Quest 17: Mobs", NPC = "QuestNPC17", Target = "Quincy", Type = "Mob"}},
        ["Boss Island"] = {{Name = "Âncora de Ilha", NPC = "SummonBossNPC", Target = "Nenhum", Type = "Mob"}}
    }

    local QuestProgression = {
        { Island = "Starter", Quest = "Quest 1: Mobs (Thief)" }, { Island = "Starter", Quest = "Quest 2: Boss (Thief Boss)" },
        { Island = "Jungle", Quest = "Quest 3: Mobs (Monkey)" }, { Island = "Jungle", Quest = "Quest 4: Boss (Monkey Boss)" },
        { Island = "Desert", Quest = "Quest 5: Mobs (Bandits)" }, { Island = "Desert", Quest = "Quest 6: Boss (Desert Boss)" },
        { Island = "Snow", Quest = "Quest 7: Mobs (Frost Rogue)" }, { Island = "Snow", Quest = "Quest 8: Boss (Snow Boss)" },
        { Island = "Shibuya", Quest = "Quest 9: Mobs (Sorcerer)" }, { Island = "Shibuya", Quest = "Quest 10: Mobs (Panda Sorcerer)" },
        { Island = "Hueco Mundo", Quest = "Quest 11: Mobs (Hollow)" }, { Island = "Shinjuku", Quest = "Quest 12: Mobs" },
        { Island = "Shinjuku", Quest = "Quest 13: Mobs" }, { Island = "Slime", Quest = "Quest 14: Mobs (Slime)" },
        { Island = "Academy", Quest = "Quest 15: Mobs (Teacher)" }, { Island = "Judgement", Quest = "Quest 16: Mobs" },
        { Island = "Soul Society", Quest = "Quest 17: Mobs" }
    }

    -- Processamento de Dados (Cruza a Progressão com os Detalhes do Mapa)
    self.OrderedQuests = {}
    self.DropdownOptions = {}

    for _, prog in ipairs(QuestProgression) do
        local islandData = QuestDataMap[prog.Island]
        if islandData then
            for _, q in ipairs(islandData) do
                if q.Name == prog.Quest then
                    local displayName = "[" .. prog.Island .. "] " .. q.Name
                    table.insert(self.DropdownOptions, displayName)
                    
                    self.OrderedQuests[displayName] = {
                        Island = prog.Island,
                        Name = q.Name,
                        NPC = q.NPC,
                        Target = q.Target,
                        Type = q.Type
                    }
                    break
                end
            end
        end
    end

    self.SelectedQuest = self.OrderedQuests[self.DropdownOptions[1]] -- Seleciona a primeira por padrão

    self.CombatRemote = pcall(function() return ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit") end) and ReplicatedStorage.CombatSystem.Remotes.RequestHit or nil
    self.AbilityRemote = pcall(function() return ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility") end) and ReplicatedStorage.AbilitySystem.Remotes.RequestAbility or nil
end

-- ========================================================================
-- ⚙️ LÓGICA DE DETECÇÃO
-- ========================================================================
function Module:IsQuestActive(targetName)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    local targetBase = targetName:lower():gsub("%s+", "")
    
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local currStr, maxStr = obj.Text:lower():match("(%d+)%s*/%s*(%d+)")
            if currStr and maxStr then
                local isVis, temp = true, obj
                while temp and temp:IsA("GuiObject") do
                    if not temp.Visible then isVis = false; break end
                    temp = temp.Parent
                end
                if isVis then
                    local screenGui = obj:FindFirstAncestorOfClass("ScreenGui")
                    if screenGui then
                        for _, relativeObj in ipairs(screenGui:GetDescendants()) do
                            if relativeObj:IsA("TextLabel") and relativeObj.Text:lower():gsub("%s+", ""):find(targetBase) then
                                return (tonumber(currStr) < tonumber(maxStr))
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

function Module:GetClosestMob(mobName)
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        local hum = npc:FindFirstChild("Humanoid")
        local npcBase = npc:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and npcBase and not npc:GetAttribute("IsTrainingDummy") then
            local cleanNpcName = npc.Name:gsub("%d+", ""):lower():gsub("%s+", "")
            local cleanTarget = mobName:lower():gsub("%s+", "")
            
            if cleanNpcName:find(cleanTarget) then
                local dist = (hrp.Position - npcBase.Position).Magnitude
                if dist < minDist then 
                    minDist = dist
                    closest = npc 
                end
            end
        end
    end
    return closest
end

function Module:EquipWeapon()
    local char = LP.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local backpack = LP:FindFirstChild("Backpack")
        if backpack then 
            tool = backpack:FindFirstChildOfClass("Tool")
            if tool then tool.Parent = char end 
        end
    end
end

-- ========================================================================
-- 🖥️ INTERFACE E LOOPS
-- ========================================================================
function Module:Start()
    local tabName = "Missões"
    
    UI:CreateSection(tabName, "Auto Quest Unitária")

    UI:CreateDropdown(tabName, "📜 " .. self.DropdownOptions[1], self.DropdownOptions, function(selected)
        self.SelectedQuest = self.OrderedQuests[selected]
    end)

    UI:CreateToggle(tabName, "Auto Quest Selecionada", function(state)
        self:Toggle(state)
    end)
end

function Module:StartFarm()
    self.IsRunning = true

    self.MoveLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or not self.SelectedQuest then continue end

            local qTarget = self.SelectedQuest.Target
            local qNPC = self.SelectedQuest.NPC
            local qIsland = self.SelectedQuest.Island

            if not self:IsQuestActive(qTarget) then
                self.FarmTarget = nil 
                local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
                local npc = serviceFolder and serviceFolder:FindFirstChild(qNPC)
                
                -- Se o NPC não existir, significa que estamos na ilha errada.
                if not npc then
                    print("🗺️ NPC não encontrado. Viajando para a ilha: " .. qIsland)
                    TeleportService:TeleportToIsland(qIsland)
                    task.wait(4) -- Aguarda o loading do mapa
                    continue
                end

                -- Se o NPC existir, voa até ele
                if npc:FindFirstChild("HumanoidRootPart") then
                    TeleportService:FlyToNPC(qNPC)
                    task.wait(0.2)
                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then 
                        fireproximityprompt(prompt)
                        task.wait(1.5) 
                    end
                end
            else
                -- Missão ativa! Procurar o mob
                if not self.FarmTarget or not self.FarmTarget:FindFirstChild("Humanoid") or self.FarmTarget.Humanoid.Health <= 0 then
                    self.FarmTarget = self:GetClosestMob(qTarget)
                end
                
                if self.FarmTarget then
                    local targetHrp = self.FarmTarget:FindFirstChild("HumanoidRootPart")
                    if targetHrp then
                        hum.PlatformStand = true
                        hrp.Velocity = Vector3.zero
                        
                        -- Voo Orbital em volta do Mob
                        self.OrbitAngle = self.OrbitAngle + math.rad(15)
                        local radius = 8
                        local height = 5
                        local pos = targetHrp.Position + Vector3.new(math.cos(self.OrbitAngle) * radius, height, math.sin(self.OrbitAngle) * radius)
                        
                        hrp.CFrame = CFrame.new(pos, targetHrp.Position)
                    end
                end
            end
        end
    end)

    self.AttackLoop = task.spawn(function()
        while self.IsRunning and task.wait(0.1) do
            if self.FarmTarget and self.FarmTarget:FindFirstChild("Humanoid") and self.FarmTarget.Humanoid.Health > 0 then
                self:EquipWeapon()
                if self.CombatRemote then pcall(function() self.CombatRemote:FireServer() end) end
                if self.AbilityRemote then for i = 1, 4 do pcall(function() self.AbilityRemote:FireServer(i) end) end end
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.MoveLoop then task.cancel(self.MoveLoop); self.MoveLoop = nil end
    if self.AttackLoop then task.cancel(self.AttackLoop); self.AttackLoop = nil end
    
    local char = LP.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    self.FarmTarget = nil
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module

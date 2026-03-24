-- ========================================================================
-- 📦 MÓDULO: NAVEGAÇÃO E TELEPORTE (UI + SERVIÇO GLOBAL)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local UI = Import("Ui/UI") 

local Module = {
    NoToggle = true -- Avisa o Main.lua para não criar o botão automático de Ligar/Desligar
}

function Module:Init()
    -- Lista em ordem para exibir na UI
    self.IslandsDisplay = {
        "Starter", "Jungle", "Desert", "Snow", "Sailor", "Shibuya Station", 
        "Hueco Mundo", "Boss Island", "Dungeon", "Shinjuku", "Slime", 
        "Academy", "Judgement", "Soul Society"
    }
    self.CurrentIslandIndex = 1

    -- Tradutor: Nome da UI -> Nome do Jogo
    self.TeleportMap = {
        ["Starter"] = "Starter", ["Jungle"] = "Jungle", ["Desert"] = "Desert",
        ["Snow"] = "Snow", ["Sailor"] = "Sailor", ["Shibuya Station"] = "Shibuya",
        ["Hueco Mundo"] = "HuecoMundo", ["Boss Island"] = "Boss", ["Dungeon"] = "Dungeon",
        ["Shinjuku"] = "Shinjuku", ["Slime"] = "Slime", ["Academy"] = "Academy",
        ["Judgement"] = "Judgement", ["Soul Society"] = "SoulSociety"
    }

    self.NpcList = {
        "GroupRewardNPC", "BossRushShopNPC", "BossRushPortalNPC", "DungeonMerchantNPC", 
        "EnchantNPC", "YujiBuyerNPC", "BlessingNPC", "SlimeCraftNPC", 
        "RimuruMasteryNPC", "SkillTreeNPC", "Katana", "MadokaBuyer", 
        "HakiQuestNPC", "SummonBossNPC"
    }
    self.CurrentNpcIndex = 1

    self.TeleportRemote = ReplicatedStorage:FindFirstChild("TeleportToPortal", true)
end

-- ========================================================================
-- 🚀 FUNÇÕES PÚBLICAS (Outros Módulos usarão isto!)
-- ========================================================================
function Module:FlyTo(targetPos)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if hrp and hum then
        local distance = (hrp.Position - targetPos).Magnitude
        local tempo = math.max(0.1, distance / 150) -- Velocidade de voo adaptável

        hum.PlatformStand = true
        hrp.Velocity = Vector3.zero

        local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
        tween:Play()
        tween.Completed:Wait()

        hum.PlatformStand = false
    end
end

function Module:FlyToNPC(npcName)
    local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
    local npc = serviceFolder and serviceFolder:FindFirstChild(npcName)
    
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        local pos = npc.HumanoidRootPart.Position + Vector3.new(0, 0, 5)
        self:FlyTo(pos)
        return true
    end
    return false
end

function Module:TeleportToIsland(displayName)
    if self.TeleportRemote then
        -- Traduz o nome da UI para o nome que o servidor entende
        local serverIslandName = self.TeleportMap[displayName]

        if serverIslandName then
            local char = LP.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end 
            
            pcall(function() self.TeleportRemote:FireServer(serverIslandName) end)
        else
            print("❌ Erro: Ilha não mapeada no tradutor: " .. tostring(displayName))
        end
    end
end

-- ========================================================================
-- 🖥️ CONSTRUÇÃO DA UI
-- ========================================================================
function Module:Start()
    local tabName = "Mundo & Teleporte"
    local container = UI.Tabs[tabName].Container

    -- --- SEÇÃO DE ILHAS ---
    UI:CreateSection(tabName, "Viagem Interdimensional")

    local islandBtn = Instance.new("TextButton")
    islandBtn.Size = UDim2.new(1, -10, 0, 35)
    islandBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    islandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    islandBtn.Font = Enum.Font.GothamBold
    islandBtn.TextSize = 13
    islandBtn.Text = "📍 Ilha: " .. self.IslandsDisplay[self.CurrentIslandIndex] .. " (Clique)"
    islandBtn.Parent = container
    Instance.new("UICorner", islandBtn).CornerRadius = UDim.new(0, 4)

    islandBtn.MouseButton1Click:Connect(function()
        self.CurrentIslandIndex = self.CurrentIslandIndex + 1
        if self.CurrentIslandIndex > #self.IslandsDisplay then self.CurrentIslandIndex = 1 end
        islandBtn.Text = "📍 Ilha: " .. self.IslandsDisplay[self.CurrentIslandIndex] .. " (Clique)"
    end)

    UI:CreateButton(tabName, "🔮 Teleportar", function()
        self:TeleportToIsland(self.IslandsDisplay[self.CurrentIslandIndex])
    end)

    -- --- SEÇÃO DE NPCS ---
    UI:CreateSection(tabName, "Localizador de Serviços")

    local npcBtn = Instance.new("TextButton")
    npcBtn.Size = UDim2.new(1, -10, 0, 35)
    npcBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 100)
    npcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    npcBtn.Font = Enum.Font.GothamBold
    npcBtn.TextSize = 13
    npcBtn.Text = "👤 NPC: " .. self.NpcList[self.CurrentNpcIndex] .. " (Clique)"
    npcBtn.Parent = container
    Instance.new("UICorner", npcBtn).CornerRadius = UDim.new(0, 4)

    npcBtn.MouseButton1Click:Connect(function()
        self.CurrentNpcIndex = self.CurrentNpcIndex + 1
        if self.CurrentNpcIndex > #self.NpcList then self.CurrentNpcIndex = 1 end
        npcBtn.Text = "👤 NPC: " .. self.NpcList[self.CurrentNpcIndex] .. " (Clique)"
    end)

    UI:CreateButton(tabName, "✈️ Voar até NPC", function()
        self:FlyToNPC(self.NpcList[self.CurrentNpcIndex])
    end)
end

function Module:Stop() end
function Module:Toggle(state) end

return Module

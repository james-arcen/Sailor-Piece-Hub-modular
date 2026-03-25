-- ========================================================================
-- 🛏️ SERVIÇO: GERENCIADOR DE SPAWN (CRISTAIS)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local TeleportService = Import("Services/Teleport")

local SpawnService = {
    SpawnSetado = false
}

-- 🔍 Busca cirúrgica pelo cristal de spawn mais próximo
function SpawnService:GetClosestSpawn()
    local closest = nil
    local minDist = math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end

    -- Como o formato é Workspace.Ilha.SpawnPointCrystal_Nome
    for _, islandFolder in ipairs(Workspace:GetChildren()) do
        local potentialSpawns = {}

        -- Se o cristal estiver solto direto no Workspace
        if islandFolder.Name:find("SpawnPointCrystal") then
            table.insert(potentialSpawns, islandFolder)
        -- Se estiver dentro da pasta/model da ilha (ex: StarterIsland)
        elseif islandFolder:IsA("Folder") or islandFolder:IsA("Model") then
            for _, child in ipairs(islandFolder:GetChildren()) do
                if child.Name:find("SpawnPointCrystal") then
                    table.insert(potentialSpawns, child)
                end
            end
        end

        -- Calcula a distância de todos os cristais encontrados
        for _, obj in ipairs(potentialSpawns) do
            -- O objeto pode ser uma Part direta ou um Model com parts dentro
            local objPos = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            
            if objPos then
                local dist = (hrp.Position - objPos.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = obj
                end
            end
        end
    end

    return closest
end

-- 🏃‍♂️ Vai até o cristal e interage
function SpawnService:SetSpawn()
    if self.SpawnSetado then return true end

    local spawnObj = self:GetClosestSpawn()
    if not spawnObj then
        -- Se não achar o cristal, não trava o script, apenas avisa
        return false 
    end

    local targetPart = spawnObj:IsA("BasePart") and spawnObj or spawnObj:FindFirstChildWhichIsA("BasePart", true)

    if targetPart then
        -- 1. Voa até o cristal (parando um pouco acima dele para não bugar no chão)
        TeleportService:FlyTo(targetPart.Position + Vector3.new(0, 3, 0))
        task.wait(0.5)

        -- 2. Procura o botão de interação (ProximityPrompt) dentro do cristal
        local prompt = spawnObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(1) -- Dá um tempinho pro servidor salvar seu spawn
            
            self.SpawnSetado = true
            print("✅ Spawn salvo no cristal: " .. spawnObj.Name)
            return true
        end
    end

    return false
end

-- 🔄 Chamado pelo Teleport.lua quando o jogador muda de ilha
function SpawnService:Reset()
    self.SpawnSetado = false
    print("🔄 Mudança de Ilha detectada. Spawn resetado para 'Não Setado'.")
end

return SpawnService

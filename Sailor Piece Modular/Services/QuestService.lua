-- ========================================================================
-- 👁️ SERVIÇO: QUEST SERVICE (LEITOR DE INTERFACE BLINDADO)
-- ========================================================================
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local QuestService = {}

function QuestService:GetQuestContainer()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    
    local questUI = pg:FindFirstChild("QuestUI")
    local q1 = questUI and questUI:FindFirstChild("Quest")
    local q2 = q1 and q1:FindFirstChild("Quest")
    local holder = q2 and q2:FindFirstChild("Holder")
    local content = holder and holder:FindFirstChild("Content")
    
    if content and content.Visible then return content end
    return nil
end

function QuestService:HasAnyQuest()
    local container = self:GetQuestContainer()
    if not container then return false end
    
    local questInfo = container:FindFirstChild("QuestInfo")
    local req = questInfo and questInfo:FindFirstChild("QuestRequirement")
    
    if req and req:IsA("TextLabel") then
        local rawText = (req.ContentText ~= "" and req.ContentText) or req.Text
        if rawText:match("%d+%s*/%s*%d+") then
            return true
        end
    end
    return false
end

function QuestService:IsTracking(targetName)
    local container = self:GetQuestContainer()
    if not container then return false end
    
    local cleanTarget = targetName:gsub("%s+", ""):lower()
    
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local rawText = (obj.ContentText ~= "" and obj.ContentText) or obj.Text
            if rawText and rawText ~= "" then
                local cleanText = rawText:gsub("%s+", ""):lower()
                
                if cleanText:find(cleanTarget, 1, true) or rawText:find(targetName, 1, true) then
                    return true 
                end
            end
        end
    end
    return false
end

function QuestService:IsQuestCompleted()
    local container = self:GetQuestContainer()
    if not container then return false end
    
    local questInfo = container:FindFirstChild("QuestInfo")
    local req = questInfo and questInfo:FindFirstChild("QuestRequirement")
    
    if req and req:IsA("TextLabel") then
        local rawText = (req.ContentText ~= "" and req.ContentText) or req.Text
        local currStr, maxStr = rawText:match("(%d+)%s*/%s*(%d+)")
        if currStr and maxStr then
            return tonumber(currStr) >= tonumber(maxStr)
        end
    end
    return false
end

return QuestService

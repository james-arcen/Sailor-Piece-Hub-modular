-- ========================================================================
-- 🌟 SAILOR PIECE PROFESSIONAL HUB - CORE & UI BASE (ETAPAS 1, 2 e 3)
-- ========================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ========================================================================
-- 📁 TABELAS DE ARQUITETURA (ETAPA 1)
-- ========================================================================
local Config = {
    HubName = "Sailor Piece Hub Pro",
    Version = "1.0.0",
    State = {}
}

local Services = {}
local Modules = {}
local UI = {
    Tabs = {},
    ActiveTab = nil
}
local Core = {}

-- ========================================================================
-- ⚙️ SISTEMA DE REGISTRO NO CORE (ETAPA 1)
-- ========================================================================
function Core:RegisterService(name, serviceTable)
    Services[name] = serviceTable
    print("[Core] Serviço registrado: " .. name)
end

function Core:RegisterModule(name, category, moduleTable)
    assert(type(moduleTable.Init) == "function", "Módulo " .. name .. " sem função Init()")
    assert(type(moduleTable.Start) == "function", "Módulo " .. name .. " sem função Start()")
    assert(type(moduleTable.Stop) == "function", "Módulo " .. name .. " sem função Stop()")
    assert(type(moduleTable.Toggle) == "function", "Módulo " .. name .. " sem função Toggle()")

    moduleTable.Name = name
    moduleTable.Category = category
    Modules[name] = moduleTable
    Config.State[name] = false 

    print("[Core] Módulo registrado: [" .. category .. "] " .. name)
end

-- ========================================================================
-- 🖥️ CONSTRUÇÃO DA INTERFACE - UI (ETAPA 2)
-- ========================================================================
function UI:Init(ModulesList, HubConfig)
    print("[UI] Construindo Interface...")

    local uiName = "SailorPieceHubPro_UI"
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild(uiName) then 
        uiParent[uiName]:Destroy() 
    end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = uiName
    self.ScreenGui.Parent = uiParent

    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 550, 0, 380)
    self.MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 8)

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    topBar.Parent = self.MainFrame
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = HubConfig.HubName .. " v" .. HubConfig.Version
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    self.Sidebar = Instance.new("ScrollingFrame")
    self.Sidebar.Size = UDim2.new(0, 130, 1, -50)
    self.Sidebar.Position = UDim2.new(0, 10, 0, 45)
    self.Sidebar.BackgroundTransparency = 1
    self.Sidebar.ScrollBarThickness = 2
    self.Sidebar.Parent = self.MainFrame
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.Parent = self.Sidebar

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -155, 1, -50)
    self.ContentArea.Position = UDim2.new(0, 145, 0, 45)
    self.ContentArea.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.ContentArea.Parent = self.MainFrame
    Instance.new("UICorner", self.ContentArea).CornerRadius = UDim.new(0, 8)
end

function UI:CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -5, 0, 32)
    tabBtn.Text = name
    tabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 13
    tabBtn.Parent = self.Sidebar
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, -10, 1, -10)
    tabContainer.Position = UDim2.new(0, 5, 0, 5)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 3
    tabContainer.Visible = false
    tabContainer.Parent = self.ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = tabContainer

    self.Tabs[name] = { Button = tabBtn, Container = tabContainer }

    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    if not self.ActiveTab then
        self:SelectTab(name)
    end

    return tabContainer
end

function UI:SelectTab(tabName)
    self.ActiveTab = tabName
    for name, data in pairs(self.Tabs) do
        if name == tabName then
            data.Button.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
            data.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            data.Container.Visible = true
        else
            data.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            data.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
            data.Container.Visible = false
        end
    end
end

-- ========================================================================
-- 🛠️ CONSTRUTORES DE ELEMENTOS (ETAPA 3)
-- ========================================================================
function UI:CreateToggle(tabName, text, callback)
    local container = self.Tabs[tabName].Container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -10, 0, 35)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.Text = text .. ": OFF"
    toggleBtn.Parent = container
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

    local state = false
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.Text = text .. ": " .. (state and "ON" or "OFF")
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(50, 150, 80) or Color3.fromRGB(40, 40, 50)
        
        if callback then callback(state) end
    end)
end

function UI:CreateButton(tabName, text, callback)
    local container = self.Tabs[tabName].Container
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        local oldColor = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(100, 130, 230)
        task.delay(0.1, function() btn.BackgroundColor3 = oldColor end)
        if callback then callback() end
    end)
end

function UI:CreateSection(tabName, text)
    local container = self.Tabs[tabName].Container
    
    local sectionLbl = Instance.new("TextLabel")
    sectionLbl.Size = UDim2.new(1, -10, 0, 25)
    sectionLbl.BackgroundTransparency = 1
    sectionLbl.TextColor3 = Color3.fromRGB(150, 150, 255)
    sectionLbl.Font = Enum.Font.GothamBlack
    sectionLbl.TextSize = 14
    sectionLbl.Text = "--- " .. string.upper(text) .. " ---"
    sectionLbl.Parent = container
end

function UI:Start()
    self:CreateTab("Farm & Nível")
    self:CreateTab("Missões")
    self:CreateTab("Chefes (Boss)")
    self:CreateTab("Mundo & Teleporte")
    self:CreateTab("Gacha & Itens")
    self:CreateTab("Misc & Config")
    print("[UI] Sistema de Abas carregado.")
end

-- ========================================================================
-- 🚀 SISTEMA DE INICIALIZAÇÃO (ETAPA 1)
-- ========================================================================
function Core:Init()
    print("Iniciando " .. Config.HubName .. " v" .. Config.Version .. "...")
    
    for _, service in pairs(Services) do
        if type(service.Init) == "function" then service:Init() end
    end

    for _, module in pairs(Modules) do
        module:Init()
    end

    UI:Init(Modules, Config)
end

function Core:Start()
    UI:Start()
    
    -- Gera os Toggles automaticamente para cada módulo registrado
    for name, module in pairs(Modules) do
        UI:CreateToggle(module.Category, name, function(state)
            module:Toggle(state)
        end)
    end
    
    print("🚀 Hub pronto para uso!")
end

-- ========================================================================
-- 🏁 INÍCIO DA EXECUÇÃO
-- ========================================================================
Core:Init()
Core:Start()
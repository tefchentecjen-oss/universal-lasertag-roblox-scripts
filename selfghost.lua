print(string.rep("=", 40))
print("🔮 ЗАПУСК СИСТЕМЫ СЛЕДУЮЩИХ ПРИЗРАКОВ v1.0 [MY GHOST TRAIL] 🔮")
print("-> Фиолетовый фантом в точности повторяет твои движения с задержкой в 1 сек!")
print(string.rep("=", 40))

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- НАСТРОЙКИ СТИЛЯ И ЗАДЕРЖКИ ПРИЗРАКА
-- =================================================================
local DELAY_TIME = 0.5           -- Задержка следования призрака (в секундах)
local GHOST_COLOR = Color3.fromRGB(180, 0, 255) -- Фиолетовый неоновый цвет
local GHOST_TRANSPARENCY = 0.65  -- Прозрачность твоего двойника

-- Буфер для хранения истории движений деталей тела
local positionBuffer = {}
local ghostModel = nil
local ghostParts = {}

-- Функция создания каркаса призрака на клиенте (вызывается один раз)
local function createGhostSkeleton(character)
    if ghostModel then ghostModel:Destroy() end
    ghostParts = {}
    
    ghostModel = Instance.new("Model")
    ghostModel.Name = "MadiumMyGhostTrail"
    ghostModel.Parent = Workspace
    
    -- Собираем кости твоего персонажа в один прозрачный неоновый слой
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local ghostPart = Instance.new("Part")
            ghostPart.Name = part.Name
            ghostPart.Size = part.Size
            ghostPart.Color = GHOST_COLOR
            ghostPart.Material = Enum.Material.Neon
            ghostPart.Transparency = GHOST_TRANSPARENCY
            
            -- Отключаем физику, чтобы призрак не падал и не застревал в стенах
            ghostPart.Anchored = true
            ghostPart.CanCollide = false
            ghostPart.CanTouch = false
            ghostPart.CanQuery = false
            ghostPart.CastShadow = false
            
            ghostPart.Parent = ghostModel
            ghostParts[part.Name] = ghostPart
        end
    end
    
    -- Добавляем сквозную обводку Chams
    local highlight = Instance.new("Highlight")
    highlight.Name = "TrailHighlight"
    highlight.FillTransparency = 1 -- Оставляем видимой только структуру неоновых партов
    highlight.OutlineColor = GHOST_COLOR
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ghostModel
end

-- Основной цикл записи координат и рендеринга призрачного следа
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        if ghostModel then ghostModel:Destroy() ghostModel = nil end
        return 
    end
    
    -- Если модель призрака еще не создана или персонаж обновился — собираем каркас
    if not ghostModel or #ghostModel:GetChildren() == 0 then
        createGhostSkeleton(character)
    end
    
    -- 1. ЗАПИСЬ ТЕКУЩЕГО КАДРА В БУФЕР
    local currentFrameData = {}
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            currentFrameData[part.Name] = part.CFrame
        end
    end
    
    -- Добавляем данные кадра вместе с временной меткой в конец очереди
    table.insert(positionBuffer, {
        Timestamp = os.clock(),
        Transforms = currentFrameData
    })
    
    -- 2. ПОИСК КАДРА С ЗАДЕРЖКОЙ ИЗ ИСТОРИИ
    local targetTime = os.clock() - DELAY_TIME
    local delayedFrame = nil
    
    -- Бежим по истории и ищем кадр, ближайший к секундной задержке
    while #positionBuffer > 0 and positionBuffer[1].Timestamp < targetTime do
        delayedFrame = positionBuffer[1]
        table.remove(positionBuffer, 1) -- Удаляем слишком старые кадры, чтобы не забивать память
    end
    
    -- Если нужный кадр из прошлого найден — плавно обновляем координаты призрака
    if delayedFrame then
        for partName, savedCFrame in pairs(delayedFrame.Transforms) do
            local ghostPart = ghostParts[partName]
            if ghostPart and ghostPart.Parent then
                ghostPart.CFrame = savedCFrame
                ghostPart.Transparency = GHOST_TRANSPARENCY -- Удерживаем видимость структуры
            end
        end
    end
end)

-- Сброс буфера при смерти или респавне
LocalPlayer.CharacterAdded:Connect(function(char)
    positionBuffer = {}
    task.wait(0.5)
    createGhostSkeleton(char)
end)

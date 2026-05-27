print(string.rep("=", 40))
print("🎯 ЗАПУСК ПИКСЕЛЬНЫХ ЧЕРНО-БЕЛЫХ ХИТМАРКЕРОВ v2.0 🎯")
print("-> Чистый Drawing API без BillboardGui. Тряска и сдвиги устранены!")
print("-> Маленький, пиксельный, черно-белый прицел в 3D мире.")
print(string.rep("=", 40))

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local hpCache = {}
local activeHitmarkers = {} -- Список всех живых хитмаркеров в мире

-- =================================================================
-- ⚙️ НАСТРОЙКИ СТИЛЯ ЧЕРНО-БЕЛОГО ПИКСЕЛЬНОГО ПРИЦЕЛА
-- =================================================================
local LINE_LENGTH = 6           -- Палочки стали ПОМЕНЬШЕ (всего 6 пикселей)
local CENTRAL_GAP = 2           -- Минимальный пиксельный отступ от центра
local LINE_THICKNESS = 1        -- Идеальная жесткая пиксельная толщина в 1 пиксель
local DISPLAY_DURATION = 0.3    -- Сколько секунд крестик висит на враге
local FADE_SPEED = 3.5          -- Скорость плавного растворения в конце

-- Функция сборки одной жесткой линии через Drawing API (без сглаживания)
local function createPixelLine()
    local line = Drawing.new("Line")
    line.Thickness = LINE_THICKNESS
    line.Color = Color3.fromRGB(255, 255, 255) -- Внутренний цвет — БЕЛЫЙ
    line.Transparency = 1
    line.Visible = false
    return line
end

-- Функция спавна нового черно-белого прицела по 3D-координатам
local function spawnPixelWorldHitmarker(worldPosition)
    local hitmarkerData = {
        WorldPos = worldPosition,
        SpawnTime = os.clock(),
        Transparency = 1,
        Lines = {},
        Outlines = {} -- Черная обводка для создания классического контрастного стиля
    }
    
    -- Создаем 4 белые палочки и 4 черные обводки для пиксельного контраста
    for i = 1, 4 do
        hitmarkerData.Lines[i] = createPixelLine()
        
        local outline = Drawing.new("Line")
        outline.Thickness = LINE_THICKNESS + 2 -- Обводка чуть толще, чтобы оборачивать белый пиксель
        outline.Color = Color3.fromRGB(0, 0, 0) -- Внешний цвет — ЧЕРНЫЙ
        outline.Transparency = 1
        outline.Visible = false
        hitmarkerData.Outlines[i] = outline
    end
    
    table.insert(activeHitmarkers, hitmarkerData)
end

-- =================================================================
-- ОСНОВНОЙ ЦИКЛ ОБРАБОТКИ ФИЗИКИ И ОТРИСОВКИ
-- =================================================================
RunService.RenderStepped:Connect(function()
    local activeCamera = Workspace.CurrentCamera or Camera
    if not activeCamera then return end
    
    local currentTime = os.clock()
    local silentData = getgenv().MadiumSilentData
    
    -- --- 1. СКАНИРОВАНИЕ ПОПАДАНИЙ ПО ВРАГАМ ---
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and head then
                local currentHp = humanoid.Health
                
                if hpCache[player] == nil then hpCache[player] = currentHp end
                
                if currentHp < hpCache[player] and currentHp > 0 then
                    local isSilentTarget = silentData and silentData.TargetName == player.Name
                    local isCloseRange = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 40
                    
                    if isSilentTarget or isCloseRange then
                        -- Фиксируем точную 3D точку попадания (например, голову врага)
                        spawnPixelWorldHitmarker(head.Position)
                    end
                end
                hpCache[player] = currentHp
            end
        end
    end
    
    -- --- 2. ЖЕСТКАЯ ДИНАМИЧЕСКАЯ ОТРИСОВКА В 3D МИРЕ ЧЕРЕЗ 2D ВЕКТОРЫ ---
    for index = #activeHitmarkers, 1, -1 do
        local data = activeHitmarkers[index]
        local elapsed = currentTime - data.SpawnTime
        
        if elapsed >= (DISPLAY_DURATION + 0.3) then
            -- Время жизни полностью вышло — стираем линии и очищаем оперативку
            for i = 1, 4 do
                data.Lines[i]:Destroy()
                data.Outlines[i]:Destroy()
            end
            table.remove(activeHitmarkers, index)
        else
            -- Математика затухания Fade Out
            if elapsed > DISPLAY_DURATION then
                data.Transparency = data.Transparency - (RunService.RenderStepped:Wait() * FADE_SPEED)
                if data.Transparency < 0 then data.Transparency = 0 end
            end
            
            -- Переводим 3D точку мира в 2D пиксели твоего монитора
            local screenPos, onScreen = activeCamera:WorldToViewportPoint(data.WorldPos)
            
            if onScreen and data.Transparency > 0 then
                local center = Vector2.new(screenPos.X, screenPos.Y)
                
                -- Направления осей крестика прицела: Лево, Право, Верх, Низ
                local directions = {
                    Vector2.new(-1, 0), -- Лево
                    Vector2.new(1, 0),  -- Право
                    Vector2.new(0, -1), -- Верх
                    Vector2.new(0, 1)   -- Низ
                }
                
                for i = 1, 4 do
                    local dir = directions[i]
                    
                    -- Сначала прорисовываем ЧЕРНЫЙ пиксельный контур (задний слой)
                    local outLine = data.Outlines[i]
                    outLine.From = center + (dir * (CENTRAL_GAP - 1))
                    outLine.To = center + (dir * (CENTRAL_GAP + LINE_LENGTH + 1))
                    outLine.Transparency = data.Transparency
                    outLine.Visible = true
                    
                    -- Поверх него накладываем БЕЛЫЙ пиксельный прицел (передний слой)
                    local whiteLine = data.Lines[i]
                    whiteLine.From = center + (dir * CENTRAL_GAP)
                    whiteLine.To = center + (dir * (CENTRAL_GAP + LINE_LENGTH))
                    whiteLine.Transparency = data.Transparency
                    whiteLine.Visible = true
                end
            else
                -- Если враг зашел за твою спину или прозрачность упала до 0
                for i = 1, 4 do
                    data.Lines[i].Visible = false
                    data.Outlines[i].Visible = false
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    hpCache[player] = nil
end)

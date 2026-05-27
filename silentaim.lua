print(string.rep("=", 40))
print("🎯 ЗАПУСК SILENT AIM v6.0 [ANIME SPEED LINES EDITION] 🎯")
print("-> Добавлен процедурный эффект линий скорости (Speed Lines) по краям.")
print("-> Добавлен агрессивный FOV-толчок камеры при попадании.")
print(string.rep("=", 40))

getgenv().MadiumSilentData = {
    TargetHumanoid = nil,
    TargetHeadPosition = nil,
    TargetName = ""
}

local PlayersService = game:GetService("Players")
local WorkspaceService = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = PlayersService.LocalPlayer
local Camera = WorkspaceService.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChildOfClass("PlayerGui")

local isAuraShooting = false
local MAX_DISTANCE = 500 
local lastClick = 0
local CLICK_DELAY = 0.02 

local triggerHitEffect = false

-- =================================================================
-- СОЗДАНИЕ ИНТЕРФЕЙСА ЛИНИЙ СКОРОСТИ (SPEED LINES GUI)
-- =================================================================
if PlayerGui:FindFirstChild("SpeedLinesGui") then
    PlayerGui.SpeedLinesGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedLinesGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local LinesContainer = Instance.new("Frame")
LinesContainer.Size = UDim2.new(1, 0, 1, 0)
LinesContainer.BackgroundTransparency = 1
LinesContainer.Parent = ScreenGui

-- Генерируем 24 линии по кругу экрана, направленные к центру
local speedLines = {}
local NUM_LINES = 24

for i = 1, NUM_LINES do
    local angle = (i / NUM_LINES) * math.pi * 2
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Цвет линий (можно сделать красным/синим)
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 1 -- Скрыты по дефолту
    line.Parent = LinesContainer
    
    -- Запоминаем угол и саму линию для анимации
    table.insert(speedLines, {Instance = line, Angle = angle})
end

-- Функция обновления позиций линий при изменении размера экрана
local function updateLinesLayout()
    local screenWidth = ScreenGui.AbsoluteSize.X
    local screenHeight = ScreenGui.AbsoluteSize.Y
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    local radius = math.max(centerX, centerY) -- Выносим линии за границы экрана

    for _, data in ipairs(speedLines) do
        local cos = math.cos(data.Angle)
        local sin = math.sin(data.Angle)
        
        -- Позиция линии на внешнем радиусе
        local startX = centerX + cos * radius
        local startY = centerY + sin * radius
        
        data.Instance.Position = UDim2.new(0, startX, 0, startY)
        -- Поворачиваем линию строго к центру экрана
        data.Instance.Rotation = math.deg(data.Angle) + 90
    end
end

ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLinesLayout)
updateLinesLayout()

-- =================================================================
-- СОЧНАЯ АНИМАЦИЯ ЭФФЕКТА СКОРОСТИ
-- =================================================================
local function playSpeedLinesEffect()
    local screenWidth = ScreenGui.AbsoluteSize.X
    local screenHeight = ScreenGui.AbsoluteSize.Y
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    local radius = math.max(centerX, centerY)
    
    local originalFOV = Camera.FieldOfView

    -- 1. FOV-ТОЛЧОК (Камера резко зумится/сжимается вперед, создавая динамику отдачи)
    Camera.FieldOfView = originalFOV - 12
    TweenService:Create(Camera, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {FieldOfView = originalFOV}):Play()

    -- 2. ВЫЛЕТ ЛИНИЙ (Линии сужаются к центру и становятся видимыми)
    for _, data in ipairs(speedLines) do
        local cos = math.cos(data.Angle)
        local sin = math.sin(data.Angle)
        
        -- Случайная длина и толщина для хаотичности гоночного эффекта
        local length = math.random(150, 350)
        local width = math.random(2, 5)
        
        data.Instance.Size = UDim2.new(0, width, 0, length)
        data.Instance.BackgroundTransparency = math.random(1, 4) / 10 -- Полупрозрачность для стиля
        
        -- Внутренняя точка, куда летит линия (ближе к центру)
        local targetX = centerX + cos * (radius * 0.4)
        local targetY = centerY + sin * (radius * 0.4)
        
        -- Анимация движения линии к центру и её исчезновение
        local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local moveTween = TweenService:Create(data.Instance, tweenInfo, {
            Position = UDim2.new(0, targetX, 0, targetY),
            BackgroundTransparency = 1
        })
        
        moveTween:Play()
    end
    
    -- Сбрасываем позиции линий обратно за экран после завершения
    task.delay(0.13, updateLinesLayout)
end

-- Безопасный триггер в основном потоке игры
RunService.Heartbeat:Connect(function()
    if triggerHitEffect then
        triggerHitEffect = false
        playSpeedLinesEffect()
    end
end)

-- Функция проверки прямой видимости (LoS)
local function isPlayerVisible(targetCharacter, myRootPart)
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not targetHead then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {
        LocalPlayer.Character,
        targetCharacter,
        WorkspaceService.CurrentCamera
    }
    
    local origin = myRootPart.Position
    local direction = (targetHead.Position - origin)
    local rayResult = WorkspaceService:Raycast(origin, direction, raycastParams)
    
    return rayResult == nil
end

-- =================================================================
-- ПОТОК 1: ДИНАМИЧЕСКИЙ СКАНЕР И УМНЫЙ АВТО-КЛИКЕР
-- =================================================================
RunService.RenderStepped:Connect(function()
    local closestPlayer = nil
    local shortestDistance = MAX_DISTANCE
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if isAuraShooting then
            isAuraShooting = false
            mouse1release()
        end
        return
    end
    
    local myRoot = LocalPlayer.Character.HumanoidRootPart
    local myPos = myRoot.Position
    
    for _, player in ipairs(PlayersService:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChildOfClass("Humanoid") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            local isTeammate = false
            if player.Team and LocalPlayer.Team then
                if player.Team == LocalPlayer.Team then isTeammate = true end
            elseif player:FindFirstChild("TeamColor") and LocalPlayer:FindFirstChild("TeamColor") then
                if player.TeamColor == LocalPlayer.TeamColor then isTeammate = true end
            end
            
            if humanoid.Health > 0 and not isTeammate then
                local enemyPos = player.Character.Head.Position
                local distance = (enemyPos - myPos).Magnitude
                
                if distance < shortestDistance then
                    if isPlayerVisible(player.Character, myRoot) then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
        getgenv().MadiumSilentData.TargetHumanoid = closestPlayer.Character:FindFirstChildOfClass("Humanoid")
        getgenv().MadiumSilentData.TargetHeadPosition = closestPlayer.Character.Head.Position
        getgenv().MadiumSilentData.TargetName = closestPlayer.Name
        
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            if tick() - lastClick > CLICK_DELAY then
                lastClick = tick()
                isAuraShooting = true
                task.spawn(function()
                    mouse1press()
                    task.wait(0.01)
                    mouse1release()
                end)
            end
        end
    else
        getgenv().MadiumSilentData.TargetHumanoid = nil
        getgenv().MadiumSilentData.TargetHeadPosition = nil
        getgenv().MadiumSilentData.TargetName = ""
        
        if isAuraShooting then
            isAuraShooting = false
            mouse1release()
        end
    end
end)

-- =================================================================
-- ПОТОК 2: СВЕРХБЫСТРЫЙ СЕТЕВОЙ ПОДМЕНЩИК
-- =================================================================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" and self.Name == "Shoot" and not checkcaller() then
        local args = {...}
        local targetHeadPos = getgenv().MadiumSilentData.TargetHeadPosition
        local targetHumanoid = getgenv().MadiumSilentData.TargetHumanoid
        
        if targetHeadPos and targetHumanoid then
            local origCFrame = args[3]
            
            if typeof(origCFrame) == "CFrame" then
                local myPosition = origCFrame.Position
                local silentCFrame = CFrame.new(myPosition, targetHeadPos)
                args[3] = silentCFrame
                args[4] = {["1"] = targetHumanoid}
                
                -- Триггерим эффект вылета линий скорости
                triggerHitEffect = true
                
                return oldNamecall(self, unpack(args))
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

print("Эффект Speed Lines успешно активирован!")
print(string.rep("=", 40))

print(string.rep("=", 40))
print("🔮 ЗАПУСК HIT LOGS v5.0 [RAINBOW GHOST CHAMS] 🔮")
print("-> Внедрена плавная анимация переливания цветов (Color Shift).")
print("-> Прозрачность зафиксирована и настроена для четких деталей тела.")
print(string.rep("=", 40))

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local hpCache = {}

local FUNNY_MESSAGES = {
    "походу сегодня не его день...",
    "отправился в канаву!",
    "минус кабина, отдыхай",
    "удаляй игру, бро, без шансов",
    "серверная валидация не спасла!",
    "Madium Hub на связи, сынок",
    "помянем бедолагу..."
}

-- =================================================================
-- ⚙️ НАСТРОЙКИ ПРОЗРАЧНОСТИ И АНИМАЦИИ (ПОДСТРОЙ ПОД СЕБЯ)
-- =================================================================
local GHOST_BASE_TRANSPARENCY = 0.6 -- НАСТОЯЩАЯ ПРОЗРАЧНОСТЬ ПАРТОВ (0.0 = плотный, 1.0 = невидимый)
local GHOST_DURATION = 1.5          -- Сколько секунд призрак переливается перед исчезновением
local COLOR_SHIFT_SPEED = 4         -- Скорость переливания цветов (чем выше цифра, тем быстрее)
local FLOAT_SPEED = 2               -- Скорость плавного взлета вверх
local FADE_DURATION = 0.4           -- Скорость финального растворения

-- =================================================================
-- ГЕНЕРАЦИЯ ПЕРЕЛИВАЮЩЕГОСЯ АНИМИРОВАННОГО ПРИЗРАКА
-- =================================================================
local function spawnRainbowGhost(targetCharacter)
    if not targetCharacter then return end
    
    local ghostModel = Instance.new("Model")
    ghostModel.Name = "MadiumRainbowGhost"
    ghostModel.Parent = Workspace
    
    local partsList = {}
    
    -- Собираем кости персонажа строго в ОДИН прозрачный слой
    for _, part in ipairs(targetCharacter:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local ghostPart = Instance.new("Part")
            ghostPart.Name = part.Name
            ghostPart.Size = part.Size
            ghostPart.CFrame = part.CFrame
            ghostPart.Material = Enum.Material.Neon -- Чистый неон, но сбалансированный прозрачностью
            ghostPart.Transparency = GHOST_BASE_TRANSPARENCY -- Жестко задаем прозрачность из настроек
            
            ghostPart.Anchored = true
            ghostPart.CanCollide = false
            ghostPart.CanTouch = false
            ghostPart.CanQuery = false
            ghostPart.CastShadow = false
            
            ghostPart.Parent = ghostModel
            
            table.insert(partsList, {
                Part = ghostPart,
                LocalOffset = targetCharacter.HumanoidRootPart.CFrame:ToObjectSpace(part.CFrame)
            })
        end
    end
    
    -- Сквозной Chams-контур, подстраивающийся под прозрачность
    local highlight = Instance.new("Highlight")
    highlight.Name = "GhostHighlight"
    highlight.FillTransparency = 1 -- Полностью отключаем внутреннюю заливку хайлайта, чтобы видеть структуру партов!
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ghostModel
    
    local startTime = os.clock()
    local centerPosition = targetCharacter.HumanoidRootPart.Position
    
    -- Цикл RenderStepped для плавной анимации переливания цветов и левитации
    local animConnection
    animConnection = RunService.RenderStepped:Connect(function()
        local elapsed = os.clock() - startTime
        
        if elapsed >= GHOST_DURATION then
            animConnection:Disconnect()
            return
        end
        
        -- Математика радужного переливания (рассчитываем RGB от времени)
        local hue = (os.clock() * (COLOR_SHIFT_SPEED / 10)) % 1
        local rainbowColor = Color3.fromHSV(hue, 0.8, 1) -- Плавный цветовой сдвиг
        
        -- Обновляем обводку Chams под текущий цвет радуги
        highlight.OutlineColor = rainbowColor
        
        local currentHeight = elapsed * FLOAT_SPEED
        
        for _, data in ipairs(partsList) do
            if data.Part and data.Part.Parent then
                -- Плавный взлет вверх по оси Y
                local animatedCenter = CFrame.new(centerPosition + Vector3.new(0, currentHeight, 0))
                data.Part.CFrame = animatedCenter * data.LocalOffset
                
                -- Жестко удерживаем базовую прозрачность партa, меняя только цвет
                data.Part.Color = rainbowColor
                data.Part.Transparency = GHOST_BASE_TRANSPARENCY
            end
        end
    end)
    
    -- ПЛАВНЫЙ FADE OUT ПО ИСТЕЧЕНИИ ВРЕМЕНИ
    task.spawn(function()
        task.wait(GHOST_DURATION)
        if animConnection.Connected then animConnection:Disconnect() end
        
        local tweenInfo = TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        for _, data in ipairs(partsList) do
            if data.Part and data.Part.Parent then
                -- Плавно растворяем парты до полной невидимости (1.0), сохраняя их размер, чтобы не портить структуру
                TweenService:Create(data.Part, tweenInfo, {Transparency = 1}):Play()
            end
        end
        
        local highlightTween = TweenService:Create(highlight, tweenInfo, {OutlineTransparency = 1})
        highlightTween:Play()
        highlightTween.Completed:Connect(function()
            ghostModel:Destroy() -- Очищаем память Workspace
        end)
    end)
end

-- =================================================================
-- ИНТЕРФЕЙС И МОНИТОРИНГ ХП ПО ЦЕНТРУ
-- =================================================================
local LogScreenGui = Instance.new("ScreenGui")
LogScreenGui.Name = "MadiumCenterHitLogsUI"
if syn and syn.protect_gui then syn.protect_gui(LogScreenGui) end
LogScreenGui.Parent = CoreGui

local LogContainer = Instance.new("Frame")
LogContainer.Name = "LogContainer"
LogContainer.Size = UDim2.new(0, 500, 0, 300) 
LogContainer.Position = UDim2.new(0.5, -250, 0.5, 50) 
LogContainer.BackgroundTransparency = 1
LogContainer.Parent = LogScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = LogContainer

local function createHitLogMessage(enemyName, damageValue, positionVector)
    local randomPhrase = FUNNY_MESSAGES[math.random(1, #FUNNY_MESSAGES)]
    local posX = math.floor(positionVector.X)
    local posY = math.floor(positionVector.Y)
    local posZ = math.floor(positionVector.Z)
    
    local logLabel = Instance.new("TextLabel")
    logLabel.Size = UDim2.new(1, 0, 0, 40) 
    logLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    logLabel.BackgroundTransparency = 0.15 
    logLabel.BorderSizePixel = 0
    logLabel.RichText = true
    logLabel.Text = string.format(
        "  💥 [<font color='rgb(0, 255, 150)'>HIT</font>] <b>%s</b>  |  Урон: <font color='rgb(255, 60, 60)'>-%d</font>  |  XYZ: (%d, %d, %d)  ->  <i>%s</i>",
        enemyName, damageValue, posX, posY, posZ, randomPhrase
    )
    logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    logLabel.Font = Enum.Font.SourceSansBold
    logLabel.TextSize = 15 
    logLabel.TextXAlignment = Enum.TextXAlignment.Center 
    logLabel.Parent = LogContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6) 
    corner.Parent = logLabel
    
    logLabel.TextTransparency = 1
    logLabel.BackgroundTransparency = 1
    
    TweenService:Create(logLabel, TweenInfo.new(0.12), {TextTransparency = 0, BackgroundTransparency = 0.15}):Play()
    
    task.spawn(function()
        task.wait(3.0)
        local fadeTween = TweenService:Create(logLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
            BackgroundTransparency = 1
        })
        fadeTween:Play()
        fadeTween.Completed:Connect(function()
            logLabel:Destroy()
        end)
    end)
end

game:GetService("RunService").RenderStepped:Connect(function()
    local silentData = getgenv().MadiumSilentData
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and head then
                local currentHp = humanoid.Health
                
                if hpCache[player] == nil then
                    hpCache[player] = currentHp
                end
                
                if currentHp < hpCache[player] and currentHp > 0 then
                    local damageDealt = hpCache[player] - currentHp
                    local isSilentTarget = silentData and silentData.TargetName == player.Name
                    
                    if isSilentTarget or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 40) then
                        -- Вызываем нашего нового переливающегося радужного призрака
                        pcall(function()
                            spawnRainbowGhost(player.Character)
                        end)
                        
                        pcall(function()
                            createHitLogMessage(player.Name, damageDealt, head.Position)
                        end)
                    end
                 end
                
                hpCache[player] = currentHp
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    hpCache[player] = nil
end)

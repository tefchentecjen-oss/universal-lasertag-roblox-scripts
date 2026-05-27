print(string.rep("=", 40))
print("🎥 ЗАПУСК THIRD PERSON v11.0 [PINK NEON ARMS] 🎥")
print("-> Вьюмодели безопасно переносятся в папку без Destroy.")
print("-> РУКИ СТАЛИ ЯРКО-РОЗОВЫМИ НЕОНОВЫМИ!")
print("-> Нажмите английскую 'K' для переключения.")
print(string.rep("=", 40))

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local thirdPersonActive = false
local DISTANCE_BACK = 12
local DISTANCE_UP = 2.5

-- Цвета для неоновых розовых рук
local PINK_ARM_COLOR = Color3.fromRGB(255, 20, 147) -- Ярко-розовый
local PINK_GLOW_COLOR = Color3.fromRGB(255, 105, 180) -- Светло-розовый для свечения
local PINK_OUTLINE_COLOR = Color3.fromRGB(255, 0, 128) -- Насыщенно-розовый для контура

-- Создаем папку-хранилище
local storageFolder = ReplicatedStorage:FindFirstChild("ViewModelStorage")
if not storageFolder then
    storageFolder = Instance.new("Folder")
    storageFolder.Name = "ViewModelStorage"
    storageFolder.Parent = ReplicatedStorage
end

-- =================================================================
-- ФУНКЦИЯ ОКРАШИВАНИЯ РУК В РОЗОВЫЙ НЕОН
-- =================================================================
local function makeArmsPink(model)
    -- Подсветка всей модели
    local highlight = model:FindFirstChild("PinkArmHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "PinkArmHighlight"
        highlight.Parent = model
    end
    highlight.Enabled = true
    highlight.FillColor = PINK_GLOW_COLOR
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = PINK_OUTLINE_COLOR
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Окрашиваем каждый BasePart в розовый
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Color = PINK_ARM_COLOR
            part.Material = Enum.Material.Neon -- Неоновый материал для свечения
            
            -- Добавляем свечение через ParticleEmitter на крупные части
            if part.Size.Magnitude > 1 and not part:FindFirstChild("PinkGlow") then
                local glow = Instance.new("ParticleEmitter")
                glow.Name = "PinkGlow"
                glow.Texture = "rbxassetid://284205746" -- Текстура свечения
                glow.Color = ColorSequence.new(PINK_GLOW_COLOR)
                glow.Size = NumberSequence.new(0.3)
                glow.Lifetime = NumberRange.new(0.5, 1)
                glow.Rate = 20
                glow.Speed = NumberRange.new(0.5, 1)
                glow.SpreadAngle = Vector2.new(10, 20)
                glow.Transparency = NumberSequence.new(0.5, 0.8)
                glow.LightEmission = 1
                glow.LightInfluence = 1
                glow.Parent = part
            end
        end
        
        -- Окрашиваем MeshPart
        if part:IsA("MeshPart") then
            part.Color = PINK_ARM_COLOR
            part.Material = Enum.Material.Neon
        end
        
        -- Окрашиваем Decal/Texture
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Color3 = PINK_ARM_COLOR
            part.Transparency = 0.3
        end
    end
    
    -- Добавляем неоновую ауру через BillboardGui
    local aura = model:FindFirstChild("PinkAura")
    if not aura then
        aura = Instance.new("BillboardGui")
        aura.Name = "PinkAura"
        aura.Size = UDim2.new(2, 0, 2, 0)
        aura.AlwaysOnTop = true
        aura.LightInfluence = 0
        aura.Parent = model
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = PINK_GLOW_COLOR
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 0
        frame.Parent = aura
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
        
        -- Анимация пульсации ауры
        task.spawn(function()
            while aura and aura.Parent do
                for i = 0, 1, 0.05 do
                    if not aura or not aura.Parent then break end
                    frame.BackgroundTransparency = 0.7 - (math.sin(i * math.pi) * 0.3)
                    task.wait(0.05)
                end
            end
        end)
    end
end

-- Функция возврата оригинальных цветов
local function resetArmsColor(model)
    -- Убираем подсветку
    local highlight = model:FindFirstChild("PinkArmHighlight")
    if highlight then
        highlight:Destroy()
    end
    
    -- Убираем ауру
    local aura = model:FindFirstChild("PinkAura")
    if aura then
        aura:Destroy()
    end
    
    -- Убираем партиклы
    for _, part in ipairs(model:GetDescendants()) do
        local glow = part:FindFirstChild("PinkGlow")
        if glow then
            glow:Destroy()
        end
    end
end

-- =================================================================
-- 1. ЖЕСТКИЙ ХУК МЕТАМЕТОДОВ ДЛЯ ПОЛНОЙ РАЗБЛОКИРОВКИ МЫШКИ
-- =================================================================
local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if not checkcaller() and thirdPersonActive then
        if self == UserInputService and key == "MouseBehavior" then
            return oldNewIndex(self, key, Enum.MouseBehavior.Default)
        end
        if self == UserInputService and key == "MouseIconEnabled" then
            return oldNewIndex(self, key, true)
        end
    end
    return oldNewIndex(self, key, value)
end)

-- =================================================================
-- 2. ОТСЛЕЖИВАНИЕ НАЖАТИЯ КЛАВИШИ K И БЕЗОПАСНЫЙ ВОЗВРАТ В КАМЕРУ
-- =================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.K then
        thirdPersonActive = not thirdPersonActive
        Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
        
        if thirdPersonActive then
            UserInputService.MouseIconEnabled = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        else
            -- Возврат в дефолтное первое лицо шутера
            LocalPlayer.CameraMaxZoomDistance = 0.5
            LocalPlayer.CameraMinZoomDistance = 0.5
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            
            -- ВОЗВРАЩАЕМ ВЬЮМОДЕЛИ ИЗ ПАПКИ В КАМЕРУ И УБИРАЕМ РОЗОВЫЙ ЦВЕТ
            if Camera then
                for _, savedObj in ipairs(storageFolder:GetChildren()) do
                    pcall(function()
                        resetArmsColor(savedObj) -- Убираем розовый цвет
                        savedObj:PivotTo(Camera.CFrame)
                        savedObj.Parent = Camera
                    end)
                end
            end
        end
    end
end)

-- =================================================================
-- 3. ЦИКЛ ДИНАМИЧЕСКОГО ПЕРЕНОСА ВЬЮМОДЕЛЕЙ И УПРАВЛЕНИЯ ОБЗОРОМ
-- =================================================================
RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    
    if not thirdPersonActive then return end
    
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    -- ХИТРЫЙ ПЕРЕНОС: Вместо Destroy меняем Parent на нашу папку
    if Camera then
        for _, obj in ipairs(Camera:GetChildren()) do
            if obj:IsA("Model") and (obj.Name == "Blaster" or obj.Name == "AutoBlaster" or obj:FindFirstChild("LeftArm") or obj:FindFirstChild("RightArm")) then
                pcall(function()
                    makeArmsPink(obj) -- ДЕЛАЕМ РУКИ РОЗОВЫМИ!
                    obj.Parent = storageFolder
                end)
            end
        end
    end
    
    -- Убираем копии, если игра спавнит их в Workspace
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and (obj.Name == "Blaster" or obj.Name == "AutoBlaster") then
            pcall(function()
                obj.Parent = storageFolder
            end)
        end
    end
    
    -- Применяем розовый цвет к моделям в хранилище
    for _, model in ipairs(storageFolder:GetChildren()) do
        if model:IsA("Model") then
            pcall(function()
                makeArmsPink(model)
            end)
        end
    end
    
    -- Физически отодвигаем камеру за спину через умножение CFrame
    local char = LocalPlayer.Character
    if Camera and char and char:FindFirstChild("HumanoidRootPart") then
        if Camera.CameraType ~= Enum.CameraType.Custom then 
            Camera.CameraType = Enum.CameraType.Custom 
        end
        Camera.CFrame = Camera.CFrame * CFrame.new(0, DISTANCE_UP, DISTANCE_BACK)
    end
    
    -- Проявляем тело реального персонажа
    if char then
        LocalPlayer.CameraMaxZoomDistance = 20
        LocalPlayer.CameraMinZoomDistance = 3
        
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not part:IsDescendantOf(Camera) then
                part.Transparency = 0
                part.LocalTransparencyModifier = 0 
            end
        end
    end
end)

print("Розовые неоновые руки активированы! Нажмите K для Third Person!")
print(string.rep("=", 40))

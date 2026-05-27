print(string.rep("=", 40))
print("🔮 ЗАПУСК CUSTOM PURPLE BULLET TRACERS v2.1 [FIXED] 🔮")
print("-> Fade Out полностью переписан без использования TweenService.")
print(string.rep("=", 40))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Загружаем оригинальный модуль отрисовки лучей в игре
local drawRayResultsModule = require(ReplicatedStorage.Blaster.Utility.drawRayResults)

-- Функция создания красивого фиолетового трейсера через Beam
local function createCustomPurpleBeam(startPos, endPos)
    local beamHolder = Instance.new("Part")
    beamHolder.Name = "MadiumBeamHolder"
    beamHolder.Size = Vector3.new(0, 0, 0)
    beamHolder.Transparency = 1
    beamHolder.Anchored = true
    beamHolder.CanCollide = false
    beamHolder.Position = startPos
    beamHolder.Parent = Workspace

    local attachStart = Instance.new("Attachment", beamHolder)
    attachStart.WorldPosition = startPos

    local attachEnd = Instance.new("Attachment", beamHolder)
    attachEnd.WorldPosition = endPos

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachStart
    beam.Attachment1 = attachEnd
    
    -- НАСТРОЙКИ СТИЛЯ И ЦВЕТА (Фиолетовый неон)
    beam.Color = ColorSequence.new(Color3.fromRGB(180, 0, 255)) 
    beam.Width0 = 0.12 -- Начальная толщина
    beam.Width1 = 0.12 -- Конечная толщина
    beam.FaceCamera = true 
    
    local currentTransparency = 0.3 -- Стартовая полупрозрачность
    beam.Transparency = NumberSequence.new(currentTransparency) 
    beam.LightEmission = 1 
    beam.Parent = beamHolder

    -- БЕЗОПАСНЫЙ И ПЛАВНЫЙ FADE OUT ЧЕРЕЗ ЦИКЛ НА КАЖДЫЙ КАДР
    task.spawn(function()
        task.wait(0.15) -- Время отображения линии перед растворением
        
        -- Плавно растворяем луч в воздухе
        while currentTransparency < 1 do
            -- Увеличиваем прозрачность на каждом кадре физики
            currentTransparency = currentTransparency + (RunService.RenderStepped:Wait() * 2.5) -- 2.5 задает скорость исчезновения
            
            if currentTransparency > 1 then 
                currentTransparency = 1 
            end
            
            -- Безопасно обновляем NumberSequence без вылетов TweenService
            pcall(function()
                beam.Transparency = NumberSequence.new(currentTransparency)
            end)
        end
        
        -- Полностью удаляем деталь-контейнер из Workspace, чтобы не засорять память
        beamHolder:Destroy()
    end)
end

-- Хукаем оригинальный модуль отрисовки
hookfunction(drawRayResultsModule, function(position, rayResults)
    local silentData = getgenv().MadiumSilentData
    local hasTarget = silentData and silentData.TargetHeadPosition ~= nil
    
    for _, rayResult in ipairs(rayResults) do
        local endPosition = rayResult.position
        
        if hasTarget then
            -- Перенаправляем визуальный фиолетовый луч в голову цели Silent Aim
            endPosition = silentData.TargetHeadPosition
        end
        
        -- Безопасно рисуем кастомную линию
        pcall(function()
            createCustomPurpleBeam(position, endPosition)
        end)
    end
end)

print("Трейсеры обновлены. Попробуйте пострелять — ошибок больше не будет!")
print(string.rep("=", 40))

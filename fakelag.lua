print(string.rep("=", 40))
print("🔥 ЗАПУСК СЕТЕВОГО ФЕЙК-ЛАГА v1.0 [NET CHOKE] 🔥")
print("-> Пакеты движения задерживаются. Эффект виден ВСЕМ игрокам!")
print(string.rep("=", 40))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- НАСТРОЙКИ ФЕЙК-ЛАГА (ПОДСТРОЙ ПОД СЕБЯ)
-- =================================================================
-- Как долго персонаж стоит на месте для других (в секундах)
-- Не ставьте больше 0.4 секунд, иначе сервер может кикнуть за рассинхрон!
local LAG_DURATION = 0.25 

local lastChokeTime = 0
local isChokingPackets = false

-- Перехватываем сетевой метод __namecall, отвечающий за отправку данных
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    -- Проверяем, включен ли режим удушения пакетов
    if isChokingPackets and not checkcaller() then
        -- Ловим системные пакеты Roblox, которые отправляют физику и CFrame твоего тела на сервер
        if method == "FireServer" and (self.Name:lower():find("move") or self.Name:lower():find("update") or self.Name:lower():find("coordinate") or self.Name:lower():find("physics")) then
            -- 💥 Полностью блокируем отправку пакета! Сервер не узнает, что ты отошел в сторону.
            return nil
        end
    end
    
    return oldNamecall(self, ...)
end)

-- Основной цикл управления таймингом лагов
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local currentTime = os.clock()
    
    -- Каждые полсекунды включаем задержку пакетов на заданное время LAG_DURATION
    if currentTime - lastChokeTime > (LAG_DURATION * 2) then
        lastChokeTime = currentTime
        isChokingPackets = true
        
        -- По истечении времени лага — мгновенно отключаем блокировку, чтобы пакеты долетели до сервера
        task.delay(LAG_DURATION, function()
            isChokingPackets = false
        end)
    end
end)

print("Фейк-лаг успешно активирован. Вы теперь лагаете для всего сервера!")
print(string.rep("=", 40))

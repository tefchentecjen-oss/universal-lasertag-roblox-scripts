print(string.rep("=", 40))
print("🔊 ЗАПУСК КАСТОМНОГО ХИТСАУНДА v1.0 [STABLE] 🔊")
print("-> Звук колокольчика будет срабатывать при каждом твоем попадании!")
print(string.rep("=", 40))

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

local hpCache = {}

-- =================================================================
-- НАСТРОЙКА ID ЗВУКА ПОПАДАНИЯ
-- =================================================================
-- Сейчас стоит классический сочный колокольчик (ID: 4684534123)
-- Ты можешь заменить этот ID на любой другой звук из библиотеки Roblox!
local CUSTOM_HIT_SOUND_ID = "rbxassetid://112506378296286" 
local HIT_VOLUME = 1.5 -- Громкость звука

-- Создаем локальный объект звука в памяти твоего UI
local hitSoundObject = Instance.new("Sound")
hitSoundObject.SoundId = CUSTOM_HIT_SOUND_ID
hitSoundObject.Volume = HIT_VOLUME
hitSoundObject.Parent = SoundService

-- Автономный сканер урона для мгновенного воспроизведения звука
game:GetService("RunService").RenderStepped:Connect(function()
    local silentData = getgenv().MadiumSilentData
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if humanoid then
                local currentHp = humanoid.Health
                
                if hpCache[player] == nil then
                    hpCache[player] = currentHp
                end
                
                -- Если враг получил урон
                if currentHp < hpCache[player] and currentHp > 0 then
                    -- Проверяем, что урон нанес именно ты через Сайлент Аим или вблизи
                    local isSilentTarget = silentData and silentData.TargetName == player.Name
                    local isCloseRange = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 40
                    
                    if isSilentTarget or isCloseRange then
                        -- Мгновенно воспроизводим наш кастомный хитсаунд!
                        pcall(function()
                            if hitSoundObject.IsPlaying then
                                hitSoundObject:Stop() -- Сбрасываем, чтобы звук мог быстро спамиться при частых попаданиях
                            end
                            hitSoundObject:Play()
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

print(string.rep("=", 40))
print("📦 ЗАПУСК MADIUM PREMIUM HUB v8.0 [INFINITE AMMO] 📦")
print("-> Клавиша 'HOME' — Открытие/Закрытие меню")
print(string.rep("=", 40))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Состояния функций из меню
local legitAimEnabled = false
local rapidFireEnabled = false
local infiniteAmmoEnabled = false
local noRecoilEnabled = false
local noCameraShakeEnabled = false
local espBoxEnabled = false
local espTracersEnabled = false
local espNamesEnabled = false
local chamsEnabled = false
local menuOpen = false

local espCache = {}

-- Загружаем константы вашей игры
local Constants = require(ReplicatedStorage.Blaster.Constants)

-- =================================================================
-- 1. ГРАФИЧЕСКИЙ ИНТЕРФЕЙС (МЕНЮ НА HOME)
-- =================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MadiumHubUI_v80"
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 515) -- Увеличили под новую кнопку
MainFrame.Position = UDim2.new(0.5, -200, 0.3, -257)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "   MADIUM PREMIUM HUB v8.0"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BorderSizePixel = 0
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local buttonCount = 0
local function createToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 360, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, 60 + (buttonCount * 48))
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = text .. ": ВЫКЛ"
    btn.TextColor3 = Color3.fromRGB(220, 60, 60)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 15
    btn.BorderSizePixel = 0
    btn.Parent = MainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            btn.Text = text .. ": ВКЛ"
            btn.TextColor3 = Color3.fromRGB(60, 220, 60)
        else
            btn.Text = text .. ": ВЫКЛ"
            btn.TextColor3 = Color3.fromRGB(220, 60, 60)
        end
        callback(enabled)
    end)
    buttonCount = buttonCount + 1
end

-- Кнопки управления хабом
createToggle("Legit Aim (Магнит прицела)", function(state) legitAimEnabled = state end)
createToggle("Rapid Fire (Супер скорострельность)", function(state) rapidFireEnabled = state end)
createToggle("Infinite Ammo (Мгновенный релод)", function(state) infiniteAmmoEnabled = state end)
createToggle("No Recoil (Отключение отдачи)", function(state) noRecoilEnabled = state end)
createToggle("No Camera Shake (Отключение тряски)", function(state) noCameraShakeEnabled = state end)
createToggle("2D Box ESP", function(state) espBoxEnabled = state end)
createToggle("Tracer ESP", function(state) espTracersEnabled = state end)
createToggle("Name & Distance ESP", function(state) espNamesEnabled = state end)
createToggle("Chams (Подсветка тел)", function(state) chamsEnabled = state end)

local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 0, 30)
Credits.Position = UDim2.new(0, 0, 1, -30)
Credits.BackgroundTransparency = 1
Credits.Text = "Клавиша HOME — открыть/закрыть интерфейс"
Credits.TextColor3 = Color3.fromRGB(130, 130, 130)
Credits.Font = Enum.Font.SourceSansItalic
Credits.TextSize = 14
Credits.Parent = MainFrame

-- =================================================================
-- 2. УПРАВЛЕНИЕ МЫШКОЙ И ОТКРЫТИЕ НА HOME
-- =================================================================
local function toggleMenu()
    menuOpen = not menuOpen
    MainFrame.Visible = menuOpen
    
    if menuOpen then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Home then toggleMenu() end
end)

RunService.RenderStepped:Connect(function()
    if menuOpen then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
end)

-- =================================================================
-- 3. МОДИФИКАЦИЯ ХАРАКТЕРИСТИК ОРУЖИЯ (RAPID & INVISIBLE RELOAD)
-- =================================================================
task.spawn(function()
    while true do
        if LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                -- Сверхскорострельность
                if rapidFireEnabled then
                    if tool:GetAttribute(Constants.RATE_OF_FIRE_ATTRIBUTE) then tool:SetAttribute(Constants.RATE_OF_FIRE_ATTRIBUTE, 99999) end
                    if tool:GetAttribute(Constants.FIRE_MODE_ATTRIBUTE) then tool:SetAttribute(Constants.FIRE_MODE_ATTRIBUTE, Constants.FIRE_MODE.AUTO) end
                end

                -- Бесконечные патроны через скручивание таймера перезарядки в 0 секунд!
                if infiniteAmmoEnabled then
                    if tool:GetAttribute(Constants.RELOAD_TIME_ATTRIBUTE) then 
                        tool:SetAttribute(Constants.RELOAD_TIME_ATTRIBUTE, 0) 
                    end
                end

                -- Снятие отдачи
                if noRecoilEnabled then
                    if tool:GetAttribute(Constants.RECOIL_MIN_ATTRIBUTE) then tool:SetAttribute(Constants.RECOIL_MIN_ATTRIBUTE, Vector2.new(0, 0)) end
                    if tool:GetAttribute(Constants.RECOIL_MAX_ATTRIBUTE) then tool:SetAttribute(Constants.RECOIL_MAX_ATTRIBUTE, Vector2.new(0, 0)) end
                end
                
                -- Легитный Аим
                if legitAimEnabled then
                    if tool:GetAttribute(Constants.AIM_ASSIST_RANGE_ATTRIBUTE) then tool:SetAttribute(Constants.AIM_ASSIST_RANGE_ATTRIBUTE, 9999) end
                    if tool:GetAttribute(Constants.AIM_ASSIST_FOV_ATTRIBUTE) then tool:SetAttribute(Constants.AIM_ASSIST_FOV_ATTRIBUTE, 180) end
                    if tool:GetAttribute(Constants.AIM_ASSIST_TRACKING_STRENGTH_ATTRIBUTE) then tool:SetAttribute(Constants.AIM_ASSIST_TRACKING_STRENGTH_ATTRIBUTE, 1) end
                    if tool:GetAttribute(Constants.AIM_ASSIST_CENTERING_STRENGTH_ATTRIBUTE) then tool:SetAttribute(Constants.AIM_ASSIST_CENTERING_STRENGTH_ATTRIBUTE, 1) end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- =================================================================
-- 4. ХУК ИНТЕРФЕЙСА ДЛЯ ПОЛНОГО ОТКЛЮЧЕНИЯ АНИМАЦИИ RE-LOAD
-- =================================================================
local GuiControllerModule = require(ReplicatedStorage.Blaster.Scripts.GuiController)
local oldSetReloading = GuiControllerModule.setReloading

-- Перехватываем функцию смены текста патронов на "---"
GuiControllerModule.setReloading = function(self, reloading)
    if infiniteAmmoEnabled then
        -- Если чит включен, принудительно запрещаем интерфейсу уходить в режим перезарядки
        return oldSetReloading(self, false)
    end
    return oldSetReloading(self, reloading)
end

-- Гасим тряску камеры
RunService.RenderStepped:Connect(function()
    if noCameraShakeEnabled then
        if Constants.RECOIL_BIND_NAME then pcall(function() RunService:UnbindFromRenderStep(Constants.RECOIL_BIND_NAME) end) end
        if Camera:FindFirstChild("CameraShake") then Camera.CameraShake:Destroy() end
    end
end)

-- =================================================================
-- 5. РЕАЛИЗАЦИЯ ADVANCED ESP (DRAWING API & CHAMS)
-- =================================================================
local function createDrawingObjects()
    local box = Drawing.new("Square"); box.Thickness = 1.5; box.Filled = false; box.Color = Color3.fromRGB(0, 255, 150); box.Visible = false
    local tracer = Drawing.new("Line"); tracer.Thickness = 1.5; tracer.Color = Color3.fromRGB(255, 200, 0); tracer.Visible = false
    local text = Drawing.new("Text"); text.Size = 14; text.Center = true; text.Outline = true; text.Color = Color3.fromRGB(255, 255, 255); text.Visible = false
    return {Box = box, Tracer = tracer, Text = text}
end

local function applyChams(character)
    local highlight = character:FindFirstChild("MadiumChams")
    if not highlight then highlight = Instance.new("Highlight", character); highlight.Name = "MadiumChams" end
    if chamsEnabled then
        highlight.Enabled = true; highlight.FillColor = Color3.fromRGB(0, 255, 150); highlight.FillTransparency = 0.4
        highlight.OutlineColor = Color3.fromRGB(0, 255, 255); highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    else highlight.Enabled = false end
end

RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not espCache[p] then
                espCache[p] = createDrawingObjects()
            end
            
            local drawings = espCache[p]
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and hrp and head and hum and hum.Health > 0 then
                local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                applyChams(char)

                if onScreen then
                    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local boxHeight = math.abs(headPos.Y - legPos.Y)
                    local boxWidth = boxHeight / 1.5

                    if espBoxEnabled then
                        drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
                        drawings.Box.Position = Vector2.new(hrpPos.X - boxWidth / 2, hrpPos.Y - boxHeight / 2)
                        drawings.Box.Visible = true
                    else
                        drawings.Box.Visible = false
                    end

                    if espTracersEnabled then
                        drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        drawings.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y + (boxHeight / 2))
                        drawings.Tracer.Visible = true
                    else
                        drawings.Tracer.Visible = false
                    end

                    if espNamesEnabled then
                        local distance = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0)
                        drawings.Text.Text = string.format("%s [%dm]", p.Name, distance)
                        drawings.Text.Position = Vector2.new(hrpPos.X, hrpPos.Y - (boxHeight / 2) - 18)
                        drawings.Text.Visible = true
                    else
                        drawings.Text.Visible = false
                    end
                else
                    -- Игрок за пределами экрана
                    drawings.Box.Visible = false
                    drawings.Tracer.Visible = false
                    drawings.Text.Visible = false
                end
            else
                -- Игрок мертв или отсутствует
                drawings.Box.Visible = false
                drawings.Tracer.Visible = false
                drawings.Text.Visible = false
                if char and char:FindFirstChild("MadiumChams") then
                    char.MadiumChams.Enabled = false
                end
            end
        end -- Закрывает условие if p ~= LocalPlayer
    end -- Закрывает цикл for
end) -- ТЕПЕРЬ ЦИКЛ RENDERSTEPPED ЗАКРЫТ ПРАВИЛЬНО!

-- Вызов открытия меню при инжекте
toggleMenu()

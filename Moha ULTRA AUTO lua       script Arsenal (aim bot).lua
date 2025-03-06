-- Script amélioré pour Der Hood avec Infinite Bullet, Aimbot amélioré, etc.
-- Fonctionnalités :
--   1. God Mode renforcé
--   2. ESP amélioré : boîte autour des joueurs + affichage du pseudo
--   3. Aimbot amélioré : vise le joueur le plus proche en excluant ceux qui sont KO,
--      dont la tête est trop basse, en dessous de la vôtre ou presque au niveau de leurs pieds.
--   4. Speed Modifier amélioré : touches X/Z pour boost/reset, C/V pour ajuster la vitesse
--   5. Infinite Bullet : réinitialise en continu l'ammo de vos outils

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local image = "rbxassetid://111201744721013"

local function sendNotification(title, text, duration, icon)
    StarterGui:SetCore("SendNotification", {
        Title = title; -- Titre de la notification
        Text = text; -- Texte de la notification
        Duration = duration; -- Durée en secondes
        Icon = icon or "https://cdn.discordapp.com/avatars/1223807225881956477/0b02158183f7fe2a07531ac746850796.png?size=2048?size=1024"; -- URL ou ID de l'image (facultatif)
    })
end
-- ==================================================================
--                      GOD MODE AMÉLIORÉ
-- ==================================================================

local function enforceGodMode(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge

        humanoid.HealthChanged:Connect(function(newHealth)
            if newHealth < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
        end)

        if character:FindFirstChild("Armor") then
            local armor = character.Armor
            armor.Value = math.huge
            armor.Changed:Connect(function(newVal)
                if newVal < math.huge then
                    armor.Value = math.huge
                end
            end)
        end
    end
end

if LocalPlayer.Character then
    enforceGodMode(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    enforceGodMode(character)
end)

-- ==================================================================
--                           ESP AMÉLIORÉ
-- ==================================================================

local espObjects = {}

local function createESP(player)
    if player == LocalPlayer then return end
    local esp = {}
    esp.box = Drawing.new("Square")
    esp.box.Color = Color3.new(0, 1, 0)
    esp.box.Thickness = 2
    esp.box.Filled = false
    esp.box.Transparency = 1

    esp.name = Drawing.new("Text")
    esp.name.Color = Color3.new(1, 1, 1)
    esp.name.Size = 15
    esp.name.Transparency = 1
    esp.name.Center = true
    esp.name.Outline = true

    espObjects[player] = esp

    RunService.RenderStepped:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            esp.box.Visible = false
            esp.name.Visible = false
            return
        end

        local character = player.Character
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if head and torso then
            local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
            local torsoPos, torsoOnScreen = Camera:WorldToViewportPoint(torso.Position)
            if headOnScreen and torsoOnScreen then
                local height = math.abs(headPos.Y - torsoPos.Y) * 2
                local width = height * 0.6

                esp.box.Size = Vector2.new(width, height)
                esp.box.Position = Vector2.new(torsoPos.X - width/2, headPos.Y - height/2)
                esp.box.Visible = true

                esp.name.Position = Vector2.new(torsoPos.X, headPos.Y - height/2 - 15)
                esp.name.Text = player.Name
                esp.name.Visible = true
            else
                esp.box.Visible = false
                esp.name.Visible = false
            end
        else
            esp.box.Visible = false
            esp.name.Visible = false
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end
Players.PlayerAdded:Connect(createESP)

-- ==================================================================
--                        AIMBOT AMÉLIORÉ
-- ==================================================================

local aimbotEnabled = true
local currentTarget = nil
local raycastParams = RaycastParams.new()
local holdingMouse = false

local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Configurer Raycast pour ignorer ton propre personnage
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if not aimbotEnabled then
        currentTarget = nil
        holdingMouse = false
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1) -- Relâcher la souris si c'était en train de tirer
        print("[AIMBOT] Désactivé")
        sendNotification(
        "Script",
        "[AIMBOT] Désactivé", 
        5, 
        image -- ID ou URL de l'image
    )
    else
        print("[AIMBOT] Activé")
        sendNotification(
        "Script",
        "[AIMBOT] Activé", 
        5, 
        image -- ID ou URL de l'image
    )
    end
end

-- Touche M pour activer/désactiver l'aimbot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        toggleAimbot()
    end
end)

-- Check si la cible est visible
local function isVisible(targetHead)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Head") then
        return false
    end

    local origin = character.Head.Position
    local direction = (targetHead.Position - origin).Unit * (targetHead.Position - origin).Magnitude

    local result = workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        if result.Instance:IsDescendantOf(targetHead.Parent) then
            return true
        else
            return false
        end
    end
    return true
end

-- Trouver l'ennemi visible le plus proche
local function getClosestVisibleEnemy()
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local localPos = localCharacter.HumanoidRootPart.Position
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            if LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team then
                continue
            end

            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = player.Character:FindFirstChild("Head")

                if isVisible(head) then
                    local distance = (player.Character.HumanoidRootPart.Position - localPos).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Maintien du clic gauche (tir continu)
local function startShooting()
    if not holdingMouse then
        holdingMouse = true
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1) -- Maintenir le clic gauche
    end
end

local function stopShooting()
    if holdingMouse then
        holdingMouse = false
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1) -- Relâcher le clic gauche
    end
end

-- Boucle principale aimbot + auto-shoot avec maintien de tir
game:GetService("RunService").RenderStepped:Connect(function()
    if not aimbotEnabled then
        stopShooting()
        return
    end

    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Head") then
        local head = currentTarget.Character:FindFirstChild("Head")
        local humanoid = currentTarget.Character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health > 0 and isVisible(head) then
            game.Workspace.CurrentCamera.CFrame = CFrame.new(game.Workspace.CurrentCamera.CFrame.Position, head.Position)
            startShooting()
        else
            currentTarget = nil
            stopShooting()
        end
    else
        currentTarget = getClosestVisibleEnemy()
        if not currentTarget then
            stopShooting()
        end
    end
end)


-- ==================================================================
--                     SPEED MODIFICATEUR AMÉLIORÉ
-- ==================================================================

local defaultSpeed = 16
local currentSpeed = defaultSpeed
local boostedSpeed = 50
local speedIncrement = 5

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    
    if input.KeyCode == Enum.KeyCode.X then
        humanoid.WalkSpeed = boostedSpeed
        currentSpeed = boostedSpeed
        Camera.CameraType = Enum.CameraType.Custom
    elseif input.KeyCode == Enum.KeyCode.Z then
        humanoid.WalkSpeed = defaultSpeed
        currentSpeed = defaultSpeed
        Camera.CameraType = Enum.CameraType.Custom
    elseif input.KeyCode == Enum.KeyCode.C then
        currentSpeed = currentSpeed + speedIncrement
        humanoid.WalkSpeed = currentSpeed
        Camera.CameraType = Enum.CameraType.Custom
    elseif input.KeyCode == Enum.KeyCode.V then
        currentSpeed = math.max(defaultSpeed, currentSpeed - speedIncrement)
        humanoid.WalkSpeed = currentSpeed
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

-- ==================================================================
--                     TP (TELEPORT) FUNCTIONNALITÉ
-- ==================================================================

function teleportToPlayer(targetName)
    local targetPlayer = Players:FindFirstChild(targetName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    end
end

-- ==================================================================
--                     INFINITE BULLET
-- ==================================================================

local function setInfiniteAmmo(tool)
    local ammo = tool:FindFirstChild("Ammo")
    if ammo and type(ammo.Value) == "number" then
        ammo.Value = math.huge
    end
end

local function infiniteBullet()
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                setInfiniteAmmo(tool)
            end
        end
    end
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                setInfiniteAmmo(tool)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    infiniteBullet()
end)

-- ==================================================================
--                     NOTIFICATION DE DÉMARRAGE
-- ==================================================================

sendNotification(
    "Script ",
    "God Mode, ESP, TP, Aimbot, Speed Modifier & Infinite Bullet activés.\nRMB pour Aimbot,\nX/Z pour boost/reset speed,\nC/V pour ajuster la vitesse. !", 
    15, 
    image -- ID ou URL de l'image
)
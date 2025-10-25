local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
if not player then return end

local PLACES = {
    GAME1 = 87152046708536,
    GAME2 = 987654321,
}

local function disableInputs()
    local blockedKeys = {
        Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
        Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
        Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift,
    }
    ContextActionService:BindAction("BlockAll", function() 
        return Enum.ContextActionResult.Sink 
    end, false, unpack(blockedKeys))
    local starterGui = game:GetService("StarterGui")
    pcall(function() starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Movement, false) end)
    pcall(function() starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Camera, false) end)
    pcall(function() starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false) end)
    pcall(function() starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true) end)
end

local function hideCharacter(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 1
            part.CanCollide = false
        end
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
    end
end

local function teleportToPlace(placeId)
    local success, err = pcall(function()
        TeleportService:Teleport(placeId, player)
    end)
    
    if not success then
        warn("Error al teleportar:", err)
    end
end

local function createLobbyUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LobbyUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true

    local musicName = "FondoM"
    local music = workspace:FindFirstChild(musicName)
    if not music then
        music = game:GetService("ReplicatedStorage"):FindFirstChild(musicName)
    end

    if music and music:IsA("Sound") then
        music.Looped = true
        music:Play()
    else
        warn("No se encontró el objeto Sound llamado: " .. musicName .. " o no es un Sound.")
    end

    local logoDecal = workspace:FindFirstChild("LogoGame")
    local logoId = logoDecal.Texture
    
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    background.BorderSizePixel = 0
    background.Parent = screenGui

    if #logoId > 0 then
        local logo = Instance.new("ImageLabel")
        logo.Name = "GameLogo"
        logo.Size = UDim2.new(0.3, 0, 0.3, 0)
        logo.Position = UDim2.new(0.35, 0, 0.25, 0)
        logo.BackgroundTransparency = 1
        logo.Image = logoId
        logo.Parent = background
    end
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.8, 0, 0.2, 0)
    title.Position = UDim2.new(0.1, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Text = "Escapa de Ronald Mikedonald"
    title.Parent = background
    
    local button1 = Instance.new("TextButton")
    button1.Name = "Map1Button"
    button1.Size = UDim2.new(0.4, 0, 0.1, 0)
    button1.Position = UDim2.new(0.3, 0, 0.4, 0)
    button1.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    button1.Font = Enum.Font.GothamSemibold
    button1.TextColor3 = Color3.new(1, 1, 1)
    button1.TextScaled = true
    button1.Text = "Jugar Primer Mapa"
    button1.Parent = background
    
    local button2 = Instance.new("TextButton")
    button2.Name = "Map2Button"
    button2.Size = UDim2.new(0.4, 0, 0.1, 0)
    button2.Position = UDim2.new(0.3, 0, 0.6, 0)
    button2.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
    button2.Font = Enum.Font.GothamSemibold
    button2.TextColor3 = Color3.new(1, 1, 1)
    button2.TextScaled = true
    button2.Text = "Jugar La Prisión"
    button2.Parent = background
    
    button1.MouseButton1Click:Connect(function()
        teleportToPlace(PLACES.GAME1)
    end)
    
    button2.MouseButton1Click:Connect(function()
        teleportToPlace(PLACES.GAME2)
    end)
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local function setupCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.new(0, 50, 0) * CFrame.Angles(-math.rad(90), 0, 0)
end

local function createSplash(logoId1, logoId2)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SplashScreen"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = screenGui

    local fullImage = Instance.new("ImageLabel")
    fullImage.Name = "FullImage"
    fullImage.Size = UDim2.new(0.6, 0, 0.6, 0)
    fullImage.Position = UDim2.new(0.5, 0, 0.37, 0)
    fullImage.AnchorPoint = Vector2.new(0.5, 0.5)
    fullImage.BackgroundTransparency = 1
    fullImage.ScaleType = Enum.ScaleType.Fit
    fullImage.Image = logoId1 or ""
    fullImage.ImageTransparency = 1
    fullImage.Parent = bg

    local presenta = Instance.new("TextLabel")
    presenta.Name = "Presenta"
    presenta.Size = UDim2.new(0.5, 0, 0, 36)
    presenta.Position = UDim2.new(0.5, 0, 0.82, 0)
    presenta.AnchorPoint = Vector2.new(0.5, 0)
    presenta.BackgroundTransparency = 1
    presenta.Text = "PRESENTA"
    presenta.TextColor3 = Color3.fromRGB(0, 255, 0)
    presenta.Font = Enum.Font.GothamBold
    presenta.TextScaled = true
    presenta.TextTransparency = 1
    presenta.Parent = bg

    local centerContainer = Instance.new("Frame")
    centerContainer.Name = "CenterContainer"
    centerContainer.Size = UDim2.new(0.9, 0, 0.12, 0)
    centerContainer.Position = UDim2.new(0.05, 0, 0.55, 0)
    centerContainer.BackgroundTransparency = 1
    centerContainer.Parent = bg
    centerContainer.Visible = false

    local midText = Instance.new("TextLabel")
    midText.Name = "MidText"
    midText.Size = UDim2.new(1, 0, 1, 0)
    midText.Position = UDim2.new(0, 0, 0, 0)
    midText.BackgroundTransparency = 1
    midText.Text = "EN COLABORACIÓN CON"
    midText.TextColor3 = Color3.fromRGB(173, 216, 230)
    midText.Font = Enum.Font.Gotham
    midText.TextScaled = true
    midText.TextTransparency = 1
    midText.TextStrokeTransparency = 0.8
    midText.Parent = centerContainer

    local function fadeInImage(img, duration)
        duration = duration or 0.6
        local steps = 12
        for i = 1, steps do
            img.ImageTransparency = 1 - (i / steps)
            task.wait(duration / steps)
        end
        img.ImageTransparency = 0
    end
    local function fadeOutImage(img, duration)
        duration = duration or 0.6
        local steps = 12
        for i = 1, steps do
            img.ImageTransparency = (i / steps)
            task.wait(duration / steps)
        end
        img.ImageTransparency = 1
    end
    local function fadeText(label, target, duration)
        duration = duration or 0.5
        local steps = 10
        local start = label.TextTransparency
        for i = 1, steps do
            label.TextTransparency = start + (target - start) * (i / steps)
            task.wait(duration / steps)
        end
        label.TextTransparency = target
    end

    local durationFull = 2.2
    local durationMiddle = 1.6

    fullImage.Image = logoId1 or ""
    fadeInImage(fullImage, 0.6)
    fadeText(presenta, 0, 0.6)
    task.wait(durationFull)

    centerContainer.Visible = true
    fadeOutImage(fullImage, 0.4)
    fadeText(midText, 0, 0.5)
    task.wait(durationMiddle)

    fadeText(midText, 1, 0.4)
    centerContainer.Visible = false

    fullImage.Image = logoId2 or ""
    fadeInImage(fullImage, 0.6)
    fadeText(presenta, 0, 0.25)
    task.wait(2.0)

    for i = 0, 1, 0.08 do
        bg.BackgroundTransparency = i
        fullImage.ImageTransparency = i
        task.wait(0.03)
    end
    screenGui:Destroy()
end

local function init()
    if player.Character then
        hideCharacter(player.Character)
    end
    player.CharacterAdded:Connect(hideCharacter)
    disableInputs()
    setupCamera()
    local logoPinguiDecal = workspace:FindFirstChild("LogoPinguin")
    local logoPinguin = logoPinguiDecal.Texture
    local logoCreaProDecal = workspace:FindFirstChild("LogoCreaPro")
    local logoCreaPro = logoCreaProDecal.Texture
    createSplash(logoPinguin, logoCreaPro)
    createLobbyUI()
end

init()
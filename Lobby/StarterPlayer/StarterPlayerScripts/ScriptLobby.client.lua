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
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BorderSizePixel = 0
    background.Parent = screenGui
    local imageDisplay = Instance.new("ImageLabel")
    imageDisplay.Name = "LogoGroups"
    imageDisplay.Size = UDim2.new(0.4, 0, 0.4, 0)
    imageDisplay.Position = UDim2.new(0.3, 0, 0.3, 0)
    imageDisplay.BackgroundTransparency = 1 
    imageDisplay.ScaleType = Enum.ScaleType.Fit
    imageDisplay.Parent = background
    screenGui.Parent = player:WaitForChild("PlayerGui")
    imageDisplay.Image = logo1Id
    imageDisplay.ImageTransparency = 0
    durationPerLogo = 3
    task.wait(durationPerLogo)
    for i = 0, 1, 0.1 do
        imageDisplay.ImageTransparency = i
        task.wait(0.05)
    end
    imageDisplay.Image = logo2Id
    imageDisplay.ImageTransparency = 1
    for i = 1, 0, -0.1 do
        imageDisplay.ImageTransparency = i
        task.wait(0.05)
    end
    task.wait(durationPerLogo)
    for i = 0, 1, 0.1 do
        imageDisplay.ImageTransparency = i
        background.BackgroundTransparency = i
        task.wait(0.05)
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
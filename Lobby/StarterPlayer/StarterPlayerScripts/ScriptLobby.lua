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
    
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
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
    button1.Text = "Jugar Mapa 1"
    button1.Parent = background
    
    local button2 = Instance.new("TextButton")
    button2.Name = "Map2Button"
    button2.Size = UDim2.new(0.4, 0, 0.1, 0)
    button2.Position = UDim2.new(0.3, 0, 0.6, 0)
    button2.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
    button2.Font = Enum.Font.GothamSemibold
    button2.TextColor3 = Color3.new(1, 1, 1)
    button2.TextScaled = true
    button2.Text = "Jugar Mapa 2"
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

local function init()
    if player.Character then
        hideCharacter(player.Character)
    end
    player.CharacterAdded:Connect(hideCharacter)
    
    disableInputs()
    setupCamera()
    createLobbyUI()
end

init()
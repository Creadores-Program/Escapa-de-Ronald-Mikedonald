local model = script.Parent

local function ensureModelForNPC(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Anchored = false
        end
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart

    if not hrp then
        local biggest, maxVol = nil, 0
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                local vol = p.Size.X * p.Size.Y * p.Size.Z
                if vol > maxVol then
                    biggest = p
                    maxVol = vol
                end
            end
        end
        if biggest then
            hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            hrp.CanCollide = false
            hrp.Anchored = false
            hrp.CFrame = biggest.CFrame
            hrp.Parent = model
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = hrp
            weld.Part1 = biggest
            weld.Parent = hrp
        end
    end

    if not humanoid and hrp then
        humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
    end

    if hrp and not model.PrimaryPart then
        model.PrimaryPart = hrp
    end

    return humanoid, hrp
end

local mikeDonaldPart = model
local humanoid, hrp = ensureModelForNPC(model)
if not humanoid or not hrp then
    warn("No se pudo preparar el modelo para NPC (falta Humanoid o HumanoidRootPart).")
    return
end
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local function getNearestPlayer()
    local nearestPlayer
    local nearestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local charHrp = char and char:FindFirstChild("HumanoidRootPart")
        if charHrp then
            local d = (hrp.Position - charHrp.Position).Magnitude
            if d < nearestDistance then
                nearestDistance = d
                nearestPlayer = player
            end
        end
    end
    return nearestPlayer, nearestDistance
end

spawn(function()
    while true do
        wait(0.5)
        local player = getNearestPlayer()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = player.Character.HumanoidRootPart.Position
            local path = PathfindingService:CreatePath()
            path:ComputeAsync(hrp.Position, targetPos)
            if path.Status == Enum.PathStatus.Success then
                for _, waypoint in ipairs(path:GetWaypoints()) do
                    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then break end
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                    humanoid:MoveTo(waypoint.Position)
                    local reached = humanoid.MoveToFinished:Wait()
                    if not reached then break end
                end
            else
                humanoid:MoveTo(targetPos)
                humanoid.MoveToFinished:Wait()
            end
        end
    end
end)
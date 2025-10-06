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
humanoid.WalkSpeed = 50
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

local lastAttackTimes = {}

local function canAttack(player)
    if not player then return false end
    local uid = player.UserId
    local now = tick()
    if lastAttackTimes[uid] and now - lastAttackTimes[uid] < 1 then
        return false
    end
    lastAttackTimes[uid] = now
    return true
end

local function attackPlayer(player)
    if not player or not player.Character then return end
    local targetHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not targetHumanoid or not targetHrp then return end
    if (hrp.Position - targetHrp.Position).Magnitude > 3 then
        return
    end
    if not canAttack(player) then return end

    if targetHumanoid.Health > 0 then
        targetHumanoid:TakeDamage(100)
    end
end

spawn(function()
    while true do
        wait(0.5)
        local player, dist = getNearestPlayer()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if dist and dist < 3 then
                attackPlayer(player)
                continue
            end
            if dist and dist < 200 then
                local targetPos = player.Character.HumanoidRootPart.Position
                local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
                local ok, err = pcall(function()
                    path:ComputeAsync(hrp.Position, targetPos)
                end)
                if not ok then
                    warn("Error computing path: " ..tostring(err))
                    humanoid:MoveTo(targetPos)
                    humanoid.MoveToFinished:Wait()
                    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        if (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude < 3 then
                            attackPlayer(player)
                        end
                    end
                    continue
                end
                if path.Status == Enum.PathStatus.Success then
                    for _, waypoint in ipairs(path:GetWaypoints()) do
                        if humanoid.Health <= 0 then return end
                        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then break end
                        local targetHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if targetHrp and (hrp.Position - targetHrp.Position).Magnitude < 3 then
                            attackPlayer(player)
                            break
                        end
                        if waypoint.Action == Enum.PathWaypointAction.Jump then
                            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end

                        humanoid:MoveTo(waypoint.Position)
                        local reached = humanoid.MoveToFinished:Wait()
                        if not reached then break end
                        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            if (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude < 3 then
                                attackPlayer(player)
                                break
                            end
                        end
                    end
                else
                    humanoid:MoveTo(targetPos)
                    humanoid.MoveToFinished:Wait()
                    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        if (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude < 3 then
                            attackPlayer(player)
                        end
                    end
                end
            end
        end
    end
end)
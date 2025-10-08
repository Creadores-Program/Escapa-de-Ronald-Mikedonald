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
pcall(function()
    if humanoid then
        humanoid.JumpHeight = 7
        humanoid.UseJumpPower = false
    end
end)

local function createFootstepSound()
    local FOOTSTEP_TEMPLATE_NAME = "stepsM"
    local ServerStorage = game:GetService("ServerStorage")
    local template = model:FindFirstChild(FOOTSTEP_TEMPLATE_NAME) or ServerStorage:FindFirstChild(FOOTSTEP_TEMPLATE_NAME) or workspace:FindFirstChild(FOOTSTEP_TEMPLATE_NAME)
    if template and template:IsA("Sound") then
        local s = template:Clone()
        s.Parent = hrp
        s.Volume = 1
        s.Looped = true
        return s
    end
end

local footstepSound = createFootstepSound()

local runningConn
runningConn = humanoid.Running:Connect(function(speed)
    if speed and speed > 0 then
        if footstepSound and not footstepSound.IsPlaying then
            footstepSound:Play()
        end
        if footstepSound then
            footstepSound.PlaybackSpeed = math.clamp(speed / 16, 0.6, 1.6)
        end
    else
        if footstepSound.IsPlaying then
            footstepSound:Stop()
        end
    end
end)
humanoid.Died:Connect(function()
    if footstepSound.IsPlaying then footstepSound:Stop() end
    if runningConn then runningConn:Disconnect() end
end)

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
    if (hrp.Position - targetHrp.Position).Magnitude > 7 then
        return
    end
    if not canAttack(player) then return end

    if targetHumanoid.Health > 0 then
        targetHumanoid:TakeDamage(100)
    end
end

local REPATH_INTERVAL = 0.5
local WAYPOINT_TIMEOUT = 1.2
local STUCK_DIST = 0.6
local GOAL_BUFFER = 2
local CHASE_MAX_DISTANCE = 250
local ATTACK_DISTANCE = 7

local function getOffsetTarget(hrpPos, targetPos)
    local dir = targetPos - hrpPos
    local mag = dir.Magnitude
    if mag < 0.5 then return targetPos end
    local offsetDist = math.clamp(GOAL_BUFFER, 0, mag - 0.5)
    return targetPos - dir.Unit * offsetDist
end

local WANDER_RADIUS = 60
local WANDER_POINT_REACH = 3
local WANDER_WAIT_MIN = 1.0
local WANDER_WAIT_MAX = 2.5

local initialWanderOrigin = hrp.Position

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = { model }
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function findGroundPosition(posAbove)
    local ray = workspace:Raycast(posAbove, Vector3.new(0, -200, 0), rayParams)
    if ray and ray.Position then
        return ray.Position + Vector3.new(0, 2, 0)
    end
    return nil
end

local function getRandomWanderPoint()
    for i = 1, 12 do
        local angle = math.random() * math.pi * 2
        local radius = math.random() * WANDER_RADIUS
        local candidateHigh = initialWanderOrigin + Vector3.new(math.cos(angle) * radius, 40, math.sin(angle) * radius)
        local groundPos = findGroundPosition(candidateHigh)
        if groundPos then
            return groundPos
        end
    end
    return initialWanderOrigin
end

local function followPlayerLoop()
    while humanoid and humanoid.Health > 0 do
        wait(REPATH_INTERVAL)

        local player, dist = getNearestPlayer()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and dist and dist <= CHASE_MAX_DISTANCE then
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not targetHrp then
                continue
            end

            if dist and dist <= ATTACK_DISTANCE then
                attackPlayer(player)
                continue
            end

            local aimPos = getOffsetTarget(hrp.Position, targetHrp.Position)
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentJumpHeight = 6.8,
                AgentMaxSlope = 60,
            })

            local ok, err = pcall(function()
                path:ComputeAsync(hrp.Position, aimPos)
            end)
            if not ok or path.Status ~= Enum.PathStatus.Success then
                humanoid:MoveTo(aimPos)
                local t0 = tick()
                local moved = false
                local before = hrp.Position
                while tick() - t0 < WAYPOINT_TIMEOUT do
                    wait(0.12)
                    if (hrp.Position - aimPos).Magnitude < 1.5 then
                        moved = true
                        break
                    end
                    if (hrp.Position - before).Magnitude > STUCK_DIST then
                        moved = true
                        break
                    end
                end
                if not moved then
                    humanoid.Jump = true
                    wait(0.35)
                    humanoid:MoveTo(aimPos)
                    wait(0.45)
                    if (hrp.Position - aimPos).Magnitude < 1.5 or (hrp.Position - before).Magnitude > STUCK_DIST then
                        moved = true
                    else
                        local dir = aimPos - hrp.Position
                        if dir.Magnitude > 0 then
                            local sidestep = hrp.Position + Vector3.new(-dir.Z, 0, dir.X).Unit * 2
                            humanoid:MoveTo(sidestep)
                            wait(0.35)
                        end
                    end
                end
                continue
            end

            local waypoints = path:GetWaypoints()
            for i, wp in ipairs(waypoints) do
                if humanoid.Health <= 0 then return end
                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then break end

                local wpPos = wp.Position
                if i == #waypoints then
                    wpPos = getOffsetTarget(hrp.Position, player.Character.HumanoidRootPart.Position)
                end

                if wp.Action == Enum.PathWaypointAction.Jump then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end

                local before = hrp.Position
                humanoid:MoveTo(wpPos)

                local t0 = tick()
                local reached = false
                while tick() - t0 < WAYPOINT_TIMEOUT do
                    wait(0.12)
                    if (hrp.Position - wpPos).Magnitude < 1.2 then
                        reached = true
                        break
                    end
                    if (hrp.Position - before).Magnitude > STUCK_DIST then
                        reached = true
                        break
                    end
                    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        if (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude <= ATTACK_DISTANCE then
                            attackPlayer(player)
                            reached = true
                            break
                        end
                    end
                end

                if not reached then
                    humanoid.Jump = true
                    wait(0.25)
                    humanoid:MoveTo(wpPos)
                    wait(0.45)
                    if (hrp.Position - wpPos).Magnitude > 1.2 or (hrp.Position - before).Magnitude < STUCK_DIST then
                        local lateral = (wpPos - hrp.Position)
                        if lateral.Magnitude > 0 then
                            local sidestep = hrp.Position + Vector3.new(-lateral.Z, 0, lateral.X).Unit * 2
                            humanoid:MoveTo(sidestep)
                            wait(0.35)
                        end
                        break
                    end
                end
            end

        else
            local wanderTarget = getRandomWanderPoint()
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
            })
            local ok, err = pcall(function()
                path:ComputeAsync(hrp.Position, wanderTarget)
            end)
            if not ok or path.Status ~= Enum.PathStatus.Success then
                humanoid:MoveTo(wanderTarget)
                local t0 = tick()
                local before = hrp.Position
                while tick() - t0 < WAYPOINT_TIMEOUT do
                    wait(0.12)
                    local ptemp, dtemp = getNearestPlayer()
                    if ptemp and dtemp and dtemp <= CHASE_MAX_DISTANCE then
                        break
                    end
                    if (hrp.Position - wanderTarget).Magnitude < WANDER_POINT_REACH then
                        break
                    end
                    if (hrp.Position - before).Magnitude > STUCK_DIST then
                        break
                    end
                end
            else
                local waypoints = path:GetWaypoints()
                for i, wp in ipairs(waypoints) do
                    if humanoid.Health <= 0 then return end
                    local ptemp, dtemp = getNearestPlayer()
                    if ptemp and dtemp and dtemp <= CHASE_MAX_DISTANCE then
                        break
                    end

                    local wpPos = wp.Position
                    if wp.Action == Enum.PathWaypointAction.Jump then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end

                    humanoid:MoveTo(wpPos)
                    local t0 = tick()
                    local movedTo = false
                    local before = hrp.Position
                    while tick() - t0 < WAYPOINT_TIMEOUT do
                        wait(0.12)
                        if (hrp.Position - wpPos).Magnitude < 1.2 then
                            movedTo = true
                            break
                        end
                        if (hrp.Position - before).Magnitude > STUCK_DIST then
                            movedTo = true
                            break
                        end
                        local pnow, dnow = getNearestPlayer()
                        if pnow and dnow and dnow <= CHASE_MAX_DISTANCE then
                            movedTo = true
                            break
                        end
                    end
                    if not movedTo then
                        humanoid.Jump = true
                        wait(0.3)
                        humanoid:MoveTo(wpPos)
                        wait(0.4)
                        if (hrp.Position - wpPos).Magnitude > 1.2 or (hrp.Position - before).Magnitude < STUCK_DIST then
                            local lateral = (wpPos - hrp.Position)
                            if lateral.Magnitude > 0 then
                                local sidestep = hrp.Position + Vector3.new(-lateral.Z, 0, lateral.X).Unit * 2
                                humanoid:MoveTo(sidestep)
                                wait(0.35)
                            end
                            break
                        end
                    end
                end
            end

            wait(math.random() * (WANDER_WAIT_MAX - WANDER_WAIT_MIN) + WANDER_WAIT_MIN)
        end
    end
end

spawn(followPlayerLoop)
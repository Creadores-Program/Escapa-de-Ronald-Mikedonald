local mikeDonaldPart = script.Parent
local humanoid = mikeDonaldPart:FindFirstChildOfClass("Humanoid")
local hrp = mikeDonaldPart:FindFirstChild("HumanoidRootPart")
if not humanoid or not hrp then return end
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
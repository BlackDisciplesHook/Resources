local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RenderStepped = RunService.RenderStepped

local Aimbot = {
    Config = {
        Enabled = false,
        Smoothness = 0.01,
        Aimpart = "Head",
        Method = "Camera",

        WallCheck = false,
        TeamCheck = false,
        InvisCheck = false,
        ForceFieldCheck = false,
    },

    FOVConfig = {
        Enabled = false,
        Visible = false,

        Color = Color3.new(1, 1, 1),
        NumSides = 60,
        Transparency = 1,
        Radius = 100,
        Thickness = 1,
        Filled = false
    },

    Locked = false,
    Connections = {},
    FOVCircle = Drawing.new("Circle"),
    FOVCircleOutline = Drawing.new("Circle"),
}

local function IsInRadius(position, radius)
    local MousePosition = UserInputService:GetMouseLocation()
    return (position - MousePosition).Magnitude <= radius
end

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
RaycastParams.IgnoreWater = true

local function Direction(origin, pos)
    return (pos - origin).Unit * 1000
end

function Aimbot.WallCheck(Part)
    if not Aimbot.Config.WallCheck then
        return true
    end

    if not Part or not Part.Parent then
        return false
    end

    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

    local RayResult = workspace:Raycast(Camera.CFrame.Position, Direction(Camera.CFrame.Position, Part.Position), RaycastParams)

    if RayResult then
        local HitPart = RayResult.Instance
        local HitCharacter = HitPart:FindFirstAncestorOfClass("Model")
        local TargetCharacter = Part:FindFirstAncestorOfClass("Model")
        return HitCharacter == TargetCharacter
    end

    return false
end

function Aimbot.IsVisible(Player)
    if not Aimbot.Config.InvisCheck then
        return true
    end

    return Player and Player.Character and Player.Character:FindFirstChild("Head") and Player.Character.Head.Transparency == 0
end

function Aimbot.TeamCheck(Player)
    if not Aimbot.Config.TeamCheck then
        return true
    end

    return Player and Player.Team ~= LocalPlayer.Team
end

function Aimbot.HasForceField(Player)
    if not Aimbot.Config.ForceFieldCheck then
        return true
    end

    return Player and Player.Character and not Player.Character:FindFirstChildOfClass("ForceField")
end

function Aimbot.IsAlive(Player)
    return Player and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0
end

Aimbot.GetClosestPlayer = function()
    if not Aimbot.Config.Enabled then
        return nil
    end

    local closest_player, closest_distance = nil, math.huge
    local mouse_pos = UserInputService:GetMouseLocation()

    for _, player in next, Players:GetPlayers() do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild(Aimbot.Config.Aimpart) then
                if not Aimbot.TeamCheck(player) then continue end
                if not Aimbot.IsAlive(player) then continue end
                if not Aimbot.HasForceField(player) then continue end

                local aim_part = character[Aimbot.Config.Aimpart]
                local aim_part_position, on_screen = Camera:WorldToViewportPoint(aim_part.Position)

                if on_screen then
                    local aim_vector = Vector2.new(aim_part_position.X, aim_part_position.Y)
                    local distance = (mouse_pos - aim_vector).Magnitude

                    if distance < closest_distance then
                        if not Aimbot.FOVConfig.Enabled or IsInRadius(aim_vector, Aimbot.FOVConfig.Radius) then
                            if Aimbot.IsVisible(player) and Aimbot.WallCheck(aim_part) then
                                closest_player = player
                                closest_distance = distance
                            end
                        end
                    end
                end
            end
        end
    end

    return closest_player
end

Aimbot.Update = function()
    local MousePosition = UserInputService:GetMouseLocation()

    if Aimbot.FOVConfig.Enabled then
        local FOVCircle = Aimbot.FOVCircle
        FOVCircle.Radius = Aimbot.FOVConfig.Radius
        FOVCircle.Thickness = Aimbot.FOVConfig.Thickness
        FOVCircle.Filled = Aimbot.FOVConfig.Filled
        FOVCircle.NumSides = Aimbot.FOVConfig.NumSides
        FOVCircle.Color = Aimbot.FOVConfig.Color
        FOVCircle.Transparency = Aimbot.FOVConfig.Transparency
        FOVCircle.Visible = Aimbot.FOVConfig.Visible
        FOVCircle.Position = Vector2.new(MousePosition.X, MousePosition.Y)
        FOVCircle.ZIndex = 11

        local FOVCircleOutline = Aimbot.FOVCircleOutline
        FOVCircleOutline.Radius = Aimbot.FOVConfig.Radius
        FOVCircleOutline.Thickness = Aimbot.FOVConfig.Thickness + 2
        FOVCircleOutline.NumSides = Aimbot.FOVConfig.NumSides
        FOVCircleOutline.Color = Color3.new(0, 0, 0)
        FOVCircleOutline.Transparency = Aimbot.FOVConfig.Transparency
        FOVCircleOutline.Visible = Aimbot.FOVConfig.Visible
        FOVCircleOutline.Position = Vector2.new(MousePosition.X, MousePosition.Y)
        FOVCircleOutline.ZIndex = 10
    else
        Aimbot.FOVCircle.Visible = false
        Aimbot.FOVCircleOutline.Visible = false
    end

    if Aimbot.Config.Enabled then
        local ClosestPlayer = Aimbot.GetClosestPlayer()
        Aimbot.Locked = Options and Options.AimbotBind:GetState() --ClosestPlayer ~= nil

        if Aimbot.Locked and ClosestPlayer then
            local AimPartPosition = ClosestPlayer.Character[Aimbot.Config.Aimpart].Position

            if Aimbot.Config.Method == "Mouse" then
                local Vector = Camera:WorldToViewportPoint(AimPartPosition)
                local DeltaX = (Vector.X - MousePosition.X) * math.clamp(Aimbot.Config.Smoothness, 0.1, 1)
                local DeltaY = (Vector.Y - MousePosition.Y) * math.clamp(Aimbot.Config.Smoothness, 0.1, 1)

                mousemoverel(DeltaX, DeltaY)
            else
                local TargetCFrame = CFrame.new(Camera.CFrame.Position, AimPartPosition)
                Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, Aimbot.Config.Smoothness)
            end
        end
    else
        Aimbot.Locked = false
    end
end

table.insert(Aimbot.Connections, RenderStepped:Connect(function()
    Aimbot.Update()
end))

return Aimbot

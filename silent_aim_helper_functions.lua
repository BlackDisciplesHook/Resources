local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RenderStepped = RunService.RenderStepped

local function IsInRadius(position, radius)
    local MousePosition = UserInputService:GetMouseLocation()
    return (position - MousePosition).Magnitude <= radius
end

local SilentAim = {
    Config = {
        enabled = false,
        always_send_hit_packet = false,
        part_priority = false,
        priority_part = "",
        bullet_teleport = false,
        hitchance = 50,
        hitparts = {"Head", "Torso"},
        method = "Raycast",

        wall_check = false,
        invis_check = false,
        team_check = false,
        forcefield_check = false,
    },

    FOVConfig = {
        enabled = false,
        visible = false,

        color = Color3.new(1, 1, 1),
        numsides = 360,
        transparency = 1,
        radius = 100,
        thickness = 1,
        filled = false
    },

    FOVCircle = Drawing.new("Circle"),
    FOVCircleOutline = Drawing.new("Circle"),
}

function SilentAim.WallCheck(Part)
    if not SilentAim.Config.wall_check then
        return true
    end

    if not Part or not Part.Position then
        return false
    end

    local PartPosition = Part and Part.Position
    local parts = Camera:GetPartsObscuringTarget({PartPosition}, {LocalPlayer.Character, Part})
    local visible = #parts == 0

    return visible
end

function SilentAim.HasForceField(Player)
    if not SilentAim.Config.forcefield_check then
        return true
    end

    return Player and Player.Character and Player.Character:FindFirstChildOfClass("ForceField") == nil
end

function SilentAim.IsVisible(Player)
    if not SilentAim.Config.invis_check then
        return true
    end

    return Player and Player.Character and Player.Character:FindFirstChild("Head") and Player.Character.Head.Transparency == 0
end

function SilentAim.TeamCheck(Player)
    if not SilentAim.Config.team_check then
        return true
    end

    return Player and Player.Team ~= LocalPlayer.Team
end

function SilentAim.IsAlive(Player)
    return Player and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0
end

function SilentAim.GetClosestHitpart()
    local _ClosestPart, MaxDistance, MousePosition = nil, math.huge, UserInputService:GetMouseLocation()
    local PriorityPart, HeadDistance = nil, math.huge

    if not SilentAim.Config.enabled then
        return nil
    end

    for _, Player in next, Players:GetPlayers() do
        if Player ~= LocalPlayer and not table.find(getgenv().Whitelist, Player) then
            local Character = Player.Character
            if Character then
                for _, Part in next, Character:GetChildren() do
                    if table.find(SilentAim.Config.hitparts, Part.Name) or (SilentAim.Config.part_priority and Part.Name == SilentAim.Config.priority_part) then
                        local AimPartPosition, onScreen = Camera:WorldToViewportPoint(Part.Position)

                        if onScreen then
                            local AimVector = Vector2.new(AimPartPosition.X, AimPartPosition.Y)
                            local DistanceToMouse = (Vector2.new(MousePosition.X, MousePosition.Y) - AimVector).Magnitude

                            if DistanceToMouse < math.min(MaxDistance, HeadDistance) then
                                if not SilentAim.FOVConfig.enabled or IsInRadius(AimVector, SilentAim.FOVConfig.radius) then
                                    if SilentAim.IsAlive(Player) and SilentAim.TeamCheck(Player) and SilentAim.HasForceField(Player) and SilentAim.IsVisible(Player) and SilentAim.WallCheck(Part) then
                                        if SilentAim.Config.part_priority and Part.Name == SilentAim.Config.priority_part then
                                            PriorityPart = Part
                                            HeadDistance = DistanceToMouse
                                        elseif not SilentAim.Config.part_priority then
                                            _ClosestPart = Part
                                            MaxDistance = DistanceToMouse
                                        elseif not PriorityPart then
                                            _ClosestPart = Part
                                            MaxDistance = DistanceToMouse
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return (SilentAim.Config.part_priority and PriorityPart) or _ClosestPart
end

function SilentAim.Update()
    local MousePosition = UserInputService:GetMouseLocation()
    SilentAim.Aiming = Options and Options.SilentAimBind:GetState() or false

    if SilentAim.Config.enabled and SilentAim.FOVConfig.enabled then
        local FOVCircle = SilentAim.FOVCircle
        FOVCircle.Radius = SilentAim.FOVConfig.radius
        FOVCircle.Thickness = SilentAim.FOVConfig.thickness
        FOVCircle.Filled = SilentAim.FOVConfig.filled
        FOVCircle.NumSides = SilentAim.FOVConfig.numsides
        FOVCircle.Color = SilentAim.FOVConfig.color
        FOVCircle.Transparency = SilentAim.FOVConfig.transparency
        FOVCircle.Visible = SilentAim.FOVConfig.visible
        FOVCircle.Position = Vector2.new(MousePosition.X, MousePosition.Y)
        FOVCircle.ZIndex = 20

        local FOVCircleOutline = SilentAim.FOVCircleOutline
        FOVCircleOutline.Radius = SilentAim.FOVConfig.radius
        FOVCircleOutline.Thickness = SilentAim.FOVConfig.thickness + 2
        FOVCircleOutline.NumSides = SilentAim.FOVConfig.numsides
        FOVCircleOutline.Color = Color3.new(0, 0, 0)
        FOVCircleOutline.Transparency = SilentAim.FOVConfig.transparency
        FOVCircleOutline.Visible = SilentAim.FOVConfig.visible
        FOVCircleOutline.Position = Vector2.new(MousePosition.X, MousePosition.Y)
        FOVCircleOutline.ZIndex = 19
    else
        SilentAim.FOVCircle.Visible = false
        SilentAim.FOVCircleOutline.Visible = false
    end
end

function SilentAim.CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

SilentAim.ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 2,
        Args = { "Instance", "Ray", "table", "boolean", "boolean" }
    },

    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 2,
        Args = { "Instance", "Ray", "table", "boolean" }
    },

    FindPartOnRay = {
        ArgCountRequired = 1,
        Args = { "Instance", "Ray", "Instance", "boolean", "boolean" }
    },

    Raycast = {
        ArgCountRequired = 2,
        Args = { "Instance", "Vector3", "Vector3", "RaycastParams" }
    },

    Spherecast = {
        ArgCountRequired = 3,
        Args = { "Instance", "Vector3", "Vector3", "number", "RaycastParams" }
    },

    Blockcast = {
        ArgCountRequired = 3,
        Args = { "Instance", "CFrame", "Vector3", "Vector3", "RaycastParams" }
    },

    Boxcast = {
        ArgCountRequired = 3,
        Args = { "Instance", "CFrame", "Vector3", "Vector3", "RaycastParams" }
    },
}

function SilentAim.ValidateArguments(Args, RayMethod)
    return #Args >= RayMethod.ArgCountRequired
end

RenderStepped:Connect(function()
    SilentAim.Update()
end)

return SilentAim

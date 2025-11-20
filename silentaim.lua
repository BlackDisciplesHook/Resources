local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RenderStepped = RunService.RenderStepped

local SilentAim = {
    Config = {
        Enabled = false,
        Hitchance = 50,

        PriorityPart = "nil",
        Hitparts = {"Head", "Torso"},

        Method = "Raycast",
        BulletTeleport = false,

        WallCheck = false,
        TeamCheck = false,
        InvisCheck = false,
        ForceFieldCheck = false,
    },

    FOVConfig = {
        Enabled = false,
        Visible = false,

        Color = Color3.new(1, 1, 1),
        NumSides = 12,
        Transparency = 1,
        Radius = 100,
        Thickness = 1,
        Filled = false
    },

    Target = nil,
    Locked = false,
    Connections = {},
    FOVCircle = Drawing.new("Circle"),
    FOVCircleOutline = Drawing.new("Circle"),
}

local function IsInRadius(position, radius)
    local MousePosition = UserInputService:GetMouseLocation()
    return (position - MousePosition).Magnitude <= radius
end

local _RaycastParams = RaycastParams.new()
_RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
_RaycastParams.IgnoreWater = true

local function Direction(origin, pos)
    return (pos - origin).Unit * 1000
end

function SilentAim.WallCheck(Part)
    if not SilentAim.Config.WallCheck then
        return true
    end

    if not Part or not Part.Parent then
        return false
    end

    _RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

    local RayResult = workspace:Raycast(Camera.CFrame.Position, Direction(Camera.CFrame.Position, Part.Position), _RaycastParams)

    if RayResult then
        local HitPart = RayResult.Instance
        local HitCharacter = HitPart:FindFirstAncestorOfClass("Model")
        local TargetCharacter = Part:FindFirstAncestorOfClass("Model")
        return HitCharacter == TargetCharacter
    end

    return false
end

function SilentAim.IsVisible(Player)
    if not SilentAim.Config.InvisCheck then
        return true
    end

    return Player and Player.Character and Player.Character:FindFirstChild("Head") and Player.Character.Head.Transparency == 0
end

function SilentAim.TeamCheck(Player)
    if not SilentAim.Config.TeamCheck then
        return true
    end

    return Player and Player.Team ~= LocalPlayer.Team
end

function SilentAim.HasForceField(Player)
    if not SilentAim.Config.ForceFieldCheck then
        return true
    end

    return Player and Player.Character and not Player.Character:FindFirstChildOfClass("ForceField")
end

function SilentAim.CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

function SilentAim.IsAlive(Player)
    return Player and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0
end

SilentAim.GetClosestHitpart = function()
    if not SilentAim.Config.Enabled then
        return nil
    end

    local ClosestPart, ClosestDistance = nil, math.huge
    local PriorityPart, PriorityDistance = nil, math.huge
    local MousePosition = UserInputService:GetMouseLocation()

    for _, Player in next, Players:GetPlayers() do
        if Player ~= LocalPlayer and not table.find(getgenv().Whitelist, Player.Name) then
            if not SilentAim.TeamCheck(Player) then
                continue
            end

            if not SilentAim.IsAlive(Player) then
                continue
            end

            if not SilentAim.HasForceField(Player) then
                continue
            end

            local Character = Player.Character

            if Character then
                for _, Part in next, Character:GetChildren() do
                    if table.find(SilentAim.Config.Hitparts, Part.Name) then
                        local PartPosition, OnScreen = Camera:WorldToViewportPoint(Part.Position)

                        if OnScreen then
                            local PartVector = Vector2.new(PartPosition.X, PartPosition.Y)
                            local Distance = (MousePosition - PartVector).Magnitude

                            if Distance < math.min(ClosestDistance, PriorityDistance) then
                                if not SilentAim.FOVConfig.Enabled or IsInRadius(PartVector, SilentAim.FOVConfig.Radius) then
                                    if SilentAim.IsVisible(Player) and SilentAim.WallCheck(Part) then
                                        if SilentAim.Config.PriorityPart and Part.Name == SilentAim.Config.PriorityPart then
                                            PriorityPart = Part
                                            PriorityDistance = Distance
                                        elseif not PriorityPart then
                                            ClosestPart = Part
                                            ClosestDistance = Distance
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

    return PriorityPart or ClosestPart
end

SilentAim.Update = function()
    local MousePosition = UserInputService:GetMouseLocation()

    if SilentAim.FOVConfig.Enabled then
        local FOVCircle = SilentAim.FOVCircle
        FOVCircle.Radius = SilentAim.FOVConfig.Radius
        FOVCircle.Thickness = SilentAim.FOVConfig.Thickness
        FOVCircle.Filled = SilentAim.FOVConfig.Filled
        FOVCircle.NumSides = SilentAim.FOVConfig.NumSides
        FOVCircle.Color = SilentAim.FOVConfig.Color
        FOVCircle.Transparency = SilentAim.FOVConfig.Transparency
        FOVCircle.Visible = SilentAim.FOVConfig.Visible
        FOVCircle.Position = Vector2.new(MousePosition.X, MousePosition.Y)
        FOVCircle.ZIndex = 11

        local FOVCircleOutline = SilentAim.FOVCircleOutline
        FOVCircleOutline.Radius = SilentAim.FOVConfig.Radius
        FOVCircleOutline.Thickness = SilentAim.FOVConfig.Thickness + 2
        FOVCircleOutline.NumSides = SilentAim.FOVConfig.NumSides
        FOVCircleOutline.Color = Color3.new(0, 0, 0)
        FOVCircleOutline.Transparency = SilentAim.FOVConfig.Transparency
        FOVCircleOutline.Visible = SilentAim.FOVConfig.Visible
        FOVCircleOutline.Position = Vector2.new(MousePosition.X, MousePosition.Y)
        FOVCircleOutline.ZIndex = 10
    else
        SilentAim.FOVCircle.Visible = false
        SilentAim.FOVCircleOutline.Visible = false
    end
end

table.insert(SilentAim.Connections, RenderStepped:Connect(function()
    SilentAim.Update()
    SilentAim.Target = SilentAim.GetClosestHitpart()
end))

local _RaycastParams = RaycastParams.new()
_RaycastParams.FilterType = Enum.RaycastFilterType.Whitelist
_RaycastParams.FilterDescendantsInstances = {}

local old
old = hookmetamethod(workspace, "__namecall", function(self, ...)
    if checkcaller() then
        return old(self, ...)
    end

    local method = getnamecallmethod()
    local arguments = {...}

    if SilentAim.Target and method == SilentAim.Config.Method and SilentAim.CalculateChance(SilentAim.Config.Hitchance) then
        if method == "Raycast" then
            arguments[2] = Direction(arguments[1], SilentAim.Target.Position)

            if SilentAim.Config.BulletTeleport then
                _RaycastParams.FilterDescendantsInstances = {SilentAim.Target.Parent}
                arguments[3] = _RaycastParams
            end

        elseif method == "FindPartOnRay" then
            local ray = arguments[1]
            arguments[1] = Ray.new(ray.Origin, Direction(ray.Origin, SilentAim.Target.Position))

        elseif method == "FindPartOnRayWithIgnoreList" then
            local ray = arguments[1]
            arguments[1] = Ray.new(ray.Origin, Direction(ray.Origin, SilentAim.Target.Position))

            if SilentAim.Config.BulletTeleport then
                arguments[2] = {}
            end

        elseif method == "FindPartOnRayWithWhitelist" then
            local ray = arguments[1]
            arguments[1] = Ray.new(ray.Origin, Direction(ray.Origin, SilentAim.Target.Position))

            if SilentAim.Config.BulletTeleport then
                arguments[2] = {SilentAim.Target.Parent}
            end

        elseif method == "Spherecast" then
            arguments[2] = Direction(arguments[1], SilentAim.Target.Position)

            if SilentAim.Config.BulletTeleport then
                _RaycastParams.FilterDescendantsInstances = {SilentAim.Target.Parent}
                arguments[4] = _RaycastParams
            end

        end

        return old(self, unpack(arguments))
    end

    return old(self, ...)
end)

return SilentAim

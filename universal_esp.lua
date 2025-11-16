if not isfile("BlackDisciplesHook/smallest_pixel-7.ttf") then
    writefile("BlackDisciplesHook/smallest_pixel-7.ttf", game:HttpGet("https://github.com/cutelilfemboy12/Resources/raw/refs/heads/main/smallest_pixel-7.ttf"))
end

local smallest_pixel = {
    name = "smallest_pixel-7", faces = {
        {
            name = "Regular",
            weight = 400,
            style = "normal",
            assetId = getcustomasset("BlackDisciplesHook/smallest_pixel-7.ttf")
        }
    }
}

writefile("BlackDisciplesHook/smallest_pixel-7.font", game:GetService("HttpService"):JSONEncode(smallest_pixel))

if isfile("BlackDisciplesHook/ProggyClean.ttf") then
    delfile("BlackDisciplesHook/ProggyClean.ttf")
end

writefile("BlackDisciplesHook/ProggyClean.ttf", game:HttpGet("https://github.com/cutelilfemboy12/Resources/raw/refs/heads/main/ProggyClean.ttf"))

local ProggyClean = {
    name = "ProggyClean",
    faces = {
        {
            name = "Regular",
            weight = 400,
            style = "normal",
            assetId = getcustomasset("BlackDisciplesHook/ProggyClean.ttf")
        }
    }
}

writefile("BlackDisciplesHook/ProggyClean.font", game:GetService("HttpService"):JSONEncode(ProggyClean))

getgenv().GlobalFont = "ProggyClean.font"

local Utility = {
    Draw = function(class: string, properties: {}?): Instance | boolean
        local success, instance = pcall(Drawing.new, class)

        if not success then
            return false
        end

        if properties then
            for key, value in next, properties do
                local succ, err = pcall(function()
                    (instance :: any)[key] = value
                end)

                if not succ then
                    warn(err)
                    return false
                end
            end
        end

        return instance
    end,

    Create = function(class: string, properties: {}?, attributes: {}?): Instance | boolean
        local success, instance = pcall(Instance.new, class)

        if not success then
            return false
        end

        if properties then
            for key, value in next, properties do
                local succ, err = pcall(function()
                    (instance :: any)[key] = value
                end)

                if not succ then
                    warn(err)
                    return false
                end
            end
        end

        if attributes then
            for key, value in pairs(attributes) do
                instance:SetAttribute(key, value)
            end
        end

        return instance
    end
}

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RenderStepped = RunService.RenderStepped

local ESP = {
    Config = {
        Enabled = false,

        Box = false,
        BoxColor = Color3.fromRGB(45, 125, 254),

        Name = false,
        NameColor = Color3.fromRGB(255, 255, 255),

        Distance = false,
        DistanceColor = Color3.fromRGB(255, 255, 255),

        HealthBar = false,
        HighHealthColor = Color3.fromRGB(45, 125, 254),
        LowHealthColor = Color3.fromRGB(45, 125, 254),

        Chams = false,
        ChamsOutlineColor = Color3.fromRGB(45, 125, 254),
        ChamsFillColor = Color3.fromRGB(45, 125, 254),
        ChamsOutlineTransparency = 0,
        ChamsFillTransparency = 0.5,

        Tracers = false,
        TracerPosition = "Center",
        TracerColor = Color3.fromRGB(255, 255, 255),

        OutlineColor = Color3.fromRGB(0, 0, 0),

        TeamCheck = false,
        InvisibleCheck = false,
    },

    Rigs = {
        R6 = {
            "Head",
            "Torso",
            "Left Arm",
            "Right Arm",
            "Left Leg",
            "Right Leg",
            "Humanoid"
        },

        R15 = {
            "Head",
            "UpperTorso",
            "LowerTorso",
            "LeftUpperArm",
            "LeftLowerArm",
            "LeftHand",
            "RightUpperArm",
            "RightLowerArm",
            "RightHand",
            "LeftUpperLeg",
            "LeftLowerLeg",
            "LeftFoot",
            "RightUpperLeg",
            "RightLowerLeg",
            "RightFoot",
            "Humanoid"
        },
    },

    Limbs = {},
    Drawings = {},
    Connections = {},
}

ESP.ScreenGui = Utility.Create("ScreenGui", {
    Parent = gethui(),
    DisplayOrder = 10,
    IgnoreGuiInset = true,
    Name = HttpService:GenerateGUID(false),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

ESP.Init = function(Player)
    local Drawings = {}

    Drawings.BoxOutline = Utility.Draw("Square", {
        Visible = false,
        Color = Color3.new(0, 0, 0),
        ZIndex = 1,
        Thickness = 3,
    })

    Drawings.Box = Utility.Draw("Square", {
        Visible = false,
        Color = Color3.new(1, 1, 1),
        ZIndex = 2,
        Thickness = 1,
    })

    Drawings.Name = Utility.Create("TextLabel", {
        Text = Player.Name,
        ZIndex = 9e9,
        TextSize = 12,
        Visible = false,
        RichText = true,
        Font = Enum.Font.Code,
        Parent = ESP.ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 0, 20),
        TextColor3 = ESP.Config.NameColor,
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextYAlignment = Enum.TextYAlignment.Top,
        FontFace = Font.new(getcustomasset("BlackDisciplesHook/" .. getgenv().GlobalFont), Enum.FontWeight.Regular),
    })

    Utility.Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        LineJoinMode = Enum.LineJoinMode.Bevel,
        Color = Color3.fromRGB(0, 0, 0),
        Parent = Drawings.Name
    })

    Drawings.Distance = Utility.Create("TextLabel", {
        Text = "?m",
        ZIndex = 9e9,
        TextSize = 12,
        Visible = false,
        RichText = true,
        Font = Enum.Font.Code,
        Parent = ESP.ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 0, 20),
        TextColor3 = ESP.Config.NameColor,
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextYAlignment = Enum.TextYAlignment.Bottom,
        FontFace = Font.new(getcustomasset("BlackDisciplesHook/" .. getgenv().GlobalFont), Enum.FontWeight.Regular),
    })

    Utility.Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        LineJoinMode = Enum.LineJoinMode.Bevel,
        Color = Color3.fromRGB(0, 0, 0),
        Parent = Drawings.Distance
    })

    Drawings.HealthBarOutline = Utility.Draw("Line", {
        Visible = false,
        Thickness = 3,
        ZIndex = 1,
        Color = Color3.new(0, 0, 0),
    })

    Drawings.HealthBar = Utility.Draw("Line", {
        Visible = false,
        Thickness = 1,
        ZIndex = 2,
        Color = Color3.new(0, 1, 0),
    })

    Drawings.Tracer = Utility.Draw("Line", {
        Visible = false,
        Thickness = 1,
        ZIndex = 1,
        Color = Color3.new(1, 1, 1),
    })

    ESP.Drawings[Player] = Drawings

    local Limbs = {}

    local function Init()
        task.spawn(function()
            repeat
                task.wait(0.2)
            until Player.Character

            if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Head") then
                if Player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
                    for _, Part in next, Player.Character:GetChildren() do
                        if table.find(ESP.Rigs.R6, Part.Name) then
                            table.insert(Limbs, Part)
                        end
                    end
                else
                    for _, Part in next, Player.Character:GetChildren() do
                        if table.find(ESP.Rigs.R15, Part.Name) then
                            table.insert(Limbs, Part)
                        end
                    end
                end
            end
        end)
    end

    Init()

    table.insert(ESP.Connections, Player.CharacterRemoving:Connect(function()
        Limbs = {}
        ESP.Limbs[Player] = Limbs
    end))

    table.insert(ESP.Connections, Player.CharacterAdded:Connect(function()
        task.wait(0.1)
        Init()
        ESP.Limbs[Player] = Limbs
    end))

    ESP.Limbs[Player] = Limbs
end

ESP.GetBoxSize = function(Player)
    local MinX = math.huge
    local MinY = math.huge
    local MaxX = -math.huge
    local MaxY = -math.huge

    for _, Limb in next, ESP.Limbs[Player] do
        if Limb:IsA("BasePart") then
            local CFrame = Limb.CFrame
            local Size = Limb.Size * 0.5

            local Corners = {
                Vector3.new(-Size.X, -Size.Y, -Size.Z),
                Vector3.new(-Size.X, -Size.Y,  Size.Z),
                Vector3.new(-Size.X,  Size.Y, -Size.Z),
                Vector3.new(-Size.X,  Size.Y,  Size.Z),
                Vector3.new( Size.X, -Size.Y, -Size.Z),
                Vector3.new( Size.X, -Size.Y,  Size.Z),
                Vector3.new( Size.X,  Size.Y, -Size.Z),
                Vector3.new( Size.X,  Size.Y,  Size.Z)
            }

            for _, Offset in next, Corners do
                local Point = Camera:WorldToViewportPoint(CFrame * Offset)

                if Point.X < MinX then
                    MinX = Point.X
                end

                if Point.X > MaxX then
                    MaxX = Point.X
                end

                if Point.Y < MinY then
                    MinY = Point.Y
                end

                if Point.Y > MaxY then
                    MaxY = Point.Y
                end
            end
        end
    end

    return {X = math.floor(MinX), Y = math.floor(MinY), W = math.floor(MaxX - MinX), H = math.floor(MaxY - MinY)}
end

ESP.TeamCheck = function(player)
    if not ESP.Config.TeamCheck then
        return true
    end

    return player.Team ~= LocalPlayer.Team
end

ESP.InvisibleCheck = function(Head)
    if not ESP.Config.InvisibleCheck then
        return true
    end

    return Head.Transparency == 0
end

local NewParent = Utility.Create("Model", {
    Name = HttpService:GenerateGUID(false),
    Parent = workspace,
})

local ChamsHighlight = Utility.Create("Highlight", {
    Parent = CoreGui,
    Adornee = NewParent,
    Name = HttpService:GenerateGUID(false),
    FillColor = ESP.Config.ChamsFillColor,
    OutlineColor = ESP.Config.ChamsOutlineColor,
    FillTransparency = ESP.Config.ChamsFillTransparency,
    OutlineTransparency = ESP.Config.ChamsOutlineTransparency,
})

ESP.Reparent = function(Player)
    if not Player or not Player.Character then
        return
    end

    local ok, alive = pcall(function()
        return Player.Character.Humanoid.Health > 0
    end)

    if ESP.Config.Chams and ESP.TeamCheck(Player) and ok and alive then
        Player.Character.Parent = NewParent
    else
        Player.Character.Parent = workspace
    end
end

ESP.UpdateFonts = function()
    for _, Drawings in next, ESP.Drawings do
        Drawings.Name.FontFace = Font.new(getcustomasset("BlackDisciplesHook/" .. getgenv().GlobalFont), Enum.FontWeight.Regular)
        Drawings.Distance.FontFace = Font.new(getcustomasset("BlackDisciplesHook/" .. getgenv().GlobalFont), Enum.FontWeight.Regular)
    end
end

ESP.FadeObjects = function(instance)
    if isrenderobj(instance) then

    elseif instance:IsA("TextLabel") then
        instance.TextTransparency = nil
        instance.UIStroke.Transparency = nil
    end
end

ESP.Update = function()
    for Player, Drawings in next, ESP.Drawings do
        local ok, notinvisible = pcall(function()
            return ESP.InvisibleCheck(Player.Character.Head)
        end)

        if ESP.Config.Enabled and Player.Character and ESP.Limbs[Player] and ESP.TeamCheck(Player) and ok and notinvisible then
            local To, OnScreen = Camera:WorldToViewportPoint(Player.Character:GetPivot().Position)
            local BoxSize = ESP.GetBoxSize(Player)

            local ok, alive = pcall(function()
                return Player.Character.Humanoid.Health > 0
            end)

            if OnScreen and BoxSize and ok then
                if alive then
                    for _, Drawing in next, Drawings do
                        if isrenderobj(Drawing) then
                            Drawing.Transparency = 1
                        elseif Drawing:IsA("TextLabel") then
                            Drawing.TextTransparency = 0
                            Drawing.UIStroke.Transparency = 0
                        end
                    end
                else
                    task.spawn(function()
                        for _, v in next, Drawings do
                            if isrenderobj(v) then
                                local Duration = 0.15
                                local Start, Goal, StartTime = v.Transparency or 1, 0, tick()

                                task.spawn(function()
                                    while tick() - StartTime < Duration do
                                        local Alpha = (tick() - StartTime) / Duration
                                        v.Transparency = Start + (Goal - Start) * Alpha
                                        task.wait()
                                    end

                                    v.Transparency = Goal
                                end)
                            elseif v:IsA("TextLabel") then
                                local TweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                                TweenService:Create(v, TweenInfo, {TextTransparency = 1}):Play()
                                TweenService:Create(v.UIStroke, TweenInfo, {Transparency = 1}):Play()
                            end
                        end
                    end)
                end

                if ESP.Config.Box then
                    Drawings.Box.Visible = true
                    Drawings.Box.Size = Vector2.new(BoxSize.W, BoxSize.H)
                    Drawings.Box.Position = Vector2.new(BoxSize.X, BoxSize.Y)
                    Drawings.Box.Color = ESP.Config.BoxColor

                    Drawings.BoxOutline.Visible = true
                    Drawings.BoxOutline.Size = Vector2.new(BoxSize.W, BoxSize.H)
                    Drawings.BoxOutline.Position = Vector2.new(BoxSize.X, BoxSize.Y)
                    Drawings.BoxOutline.Color = ESP.Config.OutlineColor
                else
                    Drawings.Box.Visible = false
                    Drawings.BoxOutline.Visible = false
                end

                if ESP.Config.HealthBar then
                    local HealthPercent = math.clamp(Player.Character.Humanoid.Health / Player.Character.Humanoid.MaxHealth, 0, 1)

                    Drawings.HealthBar.Visible = true
                    Drawings.HealthBar.Color = ESP.Config.LowHealthColor:Lerp(ESP.Config.HighHealthColor, HealthPercent)
                    Drawings.HealthBar.From = Vector2.new(BoxSize.X - 4, BoxSize.Y + (BoxSize.H - BoxSize.H * HealthPercent))
                    Drawings.HealthBar.To = Vector2.new(BoxSize.X - 4, BoxSize.Y + BoxSize.H)

                    Drawings.HealthBarOutline.Visible = true
                    Drawings.HealthBarOutline.Color = ESP.Config.OutlineColor
                    Drawings.HealthBarOutline.From = Vector2.new(BoxSize.X - 4, BoxSize.Y - 1)
                    Drawings.HealthBarOutline.To = Vector2.new(BoxSize.X - 4, BoxSize.Y + BoxSize.H + 1)
                else
                    Drawings.HealthBar.Visible = false
                    Drawings.HealthBarOutline.Visible = false
                end

                if ESP.Config.Tracers then
                    Drawings.Tracer.Visible = true
                    Drawings.Tracer.Color = ESP.Config.TracerColor

                    if ESP.Config.TracerPosition == "Top" then
                        Drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                    elseif ESP.Config.TracerPosition == "Center" then
                        Drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    else
                        Drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    end

                    Drawings.Tracer.To = Vector2.new(To.X, To.Y)
                else
                    Drawings.Tracer.Visible = false
                end

                if ESP.Config.Name then
                    Drawings.Name.Visible = true
                    Drawings.Name.TextColor3 = ESP.Config.NameColor
                    Drawings.Name.Position = UDim2.fromOffset(BoxSize.X + BoxSize.W / 2, BoxSize.Y - 5)
                else
                    Drawings.Name.Visible = false
                end

                if ESP.Config.Distance then
                    local Distance = (Camera.CFrame.Position - Player.Character:GetPivot().Position).Magnitude
                    Drawings.Distance.Visible = true
                    Drawings.Distance.Text = string.format("%dm", math.floor(Distance))
                    Drawings.Distance.TextColor3 = ESP.Config.DistanceColor
                    Drawings.Distance.Position = UDim2.fromOffset(BoxSize.X + BoxSize.W / 2, BoxSize.Y + BoxSize.H + 5)
                else
                    Drawings.Distance.Visible = false
                end
            else
                for _, Drawing in next, Drawings do
                    Drawing.Visible = false
                end
            end
        else
            for _, Drawing in next, Drawings do
                Drawing.Visible = false
            end
        end

        ESP.Reparent(Player)
    end

    ChamsHighlight.OutlineColor = ESP.Config.ChamsOutlineColor
    ChamsHighlight.OutlineTransparency = Options and Options.ESPHighlightOutlineColor and Options.ESPHighlightOutlineColor.Transparency or ESP.Config.ChamsOutlineTransparency

    ChamsHighlight.FillColor = ESP.Config.ChamsFillColor
    ChamsHighlight.FillTransparency = Options and Options.ESPHighlightFillColor and Options.ESPHighlightFillColor.Transparency or ESP.Config.ChamsFillTransparency
end

for _, Player in next, Players:GetPlayers() do
    if Player ~= LocalPlayer then
        ESP.Init(Player)
    end
end

table.insert(ESP.Connections, Players.PlayerAdded:Connect(function(Player)
    if Player ~= LocalPlayer then
        ESP.Init(Player)
    end
end))

table.insert(ESP.Connections, Players.PlayerRemoving:Connect(function(Player)
    for _, v in next, ESP.Drawings[Player] do
        v:Destroy()
    end

    ESP.Limbs[Player] = {}
end))

table.insert(ESP.Connections, RenderStepped:Connect(function()
    ESP.Update()
end))

-- return ESP

-- Services.lua - Game Services Initialization Module
-- Handles all game:GetService() calls and module requires

local S = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    RunService = game:GetService("RunService"),
    Stats = game:GetService("Stats"),
    TeleportService = game:GetService("TeleportService"),
    Lighting = game:GetService("Lighting"),
    StarterGui = game:GetService("StarterGui"),
}

S.Packages = S.ReplicatedStorage:FindFirstChild("Packages")
S.Datas = S.ReplicatedStorage:FindFirstChild("Datas")
S.Shared = S.ReplicatedStorage:FindFirstChild("Shared")
S.Utils = S.ReplicatedStorage:FindFirstChild("Utils")

S.Synchronizer = require(S.Packages.Synchronizer)
S.AnimalsData = require(S.Datas.Animals)
S.RaritiesData = require(S.Datas.Rarities)
S.AnimalsShared = require(S.Shared.Animals)
S.NumberUtils = require(S.Utils.NumberUtils)

S.LocalPlayer = S.Players.LocalPlayer
S.PlayerGui = S.LocalPlayer:FindFirstChild("PlayerGui") or S.LocalPlayer:WaitForChild("PlayerGui", 2)

return S


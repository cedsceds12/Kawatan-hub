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

-- Wrap require calls in pcall to handle missing modules gracefully
if S.Packages then
    local success, result = pcall(function() return require(S.Packages.Synchronizer) end)
    if success then S.Synchronizer = result end
end

if S.Datas then
    local success, result = pcall(function() return require(S.Datas.Animals) end)
    if success then S.AnimalsData = result end
    
    local success2, result2 = pcall(function() return require(S.Datas.Rarities) end)
    if success2 then S.RaritiesData = result2 end
end

if S.Shared then
    local success, result = pcall(function() return require(S.Shared.Animals) end)
    if success then S.AnimalsShared = result end
end

if S.Utils then
    local success, result = pcall(function() return require(S.Utils.NumberUtils) end)
    if success then S.NumberUtils = result end
end

S.LocalPlayer = S.Players.LocalPlayer
S.PlayerGui = S.LocalPlayer:FindFirstChild("PlayerGui") or S.LocalPlayer:WaitForChild("PlayerGui", 2)

return S


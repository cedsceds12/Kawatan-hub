-- Config.lua - Configuration Management Module
-- Handles CONFIG table, COLORS, and save/load functions

-- Services loaded separately for executor use
local Services = getgenv().KH and getgenv().KH.Services
if not Services then
    Services = { HttpService = game:GetService("HttpService") }
end

-- Initialize CONFIG from global or create new (trimmed to essentials)
getgenv().KAWATAN_CONFIG = getgenv().KAWATAN_CONFIG or {
    -- Combat
    AUTO_STEAL_ENABLED = false,
    AUTO_STEAL_NEAREST_ENABLED = false,
    AUTO_STEAL_FAST_INTERVAL = 0.08,
    AUTO_STEAL_IDLE_INTERVAL = 0.5,
    AUTO_STEAL_TRIGGER_DISTANCE = 30,
    STEAL_SPEED_ENABLED = false,
    AIMBOT_ENABLED = false,
    
    -- Movement
    INFINITE_JUMP_ENABLED = false,
    SLOW_FALL_ENABLED = false,
    FLOOR_STEAL_ENABLED = false,
    
    -- Performance
    OPTIMIZER_ENABLED = false,
    ANTI_LAG_ENABLED = false,
    ANTI_BEE_DISCO_ENABLED = false,
    ANTI_RAGDOLL_V2_ENABLED = false,
    
    -- Visual
    ESP_PLAYERS_ENABLED = false,
    XRAY_BASE = false,
    BEAM_TO_BEST_BRAINROT_ENABLED = false,
    BEAM_TO_BASE_ENABLED = false,
}

-- Safe Teleport is always enabled (not configurable)
getgenv().KAWATAN_CONFIG.SAFE_TELEPORT = true

local CONFIG = getgenv().KAWATAN_CONFIG
local CONFIG_FILE = "KawatanHubConfig.json"

local COLORS = {
    Background = Color3.fromRGB(15, 20, 30),
    BackgroundTransparency = 0.25,
    Surface = Color3.fromRGB(25, 35, 50),
    SurfaceTransparency = 0,
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 190, 210),
    Accent = Color3.fromRGB(0, 150, 255),
    Blue = Color3.fromRGB(50, 180, 255),
    Cyan = Color3.fromRGB(80, 200, 255),
    Red = Color3.fromRGB(255, 100, 120),
    Success = Color3.fromRGB(100, 255, 180),
}

local function saveConfig()
    local success, jsonData = pcall(Services.HttpService.JSONEncode, Services.HttpService, CONFIG)
    if success then
        writefile(CONFIG_FILE, jsonData)
    end
end

-- Debounced config save to prevent disk write spam
local saveDebounce = nil
local function saveConfigDebounced()
    if saveDebounce then task.cancel(saveDebounce) end
    saveDebounce = task.delay(2, saveConfig)
end

local function loadConfig()
    if not isfile or not isfile(CONFIG_FILE) then return end
    
    local ok, data = pcall(readfile, CONFIG_FILE)
    if not ok then return end
    
    local ok2, saved = pcall(Services.HttpService.JSONDecode, Services.HttpService, data)
    if ok2 and saved then
        for k, v in pairs(saved) do
            CONFIG[k] = v
        end
    end
    CONFIG.SAFE_TELEPORT = true
    getgenv().KAWATAN_CONFIG = CONFIG
end

return {
    CONFIG = CONFIG,
    COLORS = COLORS,
    CONFIG_FILE = CONFIG_FILE,
    saveConfig = saveConfig,
    loadConfig = loadConfig,
    saveConfigDebounced = saveConfigDebounced
}


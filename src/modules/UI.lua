-- UI.lua - Fluent UI Wrapper Module
-- Handles Fluent UI initialization and provides wrapper functions

-- Modules loaded separately for executor use
local Services = getgenv().KH and getgenv().KH.Services
local Config = getgenv().KH and getgenv().KH.Config
local Helpers = getgenv().KH and getgenv().KH.Helpers

if not Services or not Config or not Helpers then
    error("UI: Services, Config, and Helpers must be loaded first!")
end

-- Load Fluent library
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Window = nil
local Tabs = {}

local function CreateWindow(config)
    config = config or {}
    
    -- Mobile detection
    local isMobile = Helpers.isMobile()
    local windowSize = isMobile and UDim2.fromOffset(380, 420) or UDim2.fromOffset(520, 460)
    local tabWidth = isMobile and 120 or 160
    
    -- Create Fluent window
    Window = Fluent:CreateWindow({
        Title = config.title or "Kawatan Hub v3.0",
        TabWidth = tabWidth,
        Size = windowSize,
        Acrylic = true,
        Theme = "Darker"
    })
    
    -- Create tabs
    Tabs.Combat = Window:AddTab({ Title = "Combat", Icon = "" })
    Tabs.Movement = Window:AddTab({ Title = "Movement", Icon = "" })
    Tabs.Performance = Window:AddTab({ Title = "Perf", Icon = "" })
    Tabs.Visual = Window:AddTab({ Title = "Visual", Icon = "" })
    Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "" })
    Tabs.Debugger = Window:AddTab({ Title = "Debug", Icon = "" })
    
    return Window, Tabs
end

local function AddToggle(tabName, title, configKey, enableFunc, disableFunc)
    local tab = Tabs[tabName]
    if not tab then 
        warn("UI.AddToggle: Tab '" .. tabName .. "' not found") 
        return 
    end
    
    tab:AddToggle(title, {
        Title = title,
        Default = Config.CONFIG[configKey] or false,
        Callback = function(Value)
            Config.CONFIG[configKey] = Value
            if Value and enableFunc then enableFunc() end
            if not Value and disableFunc then disableFunc() end
            Config.saveConfig()
        end
    })
end

local function AddButton(tabName, title, callback)
    local tab = Tabs[tabName]
    if not tab then 
        warn("UI.AddButton: Tab '" .. tabName .. "' not found") 
        return 
    end
    
    tab:AddButton({
        Title = title,
        Description = "",
        Callback = callback or function() end
    })
end

local function Notify(title, text)
    if Window then
        Window:Notify({
            Title = title,
            Content = text,
            Duration = 3
        })
    else
        -- Fallback to simple notification if window not created
        Helpers.notify(title, text)
    end
end

local function ToggleWindow()
    if Window then
        Window:SetEnabled(not Window.Enabled)
    end
end

local function GetWindow()
    return Window
end

local function GetTabs()
    return Tabs
end

return {
    CreateWindow = CreateWindow,
    AddToggle = AddToggle,
    AddButton = AddButton,
    Notify = Notify,
    ToggleWindow = ToggleWindow,
    GetWindow = GetWindow,
    Tabs = Tabs, -- Export tabs directly for more granular control if needed
}



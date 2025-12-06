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
    
    -- Hide Fluent's default HideButton (the toggle button)
    pcall(function()
        task.wait(0.1) -- Wait for Fluent to create the button
        if Window and Window.HideButton then
            Window.HideButton.Visible = false
        end
    end)
    
    -- Create tabs
    Tabs.Combat = Window:AddTab({ Title = "Combat", Icon = "" })
    Tabs.Movement = Window:AddTab({ Title = "Movement", Icon = "" })
    Tabs.Performance = Window:AddTab({ Title = "Perf", Icon = "" })
    Tabs.Visual = Window:AddTab({ Title = "Visual", Icon = "" })
    Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "" })
    
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

local function AddParagraph(tabName, title, content)
    local tab = Tabs[tabName]
    if not tab then 
        warn("UI.AddParagraph: Tab '" .. tabName .. "' not found") 
        return 
    end
    
    return tab:CreateParagraph(title, {
        Title = title,
        Content = content or ""
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
        pcall(function()
            -- Use Fluent's built-in Minimize method
            Window:Minimize()
        end)
    end
end

local function GetWindow()
    return Window
end

local function GetTabs()
    return Tabs
end

-- Quick action buttons storage
local quickActionButtons = {}

-- Get Fluent theme accent color
local function GetFluentAccentColor()
    -- Fluent accent color from Window.luau source: Color3.fromRGB(76, 194, 255)
    return Color3.fromRGB(76, 194, 255)
end

-- Create custom toggle button (hamburger menu)
local function CreateCustomToggleButton(screenGui, config, colors)
    local btn = Instance.new("TextButton")
    btn.Name = "ToggleButton"
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = config.TOGGLE_BTN_X and UDim2.new(0, config.TOGGLE_BTN_X, 0, config.TOGGLE_BTN_Y) or UDim2.new(1, -65, 0, 15)
    
    -- Fluent UI styling: semi-transparent background with accent color
    local accentColor = GetFluentAccentColor()
    btn.BackgroundColor3 = accentColor
    btn.BackgroundTransparency = 0.3
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn
    
    -- Soft outline (UIStroke)
    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = btn
    
    -- Create hamburger menu icon with 3 lines (blue accent color)
    for i = 1, 3 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 24, 0, 3)
        line.Position = UDim2.new(0.5, -12, 0, 12 + (i-1) * 9)
        line.BackgroundColor3 = accentColor
        line.BorderSizePixel = 0
        line.ZIndex = 11
        line.Parent = btn
        
        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(0, 2)
        lineCorner.Parent = line
    end
    
    -- Dragging logic
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    btn.InputBegan:Connect(function(input)
        if config.TOGGLE_MENU_LOCKED then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.AbsolutePosition
        end
    end)
    
    btn.InputEnded:Connect(function(input)
        if config.TOGGLE_MENU_LOCKED then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                config.TOGGLE_BTN_X = btn.AbsolutePosition.X
                config.TOGGLE_BTN_Y = btn.AbsolutePosition.Y
                Config.saveConfigDebounced()
            end
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if config.TOGGLE_MENU_LOCKED then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport = workspace.CurrentCamera.ViewportSize
            local delta = input.Position - dragStart
            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y
            local btnSize = btn.AbsoluteSize
            
            newX = math.clamp(newX, 0, viewport.X - btnSize.X)
            newY = math.clamp(newY, 0, viewport.Y - btnSize.Y)
            
            btn.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
    
    -- Connect to toggle Fluent window
    btn.MouseButton1Click:Connect(function()
        ToggleWindow()
    end)
    
    return btn
end

-- Create quick action button
local function CreateQuickActionButton(screenGui, name, text, config, configKey, xConfigKey, yConfigKey, onClick, colors)
    if not config[configKey] then return nil end
    
    if quickActionButtons[name] then
        quickActionButtons[name]:Destroy()
        quickActionButtons[name] = nil
    end
    
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 40, 0, 40)
    
    local defaultY = 15
    if config.TOGGLE_BTN_Y then
        defaultY = config.TOGGLE_BTN_Y + 50
    end
    btn.Position = config[xConfigKey] and UDim2.new(0, config[xConfigKey], 0, config[yConfigKey]) or UDim2.new(1, -55, 0, defaultY)
    
    -- Fluent UI styling: semi-transparent background with accent color
    local accentColor = GetFluentAccentColor()
    btn.BackgroundColor3 = accentColor
    btn.BackgroundTransparency = 0.3
    btn.Text = text
    btn.TextColor3 = accentColor
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.TextStrokeTransparency = 1 -- Remove text stroke for cleaner look
    btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    -- Soft outline (UIStroke)
    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if onClick then onClick() end
    end)
    
    -- Dragging logic
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    btn.InputBegan:Connect(function(input)
        if config.QUICK_ACTION_LOCKED then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.AbsolutePosition
        end
    end)
    
    btn.InputEnded:Connect(function(input)
        if config.QUICK_ACTION_LOCKED then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                config[xConfigKey] = btn.AbsolutePosition.X
                config[yConfigKey] = btn.AbsolutePosition.Y
                Config.saveConfigDebounced()
            end
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if config.QUICK_ACTION_LOCKED then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport = workspace.CurrentCamera.ViewportSize
            local delta = input.Position - dragStart
            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y
            local btnSize = btn.AbsoluteSize
            
            newX = math.clamp(newX, 0, viewport.X - btnSize.X)
            newY = math.clamp(newY, 0, viewport.Y - btnSize.Y)
            
            btn.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
    
    quickActionButtons[name] = btn
    return btn
end

-- Get quick action buttons table
local function GetQuickActionButtons()
    return quickActionButtons
end

return {
    CreateWindow = CreateWindow,
    AddToggle = AddToggle,
    AddButton = AddButton,
    AddParagraph = AddParagraph,
    Notify = Notify,
    ToggleWindow = ToggleWindow,
    GetWindow = GetWindow,
    CreateCustomToggleButton = CreateCustomToggleButton,
    CreateQuickActionButton = CreateQuickActionButton,
    GetQuickActionButtons = GetQuickActionButtons,
    Tabs = Tabs, -- Export tabs directly for more granular control if needed
}


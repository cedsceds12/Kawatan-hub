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
    local windowSize = isMobile and UDim2.fromOffset(380, 320) or UDim2.fromOffset(520, 460)
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
    Tabs.Keybinds = Window:AddTab({ Title = "Keybinds", Icon = "" })
    
    -- Minimize window by default
    pcall(function()
        task.wait(0.2) -- Wait for window to fully initialize
        if Window then
            Window:Minimize()
        end
    end)
    
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

-- Keybind storage
local keybindStorage = {}

local function AddKeybind(tabName, name, title, configKey, mode, defaultKey, callback, changedCallback)
    local tab = Tabs[tabName]
    if not tab then 
        warn("UI.AddKeybind: Tab '" .. tabName .. "' not found") 
        return nil
    end
    
    -- Convert Enum.KeyCode to string if needed
    local defaultKeyStr = defaultKey
    if typeof(defaultKey) == "EnumItem" then
        defaultKeyStr = defaultKey.Name
    elseif Config.CONFIG[configKey] then
        -- Load from config if exists
        local configKeybind = Config.CONFIG[configKey]
        if typeof(configKeybind) == "EnumItem" then
            defaultKeyStr = configKeybind.Name
        else
            defaultKeyStr = tostring(configKeybind)
        end
    end
    
    -- Create keybind using Fluent
    local keybind = tab:CreateKeybind(name, {
        Title = title,
        Mode = mode or "Toggle",
        Default = defaultKeyStr,
        Callback = function(Value)
            if callback then callback(Value) end
        end,
        ChangedCallback = function(New)
            -- Save to config
            Config.CONFIG[configKey] = New
            Config.saveConfig()
            if changedCallback then changedCallback(New) end
        end
    })
    
    -- Store reference
    keybindStorage[name] = keybind
    return keybind
end

local function GetKeybind(name)
    return keybindStorage[name]
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

-- Custom UI elements storage (Top Bar, Speed Customizer)
local customUIElements = {
    topBar = nil,
    speedCustomizer = nil,
}

-- Get Fluent theme accent color
local function GetFluentAccentColor()
    -- Fluent accent color from Window.luau source: Color3.fromRGB(76, 194, 255)
    return Color3.fromRGB(76, 194, 255)
end

-- Get Fluent theme surface color (grey background)
local function GetFluentSurfaceColor()
    -- Fluent UI uses grey/transparent backgrounds for buttons
    return Color3.fromRGB(30, 30, 30)
end

-- Create custom toggle button (hamburger menu)
local function CreateCustomToggleButton(screenGui, config, colors)
    local btn = Instance.new("TextButton")
    btn.Name = "ToggleButton"
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = config.TOGGLE_BTN_X and UDim2.new(0, config.TOGGLE_BTN_X, 0, config.TOGGLE_BTN_Y) or UDim2.new(1, -65, 0, 15)
    
    -- Fluent UI styling: semi-transparent grey background with blue accent
    local accentColor = GetFluentAccentColor()
    local surfaceColor = GetFluentSurfaceColor()
    btn.BackgroundColor3 = surfaceColor
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
            local delta = input.Position - dragStart
            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y
            
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
    
    -- Fluent UI styling: semi-transparent grey background with blue accent
    local accentColor = GetFluentAccentColor()
    local surfaceColor = GetFluentSurfaceColor()
    btn.BackgroundColor3 = surfaceColor
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
            local delta = input.Position - dragStart
            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y
            
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

-- Get custom UI elements table
local function GetCustomUIElements()
    return customUIElements
end

-- Create Top Bar
local function CreateTopBar(screenGui)
    -- Destroy existing if any
    if customUIElements.topBar then
        customUIElements.topBar:Destroy()
        customUIElements.topBar = nil
    end
    
    local isMobile = Helpers.isMobile()
    local accentColor = GetFluentAccentColor()
    local surfaceColor = GetFluentSurfaceColor()
    
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(0, 0, 0, 30) -- Auto-size with UIListLayout
    topBar.Position = UDim2.new(0.5, 0, 0, 10)
    topBar.AnchorPoint = Vector2.new(0.5, 0)
    topBar.BackgroundColor3 = surfaceColor
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 999
    topBar.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = topBar
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = topBar
    
    local padding = Instance.new("UIPadding")
    local paddingAmount = isMobile and 10 or 15
    padding.PaddingLeft = UDim.new(0, paddingAmount)
    padding.PaddingRight = UDim.new(0, paddingAmount)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = topBar
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.Parent = topBar
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 0, 1, 0)
    title.AutomaticSize = Enum.AutomaticSize.X
    title.BackgroundTransparency = 1
    title.Text = "Kawatan Hub"
    title.TextColor3 = accentColor
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 1000
    title.Parent = topBar
    
    -- Separator
    local separator = Instance.new("TextLabel")
    separator.Size = UDim2.new(0, 0, 1, 0)
    separator.AutomaticSize = Enum.AutomaticSize.X
    separator.BackgroundTransparency = 1
    separator.Text = "|"
    separator.TextColor3 = accentColor
    separator.TextTransparency = 0.5
    separator.TextSize = 13
    separator.Font = Enum.Font.GothamBold
    separator.ZIndex = 1000
    separator.Parent = topBar
    
    -- FPS
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0, 0, 1, 0)
    fpsLabel.AutomaticSize = Enum.AutomaticSize.X
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS 60"
    fpsLabel.TextColor3 = accentColor
    fpsLabel.TextSize = 12
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.ZIndex = 1000
    fpsLabel.Parent = topBar
    
    -- PING
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(0, 0, 1, 0)
    pingLabel.AutomaticSize = Enum.AutomaticSize.X
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "PING 50ms"
    pingLabel.TextColor3 = accentColor
    pingLabel.TextSize = 12
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.ZIndex = 1000
    pingLabel.Parent = topBar
    
    -- Auto-size container after layout updates
    task.defer(function()
        task.wait(0.05)
        topBar.Size = UDim2.new(0, layout.AbsoluteContentSize.X + (paddingAmount * 2), 0, 30)
    end)
    
    -- FPS/Ping update loop
    task.spawn(function()
        local frames = 0
        local lastTime = tick()
        
        Services.RunService.RenderStepped:Connect(function()
            frames = frames + 1
            local now = tick()
            if now - lastTime >= 1 then
                local fps = frames
                frames = 0
                lastTime = now
                
                local ping = Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                fpsLabel.Text = "FPS " .. fps
                pingLabel.Text = "PING " .. math.floor(ping + 0.5) .. "ms"
            end
        end)
    end)
    
    customUIElements.topBar = topBar
    return topBar
end

-- Create Speed Customizer
local function CreateSpeedCustomizer(screenGui, config)
    -- Destroy existing if any
    if customUIElements.speedCustomizer then
        customUIElements.speedCustomizer:Destroy()
        customUIElements.speedCustomizer = nil
    end
    
    local isMobile = Helpers.isMobile()
    local accentColor = GetFluentAccentColor()
    local surfaceColor = GetFluentSurfaceColor()
    
    local container = Instance.new("Frame")
    container.Name = "SpeedCustomizer"
    local containerWidth = isMobile and 180 or 200
    -- Fixed height calculation: 10 (top pad) + 15 (title) + 8 (margin) + 24 (input) + 6 (margin) + 24 (buttons) + 10 (bottom pad) = 97px
    local containerHeight = isMobile and 95 or 97
    container.Size = UDim2.new(0, containerWidth, 0, containerHeight)
    -- Load saved position or default to below top bar
    local defaultY = 50
    container.Position = config.QUICK_SPEED_BTN_X and UDim2.new(0, config.QUICK_SPEED_BTN_X, 0, config.QUICK_SPEED_BTN_Y) or UDim2.new(0.5, 0, 0, defaultY)
    container.AnchorPoint = config.QUICK_SPEED_BTN_X and Vector2.new(0, 0) or Vector2.new(0.5, 0)
    container.BackgroundColor3 = surfaceColor
    container.BackgroundTransparency = 0.1
    container.BorderSizePixel = 0
    container.ZIndex = 999
    container.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = container
    
    -- Title (TextLabel - non-interactive text)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 15)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Steal Speed Boost"
    title.TextColor3 = accentColor
    title.TextSize = 11
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 1000
    title.Parent = container
    
    -- Drag handle (invisible button over title area for dragging)
    local dragHandle = Instance.new("TextButton")
    dragHandle.Size = UDim2.new(1, 0, 0, 15)
    dragHandle.Position = UDim2.new(0, 0, 0, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Text = ""
    dragHandle.ZIndex = 1001
    dragHandle.Parent = container
    
    -- Input box (positioned after title + 8px margin)
    local input = Instance.new("TextBox")
    input.Name = "SpeedInput"
    input.Size = UDim2.new(1, 0, 0, 24)
    input.Position = UDim2.new(0, 0, 0, 23) -- 15 (title) + 8 (margin) = 23
    input.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    input.BackgroundTransparency = 0.4
    input.BorderSizePixel = 0
    input.Text = tostring(config.STEAL_SPEED or 25.5)
    input.TextColor3 = accentColor
    input.TextSize = 12
    input.Font = Enum.Font.GothamBold
    input.PlaceholderText = "16-50"
    input.ClearTextOnFocus = false
    input.TextTransparency = config.STEAL_SPEED_ENABLED and 0 or 0.5
    input.ZIndex = 1000
    input.Parent = container
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 5)
    inputCorner.Parent = input
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = accentColor
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.7
    inputStroke.Parent = input
    
    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.new(0.48, -3, 0, 24) -- -3 for gap between buttons
    toggleBtn.Position = UDim2.new(0, 0, 0, 53) -- 23 (input Y) + 24 (input height) + 6 (margin) = 53
    -- When enabled: use accent color background with 0.3 opacity (0.7 transparency)
    -- When disabled: use dark background with 0.6 opacity (0.4 transparency)
    toggleBtn.BackgroundColor3 = config.STEAL_SPEED_ENABLED and accentColor or Color3.fromRGB(50, 50, 70)
    toggleBtn.BackgroundTransparency = config.STEAL_SPEED_ENABLED and 0.7 or 0.4
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = config.STEAL_SPEED_ENABLED and "Enabled" or "Disabled"
    toggleBtn.TextColor3 = accentColor
    toggleBtn.TextSize = 11
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.ZIndex = 1000
    toggleBtn.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = toggleBtn
    
    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = accentColor
    toggleStroke.Thickness = 1
    -- When enabled: full opacity border (0 transparency) for stronger accent
    -- When disabled: semi-transparent border (0.7 transparency)
    toggleStroke.Transparency = config.STEAL_SPEED_ENABLED and 0 or 0.7
    toggleStroke.Parent = toggleBtn
    
    -- Reset button
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.48, -3, 0, 24)
    resetBtn.Position = UDim2.new(0.52, 3, 0, 53) -- 0.52 (position) + 3px offset for gap
    resetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    resetBtn.BackgroundTransparency = 0.4
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset"
    resetBtn.TextColor3 = accentColor
    resetBtn.TextSize = 11
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.ZIndex = 1000
    resetBtn.Parent = container
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 5)
    resetCorner.Parent = resetBtn
    
    local resetStroke = Instance.new("UIStroke")
    resetStroke.Color = accentColor
    resetStroke.Thickness = 1
    resetStroke.Transparency = 0.7
    resetStroke.Parent = resetBtn
    
    -- Input validation
    input.FocusLost:Connect(function()
        local val = tonumber(input.Text) or 25.5
        val = math.clamp(val, 16, 50)
        input.Text = tostring(val)
        config.STEAL_SPEED = val
        Config.saveConfigDebounced()
    end)
    
    -- Toggle functionality
    toggleBtn.MouseButton1Click:Connect(function()
        config.STEAL_SPEED_ENABLED = not config.STEAL_SPEED_ENABLED
        toggleBtn.Text = config.STEAL_SPEED_ENABLED and "Enabled" or "Disabled"
        
        -- Update button styling to match HTML active state
        toggleBtn.BackgroundColor3 = config.STEAL_SPEED_ENABLED and accentColor or Color3.fromRGB(50, 50, 70)
        toggleBtn.BackgroundTransparency = config.STEAL_SPEED_ENABLED and 0.7 or 0.4
        toggleStroke.Transparency = config.STEAL_SPEED_ENABLED and 0 or 0.7
        
        input.TextTransparency = config.STEAL_SPEED_ENABLED and 0 or 0.5
        
        -- If disabling, stop speed immediately
        if not config.STEAL_SPEED_ENABLED then
            if getgenv().KH and getgenv().KH.StealSpeed then
                getgenv().KH.StealSpeed.Stop()
            end
        end
        
        Config.saveConfigDebounced()
    end)
    
    -- Reset functionality
    resetBtn.MouseButton1Click:Connect(function()
        input.Text = "25.5"
        config.STEAL_SPEED = 25.5
        Config.saveConfigDebounced()
    end)
    
    -- Dragging logic (copied from quick action buttons - works perfectly)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    dragHandle.InputBegan:Connect(function(input)
        if config.QUICK_ACTION_LOCKED then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = container.AbsolutePosition
        end
    end)
    
    dragHandle.InputEnded:Connect(function(input)
        if config.QUICK_ACTION_LOCKED then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                config.QUICK_SPEED_BTN_X = container.AbsolutePosition.X
                config.QUICK_SPEED_BTN_Y = container.AbsolutePosition.Y
                Config.saveConfigDebounced()
            end
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if config.QUICK_ACTION_LOCKED then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y
            
            container.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
    
    -- Store references in customUIElements (can't assign custom properties to Frame)
    customUIElements.speedCustomizer = container
    customUIElements.speedCustomizerInput = input
    customUIElements.speedCustomizerToggle = toggleBtn
    
    return container
end

return {
    CreateWindow = CreateWindow,
    AddToggle = AddToggle,
    AddButton = AddButton,
    AddParagraph = AddParagraph,
    AddKeybind = AddKeybind,
    GetKeybind = GetKeybind,
    Notify = Notify,
    ToggleWindow = ToggleWindow,
    GetWindow = GetWindow,
    CreateCustomToggleButton = CreateCustomToggleButton,
    CreateQuickActionButton = CreateQuickActionButton,
    GetQuickActionButtons = GetQuickActionButtons,
    CreateTopBar = CreateTopBar,
    CreateSpeedCustomizer = CreateSpeedCustomizer,
    GetCustomUIElements = GetCustomUIElements,
    Tabs = Tabs, -- Export tabs directly for more granular control if needed
}

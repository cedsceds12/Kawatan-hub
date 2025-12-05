-- Helpers.lua - Utility Functions Module
-- Handles all utility functions: notify, colors, UI helpers, etc.

-- Modules loaded separately for executor use
local Services = getgenv().KAWATAN_MODULES and getgenv().KAWATAN_MODULES.Services
local Config = getgenv().KAWATAN_MODULES and getgenv().KAWATAN_MODULES.Config

if not Services or not Config then
    error("Helpers: Services and Config must be loaded first!")
end

-- Localized functions for performance
local tinsert, tremove = table.insert, table.remove
local mathclamp, mathabs, mathmin, mathmax = math.clamp, math.abs, math.min, math.max
local mathfloor, mathhuge = math.floor, math.huge
local Vector3new, CFramenew = Vector3.new, CFrame.new

local function notify(title, text)
    -- Disabled for performance (27 calls removed)
end

local function blendColor(c1, c2, alpha)
    return Color3.new(
        c1.R + (c2.R - c1.R) * alpha,
        c1.G + (c2.G - c1.G) * alpha,
        c1.B + (c2.B - c1.B) * alpha
    )
end

local function applyTextStroke(el)
    if not el then return end
    if el:IsA("TextLabel") or el:IsA("TextButton") or el:IsA("TextBox") then
        el.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        local size = el.TextSize
        if el.TextScaled then
            size = math.floor((el.AbsoluteSize.Y / 24) * 18)
        end
        if size <= 12 then
            el.TextStrokeTransparency = 0.5
        elseif size <= 16 then
            el.TextStrokeTransparency = 0.3
        else
            el.TextStrokeTransparency = 0.2
        end
    end
end

local function applyUIStroke(frame, color, thickness, transparency)
    if not frame then return end
    
    local border = frame:FindFirstChild("UIStroke")
    if not border then
        border = Instance.new("UIStroke")
        border.Name = "UIStroke"
        border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        border.Parent = frame
    end
    border.Thickness = thickness or 1.5
    border.Color = color or Config.COLORS.Blue
    border.Transparency = transparency or 0.3
end

local function getHRP()
    local c = Services.LocalPlayer.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function clampToScreen(frame)
    local viewport = workspace.CurrentCamera.ViewportSize
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    
    local clampedX = mathclamp(pos.X, 0, viewport.X - size.X)
    local clampedY = mathclamp(pos.Y, 0, viewport.Y - size.Y)
    
    frame.Position = UDim2.new(0, clampedX, 0, clampedY)
end

local function tween(el, duration, props)
    Services.TweenService:Create(el, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), props):Play()
end

local function isMobile()
    return Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled
end

local function getScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    if isMobile() then
        return mathclamp(viewport.X / 1920 * 0.85, 0.6, 0.9)
    end
    return 1
end

return {
    notify = notify,
    blendColor = blendColor,
    applyTextStroke = applyTextStroke,
    applyUIStroke = applyUIStroke,
    getHRP = getHRP,
    clampToScreen = clampToScreen,
    tween = tween,
    isMobile = isMobile,
    getScale = getScale,
    -- Localized functions
    tinsert = tinsert,
    tremove = tremove,
    mathclamp = mathclamp,
    mathabs = mathabs,
    mathmin = mathmin,
    mathmax = mathmax,
    mathfloor = mathfloor,
    mathhuge = mathhuge,
    Vector3new = Vector3new,
    CFramenew = CFramenew,
}


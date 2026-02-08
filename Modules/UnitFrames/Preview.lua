local addon, ns = ...

--[[
    Preview Module for DessertUI

    Provides a preview mode to display all unit frames for testing/configuration.
    - Toggle with /dui preview
    - Automatically disables when combat starts
    - Disables faders during preview for clear visibility
]]

local Preview = {}
ns.Preview = Preview

-- Preview state
local isPreviewActive = false
local previewFrames = {}
local originalFaderStates = {}

-- Frame names to preview (everything except player)
local PREVIEW_FRAMES = {
    "DessertUI_Target",
    "DessertUI_Pet",
    "DessertUI_ToT",
    "DessertUI_Focus",
    "DessertUI_Boss1",
    "DessertUI_Boss2",
    "DessertUI_Boss3",
    "DessertUI_Boss4",
}

-- Store original fader states and disable faders
local function disableFadersForPreview()
    originalFaderStates = {}

    -- Store and disable unit fader
    if ns.Settings and ns.Settings.GetOption then
        originalFaderStates.unitFader = ns.Settings.GetOption("unitFader")
        if originalFaderStates.unitFader and ns.Faders and ns.Faders.ToggleUnitFaderSilent then
            ns.Faders.ToggleUnitFaderSilent(false)
        end
    end

    -- Also reset alpha on preview frames to ensure visibility
    for _, frameName in ipairs(PREVIEW_FRAMES) do
        local frame = _G[frameName]
        if frame then
            frame:SetAlpha(1)
        end
    end

    ns.Utils.PrintMessage("Faders disabled for preview mode")
end

-- Restore original fader states
local function restoreFadersAfterPreview()
    if originalFaderStates.unitFader and ns.Faders and ns.Faders.ToggleUnitFaderSilent then
        ns.Faders.ToggleUnitFaderSilent(true)
    end

    originalFaderStates = {}
    ns.Utils.PrintMessage("Faders restored")
end

-- Enable preview mode
local function enablePreview()
    if isPreviewActive then return end

    -- Check if UnitFrames have been initialized
    local any_frame_exists = false
    for _, frameName in ipairs(PREVIEW_FRAMES) do
        if _G[frameName] then
            any_frame_exists = true
            break
        end
    end

    if not any_frame_exists then
        ns.Utils.PrintMessage("Preview mode unavailable - unit frames not yet initialized")
        return
    end

    isPreviewActive = true
    disableFadersForPreview()

    -- Force show each preview frame using player as the display unit
    for _, frameName in ipairs(PREVIEW_FRAMES) do
        local frame = _G[frameName]
        if frame then
            -- Store original state
            previewFrames[frameName] = {
                originalUnit = frame:GetAttribute("unit"),
            }

            -- Use player as mock unit data so the frame has something to display
            frame:SetAttribute("unit", "player")
            frame:Show()

            -- Force update the frame
            if frame.Update then
                frame:Update()
            end
        end
    end

    ns.Utils.PrintMessage("Preview mode enabled - showing all unit frames")
end

-- Disable preview mode
local function disablePreview()
    if not isPreviewActive then return end

    isPreviewActive = false

    -- Restore each frame to its original unit
    for frameName, state in pairs(previewFrames) do
        local frame = _G[frameName]
        if frame and state.originalUnit then
            frame:SetAttribute("unit", state.originalUnit)

            -- Let oUF handle visibility based on actual unit existence
            if frame.Update then
                frame:Update()
            end
        end
    end

    previewFrames = {}
    restoreFadersAfterPreview()

    ns.Utils.PrintMessage("Preview mode disabled")
end

-- Toggle preview mode
function Preview.Toggle()
    if isPreviewActive then
        disablePreview()
    else
        enablePreview()
    end
end

-- Check if preview is active
function Preview.IsActive()
    return isPreviewActive
end

-- Combat handler to auto-disable preview
local function onCombatStart()
    if isPreviewActive then
        ns.Utils.PrintMessage("Combat started - disabling preview mode")
        disablePreview()
    end
end

-- Register for combat events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        onCombatStart()
    end
end)

-- Register slash command
ns.Utils.RegisterCallback("PLAYER_LOGIN", function()
    ns.Slash.Register({"preview", "prev", "test"}, function()
        Preview.Toggle()
    end, {
        description = "Toggle unit frame preview mode",
        usage = "/dui preview",
    })
end)

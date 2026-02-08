local addon, ns = ...

-- Initialize Faders namespace
ns.Faders = ns.Faders or {}
local Faders = ns.Faders

-- Cache frequently used functions
local pairs = pairs
local ipairs = ipairs
local string_format = string.format

-- Helper to check if a frame name uses combined fader
local function usesCombinedFader(frameName)
    local combined_frames = ns.Constants.unitFrameNames and ns.Constants.unitFrameNames.combined or {}
    for _, name in ipairs(combined_frames) do
        if frameName == name then
            return true
        end
    end
    return false
end

-- Helper function to safely create fader for a frame
local function createFaderForFrame(frame, frameName)
    if not frame then
        ns.Utils.PrintMessage(string.format("Warning: %s frame not found, skipping fader creation", frameName))
        return false
    end

    if not ns.Fader or not ns.Fader.Create then
        ns.Utils.PrintMessage("Error: Fader module not available")
        return false
    end

    -- Use combined fader for unit frames, mouseover for other frames
    local faderConfig = usesCombinedFader(frameName)
        and ns.Constants.faders.combined
        or ns.Constants.faders.mouseover
    ns.Fader.Create(frame, faderConfig)
    return true
end

-- Generic toggle function for faders
local function toggleFader(frame, frameName, settingName, enabled, silent)
    -- Update saved variables using Settings module
    if ns.Settings and ns.Settings.SetOption then
        ns.Settings.SetOption(settingName, enabled)
    else
        -- Fallback to direct database access
        if not DessertUIDB then DessertUIDB = {} end
        DessertUIDB[settingName] = enabled
    end

    if frame then
        if not ns.Fader then
            ns.Utils.PrintMessage("Error: Fader module not available")
            return false
        end

        if enabled then
            -- Enable fader if it was disabled, or create new one if not initialized
            if frame.__faderInitialized and frame.__faderDisabled then
                ns.Fader.Enable(frame)
            else
                -- Use combined fader for unit frames, mouseover for other frames
                local faderConfig = usesCombinedFader(frameName)
                    and ns.Constants.faders.combined
                    or ns.Constants.faders.mouseover
                ns.Fader.Create(frame, faderConfig)
            end
        else
            -- Disable fader
            ns.Fader.Disable(frame)
        end
    end

    -- Only print message if not called from options system
    if not silent then
        local status = enabled and "enabled" or "disabled"
        ns.Utils.PrintMessage(string.format("%s fading %s", frameName, status))
    end

    return true
end

local function createFaders()
    -- Create micro menu fader if the setting is enabled
    if ns.Settings.GetOption("microMenuFader") then
        createFaderForFrame(MicroMenu, "Micro Menu")
    end

    -- Create bag fader if the setting is enabled
    if ns.Settings.GetOption("bagFader") then
        createFaderForFrame(BagsBar, "Bag Bar")
    end
end

-- Function to toggle micro menu fader in real-time
function Faders.ToggleMicroMenuFader(enabled, silent)
    return toggleFader(MicroMenu, "Micro Menu", "microMenuFader", enabled, silent)
end

-- Wrapper function for the options system (silent mode)
function Faders.ToggleMicroMenuFaderSilent(enabled)
    return Faders.ToggleMicroMenuFader(enabled, true)
end

-- Function to toggle bag fader in real-time
function Faders.ToggleBagFader(enabled, silent)
    return toggleFader(BagsBar, "Bag Bar", "bagFader", enabled, silent)
end

-- Wrapper function for the options system (silent mode)
function Faders.ToggleBagFaderSilent(enabled)
    return Faders.ToggleBagFader(enabled, true)
end

-- Function to toggle unit frame faders in real-time
function Faders.ToggleUnitFader(enabled, silent)
    -- Get all unit frames
    local unitFrames = {
        {frame = _G["DessertUI_Player"], name = "Player"},
        {frame = _G["DessertUI_Target"], name = "Target"},
        {frame = _G["DessertUI_Pet"], name = "Pet"},
        {frame = _G["DessertUI_ToT"], name = "Target of Target"},
        {frame = _G["DessertUI_Focus"], name = "Focus"}
    }

    local success = true
    local frame_count = 0
    for _, unitData in pairs(unitFrames) do
        if unitData.frame then
            frame_count = frame_count + 1
            local result = toggleFader(unitData.frame, unitData.name, "unitFader", enabled, silent)
            if not result then
                success = false
            end
        end
    end

    if frame_count == 0 and not silent then
        ns.Utils.PrintMessage("Warning: No unit frames found to apply fader changes")
    end

    return success
end

-- Wrapper function for the options system (silent mode)
function Faders.ToggleUnitFaderSilent(enabled)
    return Faders.ToggleUnitFader(enabled, true)
end

-- Function to refresh all faders (useful for after UI reloads)
function Faders.RefreshAllFaders()
    -- Recreate faders for existing frames
    if MicroMenu and ns.Settings.GetOption("microMenuFader") then
        if ns.Fader then
            ns.Fader.Create(MicroMenu, ns.Constants.faders.mouseover)
        end
    end

    if BagsBar and ns.Settings.GetOption("bagFader") then
        if ns.Fader then
            ns.Fader.Create(BagsBar, ns.Constants.faders.mouseover)
        end
    end

    -- Refresh unit frame faders
    if ns.Settings.GetOption("unitFader") then
        local unitFrames = {
            {frame = _G["DessertUI_Player"], name = "Player"},
            {frame = _G["DessertUI_Target"], name = "Target"},
            {frame = _G["DessertUI_Pet"], name = "Pet"},
            {frame = _G["DessertUI_ToT"], name = "Target of Target"},
            {frame = _G["DessertUI_Focus"], name = "Focus"}
        }

        for _, unitData in pairs(unitFrames) do
            if unitData.frame and ns.Fader then
                ns.Fader.Create(unitData.frame, ns.Constants.faders.combined)
            end
        end
    end
end

-- Register callbacks for fader management
ns.Utils.RegisterCallback("PLAYER_LOGIN", createFaders)

-- Export functions to global namespace for backward compatibility
-- These can be removed once all code is updated to use the new namespace
ns.ActionBars = ns.ActionBars or {}
ns.ActionBars.ToggleMicroMenuFader = Faders.ToggleMicroMenuFader
ns.ActionBars.ToggleMicroMenuFaderSilent = Faders.ToggleMicroMenuFaderSilent
ns.ActionBars.ToggleBagFader = Faders.ToggleBagFader
ns.ActionBars.ToggleBagFaderSilent = Faders.ToggleBagFaderSilent

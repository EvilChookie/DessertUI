local addon, ns = ...

-- Initialize Faders namespace
ns.Faders = ns.Faders or {}
local Faders = ns.Faders

-- Cache frequently used functions
local pairs = pairs
local string_format = string.format

-- Generic toggle function for unit frame faders
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
            if frame.__faderInitialized and frame.__faderDisabled then
                ns.Fader.Enable(frame)
            else
                ns.Fader.Create(frame, ns.Constants.faders.combined)
            end
        else
            ns.Fader.Disable(frame)
        end
    end

    if not silent then
        local status = enabled and "enabled" or "disabled"
        ns.Utils.PrintMessage(string_format("%s fading %s", frameName, status))
    end

    return true
end

-- Function to toggle unit frame faders in real-time
function Faders.ToggleUnitFader(enabled, silent)
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

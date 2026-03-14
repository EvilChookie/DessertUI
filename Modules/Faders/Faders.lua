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

-- Action bar fader
local ACTION_BAR_FRAMES = {
    "MainActionBar",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarRight",
    "MultiBarLeft",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
    "StanceBar",
    "PetActionBar",
}

local actionBarFrames = {}

local function applyActionBarFader(enabled)
    if not ns.Fader then return end
    -- Bartender4 replaces default action bars; skip fading Blizzard frames
    if ns.hasBartender4 then return end

    for _, frameName in pairs(ACTION_BAR_FRAMES) do
        local frame = _G[frameName]
        -- PetActionBar resolves to PetActionBarFrame
        if not frame and frameName == "PetActionBar" then
            frame = _G.PetActionBarFrame
        end
        if frame then
            if enabled then
                if frame.__faderInitialized and frame.__faderDisabled then
                    ns.Fader.Enable(frame)
                elseif not frame.__faderInitialized then
                    ns.Fader.Create(frame, ns.Constants.faders.actionBars)
                    actionBarFrames[#actionBarFrames + 1] = frame
                end
            else
                ns.Fader.Disable(frame)
            end
        end
    end
end

function Faders.ToggleActionBarFader(enabled, silent)
    if ns.Settings and ns.Settings.SetOption then
        ns.Settings.SetOption("actionBarFader", enabled)
    else
        if not DessertUIDB then DessertUIDB = {} end
        DessertUIDB["actionBarFader"] = enabled
    end

    applyActionBarFader(enabled)

    if not silent then
        local status = enabled and "enabled" or "disabled"
        ns.Utils.PrintMessage(string_format("Action bar fading %s", status))
    end

    return true
end

function Faders.ToggleActionBarFaderSilent(enabled)
    return Faders.ToggleActionBarFader(enabled, true)
end

-- Mouseover-only faders for irrelevant UI frames (bag bar, micro menu)
local irrelevantFrames = {}

local function initIrrelevantFaders()
    local frames_to_fade = {
        BagsBar,
        MicroMenu,
    }

    for _, frame in pairs(frames_to_fade) do
        if frame and not frame.__faderInitialized then
            ns.Fader.Create(frame, ns.Constants.faders.mouseoverOnly)
            irrelevantFrames[#irrelevantFrames + 1] = frame
        end
    end

    -- Initialize action bar faders if enabled
    local enabled = true
    if ns.Settings and ns.Settings.GetOption then
        enabled = ns.Settings.GetOption("actionBarFader")
        if enabled == nil then enabled = true end
    elseif DessertUIDB and DessertUIDB["actionBarFader"] ~= nil then
        enabled = DessertUIDB["actionBarFader"]
    end

    if enabled then
        applyActionBarFader(true)
    end
end

ns.Utils.RegisterCallback("PLAYER_ENTERING_WORLD", initIrrelevantFaders)

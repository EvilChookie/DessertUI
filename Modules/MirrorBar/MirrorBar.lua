local addon, ns = ...

--[[
    Mirror Bar

    Replaces Blizzard's MirrorTimerFrame with thin, styled bars anchored
    below the player unit frame.  Handles breath, fatigue, and feign death
    timers via the MIRROR_TIMER API.
]]

ns.MirrorBar = {}
local MirrorBar = ns.MirrorBar

-- Cached globals
local GetMirrorTimerInfo = GetMirrorTimerInfo
local GetMirrorTimerProgress = GetMirrorTimerProgress
local GetTime = GetTime
local string_format = string.format
local math_floor = math.floor
local math_max = math.max

-- Module state
local bars = {}          -- timer name → bar frame
local activeTimers = {}  -- timer name → { maxValue, scale, paused, label }
local eventFrame
local C                  -- constants shorthand

-- Max simultaneous mirror timers WoW supports
local MAX_TIMERS = 3

---------------------------------------------------------------------------
-- Friendly labels for timer types
---------------------------------------------------------------------------

local TIMER_LABELS = {
    BREATH     = "BREATH",
    EXHAUSTION = "FATIGUE",
    FEIGNDEATH = "FEIGN DEATH",
}

---------------------------------------------------------------------------
-- Time formatting
---------------------------------------------------------------------------

local function formatTime(ms)
    local seconds = math_max(0, math_floor(ms / 1000))
    local minutes = math_floor(seconds / 60)
    seconds = seconds - (minutes * 60)
    if minutes > 0 then
        return string_format("%d:%02d", minutes, seconds)
    end
    return string_format("%d", seconds)
end

---------------------------------------------------------------------------
-- Bar Creation
---------------------------------------------------------------------------

local function getAnchorFrame()
    return _G["DessertUI_Player"] or UIParent
end

local function getBarYOffset(index)
    -- Each bar slot: text height (8pt) + bar height + spacing
    local slotHeight = 8 + C.textOffset + C.barHeight + C.spacing
    -- Extra offset to clear the abbreviated HP text below the player frame
    local hpTextOffset = 12
    return -(hpTextOffset + slotHeight * (index - 1))
end

local function createBar(timerName, index)
    local anchor = getAnchorFrame()
    local yOffset = getBarYOffset(index)

    -- Container frame for text + bar
    local container = CreateFrame("Frame", "DessertUI_MirrorBar_" .. timerName, UIParent)
    local totalHeight = 8 + C.textOffset + C.barHeight
    container:SetSize(C.barWidth, totalHeight)
    container:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, yOffset)

    -- Timer label text (right-aligned, Pixelify Sans)
    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 8, "OUTLINE")
    text:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    text:SetJustifyH("RIGHT")
    container.text = text

    -- Thin status bar underneath text
    local bar = CreateFrame("StatusBar", nil, container)
    bar:SetSize(C.barWidth, C.barHeight)
    bar:SetPoint("TOPRIGHT", text, "BOTTOMRIGHT", 0, -C.textOffset)
    bar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)

    -- Bar background
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(C.background[1], C.background[2], C.background[3], C.background[4])

    container.bar = bar
    container:Hide()

    return container
end

local function getOrCreateBar(timerName)
    if bars[timerName] then return bars[timerName] end

    -- Find next available index
    local index = 0
    for _ in pairs(bars) do
        index = index + 1
    end

    local bar = createBar(timerName, index)
    bars[timerName] = bar
    return bar
end

---------------------------------------------------------------------------
-- Bar Updates
---------------------------------------------------------------------------

local function repositionBars()
    local index = 0
    for _, barFrame in pairs(bars) do
        if barFrame:IsShown() then
            local anchor = getAnchorFrame()
            local yOffset = getBarYOffset(index)
            barFrame:ClearAllPoints()
            barFrame:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, yOffset)
            index = index + 1
        end
    end
end

local function updateBar(timerName)
    local info = activeTimers[timerName]
    if not info then return end

    local barFrame = bars[timerName]
    if not barFrame then return end

    local progress = GetMirrorTimerProgress(timerName)
    if not progress then return end

    local value = progress / info.maxValue
    if value > 1 then value = 1 end
    if value < 0 then value = 0 end

    barFrame.bar:SetValue(value)

    local label = TIMER_LABELS[timerName] or info.label or timerName
    barFrame.text:SetText(string_format("%s %s", label, formatTime(progress)))
end

---------------------------------------------------------------------------
-- OnUpdate for smooth progress
---------------------------------------------------------------------------

local function onUpdate(self, elapsed)
    for timerName in pairs(activeTimers) do
        updateBar(timerName)
    end
end

---------------------------------------------------------------------------
-- Event Handling
---------------------------------------------------------------------------

local function startTimer(timerName, value, maxValue, scale, paused, label)
    if maxValue == 0 then return end

    activeTimers[timerName] = {
        maxValue = maxValue,
        scale = scale,
        paused = paused,
        label = label,
    }

    local barFrame = getOrCreateBar(timerName)

    -- Set bar color to player's class color
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    if color then
        barFrame.bar:SetStatusBarColor(color.r, color.g, color.b)
    else
        barFrame.bar:SetStatusBarColor(1, 1, 1)
    end

    barFrame.bar:SetMinMaxValues(0, 1)
    barFrame.bar:SetValue(value / maxValue)

    local displayLabel = TIMER_LABELS[timerName] or label or timerName
    barFrame.text:SetText(string_format("%s %s", displayLabel, formatTime(value)))

    barFrame:Show()
    repositionBars()
end

local function stopTimer(timerName)
    activeTimers[timerName] = nil

    local barFrame = bars[timerName]
    if barFrame then
        barFrame:Hide()
    end

    repositionBars()
end

local function pauseTimer(duration)
    -- duration > 0 means paused, 0 means unpaused
    for timerName, info in pairs(activeTimers) do
        info.paused = duration > 0
    end
end

local function onEvent(self, event, ...)
    if event == "MIRROR_TIMER_START" then
        local timerName, value, maxValue, scale, paused, label = ...
        startTimer(timerName, value, maxValue, scale, paused, label)

    elseif event == "MIRROR_TIMER_STOP" then
        local timerName = ...
        stopTimer(timerName)

    elseif event == "MIRROR_TIMER_PAUSE" then
        local duration = ...
        pauseTimer(duration)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Pick up any active mirror timers on login/reload
        for i = 1, MAX_TIMERS do
            local timer, initial, maxValue, scale, paused, label = GetMirrorTimerInfo(i)
            if timer and timer ~= "UNKNOWN" then
                startTimer(timer, GetMirrorTimerProgress(timer), maxValue, scale, paused, label)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Hide Blizzard mirror timers
---------------------------------------------------------------------------

local function hideBlizzardMirrorTimers()
    for i = 1, MAX_TIMERS do
        local frame = _G["MirrorTimer" .. i]
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
        end
    end

    -- Suppress the UIParent-managed mirror timer container if it exists
    if MirrorTimerContainer then
        MirrorTimerContainer:UnregisterAllEvents()
        MirrorTimerContainer:Hide()
    end
end

local function restoreBlizzardMirrorTimers()
    if MirrorTimerContainer then
        MirrorTimerContainer:Show()
        -- Re-register via OnLoad if available
        if MirrorTimerContainer.OnLoad then
            MirrorTimerContainer:OnLoad()
        end
    end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function MirrorBar.Initialize()
    C = ns.Constants.mirrorBar

    -- Check setting
    local show = ns.Settings.GetOption("showMirrorBar")
    if show == false then
        return
    end

    hideBlizzardMirrorTimers()

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("MIRROR_TIMER_START")
    eventFrame:RegisterEvent("MIRROR_TIMER_STOP")
    eventFrame:RegisterEvent("MIRROR_TIMER_PAUSE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", onEvent)
    eventFrame:SetScript("OnUpdate", onUpdate)
end

function MirrorBar.Toggle(value)
    if value then
        hideBlizzardMirrorTimers()
        if eventFrame then
            eventFrame:RegisterEvent("MIRROR_TIMER_START")
            eventFrame:RegisterEvent("MIRROR_TIMER_STOP")
            eventFrame:RegisterEvent("MIRROR_TIMER_PAUSE")
        else
            MirrorBar.Initialize()
        end
    else
        if eventFrame then
            eventFrame:UnregisterAllEvents()
        end
        for timerName, barFrame in pairs(bars) do
            barFrame:Hide()
        end
        activeTimers = {}
        restoreBlizzardMirrorTimers()
    end
end

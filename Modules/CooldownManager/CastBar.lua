local addon, ns = ...

--[[
    Standalone Cast Bar

    Replaces Blizzard's PlayerCastingBarFrame with a DessertUI-styled cast bar.
    Supports standard casts, channels, and empowered casts (Evoker).

    Fully decoupled from oUF — uses Blizzard APIs directly.
]]

ns.CastBar = {}
local CastBar = ns.CastBar

-- Cached globals
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitCastingDuration = UnitCastingDuration
local UnitChannelDuration = UnitChannelDuration
local UnitEmpoweredChannelDuration = UnitEmpoweredChannelDuration
local UnitEmpoweredStagePercentages = UnitEmpoweredStagePercentages
local GetTime = GetTime
local string_format = string.format
local string_sub = string.sub
local string_len = string.len
local math_min = math.min

-- Module state
local castBar
local castBarContainer
local castBarIcon
local castBarText
local castBarTime
local castBarSpark
local empowerPips = {}
local eventFrame
local holdTimer = 0
local isCasting = false
local isChanneling = false
local isEmpowering = false
local castDuration
local channelDuration

-- Constants shorthand
local C

---------------------------------------------------------------------------
-- Frame Creation
---------------------------------------------------------------------------

local function createCastBar()
    local cfg = C.castBar
    local pos = cfg.position

    -- Container frame holds the border/background; StatusBar is inset inside it
    local container = CreateFrame("Frame", "DessertUI_CastBarContainer", UIParent, "BackdropTemplate")
    container:SetSize(cfg.width, cfg.height)
    container:SetPoint(pos.point, UIParent, pos.relative, pos.x, pos.y)
    container:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    container:SetBackdropColor(cfg.background[1], cfg.background[2], cfg.background[3], cfg.background[4])
    container:SetBackdropBorderColor(0, 0, 0, 1)
    container:Hide()

    local frame = CreateFrame("StatusBar", "DessertUI_CastBar", container)
    frame:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
    frame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
    frame:SetStatusBarTexture("Interface\\AddOns\\DessertUI\\Media\\Striped")
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)

    -- Icon (inside bar, left edge, full height — OVERLAY so it renders on top of status bar fill)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(cfg.height - 2, cfg.height - 2)
    icon:SetPoint("LEFT", container, "LEFT", 1, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    castBarIcon = icon

    -- Spell name text (offset past icon)
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont(ns.Constants.fonts.arialNarrow, ns.Constants.fontSizes.small, "OUTLINE")
    text:SetPoint("LEFT", container, "LEFT", cfg.height + 4, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    castBarText = text

    -- Cast time text
    local timeText = frame:CreateFontString(nil, "OVERLAY")
    timeText:SetFont(ns.Constants.fonts.arialNarrow, ns.Constants.fontSizes.small, "OUTLINE")
    timeText:SetPoint("RIGHT", container, "RIGHT", -4, 0)
    timeText:SetJustifyH("RIGHT")
    castBarTime = timeText

    -- Spark (thin bright indicator at current position)
    local spark = frame:CreateTexture(nil, "OVERLAY")
    spark:SetSize(cfg.sparkWidth, cfg.height + 4)
    spark:SetColorTexture(1, 1, 1, 0.8)
    spark:SetBlendMode("ADD")
    castBarSpark = spark

    castBar = frame
    castBarContainer = container
    CastBar.frame = container
    return container
end

---------------------------------------------------------------------------
-- Empowered Cast Pips
---------------------------------------------------------------------------

local function clearEmpowerPips()
    for i = 1, #empowerPips do
        empowerPips[i]:Hide()
    end
end

local function createEmpowerPips(stages)
    clearEmpowerPips()
    if not stages or #stages == 0 then return end

    local cfg = C.castBar
    local cumulative = 0

    for i = 1, #stages do
        cumulative = cumulative + stages[i]

        -- Don't draw a pip at the very end
        if i < #stages then
            local pip = empowerPips[i]
            if not pip then
                pip = castBar:CreateTexture(nil, "OVERLAY")
                pip:SetSize(2, cfg.height)
                pip:SetColorTexture(1, 1, 1, 0.6)
                empowerPips[i] = pip
            end

            local xOffset = (cumulative / 100) * cfg.width
            pip:ClearAllPoints()
            pip:SetPoint("LEFT", castBar, "LEFT", xOffset, 0)
            pip:Show()
        end
    end
end

---------------------------------------------------------------------------
-- Display Helpers
---------------------------------------------------------------------------

local function formatTime(remaining)
    if remaining >= 5 then
        return string_format("%d", remaining)
    else
        return string_format("%.1f", remaining)
    end
end

local function setBarColor(colorKey)
    if colorKey == "casting" then
        local _, class = UnitClass("player")
        local color = class and RAID_CLASS_COLORS[class]
        if color then
            castBar:SetStatusBarColor(color.r, color.g, color.b)
            return
        end
    end
    local colors = C.castBar.colors[colorKey]
    if colors then
        castBar:SetStatusBarColor(colors[1], colors[2], colors[3])
    end
end

---------------------------------------------------------------------------
-- Cast Start / Stop
---------------------------------------------------------------------------

local function startCast()
    local name, _, texture = UnitCastingInfo("player")
    if not name then
        isCasting = false
        return
    end

    castDuration = UnitCastingDuration("player")
    if not castDuration then
        isCasting = false
        return
    end

    isCasting = true
    isChanneling = false
    isEmpowering = false
    holdTimer = 0

    castBarIcon:SetTexture(texture)
    castBarText:SetText(name or "")
    setBarColor("casting")
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    castBarSpark:Show()
    clearEmpowerPips()
    castBarContainer:Show()
end

local function startChannel()
    local name, _, texture = UnitChannelInfo("player")
    if not name then
        isChanneling = false
        return
    end

    channelDuration = UnitChannelDuration("player")
    if not channelDuration then
        isChanneling = false
        return
    end

    isCasting = false
    isChanneling = true
    isEmpowering = false
    holdTimer = 0

    castBarIcon:SetTexture(texture)
    castBarText:SetText(name or "")
    setBarColor("channeling")
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(1)
    castBarSpark:Show()
    clearEmpowerPips()
    castBarContainer:Show()
end

local function startEmpower()
    local name, _, texture = UnitChannelInfo("player")
    if not name then
        isEmpowering = false
        return
    end

    channelDuration = UnitEmpoweredChannelDuration("player")
    if not channelDuration then
        isEmpowering = false
        return
    end

    isCasting = false
    isChanneling = false
    isEmpowering = true
    holdTimer = 0

    castBarIcon:SetTexture(texture)
    castBarText:SetText(name or "")
    setBarColor("empowering")
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    castBarSpark:Show()

    -- Create stage pips
    local stages = { UnitEmpoweredStagePercentages("player") }
    createEmpowerPips(stages)

    castBarContainer:Show()
end

local function stopCast(failed)
    isCasting = false
    isChanneling = false
    isEmpowering = false
    castBarSpark:Hide()

    if failed then
        setBarColor("failed")
        holdTimer = C.castBar.holdTime
    else
        holdTimer = C.castBar.holdTime * 0.5
    end
end

---------------------------------------------------------------------------
-- OnUpdate
---------------------------------------------------------------------------

local function onUpdate(self, elapsed)
    if not castBarContainer:IsShown() then return end

    -- Handle hold timer (brief display after cast ends)
    if holdTimer > 0 then
        holdTimer = holdTimer - elapsed
        if holdTimer <= 0 then
            holdTimer = 0
            castBarContainer:Hide()
            clearEmpowerPips()
        end
        return
    end

    if isCasting then
        if not castDuration then
            stopCast(false)
            return
        end

        local remaining = castDuration:GetRemainingDuration()
        local total = castDuration:GetTotalDuration()
        if not remaining or not total or total == 0 then
            stopCast(false)
            return
        end

        local progress = 1 - (remaining / total)
        if progress > 1 then progress = 1 end
        if progress < 0 then progress = 0 end

        castBar:SetValue(progress)
        castBarTime:SetText(formatTime(remaining))

        -- Position spark
        local sparkX = progress * C.castBar.width
        castBarSpark:ClearAllPoints()
        castBarSpark:SetPoint("CENTER", castBar, "LEFT", sparkX, 0)

    elseif isChanneling or isEmpowering then
        local durObj = isEmpowering and channelDuration or channelDuration
        if not durObj then
            stopCast(false)
            return
        end

        local remaining = durObj:GetRemainingDuration()
        local total = durObj:GetTotalDuration()
        if not remaining or not total or total == 0 then
            stopCast(false)
            return
        end

        local progress
        if isEmpowering then
            -- Empower fills left to right
            progress = 1 - (remaining / total)
        else
            -- Channel drains right to left
            progress = remaining / total
        end

        if progress > 1 then progress = 1 end
        if progress < 0 then progress = 0 end

        castBar:SetValue(progress)
        castBarTime:SetText(formatTime(remaining))

        -- Position spark
        local sparkX = progress * C.castBar.width
        castBarSpark:ClearAllPoints()
        castBarSpark:SetPoint("CENTER", castBar, "LEFT", sparkX, 0)
    end
end

---------------------------------------------------------------------------
-- Event Handling
---------------------------------------------------------------------------

local function onEvent(self, event, ...)
    local unit = ...

    if event == "UNIT_SPELLCAST_START" then
        if unit ~= "player" then return end
        startCast()

    elseif event == "UNIT_SPELLCAST_STOP" then
        if unit ~= "player" then return end
        if isCasting then
            castBar:SetValue(1)
            stopCast(false)
        end

    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        if unit ~= "player" then return end
        stopCast(true)

    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        if unit ~= "player" then return end
        if isCasting then
            setBarColor("casting")
        end

    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        if unit ~= "player" then return end
        setBarColor("nonInterruptible")

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit ~= "player" then return end
        startChannel()

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if unit ~= "player" then return end
        if isChanneling then
            stopCast(false)
        end

    elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
        if unit ~= "player" then return end
        startEmpower()

    elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        if unit ~= "player" then return end
        if isEmpowering then
            castBar:SetValue(1)
            stopCast(false)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Check for in-progress casts on login/reload
        if UnitCastingInfo("player") then
            startCast()
        elseif UnitChannelInfo("player") then
            startChannel()
        end
    end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function CastBar.Initialize()
    C = ns.Constants.cooldownManager

    createCastBar()

    -- Disable Blizzard's cast bar
    if PlayerCastingBarFrame then
        PlayerCastingBarFrame:UnregisterAllEvents()
        PlayerCastingBarFrame:Hide()
    end

    -- Apply initial visibility from settings
    local showCastBar = ns.Settings.GetOption("showCastBar")
    if showCastBar == false then
        CastBar.Toggle(false)
        return
    end

    -- Create event frame
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", onEvent)

    -- OnUpdate for smooth progress
    castBar:SetScript("OnUpdate", onUpdate)

    -- Cast bar has no fader — if it's visible, it should be at full alpha
end

function CastBar.Toggle(value)
    if value then
        -- Re-enable our cast bar
        if castBarContainer then castBarContainer:Show() end
        if eventFrame then
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
            eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
        end
        -- Keep Blizzard's disabled
        if PlayerCastingBarFrame then
            PlayerCastingBarFrame:UnregisterAllEvents()
            PlayerCastingBarFrame:Hide()
        end
    else
        -- Disable our cast bar, restore Blizzard's
        if castBarContainer then castBarContainer:Hide() end
        if eventFrame then eventFrame:UnregisterAllEvents() end
        if PlayerCastingBarFrame then
            PlayerCastingBarFrame:OnLoad(PlayerCastingBarFrame)
        end
    end
end

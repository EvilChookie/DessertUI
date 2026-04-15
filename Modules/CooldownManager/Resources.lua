local addon, ns = ...

--[[
    Standalone Resource Display

    Primary power bar (mana, rage, energy, etc.) and secondary class power
    (combo points, holy power, runes, etc.) as mini status bars.

    Fully decoupled from oUF — uses Blizzard APIs directly.
]]

ns.Resources = {}
local Resources = ns.Resources

-- Cached globals
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitStagger = UnitStagger
local UnitHealthMax = UnitHealthMax
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetShapeshiftFormID = GetShapeshiftFormID
local GetRuneCooldown = GetRuneCooldown
local InCombatLockdown = InCombatLockdown
local string_format = string.format
local math_floor = math.floor

-- Module state
local primaryBar
local secondaryFrame
local secondaryPips = {}
local currentSpecID = 0
local currentPowerType = 0
local currentSecondary = nil
local previousPipValues = {}
local eventFrame

-- Maelstrom Weapon spell ID for Enhancement Shaman aura tracking
local MAELSTROM_WEAPON_SPELL_ID = 344179

-- Reusable rune data table and sort comparator (avoids per-tick allocation)
local runeData = {}
for i = 1, 6 do
    runeData[i] = { index = 0, ready = false, remaining = 0, start = 0, duration = 0 }
end
local function runeSort(a, b)
    if a.ready ~= b.ready then return a.ready end
    return a.remaining < b.remaining
end

-- Constants shorthand (populated on init)
local C

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function getSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return 0 end
    return GetSpecializationInfo(specIndex) or 0
end

local function getPowerColor(powerType)
    local colors = C.powerColors[powerType]
    if colors then return colors[1], colors[2], colors[3] end
    return 1, 1, 1
end

local function getSecondaryColor(key)
    local colors = C.secondaryColors[key]
    if colors then return colors[1], colors[2], colors[3] end
    return 1, 1, 1
end

-- Play gain animation when a pip transitions from empty to filled
local function playPipGainIfNew(pip, index, filled)
    if filled == 1 and (previousPipValues[index] or 0) == 0 then
        pip.gainAnim:Stop()
        pip.gainAnim:Play()
    end
    previousPipValues[index] = filled
end

-- Shared fader configuration for resource frames
local function createResourceFaderConfig()
    return {
        enableMouseover = true,
        enableCombat = true,
        fadeInAlpha = 1,
        fadeOutAlpha = 0,
        fadeInDuration = 0.15,
        fadeOutDuration = 0.15,
        fadeInSmooth = "IN_OUT",
        fadeOutSmooth = "IN_OUT",
        inCombatAlpha = 1,
        outCombatAlpha = 0,
        inCombatDuration = 0.15,
        outCombatDuration = 0.15,
        inCombatSmooth = "IN_OUT",
        outCombatSmooth = "IN_OUT",
        skipEnableMouse = true,
        skipMouseoverHooks = true,
    }
end

---------------------------------------------------------------------------
-- Primary Power Bar
---------------------------------------------------------------------------

local function createPrimaryBar()
    if primaryBar then return primaryBar end

    local cfg = C.resources.primaryBar
    local pos = cfg.position

    local frame = CreateFrame("StatusBar", "DessertUI_PrimaryPower", UIParent, "BackdropTemplate")
    frame:SetSize(cfg.width, cfg.height)
    frame:SetPoint(pos.point, UIParent, pos.relative, pos.x, pos.y)
    frame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    frame:SetBackdropColor(cfg.background[1], cfg.background[2], cfg.background[3], cfg.background[4])
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    -- Power text (right-aligned)
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetFont(ns.Constants.fonts.arialNarrow, ns.Constants.fontSizes.small, "OUTLINE")
    frame.text:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    frame.text:SetJustifyH("RIGHT")

    -- Percentage text for mana (left-aligned)
    frame.pctText = frame:CreateFontString(nil, "OVERLAY")
    frame.pctText:SetFont(ns.Constants.fonts.arialNarrow, ns.Constants.fontSizes.small, "OUTLINE")
    frame.pctText:SetPoint("LEFT", frame, "LEFT", 2, 0)
    frame.pctText:SetJustifyH("LEFT")

    primaryBar = frame
    return frame
end

local function updatePrimaryBar()
    if not primaryBar or not primaryBar:IsShown() then return end

    -- UnitPower returns "secret" values in modern WoW that cannot be used in
    -- arithmetic. StatusBar:SetValue() accepts them directly, but for text
    -- display we must use UnitPowerPercent or AbbreviateLargeNumbers (which
    -- handle secret values internally).
    local power = UnitPower("player", currentPowerType)
    local maxPower = UnitPowerMax("player", currentPowerType)

    if maxPower == 0 then
        primaryBar:SetMinMaxValues(0, 1)
        primaryBar:SetValue(0)
        primaryBar.text:SetText("")
        primaryBar.pctText:SetText("")
        return
    end

    primaryBar:SetMinMaxValues(0, maxPower)

    -- SetValue accepts secret values directly
    if Enum and Enum.StatusBarInterpolation then
        primaryBar:SetValue(power, Enum.StatusBarInterpolation.ExponentialEaseOut)
    else
        primaryBar:SetValue(power)
    end

    -- Display power text — use AbbreviateLargeNumbers which handles secret values
    primaryBar.text:SetText(AbbreviateLargeNumbers(power) .. " / " .. AbbreviateLargeNumbers(maxPower))
    primaryBar.pctText:SetText("")
end

local function refreshPrimaryPowerType()
    currentPowerType = UnitPowerType("player") or 0
    if not primaryBar then return end
    local r, g, b = getPowerColor(currentPowerType)
    primaryBar:SetStatusBarColor(r, g, b)
    updatePrimaryBar()
end

---------------------------------------------------------------------------
-- Secondary Power: Pip Creation & Management
---------------------------------------------------------------------------

local function clearSecondaryPips()
    for i = 1, #secondaryPips do
        secondaryPips[i]:Hide()
        secondaryPips[i]:ClearAllPoints()
        secondaryPips[i]:SetMinMaxValues(0, 1)
        secondaryPips[i]:SetValue(0)
    end
end

local function createPip(index)
    if secondaryPips[index] then return secondaryPips[index] end

    local cfg = C.resources.secondaryBar
    local pip = CreateFrame("StatusBar", "DessertUI_Pip" .. index, secondaryFrame, "BackdropTemplate")
    pip:SetSize(cfg.pipHeight, cfg.pipHeight)  -- initial size; layoutPips will resize
    pip:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    pip:SetMinMaxValues(0, 1)
    pip:SetValue(0)
    pip:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    pip:SetBackdropColor(cfg.background[1], cfg.background[2], cfg.background[3], cfg.background[4])
    pip:SetBackdropBorderColor(0, 0, 0, 1)

    -- Gain animation: brief alpha flash
    pip.gainAnim = pip:CreateAnimationGroup()
    local flash = pip.gainAnim:CreateAnimation("Alpha")
    flash:SetFromAlpha(0.4)
    flash:SetToAlpha(1)
    flash:SetDuration(0.15)
    flash:SetSmoothing("OUT")
    pip.gainAnim.finAlpha = 1

    secondaryPips[index] = pip
    return pip
end

local function layoutPips(count)
    if not secondaryFrame then return end
    local cfg = C.resources.secondaryBar
    local containerWidth = C.resources.primaryBar.width
    local pipWidth = (containerWidth - cfg.pipSpacing * (count - 1)) / count

    clearSecondaryPips()

    for i = 1, count do
        local pip = createPip(i)
        pip:ClearAllPoints()
        pip:SetSize(pipWidth, cfg.pipHeight)
        if i == 1 then
            pip:SetPoint("LEFT", secondaryFrame, "LEFT", 0, 0)
        else
            pip:SetPoint("LEFT", secondaryPips[i - 1], "RIGHT", cfg.pipSpacing, 0)
        end
        pip:Show()
    end
end

---------------------------------------------------------------------------
-- Secondary Power: Update Logic
---------------------------------------------------------------------------

local function updatePips_Standard(powerType, colorKey, maxOverride)
    local current = UnitPower("player", powerType)
    local max = maxOverride or UnitPowerMax("player", powerType)
    if max == 0 then return end

    -- Ensure pip count matches
    if #secondaryPips < max or not secondaryPips[1]:IsShown() then
        layoutPips(max)
    end

    local r, g, b = getSecondaryColor(colorKey)

    for i = 1, max do
        local pip = secondaryPips[i]
        if not pip then break end

        local filled = (i <= current) and 1 or 0
        pip:SetStatusBarColor(r, g, b)
        pip:SetValue(filled)
        playPipGainIfNew(pip, i, filled)
    end
end

local function updatePips_ComboPoints()
    local current = UnitPower("player", Enum.PowerType.ComboPoints)
    local max = UnitPowerMax("player", Enum.PowerType.ComboPoints)
    if max == 0 then return end

    if #secondaryPips < max or not secondaryPips[1]:IsShown() then
        layoutPips(max)
    end

    local r, g, b = getSecondaryColor("COMBO_POINTS")
    local cr, cg, cb = getSecondaryColor("COMBO_CHARGED")

    for i = 1, max do
        local pip = secondaryPips[i]
        if not pip then break end

        local filled = (i <= current) and 1 or 0
        -- Charged combo points (beyond base 5) get alternate color
        if filled == 1 and i > 5 then
            pip:SetStatusBarColor(cr, cg, cb)
        else
            pip:SetStatusBarColor(r, g, b)
        end
        pip:SetValue(filled)
        playPipGainIfNew(pip, i, filled)
    end
end

local function updateRunes()
    local cfg = C.resources.secondaryBar
    if #secondaryPips < 6 or not secondaryPips[1]:IsShown() then
        layoutPips(6)
    end

    local colorKey = currentSecondary and currentSecondary.colorKey or "RUNES_BLOOD"
    local r, g, b = getSecondaryColor(colorKey)

    -- Collect rune data and sort: ready first, then by remaining CD
    for i = 1, 6 do
        local start, duration, ready = GetRuneCooldown(i)
        local remaining = 0
        if not ready and start and duration and duration > 0 then
            remaining = (start + duration) - GetTime()
            if remaining < 0 then remaining = 0 end
        end
        local entry = runeData[i]
        entry.index = i
        entry.ready = ready
        entry.remaining = remaining
        entry.start = start
        entry.duration = duration
    end

    table.sort(runeData, runeSort)

    for i = 1, 6 do
        local pip = secondaryPips[i]
        local rune = runeData[i]
        if not pip or not rune then break end

        pip:SetStatusBarColor(r, g, b)
        if rune.ready then
            pip:SetValue(1)
        else
            local progress = 0
            if rune.duration and rune.duration > 0 then
                local elapsed = GetTime() - (rune.start or 0)
                progress = elapsed / rune.duration
                if progress > 1 then progress = 1 end
            end
            pip:SetValue(progress)
        end
    end
end

local function updateStagger()
    local stagger = UnitStagger("player") or 0
    local maxHealth = UnitHealthMax("player")
    if maxHealth == 0 then return end

    -- Show as single bar
    if #secondaryPips < 1 or not secondaryPips[1]:IsShown() then
        local cfg = C.resources.secondaryBar
        clearSecondaryPips()
        local pip = createPip(1)
        pip:SetSize(C.resources.primaryBar.width, cfg.pipHeight)
        pip:ClearAllPoints()
        pip:SetPoint("CENTER", secondaryFrame, "CENTER", 0, 0)
        pip:Show()
    end

    local pip = secondaryPips[1]

    -- UnitStagger and UnitHealthMax return normal (non-secret) values
    pip:SetMinMaxValues(0, maxHealth)
    pip:SetValue(stagger)

    -- Color by stagger tier (% of max health)
    local pct = stagger / maxHealth
    if pct < 0.3 then
        local r, g, b = getSecondaryColor("STAGGER_LIGHT")
        pip:SetStatusBarColor(r, g, b)
    elseif pct < 0.6 then
        local r, g, b = getSecondaryColor("STAGGER_MODERATE")
        pip:SetStatusBarColor(r, g, b)
    else
        local r, g, b = getSecondaryColor("STAGGER_HEAVY")
        pip:SetStatusBarColor(r, g, b)
    end
end

local function updateMaelstromWeapon()
    -- Enhancement Shaman maelstrom tracked via aura stacks
    local stacks = 0
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(MAELSTROM_WEAPON_SPELL_ID)
    if aura and aura.applications then
        stacks = aura.applications
    end
    local max = currentSecondary and currentSecondary.max or 10

    if #secondaryPips < max or not secondaryPips[1]:IsShown() then
        layoutPips(max)
    end

    local r, g, b = getSecondaryColor("MAELSTROM")
    for i = 1, max do
        local pip = secondaryPips[i]
        if not pip then break end
        local filled = (i <= stacks) and 1 or 0
        pip:SetStatusBarColor(r, g, b)
        pip:SetValue(filled)
        playPipGainIfNew(pip, i, filled)
    end
end

local function updateDestructionShards()
    -- Destruction shards as continuous bar. Use the standard (non-raw) power
    -- and let SetMinMaxValues handle scaling (avoids arithmetic on secret values).
    local power = UnitPower("player", Enum.PowerType.SoulShards)
    local maxPower = UnitPowerMax("player", Enum.PowerType.SoulShards)

    if #secondaryPips < 1 or not secondaryPips[1]:IsShown() then
        clearSecondaryPips()
        local pip = createPip(1)
        pip:SetSize(C.resources.primaryBar.width, C.resources.secondaryBar.pipHeight)
        pip:ClearAllPoints()
        pip:SetPoint("CENTER", secondaryFrame, "CENTER", 0, 0)
        pip:Show()
    end

    local pip = secondaryPips[1]
    local r, g, b = getSecondaryColor("SOUL_SHARDS")
    pip:SetStatusBarColor(r, g, b)
    pip:SetMinMaxValues(0, maxPower)

    if Enum and Enum.StatusBarInterpolation then
        pip:SetValue(power, Enum.StatusBarInterpolation.ExponentialEaseOut)
    else
        pip:SetValue(power)
    end
end

local function updateEssence()
    -- UnitPower returns secret values; comparisons (<=) work but arithmetic
    -- (+, /, %) does not. Show full/empty pips only — no partial recharge
    -- display to avoid secret value arithmetic.
    local current = UnitPower("player", Enum.PowerType.Essence)
    local max = UnitPowerMax("player", Enum.PowerType.Essence)
    if max == 0 then return end

    if #secondaryPips < max or not secondaryPips[1]:IsShown() then
        layoutPips(max)
    end

    local r, g, b = getSecondaryColor("ESSENCE")

    for i = 1, max do
        local pip = secondaryPips[i]
        if not pip then break end

        local filled = (i <= current) and 1 or 0
        pip:SetStatusBarColor(r, g, b)
        pip:SetValue(filled)
        playPipGainIfNew(pip, i, filled)
    end
end

local function updateSecondary()
    if not currentSecondary or not secondaryFrame or not secondaryFrame:IsShown() then return end

    local pt = currentSecondary.powerType
    local dt = currentSecondary.displayType

    -- Check form requirement (Druid Feral: only in Cat Form)
    if currentSecondary.formRequired then
        local formID = GetShapeshiftFormID()
        if formID ~= currentSecondary.formRequired then
            clearSecondaryPips()
            return
        end
    end

    if pt == Enum.PowerType.Runes then
        updateRunes()
    elseif pt == "STAGGER" then
        updateStagger()
    elseif pt == "MAELSTROM_WEAPON" then
        updateMaelstromWeapon()
    elseif pt == Enum.PowerType.ComboPoints then
        updatePips_ComboPoints()
    elseif pt == Enum.PowerType.SoulShards and dt == "bar" then
        updateDestructionShards()
    elseif pt == Enum.PowerType.Essence then
        updateEssence()
    else
        updatePips_Standard(pt, currentSecondary.colorKey, currentSecondary.max)
    end
end

---------------------------------------------------------------------------
-- Secondary Power Frame
---------------------------------------------------------------------------

local function createSecondaryFrame()
    if secondaryFrame then return secondaryFrame end

    secondaryFrame = CreateFrame("Frame", "DessertUI_SecondaryPower", UIParent)
    secondaryFrame:SetSize(C.resources.primaryBar.width, C.resources.secondaryBar.pipHeight)
    -- Anchor below primary bar
    if primaryBar then
        secondaryFrame:SetPoint("TOP", primaryBar, "BOTTOM", 0, -C.resources.secondaryBar.pipSpacing)
    else
        local pos = C.resources.primaryBar.position
        secondaryFrame:SetPoint(pos.point, UIParent, pos.relative, pos.x, pos.y - C.resources.primaryBar.height)
    end
    return secondaryFrame
end

---------------------------------------------------------------------------
-- OnUpdate for smooth rune/essence recharge
---------------------------------------------------------------------------

local runeUpdateElapsed = 0
local function onUpdate(self, elapsed)
    if not currentSecondary then return end

    local pt = currentSecondary.powerType
    if pt == Enum.PowerType.Runes then
        runeUpdateElapsed = runeUpdateElapsed + elapsed
        if runeUpdateElapsed >= 0.05 then
            runeUpdateElapsed = 0
            updateRunes()
        end
    elseif pt == Enum.PowerType.Essence then
        runeUpdateElapsed = runeUpdateElapsed + elapsed
        if runeUpdateElapsed >= 0.05 then
            runeUpdateElapsed = 0
            updateEssence()
        end
    end
end

---------------------------------------------------------------------------
-- Spec Change / Initialization
---------------------------------------------------------------------------

local function refreshSpec()
    currentSpecID = getSpecID()
    currentSecondary = C.specResources[currentSpecID]

    -- Refresh primary power
    refreshPrimaryPowerType()

    -- Reset secondary — clear stale state before rebuilding
    wipe(previousPipValues)
    clearSecondaryPips()
    runeUpdateElapsed = 0

    -- Only run OnUpdate for specs that need tick-based recharge animation
    if secondaryFrame then
        local needsTick = currentSecondary and (
            currentSecondary.powerType == Enum.PowerType.Runes or
            currentSecondary.powerType == Enum.PowerType.Essence
        )
        secondaryFrame:SetScript("OnUpdate", needsTick and onUpdate or nil)
    end

    local cfg = C.resources.primaryBar
    if currentSecondary and secondaryFrame then
        -- Secondary exists: primary gets 25% height
        if primaryBar then primaryBar:SetHeight(cfg.height) end
        secondaryFrame:Show()
        updateSecondary()
    elseif secondaryFrame then
        -- No secondary: primary expands to 50% height
        if primaryBar then primaryBar:SetHeight(cfg.expandedHeight) end
        secondaryFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- Event Handling
---------------------------------------------------------------------------

local function onEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        refreshSpec()

    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" then
        local unit = ...
        if unit ~= "player" then return end
        updatePrimaryBar()
        updateSecondary()

    elseif event == "UNIT_MAXPOWER" then
        local unit = ...
        if unit ~= "player" then return end
        updatePrimaryBar()
        -- Max power change may change pip count
        wipe(previousPipValues)
        clearSecondaryPips()
        updateSecondary()

    elseif event == "UNIT_DISPLAYPOWER" then
        local unit = ...
        if unit ~= "player" then return end
        refreshPrimaryPowerType()

    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        refreshPrimaryPowerType()
        updateSecondary()

    elseif event == "RUNE_POWER_UPDATE" then
        updateSecondary()

    elseif event == "UNIT_AURA" then
        -- For Maelstrom Weapon tracking
        local unit = ...
        if unit ~= "player" then return end
        if currentSecondary and currentSecondary.powerType == "MAELSTROM_WEAPON" then
            updateSecondary()
        end

    elseif event == "UNIT_HEALTH" then
        -- For stagger display
        local unit = ...
        if unit ~= "player" then return end
        if currentSecondary and currentSecondary.powerType == "STAGGER" then
            updateSecondary()
        end
    end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function Resources.Initialize()
    C = ns.Constants.cooldownManager

    -- Guard against re-initialization (PLAYER_ENTERING_WORLD fires multiple times)
    if eventFrame then
        refreshSpec()
        return
    end

    -- Create frames
    createPrimaryBar()
    createSecondaryFrame()

    -- Apply initial visibility from settings
    local showPrimary = ns.Settings.GetOption("showPrimaryPower")
    local showSecondary = ns.Settings.GetOption("showSecondaryPower")
    if showPrimary == false then primaryBar:Hide() end
    if showSecondary == false then secondaryFrame:Hide() end

    -- Create event frame
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    eventFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    eventFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    eventFrame:RegisterEvent("RUNE_POWER_UPDATE")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    eventFrame:RegisterUnitEvent("UNIT_HEALTH", "player")
    eventFrame:SetScript("OnEvent", onEvent)

    -- Register with fader system if setting is enabled
    if ns.Fader and ns.Settings and ns.Settings.GetOption("resourceFader") then
        local faderConfig = createResourceFaderConfig()
        ns.Fader.Create(primaryBar, faderConfig)
        ns.Fader.Create(secondaryFrame, faderConfig)
    end

    -- Initial spec detection
    refreshSpec()
end

function Resources.TogglePrimary(value)
    if not primaryBar then return end
    if value then
        primaryBar:Show()
        updatePrimaryBar()
    else
        primaryBar:Hide()
    end
end

function Resources.ToggleSecondary(value)
    if not secondaryFrame then return end
    local cfg = C.resources.primaryBar
    if value then
        if primaryBar then primaryBar:SetHeight(cfg.height) end
        secondaryFrame:Show()
        updateSecondary()
    else
        if primaryBar then primaryBar:SetHeight(cfg.expandedHeight) end
        secondaryFrame:Hide()
        clearSecondaryPips()
    end
end

function Resources.ToggleFader(value)
    if not ns.Fader then return end
    local faderConfig = createResourceFaderConfig()
    local frames = { primaryBar, secondaryFrame }
    for _, frame in ipairs(frames) do
        if frame then
            if value then
                if frame.__faderInitialized and frame.__faderDisabled then
                    ns.Fader.Enable(frame)
                else
                    ns.Fader.Create(frame, faderConfig)
                end
            else
                ns.Fader.Disable(frame)
            end
        end
    end
end

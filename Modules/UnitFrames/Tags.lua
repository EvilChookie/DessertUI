local addon, ns = ...

-- Ensure namespaces exist
ns.UnitFrames = ns.UnitFrames or {}
local UnitFrames = ns.UnitFrames
local Utils = ns.Utils
local oUF = ns and ns.oUF

if not oUF then
    return
end

-- Cache frequently used functions
local string_format = string.format

-- Cache CurveConstants with fallback for safety
local SCALE_TO_100 = CurveConstants and CurveConstants.ScaleTo100 or nil

oUF.Tags.Events["dUI_Name"] = "UNIT_HEALTH UNIT_CLASSIFICATION_CHANGED UNIT_CONNECTION UNIT_FACTION UNIT_NAME_UPDATE"
oUF.Tags.Methods["dUI_Name"] = function(u)
	local _, class = UnitClass(u)
    local reaction = UnitReaction(u, "player")
    local name = GetUnitName(u)
    local color

    -- Protect against nil name
    if not name then
        return ""
    end

	if UnitIsDead(u) or UnitIsGhost(u) or not UnitIsConnected(u) then
		color = "|cffA0A0A0"
	elseif UnitIsTapDenied(u) then
		color = Utils.Hex(oUF.colors.tapped)
	elseif u == "pet" then
		color = Utils.Hex(oUF.colors.class[class])
	elseif UnitIsPlayer(u) then
		color = Utils.Hex(oUF.colors.class[class])
	elseif reaction then
		color = Utils.Hex(oUF.colors.reaction[reaction])
	else
		color = Utils.Hex(1, 1, 1)
    end

    return (color .. name .."|r")
end

-- A quick tag for status (Dead, Disconnect or Ghost)
oUF.Tags.Events["dUI_Status"] = 'UNIT_HEALTH UNIT_CLASSIFICATION_CHANGED'
oUF.Tags.Methods["dUI_Status"] = function(u)
	if UnitIsDead(u) then
		return "|cffCFCFCF(Dead)|r"
	elseif UnitIsGhost(u) then
		return "|cffCFCFCF(Ghost)|r"
	elseif not UnitIsConnected(u) then
		return "|cffCFCFCF(Offline)|r"
	end
end

-- Classification tag for target (Elite, Rare, Boss, etc.)
oUF.Tags.Events["dUI_Classification"] = 'UNIT_CLASSIFICATION_CHANGED'
oUF.Tags.Methods["dUI_Classification"] = function(u)
	local classification = UnitClassification(u)
	if classification and classification ~= "normal"and classification ~= "" then
		return ns.Constants.classifications[classification]
	end
	return ""
end

-- Colour our health absed on percentage. As health goes up or down increases the amount of red or green that's present
oUF.Tags.Events["dUI_HP"] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CLASSIFICATION_CHANGED'
oUF.Tags.Methods["dUI_HP"] = function(u)
    -- Use UnitHealthPercent to handle secret health values
    -- Using white color for now to avoid arithmetic on secret values
    local healthPercentage = UnitHealthPercent(u, true, SCALE_TO_100)
    return string_format("|cffffffff%.0f%%|r", healthPercentage)
end

-- Health percentage with class color (for player)
oUF.Tags.Events["dUI_HP_Class"] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CLASSIFICATION_CHANGED'
oUF.Tags.Methods["dUI_HP_Class"] = function(u)
    -- Use UnitHealthPercent to handle secret health values
    local healthPercentage = UnitHealthPercent(u, true, SCALE_TO_100)

    -- Get player class color
    local _, class = UnitClass(u)
    local color = "|cffffffff"  -- Default to white

    if class and oUF.colors.class[class] then
        color = Utils.Hex(oUF.colors.class[class])
    end

    return string_format("%s%.0f%%|r", color, healthPercentage)
end

-- Short health value using ShortNumber function
oUF.Tags.Events["dUI_ShortHP"] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CLASSIFICATION_CHANGED'
oUF.Tags.Methods["dUI_ShortHP"] = function(u)
    local health = UnitHealth(u)
    return Utils.ShortNumber(health)
end

-- Short health with max health (e.g., "2.5k/5.0k")
oUF.Tags.Events["dUI_ShortHPFull"] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CLASSIFICATION_CHANGED'
oUF.Tags.Methods["dUI_ShortHPFull"] = function(u)
    local health = UnitHealth(u)
    local maxHealth = UnitHealthMax(u)
    return string_format("%s/%s", Utils.ShortNumber(health), Utils.ShortNumber(maxHealth))
end

-- Combined tag: Health percentage and name in one string
-- This avoids needing to calculate string widths on secret values
oUF.Tags.Events["dUI_HPAndName"] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CLASSIFICATION_CHANGED UNIT_CONNECTION UNIT_FACTION UNIT_NAME_UPDATE'
oUF.Tags.Methods["dUI_HPAndName"] = function(u)
    -- Get health percentage (white color)
    local healthPercentage = UnitHealthPercent(u, true, SCALE_TO_100)
    local healthText = string_format("|cffffffff%.0f%%|r", healthPercentage)

    -- Get colored name
    local _, class = UnitClass(u)
    local reaction = UnitReaction(u, "player")
    local name = GetUnitName(u)
    local color

    if not name then
        return healthText
    end

    if UnitIsDead(u) or UnitIsGhost(u) or not UnitIsConnected(u) then
        color = "|cffA0A0A0"
    elseif UnitIsTapDenied(u) then
        color = Utils.Hex(oUF.colors.tapped)
    elseif u == "pet" then
        color = Utils.Hex(oUF.colors.class[class])
    elseif UnitIsPlayer(u) then
        color = Utils.Hex(oUF.colors.class[class])
    elseif reaction then
        color = Utils.Hex(oUF.colors.reaction[reaction])
    else
        color = Utils.Hex(1, 1, 1)
    end

    return healthText .. " " .. color .. name .. "|r"
end
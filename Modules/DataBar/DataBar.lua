local addon, ns = ...

--[[
    Data Bar Module

    Displays a thin text panel across the bottom of the screen with a
    slate background and class-colored top border.
    Uses the action-bar style combat fader (hidden in combat).
]]

ns.DataBar = {}
local DataBar = ns.DataBar

-- Cached functions
local GetFramerate = GetFramerate
local GetInventoryItemDurability = GetInventoryItemDurability
local GetInventoryItemLink = GetInventoryItemLink
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local GetXPExhaustion = GetXPExhaustion
local UnitLevel = UnitLevel
local GetMaxLevelForPlayerExpansion = GetMaxLevelForPlayerExpansion
local string_format = string.format
local math_floor = math.floor
local math_ceil = math.ceil

-- Module state
local frame
local NUM_BUBBLES = 10
local UPDATE_INTERVAL = 1.0

---------------------------------------------------------------------------
-- XP helpers
---------------------------------------------------------------------------

local function updateXPText(f)
    if not f.xpText then return end
    local current_xp = UnitXP("player")
    local max_xp = UnitXPMax("player")
    local pct = max_xp > 0 and (current_xp / max_xp * 100) or 0
    f.xpText:SetText(string_format("%.1f%% xp", pct))
end

---------------------------------------------------------------------------
-- Reputation helpers
---------------------------------------------------------------------------

local function updateRepText(f)
    if not f.repText then return end

    local data = C_Reputation.GetWatchedFactionData()
    if not data then
        f.repText:SetText("")
        f.repFrame:Hide()
        return
    end

    f.repFrame:Show()

    local name = data.name or "Unknown"

    -- Check for major/renown faction
    local major_info = C_MajorFactions.GetMajorFactionData(data.factionID)
    if major_info and major_info.renownLevel then
        local is_paragon = C_Reputation.IsFactionParagon(data.factionID)

        if is_paragon then
            local current, threshold = C_Reputation.GetFactionParagonInfo(data.factionID)
            local paragon_value = current % threshold
            local pct = threshold > 0 and (paragon_value / threshold * 100) or 0
            f.repText:SetText(string_format("%s %.1f%%", name, pct))
        else
            local current = major_info.renownReputationEarned or 0
            local max = major_info.renownLevelThreshold or 1
            local pct = max > 0 and (current / max * 100) or 0
            f.repText:SetText(string_format("%s %.1f%%", name, pct))
        end
    else
        -- Traditional reputation
        local current = data.currentStanding - data.currentReactionThreshold
        local max = data.nextReactionThreshold - data.currentReactionThreshold
        local pct = max > 0 and (current / max * 100) or 0
        f.repText:SetText(string_format("%s %.1f%%", name, pct))
    end
end

---------------------------------------------------------------------------
-- Durability helpers
---------------------------------------------------------------------------

local DURABILITY_SLOTS = {
    INVSLOT_HEAD, INVSLOT_SHOULDER, INVSLOT_CHEST, INVSLOT_WAIST,
    INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_WRIST, INVSLOT_HAND,
    INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED,
}

local SLOT_NAMES = {
    [INVSLOT_HEAD] = "Head",
    [INVSLOT_SHOULDER] = "Shoulder",
    [INVSLOT_CHEST] = "Chest",
    [INVSLOT_WAIST] = "Waist",
    [INVSLOT_LEGS] = "Legs",
    [INVSLOT_FEET] = "Feet",
    [INVSLOT_WRIST] = "Wrist",
    [INVSLOT_HAND] = "Hands",
    [INVSLOT_MAINHAND] = "Main Hand",
    [INVSLOT_OFFHAND] = "Off Hand",
    [INVSLOT_RANGED] = "Ranged",
}

local function getDurabilityPercent()
    local total_current, total_max = 0, 0
    local lowest = 1
    for _, slot in ipairs(DURABILITY_SLOTS) do
        local current, max = GetInventoryItemDurability(slot)
        if current and max and max > 0 then
            total_current = total_current + current
            total_max = total_max + max
            local slot_pct = current / max
            if slot_pct < lowest then lowest = slot_pct end
        end
    end
    local pct = total_max > 0 and (total_current / total_max * 100) or 100
    return pct, lowest
end

local function updateDurabilityText(f)
    if not f.durabilityText then return end
    local pct, lowest = getDurabilityPercent()
    local r, g, b = 1, 1, 1
    if lowest < 0.25 then
        r, g, b = 1, 0.2, 0.2
    elseif lowest < 0.5 then
        r, g, b = 1, 0.8, 0.2
    end
    f.durabilityText:SetText(string_format("%.0f%% dur", pct))
    f.durabilityText:SetTextColor(r, g, b)
end

---------------------------------------------------------------------------
-- Hide Blizzard status tracking bars
---------------------------------------------------------------------------

local function hideBlizzardStatusBars()
    if MainStatusTrackingBarContainer then
        MainStatusTrackingBarContainer:Hide()
        MainStatusTrackingBarContainer:UnregisterAllEvents()
    end
    if SecondaryStatusTrackingBarContainer then
        SecondaryStatusTrackingBarContainer:Hide()
        SecondaryStatusTrackingBarContainer:UnregisterAllEvents()
    end
end

local function restoreBlizzardStatusBars()
    if MainStatusTrackingBarContainer then
        MainStatusTrackingBarContainer:Show()
        if MainStatusTrackingBarContainer.OnLoad then
            MainStatusTrackingBarContainer:OnLoad()
        end
    end
    if SecondaryStatusTrackingBarContainer then
        SecondaryStatusTrackingBarContainer:Show()
        if SecondaryStatusTrackingBarContainer.OnLoad then
            SecondaryStatusTrackingBarContainer:OnLoad()
        end
    end
end

---------------------------------------------------------------------------
-- Frame Creation
---------------------------------------------------------------------------

local function createFrame()
    local f = CreateFrame("Frame", "DessertUI_DataBar", UIParent)
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    f:SetHeight(ns.Constants.databar.height)
    f:SetFrameStrata("BACKGROUND")

    -- Class-colored background — same atlas the ObjectiveTracker header uses,
    -- desaturated and vertex-tinted with the class color (matches FrameColor).
    local _, class = UnitClass("player")
    local class_color = class and RAID_CLASS_COLORS[class]
    local cr, cg, cb = 0.28, 0.28, 0.28
    if class_color then
        cr, cg, cb = class_color.r, class_color.g, class_color.b
    end

    local BG_TINT = 0.3
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(cr * BG_TINT, cg * BG_TINT, cb * BG_TINT, ns.Constants.databar.opacity)
    f.bg = bg

    -- 1px class-colored top border (full saturation for contrast)
    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(cr, cg, cb, 1)
    f.border = border

    -- FPS text (left side)
    local fps_text = f:CreateFontString(nil, "OVERLAY")
    fps_text:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 10, "OUTLINE")
    fps_text:SetPoint("LEFT", f, "LEFT", 10, ns.Constants.databar.verticalOffset)
    f.fpsText = fps_text

    -- Coordinates text (centered)
    local coords_text = f:CreateFontString(nil, "OVERLAY")
    coords_text:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 10, "OUTLINE")
    coords_text:SetPoint("CENTER", f, "CENTER", 0, ns.Constants.databar.verticalOffset)
    f.coordsText = coords_text

    -- Anchor for right-side datatexts (XP and rep chain rightward from here)
    local right_anchor = { frame = f, point = "RIGHT", x = -10 }

    -- Durability datatext (rightmost)
    do
        local dur_frame = CreateFrame("Frame", nil, f)
        dur_frame:SetSize(70, ns.Constants.databar.height)
        dur_frame:SetPoint("RIGHT", right_anchor.frame, right_anchor.point, right_anchor.x, 0)
        right_anchor = { frame = dur_frame, point = "LEFT", x = -20 }

        local dur_text = dur_frame:CreateFontString(nil, "OVERLAY")
        dur_text:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 10, "OUTLINE")
        dur_text:SetPoint("CENTER", dur_frame, "CENTER", 0, ns.Constants.databar.verticalOffset)
        f.durabilityText = dur_text

        dur_frame:EnableMouse(true)
        dur_frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Durability", 1, 1, 1)

            local pct = getDurabilityPercent()
            GameTooltip:AddDoubleLine("Total", string_format("%.1f%%", pct), 1, 1, 1, 1, 1, 1)

            local any_damaged = false
            for _, slot in ipairs(DURABILITY_SLOTS) do
                local current, max = GetInventoryItemDurability(slot)
                if current and max and max > 0 and current < max then
                    if not any_damaged then
                        GameTooltip:AddLine(" ")
                        any_damaged = true
                    end
                    local slot_pct = current / max * 100
                    local link = GetInventoryItemLink("player", slot)
                    local label = link or SLOT_NAMES[slot] or ("Slot " .. slot)
                    local r, g, b = 1, 1, 1
                    if slot_pct < 25 then
                        r, g, b = 1, 0.2, 0.2
                    elseif slot_pct < 50 then
                        r, g, b = 1, 0.8, 0.2
                    end
                    GameTooltip:AddDoubleLine(label, string_format("%.0f%%", slot_pct), 1, 1, 1, r, g, b)
                end
            end

            if not any_damaged then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("All items at full durability.", 0.5, 1, 0.5)
            end

            GameTooltip:Show()
        end)
        dur_frame:SetScript("OnLeave", GameTooltip_Hide)
        f.durabilityFrame = dur_frame

        f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
        f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    end

    -- XP datatext (right side, only if not max level)
    local is_max_level = UnitLevel("player") >= GetMaxLevelForPlayerExpansion()
    if not is_max_level then
        local xp_frame = CreateFrame("Frame", nil, f)
        xp_frame:SetSize(100, ns.Constants.databar.height)
        xp_frame:SetPoint("RIGHT", right_anchor.frame, right_anchor.point, right_anchor.x, 0)
        right_anchor = { frame = xp_frame, point = "LEFT", x = -20 }

        local xp_text = xp_frame:CreateFontString(nil, "OVERLAY")
        xp_text:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 10, "OUTLINE")
        xp_text:SetPoint("CENTER", xp_frame, "CENTER", 0, ns.Constants.databar.verticalOffset)
        f.xpText = xp_text

        xp_frame:EnableMouse(true)
        xp_frame:SetScript("OnEnter", function(self)
            local current_xp = UnitXP("player")
            local max_xp = UnitXPMax("player")
            local rested_xp = GetXPExhaustion() or 0
            local remaining = max_xp - current_xp
            local xp_per_bubble = max_xp / NUM_BUBBLES
            local bubbles_remaining = math_ceil(remaining / xp_per_bubble)

            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Experience", 1, 1, 1)
            GameTooltip:AddDoubleLine("Progress", string_format("%s / %s", BreakUpLargeNumbers(current_xp), BreakUpLargeNumbers(max_xp)), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Remaining", BreakUpLargeNumbers(remaining), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Rested XP", BreakUpLargeNumbers(rested_xp), 1, 1, 1, 0.25, 0.50, 1.0)
            GameTooltip:AddDoubleLine("Bubbles to level", string_format("%d / %d", NUM_BUBBLES - bubbles_remaining, NUM_BUBBLES), 1, 1, 1, 1, 1, 1)
            GameTooltip:Show()
        end)
        xp_frame:SetScript("OnLeave", GameTooltip_Hide)
        f.xpFrame = xp_frame

        -- Event-driven XP updates
        f:RegisterEvent("PLAYER_XP_UPDATE")
        f:RegisterEvent("PLAYER_LEVEL_UP")
        f:RegisterEvent("UPDATE_EXHAUSTION")
    end

    -- Reputation datatext (right side, hidden if nothing tracked)
    do
        local rep_frame = CreateFrame("Frame", nil, f)
        rep_frame:SetSize(200, ns.Constants.databar.height)
        rep_frame:SetPoint("RIGHT", right_anchor.frame, right_anchor.point, right_anchor.x, 0)

        local rep_text = rep_frame:CreateFontString(nil, "OVERLAY")
        rep_text:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 10, "OUTLINE")
        rep_text:SetPoint("CENTER", rep_frame, "CENTER", 0, ns.Constants.databar.verticalOffset)
        f.repText = rep_text

        rep_frame:EnableMouse(true)
        rep_frame:SetScript("OnEnter", function(self)
            local data = C_Reputation.GetWatchedFactionData()
            if not data then return end

            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(data.name or "Unknown", 1, 1, 1)

            local major_info = C_MajorFactions.GetMajorFactionData(data.factionID)
            local is_paragon = C_Reputation.IsFactionParagon(data.factionID)

            if major_info and major_info.renownLevel then
                GameTooltip:AddDoubleLine("Renown Level", major_info.renownLevel, 1, 1, 1, 1, 1, 1)

                local current = major_info.renownReputationEarned or 0
                local max = major_info.renownLevelThreshold or 1
                GameTooltip:AddDoubleLine("Progress", string_format("%s / %s", BreakUpLargeNumbers(current), BreakUpLargeNumbers(max)), 1, 1, 1, 1, 1, 1)
                GameTooltip:AddDoubleLine("Remaining", BreakUpLargeNumbers(max - current), 1, 1, 1, 1, 1, 1)

                if is_paragon then
                    local paragon_current, paragon_threshold = C_Reputation.GetFactionParagonInfo(data.factionID)
                    local paragon_value = paragon_current % paragon_threshold
                    GameTooltip:AddDoubleLine("Paragon", string_format("%s / %s", BreakUpLargeNumbers(paragon_value), BreakUpLargeNumbers(paragon_threshold)), 1, 1, 1, 0.0, 0.8, 1.0)
                end
            else
                local standing = _G["FACTION_STANDING_LABEL" .. (data.reaction or 0)] or "Unknown"
                local current = data.currentStanding - data.currentReactionThreshold
                local max = data.nextReactionThreshold - data.currentReactionThreshold
                GameTooltip:AddDoubleLine("Standing", standing, 1, 1, 1, 1, 1, 1)
                GameTooltip:AddDoubleLine("Progress", string_format("%s / %s", BreakUpLargeNumbers(current), BreakUpLargeNumbers(max)), 1, 1, 1, 1, 1, 1)
                GameTooltip:AddDoubleLine("Remaining", BreakUpLargeNumbers(max - current), 1, 1, 1, 1, 1, 1)
            end

            GameTooltip:Show()
        end)
        rep_frame:SetScript("OnLeave", GameTooltip_Hide)
        f.repFrame = rep_frame

        -- Event-driven reputation updates
        f:RegisterEvent("UPDATE_FACTION")
        f:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
    end

    -- OnUpdate for FPS and coordinates
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed < UPDATE_INTERVAL then return end
        self.elapsed = 0
        self.fpsText:SetText(string_format("%d fps", math_floor(GetFramerate())))

        local map = C_Map.GetBestMapForUnit("player")
        if map then
            local pos = C_Map.GetPlayerMapPosition(map, "player")
            if pos then
                local x, y = pos:GetXY()
                self.coordsText:SetText(string_format("%.1f, %.1f", x * 100, y * 100))
                return
            end
        end
        self.coordsText:SetText("")
    end)

    -- Event handler for XP and reputation updates
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LEVEL_UP" then
            local is_max = UnitLevel("player") >= GetMaxLevelForPlayerExpansion()
            if is_max and self.xpFrame then
                self.xpFrame:Hide()
                self.xpText = nil
                self:UnregisterEvent("PLAYER_XP_UPDATE")
                self:UnregisterEvent("PLAYER_LEVEL_UP")
                self:UnregisterEvent("UPDATE_EXHAUSTION")
                return
            end
        end

        if event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" or event == "UPDATE_EXHAUSTION" then
            updateXPText(self)
        end

        if event == "UPDATE_FACTION" or event == "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" then
            updateRepText(self)
        end

        if event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_EQUIPMENT_CHANGED" then
            updateDurabilityText(self)
        end
    end)

    -- Initial text
    updateXPText(f)
    updateRepText(f)
    updateDurabilityText(f)

    return f
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function DataBar.Initialize()
    if frame then return end

    local show = ns.Settings.GetOption("showDataBar")
    if show == false then return end

    hideBlizzardStatusBars()
    frame = createFrame()

    -- Apply combat fader (same config as action bars: fade out in combat)
    ns.Fader.Create(frame, ns.Constants.faders.actionBars)
end

function DataBar.Toggle(value)
    if value then
        hideBlizzardStatusBars()
        if frame then
            frame:Show()
            ns.Fader.Enable(frame)
        else
            DataBar.Initialize()
        end
    else
        if frame then
            ns.Fader.Disable(frame)
            frame:Hide()
        end
        restoreBlizzardStatusBars()
    end
end

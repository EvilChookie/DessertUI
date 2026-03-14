local addon, ns = ...
local UnitFrames = ns.UnitFrames or {}

-- Initialize oUF
local oUF = ns.oUF or oUF
assert(oUF, "oUF not found!")

-- Cache frequently used functions for performance
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local string_format = string.format

-- Unit frame styles
local UnitStyles = {}

-- Helper function to apply position constants to a frame
local function ApplyPosition(frame, positionKey)
    local positions = ns.Constants and ns.Constants.frames and ns.Constants.frames.positions
    if not positions or not positions[positionKey] then
        ns.Utils.PrintMessage(string_format("Position constant '%s' not found", tostring(positionKey)))
        return
    end

    local pos = positions[positionKey]
    frame:SetPoint(pos.point, UIParent, pos.relative, pos.x, pos.y)

    if ns.PixelPerfect then
        ns.PixelPerfect.Snap(frame)
    end
end

-- Base style function for generic units
local function CreateStyle(self, unit)
    -- Apply unit defaults (click handling, tooltips, etc.)
    ns.Utils.SetUnitDefaults(self)
    
    -- Use player-specific style for player unit
    if unit == "player" and UnitFrames.PlayerStyle then
        return UnitFrames.PlayerStyle(self, unit)
    end
    
    -- Use target-specific style for target unit
    if unit == "target" and UnitFrames.TargetStyle then
        return UnitFrames.TargetStyle(self, unit)
    end
    
    -- Use pet-specific style for pet unit
    if unit == "pet" and UnitFrames.PetStyle then
        return UnitFrames.PetStyle(self, unit)
    end
    
    -- Use target of target-specific style for targettarget unit
    if unit == "targettarget" and UnitFrames.TargetOfTargetStyle then
        return UnitFrames.TargetOfTargetStyle(self, unit)
    end

    -- Use focus-specific style for focus unit
    if unit == "focus" and UnitFrames.FocusStyle then
        return UnitFrames.FocusStyle(self, unit)
    end

    -- Use boss-specific style for boss units (boss1, boss2, boss3, boss4)
    if unit and unit:match("^boss%d") and UnitFrames.BossStyle then
        return UnitFrames.BossStyle(self, unit)
    end
end

-- Register the base style
UnitStyles.Base = CreateStyle
UnitFrames.BaseStyle = CreateStyle

-- Helper function to create ElvUI-style shadow glow
function UnitFrames:CreateShadowGlow(parent, offset)
    local shadow = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    shadow:SetFrameLevel(parent:GetFrameLevel() - 1)
    shadow:SetFrameStrata("BACKGROUND")
    shadow:SetPoint("TOPLEFT", parent, "TOPLEFT", -offset, offset)
    shadow:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", offset, -offset) -- Standard offset on all sides
    shadow:SetBackdrop({
        edgeFile = "Interface\\AddOns\\DessertUI\\Media\\Textures\\Glow", 
        edgeSize = offset,
    })
    shadow:SetBackdropBorderColor(0, 0, 0, 0) -- Start transparent
    shadow:Hide()
    return shadow
end

-- External library dependency
local LibDispel = LibStub and LibStub("LibDispel")

-- Helper function to check if we can cure a specific debuff
local function CanCureDebuff(unit, auraData)
    if not (LibDispel and auraData and auraData.isHarmful) then return false end
    local dispelType = LibDispel:GetDispelType(auraData.spellId, auraData.dispelName)
    if not dispelType then return false end
    return LibDispel:IsDispelable(unit, auraData.spellId, dispelType, true)
end

-- Helper function to get dispellable debuff type for unified glow system
function UnitFrames:GetDispellableDebuffType(unit)
    if not unit or not UnitDebuff or not LibDispel then return nil end
    
    -- Safely check if unit exists before checking debuffs
    if not UnitExists(unit) then return nil end
    
    -- Check all debuffs on the unit using C_UnitAuras for better data
    local useNewAPI = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    local auraData
    for i = 1, 40 do
        if useNewAPI then
            auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        else
            local name, _, _, debuffType, _, _, _, _, _, spellId = UnitDebuff(unit, i)
            if not name then break end
            auraData = {
                name = name,
                spellId = spellId,
                dispelName = debuffType,
                isHarmful = true
            }
        end

        if not auraData then break end

        if CanCureDebuff(unit, auraData) then
            return auraData.dispelName
        end
    end
    
    return nil
end

-- Helper function to determine the correct glow state for a frame
function UnitFrames:GetFrameGlowState(frame, isHovered, isTargeted)
    if not frame or not frame.unit or not frame.glowStates then 
        return {0, 0, 0, 0.4} -- Default shadow color
    end
    
    -- Check for dispellable debuffs first (highest priority)
    local dispelType = self:GetDispellableDebuffType(frame.unit)
    if dispelType then
        local dispelKey = "dispel_" .. dispelType
        if frame.glowStates[dispelKey] then
            return frame.glowStates[dispelKey]
        end
    end
    
    -- Priority: Target > Hover > Shadow
    if isTargeted then
        return frame.glowStates.target
    elseif isHovered then
        return frame.glowStates.hover
    else
        return frame.glowStates.shadow
    end
end



-- Track if initialization has already been done
local isInitialized = false

-- Initialize unit frames
function UnitFrames:Initialize()
    if isInitialized then
        return
    end

    -- Register styles with oUF (oUF allows re-registration)
    oUF:RegisterStyle("DessertUI", CreateStyle)

    -- Store style for external access
    UnitStyles.Base = CreateStyle
    UnitFrames.BaseStyle = CreateStyle
    oUF:SetActiveStyle("DessertUI")

    -- Create unit frames in proper order
    self:CreatePlayer()
    self:CreateTarget()
    self:CreatePet()
    self:CreateTargetOfTarget()
    self:CreateFocus()
    self:CreateBoss()

    isInitialized = true
end

-- Helper function to apply fader to unit frame
local function ApplyFaderToUnitFrame(frame, frameName)
    if not frame then return end
    
    -- Check if unit fader is enabled
    if ns.Settings and ns.Settings.GetOption("unitFader") then
        if ns.Fader and ns.Fader.Create then
            ns.Fader.Create(frame, ns.Constants.faders.combined)
        else
            ns.Utils.PrintMessage(string_format("Fader module not available for %s", frameName))
        end
    end
end

-- Unit frame creation functions
function UnitFrames:CreatePlayer()
    local player = oUF:Spawn("player", "DessertUI_Player")
    ApplyPosition(player, "player")
    ApplyFaderToUnitFrame(player, "Player")
end

function UnitFrames:CreateTarget()
    local target = oUF:Spawn("target", "DessertUI_Target")
    ApplyPosition(target, "target")
    ApplyFaderToUnitFrame(target, "Target")
end

function UnitFrames:CreateTargetOfTarget()
    local tot = oUF:Spawn("targettarget", "DessertUI_ToT")
    ApplyPosition(tot, "tot")
    ApplyFaderToUnitFrame(tot, "Target of Target")
end

function UnitFrames:CreateFocus()
    local focus = oUF:Spawn("focus", "DessertUI_Focus")
    ApplyPosition(focus, "focus")
    ApplyFaderToUnitFrame(focus, "Focus")
end

function UnitFrames:CreatePet()
    local pet = oUF:Spawn("pet", "DessertUI_Pet")
    ApplyPosition(pet, "pet")
    ApplyFaderToUnitFrame(pet, "Pet")
end


function UnitFrames:CreateBoss()
    -- Note: Boss frames do not use faders. They only exist during boss encounters
    -- (created on combat start, destroyed on combat end) so out-of-combat fading
    -- is not applicable. See CLAUDE.md for more context.
    -- Create individual boss frames using the boss position constants
    for i = 1, 4 do
        local boss = oUF:Spawn("boss" .. i, "DessertUI_Boss" .. i)
        ApplyPosition(boss, "boss" .. i)
    end
end


ns.UnitFrames = UnitFrames

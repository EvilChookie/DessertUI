local addon, ns = ...

--[[
    Masque Support Module

    Provides Masque skinning support for Blizzard UI elements:
    - Action Bars
    - Buffs and Debuffs

    If Masque is not installed, this module silently does nothing.

    ============================================================================
    ATTRIBUTION
    ============================================================================

    This module draws inspiration from:

    Masque Skinner: Blizz Buffs by Cybeloras of Aerie Peak
    https://github.com/ascott18/Masque-Skinner-Blizz-Buffs
    - Aura wrapper frame technique for skinning modern WoW's rectangular
      buff/debuff frames with Masque

    MasqueBlizzBars by SimGuy (MIT License, 2022-2024)
    https://github.com/SimGuy2014/MasqueBlizzBars
    - Action bar region mapping patterns

    ============================================================================
]]

local hooksecurefunc = hooksecurefunc

local Masque = LibStub and LibStub("Masque", true)
if not Masque then return end

-- Group references
local groups = {}

-- Track skinned frames to avoid duplicates
local skinned = {}

-- Action bar configurations
local ACTION_BARS = {
    { prefix = "ActionButton", count = NUM_ACTIONBAR_BUTTONS or 12 },
    { prefix = "MultiBarBottomLeftButton", count = NUM_MULTIBAR_BUTTONS or 12 },
    { prefix = "MultiBarBottomRightButton", count = NUM_MULTIBAR_BUTTONS or 12 },
    { prefix = "MultiBarRightButton", count = NUM_MULTIBAR_BUTTONS or 12 },
    { prefix = "MultiBarLeftButton", count = NUM_MULTIBAR_BUTTONS or 12 },
    { prefix = "MultiBar5Button", count = NUM_MULTIBAR_BUTTONS or 12 },
    { prefix = "MultiBar6Button", count = NUM_MULTIBAR_BUTTONS or 12 },
    { prefix = "MultiBar7Button", count = NUM_MULTIBAR_BUTTONS or 12 },
    { prefix = "StanceButton", count = 10, group = "stanceBar" },
    { prefix = "PetActionButton", count = NUM_PET_ACTION_SLOTS or 10, group = "petBar" },
    { prefix = "PossessButton", count = NUM_POSSESS_SLOTS or 2 },
    { prefix = "OverrideActionBarButton", count = 6 },
}

local function createGroups()
    groups.actionBars = Masque:Group(addon, "Action Bars")
    groups.stanceBar = Masque:Group(addon, "Stance Bar")
    groups.petBar = Masque:Group(addon, "Pet Action Bar")
    groups.buffs = Masque:Group(addon, "Buffs")
    groups.debuffs = Masque:Group(addon, "Debuffs")
end

--[[
    Action Bar Skinning
]]

local function addActionButton(group, button)
    if skinned[button] then return end

    group:AddButton(button, {
        Icon = button.icon or button.Icon,
        Cooldown = button.cooldown or button.Cooldown,
        Count = button.Count,
        Border = button.Border,
        Normal = button.NormalTexture or (button.GetNormalTexture and button:GetNormalTexture()),
        Pushed = button.PushedTexture or (button.GetPushedTexture and button:GetPushedTexture()),
        Highlight = button.HighlightTexture or (button.GetHighlightTexture and button:GetHighlightTexture()),
        Checked = button.CheckedTexture or (button.GetCheckedTexture and button:GetCheckedTexture()),
        Flash = button.Flash,
        HotKey = button.HotKey,
        Name = button.Name,
        AutoCastable = button.AutoCastable,
        AutoCastShine = button.AutoCastShine,
    }, "Action")

    skinned[button] = true
end

local function registerActionBars()
    for _, config in ipairs(ACTION_BARS) do
        local group = groups[config.group] or groups.actionBars
        for i = 1, config.count do
            local button = _G[config.prefix .. i]
            if button then
                addActionButton(group, button)
            end
        end
    end

    -- Extra action buttons
    if ExtraActionButton1 then
        addActionButton(groups.actionBars, ExtraActionButton1)
    end
    if ZoneAbilityFrame and ZoneAbilityFrame.SpellButton then
        addActionButton(groups.actionBars, ZoneAbilityFrame.SpellButton)
    end
end

--[[
    Aura Skinning

    Modern WoW aura frames are rectangular, not square. We create a square
    wrapper frame and register that with Masque instead.
]]

local function skinAuraFrame(frame, group)
    if skinned[frame] then return end
    if not frame.Icon or not frame.Icon.GetTexture then return end

    skinned[frame] = true

    -- Create a square wrapper frame
    local wrapper = CreateFrame("Frame", nil, frame)
    wrapper:SetSize(30, 30)
    wrapper:SetPoint("TOP")

    -- Hide original icon and create our own square one
    frame.Icon:Hide()
    frame.SkinnedIcon = wrapper:CreateTexture(nil, "BACKGROUND")
    frame.SkinnedIcon:SetSize(30, 30)
    frame.SkinnedIcon:SetPoint("CENTER")
    frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())

    hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
        frame.SkinnedIcon:SetTexture(tex)
    end)

    -- Reparent related elements to the wrapper
    if frame.Count then
        frame.Count:SetParent(wrapper)
    end
    if frame.DebuffBorder then
        frame.DebuffBorder:SetParent(wrapper)
    end
    if frame.TempEnchantBorder then
        frame.TempEnchantBorder:SetParent(wrapper)
        frame.TempEnchantBorder:SetVertexColor(0.75, 0, 1)
    end
    if frame.Symbol then
        frame.Symbol:SetParent(wrapper)
    end

    local button_type = frame.auraType or "Aura"
    if button_type == "DeadlyDebuff" then
        button_type = "Debuff"
    end

    group:AddButton(wrapper, {
        Icon = frame.SkinnedIcon,
        DebuffBorder = frame.DebuffBorder,
        EnchantBorder = frame.TempEnchantBorder,
        Count = frame.Count,
        HotKey = frame.Symbol,
    }, button_type)
end

local function makeAuraHook(group)
    return function(self)
        if self.auraFrames then
            for _, frame in ipairs(self.auraFrames) do
                skinAuraFrame(frame, group)
            end
        end
        if self.exampleAuraFrames then
            for _, frame in ipairs(self.exampleAuraFrames) do
                skinAuraFrame(frame, group)
            end
        end
    end
end

local function setupAuraHooks()
    if not AuraButtonMixin then return end

    hooksecurefunc(BuffFrame, "UpdateAuraButtons", makeAuraHook(groups.buffs))
    hooksecurefunc(DebuffFrame, "UpdateAuraButtons", makeAuraHook(groups.debuffs))

    if BuffFrame.OnEditModeEnter then
        hooksecurefunc(BuffFrame, "OnEditModeEnter", makeAuraHook(groups.buffs))
    end
    if DebuffFrame.OnEditModeEnter then
        hooksecurefunc(DebuffFrame, "OnEditModeEnter", makeAuraHook(groups.debuffs))
    end
end

-- Initialize
local function initialize()
    createGroups()

    -- Bartender4 handles its own action bar Masque skinning
    if not ns.hasBartender4 then
        registerActionBars()
    end

    setupAuraHooks()
end

ns.Utils.RegisterCallback("PLAYER_LOGIN", initialize)

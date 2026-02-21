local addon, ns = ...

--[[
    Frame Fader System

    Based on rLib by zork (https://github.com/zorker/rothui)
    Extended with combat-aware fading and combined mouseover/combat modes.
]]

ns.Fader = ns.Fader or {}
local Fader = ns.Fader

-- Cached combat state (updated on PLAYER_REGEN_ENABLED/DISABLED only)
local inCombat = false

-- Frame registries for shared ticker and combat events
local mouseoverFrames = {} -- set of frames needing OnUpdate polling
local combatFrames = {}    -- set of frames needing combat state updates

local function FaderOnFinished(self)
    self.__owner:SetAlpha(self.finAlpha)
end

local function CreateFaderAnimation(frame)
    if frame.__fader then return end
    frame.__fader = frame:CreateAnimationGroup()
    frame.__fader.__owner = frame
    frame.__fader.direction = nil
    frame.__fader.setToFinalAlpha = false
    frame.__fader.anim = frame.__fader:CreateAnimation("Alpha")
    frame.__fader:HookScript("OnFinished", FaderOnFinished)
end

local function GetTargetAlpha(frame, fadeType)
    local config = frame.__faderConfig
    if not config then return 1 end

    if fadeType == "mouseover" then
        return config.fadeInAlpha or 1
    elseif fadeType == "mouseout" then
        return config.fadeOutAlpha or 0.2
    elseif fadeType == "combat" then
        return inCombat and (config.inCombatAlpha or 1) or (config.outCombatAlpha or 0.2)
    end

    return 1
end

local function StartFade(frame, fadeType)
    if not frame.__fader or not frame.__faderConfig then return end

    local targetAlpha = GetTargetAlpha(frame, fadeType)

    -- Early-out: skip if already at target alpha and not animating
    if frame:GetAlpha() == targetAlpha and not frame.__fader:IsPlaying() then
        return
    end

    local config = frame.__faderConfig

    -- Determine which configuration to use based on fade type
    local duration, smoothing, delay
    if fadeType == "mouseover" then
        duration = config.fadeInDuration or 0.15
        smoothing = config.fadeInSmooth or "OUT"
        delay = config.fadeInDelay or 0
    elseif fadeType == "mouseout" then
        duration = config.fadeOutDuration or 0.15
        smoothing = config.fadeOutSmooth or "OUT"
        delay = config.fadeOutDelay or 0
    elseif fadeType == "combat" then
        duration = inCombat and (config.inCombatDuration or 0.15) or (config.outCombatDuration or 0.15)
        smoothing = inCombat and (config.inCombatSmooth or "OUT") or (config.outCombatSmooth or "OUT")
        delay = inCombat and (config.inCombatDelay or 0) or (config.outCombatDelay or 0)
    end

    frame.__fader:Pause()
    frame.__fader.anim:SetFromAlpha(frame:GetAlpha())
    frame.__fader.anim:SetToAlpha(targetAlpha)
    frame.__fader.anim:SetDuration(duration)
    frame.__fader.anim:SetSmoothing(smoothing)
    frame.__fader.anim:SetStartDelay(delay)
    frame.__fader.finAlpha = targetAlpha
    frame.__fader.direction = fadeType
    frame.__fader:Play()
end

local function IsMouseOverFrame(frame)
    -- Direct check first
    if MouseIsOver(frame) then return true end

    -- Check current mouse focus ancestry to include children that extend beyond the frame bounds
    local focus = GetMouseFocus and GetMouseFocus()
    while focus do
        if focus == frame or (focus.__faderParent and focus.__faderParent == frame) then
            return true
        end
        if focus.GetParent then
            focus = focus:GetParent()
        else
            break
        end
    end

    -- Special cases: SpellFlyout with explicit fader parent
    if SpellFlyout and SpellFlyout:IsShown() and SpellFlyout.__faderParent == frame and MouseIsOver(SpellFlyout) then
        return true
    end

    return false
end

local function FrameHandler(frame)
    if not frame.__faderConfig or frame.__faderDisabled then return end

    local isMouseOver = IsMouseOverFrame(frame)

    -- Determine fade type based on current state
    local fadeType
    if frame.__faderConfig.enableCombat and frame.__faderConfig.enableMouseover then
        -- Combined fader: prioritize mouseover over combat
        if isMouseOver then
            fadeType = "mouseover"
        else
            fadeType = "combat"
        end
    elseif frame.__faderConfig.enableMouseover then
        fadeType = isMouseOver and "mouseover" or "mouseout"
    elseif frame.__faderConfig.enableCombat then
        fadeType = "combat"
    else
        return
    end

    StartFade(frame, fadeType)
end

-- Unified handler for child frames
local function ChildFrameHandler(frame)
    if frame.__faderParent then
        FrameHandler(frame.__faderParent)
    end
end

local function LABFlyoutHandlerFrameOnShow(frame)
    if not frame or not frame.buttons then return end

    for i = 1, #frame.buttons do
        local button = frame.buttons[i]
        if not button then break end
        button.__faderParent = frame
        if not button.__faderHook then
            button:HookScript("OnEnter", ChildFrameHandler)
            button:HookScript("OnLeave", ChildFrameHandler)
            button.__faderHook = true
        end
    end
end

-- Helper function to apply default fader values
local function ApplyFaderDefaults(faderConfig)
    -- Mouseover defaults
    faderConfig.fadeInAlpha = faderConfig.fadeInAlpha or 1
    faderConfig.fadeOutAlpha = faderConfig.fadeOutAlpha or 0.2
    faderConfig.fadeInDuration = faderConfig.fadeInDuration or 0.15
    faderConfig.fadeOutDuration = faderConfig.fadeOutDuration or 0.15
    faderConfig.fadeInSmooth = faderConfig.fadeInSmooth or "OUT"
    faderConfig.fadeOutSmooth = faderConfig.fadeOutSmooth or "OUT"
    faderConfig.fadeInDelay = faderConfig.fadeInDelay or 0
    faderConfig.fadeOutDelay = faderConfig.fadeOutDelay or 0

    -- Combat defaults (if combat fader is enabled)
    if faderConfig.enableCombat then
        faderConfig.inCombatAlpha = faderConfig.inCombatAlpha or 1
        faderConfig.outCombatAlpha = faderConfig.outCombatAlpha or 0.2
        faderConfig.inCombatDuration = faderConfig.inCombatDuration or 0.15
        faderConfig.outCombatDuration = faderConfig.outCombatDuration or 0.15
        faderConfig.inCombatSmooth = faderConfig.inCombatSmooth or "OUT"
        faderConfig.outCombatSmooth = faderConfig.outCombatSmooth or "OUT"
        faderConfig.inCombatDelay = faderConfig.inCombatDelay or 0
        faderConfig.outCombatDelay = faderConfig.outCombatDelay or 0
    end

    return faderConfig
end

-- Shared OnUpdate ticker for all mouseover-faded frames
local tickerFrame = CreateFrame("Frame")
tickerFrame.elapsed = 0
tickerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.12 then return end
    self.elapsed = 0

    for frame in next, mouseoverFrames do
        if frame:IsVisible() and not frame.__faderDisabled then
            FrameHandler(frame)
        end
    end
end)

-- Shared combat event frame for all combat-faded frames
local combatEventFrame = CreateFrame("Frame")
combatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatEventFrame:SetScript("OnEvent", function(self, event)
    inCombat = (event == "PLAYER_REGEN_DISABLED")

    for frame in next, combatFrames do
        if not frame.__faderDisabled then
            FrameHandler(frame)
        end
    end
end)

-- Helper function to setup mouseover fader functionality
local function SetupMouseoverFader(frame, faderConfig)
    -- Only enable mouse if not explicitly skipped (for frames where EnableMouse interferes with other systems)
    if not faderConfig.skipEnableMouse then
        frame:EnableMouse(true)
    end

    -- Only hook OnEnter/OnLeave if not explicitly skipped (for frames where these hooks interfere with edit mode)
    if not faderConfig.skipMouseoverHooks then
        frame:HookScript("OnEnter", FrameHandler)
        frame:HookScript("OnLeave", FrameHandler)
    end

    -- Register with shared ticker for edge-case polling
    mouseoverFrames[frame] = true

    FrameHandler(frame)
end

-- Helper function to setup combat fader functionality
local function SetupCombatFader(frame)
    -- Register with shared combat event handler
    combatFrames[frame] = true

    -- Set initial state (consider both combat and mouseover)
    FrameHandler(frame)
end

-- Unified fader creation function
Fader.Create = function(frame, faderConfig)
    if frame.__faderInitialized then return end

    -- Apply default values and store configuration
    faderConfig = ApplyFaderDefaults(faderConfig)
    frame.__faderConfig = faderConfig
    CreateFaderAnimation(frame)

    -- Setup mouseover fader if requested
    if faderConfig.enableMouseover then
        SetupMouseoverFader(frame, faderConfig)
    end

    -- Setup combat fader if requested
    if faderConfig.enableCombat then
        SetupCombatFader(frame)
    end

    frame.__faderInitialized = true
end

-- Function to disable fader on a frame and reset to full opacity
Fader.Disable = function(frame)
    if not frame or not frame.__faderInitialized then return end

    -- Stop any running animation
    if frame.__fader then
        frame.__fader:Stop()
    end

    -- Set disabled flag so fader handlers will ignore events
    frame.__faderDisabled = true

    -- Reset to full opacity
    frame:SetAlpha(1)
end

-- Function to re-enable a disabled fader
Fader.Enable = function(frame)
    if not frame or not frame.__faderInitialized then return end

    -- Clear disabled flag
    frame.__faderDisabled = nil

    -- Trigger initial state based on current conditions using FrameHandler
    if frame.__faderConfig then
        FrameHandler(frame)
    end
end

-- Export LAB flyout handler for external use
Fader.LABFlyoutHandlerFrameOnShow = LABFlyoutHandlerFrameOnShow

local addon, ns = ...

--[[
    Chat Module for DessertUI

    Provides layout adjustments to chat frames:
    - Hides unnecessary UI buttons
    - Removes backgrounds and borders from chat frames
]]

local Chat = {}
ns.Chat = Chat

-- Cache frequently used functions
local pairs = pairs
local ipairs = ipairs
local type = type
local string_match = string.match

-- Buttons to hide
local HIDDEN_BUTTONS = {
    "QuickJoinToastButton",
    "ChatFrameChannelButton",
    "ChatFrameMenuButton",
}

-- Hide unnecessary chat buttons
local function hideButtons()
    for _, buttonName in ipairs(HIDDEN_BUTTONS) do
        local button = _G[buttonName]
        if button then
            button:Hide()
            button:SetAlpha(0)
            -- Prevent the button from showing again
            if button.SetParent then
                button:SetParent(UIParent)
            end
            hooksecurefunc(button, "Show", function(self)
                self:Hide()
            end)
        end
    end
end

-- Remove background and border from a single chat frame
local function cleanupChatFrame(chatFrame, index)
    if not chatFrame then return end

    local frameName = chatFrame:GetName()

    -- Hide the background texture
    local bg = _G[frameName .. "Background"]
    if bg then
        bg:Hide()
        bg:SetAlpha(0)
        bg:SetTexture(nil)
    end

    -- Hide border textures
    local borderTextures = {
        "TopLeftTexture", "TopRightTexture",
        "BottomLeftTexture", "BottomRightTexture",
        "LeftTexture", "RightTexture",
        "TopTexture", "BottomTexture",
    }
    for _, textureName in ipairs(borderTextures) do
        local texture = _G[frameName .. textureName]
        if texture then
            texture:SetAlpha(0)
            texture:SetTexture(nil)
        end
    end

    -- Remove tab textures and backgrounds
    local tab = _G[frameName .. "Tab"]
    if tab then
        if tab.Left then tab.Left:SetAlpha(0) end
        if tab.Middle then tab.Middle:SetAlpha(0) end
        if tab.Right then tab.Right:SetAlpha(0) end
        if tab.ActiveLeft then tab.ActiveLeft:SetAlpha(0) end
        if tab.ActiveMiddle then tab.ActiveMiddle:SetAlpha(0) end
        if tab.ActiveRight then tab.ActiveRight:SetAlpha(0) end
        if tab.HighlightLeft then tab.HighlightLeft:SetAlpha(0) end
        if tab.HighlightMiddle then tab.HighlightMiddle:SetAlpha(0) end
        if tab.HighlightRight then tab.HighlightRight:SetAlpha(0) end
    end

    -- Set chat frame to have no background
    chatFrame:SetClampRectInsets(0, 0, 0, 0)

    -- Hide the button frame (resize grip area)
    local buttonFrame = _G[frameName .. "ButtonFrame"]
    if buttonFrame then
        buttonFrame:Hide()
        buttonFrame:SetAlpha(0)
    end

    -- Hide edit box backgrounds
    local editBox = _G[frameName .. "EditBox"]
    if editBox then
        if editBox.Left then editBox.Left:SetAlpha(0) end
        if editBox.Mid then editBox.Mid:SetAlpha(0) end
        if editBox.Right then editBox.Right:SetAlpha(0) end
        if editBox.FocusLeft then editBox.FocusLeft:SetAlpha(0) end
        if editBox.FocusMid then editBox.FocusMid:SetAlpha(0) end
        if editBox.FocusRight then editBox.FocusRight:SetAlpha(0) end
    end

    -- Kill all regions on the chat frame that might be borders/backgrounds
    local regions = {chatFrame:GetRegions()}
    for _, region in pairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local name = region:GetDebugName() or ""
            if string_match(name, "Background") or string_match(name, "Border") or string_match(name, "Texture") then
                region:SetAlpha(0)
                region:SetTexture(nil)
            end
        end
    end

    -- Also check the scroll frame if it exists
    local scrollFrame = chatFrame.ScrollBar or _G[frameName .. "ScrollBar"]
    if scrollFrame then
        scrollFrame:SetAlpha(0)
    end

    -- Remove backdrop if the frame has one
    if chatFrame.SetBackdrop then
        chatFrame:SetBackdrop(nil)
    end

    -- Check for Background child frame
    if chatFrame.Background then
        chatFrame.Background:Hide()
        chatFrame.Background:SetAlpha(0)
    end

    -- Check for border frames that might be children
    for _, child in pairs({chatFrame:GetChildren()}) do
        local childName = child:GetName() or ""
        if childName:match("Background") or childName:match("Border") or childName:match("Frame") then
            child:SetAlpha(0)
            if child.SetBackdrop then
                child:SetBackdrop(nil)
            end
        end
    end
end

-- Remove chat frame backgrounds and borders for all chat frames
local function removeChatBackgrounds()
    -- Process all chat frames (NUM_CHAT_WINDOWS is typically 10)
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        cleanupChatFrame(chatFrame, i)
    end

    -- Also handle any temporary chat frames that might be created later
    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        for i = 1, NUM_CHAT_WINDOWS do
            local chatFrame = _G["ChatFrame" .. i]
            cleanupChatFrame(chatFrame, i)
        end
    end)

    -- Hook functions that show borders/backgrounds on interaction
    hooksecurefunc("FCF_FadeInChatFrame", function(chatFrame)
        cleanupChatFrame(chatFrame)
    end)

    hooksecurefunc("FCF_FadeOutChatFrame", function(chatFrame)
        cleanupChatFrame(chatFrame)
    end)

    -- Hook the tab click to re-hide backgrounds
    hooksecurefunc("FCF_Tab_OnClick", function(self)
        local chatFrame = _G["ChatFrame" .. self:GetID()]
        cleanupChatFrame(chatFrame)
    end)

    -- Hook SetWindowAlpha which is called during interactions
    if FCF_SetWindowAlpha then
        hooksecurefunc("FCF_SetWindowAlpha", function(chatFrame)
            cleanupChatFrame(chatFrame)
        end)
    end

    -- Hook the scroll function
    if FloatingChatFrame_OnMouseScroll then
        hooksecurefunc("FloatingChatFrame_OnMouseScroll", function(chatFrame)
            cleanupChatFrame(chatFrame)
        end)
    end

    -- Hook background color functions
    if FCF_SetWindowColor then
        hooksecurefunc("FCF_SetWindowColor", function(chatFrame)
            cleanupChatFrame(chatFrame)
        end)
    end

    if FCF_SetWindowBackgroundColor then
        hooksecurefunc("FCF_SetWindowBackgroundColor", function(chatFrame)
            cleanupChatFrame(chatFrame)
        end)
    end
end

-- Initialize chat layout modifications
local function initialize()
    hideButtons()
    removeChatBackgrounds()
end

-- Register for player login
ns.Utils.RegisterCallback("PLAYER_LOGIN", initialize)

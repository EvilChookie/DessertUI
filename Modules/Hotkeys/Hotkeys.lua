local addon, ns = ...

-- Bartender4 handles its own hotkey text formatting
if ns.hasBartender4 then return end

-- Props to: https://eu.forums.blizzard.com/en/wow/t/action-bar-hotkey-text/180719
local ACTION_BAR_NAMES = { 'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft' }

local HOTKEY_REPLACEMENTS = {
    -- Modifiers
    { '(s%-)', 'S' },
    { '(a%-)', 'A' },
    { '(c%-)', 'C' },
    -- Mouse buttons
    { KEY_BUTTON1, 'LM' },
    { KEY_BUTTON2, 'RM' },
    { KEY_BUTTON3, 'MM' },
    { KEY_BUTTON4, 'M4' },
    { KEY_BUTTON5, 'M5' },
    { KEY_MOUSEWHEELDOWN, 'MWD' },
    { KEY_MOUSEWHEELUP, 'MWU' },
    -- Special keys
    { KEY_PAGEUP, 'PU' },
    { KEY_PAGEDOWN, 'PD' },
    { KEY_SPACE, 'SpB' },
    { KEY_INSERT, 'Ins' },
    { KEY_HOME, 'Hm' },
    { KEY_DELETE, 'Del' },
    -- Numpad
    { 'Num Pad %.', 'N.' },
    { 'Num Pad %/', 'N/' },
    { 'Num Pad %-', 'N-' },
    { 'Num Pad %*', 'N*' },
    { 'Num Pad %+', 'N+' },
    { KEY_NUMLOCK, 'NL' },
    { KEY_NUMPAD0, 'N0' },
    { KEY_NUMPAD1, 'N1' },
    { KEY_NUMPAD2, 'N2' },
    { KEY_NUMPAD3, 'N3' },
    { KEY_NUMPAD4, 'N4' },
    { KEY_NUMPAD5, 'N5' },
    { KEY_NUMPAD6, 'N6' },
    { KEY_NUMPAD7, 'N7' },
    { KEY_NUMPAD8, 'N8' },
    { KEY_NUMPAD9, 'N9' },
}

local ipairs = ipairs

local function applyHotkeyReplacements(originalText)
    local transformedText = originalText
    for _, mapping in ipairs(HOTKEY_REPLACEMENTS) do
        transformedText = transformedText:gsub(mapping[1], mapping[2])
    end
    return transformedText
end

-- Process a single button: shorten hotkey text and hide macro name
local function processButton(button)
    if not button then return end

    local hotkeyRegion = button.HotKey
    local text = hotkeyRegion and hotkeyRegion:GetText()
    if text and text ~= '' then
        local newText = applyHotkeyReplacements(text)
        hotkeyRegion:SetText(newText == RANGE_INDICATOR and '' or newText)
    end

    local nameRegion = button.Name
    if nameRegion then
        nameRegion:SetText('')
        nameRegion:SetAlpha(0)
    end
end

-- Full update: process all action bar buttons (hotkey text + macro names)
local function updateAllButtons()
    for _, actionBarName in ipairs(ACTION_BAR_NAMES) do
        for buttonIndex = 1, 12 do
            processButton(_G[actionBarName .. 'Button' .. buttonIndex])
        end
    end
end

-- Light update: only hide macro names on all buttons (slot content changed, not bindings)
local function hideMacroNames()
    for _, actionBarName in ipairs(ACTION_BAR_NAMES) do
        for buttonIndex = 1, 12 do
            local button = _G[actionBarName .. 'Button' .. buttonIndex]
            if button and button.Name then
                button.Name:SetText('')
                button.Name:SetAlpha(0)
            end
        end
    end
end

ns.Utils.RegisterCallback("PLAYER_LOGIN", updateAllButtons)
ns.Utils.RegisterCallback("UPDATE_BINDINGS", updateAllButtons)
ns.Utils.RegisterCallback("UPDATE_MACROS", hideMacroNames)
ns.Utils.RegisterCallback("ACTIONBAR_SLOT_CHANGED", hideMacroNames)

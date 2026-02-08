local addon, ns = ...

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

local function applyHotkeyReplacements(originalText)
    local transformedText = originalText
    for _, mapping in ipairs(HOTKEY_REPLACEMENTS) do
        transformedText = transformedText:gsub(mapping[1], mapping[2])
    end
    return transformedText
end

function dUI_Fixes_HotkeyTextFix()
    for _, actionBarName in ipairs(ACTION_BAR_NAMES) do
        for buttonIndex = 1, 12 do
            local button = _G[actionBarName .. 'Button' .. buttonIndex]
            local hotkeyRegion = button and button.HotKey
            local text = hotkeyRegion and hotkeyRegion:GetText()
            if text and text ~= '' then
                local newText = applyHotkeyReplacements(text)
                hotkeyRegion:SetText(newText == RANGE_INDICATOR and '' or newText)
            end

            -- Hide macro name
            local nameRegion = button and button.Name
            if nameRegion then
                nameRegion:SetText('')
                nameRegion:SetAlpha(0)
            end
        end
    end
end

ns.Utils.RegisterCallback("PLAYER_LOGIN", dUI_Fixes_HotkeyTextFix)
ns.Utils.RegisterCallback("UPDATE_BINDINGS", dUI_Fixes_HotkeyTextFix)
ns.Utils.RegisterCallback("UPDATE_MACROS", dUI_Fixes_HotkeyTextFix)
ns.Utils.RegisterCallback("ACTIONBAR_SLOT_CHANGED", dUI_Fixes_HotkeyTextFix)
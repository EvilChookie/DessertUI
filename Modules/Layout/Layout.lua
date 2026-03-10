local addon, ns = ...

--[[
    Layout Module for DessertUI

    Manages Edit Mode layouts using LibEditModeOverride.
    Parses an import string and applies frame positions/settings
    through the library to avoid taint issues.
]]

local Layout = {}
ns.Layout = Layout

-- Cache frequently used functions
local string_format = string.format
local ipairs = ipairs
local pcall = pcall

local LibEditMode = LibStub("LibEditModeOverride-1.0")

-- The Edit Mode import string for the DessertUI layout
local LAYOUT_IMPORT_STRING = "2 50 0 0 0 4 4 UIParent 0.0 -480.0 -1 ##$$%/&&'%)$+#,$ 0 1 0 0 0 UIParent 825.5 -1092.8 -1 ##$$%/&&'%(#,$ 0 2 0 0 0 UIParent 825.5 -1132.8 -1 ##$$%/&&'%(#,$ 0 3 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(#,$ 0 4 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(#,$ 0 5 1 1 4 UIParent 0.0 0.0 -1 ##$$%/&('%(#,$ 0 6 1 1 4 UIParent 0.0 -50.0 -1 ##$$%/&('%(#,$ 0 7 1 1 4 UIParent 0.0 -100.0 -1 ##$$%/&('%(#,$ 0 10 0 0 0 UIParent 825.5 -1018.8 -1 ##$$&('% 0 11 1 7 7 UIParent 0.0 45.0 -1 ##$$&('%,# 0 12 0 0 0 UIParent 825.5 -1018.8 -1 ##$$&('% 1 -1 0 1 1 UIParent 0.0 -713.8 -1 #($#%# 2 -1 1 2 2 UIParent 0.0 0.0 -1 ##$#%( 3 0 1 8 7 UIParent -300.0 250.0 -1 $#3# 3 1 1 6 7 UIParent 300.0 250.0 -1 %#3# 3 2 1 6 7 UIParent 520.0 265.0 -1 %#&#3# 3 3 0 0 0 UIParent 610.3 -532.8 -1 '$(#)#-C.)/#1$3#5%6(7-7$ 3 4 0 0 0 UIParent 124.3 -532.8 -1 ,%-%.)/#0#1#2(5%6(7-7$ 3 5 1 5 5 UIParent 0.0 0.0 -1 &#*$3# 3 6 1 5 5 UIParent 0.0 0.0 -1 -5.)/#4$5#6(7-7$ 3 7 1 4 4 UIParent 0.0 0.0 -1 3# 4 -1 0 4 4 UIParent 0.0 -330.0 -1 # 5 -1 0 7 7 UIParent -370.0 262.8 -1 # 6 0 1 2 2 UIParent -255.0 -10.0 -1 ##$#%#&.(()( 6 1 1 2 2 UIParent -270.0 -155.0 -1 ##$#%#'+(()(-$ 6 2 1 1 1 UIParent 0.0 -25.0 -1 ##$#%$&.(()(+#,-,$ 7 -1 1 7 7 UIParent 0.0 45.0 -1 # 8 -1 1 6 6 UIParent 35.0 50.0 -1 #'$A%$&i 9 -1 0 0 0 UIParent 1279.1 -1052.8 -1 # 10 -1 1 0 0 UIParent 16.0 -116.0 -1 # 11 -1 1 8 8 UIParent -9.0 85.0 -1 # 12 -1 1 2 2 UIParent -110.0 -275.0 -1 #K$#%# 13 -1 1 8 8 MicroButtonAndBagsBar 0.0 0.0 -1 ##$#%)&- 14 -1 1 2 2 MicroButtonAndBagsBar 0.0 10.0 -1 ##$#%( 15 0 0 1 1 UIParent 30.0 -22.8 -1 # 15 1 0 0 6 MainStatusTrackingBarContainer 0.0 -4.0 -1 # 16 -1 1 5 5 UIParent 0.0 0.0 -1 #( 17 -1 1 1 1 UIParent 0.0 -100.0 -1 ## 18 -1 1 5 5 UIParent 0.0 0.0 -1 #- 19 -1 1 7 7 UIParent 0.0 0.0 -1 ## 20 0 0 4 4 UIParent 0.0 -210.0 -1 ##$/%$&('#(-($)$+$,$-$ 20 1 0 7 7 UIParent 0.0 292.8 -1 ##$*%$&('%(-($)$+$,$-$ 20 2 0 7 7 UIParent 0.0 472.8 -1 ##$$%$&('((-($)$+$,$-$ 20 3 0 1 4 UIParent 377.0 -2.0 -1 #$$$%#&('((-($)%*#+$,$-$.-.$ 21 -1 1 7 7 UIParent -410.0 380.0 -1 ##$# 22 0 0 1 1 UIParent -269.5 -202.8 -1 #$$$%#&('((#)U*$+%,$-#.#/U0% 22 1 1 1 1 UIParent 0.0 -40.0 -1 &('()U*#+% 22 2 1 1 1 UIParent 0.0 -90.0 -1 &('()U*#+% 22 3 1 1 1 UIParent 0.0 -130.0 -1 &('()U*#+% 23 -1 1 0 0 UIParent 0.0 0.0 -1 ##$#%$&-&$'7(%)U+$,$-$.(/U"

local LAYOUT_NAME = "DessertUI"

-- Build a lookup of registered edit mode frames by system:systemIndex
local function buildFrameMap()
    local map = {}
    for _, frame in ipairs(EditModeManagerFrame.registeredSystemFrames) do
        local key = string_format("%d:%d", frame.system, frame.systemIndex or 0)
        map[key] = frame
    end
    return map
end

-- Apply the import string by parsing it and setting each frame via the lib
function Layout.Apply()
    local parsed = C_EditMode.ConvertStringToLayoutInfo(LAYOUT_IMPORT_STRING)
    if not parsed then
        ns.Utils.PrintMessage("Failed to parse layout import string.")
        return
    end

    LibEditMode:LoadLayouts()

    -- Create the layout if it doesn't exist yet
    if not LibEditMode:DoesLayoutExist(LAYOUT_NAME) then
        LibEditMode:AddLayout(Enum.EditModeLayoutType.Account, LAYOUT_NAME)
    else
        LibEditMode:SetActiveLayout(LAYOUT_NAME)
    end

    local frameMap = buildFrameMap()

    -- Apply each system's anchor and settings from the parsed layout
    for _, system in ipairs(parsed.systems) do
        local key = string_format("%d:%d", system.system, system.systemIndex or 0)
        local frame = frameMap[key]

        if frame then
            -- Apply anchor position
            local anchor = system.anchorInfo
            if anchor and not system.isInDefaultPosition then
                local relative_frame = _G[anchor.relativeTo] or UIParent
                pcall(LibEditMode.ReanchorFrame, LibEditMode,
                    frame, anchor.point, relative_frame, anchor.relativePoint, anchor.offsetX, anchor.offsetY)
            end

            -- Apply settings
            if system.settings then
                for _, setting in ipairs(system.settings) do
                    pcall(LibEditMode.SetFrameSetting, LibEditMode,
                        frame, setting.setting, setting.value)
                end
            end
        end
    end

    LibEditMode:ApplyChanges()
    ns.Utils.PrintMessage(string_format("%s layout applied.", LAYOUT_NAME))
end

-- Toggle callback for the settings system
function Layout.Toggle(value)
    if value then
        Layout.Apply()
    end
end

-- Initialize once Edit Mode is fully loaded
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
initFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent(event)
    if ns.Settings.GetOption("useDessertUILayout") then
        Layout.Apply()
    end
end)

local addon, ns = ...

-- Ensure namespaces exist
ns.UnitFrames = ns.UnitFrames or {}
local UnitFrames = ns.UnitFrames

-- Target of Target unit style
local function TargetOfTargetStyle(self, unit)
    -- Set target of target-specific frame size
    self:SetSize(110, 12)

    -- Health percentage and name text (left-aligned with arrow)
    self.SlimText = self:CreateFontString(nil, "OVERLAY")
    self.SlimText:SetFont(ns.Constants.fonts.arialNarrow, ns.Constants.fontSizes.small, "OUTLINE")
    self.SlimText:SetTextColor(1, 1, 1, 1)
    self.SlimText:SetShadowOffset(1, -1)
    self.SlimText:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.SlimText:SetJustifyH("LEFT")
    self.SlimText:SetMaxLines(1)
    self.SlimText:SetWordWrap(false)
    
    -- Register tags
    self:Tag(self.SlimText, "» [dUI_Name] [dUI_HP]")
    
    -- Create width adjustment function
    self.adjustWidth = UnitFrames.Common.CreateWidthAdjuster(self, "SlimText", 110, 0)
    
    -- Create update trigger for width adjustments
    UnitFrames.Common.CreateUpdateTrigger(self, self.adjustWidth)
    
    -- Initial width adjustment (deferred to allow text to populate)
    C_Timer.After(0.1, function()
        if self and self.adjustWidth and not InCombatLockdown() then
            self:adjustWidth()
        end
    end)
end

UnitFrames.TargetOfTargetStyle = TargetOfTargetStyle
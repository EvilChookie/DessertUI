local addon, ns = ...
local UnitFrames = ns.UnitFrames

-- Boss unit style (mirrored version of target frame)
local function BossStyle(self, unit)
    -- Set frame size (same as target)
    self:SetSize(110, 56)

    -- Health percentage (large font, anchored right, fixed width to prevent layout shift)
    self.HealthPercent = self:CreateFontString(nil, "OVERLAY")
    self.HealthPercent:SetFont(ns.Constants.fonts.rajdhaniBold, ns.Constants.fontSizes.xxlarge, "OUTLINE")
    self.HealthPercent:SetTextColor(1, 1, 1, 1)
    self.HealthPercent:SetShadowOffset(2, -2)
    self.HealthPercent:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
    self.HealthPercent:SetJustifyH("RIGHT")
    self.HealthPercent:SetWidth(ns.Constants.unitFrames.healthPercentWidth)

    -- Name (smaller font, positioned to the left of health)
    self.Name = self:CreateFontString(nil, "OVERLAY")
    self.Name:SetFont(ns.Constants.fonts.arialNarrow, ns.Constants.fontSizes.large, "OUTLINE")
    self.Name:SetTextColor(1, 1, 1, 1)
    self.Name:SetShadowOffset(1, -1)
    self.Name:SetPoint("RIGHT", self.HealthPercent, "LEFT", -4, -3)
    self.Name:SetJustifyH("RIGHT")
    self.Name:SetMaxLines(1)
    self.Name:SetWordWrap(false)

    -- Register tags
    self:Tag(self.HealthPercent, "[dUI_HP]")
    self:Tag(self.Name, "[dUI_Name]")

    -- Create a simple health element for oUF (invisible)
    self.Health = CreateFrame("StatusBar", nil, self)
    self.Health:SetAllPoints()
    self.Health:SetAlpha(0)
end

UnitFrames.BossStyle = BossStyle

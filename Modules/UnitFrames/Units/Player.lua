local addon, ns = ...

-- Ensure namespaces exist
ns.UnitFrames = ns.UnitFrames or {}
local UnitFrames = ns.UnitFrames

-- Player unit style
local function PlayerStyle(self, unit)
    -- Set player-specific frame size
    self:SetSize(110, 56)

    -- Health percentage text (large, right-aligned)
    self.HealthPercent = self:CreateFontString(nil, "OVERLAY")
    self.HealthPercent:SetFont(ns.Constants.fonts.rajdhaniBold, ns.Constants.fontSizes.xxlarge, "OUTLINE")
    self.HealthPercent:SetTextColor(1, 1, 1, 1)
    self.HealthPercent:SetShadowOffset(2, -2)
    self.HealthPercent:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
    self.HealthPercent:SetJustifyH("RIGHT")
    
    -- Health value (abbreviated, e.g., "125K")
    self.HealthValue = self:CreateFontString(nil, "OVERLAY")
    self.HealthValue:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 10, "OUTLINE")
    self.HealthValue:SetTextColor(0.8, 0.8, 0.8, 1)
    self.HealthValue:SetShadowOffset(1, -1)
    self.HealthValue:SetPoint("TOPRIGHT", self.HealthPercent, "BOTTOMRIGHT", 0, 4)
    self.HealthValue:SetJustifyH("RIGHT")

    -- Register health tags
    self:Tag(self.HealthPercent, "[dUI_HP_Class]")
    self:Tag(self.HealthValue, "[dUI_ShortHP]")

    -- Force update tags to populate text immediately
    if self.UpdateTags then
        self:UpdateTags()
    end
end

UnitFrames.PlayerStyle = PlayerStyle


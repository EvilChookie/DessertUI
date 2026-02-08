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
    
    -- Register health tags
    self:Tag(self.HealthPercent, "[dUI_HP_Class]")
    
    -- Force update tags to populate text immediately
    if self.UpdateTags then
        self:UpdateTags()
    end
end

UnitFrames.PlayerStyle = PlayerStyle


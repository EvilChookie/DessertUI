local addon, ns = ...

-- Ensure namespaces exist
ns.UnitFrames = ns.UnitFrames or {}
local UnitFrames = ns.UnitFrames

-- Target unit style
local function TargetStyle(self, unit)
    -- Set target-specific frame size
    self:SetSize(110, 56)

    -- Health percentage (large font, fixed width to prevent layout shift)
    self.HealthPercent = self:CreateFontString(nil, "OVERLAY")
    self.HealthPercent:SetFont(ns.Constants.fonts.rajdhaniBold, ns.Constants.fontSizes.xxlarge, "OUTLINE")
    self.HealthPercent:SetTextColor(1, 1, 1, 1)
    self.HealthPercent:SetShadowOffset(2, -2)
    self.HealthPercent:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.HealthPercent:SetJustifyH("LEFT")
    self.HealthPercent:SetWidth(ns.Constants.unitFrames.healthPercentWidth)

    -- Name (smaller font, positioned next to health)
    self.Name = self:CreateFontString(nil, "OVERLAY")
    self.Name:SetFont(ns.Constants.fonts.arialNarrow, ns.Constants.fontSizes.large, "OUTLINE")
    self.Name:SetTextColor(1, 1, 1, 1)
    self.Name:SetShadowOffset(1, -1)
    self.Name:SetPoint("LEFT", self.HealthPercent, "RIGHT", 4, -3)
    self.Name:SetJustifyH("LEFT")
    self.Name:SetMaxLines(1)
    self.Name:SetWordWrap(false)

    -- Classification and status text (small, above name)
    self.Classification = self:CreateFontString(nil, "OVERLAY")
    self.Classification:SetFont(ns.Constants.fonts.atkinsonHyperlegible, 8, "OUTLINE")
    self.Classification:SetTextColor(0.8, 0.8, 0.8, 1)
    self.Classification:SetShadowOffset(1, -1)
    self.Classification:SetPoint("BOTTOMLEFT", self.Name, "TOPLEFT", 0, 2)
    self.Classification:SetJustifyH("LEFT")

    -- Create auras container frame
    self.Auras = CreateFrame("Frame", nil, self)
    self.Auras:SetSize(100, 20)
    self.Auras:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT", 0, -10)
    self.Auras:SetFrameLevel(self:GetFrameLevel() + 1)

    -- Configure auras for oUF
    self.Auras.size = 24
    self.Auras.spacing = 4
    self.Auras.numBuffs = 8
    self.Auras.numDebuffs = 8
    self.Auras.initialAnchor = "TOPLEFT"
    self.Auras['growth-x'] = "RIGHT"
    self.Auras['growth-y'] = "DOWN"
    self.Auras.showDebuffType = true
    self.Auras.showType = true
    self.Auras.disableCooldown = true
    -- Set maxCols explicitly to avoid secret value arithmetic in oUF
    self.Auras.maxCols = 10  -- 100px width / (16px size + 2px spacing) ≈ 5 cols

    -- PostCreateButton callback for consistent aura icon styling
    self.Auras.PostCreateButton = function(auras, button)
        -- Basic icon styling with texture coords to remove border
        button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.Count:SetFont(ns.Constants.fonts.arialNarrow, 10, "OUTLINE")
        button.Count:ClearAllPoints()
        button.Count:SetPoint("BOTTOMRIGHT", 1, 0)
    end
    
    -- Register tags
    self:Tag(self.HealthPercent, "[dUI_HP]")
    self:Tag(self.Name, "[dUI_Name]")
    self:Tag(self.Classification, "[dUI_Classification] [dUI_Status]")

    -- Create a simple health element for oUF (invisible)
    self.Health = CreateFrame("StatusBar", nil, self)
    self.Health:SetAllPoints()
    self.Health:SetAlpha(0) -- Make it invisible
end

UnitFrames.TargetStyle = TargetStyle
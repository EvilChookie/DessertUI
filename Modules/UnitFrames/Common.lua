local addon, ns = ...

-- Ensure UnitFrames namespace exists
ns.UnitFrames = ns.UnitFrames or {}
local UnitFrames = ns.UnitFrames

UnitFrames.Common = UnitFrames.Common or {}

UnitFrames.Common.SetupTags = function(self, unit, elements)
    if not oUF or not oUF.tags then return end

    for element, tag in pairs(elements) do
        if self[element] then
            self:Tag(self[element], tag)
        end
    end
    
    if self.UpdateTags then
        self:UpdateTags()
    end
end

--[[
    Create a simple width adjustment function for unit frames
    
    @param self frame - The unit frame to adjust
    @param nameElement string - The name of the name element (e.g., "Name")
    @param minWidth number - Minimum width to prevent frames from being too small (default: 50)
    @param padding number - Extra padding for visual spacing (default: 0)
    @return function - The adjustment function
]]
UnitFrames.Common.CreateWidthAdjuster = function(self, nameElement, minWidth, padding)
    minWidth = minWidth or 50
    padding = padding or 0
    
    return function()
        if InCombatLockdown() then return end

        local nameFrame = self[nameElement]
        if not nameFrame then return end

        -- GetStringWidth() can return a secret value, so wrap arithmetic in pcall
        local success, newWidth = pcall(function()
            local nameWidth = nameFrame:GetStringWidth() or 0
            return nameWidth + padding
        end)

        if not success then
            -- If we get a secret value, use minimum width
            newWidth = minWidth
        else
            -- Apply minimum width to prevent frames from being too small
            if newWidth < minWidth then
                newWidth = minWidth
            end
        end

        self:SetWidth(newWidth)

        -- Update background if it exists
        if self.Background then
            self.Background:SetAllPoints()
        end
    end
end

--[[
    Create an UpdateTrigger frame for width adjustment functionality
    
    @param self frame - The unit frame to add the trigger to
    @param adjustWidthFunc function - The width adjustment function to call
    @return frame - The created UpdateTrigger frame
]]
UnitFrames.Common.CreateUpdateTrigger = function(self, adjustWidthFunc)
    -- Create a simple health element to trigger updates (like the backup)
    self.Health = CreateFrame("StatusBar", nil, self)
    self.Health:SetAllPoints()
    self.Health:SetAlpha(0) -- Make it completely invisible
    
    -- Use Health.PostUpdate to trigger width adjustments (same as backup approach)
    self.Health.PostUpdate = function(element, u)
        local frame = element.__owner
        if not frame or frame.unit ~= u then return end
        
        -- Size adjustments (deferred to avoid combat issues)
        if not InCombatLockdown() then
            if adjustWidthFunc then
                adjustWidthFunc()
            end
        end
    end
    
    return self.Health
end



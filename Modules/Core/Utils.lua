local addon, ns = ...

--[[
    Utility Functions

    RegisterCallback based on rLib by zork (https://github.com/zorker/rothui)
]]

ns.Utils = ns.Utils or {}
local Utils = ns.Utils

-- Cache frequently used functions
local string_format = string.format

Utils.Hex = function(r, g, b)
	if r then
		if type(r) == "table" then
			if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
		end
		return string_format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
	end
end

Utils.ShortNumber = function(number)
    -- Use WoW's built-in function to handle secret values
    return AbbreviateLargeNumbers(number)
end

Utils.SetUnitDefaults = function(self)
    self:RegisterForClicks("AnyDown")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
end

Utils.RegisterCallback = function(event, callback, ...)
    if not Utils.eventFrame then
        Utils.eventFrame = CreateFrame("Frame")
        function Utils.eventFrame:OnEvent(event, ...)
            for callback, args in next, self.callbacks[event] do
                callback(args, ...)
            end
        end
        Utils.eventFrame:SetScript("OnEvent", Utils.eventFrame.OnEvent)
    end
    if not Utils.eventFrame.callbacks then Utils.eventFrame.callbacks = {} end
    if not Utils.eventFrame.callbacks[event] then Utils.eventFrame.callbacks[event] = {} end
    Utils.eventFrame.callbacks[event][callback] = {...}
    Utils.eventFrame:RegisterEvent(event)
end

Utils.PrintMessage = function(message)
    local title = ns.Constants and ns.Constants.DessertUITitle or "DessertUI"
    print(string_format("%s|r: %s", title, message))
end
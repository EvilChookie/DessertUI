local addon, ns = ...

local function InitializeUnitFrames()
    if ns.UnitFrames then
        ns.UnitFrames:Initialize()
    end
end

local function Welcome()
    ns.Utils.PrintMessage("Welcome to DessertUI!")
end

local function InitializeSlashCommands()
    if ns.Slash then
        ns.Slash.Initialize()
    end
end

-- Register Callbacks:
ns.Utils.RegisterCallback("PLAYER_ENTERING_WORLD", InitializeUnitFrames)
ns.Utils.RegisterCallback("PLAYER_LOGIN", Welcome)
ns.Utils.RegisterCallback("PLAYER_ENTERING_WORLD", InitializeSlashCommands)
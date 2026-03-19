local addon, ns = ...

local function InitializeUnitFrames()
    if ns.UnitFrames then
        ns.UnitFrames:Initialize()
    end
end

local function InitializeCooldownManager()
    if ns.Resources then
        ns.Resources.Initialize()
    end
    if ns.CastBar then
        ns.CastBar.Initialize()
    end
    if ns.MirrorBar then
        ns.MirrorBar.Initialize()
    end
    if ns.DataBar then
        ns.DataBar.Initialize()
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
ns.Utils.RegisterCallback("PLAYER_ENTERING_WORLD", InitializeCooldownManager)
ns.Utils.RegisterCallback("PLAYER_LOGIN", Welcome)
ns.Utils.RegisterCallback("PLAYER_ENTERING_WORLD", InitializeSlashCommands)
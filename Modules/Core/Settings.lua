local addon, ns = ...

-- Initialize the Settings namespace
ns.Settings = {}

-- Flag to track if settings have been registered
local settingsRegistered = false
-- Store the category ID for later use
local settingsCategoryID = nil

-- Cache frequently used functions
local type = type
local pcall = pcall
local string_format = string.format

-- Safe getter for saved variables with fallback to defaults
function ns.Settings.GetOption(optionName)
    -- Ensure database is initialized
    if not DessertUIDB or type(DessertUIDB) ~= "table" then
        dUI_Defaults(nil, "ADDON_LOADED", "DessertUI")
    end
    
    -- Return the saved value or default
    if DessertUIDB and DessertUIDB[optionName] ~= nil then
        return DessertUIDB[optionName]
    end
    
    -- Fallback to default from constants (authoritative source)
    if ns.Constants and ns.Constants.options and ns.Constants.options[optionName] then
        return ns.Constants.options[optionName].defaultValue
    end
    
    -- If option doesn't exist in constants, return nil
    -- This helps catch typos or missing options
    return nil
end

-- Safe setter for saved variables
function ns.Settings.SetOption(optionName, value)
    -- Validate the option and value
    if ns.Constants and ns.Constants.ValidateOption then
        local isValid, errorMsg = ns.Constants.ValidateOption(optionName, value)
        if not isValid then
            ns.Utils.PrintMessage(string_format("Invalid option value: %s", errorMsg))
            return false
        end
    end
    
    -- Ensure database is initialized
    if not DessertUIDB or type(DessertUIDB) ~= "table" then
        dUI_Defaults(nil, "ADDON_LOADED", "DessertUI")
    end
    
    if DessertUIDB and type(DessertUIDB) == "table" then
        -- Check if the value is actually changing
        local oldValue = DessertUIDB[optionName]
        if oldValue ~= value then
            DessertUIDB[optionName] = value
            return true
        end
    end
    
    return false
end

-- Check if database is ready
function ns.Settings.IsReady()
    return DessertUIDB ~= nil and type(DessertUIDB) == "table"
end

-- Ensure database is ready (for other modules to call)
function ns.Settings.EnsureReady()
    if not ns.Settings.IsReady() then
        dUI_Defaults(nil, "ADDON_LOADED", "DessertUI")
    end
    return ns.Settings.IsReady()
end

-- Get all options as a table (useful for other modules)
function ns.Settings.GetAllOptions()
    if not ns.Settings.EnsureReady() then
        return {}
    end
    
    local result = {}
    if ns.Constants and ns.Constants.options then
        local optionsOrder = ns.Constants.options.order or {}
        for _, name in ipairs(optionsOrder) do
            local option = ns.Constants.options[name]
            if option then
                result[name] = ns.Settings.GetOption(option.variable)
            end
        end
    end
    return result
end

-- Simplified callback execution function
local function ExecuteCallback(callbackPath, value)
    if not callbackPath or type(callbackPath) ~= "string" then
        return false, "Invalid callback path"
    end
    
    -- Parse the callback path (e.g., "UnitFrames.ToggleUnitFader")
    local parts = {}
    for part in callbackPath:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    -- Navigate to the callback function
    local func = ns
    for i, part in ipairs(parts) do
        if func and func[part] then
            func = func[part]
        else
            return false, string_format("Callback function not found: %s", callbackPath)
        end
    end
    
    -- Call the function with the new value
    if type(func) == "function" then
        local success, err = pcall(func, value)
        if not success then
            return false, string_format("Callback execution failed: %s", err or "unknown error")
        end
        return true
    else
        return false, string_format("Callback is not a function: %s", callbackPath)
    end
end

function dUI_Defaults(callbackArgs, eventName, ...)
    if select(1, ...) == "DessertUI" then
        -- Check if this is a fresh install (saved variables file doesn't exist yet)
        if DessertUIDB == nil then
            -- Fresh install - create new database
            DessertUIDB = {}
        elseif type(DessertUIDB) ~= "table" then
            -- Corrupted saved variables - reset to fresh database
            DessertUIDB = {}
        end
        
        -- Now ensure all required options have default values
        if ns.Constants and ns.Constants.options then
            local optionsOrder = ns.Constants.options.order or {}
            for _, name in ipairs(optionsOrder) do
                local option = ns.Constants.options[name]
                if option and DessertUIDB[option.variable] == nil then
                    DessertUIDB[option.variable] = option.defaultValue
                end
            end
        end
    end
end

function dUI_SettingsScreen()
    -- Safety check: ensure DessertUIDB is initialized before creating settings
    if not DessertUIDB or type(DessertUIDB) ~= "table" then
        -- If somehow the database isn't ready, initialize it now
        dUI_Defaults(nil, "ADDON_LOADED", "DessertUI")
    end
    
    -- Double-check that we have everything we need
    if not DessertUIDB or type(DessertUIDB) ~= "table" then
        return
    end
    
    if not ns.Constants or not ns.Constants.options then
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory("Dessert UI")
    
    -- Store the category ID for later use
    if category then
        settingsCategoryID = category:GetID()
    end

    -- Load the defaults from the constants table in the specified order:
    local optionsOrder = ns.Constants.options.order or {}
    for _, name in ipairs(optionsOrder) do
        local option = ns.Constants.options[name]
        if option then
        if option.type == "toggle" then
            local setting = Settings.RegisterAddOnSetting(category, option.variable, option.variableKey, DessertUIDB, type(option.defaultValue), option.name, option.defaultValue)
            
            -- Set up value changed callback
            setting:SetValueChangedCallback(function(setting, value)
                local optionData = ns.Constants.options[option.variable]
                local displayName = optionData.name
                
                -- Check if this option supports real-time changes
                if optionData.realtime and optionData.callback then
                    -- Execute the real-time callback
                    local success, err = ExecuteCallback(optionData.callback, value)
                    
                    if success then
                        ns.Utils.PrintMessage(string_format("%s setting changed.", displayName))
                    else
                        ns.Utils.PrintMessage(string_format("%s setting changed, but callback failed: %s", displayName, err or "unknown error"))
                        ns.Utils.PrintMessage("Please reload UI (/reload) for changes to take effect.")
                    end
                else
                    -- Standard message for non-real-time options
                    ns.Utils.PrintMessage(string_format("%s setting changed. Please reload UI (/reload) for changes to take effect.", displayName))
                end
            end)
            
            Settings.CreateCheckbox(category, setting, option.tooltip)
        elseif option.type == "dropdown" then
            -- Get dropdown values
            local values = {}
            if option.getValues and type(option.getValues) == "function" then
                -- Dynamic options from function
                values = option.getValues()
            elseif option.values and type(option.values) == "table" then
                -- Static options from table
                values = option.values
            else
                -- Fallback to default only
                values = {option.defaultValue}
            end
            
            -- Ensure default value is in the values list
            local defaultFound = false
            for _, value in ipairs(values) do
                if value == option.defaultValue then
                    defaultFound = true
                    break
                end
            end
            if not defaultFound then
                table.insert(values, 1, option.defaultValue) -- Add default at the beginning
            end
            
            -- Ensure current saved value is valid, if not use default
            local currentValue = DessertUIDB[option.variable]
            if currentValue then
                local valueFound = false
                for _, value in ipairs(values) do
                    if value == currentValue then
                        valueFound = true
                        break
                    end
                end
                if not valueFound then
                    DessertUIDB[option.variable] = option.defaultValue
                    currentValue = option.defaultValue
                end
            else
                DessertUIDB[option.variable] = option.defaultValue
                currentValue = option.defaultValue
            end
            
            -- Create options using WoW's proper Settings API
            local function GetOptions()
                local container = Settings.CreateControlTextContainer()
                for _, value in ipairs(values) do
                    container:Add(value, value) -- value, label
                end
                return container:GetData()
            end
            
            -- Create dropdown setting with validated current value
            local setting = Settings.RegisterAddOnSetting(category, option.variable, option.variableKey, DessertUIDB, type(currentValue), option.name, currentValue)
            
            -- Immediately set the setting's value to ensure it matches an option
            setting:SetValue(currentValue)
            
            -- Set up value changed callback
            setting:SetValueChangedCallback(function(setting, value)
                local optionData = ns.Constants.options[option.variable]
                local displayName = optionData.name
                
                -- Check if this option supports real-time changes
                if optionData.realtime and optionData.callback then
                    -- Execute the real-time callback
                    local success, err = ExecuteCallback(optionData.callback, value)
                    
                    if success then
                        ns.Utils.PrintMessage(string_format("%s setting changed.", displayName))
                    else
                        ns.Utils.PrintMessage(string_format("%s setting changed, but callback failed: %s", displayName, err or "unknown error"))
                        ns.Utils.PrintMessage("Please reload UI (/reload) for changes to take effect.")
                    end
                else
                    -- Standard message for non-real-time options
                    ns.Utils.PrintMessage(string_format("%s setting changed. Please reload UI (/reload) for changes to take effect.", displayName))
                end
            end)
            
            Settings.CreateDropdown(category, setting, GetOptions, option.tooltip)
        end
    end
    end

    Settings.RegisterAddOnCategory(category)
end

-- Validate that all callback paths in options resolve to functions
local function ValidateCallbacks()
    if not ns.Constants or not ns.Constants.options then return end

    for _, name in ipairs(ns.Constants.options.order) do
        local option = ns.Constants.options[name]
        if option and option.callback then
            local success, _ = pcall(function()
                -- Test resolve the callback path
                local func = ns
                for part in option.callback:gmatch("[^%.]+") do
                    func = func[part]
                end
                if type(func) ~= "function" then
                    error("not a function")
                end
            end)
            if not success then
                ns.Utils.PrintMessage(string_format("Warning: Invalid callback path '%s' for option '%s'", option.callback, name))
            end
        end
    end
end

-- Function to register settings (called once during initialization)
function dUI_RegisterSettings()
    if settingsRegistered then
        return -- Already registered
    end

    -- Validate callbacks before settings are used
    ValidateCallbacks()

    dUI_SettingsScreen()
    settingsRegistered = true
end

-- Function to open settings (called when user wants to access settings)
function dUI_OpenSettings()
    -- Ensure settings are registered
    if not settingsRegistered then
        dUI_RegisterSettings()
    end
    
    -- Use the category ID to open the settings UI
    if Settings and Settings.OpenToCategory and settingsCategoryID then
        Settings.OpenToCategory(settingsCategoryID)
    end
end

ns.Utils.RegisterCallback("ADDON_LOADED", dUI_Defaults)
ns.Utils.RegisterCallback("PLAYER_LOGIN", dUI_RegisterSettings)

-- Register slash commands for this module
if ns.Slash then
    ns.Slash.Register({"settings", "config", "options"}, function(msg, argv)
        dUI_OpenSettings()
    end, { description = "Open the DessertUI settings screen" })
end
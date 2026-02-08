local addon, ns = ...

--[[
    Slash Command System for DessertUI
    
    This module provides a flexible slash command system that allows:
    - Registration of commands with aliases
    - Built-in help system
    - Error handling for command execution
    - Support for both simple and complex command structures
    - Automatic registration with WoW's slash command system
    
    Commands are registered using Slash.Register() and can have multiple aliases.
    The system automatically handles command parsing and provides helpful error messages.
]]

local Slash = {}
ns.Slash = Slash

-- Cache frequently used functions for performance
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local string_lower = string.lower
local string_match = string.match
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local pcall = pcall

-- Local variables
local registered = {}
local aliasToPrimary = {}
local isInitialized = false

-- Optimized trim function using pattern matching
local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$")
end

-- Optimized tokenize function with pre-allocated table
local function tokenize(s)
    if not s or s == "" then return {} end
    
    local t = {}
    for token in s:gmatch("%S+") do
        t[#t+1] = token
    end
    return t
end

-- Cache the title string to avoid repeated table lookups
local function getTitle()
    return ns.Constants.DessertUITitle or "DessertUI"
end

local function printHeader()
    print(getTitle() .. " commands:")
end

local function printLine(cmd, desc)
    if desc and desc ~= "" then
        print("/dui "..cmd.." - "..desc)
    else
        print("/dui "..cmd)
    end
end

-- Optimized getPrimary function with early returns
local function getPrimary(name)
    if not name then return nil end
    local key = string_lower(name)
    return aliasToPrimary[key] or key
end

-- Register command with WoW's slash command system
local function registerWithWoW()
    if isInitialized then return end
    
    -- Register the main slash command
    _G["SLASH_DESSERTUI1"] = "/dui"
    _G["SLASH_DESSERTUI2"] = "/dessertui"
    
    -- Set up the slash command handler
    SlashCmdList["DESSERTUI"] = function(msg)
        Slash.Handle(msg)
    end
    
    isInitialized = true
end

function Slash.Register(names, handler, opts)
    if not names or not handler then
        ns.Utils.PrintMessage("Slash.Register: Invalid parameters provided")
        return
    end

    local primary
    if type(names) == "table" then
        primary = names[1]
        if not primary then
            ns.Utils.PrintMessage("Slash.Register: Empty table provided")
            return
        end
        primary = string_lower(primary)
        
        -- Register all aliases
        for _, alias in ipairs(names) do
            if type(alias) == "string" then
                aliasToPrimary[string_lower(alias)] = primary
            end
        end
    else
        primary = string_lower(tostring(names))
        aliasToPrimary[primary] = primary
    end

    -- Store command information
    registered[primary] = {
        handler = handler,
        description = opts and opts.description or "",
        usage = opts and opts.usage or "",
        aliases = type(names) == "table" and names or { names },
    }
    
    -- Ensure WoW registration happens
    registerWithWoW()
end

function Slash.Help(specific)
    local key = getPrimary(specific)
    if key and registered[key] then
        local info = registered[key]
        printLine(table.concat(info.aliases, ", "), info.description)
        if info.usage and info.usage ~= "" then
            print("Usage: "..info.usage)
        end
        return
    end

    printHeader()
    
    -- Collect and sort keys for consistent output
    local keys = {}
    for k in pairs(registered) do 
        table_insert(keys, k) 
    end
    table_sort(keys)
    
    for _, k in ipairs(keys) do
        local info = registered[k]
        printLine(info.aliases[1], info.description)
    end
    print("Use '/dui help <command>' for details on a command.")
end

function Slash.Handle(msg)
    local input = trim(msg)
    local argv = tokenize(input)
    local sub = argv[1] and string_lower(argv[1]) or nil

    -- Handle help commands
    if not sub or sub == "help" or sub == "?" or sub == "h" then
        Slash.Help(argv[2])
        return
    end

    local key = getPrimary(sub)
    local info = key and registered[key] or nil
    if not info then
        print("Unknown command: '"..(sub or "").."'")
        Slash.Help()
        return
    end

    -- Remove the command name from arguments
    table_remove(argv, 1)
    
    -- Execute command with error handling
    local ok, err = pcall(info.handler, table.concat(argv, " "), argv)
    if not ok then
        print("Command error: "..tostring(err))
        if info.usage and info.usage ~= "" then
            print("Usage: "..info.usage)
        end
    end
end

-- Initialize the slash command system
function Slash.Initialize()
    registerWithWoW()
end

-- Public API
ns.Slash = Slash
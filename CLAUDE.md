# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DessertUI is a World of Warcraft addon that provides custom unit frames and UI enhancements. It uses oUF (a unit frame framework) as a submodule for unit frame creation and management.

## Development Notes

- No build system or tests - this is a WoW addon loaded directly by the game client
- Changes are tested by reloading the UI in-game (`/reload`)
- Use `/dui` or `/dessertui` to access addon commands
- Use `/dui settings` to open the settings panel

## Architecture

### Namespace Pattern
All modules use the shared namespace pattern:
```lua
local addon, ns = ...
```
- `addon` - The addon name string ("DessertUI")
- `ns` - Shared namespace table for cross-module communication

### Core Modules (loaded first via TOC)
- **Constants.lua** - All configuration values: frame positions, fader settings, fonts, unit frame dimensions, glow colors, and option definitions
- **Slash.lua** - Slash command system with alias support; register commands via `ns.Slash.Register(names, handler, opts)`
- **Utils.lua** - Utilities including `RegisterCallback(event, callback)` for WoW event handling, `PrintMessage()` for formatted output
- **Fader.lua** - Frame fade animation system supporting mouseover and combat-based fading
- **Settings.lua** - WoW Settings API integration; saved variables stored in `DessertUIDB`

### UnitFrames Module
- **UnitFrames.lua** - Main oUF integration, style registration, and frame spawning
- **Common.lua** - Shared utilities for unit frames (tag setup, width adjustment)
- **Tags.lua** - Custom oUF tags for health/power/name display
- **Units/*.lua** - Individual unit frame styles (Player, Target, Pet, etc.)

### Callback System
Register for WoW events via:
```lua
ns.Utils.RegisterCallback("EVENT_NAME", callbackFunction)
```

### Settings System
Options are defined in `ns.Constants.options` with callbacks for real-time changes. Access values via `ns.Settings.GetOption("optionName")`.

## Coding Standards (from .cursorrules)

### Performance Patterns
- Cache frequently used functions at module top:
```lua
local pairs = pairs
local string_format = string.format
local table_insert = table.insert
```
- Use string formatting instead of concatenation: `("text %s"):format(value)`
- Use early returns to avoid unnecessary processing

### Module Structure
```lua
local addon, ns = ...
local ModuleName = {}
ns.ModuleName = ModuleName
-- cached functions
-- local variables
-- functions
```

### Naming Conventions
- `camelCase` for function names
- `snake_case` for local variables
- `UPPER_CASE` for constants

### Libraries
**Do not modify any code in the Libs directory.** Libraries are external dependencies:
- LibStub - Library versioning
- LibSharedMedia-3.0 - Shared media resources
- LibDispel - Dispel type detection
- oUF (submodule) - Unit frame framework

### Design Decisions
- **Boss Frame Faders**: Boss frames do not use faders. They are only created during boss encounters (created on combat start, destroyed on combat end) so out-of-combat fading is not applicable.

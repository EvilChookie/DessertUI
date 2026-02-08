local addon, ns = ...

--[[
    Core Constants for DessertUI
    
    This module contains all the configuration constants used throughout the addon.
    Constants are organized by functionality for better maintainability.
]]

ns.Constants = {
    -- Frame sizing constants for better mouse interaction and text accommodation
    frames = {
        positions = {
            player = { point = "TOPRIGHT", relative = "CENTER", x = -200, y = -120 },
            target = { point = "TOPLEFT", relative = "CENTER", x = 200, y = -120 },
            pet = { point = "TOPRIGHT", relative = "CENTER", x = -200, y = -105 },
            tot = { point = "TOPLEFT", relative = "CENTER", x = 200, y = -105 },
            focus = { point = "TOPLEFT", relative = "CENTER", x = 200, y = -90 },
            boss1 = { point = "TOPRIGHT", relative = "TOPRIGHT", x = -300, y = -275 },
            boss2 = { point = "TOPRIGHT", relative = "TOPRIGHT", x = -300, y = -325 },
            boss3 = { point = "TOPRIGHT", relative = "TOPRIGHT", x = -300, y = -375 },
            boss4 = { point = "TOPRIGHT", relative = "TOPRIGHT", x = -300, y = -425 },
        },
    },
    
    -- Unit frame names for fader configuration
    -- combined: frames that use both mouseover and combat faders
    -- mouseover: frames that only use mouseover fader
    unitFrameNames = {
        combined = {"Player", "Target", "Pet", "Target of Target", "Focus"},
        mouseover = {},
    },

    -- Fader configurations - consolidated and simplified
    -- These control how UI elements fade in/out based on mouseover and combat state
    faders = {
        -- Mouseover-only fader: shows/hides on mouse enter/leave
        mouseover = {
            enableMouseover = true,
            enableCombat = false,
            fadeInAlpha = 1,
            fadeOutAlpha = 0,
            fadeInDuration = 0.15,
            fadeOutDuration = 0.15,
            fadeInSmooth = "IN_OUT",
            fadeOutSmooth = "IN_OUT",
        },
        -- Combined fader: handles both mouseover and combat states
        -- Prioritizes mouseover over combat state
        combined = {
            enableMouseover = true,
            enableCombat = true,
            fadeInAlpha = 1,
            fadeOutAlpha = 0.2,
            fadeInDuration = 0.15,
            fadeOutDuration = 0.15,
            fadeInSmooth = "IN_OUT",
            fadeOutSmooth = "IN_OUT",
            inCombatAlpha = 1,
            outCombatAlpha = 0.2,
            inCombatDuration = 0.15,
            outCombatDuration = 0.15,
            inCombatSmooth = "IN_OUT",
            outCombatSmooth = "IN_OUT",
        },
    },

    -- Font definitions for consistent typography across the UI
    fonts = {
        rajdhaniBold = "Interface\\AddOns\\" .. tostring(addon) .. "\\Fonts\\Rajdhani.ttf",
        atkinsonHyperlegible = "Interface\\AddOns\\" .. tostring(addon) .. "\\Fonts\\AtkinsonHyperlegible.ttf",
        arialNarrow  = "Fonts\\ARIALN.ttf",
    },

    fontSizes = {
        xxlarge = 48,
        xlarge = 36,
        large = 24,
        medium = 18,
        small = 12,
        unitName = 10,
        unitHealth = 8,
    },

    -- Unit frame constants
    unitFrames = {
        -- Frame dimensions
        dimensions = {
            base = { width = 155, height = 41 }, -- xlarge font size + 20px for role icons + 5px for power bar space
            healer = { width = 182, height = 55 }, -- + 20px for role icons + 3px for power bar space
            target = { width = 200, height = 40 },
        },
        
        -- Glow and shadow settings
        glowSize = 4,
        shadowOffset = 2,
        
        -- Spacing and offsets
        spacing = {
            nameOffset = 8,
            iconOffset = 4,
            borderOffset = 2,
        },

        -- Health percentage text width (fixed to prevent layout shift)
        healthPercentWidth = 115,
        
        -- Power bar settings
        powerBar = {
            height = {
                base = 5,
                healer = 3,
            },
        },
        
        -- Glow color states
        glowColors = {
            shadow = {0, 0, 0, 0.4},
            hover = {1, 1, 0.5, 0.6},
            target = {1, 1, 0, 0.9},
            -- Dispel colors by debuff type
            dispel_Magic = {0.2, 0.6, 1.0, 0.8},
            dispel_Curse = {0.6, 0.0, 1.0, 0.8},
            dispel_Disease = {0.6, 0.4, 0.0, 0.8},
            dispel_Poison = {0.0, 0.8, 0.0, 0.8},
        },
        
        -- Background colors
        backgrounds = {
            base = {0.15, 0.17, 0.2, 0.95},
            healer = {0.12, 0.15, 0.18, 0.98},
        },
    },

    -- Unit classification labels for target frames
    classifications = {
        worldboss = "WORLD BOSS",
        rareelite = "RARE ELITE",
        elite = "ELITE",
        rare = "RARE",
        trivial = "TRIVIAL",
        minus = "INSIGNIFICANT",
    },

    -- Option Constants:
    options = {
        -- Ordered list to control display order
        order = {
            "microMenuFader",
            "bagFader",
            "unitFader",
        },
        
        -- Option definitions (same as before)
        microMenuFader = {
            name = "Micro Menu Fader",
            variable = "microMenuFader",
            variableKey = "microMenuFader",
            tooltip = "Fade the micro menu until you mouse over it.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Faders.ToggleMicroMenuFaderSilent",
        },
        bagFader = {
            name = "Bag Fader",
            variable = "bagFader",
            variableKey = "bagFader",
            tooltip = "Fade bags until you mouse over them.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Faders.ToggleBagFaderSilent",
        },
        unitFader = {
            name = "Unit Fader",
            variable = "unitFader",
            variableKey = "unitFader",
            tooltip = "Fade the Player, Target, Pet, ToT, and Focus frames when not in combat or on mouseover.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Faders.ToggleUnitFaderSilent",
        },
    },
}

-- Simple dessert-themed color string for "DessertUI"
ns.Constants.DessertUITitle = "|cffffffffDessert|cffdc143cUI|r"
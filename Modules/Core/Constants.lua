local addon, ns = ...

--[[
    Core Constants for DessertUI
    
    This module contains all the configuration constants used throughout the addon.
    Constants are organized by functionality for better maintainability.
]]

-- Detect optional dependencies (loaded before us via OptionalDeps in TOC)
ns.hasBartender4 = C_AddOns.IsAddOnLoaded("Bartender4")

ns.Constants = {
    -- Data Bar Configuration
    databar = {
        height = 22,
        opacity = 1,
        verticalOffset = -0.5,
    },

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
    
    -- Fader configuration for unit frames (mouseover + combat aware)
    faders = {
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
        mouseoverOnly = {
            enableMouseover = true,
            fadeInAlpha = 1,
            fadeOutAlpha = 0,
            fadeInDuration = 0.15,
            fadeOutDuration = 0.3,
            fadeInSmooth = "IN_OUT",
            fadeOutSmooth = "IN_OUT",
            fadeOutDelay = 0.5,
        },
        actionBars = {
            enableMouseover = true,
            enableCombat = true,
            fadeInAlpha = 1,
            fadeOutAlpha = 0.2,
            fadeInDuration = 0.15,
            fadeOutDuration = 0.3,
            fadeInSmooth = "IN_OUT",
            fadeOutSmooth = "IN_OUT",
            inCombatAlpha = 0,
            outCombatAlpha = 1,
            inCombatDuration = 0.15,
            outCombatDuration = 0.3,
            inCombatSmooth = "IN_OUT",
            outCombatSmooth = "IN_OUT",
            skipEnableMouse = true,
        },
    },

    -- Font definitions for consistent typography across the UI
    fonts = {
        rajdhaniBold = "Interface\\AddOns\\" .. tostring(addon) .. "\\Fonts\\Rajdhani.ttf",
        atkinsonHyperlegible = "Interface\\AddOns\\" .. tostring(addon) .. "\\Fonts\\AtkinsonHyperlegible.ttf",
        arialNarrow  = "Fonts\\ARIALN.ttf",
        pixelifySans = "Interface\\AddOns\\" .. tostring(addon) .. "\\Fonts\\PixelifySans.ttf",
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

    -- Cooldown Manager: Cast Bar + Resource Display
    -- Stacked layout: cast bar (42h, matches rendered text height) + power bars below
    -- Cast bar is 90% of the 400wu gap between player/target frames (360wu)
    -- Power bars keep their own heights and sit directly under the cast bar
    cooldownManager = {
        layout = {
            width = 360,       -- 90% of 400wu gap between player (-200) and target (+200)
            blockY = -120,     -- aligned with unit frame tops
        },
        castBar = {
            position = { point = "TOP", relative = "CENTER", x = 0, y = -120 },
            width = 360,
            height = 42,            -- matches rendered HP% text height
            iconSize = 20,
            sparkWidth = 2,
            holdTime = 0.5,
            maxNameChars = 20,
            colors = {
                casting = { 1.0, 0.7, 0.0 },
                channeling = { 0.0, 1.0, 0.0 },
                empowering = { 0.0, 0.8, 1.0 },
                nonInterruptible = { 0.7, 0.7, 0.7 },
                failed = { 1.0, 0.0, 0.0 },
            },
            background = { 0.15, 0.17, 0.2, 0.95 },
        },
        resources = {
            primaryBar = {
                width = 360,
                height = 12,
                expandedHeight = 24,    -- when no secondary power
                background = { 0.15, 0.17, 0.2, 0.95 },
                position = { point = "TOP", relative = "CENTER", x = 0, y = -162 },  -- blockY - castBar.height
            },
            secondaryBar = {
                pipHeight = 12,         -- 25% of totalHeight
                pipSpacing = 2,
                background = { 0.1, 0.1, 0.1, 0.9 },
            },
        },
        -- Power type colors indexed by Enum.PowerType value
        powerColors = {
            [0]  = { 0.00, 0.00, 1.00 },  -- Mana
            [1]  = { 1.00, 0.00, 0.00 },  -- Rage
            [2]  = { 1.00, 0.50, 0.25 },  -- Focus
            [3]  = { 1.00, 1.00, 0.00 },  -- Energy
            [6]  = { 0.00, 0.82, 1.00 },  -- Runic Power
            [8]  = { 0.30, 0.52, 0.90 },  -- Lunar Power (Astral)
            [11] = { 0.00, 0.50, 1.00 },  -- Maelstrom
            [13] = { 0.40, 0.00, 0.80 },  -- Insanity
            [17] = { 0.79, 0.26, 0.99 },  -- Fury
            [18] = { 1.00, 0.61, 0.00 },  -- Pain
        },
        -- Secondary resource colors by resource type key
        secondaryColors = {
            COMBO_POINTS      = { 1.00, 0.96, 0.41 },
            COMBO_CHARGED     = { 0.25, 0.50, 1.00 },
            HOLY_POWER        = { 0.95, 0.90, 0.60 },
            CHI               = { 0.71, 1.00, 0.92 },
            ARCANE_CHARGES    = { 0.10, 0.10, 0.98 },
            SOUL_SHARDS       = { 0.58, 0.51, 0.79 },
            ESSENCE           = { 0.20, 0.58, 0.50 },
            RUNES_BLOOD       = { 1.00, 0.25, 0.25 },
            RUNES_FROST       = { 0.25, 1.00, 1.00 },
            RUNES_UNHOLY      = { 0.25, 1.00, 0.25 },
            STAGGER_LIGHT     = { 0.25, 1.00, 0.25 },
            STAGGER_MODERATE  = { 1.00, 1.00, 0.25 },
            STAGGER_HEAVY     = { 1.00, 0.25, 0.25 },
            MAELSTROM         = { 0.25, 0.50, 0.80 },
        },
        -- Secondary resource spec mapping: specID → { powerType, maxFunc, colorKey, displayType }
        -- displayType: "pips" | "bars" (runes) | "bar" (stagger/destro shards)
        -- Populated after constants table is complete (see below)
    },

    -- Mirror Bar: thin status bar for breath, fatigue, feign death, etc.
    -- Anchored to the player frame's right edge, just below it
    mirrorBar = {
        barHeight = 2,
        barWidth = 110,         -- matches player frame width
        textOffset = 2,         -- gap between text and bar
        spacing = 2,            -- vertical gap between stacked bars
        holdTime = 1.0,         -- seconds to hold bar after timer expires
        background = { 0.15, 0.17, 0.2, 0.95 },
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
            "useDessertUILayout",
            "unitFader",
            "actionBarFader",
            "showCastBar",
            "showPrimaryPower",
            "showSecondaryPower",
            "resourceFader",
            "showMirrorBar",
            "showDataBar",
        },

        useDessertUILayout = {
            name = "Use DessertUI Layout",
            variable = "useDessertUILayout",
            variableKey = "useDessertUILayout",
            tooltip = "Import and activate the DessertUI Edit Mode layout.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Layout.Toggle",
        },

        showCastBar = {
            name = "Cast Bar",
            variable = "showCastBar",
            variableKey = "showCastBar",
            tooltip = "Show a standalone cast bar that replaces Blizzard's default.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "CastBar.Toggle",
        },

        showPrimaryPower = {
            name = "Primary Power Bar",
            variable = "showPrimaryPower",
            variableKey = "showPrimaryPower",
            tooltip = "Show the primary power bar (mana, rage, energy, etc.).",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Resources.TogglePrimary",
        },

        showSecondaryPower = {
            name = "Secondary Power",
            variable = "showSecondaryPower",
            variableKey = "showSecondaryPower",
            tooltip = "Show secondary class resources (combo points, holy power, runes, etc.).",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Resources.ToggleSecondary",
        },

        resourceFader = {
            name = "Resource Fader",
            variable = "resourceFader",
            variableKey = "resourceFader",
            tooltip = "Fade power bars when not in combat or on mouseover.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Resources.ToggleFader",
        },

        showMirrorBar = {
            name = "Mirror Bar",
            variable = "showMirrorBar",
            variableKey = "showMirrorBar",
            tooltip = "Show mirror timer bars (breath, fatigue, feign death) below the player frame.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "MirrorBar.Toggle",
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

        showDataBar = {
            name = "Data Bar",
            variable = "showDataBar",
            variableKey = "showDataBar",
            tooltip = "Show the data bar panel across the bottom of the screen.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "DataBar.Toggle",
        },

        actionBarFader = {
            name = "Action Bar Fader",
            variable = "actionBarFader",
            variableKey = "actionBarFader",
            tooltip = "Fade action bars out of combat. Mouseover reveals them.",
            defaultValue = true,
            type = "toggle",
            realtime = true,
            callback = "Faders.ToggleActionBarFaderSilent",
        },
    },
}

-- Simple dessert-themed color string for "DessertUI"
ns.Constants.DessertUITitle = "|cffffffffDessert|cffdc143cUI|r"

-- Secondary resource spec mapping (outside main table for readability)
-- Keys are specIDs. Values describe what secondary resource to display.
-- powerType: Enum.PowerType constant to query
-- colorKey: key into secondaryColors table
-- displayType: "pips" (discrete points), "bars" (individual CD bars), "bar" (continuous)
ns.Constants.cooldownManager.specResources = {
    -- Death Knight: Runes (all specs)
    [250] = { powerType = Enum.PowerType.Runes, colorKey = "RUNES_BLOOD",  displayType = "bars", max = 6 },  -- Blood
    [251] = { powerType = Enum.PowerType.Runes, colorKey = "RUNES_FROST",  displayType = "bars", max = 6 },  -- Frost
    [252] = { powerType = Enum.PowerType.Runes, colorKey = "RUNES_UNHOLY", displayType = "bars", max = 6 },  -- Unholy

    -- Druid: Combo Points (Feral only, form-dependent)
    [103] = { powerType = Enum.PowerType.ComboPoints, colorKey = "COMBO_POINTS", displayType = "pips", max = 5, formRequired = 1 }, -- Feral

    -- Evoker: Essence (all specs)
    [1467] = { powerType = Enum.PowerType.Essence, colorKey = "ESSENCE", displayType = "pips" }, -- Devastation
    [1468] = { powerType = Enum.PowerType.Essence, colorKey = "ESSENCE", displayType = "pips" }, -- Preservation
    [1473] = { powerType = Enum.PowerType.Essence, colorKey = "ESSENCE", displayType = "pips" }, -- Augmentation

    -- Mage: Arcane Charges (Arcane only)
    [62] = { powerType = Enum.PowerType.ArcaneCharges, colorKey = "ARCANE_CHARGES", displayType = "pips", max = 4 },

    -- Monk: Chi (Windwalker), Stagger (Brewmaster)
    [269] = { powerType = Enum.PowerType.Chi, colorKey = "CHI", displayType = "pips" },              -- Windwalker
    [268] = { powerType = "STAGGER", colorKey = "STAGGER_LIGHT", displayType = "bar" },              -- Brewmaster

    -- Paladin: Holy Power (all specs)
    [65]  = { powerType = Enum.PowerType.HolyPower, colorKey = "HOLY_POWER", displayType = "pips" }, -- Holy
    [66]  = { powerType = Enum.PowerType.HolyPower, colorKey = "HOLY_POWER", displayType = "pips" }, -- Protection
    [70]  = { powerType = Enum.PowerType.HolyPower, colorKey = "HOLY_POWER", displayType = "pips" }, -- Retribution

    -- Rogue: Combo Points (all specs)
    [259] = { powerType = Enum.PowerType.ComboPoints, colorKey = "COMBO_POINTS", displayType = "pips" }, -- Assassination
    [260] = { powerType = Enum.PowerType.ComboPoints, colorKey = "COMBO_POINTS", displayType = "pips" }, -- Outlaw
    [261] = { powerType = Enum.PowerType.ComboPoints, colorKey = "COMBO_POINTS", displayType = "pips" }, -- Subtlety

    -- Shaman: Maelstrom (Enhancement only — tracked via aura stacks)
    [263] = { powerType = "MAELSTROM_WEAPON", colorKey = "MAELSTROM", displayType = "pips", max = 10 },

    -- Warlock: Soul Shards (all specs)
    [265] = { powerType = Enum.PowerType.SoulShards, colorKey = "SOUL_SHARDS", displayType = "pips", max = 5 },  -- Affliction
    [266] = { powerType = Enum.PowerType.SoulShards, colorKey = "SOUL_SHARDS", displayType = "pips", max = 5 },  -- Demonology
    [267] = { powerType = Enum.PowerType.SoulShards, colorKey = "SOUL_SHARDS", displayType = "bar",  max = 5 },  -- Destruction (continuous)
}
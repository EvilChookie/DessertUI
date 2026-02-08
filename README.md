# DessertUI

A custom World of Warcraft addon providing unit frames and UI enhancements.

## Features

- Custom unit frames powered by oUF
- Frame fading system (mouseover and combat-aware)
- Masque skinning support for action bars, buffs/debuffs, and cooldown manager
- Customizable settings via `/dui settings`

## Commands

- `/dui` or `/dessertui` - Access addon commands
- `/dui settings` - Open the settings panel

## Attribution

DessertUI incorporates ideas and techniques from the following projects:

### [rLib](https://github.com/zorker/rothui) by zork
- Frame fader animation system
- Event callback registration pattern

### [Masque Skinner: Blizz Buffs](https://github.com/ascott18/Masque-Skinner-Blizz-Buffs) by Cybeloras of Aerie Peak
- Aura wrapper frame technique for skinning modern WoW's rectangular buff/debuff frames

### [MasqueBlizzBars](https://github.com/SimGuy2014/MasqueBlizzBars) by SimGuy
- Cooldown viewer skinning approach
- Action bar region mapping patterns

## Libraries

- [oUF](https://github.com/oUF-wow/oUF) - Unit frame framework
- [LibStub](hhttps://github.com/lua-wow/LibStub) - Library versioning
- [LibDispel](https://github.com/lua-wow/LibDispel) - Dispel type detection

## License

MIT License - see [LICENSE](LICENSE) for details.

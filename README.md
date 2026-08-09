[![Latest Release](https://img.shields.io/github/v/release/nivthefox/wow-nivui)](https://github.com/nivthefox/wow-nivui/releases/latest)

# NivUI

A World of Warcraft UI overhaul addon. Fixing all the shit Blizzard broke in 12.0.

## Philosophy

Display modules are opt-in. NivUI loads its shared infrastructure at startup, but unit frames and resource bars stay disabled until you explicitly enable them. The configuration panel is created when you first open `/nivui` and reused afterward.

## Features

### Unit Frames
- Player, Target, Target-of-Target, Focus, Pet
- Party, Raid, Boss, and Arena frames
- Visual style designer with live preview
- Style management: create, clone, rename, and assign styles
- Edit Mode integration for positioning

### Resource Bars
- Arcane Charges Bar
- Chi Bar
- Combo Points Bar
- Essence Bar
- Holy Power Bar
- Rune Bar
- Soul Shards Bar
- Stagger Bar

## Installation

Copy the `NivUI` folder to your World of Warcraft AddOns directory:

```
World of Warcraft/_retail_/Interface/AddOns/NivUI
```

## Usage

Type `/nivui` to open the configuration panel. From there you can enable modules and customize their appearance.

Blizzard Edit Mode owns the screen position of NivUI unit frames and class bars. It also provides contextual layout and visibility settings for selected unit frames. The `/nivui` panel owns module enablement, class-bar size and appearance, reusable unit-frame styles, assignments, filters, overlays, and profiles.

## License

NivUI is released under the MIT License.

## Contact

Report bugs and request features by creating a [new issue](https://github.com/nivthefox/wow-nivui/issues/new).

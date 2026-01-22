[![Release Status](https://github.com/nivthefox/wow-nivui/workflows/release/badge.svg)](https://github.com/nivthefox/wow-nivui/actions)
[![Latest Release](https://img.shields.io/github/v/release/nivthefox/wow-nivui)](https://github.com/nivthefox/wow-nivui/releases/latest)

# NivUI

A World of Warcraft UI overhaul addon. Fixing all the shit Blizzard broke in 12.0.

## Philosophy

Everything is opt-in. On first load, NivUI registers only the `/nivui` command. Every module stays disabled until you explicitly enable it. No assumptions, no wasted resources.

## Features

### Unit Frames
- Player, Target, Target-of-Target, Focus, Pet
- Party and Raid frames
- Boss frames
- Visual style designer with live preview
- Style management: create, clone, rename, and assign styles
- Edit Mode integration for positioning

### Resource Bars
- **Stagger Bar** - Brewmaster Monk stagger visualization with DPS and percent display
- **Chi Bar** - Windwalker Monk chi resource display

## Installation

Copy the `NivUI` folder to your World of Warcraft AddOns directory:

```
World of Warcraft/_retail_/Interface/AddOns/NivUI
```

## Usage

Type `/nivui` to open the configuration panel. From there you can enable modules and customize their appearance.

## License

NivUI is released under the MIT License.

## Contact

Report bugs and request features by creating a [new issue](https://github.com/nivthefox/wow-nivui/issues/new).

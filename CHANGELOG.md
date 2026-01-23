# Changelog

All notable changes to NivUI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Target frame now shows action targets (soft targets) when no hard target exists
- Custom visibility conditions ("Show States") for each frame type, configurable via Edit Mode
- Sort order options for party and raid frames: by role, by group, or by group with role sorting
- Power bar visibility option in frame styles: show for everyone, healers only, or just yourself

### Changed

- Group frame settings (party, raid, boss, arena) now appear in an Edit Mode popup when the frame is selected, matching Blizzard's native UI style
- All frame types now have an Edit Mode settings dialog for visibility customization

### Fixed

- Editing styles no longer creates duplicate frames on screen

## [1.1.3](https://github.com/nivthefox/wow-nivui/releases/tag/v1.1.3) - 2026-01-22

### Added

- Raid marker, leader icon, and role icon widgets now update dynamically
- Role icon widget for displaying tank/healer/dps assignments

### Fixed

- Style designer tab now loads correctly
- Raid markers now display correctly in preview and on live frames
- Unit frames now show and hide properly during combat (focus, target, pet, etc.)

## [1.1.2](https://github.com/nivthefox/wow-nivui/releases/tag/v1.1.2) - 2026-01-22

### Added

- Arena enemy unit frames with the same customization options as boss frames

### Changed

- Configuration tabs now only appear for enabled frame types
- Tabs wrap to multiple rows when the window is too narrow
- Edit Mode overlays now match Blizzard's native visual style
- Frames snap to screen edges, center, grid lines, and other frames when dragging in Edit Mode

### Fixed

- Enemy target names now display correctly with Midnight's secret value system
- Party frames properly hide in raid groups
- Target frame stays visible during zone transitions
- Unit frames now reliably hide when units disappear (boss death, zone changes, encounters ending)

## [1.1.1](https://github.com/nivthefox/wow-nivui/releases/tag/v1.1.1) - 2026-01-21

### Fixed

- Castbars now work correctly with Midnight's secret value system

## [1.1.0](https://github.com/nivthefox/wow-nivui/releases/tag/v1.1.0) - 2026-01-21

### Added

- Custom unit frames for Player, Target, Pet, Focus, Party, Raid, and Boss
- Visual style designer for previewing and configuring widget styles
- Style management: create, clone, rename, and assign styles to frame types
- Chi bar for Windwalker Monk
- Edit Mode integration for repositioning custom frames

## [1.0.1](https://github.com/nivthefox/wow-nivui/releases/tag/v1.0.1) - 2026-01-21

### Changed

- Modernized configuration UI layout

### Fixed

- SharedMedia selections now persist correctly between sessions

## [1.0.0](https://github.com/nivthefox/wow-nivui/releases/tag/v1.0.0) - 2026-01-20

### Added

- Brewmaster Monk stagger bar with stagger amount, DPS, and percent display
- Configuration UI for bar appearance, colors, fonts, and textures
- Drag-to-move and drag-to-resize when unlocked

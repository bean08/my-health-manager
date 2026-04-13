# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project uses Semantic Versioning for releases.

## [0.0.2] - 2026-04-13

### Added
- Chinese README for the open-source project
- Presentation suppression for reminder popups when the frontmost app matches configured meeting or screen-sharing keywords
- Live countdown updates inside the menu bar menu for the selected reminder

### Changed
- Refined the reminder popup with lighter visuals, clearer border, smaller buttons, and transparent glass styling
- Made the reminder popup auto-size to its rendered content instead of using a fixed scrolling area
- Reworked the reminder popup content to native SwiftUI rendering for faster display when alerts fire
- Improved left sidebar module switching hit areas so "全局设置" can be selected reliably

## [0.0.1] - 2026-04-13

### Added
- First public release of My Health Manager
- Multi-reminder management with independent schedules, snooze times, and content
- Markdown reminder content with live preview and image insertion
- Per-reminder sound selection with preview playback
- Global settings page for software-level configuration
- Configurable external `settings.json` storage path
- Menu bar quick actions for a selected reminder

### Changed
- Simplified the menu bar item to icon-only display and moved runtime details into the menu
- Reworked the main window into a modular sidebar plus reminder editor layout
- Updated the app icon to better represent a general health assistant

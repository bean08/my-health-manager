# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project uses Semantic Versioning for releases.

## [0.2.0] - 2026-04-13

### Added
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

## [0.1.0] - 2026-04-13

### Added
- Native macOS health assistant focused on neck-care reminders
- Menu bar controls for opening the main window and managing reminder sessions
- Custom reminder message shown in a floating alert card
- Generated app icon integrated into the packaging flow

### Changed
- Main window now hides back to the menu bar so the app can stay resident in the status bar

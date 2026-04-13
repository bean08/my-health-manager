# My Health Manager

License: [Apache-2.0](LICENSE)

`My Health Manager` is a native macOS health assistant for lightweight recurring wellness prompts. It runs from the macOS menu bar, keeps reminder data in a user-editable JSON file, and supports multiple custom reminders with independent schedules and content.

## Features

- Native macOS app built with SwiftUI and AppKit
- Menu bar app that keeps running when the main window is closed
- Main window with separate modules for reminders and global settings
- Multiple reminders, each with its own title, interval, snooze time, sound, and content
- Markdown reminder content with live preview and image insertion
- Floating alert card shown at the top-right corner
- Selectable per-reminder sounds with preview
- Menu bar quick controls bound to a chosen reminder
- External `settings.json` storage with configurable path
- Universal macOS packaging script for Apple Silicon and Intel

## Requirements

- macOS 13.0 or later
- Xcode / Swift toolchain with Swift 5.9+

## Development

```bash
cd my-health-manager
swift run MyHealthManager
```

## Packaging

```bash
cd my-health-manager
./scripts/package-macos.sh
```

Outputs:
- `dist/MyHealthManager.app`
- `dist/MyHealthManager.dmg`

The packaging script builds both `arm64` and `x86_64` release binaries, merges them into a universal app bundle, and embeds the generated app icon.

## Storage

Default storage file:

- `~/Documents/my-health-manager/settings.json`

The storage path can be changed in `全局设置`. Enter a full path to `settings.json`; `~` is supported.

Stored reminder fields:

- `title`
- `intervalMinutes`
- `snoozeMinutes`
- `soundEnabled`
- `soundName`
- `message`

## Release

- Current version: `0.0.1`
- Recommended Git tag: `0.0.1`
- Latest changes in `0.0.1`:
  - Added the first open-source release of My Health Manager for macOS
  - Added multi-reminder management with independent scheduling and content
  - Added Markdown content, image insertion, and per-reminder sounds
  - Added external `settings.json` storage with configurable path
  - Added global settings and menu bar quick actions
- Release notes: [CHANGELOG.md](CHANGELOG.md)

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).

# LaunchAgent Manager

A native macOS menu bar app to manage your launch agents in one place.

## Features

- **Menu bar dropdown** with agents grouped by project
- **Status indicators**: green (running), yellow (loaded/stopped), gray (not loaded), orange (error)
- **Expandable groups** with running/total counts (e.g., `2/5`)
- **Quick actions**: Load/Unload per agent
- **Log viewer**: View last 50 lines of stdout/stderr
- **Search**: Filter agents by name
- **Filter toggle**: Show only your agents vs all (including system agents)
- **Auto-refresh**: Configurable polling interval (default 5s)

## Requirements

- macOS 13.0+
- Swift 5.9+

## Installation

```bash
git clone https://github.com/DSado88/LaunchAgentManager.git
cd LaunchAgentManager
swift build -c release
```

The built app will be at `.build/release/LaunchAgentManager`.

## Usage

```bash
swift run LaunchAgentManager
```

The app appears in your menu bar with a gear icon. Click to see your launch agents.

### Project Grouping

Agents are automatically grouped by label prefix:

| Prefix | Group |
|--------|-------|
| `com.apple.*` | Apple |
| `homebrew.*` | Homebrew |
| `com.adobe.*` | Adobe |
| `com.google.*` | Google |
| Others | Extracted from label |

Custom prefixes can be configured in Settings.

## Development

### Run Tests

```bash
swift test
```

84 tests covering:
- `AgentStatus` - Status parsing, colors, display text
- `LaunchAgent` - Model and schedule types
- `ProjectGrouper` - Prefix mapping and grouping
- `PlistParser` - Plist parsing and directory scanning
- `LaunchctlService` - Command building and status parsing

### Project Structure

```
Sources/LaunchAgentManager/
├── App/
│   └── LaunchAgentManagerApp.swift    # @main with MenuBarExtra
├── Models/
│   ├── AgentStatus.swift              # Status enum with colors
│   ├── LaunchAgent.swift              # Core model + ScheduleType
│   └── ProjectGroup.swift             # Grouping logic
├── Services/
│   ├── LaunchAgentService.swift       # Main orchestrator
│   ├── LaunchctlService.swift         # launchctl commands (actor)
│   ├── PlistParser.swift              # PropertyListSerialization
│   └── StatusPoller.swift             # Timer-based refresh
└── Views/
    ├── MenuBarView.swift              # Main dropdown UI
    ├── AgentRowView.swift             # Single agent row
    ├── AgentDetailView.swift          # Detail sheet with logs
    └── SettingsView.swift             # Preferences
```

## License

MIT

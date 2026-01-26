# Oni Blaster - Bean Throwing Battle

鬼退治！豆まきバトル - 10秒間で鬼に豆を投げまくれ！

![Roblox](https://img.shields.io/badge/Platform-Roblox-red)
![Web](https://img.shields.io/badge/Platform-Web-green)
![Lua](https://img.shields.io/badge/Language-Lua-blue)
![Rojo](https://img.shields.io/badge/Build-Rojo-orange)

## Play Online

**[Play Now on GitHub Pages](https://rsasaki0109.github.io/throw_beans_at_the_oni/)**

## Overview

A Japanese Setsubun festival mini-game for Roblox. Throw beans at the Oni in 10 seconds and compete for the highest score!

| Item | Description |
|------|-------------|
| Genre | Casual / Clicker / Arcade |
| Play Time | ~15 seconds per round |
| Platform | PC / Mobile |

## Features

- 10-second fast-paced gameplay
- PC: Mouse click / Space key
- Mobile: Tap to throw, hold for continuous fire
- Auto-restart after result screen
- Score popup and hit effects

## Project Structure

```
throw_beans_at_the_oni/
├── index.html              # Web version (GitHub Pages)
├── game.js                 # Web game logic
├── default.project.json    # Rojo configuration
├── src/
│   ├── client/             # Client scripts
│   │   └── GameClient.client.lua
│   ├── gui/                # UI components
│   │   ├── GameGui.lua
│   │   └── GuiInit.client.lua
│   ├── server/             # Server scripts
│   │   └── GameManager.server.lua
│   └── shared/             # Shared modules
│       ├── GameConfig.lua
│       ├── ModelFactory.lua
│       └── RemoteEvents.lua
├── plan.md                 # Design document
└── todo.md                 # Development roadmap
```

## Setup

### Prerequisites

- [Rojo](https://rojo.space/) v7.x
- Roblox Studio (Windows/Mac)

### Installation

```bash
# Install Rojo via Cargo
cargo install rojo

# Clone repository
git clone https://github.com/rsasaki0109/throw_beans_at_the_oni.git
cd throw_beans_at_the_oni
```

### Build

```bash
# Generate .rbxlx file
rojo build default.project.json --output OniBlaster.rbxlx
```

Then open `OniBlaster.rbxlx` in Roblox Studio.

### Live Sync (Development)

```bash
# Start Rojo server
rojo serve
```

In Roblox Studio, connect via the Rojo plugin.

## Controls

| Action | PC | Mobile |
|--------|-----|--------|
| Aim | Mouse | Touch position |
| Throw | Left Click / Space | Tap |
| Rapid Fire | Hold | Hold |

## Scoring

| Target | Points |
|--------|--------|
| Normal Oni (Blue) | 10 |
| Fast Oni (Red) | 30 (v2) |
| Gold Oni | 100 (v2) |

## License

MIT

## Author

[@rsasaki0109](https://github.com/rsasaki0109)

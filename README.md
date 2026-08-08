# Marble Game 3

A multiplayer survival and crafting game built with Godot 4.7 and C#/.NET 8.0.

## Overview

Marble Game 3 is a multiplayer survival game that combines resource gathering, crafting, and unique turn-based logic with a "warp speed" mechanic. Players can explore a 3D world, interact with objects like trees and stones, and survive against monsters and environmental challenges.

### Key Features

- **Multiplayer**: Integrated with Steamworks for lobby management and P2P networking. Fallback to ENet for non-Steam environments.
- **Survival Mechanics**: Includes health, hunger, and aging systems.
- **Resource Gathering**: Chop trees for logs, sticks, and apples; mine stones; gather items.
- **Warp Speed**: A unique mechanic that affects game time and interaction.
- **Persistence**: Game state is saved using a SQLite database.
- **Testing**: Robust test suite using GdUnit4.

## Prerequisites

- [Godot 4.7](https://godotengine.org/) (with .NET support)
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Steamworks SDK](https://partner.steamgames.com/) (optional for development, required for Steam features)
- [Jolt Physics](https://github.com/godot-jolt/godot-jolt) (Godot plugin)

### Installing Godot via Scoop (Windows)

```powershell
scoop bucket add extras
scoop install godot-dotnet
```

## Setup

1.  **Godot Editor**: Ensure Godot export templates are downloaded (**Editor > Manage Export Templates**).
2.  **Steam Integration**:
    - Download and install the [Steamworks SDK](https://partner.steamgames.com/).
    - Set the `STEAMCMD` environment variable to the path of the Steam builder executable, e.g.:
      ```bash
      export STEAMCMD="C:/Users/<user>/steamworks_sdk/sdk/tools/ContentBuilder/builder/steamcmd.exe"
      ```
3.  **Environment Variables**:
    - `GODOT_BIN`: Path to your Godot executable (e.g., `C:\Path\To\godot-dotnet.exe`).

## Running the Game

### From Godot Editor

1.  Open the project in Godot.
2.  Press **F5** (or the Play button) to start the game.
3.  The main scene is `res://src/game/game.tscn`.
4.  Use the **Start Server** button to host a lobby. A server instance is simply a game client that hosts the session.

### Running from Command Line

To run the game (or multiple instances for testing) from the command line:

```powershell
& $env:GODOT_BIN --path .
```

## Testing

The project uses [GdUnit4](https://github.com/Mike-Exner/gdUnit4) for testing.

### Running Tests via CLI

Use the provided script to run tests:

```bash
./addons/gdUnit4/runtest.sh --godot_binary "path/to/godot"
```

To run tests for a specific directory:

```bash
./addons/gdUnit4/runtest.sh --godot_binary "path/to/godot" -a res://src/axe
```

## Building and Deploying

The project includes a build script `build/build.sh` (requires a bash environment like Git Bash).

```bash
./build/build.sh
```

This script will:
1. Run automated tests.
2. Export the Godot project for all platforms (Windows, Linux, macOS).
3. Deploy the build to Steam (if configured).

## Project Structure

- `src/`: Core game logic and assets.
    - `src/character/`: Character movement and interaction.
    - `src/server/`: Server-side logic and persistence.
    - `src/client/`: Client-side UI and networking.
    - `src/world/`: World generation and environment.
    - `src/axe/`, `src/tree/`, `src/stone/`, etc.: Specific game entities.
- `addons/`: Godot plugins (GdUnit4, Godot-SQLite, GodotSteam).
- `build/`: Build and deployment scripts.

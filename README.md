# Marble Game 3

A multiplayer game built with Godot 4.7 and C#/.NET 8.0, featuring Steam integration.

## Prerequisites

- [Godot 4.7](https://godotengine.org/) with .NET support
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)

### Installing Godot via Scoop (Windows)

```
scoop bucket add extras
scoop install godot-dotnet
```

## Building and Deploying

### Setup

1. Make sure the Godot export templates are downloaded (Editor > Manage Export Templates)
2. Download and install the [Steamworks SDK](https://partner.steamgames.com/)
3. Set the `STEAMCMD` environment variable to the path of the Steam builder executable, e.g.:
   ```
   export STEAMCMD="C:/Users/<user>/steamworks_sdk/sdk/tools/ContentBuilder/builder/steamcmd.exe"
   ```

### Running

Use a bash terminal (Git Bash or similar) and run:

```
./build.sh
```

This will:
1. Export the Godot project for all platforms (Windows, Linux, macOS)
2. Deploy the build to Steam

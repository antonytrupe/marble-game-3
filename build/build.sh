#!/bin/bash

# pwd

# Get the path to the script itself, handling various execution methods and symlinks
SCRIPT_PATH=$(readlink -f "$0")

# Extract the directory name from that absolute path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Change to the script's directory (optional, but useful if your script needs local access)
cd "$SCRIPT_DIR"

##################
EXPORT_NAME="Windows Desktop"

# Make sure the directory exists (mkdir -p works in bash/mingw)
mkdir -p ./godot/exports/win-64

OUTPUT_PATH=$(realpath "./godot/exports/win-64/marblegame.exe")

echo "Starting Godot Windows export..."

# Execute the command using the environment variable
godot-mono --path ../ --headless --export-release "$EXPORT_NAME" "$OUTPUT_PATH"

# Immediately check the exit status stored in $?
if [ $? -eq 0 ]; then
    echo "✅ Godot Windows build SUCCEEDED!"
    # Continue with deployment steps (e.g., upload to SteamCMD)
else
    echo "❌ Godot Windows build FAILED!"
    # Stop the script or handle the error
    exit 1
fi

echo "Godot Windows Build complete."
##################

##################
EXPORT_NAME="Linux"

# Make sure the directory exists (mkdir -p works in bash/mingw)
mkdir -p ./godot/exports/linux-x64

OUTPUT_PATH=$(realpath "./godot/exports/linux-x64/marblegame.x86_64")

echo "Starting Godot Linux export..."

# Execute the command using the environment variable
godot-mono --path ../ --headless --export-release "$EXPORT_NAME" "$OUTPUT_PATH"

# Immediately check the exit status stored in $?
if [ $? -eq 0 ]; then
    echo "✅ Godot Linux build SUCCEEDED!"
    # Continue with deployment steps (e.g., upload to SteamCMD)
else
    echo "❌ Godot Linux build FAILED!"
    # Stop the script or handle the error
    exit 1
fi

echo "Godot Linux Build complete."
##################

echo "Starting Steam build..."

APP_VDF=$(realpath "./steam/app_build_4041750.vdf")

echo "Using Steam app build VDF at: $APP_VDF"
pwd
ls ${APP_VDF}

echo "$STEAMCMD" +login tynoan +run_app_build "$APP_VDF" +quit
"$STEAMCMD" +login tynoan +run_app_build "$APP_VDF" +quit

# Immediately check the exit status stored in $?
if [ $? -eq 0 ]; then
    echo "✅ Steam build SUCCEEDED!"
    # Continue with deployment steps
else
    echo "❌ Steam build FAILED!"
    # Stop the script or handle the error
    exit 1
fi

echo "Steam build complete."
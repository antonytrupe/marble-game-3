#!/bin/bash

pwd

# Get the path to the script itself, handling various execution methods and symlinks
SCRIPT_PATH=$(readlink -f "$0")

# Extract the directory name from that absolute path
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Change to the script's directory (optional, but useful if your script needs local access)
cd "$SCRIPT_DIR"

pwd

# This script assumes you have set the environment variable GODOT_PATH in your system
# Environment variables on Windows are accessed via $VAR_NAME in bash/git bash
EXPORT_NAME="Windows Desktop"

# Make sure the directory exists (mkdir -p works in bash/mingw)
mkdir -p ./godot/exports/win-64

OUTPUT_PATH=$(realpath "./godot/exports/win-64/marble-game.exe")
echo "Output path: $OUTPUT_PATH"

echo "Starting Godot export..."

# echo godot-mono --headless --export-release "$EXPORT_NAME" "$OUTPUT_PATH"


# Execute the command using the environment variable
godot-mono --path ../ --headless --export-release "$EXPORT_NAME" "$OUTPUT_PATH"

pwd

# Immediately check the exit status stored in $?
if [ $? -eq 0 ]; then
    echo "✅ Godot build SUCCEEDED!"
    # Continue with deployment steps (e.g., upload to SteamCMD)
else
    echo "❌ Godot build FAILED!"
    # Stop the script or handle the error
    exit 1
fi

echo "Godot Build complete."

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
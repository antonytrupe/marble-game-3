#!/bin/bash

# This script assumes you have set the environment variable GODOT_PATH in your system
# Environment variables on Windows are accessed via $VAR_NAME in bash/git bash
GODOT_EXE="$GODOT4"
EXPORT_NAME="Windows Desktop"
OUTPUT_PATH="./exports/win-64/my_game.exe"

# Make sure the directory exists (mkdir -p works in bash/mingw)
mkdir -p ./exports/win-64

echo "Starting Godot export..."

# Execute the command using the environment variable
"$GODOT_EXE" --headless --export-release "$EXPORT_NAME" "$OUTPUT_PATH"

echo "Build complete."

echo "Starting Steam build..."

APP_VDF=$(realpath "app_build_4041750.vdf")

"$STEAMCMD" +login tynoan +run_app_build "$APP_VDF" +quit

echo "Steam build complete."
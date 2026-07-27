#!/bin/bash

# Setup environment and directories
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
cd "$SCRIPT_DIR"

# Global settings
# scoop install godot-mono
# scoop update godot-mono
GODOT_BIN="godot-mono"

# Generic Godot build function
# Usage: build_godot "Export Name" "directory_path" "binary_name"
build_godot() {
    local EXPORT_NAME=$1
    local EXPORT_DIR=$2
    local BINARY_NAME=$3
    
    mkdir -p "$EXPORT_DIR"
    local OUTPUT_PATH=$(realpath "$EXPORT_DIR/$BINARY_NAME")

    echo "------------------------------------------------"
    echo "🚀 Starting Godot $EXPORT_NAME export..."
    
    # Execute Godot export command
    $GODOT_BIN --path ../ --quiet --headless --export-release "$EXPORT_NAME" "$OUTPUT_PATH"

    if [ $? -eq 0 ]; then
        echo "✅ Godot $EXPORT_NAME build SUCCEEDED!"
    else
        echo "❌ Godot $EXPORT_NAME build FAILED!"
        exit 1
    fi
}

# Steam specific build function
build_steam() {
    echo "------------------------------------------------"
    echo "⚙️ Running pre-build scripts..."
    ./scripts/pre-build.sh

    echo "📦 Starting Steam build..."
    local APP_VDF=$(realpath "./steam/playtest_app.vdf")

    # STEAMCMD must be defined in your environment
    "$STEAMCMD" +login marble_game_developer +run_app_build "$APP_VDF" +quit

    if [ $? -eq 0 ]; then
        echo "✅ Steam build SUCCEEDED!"
    else
        echo "❌ Steam build FAILED!"
        exit 1
    fi
}

# --- MAIN EXECUTION ---

# Build each platform
build_godot "Windows Desktop" "./godot/exports/win-64" "marblegame.exe"
build_godot "Linux" "./godot/exports/linux-x64" "marblegame.x86_64"
build_godot "macOS" "./godot/exports/macOS" "marblegame.app"

# Finalize with Steam
build_steam

echo "------------------------------------------------"
echo "🎉 All builds completed successfully!"

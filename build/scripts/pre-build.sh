#!/bin/sh

#build/scripts/pre-build.sh 

VERSION_FILE="../build_number.txt"

echo "Running pre-build hook: Incrementing build number..."

# Check if the version file exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: $VERSION_FILE not found!"
    exit 1
fi

# Read the current version number
CURRENT_VERSION=$(cat "$VERSION_FILE")

# Increment the version number (using expr for simple arithmetic)
NEW_VERSION=$((CURRENT_VERSION + 1))

# Write the new version number back to the file
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "Build number incremented to $NEW_VERSION"

# CRITICAL STEP: Add the modified file back to the git staging area,
# otherwise the change won't be included in this commit.
git add "$VERSION_FILE"

exit 0 # Exit with 0 to allow the commit to proceed

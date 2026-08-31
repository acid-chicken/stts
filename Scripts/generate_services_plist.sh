#!/bin/sh

RESOURCES_PATH="$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"
SERVICES_PLIST="$RESOURCES_PATH/services.plist"

# Retrieve the list of services. Every service is now either JSON-driven (Resources/services.json)
# or a plain hand-written class here; nothing under stts/Services/ is machine-generated anymore
# (see Scripts/services_json_migration.md), so this only ever needs to scan real class names.
SERVICES=$(find "$SRCROOT/stts/Services" -name "*.swift" -not -path "*Super*" | awk -F/ '{ print $NF }' | sed s/.swift//g | sort | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g')

# Create the services plist file
echo "{}" > "$SERVICES_PLIST"

# Write the list of services into the plist file as an array
defaults write "$SERVICES_PLIST" "services" -array $SERVICES

# Remove all quarantine attributes as they block submissions to App Store
xattr -c "$SERVICES_PLIST"

#!/bin/sh
# Regenerates Resources/services.json from live provider APIs. See
# Scripts/generators/Sources/UpdateServicesJSON/main.swift for details.
set -e
cd "$(dirname "$0")/generators"
exec swift run UpdateServicesJSON "$@"

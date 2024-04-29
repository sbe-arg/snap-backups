#!/bin/bash

# Function to restore specified snaps
restore_snaps() {
    local source="$1"
    local app="$2"

    # Check if source file exists
    if [ ! -f "$source" ]; then
        echo "Error: Snapshot file '$source' not found."
        exit 1
    fi

    # Install and Stop
    snap install "$app" || { echo "Error: Failed to install snap '$app'." >&2; exit 1; }
    snap services "$app" | grep -Ew 'active' && snap stop "$app" || { echo "Error: Failed to stop snap $app." >&2; exit 1; }

    # Import snapshot
    snap import-snapshot "$source" || { echo "Error: Failed to import snapshot from '$source'." >&2; exit 1; }

    # Check if the snap is available
    if ! snap saved "$app" >/dev/null 2>&1; then
        echo "Error: Snap '$app' snapshot is not available."
        exit 1
    fi

    # Get the snapshot ID
    snapshot_id=$(snap saved "$app" | grep -oE '^[0-9]+' | sort -nr | head -n 1)

    # Restore the snapshot
    snap restore --id="$snapshot_id" --snap="$app" || { echo "Error: Failed to restore snapshot '$snapshot_id'." >&2; exit 1; }

    # Forget the snapshot
    snap forget --id="$snapshot_id" --snap="$app" || { echo "Error: Failed to forget snapshot '$snapshot_id'." >&2; exit 1; }

    echo "Snap '$app','$snapshot_id' restored successfully."
}

# Main function
main() {
    local app=""
    local source=""

    # Parse command-line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --app) app="$2"; shift ;;
            --source) source="$2"; shift ;;
            *) echo "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done

    # Validate arguments
    if [ -z "$app" ]; then
        echo "Error: No app specified."
        exit 1
    fi
    if [ -z "$source" ]; then
        echo "Error: No source specified."
        exit 1
    fi

    # Restore snaps
    restore_snaps "$source" "$app"
}

# Execute main function with provided arguments
main "$@"

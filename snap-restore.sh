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
    /usr/bin/snap install "$app" || { echo "Error: Failed to install snap '$app'." >&2; exit 1; }
    if /usr/bin/snap services "$app" | grep -Ew 'active'; then
        /usr/bin/snap stop "$app" || { echo "error: failed to stop snap $app." >&2; exit 1; }
    fi

    # Import snapshot
    /usr/bin/snap import-snapshot "$source" || { echo "error: failed to import snapshot from '$source'." >&2; exit 1; }

    # Check if the snap is available
    if ! /usr/bin/snap saved "$app" >/dev/null 2>&1; then
        echo "error: snap '$app' snapshot is not available."
        exit 1
    fi

    # Get the snapshot ID
    snapshot_id=$(snap saved "$app" | grep -oE '^[0-9]+' | sort -nr | head -n 1)

    # Restore the snapshot
    /usr/bin/snap restore "$snapshot_id" || { echo "error: failed to restore snapshot '$snapshot_id'." >&2; exit 1; }

    # Forget the snapshot
    /usr/bin/snap forget "$snapshot_id" || { echo "error: failed to forget snapshot '$snapshot_id'." >&2; exit 1; }

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

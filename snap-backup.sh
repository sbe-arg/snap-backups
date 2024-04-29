#!/bin/bash

# Function to backup specified snaps
backup_snaps() {
    local dest="$1"
    shift
    local apps=("$@")

    # Save specified snaps and copy snapshot files to the destination directory
    for app in "${apps[@]}"; do
        echo "Action: Stop, save and export snap $app"
        snap services "$app" | grep -Ew 'active' && snap stop "$app" || { echo "Error: Failed to stop snap $app." >&2; exit 1; }
        snap save "$app" || { echo "Error: Failed to save snap $app." >&2; exit 1; }
        snap services "$app" | grep -Ew 'inactive' && snap start "$app"  || { echo "Error: Failed to start snap $app." >&2; exit 1; }
        snapshot_id=$(snap saved "$app" | grep -oE '^[0-9]+' | sort -nr | head -n 1)
        date=$(date +"%Y-%m-%d")
        snap export-snapshot "$snapshot_id" "$dest/$snapshot_id-$app-$date" || { echo "Error: Failed to export snapshot $snapshot_id for $app in $dest/$snapshot_id-$app-$date" >&2; exit 1; }
        echo "Action: Forget $app:$snapshot_id"
        snap forget --id="$snapshot_id" --snap="$app" || { echo "Error: Failed to forget snapshot $snapshot_id for $app." >&2; exit 1; }
    done
}

# Main function
main() {
    local apps=()
    local dest=""

    # Parse command-line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --apps) IFS=',' read -ra apps <<< "$2"; shift ;;
            --dest) dest="$2"; shift ;;
            *) echo "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done

    # Validate arguments
    if [ ${#apps[@]} -eq 0 ]; then
        echo "Error: No apps specified."
        exit 1
    fi
    if [ ! -d "$dest" ]; then
        echo "Error: Invalid destination"
        exit 1
    fi

    # Backup snaps
    backup_snaps "$dest" "${apps[@]}"
    echo "Snaps backup run completed successfully!"
}

# Execute main function with provided arguments
main "$@"

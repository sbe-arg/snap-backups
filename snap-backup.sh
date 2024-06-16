#!/bin/bash

# Function to backup specified snaps
backup_snaps() {
    local dest="$1"
    shift
    local apps=("$@")

    # Save specified snaps and copy snapshot files to the destination directory
    for app in "${apps[@]}"; do
        echo "Action: Stop, save and export snap $app"
        if /usr/bin/snap services "$app" | grep -Ew 'active'; then
            /usr/bin/snap stop "$app" || { echo "error: failed to stop snap $app." >&2; exit 1; }
        fi
        /usr/bin/snap save "$app" || { echo "error: failed to save snap $app." >&2; exit 1; }
        if /usr/bin/snap services "$app" | grep -Ew 'inactive'; then
            /usr/bin/snap start "$app" || { echo "error: failed to start snap $app." >&2; exit 1; }
        fi
        snapshot_id=$(/usr/bin/snap saved "$app" | awk 'NR==2 {print $1}')
        date=$(date +"%Y-%m-%d-%H%M%S")
        /usr/bin/snap export-snapshot "$snapshot_id" "$dest/$snapshot_id-$app-$date" || { echo "error: failed to export snapshot $snapshot_id for $app in $dest/$snapshot_id-$app-$date" >&2; exit 1; }
        echo "Action: Forget $app:$snapshot_id"
        /usr/bin/snap forget "$snapshot_id" || { echo "error: failed to forget snapshot $snapshot_id for $app." >&2; exit 1; }
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
        echo "error: no apps specified."
        exit 1
    fi
    if [ ! -d "$dest" ]; then
        echo "error: invalid destination directory."
        exit 1
    fi

    # Backup snaps
    backup_snaps "$dest" "${apps[@]}"
    echo "Snaps backup run completed successfully!"
}

# Execute main function with provided arguments
main "$@"

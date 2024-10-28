#!/bin/bash

# Specify the target directory to prune
DIR="/backup/snaps"

# Configurable variables
MIN_FILES=5                  # Minimum number of files to keep probbaly matching twice the number of apps backed up
MAX_FILES=20                 # Maximum number of files to consider keeping if storage is available likely a multiplier of the minimum files
SIZE_LIMIT_GB=100            # Maximum total size in GB so there is always enough space for new backups

# Convert size limit to bytes for easier comparison
SIZE_LIMIT_BYTES=$((SIZE_LIMIT_GB * 1024 * 1024 * 1024))

echo "Directory: $DIR"
echo "Minimum files to keep: $MIN_FILES"
echo "Maximum files to keep if storage permits: $MAX_FILES"
echo "Size limit: ${SIZE_LIMIT_GB}GB"

# List files by modification time and store in an array
files=($(ls -t "$DIR"))

# Calculate the total size of all files
total_size=0
for file in "${files[@]}"; do
    file_size=$(stat -c%s "$DIR/$file")
    total_size=$((total_size + file_size))
done

echo "Total size of all files: $(echo "scale=2; $total_size / (1024*1024*1024)" | bc) GB"

# Decide the number of files to keep based on size limit
files_to_keep=$MAX_FILES
while (( total_size > SIZE_LIMIT_BYTES && files_to_keep > MIN_FILES )); do
    ((files_to_keep--))
    total_size=0
    for (( i=0; i<files_to_keep; i++ )); do
        file_size=$(stat -c%s "$DIR/${files[$i]}")
        total_size=$((total_size + file_size))
    done
done

echo "Keeping $files_to_keep files based on size limit and minimum requirements."

# Output files to be kept
echo "Files to keep:"
for (( i=0; i<files_to_keep; i++ )); do
    echo "  ${files[$i]}"
done

# Delete all other files
echo "Deleting the rest of the files:"
for (( i=files_to_keep; i<${#files[@]}; i++ )); do
    echo "  Deleting: ${files[$i]}"
    rm -- "$DIR/${files[$i]}"
done

echo "Cleanup complete."
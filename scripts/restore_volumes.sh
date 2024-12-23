#!/bin/bash

BACKUP_DIR=$1

echo "Starting volume restoration on VPS B..."

# Loop through each backup file and restore the volumes
for backup in ${BACKUP_DIR}/*.tar.gz; do
    volume=$(basename "$backup" .tar.gz)
    echo "Restoring volume: $volume"

    # Read the project and volume name metadata
    project_name=$(cat "$BACKUP_DIR/${volume}_project_name.txt")
    volume_name=$(cat "$BACKUP_DIR/${volume}_volume_name.txt")

    if [ -z "$project_name" ] || [ -z "$volume_name" ]; then
        echo "Warning: Could not determine project or volume name for volume $volume"
        continue
    fi

    # Create the volume with Compose-compatible labels
    docker volume create --name "$volume" \
        --label com.docker.compose.project="$project_name" \
        --label com.docker.compose.volume="$volume_name"

    # Restore the volume data from the backup
    docker run --rm -v "$volume":/data -v "$BACKUP_DIR":/backup alpine \
        tar -xzf "/backup/${volume}.tar.gz" -C /data
done

echo "All volumes restored with Compose-compatible labels!"

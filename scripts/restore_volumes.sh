#!/bin/bash

BACKUP_DIR=$1
COMPOSE_PROJECT_NAME=$2  # Adjust to your compose project name

echo "Starting volume restoration on VPS B..."

# Loop through each backup file and restore the volumes
for backup in ${BACKUP_DIR}/*.tar.gz; do
    volume=$(basename "$backup" .tar.gz)
    echo "Restoring volume: $volume"

    # Delete the existing volume if it already exists (without labels)
#    docker volume rm "$volume" 2>/dev/null || true

    # Create the volume with Compose-compatible labels
    docker volume create --name "$volume" \
        --label com.docker.compose.project="$COMPOSE_PROJECT_NAME" \
        --label com.docker.compose.volume="$volume"

    # Restore the volume data from the backup
    docker run --rm -v "$volume":/data -v "$BACKUP_DIR":/backup alpine \
        tar -xzf "/backup/${volume}.tar.gz" -C /data
done

echo "All volumes restored with Compose-compatible labels!"
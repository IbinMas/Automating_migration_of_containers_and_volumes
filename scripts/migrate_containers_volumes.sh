#!/bin/bash

# Retrieve parameters
VPS_B_USER=$1
VPS_B_HOST=$2
COMPOSE_DIR=$3
BACKUP_DIR=$4

# Transfer Compose Files
# echo "Transferring Compose files to VPS B..."
# rsync -avz $COMPOSE_DIR $VPS_B_USER@$VPS_B_HOST:$COMPOSE_DIR

# Backup Volumes
echo "Backing up Docker volumes..."
mkdir -p $BACKUP_DIR


# Loop through each volume to backup
# for volume in $(docker volume ls --format '{{.Name}}'); do
docker_volumes=("jenkins_home" "rocketchat_mongodb_data" "compose_files_web1_data" "compose_files_web2_data")
for volume in "${docker_volumes[@]}"; do
    echo "Backing up volume: $volume"

    # Inspect the volume to retrieve the project and volume labels
    volume_info=$(docker volume inspect "$volume")
    project_name=$(echo "$volume_info" | jq -r '.[0].Labels["com.docker.compose.project"]')
    volume_name=$(echo "$volume_info" | jq -r '.[0].Labels["com.docker.compose.volume"]')

    # Save project and volume name metadata
    echo "$project_name" > "$BACKUP_DIR/${volume}_project_name.txt"
    echo "$volume_name" > "$BACKUP_DIR/${volume}_volume_name.txt"

    # Backup the volume data
    docker run --rm -v "$volume:/data" -v "$BACKUP_DIR:/backup" alpine \
        tar -czf "/backup/${volume}.tar.gz" -C /data .
done

# Transfer Volume Backups
echo "Transferring volume backups to VPS B..."
rsync -avz $BACKUP_DIR/ $VPS_B_USER@$VPS_B_HOST:$BACKUP_DIR

echo "Migration preparation complete! Run restore scripts on VPS B."

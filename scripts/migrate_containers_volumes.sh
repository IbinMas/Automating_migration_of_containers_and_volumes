#!/bin/bash

# Retrieve parameters
VPS_B_USER=$1
VPS_B_HOST=$2
COMPOSE_DIR=$3
BACKUP_DIR=$4

# Transfer Compose Files
echo "Transferring Compose files to VPS B..."
rsync -avz $COMPOSE_DIR $VPS_B_USER@$VPS_B_HOST:$COMPOSE_DIR

# Backup Volumes
echo "Backing up Docker volumes..."
mkdir -p $BACKUP_DIR
docker_volumes=("compose_files_app2_data" "compose_files_app1_data" "compose_files_db_data" "compose_files_mongo_data" "compose_files_php_data" "compose_files_postgres_data" "compose_files_redis_data" "compose_files_web1_data" "compose_files_web2_data")

# for volume in $(docker volume ls --format '{{.Name}}'); do
for volume in "${docker_volumes[@]}"; do
    echo "Backing up volume: $volume"
    docker run --rm -v "$volume:/data" -v "$BACKUP_DIR:/backup" alpine \
        tar -czf "/backup/${volume}.tar.gz" -C /data .
done

# Transfer Volume Backups
echo "Transferring volume backups to VPS B..."
rsync -avz $BACKUP_DIR/ $VPS_B_USER@$VPS_B_HOST:$BACKUP_DIR

echo "Migration preparation complete! Run restore scripts on VPS B."

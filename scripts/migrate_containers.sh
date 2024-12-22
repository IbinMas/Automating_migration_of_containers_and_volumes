#!/bin/bash

# Configurations
VPS_B_USER="root"
VPS_B_HOST="10.1.1.100"
COMPOSE_DIR="../compose_files"
BACKUP_DIR="/tmp/docker_volume_backups"

# Transfer Compose Files
echo "Transferring Compose files to VPS B..."
rsync -avz $COMPOSE_DIR $VPS_B_USER@$VPS_B_HOST:/root/test-compose_files

# Backup Volumes
echo "Backing up Docker volumes..."
mkdir -p $BACKUP_DIR

for volume in $(docker volume ls --format '{{.Name}}'); do
    echo "Backing up volume: $volume"
    docker run --rm -v $volume:/data -v $BACKUP_DIR:/backup alpine \
        tar -czf /backup/${volume}.tar.gz -C /data .
done

# Transfer Volume Backups
echo "Transferring volume backups to VPS B..."
rsync -avz $BACKUP_DIR/ $VPS_B_USER@$VPS_B_HOST:/tmp/docker_volume_backups/

echo "Migration preparation complete! Run restore scripts on VPS B."


#!/bin/bash

# Retrieve parameters
VPS_B_USER=$1
VPS_B_HOST=$2
COMPOSE_DIR=$3
BACKUP_DIR=$4

# Transfer Compose Files
echo "Transferring Compose files to VPS B..."
rsync -avz $COMPOSE_DIR $VPS_B_USER@$VPS_B_HOST:/root/test-compose_files

# Backup Volumes
echo "Backing up Docker volumes..."
mkdir -p $BACKUP_DIR

for volume in $(docker volume ls --format '{{.Name}}'); do
    echo "Backing up volume: $volume"
    docker run --rm -v $volume:/data -v $BACKUP_DIR:/backup alpine \
        tar -czf /backup/${volume}.tar.gz -C /data .
done

# Transfer Volume Backups
echo "Transferring volume backups to VPS B..."
rsync -avz $BACKUP_DIR/ $VPS_B_USER@$VPS_B_HOST:/tmp/docker_volume_backups/

echo "Migration preparation complete! Run restore scripts on VPS B."

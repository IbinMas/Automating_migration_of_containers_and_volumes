   #!/bin/bash
   BACKUP_DIR=/tmp/docker_volume_backups
   mkdir -p $BACKUP_DIR

   for volume in $(docker volume ls --format '{{.Name}}'); do
       echo "Backing up volume: $volume"
       docker run --rm -v $volume:/data -v $BACKUP_DIR:/backup alpine \
           tar -czf /backup/${volume}.tar.gz -C /data .
   done

  echo "All volumes backed up in $BACKUP_DIR"
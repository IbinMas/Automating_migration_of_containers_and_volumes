   #!/bin/bash
   BACKUP_DIR=$1

   for backup in $BACKUP_DIR/*.tar.gz; do
       volume=$(basename $backup .tar.gz)
       echo "Restoring volume: $volume"
       docker volume create $volume
       docker run --rm -v $volume:/data -v $BACKUP_DIR:/backup alpine \
           tar -xzf /backup/${volume}.tar.gz -C /data
   done

   echo "All volumes restored!"
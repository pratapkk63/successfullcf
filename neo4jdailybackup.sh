#!/bin/bash
# neo4j_backup.sh [incremental|full]
# Requires the server to copy it's SSH key to the remote media server
# ssh-copy-id $REMOTE_USER@$REMOTE_HOST

# Input variables
BACKUP_TYPE=$1

# Script configuration
LOG_PATH="/var/log/neo4j/backup.log"
NEO4J_ADMIN_PATH="/usr/share/neo4j/bin/neo4j-admin"
DATE=$(date +"%Y-%m-%d")

# Backup configuration
BACKUP_DIR="/mnt/backup"
BACKUP_NAME="graph.db-backup"
REMOTE_HOST=""
REMOTE_USER="backup"
REMOTE_DIR="/mnt/backup/neo4j"

# Default BACKUP_TYPE is set to incremental
if [ -z $BACKUP_TYPE ]; then
    BACKUP_TYPE="incremental"
fi

# Remove previous full backup
if [ $BACKUP_TYPE == "full" ]; then
    rm -rf $BACKUP_DIR/$BACKUP_NAME >> $LOG_PATH
fi

# Check that the backup directory is available
if [ ! -d $BACKUP_DIR ]; then
    echo "$(date +"%y-%m-%d %H:%M:%S") ERROR: $BACKUP_DIR is not a directory. Exiting backup." >> $LOG_PATH
    exit 1
fi

# Execute the backup
echo "$(date +"%m.%d.%Y %H:%M:%S") DEBUG: Starting backup" >> $LOG_PATH
$NEO4J_ADMIN_PATH backup --backup-dir=$BACKUP_DIR --name=$BACKUP_NAME --fallback-to-full=true --check-consistency=false >> $LOG_PATH
if [ $? -ne 0 ]; then
    echo "$(date +"%y-%m-%d %H:%M:%S") ERROR: Backup failed - aborting" >> $LOG_PATH
    exit 1
fi

# Copy backup to the remote media server
echo "$(date +"%y-%m-%d %H:%M:%S") DEBUG: Copying data to backup server $REMOTE_HOST:$REMOTE_DIR/$BACKUP_NAME-$DATE" >> $LOG_PATH
scp -r $BACKUP_DIR/$BACKUP_NAME $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$BACKUP_NAME-$DATE
if [ $? -ne 0 ]; then
    echo "$(date +"%y-%m-%d %H:%M:%S") ERROR: Copy failed to $REMOTE_HOST:$REMOTE_DIR/$BACKUP_NAME-$DATE" >> $LOG_PATH
    exit 1
fi

echo "$(date +"%y-%m-%d %H:%M:%S") DEBUG: $BACKUP_TYPE backup finished successfully" >> $LOG_PATH

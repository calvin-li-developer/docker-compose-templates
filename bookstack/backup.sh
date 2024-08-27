#!/bin/bash
docker stop bookstack
docker stop bookstack-database
folder_path="$HOME/docker/bookstack"
backup_paths="database config docker-compose.yml README.md"
max_num_backups=20
target_dir="$HOME/docker/bookstack/backups"
zip_file="$target_dir/bookstack-$(date +'%Y-%m-%d_%I%M_%p').tar.gz"
tar -czf "$zip_file" -C "$folder_path" $backup_paths > /dev/null

echo "[INFO]: tar zip file location is $target_dir"

if [ "$(ls -1qA $target_dir | grep bookstack | wc -l)" -gt $max_num_backups ]; then
    # Get the oldest file in the directory
    oldest_file=$(ls -1t $target_dir | grep "bookstack-" | tail -1 | awk '{print $NF}')
    echo "[INFO]: Backup tar files in $target_dir exceeded $max_num_backups"
    echo "[INFO]: Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm $target_dir/$oldest_file
fi

docker start bookstack-database
docker start bookstack
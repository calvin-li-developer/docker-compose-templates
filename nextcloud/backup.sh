#!/bin/bash
docker stop nextcloud

folder_path="$HOME/docker/nextcloud/data/"
target_dir="$HOME/docker/nextcloud/backups"
max_num_backups=1
zip_file="$target_dir/nc-$(date +'%Y-%m-%d_%I%M_%p').tar.gz"
tar -czf "$zip_file" -C "$folder_path" . > /dev/null

echo "[INFO]: tar zip file location is $target_dir"

if [ "$(ls -1qA $target_dir | grep nc | wc -l)" -gt $max_num_backups ]; then
    # Get the oldest file in the directory
    oldest_file=$(ls -1t $target_dir | grep "nc-" | tail -1 | awk '{print $NF}')
    echo "[INFO]: Backup tar files in $target_dir exceeded $max_num_backups"
    echo "[INFO]: Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm $target_dir/$oldest_file
fi

docker start nextcloud
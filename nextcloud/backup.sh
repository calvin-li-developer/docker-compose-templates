#!/bin/bash
version=`docker inspect nextcloud -f '{{json .Config.Labels}}' | jq -r '.["org.opencontainers.image.version"]'`

echo "Nextcloud Version: $version"

echo "Stop Nextcloud docker ..." && docker stop nextcloud nextcloud-database > /dev/null

echo "Backup starting ..."

backup_paths="README.md docker-compose.yml cloudflared-config fail2ban-config .env data/$NEXTCLOUD_USER/files"
folder_path="$HOME/docker/nextcloud"
target_dir="$HOME/docker/nextcloud/backups"
max_num_backups=1
current_date=`date +'%Y-%m-%d_%I%M_%p'`

mkdir -p "$target_dir/${version%%-*}"
find $target_dir -mindepth 1 -maxdepth 1 -type d ! -name "${version%%-*}" -exec rm -rf {} +

zip_file="$target_dir/${version%%-*}/nc-$current_date.tar.gz"

echo "Backup compressed filename: $zip_file"
sudo tar -czf "$zip_file" -C "$folder_path" $backup_paths > /dev/null

if [ "$(ls -1qAR $target_dir | grep nc | wc -l)" -gt $max_num_backups ]; then
    # Get the oldest file in the directory
    oldest_file="$(ls -1tR $target_dir | grep nc | tail -1 | awk '{print $NF}')"
    echo "Backup tar files in $target_dir exceeded $max_num_backups"
    echo "Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm "$target_dir/${version%%-*}/$oldest_file"
fi

echo "Start Nextcloud docker ..." && docker start nextcloud nextcloud-database

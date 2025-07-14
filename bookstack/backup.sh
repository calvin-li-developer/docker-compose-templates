#!/bin/bash
version=`docker inspect bookstack -f '{{json .Config.Labels}}' | jq -r '.["org.opencontainers.image.version"]'`
image_tag=`docker inspect bookstack -f '{{ json .Config.Image }}' | jq -r . | cut -d ':' -f2-`
printf "Bookstack Version: ${version}\nImage Tag: $image_tag\n" | tee "$HOME/docker/bookstack/config/backup_metadata.txt"

echo "Stop Bookstack docker ..." && docker stop bookstack bookstack-database > /dev/null

echo "Backup starting ..."

backup_paths="database config docker-compose.yml README.md cloudflared-config fail2ban-config .env"
folder_path="$HOME/docker/bookstack"
target_dir="$HOME/docker/bookstack/backups"
max_num_backups=20
current_date=`date +'%Y-%m-%d@%H%M'`

mkdir -p "$target_dir/${version%%-*}"
find $target_dir -mindepth 1 -maxdepth 1 -type d ! -name "${version%%-*}" -exec rm -rf {} +

zip_file="$target_dir/${version%%-*}/bookstack-$current_date.tar.gz"

echo "Backup compressed filename: $zip_file"
sudo tar -czf "$zip_file" -C "$folder_path" $backup_paths > /dev/null

if [ "$(ls -1qAR $target_dir | grep bookstack | wc -l)" -gt $max_num_backups ]; then
    # Get the oldest file in the directory
    oldest_file="$(ls -1tR $target_dir | grep bookstack | tail -1 | awk '{print $NF}')"
    echo "Backup tar files in $target_dir exceeded $max_num_backups"
    echo "Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm "$target_dir/${version%%-*}/$oldest_file"
fi

echo "Start Bookstack docker ..." && docker start bookstack bookstack-database

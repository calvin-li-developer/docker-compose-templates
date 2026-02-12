#!/bin/bash
set -e
version=`docker inspect bookstack -f '{{json .Config.Labels}}' | jq -r '.["org.opencontainers.image.version"]'`
image_tag=`docker inspect bookstack -f '{{ json .Config.Image }}' | jq -r . | cut -d ':' -f2-`
printf "Bookstack Version: ${version}\nImage Tag: $image_tag\n" | tee "$HOME/docker/bookstack/config/backup_metadata.txt"

echo "Stop Bookstack docker ..." && docker stop bookstack bookstack-database > /dev/null

echo "Backup starting ..."

backup_paths=`ls -a $HOME/docker/bookstack | grep -vE '^(\.\.?|\.stfolder|backups)$' | paste -sd' ' -`
folder_path="$HOME/docker/bookstack"
target_dir="$HOME/docker/bookstack/backups"
max_num_backups=20
current_date=`date +'%Y-%m-%d@%H%M'`

mkdir -p "$target_dir/${version%%-*}"

zip_file="$target_dir/${version%%-*}/bookstack-$current_date.tar.gz"

echo "Backup compressed filename: $zip_file"
sudo tar -czf "$zip_file" -C "$folder_path" $backup_paths > /dev/null

if [ "$(ls -1qAR $target_dir | grep 'bookstack-' | wc -l)" -gt $max_num_backups ]; then
    # Get the oldest file in the directory
    oldest_file="$(ls -1tR $target_dir | grep 'bookstack-' | tail -1 | awk '{print $NF}')"
    path_to_oldest_file=`find "$target_dir" -name "$oldest_file" -type f`
    echo "Backup tar files in $target_dir exceeded $max_num_backups"
    rm -f "$path_to_oldest_file" && echo "Oldest file removed is $path_to_oldest_file"
fi
find "$target_dir" -type d -empty -print -delete

echo "Start Bookstack docker ..." && docker start bookstack bookstack-database
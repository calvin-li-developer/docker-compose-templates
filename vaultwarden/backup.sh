#!/bin/bash
set -e
version=`docker inspect vaultwarden -f '{{ json .Config.Labels }}' | jq -r '.["org.opencontainers.image.version"]'`
image_tag=`docker inspect vaultwarden -f '{{ json .Config.Image }}' | jq -r . | cut -d ':' -f2-`

printf "Vaultwarden Version: ${version}\nImage Tag: $image_tag\n" | tee "$HOME/docker/vaultwarden/config/backup_metadata.txt"

echo "Stop Vaultwarden docker ..." && docker stop vaultwarden > /dev/null

echo "Backup starting ..."

backup_paths=`ls -a $HOME/docker/vaultwarden | grep -vE '^(\.\.?|\.stfolder|backups|sync)$' | paste -sd' ' -`
folder_path="$HOME/docker/vaultwarden"
target_dir="$HOME/docker/vaultwarden/backups"
max_num_backups=240
current_date=`date +'%Y-%m-%d@%H%M'`

mkdir -p "$target_dir/${version%%-*}"

zip_file="$target_dir/${version%%-*}/vault-$current_date.tar.gz"

echo "Backup compressed filename: $zip_file"
sudo tar -czf "$zip_file" -C "$folder_path" $backup_paths

if [ "$(ls -1qAR $target_dir | grep 'vault-' | wc -l)" -gt $max_num_backups ]; then
    # Get the oldest file in the directory
    oldest_file="$(ls -1tR $target_dir | grep 'vault-' | tail -1 | awk '{print $NF}')"
    path_to_oldest_file=`find "$target_dir" -name "$oldest_file" -type f`
    echo "Backup tar files in $target_dir exceeded $max_num_backups"
    echo "Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm -f "$path_to_oldest_file"
fi
find "$target_dir" -type d -empty -print -delete

echo "Start Vaultwarden docker ..." && docker start vaultwarden
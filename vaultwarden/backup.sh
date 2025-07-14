# 
# add the next line to command crontab -e on ubuntu server:
# 0 */8 * * * $HOME/docker/vaultwarden/backup.sh
# 
#!/bin/bash
version=`docker inspect vaultwarden -f '{{ json .Config.Labels }}' | jq -r '.["org.opencontainers.image.version"]'`
image_tag=`docker inspect vaultwarden -f '{{ json .Config.Image }}' | jq -r . | cut -d ':' -f2-`

printf "Vaultwarden Version: ${version}\nImage Tag: $image_tag\n" | tee "$HOME/docker/vaultwarden/vaultwarden-config/backup_metadata.txt"

echo "Stop Vaultwarden docker ..." && docker stop vaultwarden > /dev/null

echo "Backup starting ..."

backup_paths="vaultwarden-config README.md cloudflared-config fail2ban-config .env docker-compose.yml"
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
    path_to_oldest_file=`find "$HOME/docker/vaultwarden/backups" -name "$oldest_file" -type f`
    echo "Backup tar files in $target_dir exceeded $max_num_backups"
    echo "Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm -f "$path_to_oldest_file"
fi

echo "Start Vaultwarden docker ..." && docker start vaultwarden
#
# add the next line to command crontab -e on ubuntu server:
# 0 */8 * * * $HOME/docker/vaultwarden/backup.sh
#
#!/bin/bash
docker stop vaultwarden

sleep 10 # wait for 10 seconds
echo "[INFO]: Starting vaultwarden back up . . ."

folder_path="vaultwarden-config/"
target_dir="$HOME/docker/vaultwarden"
max_num_backups=240
zip_file="vault-$(date +'%Y-%m-%d_%I%M_%p').tar.gz"
tar -czvf "$target_dir/backups/$zip_file" -C "$target_dir" "$folder_path" > /dev/null

echo "[INFO]: tar zip file location is $target_dir"

if [ "$(ls -1qA $target_dir | grep vault | wc -l)" -gt $max_num_backups  ]; then
    # Get the oldest file in the directory
    oldest_file=$(ls -1t $target_dir | grep "vault" | tail -1 | awk '{print $NF}')
    echo "[INFO]: Backup tar files in $target_dir exceeded $max_num_backups"
    echo "[INFO]: Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm $target_dir/$oldest_file
fi

docker start vaultwarden

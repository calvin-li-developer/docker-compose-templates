#!/bin/bash
target_dir="/backups"
max_num_backups=18

while [ "$(ls -1qA $target_dir | grep world | wc -l)" -gt $max_num_backups ];
do
    # Get the oldest file in the directory
    oldest_file=$(ls -1t $target_dir | grep "world" | tail -1 | awk '{print $NF}')
    echo "[INFO]: Backup tar files in $target_dir exceeded $max_num_backups"
    echo "[INFO]: Oldest file removed is $oldest_file"
    # Delete the oldest file
    rm $target_dir/$oldest_file
done
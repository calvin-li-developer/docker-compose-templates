crontab -e:
@reboot sh /home/ubuntu/docker/handbrake/scripts/onboot.sh >> /home/ubuntu/docker/handbrake/logs/onboot.log 2>&1
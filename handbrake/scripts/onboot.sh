# Make sure that /etc/netplan/* all the ethernet dhcp option does NOT contain optional: true
# Example:
# sudo cat /etc/netplan/50-cloud-init.yaml
#
# network:
#    ethernets:
#        eno1:
#            dhcp4: true
#    version: 2
#    wifis: {}
#

# replace "/home/ubuntu/docker/handbrake/media" if needed
while true; do
   if mountpoint -q "/home/ubuntu/docker/handbrake/media"; then
       echo "$(date) Mount point found. Starting handbrake docker container..."
       docker start handbrake > /dev/null
       break
   else
       echo "$(date) Trying again in 5 seconds..."
       sleep 5
   fi
done
echo "$(date) onboot.sh Successfully exited (0)."
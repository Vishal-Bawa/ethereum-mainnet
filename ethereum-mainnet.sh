#!/bin/bash

        sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install aria2  -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install jq -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install lz4 -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install xfsprogs -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install unzip -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -f 
        sudo hostnamectl set-hostname ${instance_name}
        sudo add-apt-repository -y ppa:ethereum/ethereum
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
        sudo DEBIAN_FRONTEND=noninteractive apt-get install ethereum -y
# # disk mount
#         sudo mkdir /data #create directory
#         disk2=$(lsblk -nx size -o kname|tail  -1 |awk {'printf "/dev/"$1'}) # To find unmount partion
#         sudo mkfs -t xfs $disk2 # To make a filesystem on partion 
#         sleep 10
#         sudo cp /etc/fstab /etc/fstab-old # To backup file /etc/fstab-old
#         VUUID=$(sudo blkid -o value -s UUID $disk2)
#         sleep 10
#         sudo su -c "echo 'UUID=$VUUID  /data   xfs   defaults        0       0' >> /etc/fstab" # To entry permament mount
#         sudo mount -a
#         echo "Disk mount complete"
#         sleep 10
sudo chown -R root:root /data # change the ownership /data dir.
        mkdir /data/.ethereum
        ln -s /data/.ethereum /root
        mkdir /data/.eth2
        ln -s /data/.eth2 /root
        sleep 10
        mkdir /data/prysm && cd /data/prysm
        # mkdir consensus execution && cd consensus
        curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output prysm.sh && chmod +x prysm.sh
        ./prysm.sh beacon-chain generate-auth-secret
        

sudo bash -c 'cat <<EOF > /etc/systemd/system/eth.service
[Unit]
Description=Ethereum Service
After=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/root/.ethereum
ExecStart=/usr/bin/geth --http --http.api eth,net,engine,admin,personal  --http.addr 0.0.0.0  --ws.addr 0.0.0.0  --authrpc.jwtsecret /data/prysm/jwt.hex --authrpc.port 8551   --metrics --metrics.addr 0.0.0.0 --metrics.port 6060
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF'

sudo bash -c 'cat <<EOF > /etc/systemd/system/prysm.service
[Unit]
Description=prysm Service
After=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/root/.eth2
Environment=PRYSM_ALLOW_UNVERIFIED_BINARIES=1
ExecStart=/data/prysm/prysm.sh beacon-chain --execution-endpoint=http://localhost:8551 --jwt-secret=/data/prysm/jwt.hex --accept-terms-of-use --checkpoint-sync-url=https://mainnet-checkpoint-sync.stakely.io --genesis-beacon-api-url=https://mainnet-checkpoint-sync.stakely.io
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF'
# mkdir /root/stopScript
# cat <<EOL > stopScript.sh
# #!/bin/bash
# sudo systemctl stop eth.service
# sleep 10
# sudo systemctl stop prysm.service
# sleep 10
# sudo poweroff
# EOL
sudo chown -R root:root /data

sudo systemctl enable prysm.service
sudo systemctl enable eth.service
sudo systemctl start prysm.service
sudo systemctl start eth.service

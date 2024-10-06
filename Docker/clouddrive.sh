#!/bin/bash

# 变量
docker_data="/vol1/1000/Docker"
container="Clouddrive"

sudo mkdir -p /etc/systemd/system/docker.service.d/
sudo cat <<EOF > /etc/systemd/system/docker.service.d/clear_mount_propagation_flags.conf
[Service]
MountFlags=shared
EOF
sudo systemctl restart docker.service


sudo mkdir -p $docker_data/$container
compose=$(cat <<'EOF'
# docker-compose.yml
version: "2.1"
services:
  cloudnas:
    image: cloudnas/clouddrive2
    container_name: clouddrive2
    environment:
      - TZ=Asia/Shanghai
      - CLOUDDRIVE_HOME=/Config
    volumes:
      - /vol1/1000/Clouddrive/shared:/CloudNAS:shared
      - /vol1/1000/Clouddrive/Config:/Config
      - /vol1/1000/Clouddrive/media/shared:/media:shared #optional media path of host
    devices:
      - /dev/fuse:/dev/fuse
    restart: unless-stopped
    pid: "host"
    privileged: true
    network_mode: "host"
EOF
)

# docker-compose
sudo cat <<EOF > $docker_data/$container/docker-compose.yml
$compose
EOF

cd $docker_data/$container
sudo docker-compose up -d
#!/bin/bash

# 变量
docker_data="/vol1/1000/Docker"
container="clash"

sudo mkdir -p $docker_data/$container

# 配置文件
sudo cat <<EOF > $docker_data/$container/config.yaml
# config.yaml
port: 7890
socks-port: 7891
allow-lan: true
external-controller: 0.0.0.0:9090
EOF

# docker-compose
sudo cat <<EOF > $docker_data/$container/docker-compose.yml
# docker-compose.yml
version: '3.7'
services:
	clash-server:
	    image: dreamacro/clash
	    container_name: clash
	    ports:
	      - "5090:9090"
	      - "5890:7890"
	      - "5891:7891"
	    volumes:
	      - ./config.yaml:/root/.config/clash/config.yaml

	clash-ui:
	    image: haishanh/yacd
	    container_name: clash-ui
	    ports:
	      - 5080:80
EOF

cd $docker_data/$container
sudo docker-compose up -d


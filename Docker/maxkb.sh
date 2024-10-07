#!/bin/bash
# 变量
container_data="/vol1/1000/Docker/maxkb"

# 定义要写入的文本
text=$(cat <<'EOF'
networks:
    1panel-network:
        external: true
services:
    maxkb:
        container_name: maxkb
        image: 1panel/maxkb:v1.6.1
        labels:
            createdBy: Apps
        networks:
            - 1panel-network
        ports:
            - 8080:8080
        restart: always
        volumes:
            - /vol1/1000/Docker/maxkb/data:/var/lib/postgresql/data
            - /vol1/1000/Docker/maxkb/python-packages:/opt/maxkb/app/sandbox/python-packages
EOF
)

# 运行容器
mkdir -p $container_data
cd $container_data

# 将文本写入文件
cat > $container_data/docker-compose.yml << EOF
$text
EOF

docker-compose up -d
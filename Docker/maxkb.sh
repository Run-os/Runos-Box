#!/bin/bash
# 变量
docker_data="/vol1/1000/Docker"
container="maxkb"

# 定义要写入的文本
text="""
networks:
    1panel-network:
        external: true
services:
    maxkb:
        container_name: \${CONTAINER_NAME}
        deploy:
            resources:
                limits:
                    cpus: \${CPUS}
                    memory: \${MEMORY_LIMIT}
        image: 1panel/maxkb:v1.6.1
        labels:
            createdBy: Apps
        networks:
            - 1panel-network
        ports:
            - \${HOST_IP}:\${PANEL_APP_PORT_HTTP}:8080
        restart: unless-stopped
        volumes:
            - $docker_data/$container/data:/var/lib/postgresql/data
            - $docker_data/$container/python-packages:/opt/maxkb/app/sandbox/python-packages
"""

# 运行容器
mkdir -p $docker_data/$container/
cd $docker_data/$container/

# 将文本写入文件
cat > $docker_data/$container/docker-compose.yml << EOF
$text
EOF

docker-compose up -d
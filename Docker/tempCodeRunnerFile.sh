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
            - ./data:/var/lib/postgresql/data
            - ./python-packages:/opt/maxkb/app/sandbox/python-packages
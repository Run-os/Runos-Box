#!/bin/bash
# 定义颜色输出函数
red() { echo -e "\033[31m\033[01m[WARNING] $1\033[0m"; }
green() { echo -e "\033[32m\033[01m[INFO] $1\033[0m"; }
greenline() { echo -e "\033[32m\033[01m $1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m[NOTICE] $1\033[0m"; }
blue() { echo -e "\033[34m\033[01m[MESSAGE] $1\033[0m"; }
light_magenta() { echo -e "\033[95m\033[01m[NOTICE] $1\033[0m"; }
highlight() { echo -e "\033[32m\033[01m$1\033[0m"; }
cyan() { echo -e "\033[38;2;0;255;255m$1\033[0m"; }

# 变量
docker_data="/home/Docker/data"
ip_address=$(hostname -I | awk '{print $1}')
echo "本机 IP 地址是: $ip_address"

declare -a menu_options
declare -A commands
menu_options=(
    # ====系统相关====
    "更新系统软件包"
    "swap修改"
    # =====Docker安装=====
    "安装Docker"
    "安装1panel面板"
    "查看1panel用户信息"
    # =====Docker容器相关=====
    "安装CloudDrive2"
    "安装CloudDrive2--fnOS专属"
    "安装Duplicati"
    "安装memos"
    # =====Docker进阶=====
    "安装Homarr--导航页"
    "安装freshrss--rss服务器"
    # =====Nginx相关=====
    "安装Nginx"
    "安装Nginx Proxy Manager"
    "配置openai和groq反代"
    # =====脚本相关=====
    "更新脚本"
    "安装大圣的日常--脚本"
)

commands=(
    ["更新系统软件包"]="update_system_packages"
    ["swap修改"]="swap_modify"
    ["安装Docker"]="install_docker"
    ["安装1panel面板"]="install_1panel_on_linux"
    ["查看1panel用户信息"]="read_1panel_info"
    ["安装Nginx Proxy Manager"]="install_nginx_proxy_manager"
    ["安装Nginx"]="install_nginx"
    ["配置openai和groq反代"]="configured_openai_groq_reverse_proxy"
    ["更新脚本"]="update_scripts"
    ["安装Docker"]="install_docker"
    ["安装CloudDrive2"]="install_clouddrive2"
    ["安装CloudDrive2--fnOS专属"]="install_clouddrive2_fnos"
    ["安装Duplicati"]="install_Duplicati"
    ["安装memos"]="install_memos"
    ["安装Homarr--导航页"]="install_Homarr"
    ["安装freshrss--rss服务器"]="install_freshrss"
    ["安装大圣的日常--脚本"]="install_daily_scripts"
)

# 检查是否以 root 用户身份运行
if [ "$(id -u)" -ne 0 ]; then
    green "注意！输入密码过程不显示*号属于正常现象"
    echo "此脚本需要以 root 用户权限运行，请输入当前用户的密码："
    # 使用 'sudo' 重新以 root 权限运行此脚本
    sudo -E "$0" "$@"
    exit $?
fi

# 更新系统软件包
update_system_packages() {
    green "Setting timezone Asia/Shanghai..."
    sudo timedatectl set-timezone Asia/Shanghai
    # 更新系统软件包
    green "Updating system packages..."
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    if [[ -z $(command -v curl) ]]; then
        red "curl is not installed. Installing now..."
        sudo apt install -y curl
        if command -v curl &>/dev/null; then
            green "curl has been installed successfully."
        else
            echo "Failed to install curl.
            Please check for errors."
        fi
    else
        echo "curl is already installed."
    fi
}

# 安装并启动Docker
install_docker() {
    # 检查是否已安装Docker
    if command -v docker &>/dev/null; then
        green "Docker 已经安装，跳过安装步骤"
    else
        # 安装Docker
        green "检测到未安装Docker，开始安装..."
        curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
        # 设置开机自启
        systemctl enable --now docker
        # 验证Docker是否安装成功
        green "验证Docker是否安装成功,显示版本号则为安装成功"
        docker --version
    fi

    # 检查是否已安装Docker-compose
    if command -v docker-compose &>/dev/null; then
        green "Docker-compose 已经安装，跳过安装步骤"
    else
        # 安装Docker-compose
        green "检测到未安装Docker-compose,开始安装..."
        curl -fsSL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        docker-compose --version
        # 下面这个好像也可以，从Debian/Ubuntu软件源一键安装
        # apt install -y docker.io  docker-compose
    fi

    read -p "是否需要更换镜像源？(y/n)" answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        # 更换镜像源
        mkdir -p /etc/docker
        tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://hub.geekery.cn",
    "https://ghcr.geekery.cn",
    "https://dockerpull.org",
    "https://dockerhub.icu",
    "https://docker.1panel.live",
    "https://docker.udayun.com"
  ],
  "live-restore": true
}
EOF
        systemctl daemon-reload
        systemctl restart docker
        green "镜像源已更换为国内镜像"
        docker info
    else
        yellow "跳过更换镜像源"
    fi
}

# 安装1panel面板
install_1panel_on_linux() {
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sudo bash quick_start.sh
    intro="https://1panel.cn/docs/installation/cli/"
    if command -v 1pctl &>/dev/null; then
        green "如何卸载1panel 请参考：$intro"
    else
        red "未安装1panel"
    fi
}

# 查看1panel用户信息
read_1panel_info() {
    sudo 1pctl user-info
}

# clouddrive2
install_clouddrive2() {
  sudo mkdir -p /etc/systemd/system/docker.service.d/
  sudo cat <<EOF >/etc/systemd/system/docker.service.d/clear_mount_propagation_flags.conf
[Service]
MountFlags=shared
EOF
  sudo systemctl daemon-reload
  sudo systemctl restart docker.service
  # 安装clouddrive2
  docker run -d \
    --name clouddrive2 \
    --restart unless-stopped \
    --env CLOUDDRIVE_HOME=/Config \
    -v /home/clouddrive/shared:/CloudNAS:shared \
    -v /home/clouddrive/Config:/Config \
    -v /home/clouddrive/media/shared:/media:shared \
    -p:19798:19798 \
    --privileged \
    --device /dev/fuse:/dev/fuse \
    cloudnas/clouddrive2
  green "clouddrive2 安装成功，请访问 http://你的服务器IP地址:19798"
  green "私人提示：clouddrive2 安装成功，请访问 http://$ip_address:19798"
}

# clouddrive2--fnOS专属
install_clouddrive2_fnos() {
  sudo mkdir -p /etc/systemd/system/docker.service.d/
  sudo cat <<EOF >/etc/systemd/system/docker.service.d/clear_mount_propagation_flags.conf
[Service]
MountFlags=shared
EOF
  sudo systemctl daemon-reload
  sudo systemctl restart docker.service
  # 安装clouddrive2
  docker run -d \
    --name clouddrive2 \
    --restart unless-stopped \
    --env CLOUDDRIVE_HOME=/Config \
    -v /vol1/1000/Clouddrive/shared:/CloudNAS:shared \
    -v /vol1/1000/Clouddrive/Config:/Config \
    -v /vol1/1000/Clouddrive/media/shared:/media:shared \
    -p:19798:19798 \
    --privileged \
    --device /dev/fuse:/dev/fuse \
    cloudnas/clouddrive2
  green "clouddrive2 安装成功，请访问 http://你的服务器IP地址:19798"
  green "私人提示：clouddrive2 安装成功，请访问 http://$ip_address:19798"

}


# 安装Duplicati
install_Duplicati() {
  mkdir -p $docker_data/duplicati
  cd $docker_data/duplicati
  # 创建docker-compose文件

  cat >docker-compose.yml <<'EOL'
version: "3"
services:
  duplicati:
    image: linuxserver/duplicati
    container_name: duplicati
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - /root/data/docker_data/duplicati/config:/config
      - /root/data/docker_data/duplicati/backups:/backups
      ###- /root/data:/source
      - /:/source  #这个地方我直接映射根目录，这样什么文件就都可以备份了
    ports:
      - 8080:8200
    restart: unless-stopped
EOL

  # 启动容器
  docker-compose -f docker-compose.yml up -d
  green "Duplicati 安装成功，请访问 http://你的服务器IP地址:8080"
  green "私人提示：Duplicati 安装成功，请访问 http://$ip_address:8080"
}



# 安装memos
install_memos() {
  read -p "-----------------
  1. 安装最新版本memos
  2. 安装 $memos_version 版本的memos(适配inbox) 
  请输入序号：" answer

  if [ "$answer" -eq 1 ]; then
    # 安装最新版本memos
    docker run \
      --name memos \
      -d \
      --publish 5230:5230 \
      --restart unless-stopped \
      --volume $docker_data/memos/:/var/opt/memos \
      neosmemo/memos --mode prod \
      --port 5230
    green "memos 安装成功，请访问 http://你的服务器IP地址:5230"
    green "私人提示：memos 安装成功，请访问 http://$ip_address:5230"
    green "注意：memos文件保存在 $docker_data/memos 文件夹下。"
  fi

  if [ "$answer" -eq 2 ]; then
    if docker ps | grep -q "memos"; then
      docker stop memos
      docker rm memos
      green "memos 容器已存在，已停止并删除原容器"
    else
      green "memos 容器不存在，可以安装"
    fi
    # 安装适配inbox的memos版本
    green "正在拉取 $memos_version 版本的memos镜像..."
    docker run \
      --name memos \
      -d \
      --publish 5230:5230 \
      --restart unless-stopped \
      --volume $docker_data/memos/:/var/opt/memos \
      neosmemo/memos:$memos_version \
      --port 5230
    green "memos $memos_version 安装成功，请访问 http://你的服务器IP地址:5230"
    green "注意：memos文件保存在 $docker_data/memos/ 文件夹下。"
  fi

  if [ "$answer" -ne 1 ] && [ "$answer" -ne 2 ]; then
    echo -e "${RED}请输入有效数字!${NC}"
    return
  fi

}

install_Homarr() {
  mkdir -p $docker_data/Homarr
  cd $docker_data/Homarr

  # 创建docker
  docker run  \
    --name homarr \
    --restart unless-stopped \
    -p 7575:7575 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $docker_data/homarr/configs:/app/data/configs \
    -v $docker_data/homarr/data:/data \
    -v $docker_data/homarr/icons:/app/public/icons \
    -d ghcr.dockerproxy.net/ajnart/homarr:latest

  green "Homarr 安装成功，请访问 http://你的服务器IP地址:7575"
  green "私人提示：Homarr 安装成功，请访问 http://$ip_address:7575"
  }


install_freshrss() {
  mkdir -p $docker_data/freshrss
  cd $docker_data/freshrss
  # 创建docker-compose文件
  cat >docker-compose.yml <<'EOL'
version: "3.9"
services:
  freshrss:
    image: linuxserver/freshrss:latest
    container_name: freshrss
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - /path/to/data:/config
    ports:
      - 8088:80
    restart: unless-stopped
EOL
  
    # 启动容器
    docker-compose -f docker-compose.yml up -d
    green "FreshRSS 安装成功，请访问 http://你的服务器IP地址:8088"
    green "私人提示：FreshRSS 安装成功，请访问 http://$ip_address:8088"
  }  

# 安装Nginx
install_nginx() {
    if command -v nginx &>/dev/null; then
        green "已经安装nginx，跳过安装步骤"
    else
        red "未安装nginx，开始安装"
        apt install nginx
    fi
    green "Nginx 安装成功"
}

# 安装Nginx Proxy Manager
install_nginx_proxy_manager() {
    mkdir -p $docker_data/npm
    cd $docker_data/npm
    # 创建docker-compose文件

    cat >docker-compose.yml <<'EOL'
# version: '3'
services:
  app:
    image: 'chishin/nginx-proxy-manager-zh:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOL

    # 启动Nginx Proxy Manager容器
    docker-compose -f docker-compose.yml up -d
    green "Nginx Proxy Manager 安装成功，请访问 http://你的服务器IP地址:81"
}

# 配置openai和groq反代
configured_openai_groq_reverse_proxy() {
    green "配置openai和groq反代"
    # openai
    sudo tee /etc/nginx/conf.d/openai.conf <<'EOL'
server {
	listen 84;
    location / {
        proxy_pass https://api.openai.com/;
        proxy_ssl_server_name on;
        proxy_set_header Host api.openai.com;
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOL
    green "openai反代配置文件完成，端口为 84"
    # groq
    sudo tee /etc/nginx/conf.d/groq.conf <<'EOL'
server {
	listen 88;
	location / {
		proxy_pass https://api.groq.com;
		proxy_set_header Host api.groq.com;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_ssl_server_name on;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # 如果响应是流式的
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
        # 如果响应是一般的
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
	}
}
EOL
    green "groq反代配置文件完成，端口为 88"
    green "重启Nginx..."
    sudo nginx -s stop
    sudo nginx
}


# swap修改
swapsh() {
    wget -O "/root/swap.sh" "https://ghp.ci/https://raw.githubusercontent.com/BlueSkyXN/ChangeSource/master/swap.sh" --no-check-certificate -T 30 -t 5 -d
    chmod +x "/root/swap.sh"
    chmod 777 "/root/swap.sh"
    blue "下载完成"
    blue "你也可以输入 bash /root/swap.sh 来手动运行"
    bash "/root/swap.sh"
}

# 更新自己
update_scripts() {
    wget -O docker-box.sh https://ghp.ci/https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-box.sh && chmod +x docker-box.sh && clear && ./docker-box.sh
    echo "脚本已更新并保存在当前目录 docker-box.sh,现在将执行新脚本。"
    ./docker-box.sh
    exit 0
}

# 安装大圣的日常--脚本
install_dashen_scripts() {
  # 下载脚本
  wget -qO pi.sh https://cafe.cpolar.cn/wkdaily/zero3/raw/branch/main/zero3/pi.sh && chmod +x pi.sh && ./pi.sh
  green "脚本已经下载到当前目录，现在将执行新脚本。"
  ./pi.sh
  exit 0
}

# 显示菜单
show_menu() {
    clear
    greenline "————————————————————————————————————————————————————"
    red " Runos-Box Linux Supported ONLY"
    green " FROM: https://github.com/Run-os/Runos-Box "
    green " USE:  wget -O docker-box.sh https://ghp.ci/https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-box.sh && chmod +x docker-box.sh && clear && ./docker-box.sh "
    greenline "————————————————————————————————————————————————————"
    echo "请选择操作："

    # 特殊处理的项数组
    special_items=("安装Docker" "安装Nginx" "更新脚本")
    for i in "${!menu_options[@]}"; do
        if [[ " ${special_items[*]} " =~ " ${menu_options[i]} " ]]; then
            # 如果当前项在特殊处理项数组中，使用特殊颜色
            yellow "=============================================="
            green "$((i + 1)). ${menu_options[i]}"
        else
            # 否则，使用普通格式
            green "$((i + 1)). ${menu_options[i]}"
        fi
    done
}

# 执行命令
handle_choice() {
    local choice=$1
    # 检查输入是否为空
    if [[ -z $choice ]]; then
        echo -e "${RED}输入不能为空，请重新选择。${NC}"
        return
    fi

    # 检查输入是否为数字
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效数字!${NC}"
        return
    fi

    # 检查数字是否在有效范围内
    if [[ $choice -lt 1 ]] || [[ $choice -gt ${#menu_options[@]} ]]; then
        echo -e "${RED}选项超出范围!${NC}"
        echo -e "${YELLOW}请输入 1 到 ${#menu_options[@]} 之间的数字。${NC}"
        return
    fi

    # 执行命令
    if [ -z "${commands[${menu_options[$choice - 1]}]}" ]; then
        echo -e "${RED}无效选项，请重新选择。${NC}"
        return
    fi

    "${commands[${menu_options[$choice - 1]}]}"
}

while true; do
    show_menu
    read -p "请输入选项的序号(输入q退出): " choice
    if [[ $choice == 'q' ]]; then
        break
    fi
    handle_choice $choice
    echo "按任意键继续..."
    read -n 1 # 等待用户按键
done

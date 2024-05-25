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
docker_data="/root/data/docker_data"

declare -a menu_options
declare -A commands
menu_options=(
    # ====系统相关====
    "更新系统软件包"
    "swap修改"
    # =====Docker相关=====
    "安装Docker"
    "安装1panel面板"
    "查看1panel用户信息"
    # =====Nginx相关=====
    "安装Nginx"
    "安装Nginx Proxy Manager"
    "配置openai和groq反代"
    "配置notion反代"
    # =====脚本相关=====
    "更新脚本"
    "docker-start.sh脚本"
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
    ["配置notion反代"]="configured_notion_reverse_proxy"
    ["更新脚本"]="update_scripts"
    ["docker-start.sh脚本"]="docker_start_script"
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
    "https://0b27f0a81a00f3560fbdc00ddd2f99e0.mirror.swr.myhuaweicloud.com",
    "https://ypzju6vq.mirror.aliyuncs.com",
    "https://registry.docker-cn.com",
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
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
version: '3'
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
    green "openai反代配置文件完成"
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
    green "groq反代配置文件完成"
    green "重启Nginx..."
    sudo nginx -s stop
    sudo nginx
}

# 配置notion反代
configured_notion_reverse_proxy() {
    green "配置notion反代"
    sudo tee /etc/nginx/conf.d/notion.conf <<'EOL'
server {
	listen 82;
    location / {
        proxy_pass https://www.notion.so/;
        proxy_ssl_server_name on;
        proxy_set_header Host www.notion.so;
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
    green "notion反代配置文件完成"
    green "重启Nginx..."
    sudo nginx -s stop
    sudo nginx
}

# swap修改
swapsh() {
    wget -O "/root/swap.sh" "https://raw.githubusercontent.com/BlueSkyXN/ChangeSource/master/swap.sh" --no-check-certificate -T 30 -t 5 -d
    chmod +x "/root/swap.sh"
    chmod 777 "/root/swap.sh"
    blue "下载完成"
    blue "你也可以输入 bash /root/swap.sh 来手动运行"
    bash "/root/swap.sh"
}

# docker-start.sh脚本
docker_start_sh() {
    wget -O docker-start.sh https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-start.sh && chmod +x docker-start.sh && clear && ./docker-start.sh
    echo "脚本已更新并保存在当前目录 docker-start.sh,现在将执行新脚本。"
    ./docker-start.sh
    exit 0
}

# 更新自己
update_scripts() {
    wget -O box.sh https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/box.sh && chmod +x box.sh && clear && ./box.sh
    echo "脚本已更新并保存在当前目录 box.sh,现在将执行新脚本。"
    ./box.sh
    exit 0
}

show_menu() {
    clear
    greenline "————————————————————————————————————————————————————"
    red " Runos-Box Linux Supported ONLY"
    green " FROM: https://github.com/Run-os/Runos-Box "
    green " USE:  wget -O box.sh https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/box.sh && chmod +x box.sh && clear && ./box.sh "
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

#!/bin/bash

# =============================================================================
# Runos-Box Docker Management Script
# 脚本描述：Linux Docker 容器管理工具
# 作者：Run-os
# 版本：2.0
# 注意：如果报错SSL错误，使用指令：wget -P /root -N --no-check-certificate https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-box.sh && chmod 700 /root/docker-box.sh && /root/docker-box.sh
# =============================================================================

# 注意：不使用 set -e，因为我们有自定义的错误处理机制
set -u  # 使用未定义变量时退出

# 定义颜色输出函数
readonly RED='\033[31m\033[01m'
readonly GREEN='\033[32m\033[01m'
readonly YELLOW='\033[33m\033[01m'
readonly BLUE='\033[34m\033[01m'
readonly MAGENTA='\033[95m\033[01m'
readonly CYAN='\033[38;2;0;255;255m'
readonly NC='\033[0m'

red() { echo -e "${RED}[WARNING] $1${NC}"; }
green() { echo -e "${GREEN}[INFO] $1${NC}"; }
greenline() { echo -e "${GREEN} $1${NC}"; }
yellow() { echo -e "${YELLOW}[NOTICE] $1${NC}"; }
blue() { echo -e "${BLUE}[MESSAGE] $1${NC}"; }
cyan() { echo -e "${CYAN}$1${NC}"; }

# 全局变量
readonly DOCKER_DATA="/home/Docker/data"
readonly MEMOS_VERSION="0.22.4"

# 获取本机IP地址
get_ip_address() {
    local ip
    ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")
    echo "$ip"
}

readonly IP_ADDRESS=$(get_ip_address)
green "本机 IP 地址是: $IP_ADDRESS"

# 菜单配置
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
    "安装sun-panel--导航页"
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
    ["安装CloudDrive2"]="install_clouddrive2"
    ["安装CloudDrive2--fnOS专属"]="install_clouddrive2_fnos"
    ["安装Duplicati"]="install_duplicati"
    ["安装memos"]="install_memos"
    ["安装sun-panel--导航页"]="install_sun_panel"
    ["安装freshrss--rss服务器"]="install_freshrss"
    ["安装Nginx"]="install_nginx"
    ["安装Nginx Proxy Manager"]="install_nginx_proxy_manager"
    ["配置openai和groq反代"]="configure_openai_groq_reverse_proxy"
    ["更新脚本"]="update_scripts"
    ["安装大圣的日常--脚本"]="install_daily_scripts"
)

# 工具函数
check_command() {
    command -v "$1" &>/dev/null
}

ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            red "创建目录失败: $dir"
            return 1
        }
        green "创建目录: $dir"
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local answer
    
    while true; do
        read -p "$prompt (y/n): " answer
        case "$answer" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "请输入 y 或 n" ;;
        esac
    done
}

# 检查是否以 root 用户身份运行
check_root_privileges() {
    if [[ "$(id -u)" -ne 0 ]]; then
        green "注意！输入密码过程不显示*号属于正常现象"
        echo "此脚本需要以 root 用户权限运行，请输入当前用户的密码："
        # 使用 'sudo' 重新以 root 权限运行此脚本
        exec sudo -E "$0" "$@"
    fi
}

# 更新系统软件包
update_system_packages() {
    green "设置时区为 Asia/Shanghai..."
    timedatectl set-timezone Asia/Shanghai || {
        red "设置时区失败"
        return 1
    }
    
    green "更新系统软件包..."
    apt update || {
        red "更新软件包列表失败"
        return 1
    }
    
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y || {
        red "升级系统软件包失败"
        return 1
    }
    
    # 检查并安装 curl
    if ! check_command curl; then
        green "安装 curl..."
        apt install -y curl || {
            red "安装 curl 失败"
            return 1
        }
        green "curl 安装成功"
    else
        green "curl 已经安装"
    fi
    
    green "系统更新完成"
}

# 安装并启动Docker
install_docker() {
    # 检查是否已安装Docker
    if check_command docker; then
        green "Docker 已经安装，跳过安装步骤"
    else
        # 安装Docker
        green "检测到未安装Docker，开始安装..."
        curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun || {
            red "Docker 安装失败"
            return 1
        }
        
        # 设置开机自启
        systemctl enable --now docker || {
            red "启动 Docker 服务失败"
            return 1
        }
        
        # 验证Docker是否安装成功
        green "验证Docker是否安装成功..."
        docker --version && green "Docker 安装成功" || {
            red "Docker 安装验证失败"
            return 1
        }
    fi

    # 检查是否已安装Docker-compose
    if check_command docker-compose; then
        green "Docker-compose 已经安装，跳过安装步骤"
    else
        # 安装Docker-compose
        green "检测到未安装Docker-compose，开始安装..."
        curl -fsSL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
            -o /usr/local/bin/docker-compose || {
            red "下载 Docker Compose 失败"
            return 1
        }
        
        chmod +x /usr/local/bin/docker-compose || {
            red "设置 Docker Compose 权限失败"
            return 1
        }
        
        docker-compose --version && green "Docker Compose 安装成功" || {
            red "Docker Compose 安装验证失败"
            return 1
        }
    fi

    # 询问是否更换镜像源
    if prompt_yes_no "是否需要更换Docker镜像源为国内镜像？"; then
        configure_docker_mirrors
    else
        yellow "跳过更换镜像源"
    fi
}

# 配置Docker镜像源
configure_docker_mirrors() {
    green "配置Docker镜像源..."
    ensure_directory "/etc/docker"
    
    cat > /etc/docker/daemon.json << 'EOL'
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
EOL

    systemctl daemon-reload || {
        red "重新加载 systemd 配置失败"
        return 1
    }
    
    systemctl restart docker || {
        red "重启 Docker 服务失败"
        return 1
    }
    
    green "Docker镜像源已更换为国内镜像"
    docker info | grep -A 10 "Registry Mirrors" || true
}

# 安装1panel面板
install_1panel_on_linux() {
    green "开始安装1panel面板..."
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh || {
        red "下载1panel安装脚本失败"
        return 1
    }
    
    bash quick_start.sh || {
        red "1panel安装失败"
        return 1
    }
    
    rm -f quick_start.sh
    
    if check_command 1pctl; then
        green "1panel安装成功"
        green "如何卸载1panel请参考：https://1panel.cn/docs/installation/cli/"
        green "使用 '1pctl user-info' 查看用户信息"
    else
        red "1panel安装失败，请检查错误信息"
        return 1
    fi
}

# 查看1panel用户信息
read_1panel_info() {
    if check_command 1pctl; then
        1pctl user-info || {
            red "获取1panel用户信息失败"
            return 1
        }
        green "如需修改密码，请使用 '1pctl update password'"
    else
        red "1panel未安装，请先安装1panel"
        return 1
    fi
}

# 配置Docker挂载权限
configure_docker_mount() {
    green "配置Docker挂载权限..."
    ensure_directory "/etc/systemd/system/docker.service.d/"
    
    cat > /etc/systemd/system/docker.service.d/clear_mount_propagation_flags.conf << 'EOL'
[Service]
MountFlags=shared
EOL

    systemctl daemon-reload || {
        red "重新加载systemd配置失败"
        return 1
    }
    
    systemctl restart docker.service || {
        red "重启Docker服务失败"
        return 1
    }
    
    green "Docker挂载权限配置完成"
}

# CloudDrive2安装
install_clouddrive2() {
    green "开始安装CloudDrive2..."
    configure_docker_mount || return 1
    
    # 创建必要的目录
    ensure_directory "/home/clouddrive/shared"
    ensure_directory "/home/clouddrive/Config"
    ensure_directory "/home/clouddrive/media/shared"
    
    # 安装clouddrive2
    docker run -d \
        --name clouddrive2 \
        --restart unless-stopped \
        --env CLOUDDRIVE_HOME=/Config \
        -v /home/clouddrive/shared:/CloudNAS:shared \
        -v /home/clouddrive/Config:/Config \
        -v /home/clouddrive/media/shared:/media:shared \
        -p 19798:19798 \
        --privileged \
        --device /dev/fuse:/dev/fuse \
        cloudnas/clouddrive2 || {
        red "CloudDrive2安装失败"
        return 1
    }
    
    green "CloudDrive2安装成功"
    green "访问地址: http://$IP_ADDRESS:19798"
}

# CloudDrive2--fnOS专属
install_clouddrive2_fnos() {
    green "开始安装CloudDrive2 (fnOS专用版)..."
    configure_docker_mount || return 1
    
    # 创建必要的目录
    ensure_directory "/vol1/1000/Clouddrive/shared"
    ensure_directory "/vol1/1000/Clouddrive/Config"
    ensure_directory "/vol1/1000/Clouddrive/media/shared"
    
    # 安装clouddrive2
    docker run -d \
        --name clouddrive2 \
        --restart unless-stopped \
        --env CLOUDDRIVE_HOME=/Config \
        -v /vol1/1000/Clouddrive/shared:/CloudNAS:shared \
        -v /vol1/1000/Clouddrive/Config:/Config \
        -v /vol1/1000/Clouddrive/media/shared:/media:shared \
        -p 19798:19798 \
        --privileged \
        --device /dev/fuse:/dev/fuse \
        cloudnas/clouddrive2 || {
        red "CloudDrive2 (fnOS) 安装失败"
        return 1
    }
    
    green "CloudDrive2 (fnOS专用版) 安装成功"
    green "访问地址: http://$IP_ADDRESS:19798"
}


# 安装Duplicati
install_duplicati() {
    green "开始安装Duplicati..."
    local duplicati_dir="$DOCKER_DATA/duplicati"
    
    ensure_directory "$duplicati_dir"
    ensure_directory "$duplicati_dir/config"
    ensure_directory "$duplicati_dir/backups"
    
    cd "$duplicati_dir" || {
        red "进入目录失败: $duplicati_dir"
        return 1
    }

    # 创建docker-compose文件
    cat > docker-compose.yml << 'EOL'
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
      - ./config:/config
      - ./backups:/backups
      - /:/source  # 映射根目录，可以备份任何文件
    ports:
      - 8080:8200
    restart: unless-stopped
EOL

    # 启动容器
    docker-compose up -d || {
        red "Duplicati启动失败"
        return 1
    }
    
    green "Duplicati安装成功"
    green "访问地址: http://$IP_ADDRESS:8080"
    green "数据保存位置: $duplicati_dir"
}

# 安装memos
install_memos() {
    green "开始安装memos..."
    
    echo "请选择memos版本："
    echo "1. 安装最新版本memos"
    echo "2. 安装 $MEMOS_VERSION 版本的memos (适配inbox)"
    
    local choice
    read -p "请输入序号 (1-2): " choice
    
    local memos_dir="$DOCKER_DATA/memos"
    ensure_directory "$memos_dir"
    
    # 检查并停止已存在的容器
    if docker ps -a | grep -q "memos"; then
        green "检测到已存在的memos容器，正在停止并删除..."
        docker stop memos 2>/dev/null || true
        docker rm memos 2>/dev/null || true
    fi

    case "$choice" in
        1)
            green "安装最新版本memos..."
            docker run \
                --name memos \
                -d \
                --publish 5230:5230 \
                --restart unless-stopped \
                --volume "$memos_dir":/var/opt/memos \
                neosmemo/memos --mode prod \
                --port 5230 || {
                red "memos安装失败"
                return 1
            }
            green "最新版本memos安装成功"
            ;;
        2)
            green "安装 $MEMOS_VERSION 版本的memos..."
            docker run \
                --name memos \
                -d \
                --publish 5230:5230 \
                --restart unless-stopped \
                --volume "$memos_dir":/var/opt/memos \
                "neosmemo/memos:$MEMOS_VERSION" \
                --port 5230 || {
                red "memos $MEMOS_VERSION 安装失败"
                return 1
            }
            green "memos $MEMOS_VERSION 版本安装成功"
            ;;
        *)
            red "无效选择，请重新运行"
            return 1
            ;;
    esac
    
    green "访问地址: http://$IP_ADDRESS:5230"
    green "数据保存位置: $memos_dir"
}

# 安装sun-panel
install_sun_panel() {
    green "开始安装sun-panel..."
    local sun_panel_dir="$DOCKER_DATA/sun-panel"
    
    ensure_directory "$sun_panel_dir"
    cd "$sun_panel_dir" || {
        red "进入目录失败: $sun_panel_dir"
        return 1
    }

    # 创建docker-compose文件
    cat > docker-compose.yml << 'EOL'
version: "3.2"
services:
  sun-panel:
    image: "hslr/sun-panel:latest"
    container_name: sun-panel
    volumes:
      - ./conf:/app/conf
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 3002:3002
    restart: always
EOL

    # 启动容器
    docker-compose up -d || {
        red "sun-panel启动失败"
        return 1
    }
    
    green "sun-panel安装成功"
    green "访问地址: http://$IP_ADDRESS:3002"
}

# 安装freshrss
install_freshrss() {
    green "开始安装FreshRSS..."
    local freshrss_dir="$DOCKER_DATA/freshrss"
    
    ensure_directory "$freshrss_dir"
    ensure_directory "$freshrss_dir/config"
    
    cd "$freshrss_dir" || {
        red "进入目录失败: $freshrss_dir"
        return 1
    }

    # 创建docker-compose文件
    cat > docker-compose.yml << 'EOL'
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
      - ./config:/config
    ports:
      - 8088:80
    restart: unless-stopped
EOL
    
    # 启动容器
    docker-compose up -d || {
        red "FreshRSS启动失败"
        return 1
    }
    
    green "FreshRSS安装成功"
    green "访问地址: http://$IP_ADDRESS:8088"
    green "数据保存位置: $freshrss_dir"
}  

# 安装Nginx
install_nginx() {
    if check_command nginx; then
        green "Nginx已经安装，跳过安装步骤"
    else
        green "开始安装Nginx..."
        apt install -y nginx || {
            red "Nginx安装失败"
            return 1
        }
        
        # 启动并设置开机自启
        systemctl enable --now nginx || {
            red "启动Nginx服务失败"
            return 1
        }
    fi
    
    green "Nginx安装成功"
    green "默认访问地址: http://$IP_ADDRESS"
}

# 安装Nginx Proxy Manager
install_nginx_proxy_manager() {
    green "开始安装Nginx Proxy Manager..."
    local npm_dir="$DOCKER_DATA/npm"
    
    ensure_directory "$npm_dir"
    ensure_directory "$npm_dir/data"
    ensure_directory "$npm_dir/letsencrypt"
    
    cd "$npm_dir" || {
        red "进入目录失败: $npm_dir"
        return 1
    }

    # 创建docker-compose文件
    cat > docker-compose.yml << 'EOL'
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
    docker-compose up -d || {
        red "Nginx Proxy Manager启动失败"
        return 1
    }
    
    green "Nginx Proxy Manager安装成功"
    green "访问地址: http://$IP_ADDRESS:81"
    green "默认用户名: admin@example.com"
    green "默认密码: changeme"
}

# 配置openai和groq反代
configure_openai_groq_reverse_proxy() {
    green "开始配置OpenAI和Groq反向代理..."
    
    # 检查Nginx是否安装
    if ! check_command nginx; then
        red "Nginx未安装，请先安装Nginx"
        return 1
    fi
    
    # 确保配置目录存在
    ensure_directory "/etc/nginx/conf.d"
    
    # 配置OpenAI反代
    green "配置OpenAI反向代理 (端口84)..."
    cat > /etc/nginx/conf.d/openai.conf << 'EOL'
server {
    listen 84;
    server_name _;
    
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
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOL

    # 配置Groq反代
    green "配置Groq反向代理 (端口88)..."
    cat > /etc/nginx/conf.d/groq.conf << 'EOL'
server {
    listen 88;
    server_name _;
    
    location / {
        proxy_pass https://api.groq.com;
        proxy_set_header Host api.groq.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_ssl_server_name on;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 流式响应设置
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
        
        # 缓冲区设置
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOL

    # 测试Nginx配置
    if nginx -t; then
        green "Nginx配置测试通过"
        # 重启Nginx
        systemctl reload nginx || {
            red "重新加载Nginx配置失败"
            return 1
        }
        green "Nginx配置已重新加载"
        green "OpenAI反代地址: http://$IP_ADDRESS:84"
        green "Groq反代地址: http://$IP_ADDRESS:88"
    else
        red "Nginx配置测试失败，请检查配置文件"
        return 1
    fi
}

# swap修改
swap_modify() {
    green "开始下载swap修改脚本..."
    local swap_script="/tmp/swap.sh"
    
    wget -O "$swap_script" \
        "https://ghp.ci/https://raw.githubusercontent.com/BlueSkyXN/ChangeSource/master/swap.sh" \
        --no-check-certificate -T 30 -t 5 || {
        red "下载swap脚本失败"
        return 1
    }
    
    chmod +x "$swap_script"
    green "脚本下载完成"
    green "提示：你也可以手动运行 bash $swap_script"
    
    bash "$swap_script"
}

# 更新脚本
update_scripts() {
    green "开始更新脚本..."
    local script_url="https://ghp.ci/https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-box.sh"
    local new_script="docker-box-new.sh"
    
    # 下载新脚本
    if wget -O "$new_script" "$script_url"; then
        chmod +x "$new_script"
        green "脚本更新下载完成"
        
        # 备份当前脚本
        if [[ -f "docker-box.sh" ]]; then
            cp "docker-box.sh" "docker-box-backup.sh"
            green "已备份当前脚本为 docker-box-backup.sh"
        fi
        
        # 替换脚本
        mv "$new_script" "docker-box.sh"
        green "脚本已更新，现在将执行新脚本"
        
        # 执行新脚本
        exec "./docker-box.sh"
    else
        red "脚本更新失败，请检查网络连接"
        return 1
    fi
}

# 安装大圣的日常脚本
install_daily_scripts() {
    green "开始下载大圣的日常脚本..."
    local script_url="https://cafe.cpolar.cn/wkdaily/zero3/raw/branch/main/zero3/pi.sh"
    local script_name="pi.sh"
    
    if wget -qO "$script_name" "$script_url"; then
        chmod +x "$script_name"
        green "脚本下载完成，现在将执行新脚本"
        exec "./$script_name"
    else
        red "下载脚本失败，请检查网络连接"
        return 1
    fi
}

# 显示菜单
show_menu() {
    clear
    echo
    greenline "════════════════════════════════════════════════════════════════"
    cyan "                        🐳 Runos-Box Docker 管理工具"
    greenline "════════════════════════════════════════════════════════════════"
    red " 📋 支持平台: Linux Only"
    green " 🔗 项目地址: https://github.com/Run-os/Runos-Box"
    blue " 💻 当前IP: $IP_ADDRESS"
    greenline "════════════════════════════════════════════════════════════════"
    echo
    green "请选择操作："
    echo

    # 特殊处理的项目数组（用于高亮显示）
    local special_items=("安装Docker" "安装Nginx" "更新脚本")
    
    for i in "${!menu_options[@]}"; do
        local item="${menu_options[i]}"
        local num=$((i + 1))
        
        # 检查是否是特殊项目
        if [[ " ${special_items[*]} " =~ " $item " ]]; then
            yellow "  ▶ $num. $item"
        else
            green "    $num. $item"
        fi
    done
    
    echo
    greenline "════════════════════════════════════════════════════════════════"
}

# 错误处理函数（用于特殊情况）
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    if [[ $exit_code -ne 0 ]]; then
        red "❌ 执行失败！错误代码: $exit_code，行号: $line_number"
        red "请检查错误信息并重试"
    fi
}

# 执行选择的命令
handle_choice() {
    local choice="$1"
    
    # 输入验证
    if [[ -z "$choice" ]]; then
        red "❌ 输入不能为空，请重新选择"
        return 1
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        red "❌ 请输入有效数字!"
        return 1
    fi

    if [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#menu_options[@]} ]]; then
        red "❌ 选项超出范围!"
        yellow "请输入 1 到 ${#menu_options[@]} 之间的数字"
        return 1
    fi

    # 获取选中的菜单项和对应的命令
    local selected_option="${menu_options[$((choice - 1))]}"
    local command_name="${commands[$selected_option]}"
    
    if [[ -z "$command_name" ]]; then
        red "❌ 无效选项，请重新选择"
        return 1
    fi

    # 显示即将执行的操作
    echo
    blue "🚀 正在执行: $selected_option"
    echo

    # 执行命令
    if ! "$command_name"; then
        red "❌ 操作失败: $selected_option"
        return 1
    else
        green "✅ 操作完成: $selected_option"
    fi
}

# 主程序循环
main() {
    # 检查root权限
    check_root_privileges
    
    green "🎉 欢迎使用 Runos-Box Docker 管理工具!"
    
    while true; do
        show_menu
        echo
        read -p "请输入选项序号 (输入 q 退出): " choice
        
        case "$choice" in
            [Qq]|[Qq][Uu][Ii][Tt])
                green "👋 感谢使用 Runos-Box Docker 管理工具!"
                exit 0
                ;;
            *)
                if handle_choice "$choice"; then
                    echo
                    green "✨ 按任意键继续..."
                    read -n 1 -s
                else
                    echo
                    yellow "⚠️  按任意键重试..."
                    read -n 1 -s
                fi
                ;;
        esac
    done
}

# 运行主程序
main "$@"

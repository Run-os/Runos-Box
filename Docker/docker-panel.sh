#!/bin/bash

# =============================================================================
# Runos-Box Docker Management Script
# 脚本描述：Linux Docker 容器管理工具
# 作者：Run-os
# 版本：1.0
# 注意：如果报错SSL错误，使用指令：wget -P /root -N --no-check-certificate https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-panel.sh && chmod 700 /root/docker-panel.sh && /root/docker-panel.sh
# =============================================================================

# 检测系统类型并设置包管理器
detect_package_manager() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            ubuntu|debian|pop|mint)
                PKG_MANAGER="apt"
                ;;
            fedora|rhel|centos|rocky|alma)
                PKG_MANAGER="dnf"
                ;;
            opensuse*|suse*)
                PKG_MANAGER="zypper"
                ;;
            alpine)
                PKG_MANAGER="apk"
                ;;
            arch|manjaro)
                PKG_MANAGER="pacman"
                ;;
            *)
                red "不支持的操作系统: $PRETTY_NAME"
                return 1
                ;;
        esac
        return 0
    else
        red "无法检测操作系统类型"
        return 1
    fi
}

detect_package_manager

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

# 获取本机IP地址（优先公网IP）
get_ip_address() {
    local public_ip
    local local_ip
    
    # 首先尝试获取公网IP
    public_ip=$(curl -s --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null)
    
    # 验证获取到的公网IP是否有效
    if [[ -n "$public_ip" ]] && [[ "$public_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$public_ip"
        return 0
    fi
    
    # 如果获取公网IP失败，则获取本地IP
    local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 2>/dev/null | awk '{print $7}' | head -1)
    
    # 验证本地IP是否有效
    if [[ -n "$local_ip" ]] && [[ "$local_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ ! "$local_ip" =~ ^127\. ]]; then
        echo "$local_ip"
        return 0
    fi
    
    # 如果都失败，返回默认值
    echo "127.0.0.1"
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
    "删除所有不使用的镜像"
    "删除所有不使用的容器"
    # =====脚本相关=====
    "更新脚本"
)

commands=(
    ["更新系统软件包"]="update_system_packages"
    ["swap修改"]="swap_modify"
    ["安装Docker"]="install_docker"
    ["删除所有不使用的镜像"]="remove_unused_images"
    ["删除所有不使用的容器"]="remove_unused_containers"
    ["更新脚本"]="update_scripts"
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
        if sudo -n true 2>/dev/null; then
            exec sudo -E "$0" "$@"
        else
            # 尝试获取密码并执行
            if sudo -v 2>/dev/null; then
                exec sudo -E "$0" "$@"
            else
                red "获取 root 权限失败，请检查密码或系统配置"
                exit 1
            fi
        fi
    fi
}

# 更新系统软件包
update_system_packages() {
    green "设置时区为 Asia/Shanghai..."
    timedatectl set-timezone Asia/Shanghai 2>/dev/null || {
        red "设置时区失败，请手动设置时区"
        yellow "尝试继续执行..."
    }
    
    green "更新系统软件包..."
    
    case "$PKG_MANAGER" in
        apt)
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
            ;;
        dnf)
            dnf check-update || true
            dnf upgrade -y || {
                red "升级系统软件包失败"
                return 1
            }
            if ! check_command curl; then
                dnf install -y curl || {
                    red "安装 curl 失败"
                    return 1
                }
            fi
            ;;
        zypper)
            zypper refresh || {
                red "刷新软件源失败"
                return 1
            }
            zypper update -y || {
                red "升级系统软件包失败"
                return 1
            }
            if ! check_command curl; then
                zypper install -y curl || {
                    red "安装 curl 失败"
                    return 1
                }
            fi
            ;;
        apk)
            apk update || {
                red "更新软件包索引失败"
                return 1
            }
            apk upgrade || {
                red "升级系统软件包失败"
                return 1
            }
            if ! check_command curl; then
                apk add curl || {
                    red "安装 curl 失败"
                    return 1
                }
            fi
            ;;
        pacman)
            pacman -Sy || {
                red "同步软件包数据库失败"
                return 1
            }
            pacman -Su --noconfirm || {
                red "升级系统软件包失败"
                return 1
            }
            if ! check_command curl; then
                pacman -S --noconfirm curl || {
                    red "安装 curl 失败"
                    return 1
                }
            fi
            ;;
        *)
            red "不支持的包管理器: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    green "系统更新完成"
}

# 删除所有不使用的镜像，并列出所有删除的镜像
remove_unused_images() {
    green "删除所有不使用的镜像..."
    docker image prune -a --force || {
        red "删除镜像失败"
        return 1
    }
    green "所有不使用的镜像已删除"
}

# 删除所有不使用的容器，并列出所有删除的容器
remove_unused_containers() {
    green "删除所有不使用的容器..."
    docker container prune -f || {
        red "删除容器失败"
        return 1
    }
    green "所有不使用的容器已删除"
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

# swap修改
swap_modify() {
    green "开始下载swap修改脚本..."
    local swap_script="/tmp/swap.sh"
    local swap_urls=(
        "https://raw.githubusercontent.com/BlueSkyXN/ChangeSource/master/swap.sh"
        "https://cdn.jsdelivr.net/gh/BlueSkyXN/ChangeSource@master/swap.sh"
        "https://ghproxy.cn/https://raw.githubusercontent.com/BlueSkyXN/ChangeSource/master/swap.sh"
    )
    
    local download_success=false
    for url in "${swap_urls[@]}"; do
        if wget -O "$swap_script" "$url" --no-check-certificate -T 30 -t 3 2>/dev/null; then
            download_success=true
            break
        fi
    done
    
    if [[ "$download_success" != "true" ]]; then
        red "下载swap脚本失败，请检查网络连接"
        return 1
    fi
    
    chmod +x "$swap_script"
    green "脚本下载完成"
    green "提示：你也可以手动运行 bash $swap_script"
    
    bash "$swap_script"
}

# 更新脚本
update_scripts() {
    green "开始更新脚本..."
    local script_url="https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-panel.sh"
    local new_script="docker-panel-new.sh"
    
    # 下载新脚本
    if wget -O "$new_script" "$script_url" --no-check-certificate -T 30 -t 5; then
        chmod +x "$new_script"
        green "脚本更新下载完成"
        
        # 备份当前脚本
        if [[ -f "docker-panel.sh" ]]; then
            cp "docker-panel.sh" "docker-panel-backup.sh"
            green "已备份当前脚本为 docker-panel-backup.sh"
        fi
        
        # 替换脚本
        mv "$new_script" "docker-panel.sh"
        green "脚本已更新，现在将执行新脚本"
        
        # 执行新脚本
        exec "./docker-panel.sh"
    else
        red "脚本更新失败，请检查网络连接"
        return 1
    fi
}

# 安装大圣的日常脚本
install_daily_scripts() {
    green "开始下载大圣的日常脚本..."
    local script_urls=(
        "https://raw.githubusercontent.com/wkdaily/zero3/main/zero3/pi.sh"
        "https://cdn.jsdelivr.net/gh/wkdaily/zero3@main/zero3/pi.sh"
        "https://ghproxy.cn/https://raw.githubusercontent.com/wkdaily/zero3/main/zero3/pi.sh"
    )
    local script_name="pi.sh"
    
    local download_success=false
    for url in "${script_urls[@]}"; do
        if wget -qO "$script_name" "$url" --no-check-certificate -T 30 -t 3 2>/dev/null; then
            download_success=true
            break
        fi
    done
    
    if [[ "$download_success" != "true" ]]; then
        red "下载脚本失败，请检查网络连接"
        return 1
    fi
    
    chmod +x "$script_name"
    green "脚本下载完成，现在将执行新脚本"
    exec "./$script_name"
}

# 显示菜单
show_menu() {
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
    clear
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

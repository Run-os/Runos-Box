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
    # =====安装1panel=====
    "更新系统软件包"
    "安装1panel面板"
    # =====1panel信息=====
    "查看1panel用户信息"
    # =====1panel管理=====
    "恢复 1Panel 服务及数据"
    "重启 1Panel 服务"
    "卸载 1Panel 服务"
    # =====脚本相关=====
    "更新脚本"
)

commands=(
    ["更新系统软件包"]="update_system_packages"
    ["安装1panel面板"]="install_1panel_on_linux"
    ["查看1panel用户信息"]="read_1panel_info"
    ["恢复 1Panel 服务及数据"]="reset_all_settings"
    ["重启 1Panel 服务"]="restart_1panel_service"
    ["卸载 1Panel 服务"]="uninstall_1panel_service"
    ["更新脚本"]="update_scripts"
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

# 恢复 1Panel 服务及数据
reset_all_settings() {
    sudo 1pctl restore
}

# 重启 1Panel 服务
restart_1panel_service(){
    sudo 1pctl restart
}

# 卸载 1Panel 服务
uninstall_1panel_service() {
    sudo 1pctl uninstall
}

# 更新自己
update_scripts() {
    wget -O 1panel-box.sh https://ghp.ci/https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/1panel-box.sh && chmod +x 1panel-box.sh && clear && ./1panel-box.sh
    echo "脚本已更新并保存在当前目录 1panel-box.sh,现在将执行新脚本。"
    ./1panel-box.sh
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

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
docker_data = "/root/data/docker_data"
memos_version = "0.20.1"

declare -a menu_options
declare -A commands
menu_options=(
  # =====Docker相关=====
  "安装Docker"
  "安装CloudDrive2"
  "安装Duplicati"
  "安装GPT-free-api"
  "安装memos"
  # =====脚本相关=====
  "更新脚本"
  "安装大圣的日常--脚本"
)

commands=(
  ["安装Docker"]="install_docker"
  ["安装CloudDrive2"]="install_clouddrive2"
  ["安装Duplicati"]="install_Duplicati"
  ["安装GPT-free-api"]="install_GPT-free-api"
  ["安装memos"]="install_memos"
  ["更新脚本"]="update_scripts"
  ["安装大圣的日常--脚本"]="install_daily_scripts"
)

# 安装Docker
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

# clouddrive2
install_clouddrive2() {
  sudo mkdir -p /etc/systemd/system/docker.service.d/
  sudo cat <<EOF >/etc/systemd/system/docker.service.d/clear_mount_propagation_flags.conf
[Service]
MountFlags=shared
EOF
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
}

# 安装GPT-free-api
install_GPT-free-api() {
  mkdir -p $docker_data/gpt-free-api
  cd $docker_data/gpt-free-api
  # 创建docker-compose文件
  cat >docker-compose.yml <<'EOL'
version: '3'
services:
# 月之暗面Kimi
  kimi-free-api:
    container_name: kimi-free-api
    image: vinlic/kimi-free-api:latest
    hostname: kimifree
    restart: always
    ports:
      - "10013:8000" #10013可以修改，8000不可以修改
    expose:
      - "8000"
    environment:
      - TZ=Asia/Shanghai
# 智谱清言GLM4
  glm-free-api:
    container_name: glm-free-api
    hostname: glmfree
    image: vinlic/glm-free-api:latest
    restart: always
    ports:
      - "10015:8000"  #10015可以修改，8000不可以修改
    expose:
      - "8000"
    environment:
      - TZ=Asia/Shanghai
# 通义千问Qwen-Max
  qwen-free-api:
    container_name: qwen-free-api
    hostname: qwenfree
    image: vinlic/qwen-free-api:latest
    restart: always
    ports:
      - "10016:8000"  #10016可以修改，8000不可以修改
    expose:
      - "8000"
    environment:
      - TZ=Asia/Shanghai
EOL
  # 启动容器
  docker-compose -f docker-compose.yml up -d
  green "GPT-free-api 安装成功，kimi: http://你的服务器IP地址:10013, glm: http://你的服务器IP地址:10015, qwen: http://你的服务器IP地址:10016"
}

# 安装memos
install_memos() {
  read -p "-----------------
  1. 安装最新版本memos
  2. 安装 $menu_options 版本的memos(适配inbox)
  请输入序号：" answer

  if [ "$answer" -eq 1 ]; then
    # 安装最新版本memos
    docker run \
      --name memos \
      -d \
      --publish 5230:5230 \
      --restart unless-stopped \
      --volume $commands/memos/:/var/opt/memos \
      neosmemo/memos --mode prod \
      --port 5230
    green "memos 安装成功，请访问 http://你的服务器IP地址:5230"
    green "注意：memos文件保存在 $commands/memos 文件夹下。"
  fi

  if [ "$answer" -eq 2 ]; then
    if docker ps --filter "name=memos" --format "{{.Names}}" | grep -q "memos"; then
      docker stop memos
      docker rm memos
      green "memos 容器已存在，已停止并删除原容器"
    else
      green "memos 容器不存在，可以安装"
    fi
    # 安装适配inbox的memos版本
    green "正在拉取 $menu_options 版本的memos镜像..."
    docker run \
      --name memos \
      -d \
      --publish 5230:5230 \
      --restart unless-stopped \
      --volume $commands/memos/:/var/opt/memos \
      neosmemo/memos:$menu_options \
      --port 5230
    green "memos $menu_options 安装成功，请访问 http://你的服务器IP地址:5230"
    green "注意：memos文件保存在 $commands/memos 文件夹下。"
  fi
}

# 安装大圣的日常--脚本
install_dashen_scripts() {
  # 下载脚本
  wget -qO pi.sh https://cafe.cpolar.cn/wkdaily/zero3/raw/branch/main/zero3/pi.sh && chmod +x pi.sh && ./pi.sh
  green "脚本已经下载到当前目录，现在将执行新脚本。"
  ./pi.sh
  exit 0
}

# 更新自己
update_scripts() {
  wget -O docker-start.sh https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-start.sh && chmod +x docker-start.sh && clear && ./docker-start.sh
  echo "脚本已更新并保存在当前目录 docker-start.sh,现在将执行新脚本。"
  ./docker-start.sh
  exit 0
}

show_menu() {
  clear
  greenline "————————————————————————————————————————————————————"
  red " Runos-Box Linux Supported ONLY"
  green " FROM: https://github.com/Run-os/Runos-Box "
  green " USE:  wget -O docker-start.sh https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-start.sh && chmod +x docker-start.sh && clear && ./docker-start.sh"
  greenline "————————————————————————————————————————————————————"
  echo "请选择操作："

  # 特殊处理的项数组
  special_items=("安装Docker" "更新脚本")
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

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
  docker run \
    --name memos \
    --publish 5230:5230 \
    --volume /root/.memos/:/var/opt/memos \
    neosmemo/memos --mode prod \
    --port 5230
  green "memos 安装成功，请访问 http://你的服务器IP地址:5230"
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
  wget -O docker-start.sh https://github.moeyy.xyz/https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-start.sh && chmod +x docker-start.sh && clear && ./docker-start.sh
  echo "脚本已更新并保存在当前目录 docker-start.sh,现在将执行新脚本。"
  ./docker-start.sh
  exit 0
}

#主菜单
function start_menu() {
  clear
  red " Runos-Box Docker-start Linux Supported ONLY"
  green " FROM: https://github.com/Run-os/Runos-Box "
  green " USE:  wget -O docker-start.sh https://github.moeyy.xyz/https://raw.githubusercontent.com/Run-os/Runos-Box/main/Docker/docker-start.sh && chmod +x docker-start.sh && clear && ./docker-start.sh "
  yellow " =================================================="
  green " 1. 安装Docker"
  green " 2. 安装clouddrive2"
  green " 3. 安装Duplicati"
  green " 4. 安装GPT-free-api"
  green " 5. 安装memos"
  yellow " --------------------------------------------------"
  green " 6. 安装大圣的日常--脚本"
  green " 7. 更新脚本"
  green " =================================================="
  green " 0. 退出脚本"
  echo
  read -p "请输入数字:" menuNumberInput
  case "$menuNumberInput" in
  1)
    install_docker
    start_menu
    ;;
  2)
    install_clouddrive2
    start_menu
    ;;
  3)
    install_Duplicati
    start_menu
    ;;
  4)
    install_GPT-free-api
    start_menu
    ;;
  5)
    install_memos
    start_menu
    ;;

  6)
    install_dashen_scripts
    start_menu
    ;;
  7)
    update_scripts
    start_menu
    ;;
  0)
    exit 1
    ;;
  *)
    clear
    red "请输入正确数字 !"
    start_menu
    ;;
  esac
}
start_menu "first"

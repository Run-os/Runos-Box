# 定义颜色输出函数
red() { echo -e "\033[31m\033[01m[WARNING] $1\033[0m"; }
green() { echo -e "\033[32m\033[01m[INFO] $1\033[0m"; }
greenline() { echo -e "\033[32m\033[01m $1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m[NOTICE] $1\033[0m"; }
blue() { echo -e "\033[34m\033[01m[MESSAGE] $1\033[0m"; }
light_magenta() { echo -e "\033[95m\033[01m[NOTICE] $1\033[0m"; }
highlight() { echo -e "\033[32m\033[01m$1\033[0m"; }
cyan() { echo -e "\033[38;2;0;255;255m$1\033[0m"; }
# 单引号

docker_data = "/root/data/docker_data"
memos_version = "0.20.1"

variable="Hello World"
green '$variable' # 输出:$variable

# 双引号
green "$variable" # 输出: Hello World

    green "memos $memos_version 安装成功，请访问 http://你的服务器IP地址:5230"
    echo " 注意：memos文件保存在 " + "$docker_data" + "/roor/data/docker_data/memos/ 文件夹下。"



#!/bin/bash

# 设置终端颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

num_processes=$(ps -elf | grep app.py | grep python3 | awk '{print $4}' | wc -l)

if [ $num_processes -gt 0 ]; then
    echo -e "${GREEN}程序'app.py'的数量为: $num_processes ${PLAIN}"
    echo -e "现在开始关闭程序"
    for pid in $(ps -elf | grep app.py | grep python3 | awk '{print $4}'); do
        echo -e "正在关闭进程 $pid "
        kill -9 $pid
    done
    echo -e "${GREEN}程序'app.py'已关闭 ${PLAIN}"
else
    echo -e "${RED}程序'app.py'未运行 ${PLAIN}"
fi
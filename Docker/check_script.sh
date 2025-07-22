#!/bin/bash

# 简单的脚本验证工具

echo "🔍 开始检查 docker-box.sh 脚本..."

# 检查脚本是否存在
if [[ ! -f "docker-box.sh" ]]; then
    echo "❌ docker-box.sh 文件不存在"
    exit 1
fi

echo "✅ 脚本文件存在"

# 检查shebang
if head -1 docker-box.sh | grep -q "#!/bin/bash"; then
    echo "✅ shebang 正确"
else
    echo "❌ shebang 错误或缺失"
fi

# 检查基本函数定义
functions_to_check=(
    "update_system_packages"
    "install_docker"
    "install_1panel_on_linux"
    "read_1panel_info"
    "install_clouddrive2"
    "install_duplicati"
    "install_memos"
    "install_sun_panel"
    "install_freshrss"
    "install_nginx"
    "install_nginx_proxy_manager"
    "configure_openai_groq_reverse_proxy"
    "swap_modify"
    "update_scripts"
    "install_daily_scripts"
)

echo "🔍 检查函数定义..."
missing_functions=0

for func in "${functions_to_check[@]}"; do
    if grep -q "^${func}()" docker-box.sh; then
        echo "✅ $func 已定义"
    else
        echo "❌ $func 未找到"
        ((missing_functions++))
    fi
done

if [[ $missing_functions -eq 0 ]]; then
    echo "✅ 所有必需函数都已定义"
else
    echo "❌ 有 $missing_functions 个函数缺失"
fi

# 检查变量定义
echo "🔍 检查关键变量..."
if grep -q "DOCKER_DATA=" docker-box.sh; then
    echo "✅ DOCKER_DATA 变量已定义"
else
    echo "❌ DOCKER_DATA 变量未定义"
fi

if grep -q "IP_ADDRESS=" docker-box.sh; then
    echo "✅ IP_ADDRESS 变量已定义"
else
    echo "❌ IP_ADDRESS 变量未定义"
fi

# 检查颜色函数
echo "🔍 检查颜色函数..."
color_functions=("red" "green" "yellow" "blue")
for func in "${color_functions[@]}"; do
    if grep -q "^${func}()" docker-box.sh; then
        echo "✅ $func 颜色函数已定义"
    else
        echo "❌ $func 颜色函数未定义"
    fi
done

echo "🎉 脚本检查完成！"

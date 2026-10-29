#!/bin/sh

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查root权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then 
        printf "${RED}请以root用户运行此脚本（使用 su - 或 sudo ./init.sh）${NC}\n"
        exit 1
    fi
}

# 通用的安装函数
install_component() {
    name="$1"           # 组件名称
    check_cmd="$2"      # 检查命令
    install_cmd="$3"    # 安装命令
    post_cmd="$4"       # 安装后的额外命令（可选）
    
    # 处理install_cmd中的GitHub URL
    if [ -n "$GITHUB_PROXY" ]; then
        printf "${YELLOW}使用GitHub代理: ${GITHUB_PROXY}${NC}\n"
        # 移除末尾的斜杠（如果有）
        proxy_url=$(echo "$GITHUB_PROXY" | sed 's/\/$//')
        # 使用sed替换install_cmd中的GitHub URL
        install_cmd=$(echo "$install_cmd" | sed "s|https://github.com|${proxy_url}/https://github.com|g")
    fi
    
    printf "检查%s...\n" "$name"
    if ! eval "$check_cmd" > /dev/null 2>&1; then
        printf "${YELLOW}正在安装%s...${NC}\n" "$name"
        eval "$install_cmd"
        if [ $? -ne 0 ]; then
            printf "${RED}%s安装失败${NC}\n" "$name"
            return 1
        fi
        
        if [ -n "$post_cmd" ]; then
            eval "$post_cmd"
            if [ $? -ne 0 ]; then
                printf "${RED}%s后续配置失败${NC}\n" "$name"
                return 1
            fi
        fi
        
        printf "${GREEN}%s安装成功${NC}\n" "$name"
    else
        printf "${GREEN}%s已安装${NC}\n" "$name"
    fi
}

# 通用的版本检查函数
show_component_version() {
    name="$1"           # 组件名称
    check_cmd="$2"      # 检查命令
    version_cmd="$3"    # 获取版本的命令
    
    printf "\n%s：\n" "$name"
    if eval "$check_cmd" > /dev/null 2>&1; then
        if [ -n "$version_cmd" ]; then
            printf "${GREEN}%s${NC}\n" "$(eval "$version_cmd")"
        else
            printf "${GREEN}已安装${NC}\n"
        fi
    else
        printf "${RED}未安装或安装失败${NC}\n"
    fi
} 
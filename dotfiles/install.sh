#!/bin/sh

# 导入工具函数
. "$(dirname "$0")/utils.sh"


# 基础工具安装和检查
install_basic_tools() {
    printf "检查基础开发工具...\n"
    need_install=false
    
    if ! command -v gcc > /dev/null 2>&1; then
        need_install=true
    fi
    if ! command -v cmake > /dev/null 2>&1; then
        need_install=true
    fi
    
    if [ "$need_install" = true ]; then
        printf "${YELLOW}正在安装基础开发工具...${NC}\n"
        apt-get update
        apt-get install -y build-essential curl git cmake autoconf libtool pkg-config vim google-perftools
        if [ $? -ne 0 ]; then
            printf "${RED}基础开发工具安装失败${NC}\n"
            return 1
        fi
        printf "${GREEN}基础开发工具安装成功${NC}\n"
    else
        printf "${GREEN}基础开发工具已安装${NC}\n"
    fi
}

install_tools(){

    # 安装 Python3
    install_component "Python3" \
        "command -v python3" \
        "apt-get install -y python3 python3-pip"


    # 安装 fzf
    install_component "fzf" \
        "command -v fzf" \
        "apt-get install -y fzf"

    # 安装 mlr
    install_component "mlr" \
        "command -v mlr" \
        "apt-get install -y miller"

    # 安装 jq
    install_component "jq" \
        "command -v jq" \
        "apt-get install -y jq"

    # Bazel安装和检查
    install_component "Bazel" \
        "command -v bazel" \
        "apt install -y apt-transport-https curl gnupg && \
         cat configs/bazel-release.pub.gpg | gpg --dearmor -o /usr/share/keyrings/bazel-archive-keyring.gpg &&\
         cat configs/bazel.list | tee /etc/apt/sources.list.d/bazel.list && \
         apt update && apt install -y bazel"

    # gRPC安装和检查
    install_component "gRPC" \
        "command -v protoc" \
        "apt-get install -y libgrpc++-dev libgrpc-dev protobuf-compiler-grpc libprotobuf-dev"

    # GoogleTest安装和检查
    install_component "GoogleTest" \
        "[ -f /usr/lib/libgtest.a ] && [ -f /usr/lib/libgtest_main.a ]" \
        "apt-get install -y libgtest-dev" \
        "cd /usr/src/gtest && cmake CMakeLists.txt && make && cp lib/*.a /usr/lib"
}

# 显示安装结果
show_versions() {
    printf "\n----------------------------------------\n"
    printf "安装结果汇总：\n"

    # 检查GCC
    show_component_version "GCC版本" \
        "command -v gcc" \
        "gcc --version | head -n1"

    # 检查CMake
    show_component_version "CMake版本" \
        "command -v cmake" \
        "cmake --version | head -n1"

    # 检查Bazel
    show_component_version "Bazel版本" \
        "command -v bazel" \
        "bazel --version"

    # 检查Protoc
    show_component_version "Protoc版本" \
        "command -v protoc" \
        "protoc --version"

    # 检查GoogleTest
    show_component_version "GoogleTest状态" \
        "[ -f /usr/lib/libgtest.a ] && [ -f /usr/lib/libgtest_main.a ]"

    # 检查 fzf
    show_component_version "fzf状态" \
        "command -v fzf" \
        "fzf --version"

    # 检查 mlr
    show_component_version "mlr状态" \
        "command -v mlr" \
        "mlr --version"

    # 检查 jq
    show_component_version "jq状态" \
        "command -v jq" \
        "jq --version"

    # 检查 Python3
    show_component_version "Python3状态" \
        "command -v python3" \
        "python3 --version"
}

main() {
    check_root
    
    # 记录安装状态
    install_status=true
    
    # 安装基础开发工具
    install_basic_tools || install_status=false
    
    # 安装所有其他工具
    install_tools || install_status=false
    
    # 显示最终结果
    show_versions
    
    # 输出总体状态
    printf "\n----------------------------------------\n"
    if [ "$install_status" = true ]; then
        printf "${GREEN}✅ 所有组件安装成功${NC}\n"
        exit 0
    else
        printf "${RED}❌ 部分组件安装失败，请检查上述输出${NC}\n"
        exit 1
    fi
}

main

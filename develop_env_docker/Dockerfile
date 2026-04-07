# 构建方式: docker build --build-arg USERNAME=$(whoami) --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t myenv .

FROM ubuntu:24.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装 GCC 13、CMake 3.22+、Make、Python 3.12、Go 1.23、GDB
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    wget \
    git \
    git-lfs \
    vim \
    rsync \
    jq \
    g++-13 \
    gcc-13 \
    make \
    cmake \
    gdb \
    gnupg2 \
    python3.12 \
    python3.12-dev \
    python3-pip \
    zsh \
    unzip \
    lsof \
    nload \
    htop \
    net-tools \
    dnsutils \
    openssh-server \
    docker.io \
    docker-compose \
    tmux \
    && ln -sf /usr/bin/python3.12 /usr/bin/python3 \
    && ln -sf /usr/bin/g++-13 /usr/bin/g++ \
    && ln -sf /usr/bin/gcc-13 /usr/bin/gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 Go 1.23
RUN wget -q https://go.dev/dl/go1.23.0.linux-amd64.tar.gz -O /tmp/go.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz \
    && ln -sf /usr/local/go/bin/go /usr/bin/go

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 用 npm 全局安装 claude-code，替代 apt 源安装
# 配置 npm 镜像源，再安装 claude-code
RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g @anthropic-ai/claude-code

# 配置 Git LFS（全局）
RUN git lfs install --system

# 创建用户（提前创建，以便后续配置同时生效）
ARG UID=1000
ARG GID=1000
ARG USERNAME=user
RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${USERNAME} -s /usr/bin/zsh ${USERNAME}

# DRY_RUN=1 跳过实际安装（输出伪成功），用于快速验证 Dockerfile 层结构
ARG DRY_RUN=0

# 拷贝调度脚本（独立层，脚本不变时不会触发后续重建）
COPY init-runner.sh /tmp/init-runner.sh
RUN chmod +x /tmp/init-runner.sh

# 每个步骤独立 COPY + RUN 层：
#   - 只有当对应脚本文件内容改变时，该层及之后的层才会重新构建
#   - 已调试通的步骤在 build cache 中，调试后续步骤时不会重复执行

COPY init.d/01_install_code_server.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/01_install_code_server.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 01

COPY init.d/02_install_extensions.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/02_install_extensions.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 02

COPY init.d/03_configure_git.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/03_configure_git.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 03

COPY init.d/04_install_oh_my_zsh.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/04_install_oh_my_zsh.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 04

COPY init.d/05_install_zsh_plugins.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/05_install_zsh_plugins.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 05

COPY init.d/06_configure_zshrc.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/06_configure_zshrc.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 06

COPY init.d/07_install_nvm_node.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/07_install_nvm_node.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 07

COPY init.d/08_fix_permissions.sh /tmp/init.d/
RUN chmod +x /tmp/init.d/08_fix_permissions.sh \
    && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} 08 \
    && rm -rf /tmp/init-runner.sh /tmp/init.d

# 设置字符集
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

# 切换到 ${USERNAME} 用户，连接后默认以该用户登录
USER ${USERNAME}
WORKDIR /home/${USERNAME}/workspace

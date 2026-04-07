# develop_env_docker

构建开发环境 Docker 镜像的全套脚本。

## 快速开始

### 启动容器


```bash
#在宿主机上拉取构建好的镜像,UID在构建镜像时对齐
docker pull docker.cnb.cool/miojizzy/develop-env/develop-env:latest-work

# 指定用户和挂载目录启动
USER="user"
NAME="dev"
docker run -it \
    --user ${USER} \
    --name ${NAME} \
    -v $(pwd)/proj:/home/${USER}/ \
    docker.cnb.cool/miojizzy/develop-env/develop-env:latest-work \
    /bin/zsh
```


## 文件结构

```
develop_env_docker/
├── Dockerfile            # 镜像定义，每个 init 步骤独立一层以利用构建缓存
├── build.sh              # 一键构建并推送镜像
├── init-runner.sh        # 初始化步骤调度器，支持按步骤过滤和 DRY_RUN 模式
└── init.d/               # 各安装步骤脚本，按序号顺序执行
    ├── 01_install_code_server.sh
    ├── 02_install_extensions.sh
    ├── 03_configure_git.sh
    ├── 04_install_oh_my_zsh.sh
    ├── 05_install_zsh_plugins.sh
    ├── 06_configure_zshrc.sh
    ├── 07_install_nvm_node.sh
    └── 08_fix_permissions.sh
```

## 构建镜像

> **Agent 注意**：执行构建前，必须先向用户询问以下三个参数，不得使用默认值直接运行：
> - `username`：容器内的用户名
> - `uid`：容器内用户的 UID
> - `gid`：容器内用户的 GID

### 正式构建

```bash
./build.sh <username> <uid> <gid>

# 示例
./build.sh yourname 1000 1000
```

脚本会构建镜像并自动 `docker push` 到 `docker.cnb.cool/miojizzy/develop-env:latest`。

也可以直接调用 docker build：

```bash
docker build \
  --network=host \
  --build-arg USERNAME=yourname \
  --build-arg UID=1000 \
  --build-arg GID=1000 \
  -t develop-env:latest .
```

## 调试构建

### DRY_RUN 模式

所有 `init.d/` 脚本都支持 `DRY_RUN=1` 环境变量。设置后各步骤仅打印一行提示即退出，
用于快速验证 Dockerfile 层结构是否正确，整个构建只需约 1 分钟（apt/go/node 层走缓存后更快）。

```bash
docker build \
  --network=host \
  --build-arg USERNAME=yourname \
  --build-arg UID=1000 \
  --build-arg GID=1000 \
  --build-arg DRY_RUN=1 \
  -t develop-env:dryrun .
```

### 利用构建缓存调试单个步骤

每个 `init.d/` 脚本对应 Dockerfile 中独立的 `COPY + RUN` 层。当你修改某个步骤的脚本后，
只有该层及之后的层会重新构建，之前已通过的步骤全部走缓存。

**调试流程示例：正在调试第 07 步**

1. 先用 DRY_RUN 建立完整缓存（只需做一次）：
   ```bash
   docker build --build-arg DRY_RUN=1 --build-arg USERNAME=yourname --build-arg UID=1000 --build-arg GID=1000 -t develop-env:dryrun .
   ```

2. 修改 `init.d/07_install_nvm_node.sh`

3. 不加 `--no-cache` 重新构建，步骤 01-06 走缓存，只有 07-08 真正执行：
   ```bash
   docker build --network=host --build-arg USERNAME=yourname --build-arg UID=1000 --build-arg GID=1000 -t develop-env:debug .
   ```

> **注意**：正式构建（`build.sh`）使用 `--no-cache` 以保证产物干净，不受缓存影响。

### init-runner.sh 用法

调度器支持按步骤前缀过滤，也支持逗号分隔指定多个步骤。构建时通过 Dockerfile ARG 自动传入，
一般不需要手动调用，但在容器内调试时可以直接运行：

```bash
# 只运行第 07 步
DRY_RUN=0 /tmp/init-runner.sh yourname 07

# 运行多个步骤
DRY_RUN=0 /tmp/init-runner.sh yourname 07,08

# 运行全部步骤
DRY_RUN=0 /tmp/init-runner.sh yourname all
```

## 初始化步骤说明

| 步骤 | 脚本 | 说明 |
|------|------|------|
| 01 | `01_install_code_server.sh` | 安装 code-server（优先官方 installer，失败则 deb 包） |
| 02 | `02_install_extensions.sh` | 为 root 和目标用户安装 code-server 扩展 |
| 03 | `03_configure_git.sh` | 配置 git 全局参数（postBuffer、超时等） |
| 04 | `04_install_oh_my_zsh.sh` | 安装 Oh My Zsh（多镜像 fallback） |
| 05 | `05_install_zsh_plugins.sh` | 克隆 zsh-autosuggestions、zsh-syntax-highlighting |
| 06 | `06_configure_zshrc.sh` | 写入 .zshrc 配置块 |
| 07 | `07_install_nvm_node.sh` | 安装 nvm 及 Node.js 24，全局安装 copilot-api |
| 08 | `08_fix_permissions.sh` | 修正 home 目录权限，设置 zsh 为默认 shell |

## 新增安装步骤

1. 在 `init.d/` 下新建脚本，命名规则 `NN_描述.sh`（两位数字序号）
2. 脚本开头加入标准头：
   ```bash
   #!/bin/bash
   set -euo pipefail
   USERNAME="$1"
   echo "[NN] 步骤描述"
   DRY_RUN="${DRY_RUN:-0}"
   if [ "$DRY_RUN" = "1" ]; then echo "[NN] DRY_RUN: skip"; exit 0; fi
   ```
3. 在 `Dockerfile` 中对应位置追加：
   ```dockerfile
   COPY init.d/NN_描述.sh /tmp/init.d/
   RUN chmod +x /tmp/init.d/NN_描述.sh \
       && DRY_RUN=${DRY_RUN} /tmp/init-runner.sh ${USERNAME} NN
   ```

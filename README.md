# develop-env

个人开发环境仓库：**Docker 开发镜像构建** + **dotfiles 配置**，GitHub 与 CNB 双向同步。

## 目录结构

```
develop_env_docker/   # 开发环境 Docker 镜像构建（CNB 流水线自动构建推送）
dotfiles/             # 机器初始化配置（bashrc / vimrc / gitconfig / gdbinit 等）
  ├── configs/        # 配置文件本体
  ├── setup_configs.sh  # 把 configs 追加到 /root 下的对应 dotfile
  ├── install.sh      # 常用开发工具安装（Python3、Go 等）
  └── utils.sh        # install.sh 的工具函数
legacy/               # 历史遗留（原 env_setup 的 backup/，仅存档）
```

## Docker 镜像

push 到 `main` 且 **`develop_env_docker/` 有变更**时，CNB 流水线自动构建并推送两个镜像到
`docker.cnb.cool/miojizzy/develop-env`：

| tag | 用途 | UID/GID |
|---|---|---|
| `latest-work` | 工作机 | 63676 |
| `latest-life` | 生活机（NAS） | 1001 |

也可本地手动构建：

```bash
cd develop_env_docker
./build.sh username uid gid
```

镜像内容：Ubuntu 24.04 + GCC 13 / CMake / GDB、Python 3.12、Go 1.23、Node.js 24（nvm）、
Git LFS、Vim、Docker、code-server、Zsh + Oh My Zsh。详见 `develop_env_docker/README.md`。

## dotfiles 使用（新机器初始化）

```bash
git clone <本仓库> && cd develop-env/dotfiles
sh setup_configs.sh   # 追加 bashrc/vimrc/gitconfig/gdbinit 到 /root
sh install.sh         # 安装常用开发工具
```

> 脚本假定以 root 运行、配置追加到 `/root/.*`（沿用原 env_setup 的行为）。
> `setup_configs.sh` 幂等：检测到 `/root/bin` 已写入 `.bashrc` 就跳过。

## GitHub ↔ CNB 双向同步

与 `auto-ss-server` 相同的方案，基于官方
[`tencentcom/git-sync`](https://cnb.cool/cnb/plugins/tencentcom/git-sync) 插件：

- **GitHub → CNB**：`.github/workflows/sync-to-cnb.yml`，push 到 `main` 触发
- **CNB → GitHub**：`.cnb.yml` 的 `sync-github` 流水线，push 到 `main` 触发；
  `GITHUB_TOKEN` 从密钥仓库 `miojizzy/secrets` 导入

要点：

- 插件不改写提交，**两边 commit SHA 恒等**，可直接 `git rev-parse` 对比
- 双向都**非强推**：真分叉时同步失败变红，需要人工决定保留哪边，不会静默覆盖
- 幂等防循环：对端已有相同 SHA 时输出 `Everything up-to-date`，不再触发下一轮
- 只同步 `main`；tag 与其他分支不同步
- **不要给插件设置 `force`**：`PLUGIN_FORCE` 非空即强推（`"false"` 也算）

> ⚠️ 本仓库两边都应为 **private**（dotfiles 可能含个人环境信息）。

# develop-env

用于构建和发布团队开发环境 Docker 镜像的工具集。

## 快速开始

```bash
cd develop_env_docker
./build.sh username uid gid
```

构建完成后镜像会自动推送到镜像仓库 `docker.cnb.cool/miojizzy/develop-env:latest`。

## 目录结构

```
develop_env_docker/   # 镜像构建相关文件，详见其中的 README.md
```

## 镜像内容

基础系统 Ubuntu 24.04，预装：

- 编译工具：GCC 13、G++ 13、Make、CMake、GDB
- 语言运行时：Python 3.12、Go 1.23、Node.js 24（via nvm）
- 开发工具：Git、Git LFS、Vim、Docker、code-server
- Shell：Zsh + Oh My Zsh + 常用插件

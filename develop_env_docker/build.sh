#!/bin/bash
set -e

# 用法: ./build.sh [username] [uid] [gid]
IMAGE_NAME="docker.cnb.cool/miojizzy/develop-env"
TAG="latest"
USERNAME=${1:-$(whoami)}
UID_VAL=${2:-$(id -u)}
GID_VAL=${3:-$(id -g)}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 开始构建镜像: ${IMAGE_NAME}:${TAG}"
echo "    用户名: ${USERNAME} (uid=${UID_VAL}, gid=${GID_VAL})"

docker build \
    --no-cache \
    --network=host \
    --build-arg USERNAME="${USERNAME}" \
    --build-arg UID="${UID_VAL}" \
    --build-arg GID="${GID_VAL}" \
    -t "${IMAGE_NAME}:${TAG}" \
    "${SCRIPT_DIR}"

echo "==> 构建完成: ${IMAGE_NAME}:${TAG}"
echo "    运行示例: docker run -it --rm ${IMAGE_NAME}:${TAG}"

docker push "${IMAGE_NAME}:${TAG}"
echo "==> 镜像已推送到仓库: ${IMAGE_NAME}:${TAG}"
#!/bin/bash
set -e

USERNAME=$1
if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# Temporary working dir for downloaded installers
TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

# 安装 code-server
curl -fsSL https://code-server.dev/install.sh | sh || true

EXTENSIONS=(
    "cnbcool.cnb-welcome"
    "tencent-cloud.coding-copilot"
    "ms-vscode.cmake-tools"
)

GIT_CONFIGS=(
    "http.postBuffer 524288000"
    "http.lowSpeedLimit 0"
    "http.lowSpeedTime 999999"
)

# 尝试多个镜像，按优先级
GITHUB_MIRRORS=(
    "https://mirror.ghproxy.com/https://github.com"
    "https://gitclone.com/github.com"
    "https://github.com"
)

clone_with_mirror() {
    local repo=$1   # e.g. zsh-users/zsh-autosuggestions
    local dest=$2
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        echo "Trying mirror: ${mirror}"
        if git clone --depth=1 "${mirror}/${repo}" "${dest}"; then
            echo "Cloned ${repo} from ${mirror}"
            return 0
        fi
        rm -rf "${dest}"
    done
    echo "Warning: All mirrors failed for ${repo}, continuing"
    return 0
}

# Installer URL lists (try multiple fallbacks)
OMZ_URLS=(
    "https://ghproxy.com/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    "https://mirror.ghproxy.com/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
)

NVM_VERSION="v0.40.3"
NODE_VERSION="24"
NVM_URLS=(
    "https://ghproxy.com/https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
    "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
)

for USER_HOME in "/root" "/home/${USERNAME}"; do
    USER_NAME=$(basename "${USER_HOME}")
    [ "${USER_NAME}" = "root" ] && RUN_AS="bash -c" || RUN_AS="su - ${USER_NAME} -c"

    # 安装 code-server 扩展（若 code-server 可用）
    if command -v code-server >/dev/null 2>&1; then
        for EXT in "${EXTENSIONS[@]}"; do
            ${RUN_AS} "code-server --install-extension ${EXT} || true"
        done
    else
        echo "code-server not found, skipping extension installs for ${USER_NAME}"
    fi

    # 配置 git
    for CFG in "${GIT_CONFIGS[@]}"; do
        ${RUN_AS} "git config --global ${CFG} || true"
    done

    # 安装 Oh My Zsh：尝试多个 URL
    OMZ_SCRIPT="${TMPDIR}/omz_install.sh"
    for url in "${OMZ_URLS[@]}"; do
        echo "Trying Oh My Zsh installer: ${url}"
        if curl -fsSL "${url}" -o "${OMZ_SCRIPT}"; then
            if [ "${USER_NAME}" = "root" ]; then
                bash "${OMZ_SCRIPT}" --unattended || true
            else
                su - "${USER_NAME}" -c "bash ${OMZ_SCRIPT} --unattended" || true
            fi
            break
        else
            echo "Failed to download Oh My Zsh installer from ${url}"
        fi
    done

    # 安装 zsh 插件（使用镜像），失败不致命
    clone_with_mirror "zsh-users/zsh-autosuggestions" \
        "${USER_HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" || true
    clone_with_mirror "zsh-users/zsh-syntax-highlighting" \
        "${USER_HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" || true

    # 配置 .zshrc
    mkdir -p "${USER_HOME}/.oh-my-zsh/completions"
    echo 'setopt NO_AUTO_REMOVE_SLASH' >> "${USER_HOME}/.zshrc"
    sed -i '1isetopt NULL_GLOB 2>/dev/null\nsource /etc/profile\nunsetopt NULL_GLOB 2>/dev/null\nif command -v docker > /dev/null; then\n    docker completion zsh > ~/.oh-my-zsh/completions/_docker\nfi' \
        "${USER_HOME}/.zshrc" || true

    # 安装 nvm：尝试多个 URL，且只在成功安装后才 source 和使用 nvm
    NVM_SCRIPT="${TMPDIR}/nvm_install.sh"
    for url in "${NVM_URLS[@]}"; do
        echo "Trying NVM installer: ${url}"
        if curl -fsSL "${url}" -o "${NVM_SCRIPT}"; then
            if [ "${USER_NAME}" = "root" ]; then
                bash "${NVM_SCRIPT}" || true
            else
                su - "${USER_NAME}" -c "bash ${NVM_SCRIPT}" || true
            fi
            break
        else
            echo "Failed to download NVM installer from ${url}"
        fi
    done

    # 仅在 nvm 安装成功时执行后续 nvm/npm 操作
    if [ "${USER_NAME}" = "root" ]; then
        export NVM_DIR="/root/.nvm"
        if [ -s "${NVM_DIR}/nvm.sh" ]; then
            # shellcheck disable=SC1090
            source "${NVM_DIR}/nvm.sh"
            nvm install "${NODE_VERSION}" || true
            nvm alias default "${NODE_VERSION}" || true
            npm install -g @hsupu/copilot-api || true
        else
            echo "nvm not installed for root; skipping Node/npm steps"
        fi
    else
        # run as the user in a login shell so $HOME is correct
        su - "${USER_NAME}" -c "bash -lc 'export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && source \"\$NVM_DIR/nvm.sh\" && nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION} && npm install -g @hsupu/copilot-api'" || true
    fi

    # 配置 .zshrc（在已有 sed 之后追加 nvm 初始化）
    cat >> "${USER_HOME}/.zshrc" << 'EOF'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
EOF

    # 修正权限（仅对存在的路径操作）
    if [ "${USER_NAME}" != "root" ]; then
        for p in "${USER_HOME}/.oh-my-zsh" "${USER_HOME}/.zshrc" "${USER_HOME}/.nvm"; do
            if [ -e "${p}" ]; then
                chown -R "${USER_NAME}:${USER_NAME}" "${p}" || true
            fi
        done
    fi
done

chsh -s "$(which zsh)" root || true
chsh -s "$(which zsh)" "${USERNAME}" || true

echo "Init done for root and ${USERNAME}"

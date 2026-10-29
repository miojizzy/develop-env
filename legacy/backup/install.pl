#!/usr/bin/perl

use strict;
use warnings;
use lib '.';  # 确保能找到当前目录下的模块
use ComponentManager;

# 注册基础开发工具
register(
    "basic_tools",
    "apt-get install -y build-essential curl git cmake autoconf libtool pkg-config",
    "command -v gcc && command -v cmake",
    undef,
    "apt-get remove -y build-essential curl git cmake autoconf libtool pkg-config"
);

# 注册 Git
register(
    "git",
    "apt-get install -y git",
    "which git",
    undef,
    "apt-get remove -y git"
);

# 注册 Docker
register(
    "docker",
    "apt-get install -y docker.io",
    "which docker",
    "systemctl start docker",
    "apt-get remove -y docker.io"
);

# 注册 Node.js
register(
    "nodejs",
    "apt-get install -y nodejs",
    "which node",
    "npm install -g yarn",
    "apt-get remove -y nodejs"
);

# 注册 gRPC
register(
    "grpc",
    "apt-get install -y libgrpc++-dev libgrpc-dev protobuf-compiler-grpc libprotobuf-dev",
    "command -v protoc",
    undef,
    "apt-get remove -y libgrpc++-dev libgrpc-dev protobuf-compiler-grpc libprotobuf-dev"
);

# 注册 Google Test
register(
    "gtest",
    "apt-get install -y libgtest-dev",
    "[ -f /usr/lib/libgtest.a ] && [ -f /usr/lib/libgtest_main.a ]",
    "cd /usr/src/gtest && cmake . && make && cp lib/*.a /usr/lib",
    "apt-get remove -y libgtest-dev"
);

# 注册 Bazel
register(
    "bazel",
    "apt-get install -y wget apt-transport-https && wget https://github.com/bazelbuild/bazel/releases/download/6.4.0/bazel_6.4.0-linux-x86_64.deb && dpkg -i bazel_6.4.0-linux-x86_64.deb || apt-get install -f -y && rm -f bazel_6.4.0-linux-x86_64.deb",
    "command -v bazel",
    undef,
    "apt-get remove -y bazel"
);

# 根据命令行参数决定安装还是卸载
if (@ARGV && $ARGV[0] eq "uninstall") {
    uninstall();
} else {
    install();
} 
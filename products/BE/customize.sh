#!/usr/bin/env bash
# 产品定制：在 feeds 安装完成之后、加载 .config 之前，于 OpenWrt 源码根目录执行。
set -euo pipefail

# Argon 主题
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

#!/usr/bin/env bash
# 产品定制：在 feeds 安装完成之后、加载 .config 之前，于 OpenWrt 源码根目录执行。
# 第三方仓库 clone 到 package/（软件包）或 tmp/sources/（只用其中的脚本），release 说明会记录它们的提交。
set -euo pipefail

# Argon 主题
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

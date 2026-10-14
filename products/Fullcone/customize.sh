#!/usr/bin/env bash
# 产品定制：在 feeds 安装完成之后、加载 .config 之前，于 OpenWrt 源码根目录执行。
# 第三方仓库 clone 到 package/（软件包）或 tmp/sources/（只用其中的脚本），release 说明会记录它们的提交。
set -euo pipefail

# Turbo ACC（chenmozhijin 版，不含 SFE）
git clone --depth 1 --branch luci https://github.com/chenmozhijin/turboacc.git tmp/sources/turboacc
bash tmp/sources/turboacc/add_turboacc.sh --no-sfe

# Argon 主题
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# 流量统计
git clone --depth 1 https://github.com/brvphoenix/wrtbwmon.git package/wrtbwmon
git clone --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon.git package/luci-app-wrtbwmon

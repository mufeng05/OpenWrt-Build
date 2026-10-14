#!/usr/bin/env bash
# 产品定制：在 feeds 安装完成之后、加载 .config 之前，于 OpenWrt 源码根目录执行。
set -euo pipefail

# Turbo ACC（chenmozhijin 版，不含 SFE）
curl -fsSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh
bash add_turboacc.sh --no-sfe

# Argon 主题
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# 流量统计
git clone --depth 1 https://github.com/brvphoenix/wrtbwmon.git package/wrtbwmon
git clone --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon.git package/luci-app-wrtbwmon

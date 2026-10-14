#!/usr/bin/env bash
# 产品定制：在 feeds 安装完成之后、加载 .config 之前，于 OpenWrt 源码根目录执行。
# 第三方仓库 clone 到 package/（软件包）或 tmp/sources/（只用其中的脚本），release 说明会记录它们的提交。
set -euo pipefail

# SONiC 全锥形 NAT
git clone --depth 1 https://github.com/mufeng05/openwrt-sonic-fullcone.git tmp/sources/openwrt-sonic-fullcone
bash tmp/sources/openwrt-sonic-fullcone/add_sonic_fullcone.sh

# Argon 主题
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# EasyTier
git clone --depth 1 https://github.com/EasyTier/luci-app-easytier.git package/luci-app-easytier

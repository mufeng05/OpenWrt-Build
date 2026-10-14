#!/usr/bin/env bash
# 产品定制：在 feeds 安装完成之后、加载 .config 之前，于 OpenWrt 源码根目录执行。
# 第三方仓库 clone 到 package/（软件包）或 tmp/sources/（只用其中的脚本），release 说明会记录它们的提交。
set -euo pipefail

# SONiC 全锥形 NAT
git clone --depth 1 https://github.com/mufeng05/openwrt-sonic-fullcone.git tmp/sources/openwrt-sonic-fullcone
bash tmp/sources/openwrt-sonic-fullcone/add_sonic_fullcone.sh | tee tmp/sonic-fullcone.log
# 放不进去的补丁这个脚本只会跳过、照样返回成功，固件会悄悄缺少全锥形 NAT
if ! grep -q "=== Done: [0-9]* applied, 0 skipped ===" tmp/sonic-fullcone.log; then
  echo "add_sonic_fullcone.sh 跳过了部分补丁" >&2
  exit 1
fi

# Argon 主题
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# EasyTier
git clone --depth 1 https://github.com/EasyTier/luci-app-easytier.git package/luci-app-easytier
# CI 用 EASYTIER_VERSION 环境变量指定版本（见 product.env）。它能生效是因为软件包实际没有引入 version.mk，
# 万一上游修好了，version.mk 里的赋值会盖过环境变量，所以把版本也写进去
if [ -n "${EASYTIER_VERSION:-}" ]; then
  sed -i "s/^EASYTIER_VERSION=.*/EASYTIER_VERSION=$EASYTIER_VERSION/" package/luci-app-easytier/version.mk
fi

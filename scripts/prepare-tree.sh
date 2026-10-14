#!/usr/bin/env bash
# 把产品定制应用到 OpenWrt 源码树，并生成完整的 .config。
# 用法: scripts/prepare-tree.sh <产品名> <OpenWrt 源码目录>
#
# 需要在全新源码树上执行 ./scripts/feeds update -a && ./scripts/feeds install -a 之后运行。
# 依次执行：
#   1. 复制 products/<产品名>/files/ 到源码树的 files/（固件内的覆盖文件）
#   2. 运行 products/<产品名>/customize.sh（添加第三方软件包、打补丁等）
#   3. 用 products/<产品名>/config 生成 .config（make defconfig）
set -euo pipefail

product=${1:?用法: $0 <产品名> <OpenWrt 源码目录>}
openwrt=${2:?用法: $0 <产品名> <OpenWrt 源码目录>}

repo_root=$(cd "$(dirname "$0")/.." && pwd)
product_dir="$repo_root/products/$product"

if [ ! -f "$product_dir/config" ]; then
  echo "找不到产品配置: products/$product/config" >&2
  exit 1
fi

cd "$openwrt"

if [ -d "$product_dir/files" ]; then
  mkdir -p files
  cp -a "$product_dir/files/." files/
fi

if [ -f "$product_dir/customize.sh" ]; then
  REPO_ROOT=$repo_root PRODUCT_DIR=$product_dir bash "$product_dir/customize.sh"
fi

cp "$product_dir/config" .config
make defconfig

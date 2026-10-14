#!/usr/bin/env bash
# 把产品定制应用到 OpenWrt 源码树，并生成完整的 .config。
# 用法: scripts/prepare-tree.sh <产品名> <OpenWrt 源码目录>
#
# 需要在全新源码树上执行 ./scripts/feeds update -a && ./scripts/feeds install -a 之后运行。
# 依次执行：
#   1. 复制 products/<产品名>/files/ 到源码树的 files/（固件内的覆盖文件）
#   2. 运行 products/<产品名>/customize.sh（添加第三方软件包、打补丁等）
#   3. 用 products/<产品名>/config 生成 .config（make defconfig）
#   4. 检查配置里选中的软件包都还在
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
  # 在 Windows 上提交的文件可能没有可执行位，启动脚本缺了它不会运行
  for script in files/etc/init.d/* files/usr/libexec/rpcd/*; do
    if [ -f "$script" ]; then chmod +x "$script"; fi
  done
fi

if [ -f "$product_dir/customize.sh" ]; then
  REPO_ROOT=$repo_root PRODUCT_DIR=$product_dir bash "$product_dir/customize.sh"
fi

cp "$product_dir/config" .config
make defconfig

# make defconfig 会静默丢掉上游已删除、改名或依赖不再满足的软件包，固件照样编得出来，只是少了它们
missing=$(grep -E '^CONFIG_PACKAGE_[^=]+=[ym]$' "$product_dir/config" | grep -vxF -f .config || true)
if [ -n "$missing" ]; then
  echo "以下软件包在 make defconfig 之后没有被选中，可能已被上游删除或改名，或者依赖不再满足：" >&2
  echo "$missing" >&2
  echo ".config 已经生成，可以 make menuconfig 调整后按 README「修改配置」更新 products/$product/config。" >&2
  exit 1
fi

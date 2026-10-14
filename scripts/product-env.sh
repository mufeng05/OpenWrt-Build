#!/usr/bin/env bash
# 读取产品的构建参数，按 KEY=value 逐行输出（CI 中追加到 $GITHUB_ENV，成为后续所有步骤的环境变量）。
# 用法: scripts/product-env.sh <产品名>
#
# products/<产品名>/product.env 在仓库根目录下被 source，可以用命令动态取值。
# 其中定义的变量都会输出，所以除了下面几个构建参数，也可以用它给编译过程传环境变量。
set -euo pipefail

product=${1:?用法: $0 <产品名>}
cd "$(dirname "$0")/.."
env_file=products/$product/product.env

if [ ! -f "products/$product/config" ]; then
  echo "找不到产品配置: products/$product/config" >&2
  exit 1
fi

# 默认值，可在 product.env 中覆盖
OPENWRT_REPO=openwrt/openwrt
OPENWRT_REF=main
HOST_DEBS=
extra_names=

if [ -f "$env_file" ]; then
  # shellcheck source=/dev/null
  . "$env_file"
  extra_names=$(sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' "$env_file")
fi

echo "OPENWRT_REPO=$OPENWRT_REPO"
echo "OPENWRT_REF=$OPENWRT_REF"
echo "HOST_DEBS=$HOST_DEBS"
for name in $extra_names; do
  case $name in
    OPENWRT_REPO | OPENWRT_REF | HOST_DEBS) ;;
    *) echo "$name=${!name}" ;;
  esac
done

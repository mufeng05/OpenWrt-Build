#!/usr/bin/env bash
# 读取产品的构建参数，按 KEY=value 逐行输出（CI 中直接追加到 $GITHUB_ENV）。
# 用法: scripts/product-env.sh <产品名>
set -euo pipefail

product=${1:?用法: $0 <产品名>}
dir="$(cd "$(dirname "$0")/.." && pwd)/products/$product"

if [ ! -f "$dir/config" ]; then
  echo "找不到产品配置: products/$product/config" >&2
  exit 1
fi

# 默认值，可在 products/<产品名>/product.env 中覆盖
OPENWRT_REPO=openwrt/openwrt
OPENWRT_REF=main
HOST_DEBS=

if [ -f "$dir/product.env" ]; then
  # shellcheck source=/dev/null
  . "$dir/product.env"
fi

echo "OPENWRT_REPO=$OPENWRT_REPO"
echo "OPENWRT_REF=$OPENWRT_REF"
echo "HOST_DEBS=$HOST_DEBS"

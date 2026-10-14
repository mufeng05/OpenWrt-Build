#!/usr/bin/env bash
# 编译 tools 和工具链，已从缓存恢复的部分会被跳过。
# 用法: scripts/build-toolchain.sh <OpenWrt 源码目录>
set -euo pipefail

cd "${1:?用法: $0 <OpenWrt 源码目录>}"

# 缓存里的 stamp 比刚检出的源码旧，刷新时间后 make 才会跳过已缓存的部分。
# 必须用同一个时间戳：与 stamp 同一时刻的文件，OpenWrt 不视为更新。
now=$(date +%s)
for dir in staging_dir/host/stamp staging_dir/toolchain-*/stamp; do
  if [ -d "$dir" ]; then
    find "$dir" -type f -exec touch -d "@$now" {} +
  fi
done

host_dir=$(make -s val.STAGING_DIR_HOST)
tools_enabled=$(make -s val.tools_enabled)
toolchain_dir=$(make -s val.TOOLCHAIN_DIR)

# 以 tools 和工具链的 stamp 文件为目标，只编译到工具链为止（make prepare 还会编译内核）。
# 分两次调用：顶层 make 会直接跳过已存在的目标，而一次传入两个目标可能并行地重复编译 tools。
for stamp in "$host_dir/stamp/.tools_compile_${tools_enabled// /}" "$toolchain_dir/stamp/.toolchain_compile"; do
  make -j"$(nproc)" "$stamp" || make -j1 V=s "$stamp"
done

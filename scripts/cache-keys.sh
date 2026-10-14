#!/usr/bin/env bash
# 计算 tools 和工具链缓存的 key，需在 scripts/prepare-tree.sh 之后执行。
# 用法: scripts/cache-keys.sh <产品名> <OpenWrt 源码目录>
# 按 KEY=value 输出 tools=<key> 和 toolchain=<key>（CI 中追加到 $GITHUB_OUTPUT）。
set -euo pipefail

usage="用法: $0 <产品名> <OpenWrt 源码目录>"
product=${1:?$usage}
cd "${2:?$usage}"

# 从标准输入读入以 NUL 分隔的文件列表，计算文件名和内容的整体哈希
hash_files() {
  LC_ALL=C sort -z | xargs -0 -r md5sum | md5sum | cut -c1-12
}

# 先赋值再使用，读取失败时 set -e 才能生效
tools_enabled=$(make -s val.tools_enabled)
toolchain_dir=$(make -s val.TOOLCHAIN_DIR)
if [ -z "$tools_enabled" ] || [ -z "$toolchain_dir" ]; then
  echo "无法读取 OpenWrt 的构建变量，请先运行 scripts/prepare-tree.sh" >&2
  exit 1
fi

# tools：tools/ 目录的内容，加上按配置启用的工具集合（OpenWrt 也把它编码在 stamp 文件名里）
tools_files=$(find tools -type f ! -path '*/.*' -print0 | hash_files)
tools_set=$(echo "$tools_enabled" | md5sum | cut -c1-8)
echo "tools=tools-$tools_files-$tools_set"

# 工具链：toolchain/ 目录的内容、目标平台、内核大版本、工具链选项，以及产品对内核补丁的改动
# （工具链里的内核头文件会打上 target/linux 下的补丁）。另外每月强制重建一次，兜住上面没覆盖到的上游变化。
toolchain_symbols=$(find toolchain -type f -name 'Config*' \
  -exec sed -n 's/^[[:space:]]*\(menu\)\{0,1\}config[[:space:]]\{1,\}\([A-Za-z0-9_]\{1,\}\).*/\2/p' {} + | sort -u | paste -sd '|')
toolchain_inputs=$(
  {
    find toolchain -type f ! -path '*/.*' -print0 | hash_files
    grep -E "^CONFIG_(TARGET_(BOARD|SUBTARGET|ARCH_PACKAGES|OPTIMIZATION)|CPU_TYPE|LINUX_[0-9_]+|$toolchain_symbols)=" .config || true
    git status --porcelain --untracked-files=all -- target/linux toolchain
    git diff -- target/linux toolchain
    git ls-files -z --others --exclude-standard -- target/linux toolchain | hash_files
  } | md5sum | cut -c1-12
)
toolchain_name=${toolchain_dir##*/toolchain-}
echo "toolchain=toolchain-$product-$toolchain_name-$(date -u +%Y%m)-$toolchain_inputs"

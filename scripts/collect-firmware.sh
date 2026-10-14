#!/usr/bin/env bash
# 整理编译产物并生成 release 说明。
# 用法: scripts/collect-firmware.sh <OpenWrt 源码目录> <release 说明输出文件>
# 需要环境变量 OPENWRT_REPO、OPENWRT_REF、OPENWRT_SHA。
# 按 KEY=value 输出 FIRMWARE=<固件目录>（CI 中追加到 $GITHUB_ENV）。
set -euo pipefail
shopt -s nullglob

usage="用法: $0 <OpenWrt 源码目录> <release 说明输出文件>"
openwrt=$(cd "${1:?$usage}" && pwd)
notes=${2:?$usage}

targets=("$openwrt"/bin/targets/*/*/)
if [ ${#targets[@]} -ne 1 ]; then
  echo "bin/targets 下应当正好有一个 <target>/<subtarget> 目录，实际有 ${#targets[@]} 个" >&2
  exit 1
fi
firmware=${targets[0]%/}

# feeds 软件包打成一个压缩包随固件发布，目标平台的 packages 目录不发布
tar -czf "$firmware/Packages.tar.gz" -C "$openwrt/bin/packages" .
rm -rf "$firmware/packages"

kernel=unknown
kernel_dirs=("$openwrt"/build_dir/target-*/linux-*/linux-[0-9]*/)
if [ ${#kernel_dirs[@]} -gt 0 ]; then
  kernel=${kernel_dirs[0]%/}
  kernel=${kernel##*/linux-}
fi

{
  echo "# Sources"
  echo
  echo "OpenWrt: [$OPENWRT_REPO@$OPENWRT_REF](https://github.com/$OPENWRT_REPO/tree/$OPENWRT_REF) ([\`$OPENWRT_SHA\`](https://github.com/$OPENWRT_REPO/tree/$OPENWRT_SHA))"
  echo
  echo "# Kernel Version"
  echo
  echo "$kernel"
  echo
  echo "# SHA256"
  echo
  for image in "$firmware"/*.img "$firmware"/*.img.gz; do
    # 反引号是 Markdown 的代码格式，不是命令替换
    # shellcheck disable=SC2016
    printf '%s: `%s`\n' "${image##*/}" "$(sha256sum "$image" | cut -d ' ' -f 1)"
  done
} > "$notes"

echo "FIRMWARE=$firmware"

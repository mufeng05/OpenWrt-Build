#!/usr/bin/env bash
# 删除某个产品较早的 release（连同 tag），只保留最近的 N 个。
# 用法: scripts/prune-releases.sh <产品名> <保留数量>
# 需要已登录的 gh（CI 中通过 GH_TOKEN 环境变量）。
set -euo pipefail

usage="用法: $0 <产品名> <保留数量>"
product=${1:?$usage}
keep=${2:?$usage}

if ! [[ $keep =~ ^[1-9][0-9]*$ ]]; then
  echo "保留数量必须是正整数: $keep" >&2
  exit 1
fi

# release 的 tag 格式为 OpenWrt-<产品名>_<设备>_<日期>。
# 按 publishedAt 排序：createdAt 是被打 tag 的 commit 的时间，同一 commit 的多次构建会相同。
tags=$(gh release list --limit 10000 --json tagName,publishedAt,isDraft |
  jq -r --arg prefix "OpenWrt-${product}_" --argjson keep "$keep" '
    map(select((.isDraft | not) and (.tagName | startswith($prefix))))
    | sort_by(.publishedAt) | reverse
    | .[$keep:][].tagName')

failed=0
while IFS= read -r tag; do
  [ -n "$tag" ] || continue
  echo "删除 release: $tag"
  gh release delete "$tag" --cleanup-tag --yes || failed=1
  # 积压较多时会连续删除上百个，放慢速度以免触发 GitHub 的二级限流
  sleep 1
done <<< "$tags"

exit "$failed"

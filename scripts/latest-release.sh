#!/usr/bin/env bash
# 输出 GitHub 仓库版本号最高的 release（包括标记为 pre-release 的），去掉开头的 v。
# 有的项目几乎每个版本都标成 pre-release（比如 EasyTier），GitHub 认定的「Latest」会落后好几个版本。
# 用法: scripts/latest-release.sh <owner/repo>
set -euo pipefail

repo=${1:?用法: $0 <owner/repo>}

# 读 releases 的 Atom 订阅（最近十来个已发布的 release），不走 API，避开匿名调用的频率限制。
# 只认纯版本号的 tag，nightly 之类的跳过。
feed=$(curl -fsSL --retry 3 "https://github.com/$repo/releases.atom") || feed=
version=$(grep -o 'href="https://github.com/[^"]*/releases/tag/[^"]*"' <<< "$feed" |
  sed 's|.*/releases/tag/||; s|"$||; s|^v||' |
  grep -E '^[0-9]+(\.[0-9]+)+$' | sort -V | tail -n 1) || version=

if [ -z "$version" ]; then
  echo "取不到 $repo 的最新 release" >&2
  exit 1
fi
echo "$version"

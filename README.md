# Build OpenWrt

用 GitHub Actions 编译 x86_64 OpenWrt 固件。每个"产品"是一套独立的源码 + 定制 + 配置，编译完成后自动发布到 Releases。

## 产品

| 产品 | 源码 | 定制内容 | 触发方式 |
| --- | --- | --- | --- |
| PCDN-gateway | openwrt/openwrt@main | SONiC 全锥形 NAT、Argon 主题、EasyTier | 每天 08:00、推送相关文件、手动 |
| PCDN | openwrt/openwrt@main | Turbo ACC、Argon 主题、sysctl 调优 | 手动 |
| PCDN-fw3 | openwrt/openwrt@main | Turbo ACC、Argon 主题、sysctl 调优 | 手动 |
| PCDN-mwan | openwrt/openwrt@main | Turbo ACC、Argon 主题 | 手动 |
| turboacc | openwrt/openwrt@main | Turbo ACC、Argon 主题 | 手动 |
| gateway | openwrt/openwrt@main | Turbo ACC、Argon 主题 | 手动 |
| proxy | openwrt/openwrt@main | — | 手动 |
| home-clash | openwrt/openwrt@main | — | 手动 |
| BE | openwrt/openwrt@main | Argon 主题 | 手动 |
| Fullcone | openwrt/openwrt@main | Turbo ACC（chenmozhijin 版，不含 SFE）、Argon 主题、wrtbwmon | 手动 |
| LEDE | coolsnowwolf/lede@master | sysctl 调优 | 手动 |

手动构建：在 Actions 页面选择对应的 `Build OpenWrt <产品>`，点击 **Run workflow**。

## 目录结构

```
.github/workflows/
  build.yml                    # 通用构建流程（可复用 workflow）
  Build_OpenWrt_<产品>.yml      # 各产品入口：触发条件 + 调用 build.yml
products/<产品>/
  config                       # 配置（diffconfig 格式）
  product.env                  # 源码仓库、分支，以及 CI 额外安装的主机软件包
  customize.sh                 # 可选：添加第三方软件包、打补丁等
  files/                       # 可选：直接放进固件的文件，如 etc/sysctl.d/99-custom.conf
scripts/
  product-env.sh               # 读取 product.env
  prepare-tree.sh              # 应用产品定制并生成 .config
  collect-firmware.sh          # 整理固件、生成 release 说明
  prune-releases.sh            # 清理旧 release
patches/r8168/                 # 备用补丁，目前没有产品使用（见下文）
```

## 构建流程

1. 按 `product.env` 检出源码，执行 `feeds update` / `feeds install`
2. `scripts/prepare-tree.sh`：复制 `files/`，运行 `customize.sh`，用 `config` 执行 `make defconfig`
3. `make download`，`make`
4. 上传 `bin` 目录为 artifact（保留 7 天）
5. 创建 release，tag 为 `OpenWrt-<产品>_<平台>_<日期>`，说明中包含源码 commit、内核版本和镜像的 SHA256
6. 只保留该产品最近 10 个 release，更早的连同 tag 一起删除（在产品入口 workflow 中用 `keep-releases` 调整，`0` 表示不清理）

## 修改配置

`config` 采用 diffconfig 格式，只记录与默认值不同的选项；上游默认值变化时会自动跟随。修改步骤：

```bash
# 源码仓库和分支与 product.env 一致；需要一个全新的源码树
git clone https://github.com/openwrt/openwrt.git && cd openwrt
./scripts/feeds update -a && ./scripts/feeds install -a

# 应用产品定制并加载当前配置
bash ../OpenWrt-Build/scripts/prepare-tree.sh PCDN-gateway .

make menuconfig
./scripts/diffconfig.sh > ../OpenWrt-Build/products/PCDN-gateway/config
```

直接放入完整的 `.config` 也可以编译，但不推荐。

## 新增产品

1. 新建 `products/<产品>/`，放入 `config`，按需添加 `product.env`、`customize.sh`、`files/`
2. 复制一个 `.github/workflows/Build_OpenWrt_<产品>.yml`，修改 `name` 和 `product`

## 备用补丁

`patches/r8168/010-enable_TX_RSS_disable_ASPM.patch`：r8168 驱动关闭 ASPM，开启多队列 TX 和 RSS。需要时在产品的 `customize.sh` 中加入：

```bash
cp "$REPO_ROOT"/patches/r8168/*.patch package/kernel/r8168/patches/
```

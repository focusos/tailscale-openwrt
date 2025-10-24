# Tailscale on OpenWRT
[![Release](https://img.shields.io/github/release/focusos/tailscale-openwrt)](https://github.com/focusos/tailscale-openwrt/releases)
[![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Ffocusos%2Ftailscale-openwrt&label=views&countColor=%23263759&style=flat)](https://github.com/focusos/tailscale-openwrt)
---

## 目录

- [项目初衷](#项目初衷)
- [适用范围](#适用范围)
- [支持架构](#支持架构)
- [自定义部署说明](#自定义部署说明)
- [安装步骤（0x00）](#安装步骤0x00)
- [卸载步骤（0x01）](#卸载步骤0x01)
- [升级步骤（0x02）](#升级步骤0x02)
- [支持与反馈](#支持与反馈)
- [特别感谢](#特别感谢)

---

## 请注意

## 2025年10月6日11:24:23，本人fork大佬项目，继续进行维护。

***🚨🚨🚨由于本仓库不再维护 [![deprecated](https://img.shields.io/badge/状态-不再维护-red)](https://github.com/focusos/small-tailscale-openwrt) , 您可以选择我维护的另一个同功能[仓库](https://github.com/focusos/small-tailscale-openwrt)🚨🚨🚨***

- 该仓库通过 UPX 对可执行文件进行压缩，最终体积约为 6-7MB，可直接在路由器设备中安装(某些架构无法压缩, 可执行文件大小约为20MB)。
- 支持内存闪存双安装模式
- 支持固定版本安装
- 支持自动更新
- 使用自动测速代理, 理论上不会出现代理无法使用的情况
- 支持自动生成tailscale启动命令
- 还有更直观好用的脚本
- ***本仓库不再维护!***

---

## 项目初衷

本项目最初旨在支持那些“存储空间有限、但内存相对充足”的 OpenWRT 路由器设备。核心思路是将 Tailscale 下载至 `/tmp`（内存）中运行
- ***(注:上面提到的[仓库](https://github.com/focusos/ts-test)已经可以支持内存闪存双模式安装, 且可执行文件更小)。***

---

## 适用范围
| 内存/存储        | < 80MB 存储空间       | > 80MB 存储空间       |
|------------------|------------------------|------------------------|
| < 80MB 内存       | 不支持                | 不推荐使用。建议[手动安装](https://github.com/focusos/tailscale-openwrt/issues/18#issuecomment-2336612695)至内置存储 |
| > 80MB 内存       | 支持运行              | 支持运行。建议[手动安装](https://github.com/focusos/tailscale-openwrt/issues/18#issuecomment-2336612695)以确保稳定性 |

> 注意：压缩包（zip）及解压后的二进制文件整体大小约为 80MB。

---

## 支持架构

| 已测试架构        | x86_64, aarch64, mipsle, mips, armv7l, armv8l |
|------------------|------------------------------------------------|
| 未测试架构        | riscv64, mips64, mips64le, i386, geode         |

尽管 `install.sh` 中已预设以上架构的处理方式，但因不同系统对架构识别不完全统一，执行 `uname -m` 可能返回与预设不一致的值，可能导致架构匹配失败。

---

## 自定义部署说明

您可以 fork 本仓库后，修改 `/usr/bin/` 中的下载链接以指向您自己的仓库。

GitHub Actions 将自动打包并上传 tgz 文件至您仓库的 release 中。随后修改 `install.sh` 和 `README.md` 文件中涉及的用户名为您自己的。

> 当前分支已预设多种下载代理。如发现全部代理失效，请[创建Issue](https://github.com/focusos/tailscale-openwrt/issues/new)联系我更新

---

## 安装步骤（0x00）

使用以下命令进行首次安装：

```bash
wget -O /tmp/install.sh http://ghproxy.ch3ng.top/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/install.sh && chmod +x /tmp/install.sh && /tmp/install.sh && rm -f /tmp/install.sh
```

> 自 Tailscale 1.48.0 起，官方已支持 nftables。本项目自 2024.08.20 起适配，使用版本为 1.72.0，并在执行进程中传入 `TS_DEBUG_FIREWALL_MODE=auto` 环境变量。

如您在系统日志中发现 Tailscale 启动失败，请手动在 `/etc/init.d/tailscale` 中设定明确的防火墙模式，参考：[官方防火墙设置说明](https://tailscale.com/kb/1294/firewall-mode#how-to-set-the-firewall-mode)

---

## 卸载步骤（0x01）

> **请勿在 SSH 会话中执行此脚本，否则 SSH 连接将中断。请谨慎操作，风险自负。**

```bash
wget -O /tmp/uninstall.sh http://ghproxy.ch3ng.top/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/uninstall.sh && chmod +x /tmp/uninstall.sh && /tmp/uninstall.sh && rm -f /tmp/uninstall.sh
```

---

## 升级步骤（0x02）

### 自动升级 tailscale 可执行文件

每次系统启动时，`tailscale_downloader` 会自动下载最新版本的 Tailscale 可执行文件：

```bash
reboot
```

### 升级下载器脚本（保留配置）

如您希望同步更新下载脚本（例如替换代理源），请执行以下命令：

```bash
rm -rf /tmp/tailscale* && wget -O /tmp/install.sh http://ghproxy.ch3ng.top/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/install.sh && chmod +x /tmp/install.sh && /tmp/install.sh && rm -f /tmp/install.sh && reboot
```

---

## 支持与反馈

如果本项目对您有所帮助，欢迎点个 Star 支持，谢谢！

> 若检测到新版本但 GitHub Actions 尚未触发构建，您可以手动点击仓库右上角的 Star 或 Watch 来触发自动构建。

---

## 特别感谢

- [adyanth - openwrt-tailscale-enabler](https://github.com/adyanth/openwrt-tailscale-enabler)

[![Star History Chart](https://api.star-history.com/svg?repos=focusos/tailscale-openwrt&type=Date)](https://www.star-history.com/#focusos/tailscale-openwrt&Date)

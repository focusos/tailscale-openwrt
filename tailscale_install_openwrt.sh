#!/bin/sh

set -e

# 1.配置DNS
cat <<EOF > /etc/resolv.conf
search lan
nameserver 223.5.5.5
nameserver 119.29.29.29
EOF

# 2.检查并设置架构
if [ ! -f /tmp/tailscale ]; then
    arch=$(uname -m)
	endianness=""
    case "$arch" in
        i386 | i686)
            arch=386
            ;;
        x86_64)
            arch=amd64
            ;;
        armv7l)
            arch=arm
            ;;
        aarch64 | armv8l)
            arch=arm64
            ;;
        geode)
            arch=geode
            ;;
        mips)
            endianness=$(echo -n I | hexdump -o | awk '{ print (substr($2,6,1)=="1") ? "le" : "be"; exit }')
            arch="mips$endianness"
            ;;
        riscv64)
            arch=riscv64
            ;;
        *)
            echo "DOWNLOAD: ----------------------------------------------------"
            echo "当前机器的架构是${arch}${endianness}, 脚本不兼容此架构"
            echo "请给作者提issue以便作者及时修改脚本:"
            echo "https://github.com/focusos/tailscale-openwrt/issues"
            echo "--------------------------------------------------------------"
            exit 1
            ;;
    esac
fi

if [ -e /tmp/tailscaled ]; then
    echo "INSTALL: ------------------"
    echo "存在残留, 请卸载并重启后重试"
    echo "卸载命令: "
    echo "wget -O /tmp/uninstall.sh https://ghfast.top/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/uninstall.sh && chmod +x /tmp/uninstall.sh && /tmp/uninstall.sh && rm -f /tmp/uninstall.sh"
    echo "---------------------------"
    exit 1
fi

## 1源码更新
echo 1源码更新
sed -i 's/https:\/\/raw.github/https:\/\/ghfast.top\/https:\/\/raw.github/g' /etc/opkg/distfeeds.conf
opkg update

# echo 请检查上述脚本执行情况
# read -n 1 -s

## 2检查并安装包
	echo 2检查并安装包
	required_packages="curl wget libustream-openssl ca-bundle kmod-tun coreutils-timeout ca-certificates"
	for package in $required_packages; do
		# 检查包是否已安装
		if ! opkg list-installed | grep -q "$package"; then
	echo "INSTALL: 包 $package 未安装，开始安装..."
	opkg install "$package"
	if [ $? -ne 0 ]; then
	echo "INSTALL: 安装 $package 失败，跳过该包，如果无法正常运行 tailscale，请排查是否需要手动安装该包"
	continue
	else
	echo "INSTALL: 包 $package 安装成功"
	fi
		else
	echo "INSTALL: 包 $package 已安装，跳过"
		fi
	done


# 下载安装包
timeout_seconds=5
download_success=false

# 代理列表
proxy_zip_urls="
https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale-openwrt.tgz
https://ghproxy.net/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale-openwrt.tgz
https://fastly.jsdelivr.net/gh/focusos/tailscale-openwrt@chinese_mainland/tailscale-openwrt.tgz
https://jsdelivr.pai233.top/gh/focusos/tailscale-openwrt@chinese_mainland/tailscale-openwrt.tgz
https://raw.kkgithub.com/focusos/tailscale-openwrt/chinese_mainland/tailscale-openwrt.tgz
https://wget.la/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale-openwrt.tgz
https://ghfast.top/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale-openwrt.tgz
"

for proxy_zip_url in $proxy_zip_urls; do
    if timeout $timeout_seconds wget -q $proxy_zip_url -O - | tar x -zvC / -f - > /dev/null 2>&1; then
        download_success=true
        echo "INSTALL: ------"
        echo "通过 $proxy_zip_url 下载安装脚本成功!"
        echo "---------------"
        break
    else
        echo "INSTALL: ------------------"
        echo "通过 $proxy_zip_url 下载安装脚本失败，尝试下一个代理"
        echo "---------------------------"
    fi
done

if [ "$download_success" != true ]; then
    echo "INSTALL: -------------------------"
    echo "所有代理下载均失败，请检查网络、DNS或稍后再试"
    echo "----------------------------------"
    exit 1
fi

if [ ! -e "/etc/init.d/tailscale" ]; then
    echo "/etc/init.d/tailscale 不存在, 请重试."
    exit 1
fi

/etc/init.d/tailscale enable

echo "INSTALL: --------------"
echo "正在启动 Tailscale 下载器"
echo "-----------------------"
tailscale_downloader

if [ ! -e "/tmp/tailscale" ]; then
    echo "/tmp/tailscale 不存在, 请重试."
    exit 1
fi

echo "INSTALL: ----------------"
echo "正在启动 Tailscale 后台服务"
echo "-------------------------"
/etc/init.d/tailscale start
sleep 3

echo "INSTALL: ----------------"
echo "正在启动 Tailscale 前台程序"
echo "-------------------------"
tailscale up

echo "INSTALL: -------------------------------------------------------------------------"
echo "你可以运行 tailscale up --advertise-routes=192.168.1.0/24 以启用子网中继，请自行修改网段"
echo "----------------------------------------------------------------------------------"

# echo "INSTALL: ---------------------------------------------"
# echo "当前机器的架构是 arch_:${arch_}${endianness}| arch:${arch}"
# echo "如果成功运行, 请在这个issue留下评论以便作者及时修改说明文档: "
# echo "https://github.com/focusos/tailscale-openwrt/issues/6"
# echo "------------------------------------------------------"

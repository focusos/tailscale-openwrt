#!/bin/sh

set -e

# 1.配置DNS
echo 1.配置DNS
#cat <<EOF > /etc/resolv.conf
#search lan
#nameserver 223.5.5.5
#nameserver 119.29.29.29
#EOF

# 2.检查并设置架构
echo 2.检查并设置架构
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

## 3.源码更新
	echo 3.源码更新
	sed -i 's/openwrt_core https:\/\/raw.githubusercontent/openwrt_core https:\/\/ghfast.top\/https:\/\/raw.githubusercontent/g' /etc/opkg/distfeeds.conf
	opkg update

# echo 请检查上述脚本执行情况
# read -n 1 -s

## 4.检查所需环境配置
	echo 4.检查所需环境配置
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


## 5.下载并安装tailscale
	echo 5.下载并安装tailscale

		timeout_seconds=5
		download_success=false

		# 代理列表
		proxy_zip_urls="
		https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale_install_openwrt.tgz
		https://ghproxy.net/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale_install_openwrt.tgz
		https://fastly.jsdelivr.net/gh/focusos/tailscale-openwrt@chinese_mainland/tailscale_install_openwrt.tgz
		https://jsdelivr.pai233.top/gh/focusos/tailscale-openwrt@chinese_mainland/tailscale_install_openwrt.tgz
		https://raw.kkgithub.com/focusos/tailscale-openwrt/chinese_mainland/tailscale_install_openwrt.tgz
		https://wget.la/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale_install_openwrt.tgz
		https://ghfast.top/https://raw.githubusercontent.com/focusos/tailscale-openwrt/chinese_mainland/tailscale_install_openwrt.tgz
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
	file_size=$(du -k /tailscale_install_openwrt.tgz | awk '{print $1}')
	if  [ "$file_size" -ge 1 ] ; then
		tar -xzvf tailscale_install_openwrt.tgz
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
			rm -rf /tailscale_install_openwrt.tgz			
			echo "下载成功，解压成功"
		else
			echo "下载失败，解压失败"
			exit 0
	fi
	
## 6.内核检查，决定是否开启UDP加速
	echo 6.内核检查，决定是否开启UDP加速
	opkg install ethtool
	linux_version=$(uname -r | grep -o '^.' )
	if  [ "$linux_version" -ge 6 ] ; then
		/etc/init.d/tailscale_udp enable
		/etc/init.d/tailscale_udp start
	    echo "DOWNLOAD: ---------------------------------"
	    echo "内核版本$linux_version，大于6已执行UDP加速成功!"
	    echo "-------------------------------------------"
	else
	    echo "DOWNLOAD: --------------------------------------"
	    echo "内核版本$linux_version，未大于6，无需执行UDP加速"
	    echo "------------------------------------------------"
	fi


## 7.打开转发
	echo "4打开转发"

	rm -rf /etc/sysctl.d/99-tailscale.conf

	echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-tailscale.conf

	echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-tailscale.conf

	cat /etc/sysctl.d/99-tailscale.conf

	sysctl -p /etc/sysctl.d/99-tailscale.conf

## 8.登录及组网
	echo 8.登录及组网
	echo ""
	echo ""
	echo "tailscale up --accept-routes --advertise-exit-node --advertise-routes=10.10.10.0/24 --hostname=10YF-OpenWrt"
	echo "tailscale up --accept-routes --advertise-exit-node --advertise-routes=10.10.13.0/24 --hostname=13XQ-OpenWrt"
	echo "tailscale up --accept-routes --advertise-exit-node --advertise-routes=192.168.20.0/24 --hostname=20ZW-OpenWrt"
	echo ""
	echo ""

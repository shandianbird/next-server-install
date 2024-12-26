#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
BLUE="\033[0;36m"
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
echo -e "${BLUE}
-----------------------------write by ***-----------------------------
"
[[ $EUID -ne 0 ]] && echo -e "错误 必须使用root用户运行此脚本！\n" && exit 1

last_version=$(curl -Ls "https://api.github.com/repos/SSPanel-NeXT/NeXT-Server/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
else
  arch="riscv64"
fi

install_next-server(){
if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi    
	if [[ $release = "ubuntu" || $release = "debian" ]]; then
	apt update -y && apt install wget unzip vim -y
	elif [[ $release = "centos" ]]; then
	yum update -y && yum install wget unzip vim -y
	else
	exit 1
	fi
	mkdir -p /etc/next-server
	cd /etc/next-server
	wget -N --no-check-certificate "https://github.com/SSPanel-NeXT/NeXT-Server/releases/download/${last_version}/next-server-linux-${arch}.zip"
	unzip next-server-linux-${arch}.zip
	chmod +x next-server
	mv next-server /usr/bin/
	wget -N --no-check-certificate -P /etc/systemd/system/ "https://raw.githubusercontent.com/shandianbird/next-server-install/main/next-server.service"
	systemctl daemon-reload
	systemctl enable next-server
	menu
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}next-server已运行，无需再次启动，如需重启请选择重启${plain}"
    else
        systemctl start next-server
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}next-server 启动成功，请使用 next-server log 查看运行日志${plain}"
        else
            echo -e "${red}next-server可能启动失败，请稍后使用 next-server log 查看日志信息${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        menu
    fi
}

stop() {
    systemctl stop next-server
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}next-server 停止成功${plain}"
    else
        echo -e "${red}next-server停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息${plain}"
    fi

    if [[ $# == 0 ]]; then
        menu
    fi
}

restart() {
    systemctl restart next-server
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}next-server 重启成功，请使用 next-server log 查看运行日志${plain}"
    else
        echo -e "${red}next-server可能启动失败，请稍后使用 next-server log 查看日志信息${plain}"
    fi
    if [[ $# == 0 ]]; then
        menu
    fi
}

status() {
    systemctl status next-server --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable next-server
    if [[ $? == 0 ]]; then
        echo -e "${green}next-server 设置开机自启成功${plain}"
    else
        echo -e "${red}next-server 设置开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable next-server
    if [[ $? == 0 ]]; then
        echo -e "${green}next-server 取消开机自启成功${plain}"
    else
        echo -e "${red}next-server 取消开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/next-server.service ]]; then
        return 2
    fi
    temp=$(systemctl status next-server | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled next-server)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}next-server已安装，请不要重复安装${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}请先安装next-server${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "next-server状态: ${green}已运行${plain}"
            show_enable_status
            ;;
        1)
            echo -e "next-server状态: ${yellow}未运行${plain}"
            show_enable_status
            ;;
        2)
            echo -e "next-server状态: ${red}未安装${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "是否开机自启: ${green}是${plain}"
    else
        echo -e "是否开机自启: ${red}否${plain}"
    fi
}

config(){
	echo "next-server在修改配置后会自动尝试重启"
	vim /etc/next-server/config.yml
	sleep 2
	systemctl restart next-server
	check_status
    case $? in
        0)
            echo -e "next-server状态: ${green}已运行${plain}"
            ;;
        1)
            echo -e "检测到您未启动next-server或next-server自动重启失败，是否查看日志？[Y/n]" && echo
            read -e -p "(默认: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "next-server状态: ${red}未安装${plain}"
    esac
}

before_show_menu() {
	echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
	menu
}

show_log() {
    journalctl -u next-server.service -e --no-pager -f
    if [[ $# == 0 ]]; then
	before_show_menu
    fi
}
uninstall_next-server(){
	systemctl stop next-server
	systemctl disable next-server
	rm -rf /etc/systemd/system/next-server.service
	systemctl daemon-reload
	systemctl reset-failed
	rm -rf /etc/next-server
	rm -rf /usr/bin/next-server
}

show_version() {
    echo -n "next-server 版本："
    next-server version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

before_show_menu(){
    menu
}

show_usage() {
    echo "next-server 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "nextServerManager              - 显示管理菜单 (功能更多)"
    echo "nextServerManager start        - 启动 next-server"
    echo "nextServerManager stop         - 停止 next-server"
    echo "nextServerManager restart      - 重启 next-server"
    echo "nextServerManager status       - 查看 next-server 状态"
    echo "nextServerManager enable       - 设置 next-server 开机自启"
    echo "nextServerManager disable      - 取消 next-server 开机自启"
    echo "nextServerManager log          - 查看 next-server 日志"
    echo "nextServerManager update       - 更新 next-server"
    echo "nextServerManager update x.x.x - 更新 next-server 指定版本"
    echo "nextServerManager install      - 安装 next-server"
    echo "nextServerManager uninstall    - 卸载 next-server"
    echo "nextServerManager version      - 查看 next-server 版本"
    echo "------------------------------------------"
}

menu(){
	echo -e " 
	  ${green}0.${plain} 修改配置
	————————————————
	  ${green}1.${plain} 安装 next-server
	  ${green}3.${plain} 卸载 next-server
	————————————————
	  ${green}4.${plain} 启动 next-server
	  ${green}5.${plain} 停止 next-server
	  ${green}6.${plain} 重启 next-server
	  ${green}7.${plain} 查看 next-server 状态
	  ${green}8.${plain} 查看 next-server 日志
	————————————————
	  ${green}9.${plain} 设置 next-server 开机自启
	 ${green}10.${plain} 取消 next-server 开机自启
	————————————————
	 ${green}11.${plain} 一键安装 bbr (最新内核)
	 ${green}12.${plain} 查看 next-server 版本 "
	 read -p " 请输入数字后[0-12] 按回车键:" num
	case "$num" in
		0) config
		;;
		1) install_next-server
		;;
		2)
		
		;;
		3) check_install && uninstall_next-server
		;;
		4) check_install && start
		;;
		5) check_install && stop
		;;
		6) check_install && restart
		;;
		7) check_install && status
		;;
		8) check_install && show_log
		;;
		9) check_install && enable
		;;
		10) check_install && disable
		;;
		11) 
		;;
		12) check_install && show_version
		;;
		*)	
		echo "请输入正确数字 [0-12] 按回车键"
		sleep 1s
		menu
		;;
	esac
}

if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    menu
fi

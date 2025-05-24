#! /usr/bin/env zsh

if [ "$EUID" -ne 0 ]; then
    echo "请以 root 用户运行"
    exit 1
fi

PROXY_IP=10.0.2.1
PROXY_PORT=1080

IP_WHITE_LIST=(
    "127.0.0.0/8"
    "192.168.56.0/16"
    "10.0.2.0/8"
    "172.16.0.0/12"
)

_REDSOCKS_CONF=/tmp/redsocks.conf
_REDSOCKS_BIN=/usr/sbin/redsocks
_REDSOCKS_PID=/var/run/redsocks.pid

_REDSOCKS_PORT=23456

function write__REDSOCKS_CONF() {
    cat > "$_REDSOCKS_CONF" <<EOF
base {
    log_debug = off;
    log_info = on;
    daemon = on;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = $_REDSOCKS_PORT;
    ip = $PROXY_IP;
    port = $PROXY_PORT;
    type = socks5;
}
EOF
    echo "已生成 $_REDSOCKS_CONF"
}

function add_iptables_rules() {
    iptables -t nat -N REDSOCKS 2>/dev/null
    iptables -t nat -F REDSOCKS
    for ip in "${IP_WHITE_LIST[@]}"; do
      iptables -t nat -A REDSOCKS -d "$ip" -j RETURN
    done
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports $_REDSOCKS_PORT
    iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
    echo "iptables 规则已添加"
}

function del_iptables_rules() {
    iptables -t nat -D OUTPUT -p tcp -j REDSOCKS 2>/dev/null
    iptables -t nat -F REDSOCKS 2>/dev/null
    iptables -t nat -X REDSOCKS 2>/dev/null
    echo "iptables 规则已清除"
}

function start_redsocks() {
    write__REDSOCKS_CONF
    add_iptables_rules
    $_REDSOCKS_BIN -c $_REDSOCKS_CONF -p $_REDSOCKS_PID
    echo "redsocks 已启动"
}

function stop_redsocks() {
    del_iptables_rules
    if [ -f "$_REDSOCKS_PID" ]; then
        kill "$(cat $_REDSOCKS_PID)" && rm -f "$_REDSOCKS_PID"
        echo "redsocks 已停止"
    else
        pkill redsocks && echo "redsocks 已停止"
    fi
}

case "$1" in
    start)
        start_redsocks
        ;;
    stop)
        stop_redsocks
        ;;
    restart)
        stop_redsocks
        start_redsocks
        ;;
    *)
        echo "用法: $0 {start|stop|restart}"
        ;;
esac
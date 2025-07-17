#!/bin/bash

usage() {
    echo "用法: $0 <name|sname> <target_node> <cookie> <beam_dir> <local_node>"
    echo "  name|sname:   name 为长名，sname为短名"
    echo "  target_node:  目标节点名，如 xxx@192.168.1.100"
    echo "  cookie:       分布式 cookie"
    echo "  beam_dir:     存放 beam 文件的目录"
    echo "  local_node:   本地节点名"
}

if [ $# -lt 4 ] || [ $# -gt 5 ]; then
    usage
    exit 1
fi

NAME_TYPE=$1
TARGET_NODE=$2
COOKIE=$3
BEAM_DIR=$4
LOCAL_NODE=$5
CLIENT_NODE=$LOCAL_NODE

if [[ "$NAME_TYPE" != "name" && "$NAME_TYPE" != "sname" ]]; then
    echo "[ERROR] 第一个参数必须是 name 或 sname"
    usage
    exit 1
fi

if [ ! -d "$BEAM_DIR" ]; then
    echo "[ERROR] 指定的 beam 目录不存在: $BEAM_DIR"
    exit 1
fi

MODULES=$(find "$BEAM_DIR" -maxdepth 1 -type f -name '*.beam' | xargs -n1 basename | sed 's/\.beam$//')

ERL_MODULES="["$(echo $MODULES | sed 's/ /,/g')"]"


erl -$NAME_TYPE $CLIENT_NODE -setcookie $COOKIE -noshell -eval "
    lists:foreach(fun(M) ->
        rpc:call('$TARGET_NODE', code, delete, [M]),
        rpc:call('$TARGET_NODE', code, purge, [M]),
        rpc:call('$TARGET_NODE', code, load_file, [M])
    end, $ERL_MODULES),
    init:stop().
"
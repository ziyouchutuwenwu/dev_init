# ssh-agent

## 场景

本地和多服务器做免密，但是希望服务器之间也免密

## 步骤

### 配置密钥

所有的服务器上都要有本地的公钥

### 启动 agent

手动

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

~/.profile

```sh
if [ -z "$SSH_AGENT_PID" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    eval "$(ssh-agent -s 2>/dev/null | grep -v 'Agent pid')" >/dev/null
    # ssh-add ~/downloads/keys/key >/dev/null 2>&1
    if ! trap -p | grep -q "ssh-agent -k"; then
        trap 'ssh-agent -k >/dev/null 2>&1' EXIT
    fi
fi
```

### 连接

```sh
# 连接服务器 A
ssh -A root@xx.xx.xx.xx

# 成功以后，在当前 shell 内，连接服务器 B
ssh root@yy.yy.yy.yy
```

## 备忘

```sh
# 删除
ssh-add -d ~/.ssh/id_rsa

# 删除所有
ssh-add -D

# 查看指纹
ssh-add -L
```

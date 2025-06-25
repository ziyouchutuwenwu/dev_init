# msf 环境

## 步骤

### 准备工作

启动

```sh
docker run --rm -d --name msf \
  --net=host -it \
  metasploitframework/metasploit-framework

# 远程调用
docker exec msf bash -c "./msfrpcd -U mmc -P 123456 -a 0.0.0.0 -p 55553"
```

### 调试

```sh
docker exec -it msf /usr/src/metasploit-framework/msfconsole
```

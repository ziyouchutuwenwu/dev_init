# 远程调试

## 服务端

编译好的 bin 复制到远程服务器

```sh
gdbserver :12345 ./xxxxxx
```

## 调试端

vscode 的 launch.json，类似下面

```json
{
  "type": "gdb",
  "request": "launch",
  "name": "remote_debug",
  "target": "${workspaceFolder}/output/main",
  "cwd": "${workspaceRoot}",
  "autorun": ["target remote 192.168.88.100:12345", "load ./output/main"],
  "gdbpath": "/usr/bin/gdb-multiarch"
}
```

# erlang 虚拟机调试

## 步骤

### 构建

```sh
./configure; make TYPE=debug; make
```

### 调试

[参考连接](https://max-au.com/debugging-the-beam/)

### 查看启动参数

```sh
./bin/cerl -debug -lldb
```

### vscode 配置

launch.json

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "gdb",
      "type": "cppdbg",
      "request": "launch",
      "stopAtEntry": true,
      "program": "${workspaceFolder}/bin/x86_64-pc-linux-gnu/beam.debug.smp",
      "args": [
        "--",
        "-root",
        "${workspaceFolder}",
        // 这里和下面的环境变量必须都要设置，如果这里不设置，vm 会崩溃
        "-bindir",
        "${workspaceFolder}/bin/x86_64-pc-linux-gnu/"
      ],
      "cwd": "${workspaceFolder}",
      "environment": [
        {
          "name": "BINDIR",
          "value": "${workspaceFolder}/bin/x86_64-pc-linux-gnu/"
        }
      ],
      "MIMode": "gdb",
      "setupCommands": [
        {
          "description": "Load Erlang Pathologist Toolkit",
          "text": "-interpreter-exec console \"source -v ${workspaceRoot}/erts/etc/unix/etp-commands\"",
          "ignoreFailures": true
        }
      ]
    }
  ]
}
```

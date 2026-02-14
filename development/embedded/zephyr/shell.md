# shell

## 说明

导出给 shell，一般测试时用

## 例子

```c
#include <zephyr/shell/shell.h>

static int demo_cmd(const struct shell *sh, size_t argc, char **argv, void *data)
{
  if (argc != 2) {
    shell_print(sh, "用法: %s <参数>", argv[0]);
    return -EINVAL;
  }

  shell_print(sh, "接收到的参数: %s", argv[1]);
  return 0;
}

// 第一个参数为 shell 内的命令
SHELL_CMD_REGISTER(demo, NULL, "测试命令，支持一个参数", demo_cmd);
```

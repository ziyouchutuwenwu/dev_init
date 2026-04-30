# opencode

## 说明

配置文件路径

```sh
$HOME/.config/opencode/opencode.jsonc
```

## 用法

### 安装

```sh
npm i -g opencode-ai
```

### 执行命令

```sh
opencode run "ls"
```

### mcp

```sh
opencode mcp ls
opencode mcp add
opencode mcp debug xxx
```

### session

```sh
opencode session list
opencode session delete xxx
```

session 导入导出

```sh
opencode export xxx > xx.json
opencode import xx.json
```

### 模型

```sh
opencode models
```

### key

放 api key 的地方

```sh
opencode providers list
```

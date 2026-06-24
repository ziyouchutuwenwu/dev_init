# kicad

## 说明

kicad 的 mcp

## 分类

准备

```sh
uv venv kicad_venv
```

### mcp-server-kicad

```sh
uv pip install mcp-server-kicad
```

命令

```sh
# 原理图
mcp-server-kicad-schematic
# pcb
mcp-server-kicad-pcb
# 符号管理
mcp-server-kicad-symbol
# 封装
mcp-server-kicad-footprint
# 项目
mcp-server-kicad-project
```

### kicad-mcp-pro

```sh
uv pip install kicad-mcp-pro
```

启动

```sh
kicad-mcp-pro --transport stdio
```

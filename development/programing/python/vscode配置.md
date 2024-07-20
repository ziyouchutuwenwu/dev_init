# vscode 配置

## 说明

解释器的配置和补全配置

## 例子

.vscode/settings.json

```json
{
  // 设置比较大的深度，防止快速修复失败
  "python.analysis.packageIndexDepths": [{ "name": "", "depth": 10 }],

  // 一定要用全路径，不支持环境变量
  "python.defaultInterpreterPath": "/home/xxx/dev/python/dev_env"
}
```

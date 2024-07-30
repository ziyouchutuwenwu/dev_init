# vscode 配置

## 说明

解释器的配置和补全配置

## 配置

.vscode/settings.json

```json
{
  "python.defaultInterpreterPath": "${env:HOME}/dev/python/dev_env",

  // 设置比较大的深度，防止快速修复失败
  "python.analysis.packageIndexDepths": [{ "name": "", "depth": 10 }]
}
```

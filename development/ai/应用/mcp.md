# mcp

## 配置

opencode.jsonc

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    // tailwindcss
    "tailwindcss": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "tailwindcss-mcp-server"
      ]
    },
    // tidewave
    "tidewave": {
      "type": "remote",
      "url": "http://localhost:4000/tidewave/mcp"
    }
  }
}
```

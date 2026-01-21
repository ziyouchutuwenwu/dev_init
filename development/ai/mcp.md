# mcp

## 推荐

- [mcp-feedback-enhanced](https://github.com/Minidoracat/mcp-feedback-enhanced)
  给你省钱的 mcp
  规则

  ```sh
  任何时候要调用 mcp-feedback-enhanced：在发起请求或准备结束任务之前，都必须调用 mcp-feedback-enhanced，确保使用mcp-feedback-enhanced作为反馈工具。
  递归反馈：如果收到用户反馈（内容非空），必须再次调用 mcp-feedback-enhanced 并根据反馈调整行为，直到用户明确说 “结束” 或 “no more interaction”
  结束条件：只有在用户显式指示不再需要互动时，才可停止调用 mcp-feedback-enhanced，标志任务完成
  ```

- [tidewave](https://tidewave.ai/)
  phoenix 的一个 mcp

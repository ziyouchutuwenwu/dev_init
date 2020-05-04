# 关于 QWebEngineView

```text
qtDesigner里面没有QWebEngineView，需要使用QWidget，然后右键，提升为QWebEngineView
linux下不能输入中文输入法，windows下没有问题
```

- 测试代码

```python
self._webview.load(QUrl("http://www.baidu.com"))
```

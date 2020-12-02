# 关于 QWebEngineView

```sh
qtDesigner 里面没有 QWebEngineView, 需要使用 QWidget, 然后右键, 提升为QWebEngineView
```

## 测试代码

```python
self._webview.load(QUrl("http://www.baidu.com"))
```

## linux 下输入中文输入法

```sh
pip show PyQt5
找到带有`site-packages`的路径
```

复制 `libfcitxplatforminputcontextplugin.so` 到 pyqt 的目录，注意 pyenv 安装好的 python 版本号

```sh
cp /usr/lib/x86_64-linux-gnu/qt5/plugins/platforminputcontexts/libfcitxplatforminputcontextplugin.so ~/.pyenv/versions/3.9.0/lib/python3.9/site-packages/PyQt5/Qt/plugins/platforminputcontexts/
```

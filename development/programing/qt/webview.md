# webview

webview 需要子类化，否则不能打开 href 连接

## 步骤

### 安装库

```sh
sudo pacman -S qt5-webengine
```

### pro 文件

```sh
QT += webenginewidgets
```

### ui 文件

拖一个 **QWebEngineView** 控件

### QWebEngineView 子类化

webview.h

```h
#pragma once

#include <QtWebEngineWidgets/QWebEngineView>

class WebView: public QWebEngineView{
    Q_OBJECT
public:
    explicit WebView(QWidget *parent = nullptr);
protected:
    QWebEngineView *createWindow(QWebEnginePage::WebWindowType);
signals:
};
```

webview.cpp

```cpp
#include "webview.h"

WebView::WebView(QWidget *parent) : QWebEngineView(parent){}

QWebEngineView *WebView::createWindow(QWebEnginePage::WebWindowType)
{
    return this;
}
```

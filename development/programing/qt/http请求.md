# http 请求

## 例子

初始化

```cpp
QNetworkAccessManager* manager;
QTextBrowser* pageBrowser;
```

```cpp
pageBrowser = new QTextBrowser(this);
pageBrowser->setFixedSize(600,400);
manager = new QNetworkAccessManager(this);
connect(manager,&QNetworkAccessManager::finished,this, &HttpDemo::replyFinished);
manager->get(QNetworkRequest(QUrl("http://www.baidu.com")));
```

```cpp
void HttpDemo::replyFinished(QNetworkReply *reply)
{
    QString all = reply->readAll();
    pageBrowser->setText(all);
    reply->deleteLater();
}
```

# 异步刷新 ui

基于 signal 和 slot

## 代码

msg.h

```h
#ifndef MSG_H
#define MSG_H

#include <QString>

typedef struct _Msg{
    int intInfo;
    QString strInfo;
}Msg;

#endif
```

demo_thread.h

```h
#ifndef DEMOTHREAD_H
#define DEMOTHREAD_H

#include <QThread>
#include "msg.h"

class DemoThread : public QThread
{
    Q_OBJECT
public:
    explicit DemoThread(QObject *parent = 0);
    Msg msg;

protected:
    void run();
signals:
    void uiUpdateSignal(Msg msg);
};

#endif

```

demo_thread.cpp

```cpp
#include "demothread.h"

DemoThread::DemoThread(QObject *parent) :
    QThread(parent)
{
}

void DemoThread::run()
{
    msg.intInfo = 999;
    msg.strInfo = "测试数据";

    emit uiUpdateSignal(msg);
}
```

mainwindow.h

```h
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "demothread.h"

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onUiUpdate(Msg msg);

private:
    Ui::MainWindow *ui;
    DemoThread* _thread;
};
#endif
```

mainwindow.cpp

```cpp
#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);


    qRegisterMetaType<Msg>("Msg");
    _thread = new DemoThread();
    connect(_thread, SIGNAL(uiUpdateSignal(Msg)), this, SLOT(onUiUpdate(Msg)));
    _thread->start();
}


void MainWindow::onUiUpdate(Msg msg)
{
    ui->_textEdit->append(QString::number(msg.intInfo));
    ui->_textEdit->append(msg.strInfo);
}

MainWindow::~MainWindow()
{
    delete ui;
}
```

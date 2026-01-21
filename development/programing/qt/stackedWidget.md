# stackedWidget

类似大号的 tabbar

## 例子

```cpp
ui->_stackedWidget->removeWidget(ui->page);
ui->_stackedWidget->removeWidget(ui->page_2);


QPushButton* button1 = new QPushButton("demo1");
ui->_stackedWidget->addWidget(button1);

QPushButton* button2 = new QPushButton("demo2");
ui->_stackedWidget->addWidget(button2);

QPushButton* button3 = new QPushButton("demo3");
ui->_stackedWidget->addWidget(button3);
```

```cpp
ui->_stackedWidget->setCurrentIndex(1);
```

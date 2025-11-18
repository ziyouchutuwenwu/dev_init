# listwidget

自定义的例子

## 基础用法

增加一行

```cpp
listWidget->addItem(xxx)
```

删除某一行

```cpp
listWidget->takeItem(2)
```

## 自定义 ui

### 代码

```cpp
QListWidgetItem* item = new QListWidgetItem();
item->setSizeHint(QSize(ui->_listWidget->size().width() - 2, 40));
ui->_listWidget->addItem(item);

QPushButton* button = new QPushButton("demo");
ui->_listWidget->setItemWidget(item, button);
```

```cpp
QListWidgetItem* item = ui->_listWidget->item( ui->_listWidget->count() - 1);
QPushButton* btnItem = (QPushButton*)ui->_listWidget->itemWidget(item);
btnItem->setText("aaaaaaaaa");
```

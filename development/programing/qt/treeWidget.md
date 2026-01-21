# treeWidget

## 例子

```cpp
ui->_treeWidget->setColumnCount(1);
QTreeWidgetItem* root = new QTreeWidgetItem(ui->_treeWidget, QStringList(QString("根节点")));
QTreeWidgetItem* leaf1 = new QTreeWidgetItem(root, QStringList(QString("测试1")));
root->addChild(leaf1);

QTreeWidgetItem *leaf2 = new QTreeWidgetItem(root, QStringList(QString("测试2")));
leaf2->setCheckState(0, Qt::Checked);
root->addChild(leaf2);


QList<QTreeWidgetItem*> rootList;
rootList.append(root);

ui->_treeWidget->insertTopLevelItems(0, rootList);
```

## 自定义 ui

```cpp
QPushButton* button = new QPushButton("demo");
ui->_treeWidget->setItemWidget(leaf1, 0, button);
```

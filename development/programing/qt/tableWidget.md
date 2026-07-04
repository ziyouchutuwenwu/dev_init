# tableWidget

## 用法

### 设置列数

```cpp
QStringList* titleList = new QStringList();
titleList->append("标题1");
titleList->append("标题2");
titleList->append("标题3");
titleList->append("标题4");
titleList->append("标题5");
ui->tableWidget->setColumnCount(titleList->length());
ui->tableWidget->setHorizontalHeaderLabels(*titleList);
```

### 表头

设置表头

```cpp
QStringList* rowList = new QStringList();
rowList->append("数据1");
rowList->append("数据2");
rowList->append("数据3");
rowList->append("数据4");
rowList->append("数据5");
ui->tableWidget->setRowCount(rowList->length());
ui->tableWidget->setVerticalHeaderLabels(*rowList);
```

不显示表头

```cpp
ui->tableWidget->verticalHeader()->setVisible(false);
```

### 添加普通数据

```cpp
ui->tableWidget->insertRow(0);
ui->tableWidget->setItem(0, 0,new QTableWidgetItem("a0"));
ui->tableWidget->setItem(0, 1,new QTableWidgetItem("a1"));
ui->tableWidget->setItem(0, 2,new QTableWidgetItem("a2"));
ui->tableWidget->setItem(0, 3,new QTableWidgetItem("a3"));
ui->tableWidget->setItem(0, 4,new QTableWidgetItem("a4"));

ui->tableWidget->insertRow(1);
ui->tableWidget->setItem(1, 0,new QTableWidgetItem("b0"));
ui->tableWidget->setItem(1, 1,new QTableWidgetItem("b1"));
ui->tableWidget->setItem(1, 2,new QTableWidgetItem("b2"));
ui->tableWidget->setItem(1, 3,new QTableWidgetItem("b3"));
ui->tableWidget->setItem(1, 4,new QTableWidgetItem("b4"));

ui->tableWidget->insertRow(2);
ui->tableWidget->setItem(2, 0,new QTableWidgetItem("c0"));
ui->tableWidget->setItem(2, 1,new QTableWidgetItem("c1"));
ui->tableWidget->setItem(2, 2,new QTableWidgetItem("c2"));
ui->tableWidget->setItem(2, 3,new QTableWidgetItem("c3"));
ui->tableWidget->setItem(2, 4,new QTableWidgetItem("c4"));
```

### 自定义单元格

```cpp
QComboBox *comBox = new QComboBox();
comBox->addItem("F");
comBox->addItem("M");
ui->tableWidget->setCellWidget(0, 3, comBox);
```

### 插入图片

```cpp
ui->tableWidget->setItem(0, 1, new QTableWidgetItem(QIcon("images/IED.png"), "Jan's month"));
ui->tableWidget->setItem(1, 1, new QTableWidgetItem(QIcon("images/IED.png"), "Feb's month"));
ui->tableWidget->setItem(2, 1, new QTableWidgetItem(QIcon("images/IED.png"), "Mar's month"));
```

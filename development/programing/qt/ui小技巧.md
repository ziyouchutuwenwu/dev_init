# ui 小技巧

## css 影响子控件

设置 css 的时候，直接设置 css 的话，会影响子控件

```css
#demo_id {
  background-image: url(:/apic35041.jpg);
}
```

## button

### 设置背景色

```cpp
pushButton->setPalette(QColor(0,255,255));
```

### 图片文字布局

| 布局方式 | 类名        |
| -------- | ----------- |
| 上下     | QToolButton |
| 左右     | QPushButton |

### QToolButton 设置 action

```cpp
ui->toolButton->setDefaultAction(ui->actionaaa);
```

## 设置 icon

菜单设置 icon

```cpp
ui->actiondemo->setIcon(QIcon(":/weixin.png"));
```

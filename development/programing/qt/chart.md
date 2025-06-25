# chart

自定义 chart 的例子

## 步骤

图表需要放在 QChartView 类上面

### 准备工作

pro 文件

```sh
QT       += charts
```

### 创建 chart 类

创建带 ui 的类，修改代码

chart.h

```h
#ifndef CHART_H
#define CHART_H

#include <QWidget>
#include <QChartView>
using namespace QtCharts;

namespace Ui {
class Chart;
}

class Chart : public QChartView
{
    Q_OBJECT

public:
    explicit Chart(QWidget *parent = nullptr);
    ~Chart();

private:
    Ui::Chart *ui;
};

#endif // CHART_H
```

chart.cpp

```cpp
#include "chart.h"
#include "ui_chart.h"
#include <qsplineseries.h>

Chart::Chart(QWidget *parent) : QChartView(parent), ui(new Ui::Chart)
{
    ui->setupUi(this);

    QSplineSeries *series1 = new QSplineSeries();
    *series1 << QPointF(1, 3) << QPointF(3, 4) << QPointF(7, 3)<< QPointF(12, 3)<< QPointF(16, 4) ;

    QChart *chart = new QChart();
    chart->addSeries(series1);
    chart->setTitle("测试");
    chart->createDefaultAxes();
    chart->axisX()->setRange(0, 20);
    chart->axisY()->setRange(0, 10);

    setRenderHint(QPainter::Antialiasing);
    setChart(chart);
}

Chart::~Chart()
{
    delete ui;
}
```

### 主窗口 ui

添加一个控件，提升为 Chart 类，即可

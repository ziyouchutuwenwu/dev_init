# 倍福

## 运动控制

### 添加设备

添加好伺服驱动器的 xml 文件，然后扫描设备，会提示创建 nc-configuration，创建以后，在 Motion 里面会自动创建一个 motion

### 配置电机参数

在 Devices 下伺服驱动器上双击，选择 Drive Manager，在里面选电机

```bash
Device -> Channel X -> Motor and Feedback
选择Scan feedback 1/ motor 或者 Select motor
```

### 手动测试

#### 点动测试

配置好电机参数以后，切换为 run mode，在 motion 里面，选中 axis 的 online 标签页

```bash
F1-F4 为点动模式
F5 和 F6 为手动转动，根据Target Position和Target Velocity设置
F8是对错误进行复位
F9回到原点，如果有编码器，根据编码器的位置到原点；如果没有，则根据0为原点
```

#### NC 参数

具体轴里面最重要的一个参数是 enc 的 parameter 里面的

```bash
Scaling Factor Numerator 是电机转一圈最终工件移动量
Scaling Factor Denominator 是编码器反馈脉冲数
```

例如：电机转一圈，带动丝杠移动 5mm，AX5000 的编码器反馈为一圈 1048576，那么
Scaling Factor Numerator =5，
Scaling Factor Denominator=1048576。
例如：电机转一圈，带动一个圆形负载移动 360°，
那么 Scaling Factor Numerator =360，Scaling Factor Denominator=1048576。（注：如用第三
方伺服驱动器，那么编码器反馈不再是 1048576，需要根据第三方设备的实际反馈量来进
行设置）

### PLC 编程控制

#### 添加 lib

Motion -> PTP -> Tc2_MC2

#### 添加变量

Main 里面

```pascal
VAR
	axis1 : AXIS_REF;
END_VAR
```

#### 变量连接到 PLC

编译，Motion 展开 axes，找到 axis1，setting 页面，Link To PLC，找到 Main.axis1
建立 HMI，拖个控件，绑定变量为 MAIN.axisx.NcToPlc.ActPos
运行，即可在 HMI 里面看到电机当前的位置；

##### 注意的地方

注意，具体轴设置了`Link To PLC`以后，不能点动控制

#### 添加 HMI 做控制

显示电机是否上电需要拿 MAIN.axisx.NcToPlc.StateDWord.20

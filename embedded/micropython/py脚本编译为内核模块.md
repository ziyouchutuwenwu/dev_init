#### 在ports/stm32/modules/里面写自己的py模块
- test.py
```
import pyb

def on(light_id):
    pyb.LED(light_id).on()

def off(light_id):
    pyb.LED(light_id).off()
```

####  编译
```
make -C ports/stm32 BOARD=PYBV11 MICROPY_FLOAT_IMPL=double
```
编译出来以后，烧写固件

#### 开发板切换为正常开发模式，main.py
```
import pyb
import test

while True:
	test.on(1)
	pyb.delay(500)
	test.off(1)
	pyb.delay(500)
```
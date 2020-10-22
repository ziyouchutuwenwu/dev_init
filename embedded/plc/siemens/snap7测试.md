# snap 读写测试

可以使用淘宝店 `蝴蝶科技`的库, 也可以使用 python-snap7 来测试

## plc 配置

```bash
硬件组态, 防护与安全, 连接机制, 允许来自远程对象的PUT/GET通信访问
db块,右键,属性,优化的块访问,去掉勾选
```

## python 库安装

### pip 安装

```bash
pip install python-snap7
```

### debian 需要手工编译 so 库

[这里](https://sourceforge.net/projects/snap7)下载源码

### 编译

```bash
cd \$SNAP_SRC_DIR/build/unix/
make -f x86_64_linux.mk all
cp build/bin/x86_64-linux/libsnap7.so ~/.pyenv/versions/3.9.0/lib/python3.9/site-packages/snap7/bin
```

### 修改 pip 的 python 脚本

```python
import os

class Snap7Library(object):
    ......

    def **init**(self, lib_location=None):
        cwd = os.path.abspath(os.path.dirname(**file**))
        lib_location = cwd + '/bin/libsnap7.so'
```

## 测试代码

```python
import snap7

if __name__ == '__main__':
    plc = snap7.client.Client()
    plc.connect('192.168.88.111', 0, 0)

    # 这里读取 i0.0
    data = plc.read_area(0x81, 1, 0, 1)
    print(data)
```

## 注意

关于 plc 的机架号和槽号的资料
plc 型号 | 机架号(Rack) | 槽号(Slot)
---- | --- | ---
S7-200 | 0 | 1
S7-200 Smart | 0 | 1
S7-300 | 0 | 2
S7-400 | 0 | 2
S7-1200 | 0 | 0
S7-1500 | 0 | 0

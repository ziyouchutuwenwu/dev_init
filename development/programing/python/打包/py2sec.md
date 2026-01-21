# py2sec

把代码编译为动态库，适用于把模块化的库编译为 so

## 方案

推荐基于 **cython** 的 [py2sec](https://github.com/cckuailong/py2sec)

## 说明

需要 pip 安装的插件不支持编译为动态库，部署的时候，也需要 pip 安装

### 安装依赖

```sh
pip install cython
```

### 复制模板

复制文件到项目根目录

- py2sec.py
- py2sec_build.py.template

### 测试代码

目录结构

```sh
.
├── libs
│   ├── aaa
│   │   ├── demo1.py
│   │   └── __init__.py
│   └── bbb
│       ├── demo2.py
│       └── __init__.py
├── main.py
├── py2sec_build.py.template
└── py2sec.py
```

demo1.py

```python
from loguru import logger

def show(msg):
    logger.debug(msg)
```

demo2.py

```python
from loguru import logger

def show(msg):
    logger.debug(msg)
```

main.py

```python
from libs.aaa import demo1
from libs.bbb import demo2

if __name__ == "__main__":
    demo1.show("demo1")
    demo2.show("demo2")
```

编译, 目录模式，目前只支持单目录

如果项目本身就是多目录，可以先放一个目录里面，编译以后，再把编译结果复制出来

```sh
python py2sec.py -d libs -r
```

测试调用

```python
from result.libs.aaa import demo1
from result.libs.bbb import demo2

if __name__ == "__main__":
    demo1.show("demo1")
    demo2.show("demo2")
```

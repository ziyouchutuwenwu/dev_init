# 调用 so

## 说明

调用 so

## 例子

### ctypes

python 自带，不需要三方库

```python
from loguru import logger
import ctypes

# 加载共享库
demo_lib = ctypes.CDLL('libdemo.so')

# 指定函数的参数类型和返回值类型（如果需要）
# demo_lib.add.argtypes = [ctypes.c_int, ctypes.c_int]
# demo_lib.add.restype = ctypes.c_int

result = demo_lib.add(3, 5)
logger.debug("result {}", result)
```

### cffi

需要 cffi

```python
from loguru import logger
import cffi

ffi = cffi.FFI()

ffi.cdef("""
    int add(int a, int b);
""")

demo_lib = ffi.dlopen('libdemo.so')
result = demo_lib.add(5, 3)
logger.debug("result {}", result)
```

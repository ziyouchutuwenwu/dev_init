# 调用 so

## 例子

```python
import ctypes

# 加载共享库
demo_lib = ctypes.CDLL('libdemo.so')

# 指定函数的参数类型和返回值类型（如果需要）
# demo_lib.add.argtypes = [ctypes.c_int, ctypes.c_int]
# demo_lib.add.restype = ctypes.c_int

result = demo_lib.add(3, 5)
print(result)
```

ffi

```sh
pip install cffi
```

```python
import cffi

ffi = cffi.FFI()

ffi.cdef("""
    int add(int a, int b);
""")

demo_lib = ffi.dlopen('libdemo.so')
result = demo_lib.add(5, 3)
print(result)
```

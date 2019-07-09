### 参考链接
```
https://github.com/habemus-papadum/kernel-grok
```
```
pip install scan-build --user
```
### 下载源码
- 生成compile_commands.json，这个用于给最后的ruby脚本转换为CMakeLists.txt
```
make defconfig
intercept-build make -j 12
```

### 以下一定要注意目录位置
- 在和内核源码同级目录执行
```
git clone https://github.com/habemus-papadum/kernel-grok.git
```

- 生成 CMakeLists.txt
```
cd linux-stable
../kernel-grok/generate_cmake
```

### 测试编译
```
mkdir build; cd build
cmake .. && make -j12
```
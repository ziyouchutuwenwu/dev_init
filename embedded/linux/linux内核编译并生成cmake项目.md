# linux 内核编译并生成 cmake 项目

## 参考链接

```bash
https://github.com/habemus-papadum/kernel-grok
```

## 下载需要的工具

```bash
pip install scan-build --user
```

## 下载源码

- 生成 compile_commands.json，这个用于给最后的 ruby 脚本转换为 CMakeLists.txt

```bash
make defconfig
intercept-build make -j 12
```

## 以下一定要注意目录位置

- 在和内核源码同级目录执行

```bash
git clone https://github.com/habemus-papadum/kernel-grok.git
```

- 生成 CMakeLists.txt

```bash
cd linux-stable
../kernel-grok/generate_cmake
```

## 测试编译

```bash
mkdir build; cd build
cmake .. && make -j12
```

# actor 例子

库在 [这里](https://github.com/AsynkronIT/protoactor-go)

例子的文档有问题，暂时观望

## 安装 protoc

安装 protobuf 需要的库

```sh
sudo apt install golang-goprotobuf-dev
```

编译 protoc

```sh
https://github.com/protocolbuffers/protobuf
cd protobuf
./autogen.sh
./configure --prefix=xxxxxx
make install
复制 protoc 到你需要的目录
```

## 安装 protoc-gen-gogoslick

```sh
git clone https://github.com/gogo/protobuf
cd protoc-gen-gogoslick
go install
```

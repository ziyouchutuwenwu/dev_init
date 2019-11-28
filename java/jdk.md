# jdk 配置

- 转换 deb 包

```bash
sudo apt install java-package
去oracle官网下载tar包
fakeroot make-jpkg ./下载的tar包，生成deb包
sudo dpkg -i 安装deb包
```

- 如果你还安装了 openjdk，那么配置下 java 即可

```bash
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

- code ~/.profile

```bash
# export JAVA_HOME=/usr/lib/jvm/jdk-13
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH=$JAVA_HOME/bin:$PATH
```

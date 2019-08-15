# jdk配置

- 转换deb包

```bash
sudo apt-get install java-package
去oracle官网下载tar包
fakeroot make-jpkg ./下载的tar包，生成deb包
sudo dpkg -i 安装deb包
```

- 如果你还安装了openjdk，那么配置下java即可

```bash
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

- code ~/.profile

```bash
# for JRE
# export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
# for JDK
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
```

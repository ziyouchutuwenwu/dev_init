# jdk 配置

## oracle jdk

配置

```sh
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

## 环境变量

```sh
/usr/local/etc/profile.d/jdk.sh
```

```sh
export JAVA_HOME=/usr/local/lib/jvm/jdk1.8.0_231
export PATH=$JAVA_HOME/bin:$PATH
```

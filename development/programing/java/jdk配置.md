# jdk 配置

## oracle jdk

直接下载即可

### 配置

```sh
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

## 环境变量

### bash

```sh
vim /etc/profile.d/jdk.sh
```

```sh
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_231
export PATH=$JAVA_HOME/bin:$PATH
```

### zsh

zsh 比较特别, 需要

```sh
vim /etc/zsh/zshenv
```

```sh
emulate sh -c 'source /etc/profile'
```

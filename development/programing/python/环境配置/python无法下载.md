# python 无法下载

asdf 基于 pyenv

## 步骤

### 设置 mirror

```sh
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_BUILD_MIRROR_URL="https://npm.taobao.org/mirrors/python/"
asdf install python 3.10.8
```

### 手动下载

```sh
curl -C - https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tar.xz -o /tmp/Python-3.10.8.tar.xz
export PYTHON_BUILD_CACHE_PATH=/tmp/
asdf install python 3.10.8
```

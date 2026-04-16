# mirror

## 说明

适合只读的仓库，不适合带提交的

## 配置

```sh
git config --global url."https://gh-proxy.com/https://github.com/".insteadOf "https://github.com/"
```

测试

```sh
GIT_CURL_VERBOSE=1 git clone xxx
```

# mirror

## 说明

有的语言，设置了 mirror，还会去访问 github

## 配置

nodejs

```sh
mise settings node.mirror_url=https://npmmirror.com/mirrors/node/

mise settings ls
mise settings unset node.mirror_url
```

## 测试

```sh
mise install node@lts -v
```

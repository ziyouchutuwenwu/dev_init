# 常用

## 分支相关

创建本地分支

```sh
git checkout -b newbr
```

将本地分支推送到远程

```sh
git push origin newbr
```

将本地分支 newbr 关联到远程分支 newbr 上

```sh
git branch --set-upstream-to=origin/newbr
```

查看远程分支

```sh
git branch -a
```

# pull

两个人同时修改一分支代码的话，如果需要保留对方的代码，避免提交冲突，需要 `git pull --rebase`

## 例子

默认 main 分支上，用户 A

```sh
git commit -m "a1"
git commit -m "a2"
git push
```

默认 main 分支上，用户 B

```sh
git commit -m "b1"
git commit -m "b2"
```

此时，如果用户 B 直接 push，会提示错误

`git pull` 手工 merge 或者

使用 rebase 同步用户 A 在此分支上的修改

```sh
git pull --rebase
```

此时，B 用户查看`git log`，大概如下

```sh
b2
b1
a2
a1
```

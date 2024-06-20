# rebase

## 用法 1

把目标分支上的记录和当前分支合并，按照时间顺序排列成一条记录

新的记录是重新根据时间顺序生成的

### 例子

master 更新 c1

```sh
git checkout master
git commit -m c1
```

dev 分支基于 master 的 c1

```sh
git checkout -b dev
git commit -m "dev1"
git log --oneline --all --graph
```

master 节点更新 commit 为 c2

```sh
git checkout master
git commit -m c2
```

此时 dev 分支落后于 master 分支的 c2

```sh
git checkout dev
git rebase master
```

此时 dev 分支已基于 c2 做分支

## 用法 2

合并分支上的多次提交

```sh
git checkout -b dev
git commit -m "aaa in dev"
git commit -m "bbb in dev"
git commit -m "ccc in dev"
```

如果需要把这三次提交合并为一次，则

```sh
git rebase -i HEAD~3
```

出来的界面里面

```sh
第一行不动，保持 pick
后面的改成 s
```

ctrl + X，填写说明

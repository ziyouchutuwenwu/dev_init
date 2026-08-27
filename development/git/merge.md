# merge

## 说明

会保留所有的 git 记录

## 用法

```sh
git checkout -b dev
git commit -m "dev"
```

在 dev 分支里面，同步 master 的更新

```sh
git rebase master
```

```sh
git checkout main
git merge dev
```

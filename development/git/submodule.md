# submodule

## clone

父项目已经 clone

```sh
git submodule init
git submodule update
```

父项目还没 clone

```sh
git clone --recursive https://github.com/example/example.git
```

## 增

```sh
git submodule add -b $BRANCH_NAME https://xxxxxxxx $LOCAL_SUB_MODULE_DIR
```

## 删

```sh
git submodule deinit $LOCAL_SUB_MODULE_DIR
git rm $LOCAL_SUB_MODULE_DIR
# 这时，子模块文件被删除，同时 .gitmodules 文件中的相关信息被删除

# 还有一种情况，就是子模块刚被add，但是还没有commit的时候，这时如果反悔了，但是还想保留工作现场，可以这样。
# 如果不想保留，看下一条
git rm --cached $LOCAL_SUB_MODULE_DIR
rm -rf .git/modules/$LOCAL_SUB_MODULE_RELATIVE_DIR

# 或者直接全部删除
git submodule deinit --force $LOCAL_SUB_MODULE_DIR
```

## 改

引用仓库内，子模块的更新和 push 是和主仓库没有关系的，完全独立，因此，需要分开运行

- 分支需要先 checkout, 因为子模块的分支出于游离状态
- 在引用仓库内，更新子模块

```sh
cd demo_module
git checkout main
git add *
git commit -m "xxx"
git push
```

## 主仓库同步别人的修改

只需要多手动 pull 一下

```sh
git checkout main
git pull
```

## 注意（非常重要）

子模块需要注意头指针，需要先执行一下这个，否则头指针都是分离的

```sh
git submodule foreach --recursive 'git pull; git checkout main'
```

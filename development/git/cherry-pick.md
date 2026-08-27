# cherry-pick

## 用法

把提交复制到其他分支上

```sh
git checkout -b xxx
git commit -m 'aaa'
```

切换回 main

```sh
git checkout main
git cherry-pick aaa的 commit_id
```

会在 main 上看到同步了这个 commit

# hexo

## 配置

### 安装

```sh
npm install hexo-cli -g
```

### 创建

```sh
hexo init hexo_demo
cd hexo_demo
npm install
hexo server
```

### 页面

分类页

```sh
hexo new page about
```

文章页

```sh
hexo new xxx/aaa
```

### 测试

本地测试

```sh
hexo s
```

### 发布

安装插件

```sh
npm install hexo-deployer-git --save
```

\_config.yml

```yaml
title: 博客
language: zh-CN

url: https://xxx.github.io/aaa/
root: /aaa/

deploy:
  type: git
  repo: https://github.com/xxx/repo.git
  branch: gh-pages
```

生成静态页

```sh
hexo clean
hexo g
```

推送

```sh
hexo d
```

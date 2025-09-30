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

### 文章

```sh
hexo new xxx/aaa.md
```

### 主题

```sh
cd themes
git clone https://github.com/CodeDaraW/Hacker
```

```sh
cp -rf themes/Hacker/_config.example.yml _config.Hacker.yml
```

\_config.yml

```yaml
title: 博客

theme: Hacker
```

### 发布

安装插件

```sh
npm install hexo-deployer-git --save
```

\_config.yml

```yaml
url: https://xxx.github.io
root: /aaa/

deploy:
  type: git
  repository: https://github.com/xxx/repo.git
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

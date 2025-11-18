# sitemap

## 步骤

```sh
npm install hexo-generator-sitemap --save
```

\_config.yml

```yaml
sitemap:
  path: sitemap.xml
  rel: true
```

source/robots.txt

```txt
User-agent: *
Allow: /

Disallow: /admin/

Sitemap: https://xxx.com/sitemap.xml
```

# skills

## 说明

对 ai 做增强

## 列表

### 工程

[mattpocock/skills](https://github.com/mattpocock/skills)

```sh
/grill-with-docs  拷问需求
/tdd              测试驱动开发

# 安装
npx skills@latest add mattpocock/skills
```

[gstack](https://github.com/garrytan/gstack.git)

虚拟工程师团队

```sh
/office-hours     ai 问你问题，确认需求
/plan-ceo-review  天马行空的想法
/review           代码审查
/qa               测试

git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.gstack
cd ~/.gstack
./setup --host opencode
```

### 前端

claude design 提取为 skill

```sh
npx skills add ConardLi/garden-skills -s web-design-engineer --global
```

frontend-design

```sh
npx skills add https://github.com/anthropics/skills --skill frontend-design
```

[ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)

```sh
npm install -g uipro-cli
uipro init --ai opencode
```

### 浏览器

[playwright-cli](https://github.com/microsoft/playwright-cli)

```sh
npm install -g @playwright/cli@latest

# 不支持全局安装
playwright-cli install --skills
```

### seo

[seo-geo-claude-skills](https://github.com/aaron-he-zhu/seo-geo-claude-skills)

```sh
npx skills add aaron-he-zhu/seo-geo-claude-skills
```

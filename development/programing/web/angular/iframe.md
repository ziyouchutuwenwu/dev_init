# iframe

## 说明

动态设置 iframe 的高度

## 代码

```html
<div>
  <iframe
    src="https://www.oschina.net/"
    (resize)="onIframeResize()"
    (load)="onIframeResize()"
    id="content"
    frameborder="0"
    scrolling="yes"
    height="100px"
    width="100%"
  ></iframe>
</div>
```

xxx.ts

```typescript
  onIframeResize() {
    const headerHeightToHide = 65;
    const footerHightToHide = 70;
    const height = document.documentElement.clientHeight + headerHeightToHide + footerHightToHide;
    const iframe = document.getElementById('content');
    (iframe as HTMLIFrameElement).style.height = String(height) + 'px';
  }
```

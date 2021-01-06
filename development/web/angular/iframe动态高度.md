# iframe 设置动态高度

## html

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

## ts

```typescript
  onIframeResize() {
    const headerHeightToHide = 65;
    const footerHightToHide = 70;
    const height = document.documentElement.clientHeight + headerHeightToHide + footerHightToHide;
    const iframe = document.getElementById('content');
    (iframe as HTMLIFrameElement).style.height = String(height) + 'px';
  }
```

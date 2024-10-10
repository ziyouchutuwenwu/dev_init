# wasm

## 说明

编译为 wasm 给 js 调用

## 例子

### zig 部分

demo.zig

```zig
const std = @import("std");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}
```

编译

```sh
zig build-exe src/demo.zig -static -target wasm32-freestanding -fno-entry --export=add

# 验证
wasm-dis xxx.wasm | grep 
```

### angular

ts

```typescript
import axios from "axios";

export class AppComponent {
  result: number | null = null;
  wasmInstance: WebAssembly.Instance | null = null;

  async ngOnInit() {
    await this.loadWasm();
  }

  async loadWasm() {
    try {
      const response = await axios.get("assets/demo.wasm", {
        responseType: "arraybuffer",
      });
      const bytes = new Uint8Array(response.data);
      const module = await WebAssembly.instantiate(bytes);
      this.wasmInstance = module.instance;
    } catch (error) {
      console.error("Error loading WASM:", error);
    }
  }

  wasmAdd() {
    if (this.wasmInstance) {
      console.log(this.wasmInstance.exports);
      const addFunction = this.wasmInstance.exports["add"] as (a: number, b: number) => number;
      const result = addFunction(5, 3);
      this.result = result;
    } else {
      console.warn("wasm instance is not initialized.");
    }
  }
}
```

```html
<div>
  <h1>wasm with angular</h1>
  <button (click)="wasmAdd()">call wasm</button>
  <p>result: {{ result }}</p>
</div>
```

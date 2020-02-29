# 直接上代码

- CommunicationService

```typescript
import { Injectable } from "@angular/core";
import { Subject } from "rxjs";

@Injectable({
  providedIn: "root"
})
export class CommunicationService {
  private subject;

  sendMsg(message: any): void {
    this.subject.next(message);
  }

  /*
  this.communicationService.subscribe(message => {
    if (typeof message === 'string'){
    alert('string');
  }
  if ( message instanceof Object ){
    alert('object');
  }
  });
   */
  subscribe(onNext) {
    this.subject.subscribe(message => {
      if (message !== null) onNext(message);
    });
  }

  constructor() {
    this.subject = new Subject<any>();
  }
}
```

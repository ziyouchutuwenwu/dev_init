# 直接上代码

## CommunicationService

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

## CommunicationEntity.ts

```typescript
export class CommunicationEntity {
  public name: string;
  public info: any;
}
```

- 以 login 的 service 为例

```typescript
export const LOGIN = 'login';

@Injectable({
  providedIn: 'root'
})
export class LoginoutService extends CommunicationService {

  constructor(
    private http: HttpClient
  ) {
    super();
  }

  doLogin(): void {
    this.http.get('http://127.0.0.1:1234/loginout/login', {responseType: 'text' })
      .subscribe(res => {
        const isLoggin = res;

        let msgEntity: CommunicationEntity;
        msgEntity = new CommunicationEntity();
        msgEntity.name = LOGIN;
        msgEntity.info = isLoggin;
        this.sendMsg(msgEntity);
      });
  }
```

- LoginComponent.ts

```typescript
onLogin() {
    this.loginService.doLogin();
    this.loginService.subscribe(message => {
      if ( message.name === LOGIN) {
        const isLoggin = message.info;
        // if ( isLoggin ) {
        //   this.authService.login();
        //   this.router.navigate(['platform_select']);
        // }
      }
    });
  }
```

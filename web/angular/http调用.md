# 直接上代码

## 内置 http

```typescript
constructor(private http: HttpClient) {
  super();
}

const params = new URLSearchParams();
params.set("username", userName);
params.set("password", passWord);

// HttpHeaders 这个类比较特殊，不能先set再赋值，否则这个json是空的
const options = {
  headers: new HttpHeaders().set(
    "Content-Type",
    "application/x-www-form-urlencoded"
  ),
  withCredentials: true
};

this.http
  .post("http://localhost:1234/login", params.toString(), options)
  .subscribe(response => {

    const responseObject: any = Object.create(response);
    const isLoggin = responseObject.isLoggin;

    let msgEntity: CommunicationEntity;
    msgEntity = new CommunicationEntity();
    msgEntity.name = LOGIN;
    msgEntity.info = isLoggin;
    this.sendMsg(msgEntity);
  });
```

LoginComponent.ts

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

## 使用 axios

post 调用

```typescript
const params = {
  username: userName,
  password: passWord,
};

axios({
  method: "post",
  url: "http://localhost:1234/login",
  data: qs.stringify(params),
  headers: {
    "Content-Type": "application/x-www-form-urlencoded",
  },
})
  .then((response) => {
    console.log(response.data);
  })
  .catch((error) => {
    console.log(error);
  });
```

get 调用

```typescript
const param = {
  username: userName,
  password: passWord,
};

axios({
  method: "get",
  url: "http://localhost:1234/loginout/login",
  params: param,
})
  .then((response) => {
    console.log(response.data);
  })
  .catch((error) => {
    console.log(error);
  });
```

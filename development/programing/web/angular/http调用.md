# http 调用

内置的太麻烦了, 直接 axios

## axios

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
  // withCredentials: true,
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

## 忽略 ssl

```typescript
const agent = new https.Agent({
  rejectUnauthorized: false,
});
axios.get("https://xxx.com/xxx", { httpsAgent: agent });
```

# hackney

## 用法

rebar.config

```erlang
{deps,[
  {hackney, "1.25.0"}
]}.
```

代码

```erlang
get_demo() ->
  application:ensure_all_started(hackney),
  ReqHeaders = [],
  Path = <<"http://127.0.0.1:8100">>,
  ReqBody = << "{
      \"name\": \"aaaa\",
      \"pass\": \"bbb\"
  }" >>,
  Options = [],
  {ok, _StatusCode, _RespHeaders, _ClientRef} = hackney:request(get, Path, ReqHeaders, ReqBody, Options).

%% curl -d "name=dongguan" http://127.0.0.1:8100
form_post_demo() ->
  application:ensure_all_started(hackney),
  ReqHeaders = [{<<"Content-Type">>, <<"application/x-www-form-urlencoded">>}],
  Path = <<"http://127.0.0.1:8100">>,
  Form = {form,  [{<<"name">>,<<"aaa">>}, {<<"pass">>,<<"bbb">>}]},
  Options = [],
  hackney:post(Path, ReqHeaders, Form, Options).

%% curl -H "Content-Type:application/json" -X POST --data '{"name": "sunshine"}' http://127.0.0.1:8100
json_post_demo() ->
  application:ensure_all_started(hackney),

  ReqBody = << "{
      \"name\": \"aaaa\",
      \"pass\": \"bbb\"
  }" >>,
  ReqHeaders = [{<<"Content-Type">>, <<"application/json">>}],
  Path = <<"http://127.0.0.1:8100">>,
  Method = post,
  {ok, ClientRef} = hackney:request(Method, Path, ReqHeaders, stream, []),
  ok  = hackney:send_body(ClientRef, ReqBody),
  {ok, _Status, _Headers, ClientRef} = hackney:start_response(ClientRef),
  {ok, _Body} = hackney:body(ClientRef).
```

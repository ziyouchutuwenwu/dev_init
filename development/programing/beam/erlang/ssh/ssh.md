# ssh

## 例子

```erlang
Opts = [
  {user, "root"},
  {password, "123456"},
  {silently_accept_hosts, true}
].

Opts = [
  {user, "root"},
  {key_cb, {ssh_agent, []}},
  {silently_accept_hosts, true}
].

application:ensure_all_started(ssh).

{ok, Conn} = ssh:connect("127.0.0.1", 22, Opts).
{ok, Chan} = ssh_connection:session_channel(Conn, 5000).
ssh_connection:exec(Conn, Chan, "whoami", infinity).

receive
  {ssh_cm, Conn, {data, Chan, 0, Data}} ->
    io:format("~s~n", [Data])
after 5000 ->
  io:format("无输出~n")
end.

ssh_connection:close(Conn, Chan).
ssh:close(Conn).
```

完整代码

```erlang
-module(ssh_client).
-export([upload_pubkey/4, run/4]).

-define(DEFAULT_PUBKEY, filename:join(os:getenv("HOME"), ".ssh/id_rsa.pub")).
-define(DEFAULT_TIMEOUT, 5000).

upload_pubkey(Host, User, Password, PubkeyFile) ->
    application:ensure_all_started(ssh),
    PubkeyFile1 =
        case PubkeyFile of
            undefined -> ?DEFAULT_PUBKEY;
            _ -> PubkeyFile
        end,
    {ok, PubkeyBin} = file:read_file(PubkeyFile1),
    % 去掉换行符，只取第一行
    PubkeyTrim =
        case binary:split(PubkeyBin, <<"\n">>, [global]) of
            [Line | _] -> Line;
            [] -> PubkeyBin
        end,
    EncodedPubkeyBin = base64:encode(PubkeyTrim),
    EncodedPubkeyStr = binary_to_list(EncodedPubkeyBin),

    Opts =
        case Password of
            undefined ->
                [{user, User}, {key_cb, {ssh_agent, []}}, {silently_accept_hosts, true}];
            _ ->
                [{user, User}, {password, Password}, {silently_accept_hosts, true}]
        end,
    {ok, Conn} = ssh:connect(Host, 22, Opts),
    {ok, Chan} = ssh_connection:session_channel(Conn, ?DEFAULT_TIMEOUT),
    CmdStr = lists:flatten(
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && " ++
            "echo '" ++ EncodedPubkeyStr ++ "' | base64 -d | " ++
            "(grep -qxF - ~/.ssh/authorized_keys || tee -a ~/.ssh/authorized_keys > /dev/null) && " ++
            "chmod 600 ~/.ssh/authorized_keys"
    ),
    ssh_connection:exec(Conn, Chan, CmdStr, infinity),
    _Out = receive_output(Conn, Chan, <<>>),
    ssh_connection:close(Conn, Chan),
    ssh:close(Conn),
    ok.

run(Host, User, Password, Cmd) ->
    application:ensure_all_started(ssh),
    Opts =
        case Password of
            undefined ->
                [{user, User}, {key_cb, {ssh_agent, []}}, {silently_accept_hosts, true}];
            _ ->
                [{user, User}, {password, Password}, {silently_accept_hosts, true}]
        end,
    {ok, Conn} = ssh:connect(Host, 22, Opts),
    {ok, Chan} = ssh_connection:session_channel(Conn, ?DEFAULT_TIMEOUT),
    ssh_connection:exec(Conn, Chan, Cmd, infinity),
    Output = receive_output(Conn, Chan, <<>>),
    ssh_connection:close(Conn, Chan),
    ssh:close(Conn),
    Output.

receive_output(Conn, Chan, Acc) ->
    receive
        {ssh_cm, Conn, {data, Chan, 0, Data}} ->
            receive_output(Conn, Chan, <<Acc/binary, Data/binary>>);
        {ssh_cm, Conn, {eof, Chan}} ->
            Acc;
        {ssh_cm, Conn, {exit_status, Chan, _Status}} ->
            Acc
    after ?DEFAULT_TIMEOUT ->
        Acc
    end.
```

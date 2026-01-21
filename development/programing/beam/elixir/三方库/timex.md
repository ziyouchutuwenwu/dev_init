# timex

## 说明

默认会引入 tzdata 库, 可以根据时区获取时间

另外可以把时间字符串转换为时间类型

## 步骤

mix.exs

```elixir
{:timex, "~> 3.0"}
```

代码

```elixir
Timex.now("Asia/Shanghai")
Timex.parse("2013-03-05 11:12:32", "%Y-%m-%d %H:%M:%S", :strftime)
```

## 注意

需要在非中文目录内运行，否则会有类似下面的错误

```sh
** (Mix) Could not start application tzdata: exited in: Tzdata.App.start(:normal, [])
    ** (EXIT) an exception was raised:
        ** (MatchError) no match of right hand side value: {:error, {:shutdown, {:failed_to_start_child, Tzdata.EtsHolder, {{:badmatch, {:error, {:read_error, {:file_error, [47, 104, 111, 109, 101, 47, 109, 109, 99, 47, 112, 114, 111, 106, 101, 99, 116, 115, 47, 121, 111, 122, 111, 47, 230, 160, 135, 230, 179, 168, 231, 179, 187, 231, ...], :enoent}}}}, [{Tzdata.EtsHolder, :load_ets_table, 1, [file: ~c"lib/tzdata/ets_holder.ex", line: 63]}, {Tzdata.EtsHolder, :load_release, 0, [file: ~c"lib/tzdata/ets_holder.ex", line: 56]}, {:gen_server, :init_it, 2, [file: ~c"gen_server.erl", line: 980]}, {:gen_server, :init_it, 6, [file: ~c"gen_server.erl", line: 935]}, {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 241]}]}}}}
            (tzdata 1.1.1) lib/tzdata/tzdata_app.ex:13: Tzdata.App.start/2
            (kernel 9.2.4) application_master.erl:293: :application_master.start_it_old/4
```

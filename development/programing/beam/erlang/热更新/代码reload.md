# 代码 reload

## 说明

### 做成模块

reloading.erl

```sh
-module(reloading).

-export([reload/0]).
% -define(PROJECT_NAME, "XXX").

reload() ->
  % EBinDir = "./_build/default/lib/" ++ ?PROJECT_NAME ++ "/ebin/",
  % SrcFileList = filelib:fold_files("./src/", ".*.erl", true, fun(F, AccIn) -> [F | AccIn] end, []),
  SrcFileList = filelib:wildcard("src/**/*.erl"),

  lists:foreach(fun(SrcFile) ->
      FileName = filename:rootname(filename:basename(SrcFile)),
      ModNameAtom = list_to_existing_atom(FileName),
      case ModNameAtom of
        ?MODULE ->
          ignore;
        _ ->
          c:c(SrcFile)
          % case compile:file(SrcFile, {outdir, EBinDir}) of
          %   {ok, ModName} ->
          %     % code:purge(ModName),
          %     % code:load_file(ModName);
          %     c:l(ModName);
          %   _ ->
          %     io:format("模块 ~p 编译失败，请检查~n", [SrcFile])
          % end
      end
  end,
  SrcFileList).
```

### shell 下

```erlang
% 无需路径
c(aa).

% 如果是新创建的文件，需要路径
c("./src/example/aa.erl").

% 路径
ls().
pwd().
```

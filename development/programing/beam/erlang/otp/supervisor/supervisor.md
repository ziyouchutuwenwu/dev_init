# supervisor

## 配置

### SupervisorFlags

- period 字段单位为 `s`

- strategy
  子进程绑定策略配置

  | strategy           | 说明                                                             |
  | ------------------ | ---------------------------------------------------------------- |
  | one_for_one        | 默认的重启策略，重启挂掉的子进程                                 |
  | one_for_all        | 当错误事件出现时，重启所有的子进程                               |
  | rest_for_one       | 重启失败的子进程，以及所有在它后面启动的进程                     |
  | simple_one_for_one | 所有的子进程是同一种类型，需手动 `supervisor:start_child` 来创建 |

- auto_shutdown
  supervisor 配置退出的方式

  | auto_shutdown   | 说明                                                                |
  | --------------- | ------------------------------------------------------------------- |
  | never           | supervisor 不自动退出                                               |
  | any_significant | 任何一个标记 significant 为 true 的子进程退出，然后 supervisor 退出 |
  | all_significant | 所有标记 significant 为 true 的子进程退出，然后 supervisor 退出     |

### ChildSpecs

- 子进程 `significant` 标记

  如果 `supervisor` 的 `auto_shutdown` 为 `any_significant` 或者 `all_significant`, 则可以配置 `significant => true`

- restart
  子进程重启策略

  | restart   | 说明                                 |
  | --------- | ------------------------------------ |
  | permanent | 总是重启子进程。所有进程的默认值     |
  | transient | 只有在非正常中止的时候，才重启子进程 |
  | temporary | 子进程是临时进程，子进程绝不重启     |

- shutdown
  子进程关闭模式，单位 `ms`

  | shutdown    | 说明                                                                                                                                                                                           |
  | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | brutal_kill | 使用 exit(Child, kill) 的模式来杀死子进程                                                                                                                                                      |
  | 2000        | 进程在被强制干掉之前有 2000 毫秒的时间料理后事自行终止，实际过程是 supervisor 给子进程发送一个 exit(Child, shutdown) 然后等待 exit 信号返回,在指定时间没有返回则将子进程使用 exit(Child, kill) |
  | infinity    | 当一个子进程是 supervisor 那么就要用 infinity,意思是给 supervisor 足够的时间进行重启启                                                                                                         |

## 注意

- 如果需要多种子进程, 直接在 init 的 Children 里面添加即可
- 在 module 的 start_func 的函数内，需要显式调用 spawn_link 来创建子进程
- 被 `terminate_child` 杀掉的子进程，无法重启

### 普通子进程模式

`start_link` 返回的是父进程 `pid`

### simple_one_for_one 比较特殊

- 只支持单一种类子进程

- 当在 `period` 周期内， 重启次数超过 `intensity` 的值，则所有子进程都会被 `shutdown`

- `start_child` 的 `Args` 会追加到子进程 `module` 的 `start_func` 的参数列表内

- `start_child` 不会触发 `supervisor` 的 `init` 回调

- 对应的 `start_func` 的返回值必须是 `{ok, Pid}`

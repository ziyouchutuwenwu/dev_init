# preempt

## 说明

arm 板只支持 CONFIG_PREEMPT

CONFIG_PREEMPT_RT 实时性最好

## 步骤

```sh
make linux-menuconfig
```

```sh
General setup  --->
  [*] Configure standard kernel features (expert users)
  [*] Fully Preemptible Kernel (Real-Time)

# 高精度定时器
General setup  --->
  Timers subsystem  --->
    [*] High Resolution Timer Support

# 省电加减少抖动
General setup  --->
  Timers subsystem --->
    Timer tick handling
      (X) Full dynticks system (tickless)

# 关闭调试
Kernel hacking  --->
  [ ] Debug preemptible kernel
  Lock Debugging (spinlocks, mutexes, etc...)  --->
    [ ] Sleep inside atomic section checking
  [ ] Debug shared IRQ handlers


# 内核 cmdline 中加
# isolcpus 调度器不给她普通任务
# nohz_full 停止周期性的 tick 中断，减少抖动
# rcu_nocbs rcu 转移到其它核，不让他们打断
Processor type and features  --->
  [*] Built-in kernel command line
  (isolcpus=3 nohz_full=3 rcu_nocbs=3) Built-in kernel command string
```

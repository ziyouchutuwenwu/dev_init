# ssh 多层跳板

主机 a 经过 bcd 的代理，最后到达 e

## 步骤

最后的出口机上执行，ssh 端口的流量转发到 7777

```sh
ssh \
  -o "StrictHostKeyChecking no" \
  -CfN -L 0.0.0.0:7777:出口机IP:22 root@出口机IP -p 22
```

跳板机每层设置端口转发

```sh
ssh \
  -o "StrictHostKeyChecking no" \
  -CfN -L 0.0.0.0:7777:上层跳板ip:7777 root@上层跳板ip -p 22
```

本地

流量转发

```sh
ssh \
  -o "StrictHostKeyChecking no" \
  -CfND 0.0.0.0:7777 root@第一层跳板ip -p 7777
```

映射 shell

```sh
ssh \
  -o "StrictHostKeyChecking no" \
  -CfND -L 0.0.0.0:7777:第一层跳板ip:7777 root@第一层跳板ip -p 22

ssh \
  -o "StrictHostKeyChecking no" \
  root@127.0.0.1 -p 7777
```

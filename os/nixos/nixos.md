# nixos

## 说明

/etc/nixos/configuration.nix 里面，先配置

```nix
services.openssh.enable = true;
services.openssh.settings.PermitRootLogin = "yes";
```

## 步骤

config 目录复制到 /etc/nixos/ 下

configuration.nix

```nix
imports = [
  ./hardware-configuration.nix
  ./config
];
```

第一次运行

```sh
nixos-rebuild switch --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org/"
```

后面运行

```sh
nixos-rebuild switch
```

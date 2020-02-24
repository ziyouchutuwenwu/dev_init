# electron 配置

## 如果版本不对

```bash
npm config set electron_custom_dir 8.0.1
```

## 如果提示权限不对

```bash
sudo sysctl kernel.unprivileged_userns_clone=1
```

## 通过这个检查

```bash
cat /proc/sys/kernel/unprivileged_userns_clone
```

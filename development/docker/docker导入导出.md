# docker 导入导出

## 用法

### 容器保存为 tar

比 save 保存的文件小很多

```sh
docker export ${CONTAINER_ID} > xxx.tar
```

### 从容器 tar 还原为 image

```sh
docker import xxx.tar image_name:tag
```

### 当前容器直接保存为 image

```sh
docker commit ${CONTAINER_ID} image_name:tag
```

### 保存 image 为 tar 包

使用 tag 保存，不然 load 的时候，会显示 `<none>`

```sh
docker save -o xxx.tar redis:5.0.0
```

### tar 包还原为 image，不可以重命名

这里的 tar 是指`docker images`保存出的 tar

```sh
docker load -i xxx.tar
```

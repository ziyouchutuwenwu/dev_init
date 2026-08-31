# cvat

## 说明

自动标注需要主机支持 nvidia-container-toolkit

## 步骤

```sh
git clone https://github.com/cvat-ai/cvat.git
cd cvat

echo "CVAT_HOST=10.0.2.1" > .env
```

启动

```sh
# cpu 版
docker compose up -d

# 完整版，带自动标注
docker compose -f docker-compose.yml -f components/serverless/docker-compose.serverless.yml up -d
```

查看

```sh
docker compose ps
```

创建管理员

```sh
docker exec -it cvat_server bash -ic 'python3 ~/manage.py createsuperuser'
```

nuctl

````sh
curl -fsSL https://github.com/nuclio/nuclio/releases/download/1.13.0/nuctl-1.13.0-linux-amd64 -o /usr/local/bin/nuctl
chmod a+x /usr/local/bin/*

```sh
nuctl version
````

部署本地模型，用于自动标注

```sh
cd ~/cvat

docker pull alpine:latest
docker tag alpine:latest gcr.io/iguazio/alpine:3.17

nuctl create project local-model --platform local

# 清理
nuctl delete function pth-facebookresearch-sam-vit-h --platform local --force

nuctl deploy \
  --project-name local-model \
  --path serverless/pytorch/facebookresearch/sam/nuclio \
  --platform local  \
  --logger-level debug
```

### 查看

查看模型状态

```sh
nuctl get function --platform local
```

停止服务

```sh
docker compose -f docker-compose.yml -f components/serverless/docker-compose.serverless.yml down
```

重启服务

```sh
docker compose -f docker-compose.yml -f components/serverless/docker-compose.serverless.yml restart
```

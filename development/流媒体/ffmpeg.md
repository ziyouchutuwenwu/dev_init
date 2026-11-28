# ffmpeg

## 用法

提取音频

```sh
ffmpeg -i xxx.mp4 -vn -y -acodec copy yyy.aac
ffmpeg -i xxx.mp4 -vn -y -acodec copy yyy.m4a
```

提取视频

```sh
ffmpeg -i xxx.mp4 -vcodec copy -an yyy.mp4
```

查看信息

```sh
ffmpeg -i xxx.mp4
ffmpeg -i xxx.aac
ffmpeg -i xxx.m4a
```

格式转换

```sh
ffmpeg -i xxx.mp4 yyy.avi

# 如果你想维持你的源视频文件的质量，使用 `-qscale 0` 参数：
ffmpeg -i xxx.webm -qscale 0 yyy.mp4
```

检查支持格式的列表

```sh
ffmpeg -formats
```

修改分辨率

```sh
ffmpeg -i xxx.mp4 -s 1280x720 -c:a copy yyy.mp4
```

提取所有图像

```sh
ffmpeg -i xxx.mp4 -r 1 -f image2 images/image-%2d.png
```

转换为标准摄像头视频

```sh
ffmpeg -y -i xxx.mp4 -c:v libx264 -profile:v baseline -level 3.1 -pix_fmt yuv420p -r 25 -g 25 -bf 0 -an -movflags +faststart output.mp4
```

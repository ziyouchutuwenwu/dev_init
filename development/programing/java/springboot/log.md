# log

slf4j 是抽象的日志框架，logback, log4j 等是具体实现

## 例子

### 控制台输出

#### idea

安装 lombok 插件

#### pom.xml

```xml
<dependency>
  <groupId>org.projectlombok</groupId>
  <artifactId>lombok</artifactId>
</dependency>
```

类

```java
@Slf4j

...

log.debug("=====测试日志debug级别打印====\n");
log.info("======测试日志info级别打印=====\n");
log.error("=====测试日志error级别打印====\n");
```

### 文件输出

yml

```yaml
logging:
  file:
    name: logs/log.log
  pattern:
    file: "%d{yyyy-MMM-dd HH:mm:ss.SSS} %-5level [%thread] %logger{15} - %msg%n"
  level:
    com.mmc.springbootdemo: DEBUG
```

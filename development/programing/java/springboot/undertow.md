# undertow

## 说明

web 服务器从默认的 tomcat 换成 undertow

## 例子

### pom

```xml
<!--使用undertow-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-undertow</artifactId>
</dependency>
```

### yaml

```yaml
server:
  undertow:
    accesslog:
      dir: undertow-log
      enabled: false
      pattern: common
      prefix: access_log
      suffix: .log
    threads:
      io: 4 # 设置IO线程数, 它主要执行非阻塞的任务,它们会负责多个连接, 默认设置每个CPU核心一个线程
      worker: 20 # 阻塞任务线程池, 当执行类似servlet请求阻塞操作, undertow会从这个线程池中取得线程,它的值设置取决于系统的负载
    # 以下的配置会影响buffer,这些buffer会用于服务器连接的IO操作,有点类似netty的池化内存管理
    # 每块buffer的空间大小,越小的空间被利用越充分
    buffer-size: 1024
    direct-buffers: true
    # HTTP POST请求最大的大小
    max-http-post-size: 0
```

### 配置类

```java
@Configuration
public class UnderTowerConfig {

    //替换tomcat的undertower配置
    @Bean
    UndertowServletWebServerFactory embeddedServletContainerFactory() {

        UndertowServletWebServerFactory factory = new UndertowServletWebServerFactory();

        factory.addBuilderCustomizers(builder -> builder.setServerOption(UndertowOptions.ENABLE_HTTP2, true));

        return factory;
    }
}
```

### 启动

```sh
mvn spring-boot:run
```

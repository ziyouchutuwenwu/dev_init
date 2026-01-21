# 不启用 web 端口

有时候只是用 springboot 做个工具，不需要开启端口

## 步骤

二选一即可

### application.yml

```yaml
spring:
  main:
    web-application-type: none
```

### 代码

```java
@EnableScheduling
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        new SpringApplicationBuilder(DemoApplication .class)
                .web(WebApplicationType.NONE)
                .run(args);
//        SpringApplication.run(DemoApplication.class, args);
    }
}
```

# druid

pom.xml

```xml
<!--pg支持-->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!--druid-->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>druid-spring-boot-starter</artifactId>
    <version>1.2.4</version>
</dependency>

<!-- jdbc 的支持 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
```

yml

```yml
spring:
  datasource:
    type: com.alibaba.druid.pool.DruidDataSource
    driver-class-name: org.postgresql.Driver
    username: postgres
    password: postgres

    druid:
      url: jdbc:postgresql://127.0.0.1:6543/my_db
      initial-size: 5
      max-active: 20
      min-idle: 5
      max-wait: 60000

      filters: stat, wall, log4j2

      # WebStatFilter配置
      web-stat-filter:
        enabled: true
        url-pattern: /*
        session-stat-enable: true
        session-stat-max-count: 1000

      # StatViewServlet配置
      stat-view-servlet:
        enabled: true
        url-pattern: /druid/*
        reset-enable: false
        login-username: admin
        login-password: 123456
        allow: 127.0.0.1
        deny:
```

druid 访问地址：

```sh
http://127.0.0.1:8080/druid/
```

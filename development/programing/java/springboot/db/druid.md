# druid

## 步骤

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

```yaml
spring:
  datasource:
    type: com.alibaba.druid.pool.DruidDataSource
    url: jdbc:postgresql://127.0.0.1:6543/my_db
    driver-class-name: org.postgresql.Driver
    username: postgres
    password: postgres

    druid:
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

建立配置类

config.druid.DruidDataSourceProperties.java

```java
@Data
@ConfigurationProperties(prefix = "spring.datasource")
public class DruidDataSourceProperties {
    private String url;
    private String username;
    private String password;
    private String driverClassName;
}
```

config.druid.DataSourceConfig.java

```java
@Configuration
@EnableConfigurationProperties(DruidDataSourceProperties.class)
public class DataSourceConfig {
    @Primary
    @Bean(name = "localDatasource")
    public DataSource dataSourceConfig(DruidDataSourceProperties dataSourceProperties){
        DruidDataSource druidDataSource = new DruidDataSource();
        druidDataSource.setUrl(dataSourceProperties.getUrl());
        druidDataSource.setUsername(dataSourceProperties.getUsername());
        druidDataSource.setPassword(dataSourceProperties.getPassword());
        druidDataSource.setDriverClassName(dataSourceProperties.getDriverClassName());

//        yml里面配置的这个无法自动解析
//        filters: stat,wall,log4j2

        try {
            druidDataSource.setFilters("stat,wall,log4j2");
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return druidDataSource;
    }
}
```

config.druid.RemoveDruidAd.java

```java
@Configuration
@ConditionalOnWebApplication
@AutoConfigureAfter(DruidDataSourceAutoConfigure.class)
@ConditionalOnProperty(name = "spring.datasource.druid.stat-view-servlet.enabled", havingValue = "true", matchIfMissing = true)
public class RemoveDruidAd {

    @Bean
    public FilterRegistrationBean fuckDruidAdFilterRegistrationBean(DruidStatProperties properties) {
        // 获取web监控页面的参数
        DruidStatProperties.StatViewServlet config = properties.getStatViewServlet();
        // 提取common.js的配置路径
        String pattern = config.getUrlPattern() != null ? config.getUrlPattern() : "/druid/*";
        String commonJsPattern = pattern.replaceAll("\\*", "js/common.js");

        final String filePath = "support/http/resources/js/common.js";

        Filter filter = new Filter() {
            @Override
            public void init(FilterConfig filterConfig) throws ServletException {
            }

            @Override
            public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
                chain.doFilter(request, response);
                // 重置缓冲区，响应头不会被重置
                response.resetBuffer();
                // 获取common.js
                String text = Utils.readFromResource(filePath);
                // 正则替换banner
                text = text.replaceAll("<a.*?banner\"></a><br/>", "");
                response.getWriter().write(text);
            }

            @Override
            public void destroy() {
            }
        };

        FilterRegistrationBean registrationBean = new FilterRegistrationBean();
        registrationBean.setFilter(filter);
        registrationBean.addUrlPatterns(commonJsPattern);
        return registrationBean;
    }
}
```

druid 访问地址：

```sh
http://127.0.0.1:8080/druid/
```

## 注意

最好自己做配置类，不然无法监控 sql 语句，可能是 yml 的解析 bug

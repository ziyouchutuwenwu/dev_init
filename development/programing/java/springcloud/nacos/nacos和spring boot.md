# nacos 和 springboot 的整合

## 启动 nacos 服务

```sh
sh startup.sh -m standalone
```

[管理后台](http://127.0.0.1:8848/nacos)

## spring boot

如果出现诡异问题，注意 spring boot 的版本，尽量和阿里的文档内一致

### 配置管理

#### 代码

pom.xml

```xml
<properties>
    <nacos-config-spring-boot.version>0.2.1</nacos-config-spring-boot.version>
    <java.version>1.8</java.version>
</properties>


<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
        <version>2.5.4</version>
    </dependency>

    <dependency>
        <groupId>com.alibaba.boot</groupId>
        <artifactId>nacos-config-spring-boot-starter</artifactId>
        <version>${nacos-config-spring-boot.version}</version>
    </dependency>

    <dependency>
        <groupId>com.alibaba.boot</groupId>
        <artifactId>nacos-config-spring-boot-actuator</artifactId>
        <version>${nacos-config-spring-boot.version}</version>
    </dependency>
</dependencies>
```

application.properties

```properties
nacos.config.server-addr=127.0.0.1:8848

# endpoint http://localhost:8080/actuator/nacos-config
# health http://localhost:8080/actuator/health
management.endpoints.web.exposure.include=*
management.endpoint.health.show-details=always
```

ConfigController.java

```java
import com.alibaba.nacos.api.config.annotation.NacosValue;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import static org.springframework.web.bind.annotation.RequestMethod.GET;

@Controller
@RequestMapping("config")
public class ConfigController {

    @NacosValue(value = "${useLocalCache:false}", autoRefreshed = true)
    private boolean useLocalCache;

    @RequestMapping(value = "/get", method = GET)
    @ResponseBody
    public boolean get() {
        return useLocalCache;
    }
}
```

DemoApplication.java

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import com.alibaba.nacos.spring.context.annotation.config.NacosPropertySource;

/**
 * Document: https://nacos.io/zh-cn/docs/quick-start-spring-boot.html
 * <p>
 * Nacos 控制台添加配置：
 * <p>
 * Data ID：example
 * <p>
 * Group：DEFAULT_GROUP
 * <p>
 * 配置内容：useLocalCache=true
 */
@SpringBootApplication
@NacosPropertySource(dataId = "example", autoRefreshed = true)
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

#### 测试

```sh
curl http://localhost:8080/config/get
curl -X POST "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=example&group=DEFAULT_GROUP&content=useLocalCache=true"
```

### 服务发现

#### 代码例子

pom.xml

```xml
<properties>
    <nacos-discovery-spring-boot.version>0.2.1</nacos-discovery-spring-boot.version>
    <java.version>1.8</java.version>
</properties>


<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>com.alibaba.boot</groupId>
        <artifactId>nacos-discovery-spring-boot-starter</artifactId>
        <version>${nacos-discovery-spring-boot.version}</version>
    </dependency>
</dependencies>
```

application.properties

```properties
nacos.discovery.server-addr=127.0.0.1:8848
```

DemoApplication.java

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

DiscoveryController.java

```java
import com.alibaba.nacos.api.annotation.NacosInjected;
import com.alibaba.nacos.api.exception.NacosException;
import com.alibaba.nacos.api.naming.NamingService;
import com.alibaba.nacos.api.naming.pojo.Instance;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import java.util.List;
import static org.springframework.web.bind.annotation.RequestMethod.GET;

@Controller
@RequestMapping("discovery")
public class DiscoveryController {

    @NacosInjected
    private NamingService namingService;

    @RequestMapping(value = "/get", method = GET)
    @ResponseBody
    public List<Instance> get(@RequestParam String serviceName) throws NacosException {
        return namingService.getAllInstances(serviceName);
    }
}
```

#### 测试命令

创建服务

```sh
curl -X POST 'http://127.0.0.1:8848/nacos/v1/ns/service?serviceName=example'
```

注册实例

```sh
curl -X PUT 'http://127.0.0.1:8848/nacos/v1/ns/instance?serviceName=example&ip=127.0.0.1&port=8080'
```

获取实例

```sh
curl 'http://localhost:8080/discovery/get?serviceName=example'
```

测试没成功

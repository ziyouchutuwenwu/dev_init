# mybatis-plus

## 步骤

### 常规配置

pom.xml

```xml
<!-- getter, setter -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.16</version>
    <scope>provided</scope>
</dependency>

<!--pg支持-->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- mybatis-plus -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-boot-starter</artifactId>
    <version>3.4.1</version>
</dependency>
```

model/User

```java
@Data
@TableName("users")
public class User {
    private Long id;
    private String name;
    private Integer age;
}
```

dao/UserMapper

```java
public interface UserMapper extends BaseMapper<User> {
}
```

启动类里面添加@MapperScan

```java
@MapperScan("com.example.demo.dao")
```

controller 里面

```java
@Autowired
private UserMapper userMapper;
```

application.yml

```yml
spring:
  datasource:
    url: jdbc:postgresql://127.0.0.1:6543/my_db
    driver-class-name: org.postgresql.Driver
    username: postgres
    password: postgres
```

### 代码生成器

代码生成器非必须

#### 配置方式

pom.xml 内添加

```xml
<!-- mybatis-plus 代码生成器-->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-generator</artifactId>
    <version>3.4.2</version>
</dependency>

<!-- mybatis-plus 代码生成器需要的模板引擎 -->
<dependency>
    <groupId>org.freemarker</groupId>
    <artifactId>freemarker</artifactId>
    <version>2.3.30</version>
</dependency>
```

代码生成器地址参考官网

#### 注意

使用代码生成器，如果提示缺乏模板，则可以尝试换一个模板引擎

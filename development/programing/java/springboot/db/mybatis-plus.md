# mybatis-plus

## 步骤

### pom.xml

```xml
<!-- getter, setter -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.16</version>
    <scope>provided</scope>
</dependency>

<!-- mybatis-plus -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-boot-starter</artifactId>
    <version>3.4.1</version>
</dependency>

<!--pg支持-->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- mysql -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <scope>runtime</scope>
</dependency>
```

### model

model.User.java

```java
@Data
@TableName("users")
public class User {

    @TableId(value = "id",type= IdType.AUTO)
    private Long id;
    private String name;
    private Integer age;

    @TableField(value = "phone")
    private String phoneNumber;
}
```

### mapper

dao.UserMapper.java

```java
public interface UserMapper extends BaseMapper<User> {
    @Select("SELECT * FROM nlp_user where name = #{name}")
    List<User> selectByName(@Param("name") String name);
}
```

### MapperScan

启动类里面添加 @MapperScan

```java
@MapperScan("com.example.demo.dao")
```

### 数据库配置

application.yml

```yaml
spring:
  datasource:
    url: jdbc:postgresql://127.0.0.1:6543/my_db
    driver-class-name: org.postgresql.Driver
    username: postgres
    password: postgres
```

或者

```yaml
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1:4407/my_db
    driver-class-name: com.mysql.cj.jdbc.Driver
    username: root
    password: root
```

### 测试

```java
@SpringBootTest
class DemoApplicationTests {

    @Autowired
    private UserMapper userMapper;

    @Test
    void contextLoads() {
    }

    @Test
    void selectAll() {
        List<User> users = userMapper.selectList(null);
        users.forEach(System.out::println);
    }

    @Test
    public void selectByName() {
        List<User> users = userMapper.selectByName("name");
        users.forEach(System.out::println);
    }
}
```

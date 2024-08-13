# mybatis

## 配置

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

<!--mybatis-->
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>2.1.4</version>
</dependency>

<!--重定义资源路径, mybatis-generator 需要用, 放 build 字段下面-->
<resources>
    <resource>
        <directory>src/main/resources</directory>
        <includes>
            <include>**/*.html</include>
            <include>**/*.yml</include>
            <include>**/*.properties</include>
            <include>**/*.xml</include>
        </includes>
        <filtering>true</filtering>
    </resource>

    <resource>
        <directory>src/main/java</directory>
        <includes>
            <include>**/*.html</include>
            <include>**/*.yml</include>
            <include>**/*.properties</include>
            <include>**/*.xml</include>
        </includes>
        <filtering>true</filtering>
    </resource>
</resources>

<!--mybatis-generator-->
<plugin>
    <groupId>org.mybatis.generator</groupId>
    <artifactId>mybatis-generator-maven-plugin</artifactId>
    <version>1.4.0</version>
    <configuration>
        <!--定义配置文件路径-->
        <configurationFile>src/main/resources/xml/mybatis-gen-config.xml</configurationFile>
        <verbose>true</verbose>
        <overwrite>true</overwrite>
    </configuration>
</plugin>
```

src/main/resources/xml/mybatis-gen-config.xml

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE generatorConfiguration PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN" "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd" >
<generatorConfiguration>
    <!-- 引入配置文件 -->
    <properties resource="properties/mybatis-gen.properties" />
    <!-- 指定数据连接驱动jar地址 -->
    <classPathEntry location="${classPath}" />

    <context id="context1" targetRuntime="MyBatis3Simple">

        <!-- 数据库连接信息 -->
        <jdbcConnection driverClass="${jdbc.driverClassName}"
                        connectionURL="${jdbc.url}" userId="${jdbc.username}" password="${jdbc.password}" />

        <!-- 生成Model对象路径配置 -->
        <javaModelGenerator targetPackage="${bgm.model.pkgname}"
                            targetProject="src/main/java">
            <property name="enableSubPackages" value="true" />
            <property name="trimStrings" value="true" />
        </javaModelGenerator>

        <!-- 生成sqlXML文件路径配置，如果不和mapper类在一个包下面，需要设置mybatis的mapper-locations属性 -->
        <sqlMapGenerator targetPackage="${bgm.mapper.xmlpkgname}"
                         targetProject="src/main/java">
            <property name="enableSubPackages" value="true" />
        </sqlMapGenerator>

        <!-- 生成DAO的类文件路径配置 -->
        <javaClientGenerator targetPackage="${bgm.mapper.pkgname}"
                             targetProject="src/main/java" type="XMLMAPPER">
            <property name="enableSubPackages" value="true" />
        </javaClientGenerator>

        <!--要生成哪些表 -->
        <table tableName="users" domainObjectName="User" />
    </context>

</generatorConfiguration>
```

src/main/resources/properties/mybatis-gen.properties

```properties
# tools 为和 src 同级目录
classPath = tools/postgresql-42.2.4.jar

jdbc.driverClassName = org.postgresql.Driver
jdbc.url = jdbc:postgresql://127.0.0.1:6543/my_db
jdbc.username = postgres
jdbc.password = postgres

bgm.model.pkgname = my.mybatis.generator.auto.entity
bgm.mapper.pkgname = my.mybatis.generator.auto.mapper
bgm.mapper.xmlpkgname = my.mybatis.generator.auto.xml
```

生成代码

```sh
mvn mybatis-generator:generate
```

## 代码部分

创建 mapper

XmlUserMapper.java

```java
@Component
public interface XmlUserMapper extends UserMapper {
}
```

AnnotationUserMapper.java

```java
@Mapper
public interface AnnotationUserMapper {

    @Select("select * from users where name = #{name}")
    User findByName(@Param("name") String name);

    @Insert("insert into users(name, age) values(#{name}, #{age})")
    void insert(@Param("name") String name, @Param("age") Integer age);

    @Select("select * from users")
    List<User> getAllUsers();

    @Insert("<script>"  +
            "insert into users(name, age) values" +
            "<foreach collection=\"userList\" item=\"iterUser\" index=\"index\"  separator=\",\">" +
            "(#{iterUser.name},#{iterUser.age})" +
            "</foreach>" +
            "</script>")
    void batchInsert(@Param("userList") List<User> userList);

    @Delete("delete from users where name = #{name}")
    void deleteUser(@Param("name") String name);

    @Update("update users set age = #{newAge} where name = #{conditionName}")
    void updateUser(@Param("conditionName") String conditionName, @Param("newAge") Integer newAge);

    @Select("truncate table users")
    void truncate();
}
```

model.User.java

```java
@Getter
@Setter
public class User implements Serializable {

    private Integer id;

    private String name;
    private Integer age;
}
```

IUserService.java

```java
public interface IUserService {
    void addUser(String name, Integer age);
    void batchAddUsers(List<User> users);

    void deleteUser(String name);
    void updateUser(String conditionName, Integer newAge);

    void clear();

    List<User> getAllUsers();
    User findByName(String name);

    void doTranscation() throws Exception;
}
```

UserService.java

```java
@Service("mybatisUserService")
public class UserService implements IUserService {
    private XmlUserMapper _xmlUserMapper;
    private AnnotationUserMapper _annotationUserMapper;

    @Autowired
    public UserService(XmlUserMapper xmlUserMapper, AnnotationUserMapper annotationUserMapper) {
        _xmlUserMapper = xmlUserMapper;
        _annotationUserMapper = annotationUserMapper;
    }

    @Override
    public List<User> getAllUsers() {
//        return _annotationUserMapper.getAllUsers();

        //这段使用xml的mapper测试
        List<User> result = new ArrayList<User>();

        List<my.mybatis.generator.auto.entity.User> userList =  _xmlUserMapper.selectAll();
        for ( my.mybatis.generator.auto.entity.User iterUser : userList ){
            User user = new User();
            user.setId(iterUser.getId());
            user.setAge(iterUser.getAge());
            user.setName(iterUser.getName());
            result.add(user);
        }

        return result;
    }

    @Override
    public User findByName(String name){
        return _annotationUserMapper.findByName(name);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void doTranscation(){
        _annotationUserMapper.insert("aaa", 10);
        throw new RuntimeException("mybatis 事务抛异常");
    }

    @Override
    public void addUser(String name, Integer age) {
        _annotationUserMapper.insert(name, age);
    }

    @Override
    public void batchAddUsers(List<User> users) {
        _annotationUserMapper.batchInsert(users);
    }

    @Override
    public void deleteUser(String name) {
        _annotationUserMapper.deleteUser(name);
    }

    @Override
    public void updateUser(String conditionName, Integer newAge) {
        _annotationUserMapper.updateUser(conditionName, newAge);
    }

    @Override
    public void clear() {
        _annotationUserMapper.truncate();
    }
}
```

controller 里面

```java
private IUserService _mybatisUserService;

@Autowired
@Qualifier("mybatisUserService")
public void setMyBatisService(IUserService myBatisUserService) {
    _mybatisUserService = myBatisUserService;
}
```

application 上加 mapscan 注解, 事务支持，默认已启用

```java
@MapperScan({
    "my.mybatis.generator.auto",
    "com.example.demo.dao.mybatis"
})
@EnableTransactionManagement
```

application.yml

```yaml
spring:
  datasource:
    url: jdbc:postgresql://127.0.0.1:6543/my_db
    driver-class-name: org.postgresql.Driver
    username: postgres
    password: postgres

mybatis:
  # 不设置的话，mybatis 找不到mapper，无法curd
  mapper-locations: "classpath:my/mybatis/generator/auto/xml/*.xml"

  # 万能 mapper路径
  # mapper-locations: "classpath*:**/**Mapper.xml"

  # 以下为多路径
  #  mapper-locations: "classpath:aa/bb/gen/xml/*.xml, classpath*:cc/dd/gen/xml/*.xml"
```

### druid

参考 druid 配置文档

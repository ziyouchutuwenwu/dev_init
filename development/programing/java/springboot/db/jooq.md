# jooq

## 步骤

### 基本配置

pom.xml

```xml
<!-- getter, setter -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.16</version>
    <scope>provided</scope>
</dependency>

<!--jooq-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jooq</artifactId>
</dependency>

<!--mysql 支持-->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <scope>runtime</scope>
</dependency>

<!--pgsql 支持-->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter</artifactId>
    <version>2.4.2</version>
</dependency>

<!--jooq-code-gen，代码生成器，可以不用-->
<plugin>
    <groupId>org.jooq</groupId>
    <artifactId>jooq-codegen-maven</artifactId>
    <executions>
        <execution>
            <id>jooq-codegen</id>
            <phase>generate-sources</phase>
            <goals>
                <goal>generate</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <!--定义配置文件路径-->
        <configurationFile>src/main/resources/xml/jooq-gen-config.xml</configurationFile>
    </configuration>
</plugin>
```

src/main/resources/xml/jooq-gen-config.xml

```xml
<configuration xmlns="http://www.jooq.org/xsd/jooq-codegen-3.14.0.xsd">
    <!-- <jdbc>
        <driver>org.postgresql.Driver</driver>
        <url>jdbc:postgresql://127.0.0.1:6543/my_db</url>
        <user>postgres</user>
        <password>postgres</password>
    </jdbc> -->

    <driver>com.mysql.cj.jdbc.Driver</driver>
    <!-- mysql的话，这里的 demo_repo 可以不写 -->
    <url>jdbc:mysql://localhost:4407/demo_repo</url>
    <user>root</user>
    <password>root</password>

    <generator>
        <database>
<!--            <name>org.jooq.meta.mysql.MySQLDatabase</name>-->
<!--            <name>org.jooq.meta.postgres.PostgresDatabase</name>-->
            <name>org.jooq.meta.jdbc.JDBCDatabase</name>

            <includes>.*</includes>

            <excludes></excludes>

            <!--mysql为数据库名称-->
            <!--pgsql为schema-->
            <inputSchema>public</inputSchema>
        </database>

        <generate/>

        <target>
            <!--生成代码文件的包名及放置目录-->
            <packageName>my.jooq.generator.auto</packageName>
            <directory>src/main/java</directory>
        </target>
    </generator>
</configuration>
```

生成代码

```sh
mvn jooq-codegen:generate
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

UserService.java

```java
@Service("jooqService")
public class UserService implements IUserService {
    private DSLContext dsl;

    @Autowired
    public UserService(DSLContext context){
        dsl = context;
    }

    @Override
    public List<User> getAllUsers(){
        Result<Record> result = dsl.select().from(Tables.USERS).fetch();
//        Result<Record> result = dsl.fetch("select * from users");

        List<User> users = new ArrayList<>();

        for ( Record record : result ) {
            Integer id = record.getValue(Tables.USERS.ID);
            String name = record.getValue(Tables.USERS.NAME);
            Integer age = record.getValue(Tables.USERS.AGE);

            User user = new User();
            user.setId(id);
            user.setName(name);
            user.setAge(age);

            users.add(user);
        }

        return users;
    }

    @Override
    public User findByName(String name) {
        Result result = dsl.select().from(Tables.USERS).where(Tables.USERS.NAME.equal(name)).fetch();

        User user = new User();
        if ( 0 == result.size() ) return user;

        Record record = (Record) result.get(0);
        Integer recordId = record.getValue(Tables.USERS.ID);
        String recordName = record.getValue(Tables.USERS.NAME);
        Integer recordAge = record.getValue(Tables.USERS.AGE);

        user.setId(recordId);
        user.setName(recordName);
        user.setAge(recordAge);

        return user;
    }

    @Override
    public void addUser(String name, Integer age) {
        dsl.insertInto(Tables.USERS).columns(Tables.USERS.NAME, Tables.USERS.AGE).values(name, age).execute();
    }

    @Override
    public void batchAddUsers(List<User> users) {

        Result<UsersRecord> records = dsl.newResult(Tables.USERS);
        for (User user: users){
            UsersRecord userRecord = dsl.newRecord(Tables.USERS, user);
            records.add(userRecord);
        }
        dsl.batchStore(records).execute();
    }

    @Override
    public void deleteUser(String name) {
        dsl.deleteFrom(Tables.USERS).where(Tables.USERS.NAME.equal(name)).execute();
    }

    @Override
    public void updateUser(String conditionName, Integer newAge) {
        dsl.update(Tables.USERS).set(Tables.USERS.AGE, newAge).where(Tables.USERS.NAME.eq(conditionName)).execute();
    }

    @Override
    public void clear() {
        dsl.execute("truncate table users");
//        dsl.truncate(Tables.USERS).execute();
    }

    @Override
    public void doTranscation(){

        try {
            dsl.transaction(configuration -> {
                dsl.execute("insert into users (age, name) values(111,'111')");
                dsl.execute("insert into users (age, name) values(222,'222')");
                throw new Exception("使用jooq自带事务抛出的异常");
            });
        }
        catch (Exception e){
            System.out.println("捕获jooq事务异常");
        }
    }
}
```

controller

```java
private IUserService _jooqUserService;

@Autowired
@Qualifier("jooqService")
public void setJooqService(IUserService jooqUserService) {
    _jooqUserService = jooqUserService;
}
```

```yaml
spring:
  datasource:
    url: jdbc:postgresql://127.0.0.1:6543/my_db
    driver-class-name: org.postgresql.Driver
    username: postgres
    password: postgres
```

### 集成 druid

先参考 druid 的配置

然后 service 的构造函数里面

```java
@Service("jooqService")
public class UserService implements IUserService {
    private DSLContext dsl;

    public UserService(@Qualifier("localDatasource") DataSource dataSource){
        ConnectionProvider connectionProvider =  new DataSourceConnectionProvider(dataSource);
        org.jooq.Configuration configuration = new DefaultConfiguration()
                .set(connectionProvider)
                .set(SQLDialect.POSTGRES);
        dsl = DSL.using(configuration);
    }
```

### 打印 sql

application.properties

```properties
logging.level.org.jooq.tools.LoggerListener=DEBUG
```

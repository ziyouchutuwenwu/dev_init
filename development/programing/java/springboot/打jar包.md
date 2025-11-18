# 打 jar 包

## 步骤

### 修改 maven

pom.xml, build 字段里面

```xml
<!--jar包打包-->
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <mainClass>com.example.DemoApplication</mainClass>
        <layout>JAR</layout>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>repackage</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### 打包

忽略单元测试

```sh
mvn clean; mvn package -Dmaven.test.skip=true
```

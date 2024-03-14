# 打 jar 包

## 步骤

### 修改 maven

pom.xml, build 字段里面

```xml
<!--jar包打包-->
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
</plugin>
```

### 命令

忽略单元测试

```sh
mvn clean; mvn package -Dmaven.test.skip=true
```

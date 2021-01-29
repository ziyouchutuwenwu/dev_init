# 生成 jar 包

pom.xml, build 字段里面

```xml
<!--jar包打包-->
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
</plugin>
```

命令

```sh
mvn package
```

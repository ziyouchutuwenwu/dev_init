# maven 引入本地 jar 包

## 例子

```xml
<dependency>
    <groupId>dingding</groupId>
    <artifactId>dingding</artifactId>
    <version>2.8</version>
    <scope>system</scope>
    <!-- 引入本地 jar 包 -->
    <systemPath>${project.basedir}/lib/taobao-sdk-java.jar</systemPath>
</dependency>

<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <!-- 打包时包含本地的 jar 包 -->
        <includeSystemScope>true</includeSystemScope>
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

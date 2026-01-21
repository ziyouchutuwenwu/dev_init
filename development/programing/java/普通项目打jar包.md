# 普通项目打 jar 包

推荐使用 maven-shade-plugin

## maven-assembly-plugin

pom.xml

```xml
<plugin>
    <artifactId>maven-assembly-plugin</artifactId>
    <configuration>
    <appendAssemblyId>false</appendAssemblyId>
    <archive>
        <manifest>
        <!-- 修改启动类 -->
        <mainClass>org.example.App</mainClass>
        </manifest>
    </archive>
    <descriptorRefs>
        <descriptorRef>jar-with-dependencies</descriptorRef>
    </descriptorRefs>
    </configuration>
</plugin>
```

生成 jar 包

```sh
mvn clean assembly:assembly
```

## maven-shade-plugin

pom.xml

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-shade-plugin</artifactId>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>shade</goal>
            </goals>
            <configuration>
                <transformers>
                    <transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                        <resource>META-INF/spring.handlers</resource>
                    </transformer>
                    <transformer implementation="org.springframework.boot.maven.PropertiesMergingResourceTransformer">
                        <resource>META-INF/spring.factories</resource>
                    </transformer>
                    <transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                        <resource>META-INF/spring.schemas</resource>
                    </transformer>
                    <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer" />
                    <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                        <!-- 修改启动类 -->
                        <mainClass>org.example.App</mainClass>
                    </transformer>
                </transformers>
            </configuration>
        </execution>
    </executions>
</plugin>
```

生成 jar 包

```sh
mvn clean package shade:shade
```

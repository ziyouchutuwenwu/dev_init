# 程序启用本机 ui

pom.xml

```xml
<properties>
  <flink.version>1.13.1</flink.version>
  <flink.scala.version>2.12</flink.scala.version>
</properties>

<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-runtime-web_${flink.scala.version}</artifactId>
  <version>${flink.version}</version>
</dependency>
```

代码，类似

```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.createLocalEnvironmentWithWebUI(new Configuration());
```

运行以后，浏览器可以直接访问 [flink 管理后台](http://127.0.0.1:8081)

不需要另外启动 flink

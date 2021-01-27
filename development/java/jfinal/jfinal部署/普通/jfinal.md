# undertow

## 目录结构类似这样

```sh
└── main
    ├── java
    ├── resources
    └── webapp
```

## 配置 maven 脚本

创建基于 maven-archetype-webapp 模板的项目

在 pom.xml 里面添加

```xml
<dependency>
    <groupId>com.jfinal</groupId>
    <artifactId>jfinal-undertow</artifactId>
    <version>2.0</version>
</dependency>

<dependency>
    <groupId>com.jfinal</groupId>
    <artifactId>jfinal</artifactId>
    <version>4.8</version>
</dependency>
```

修改 pom.xml 文件，其中的 packaging 标签值要改成 jar

修改 build 标签下面的 plugs，注意，把 plugins 从 pluginManagement 里面拿出来，参考模板改

注意，如果你的 webapp 目录不在 resources 下面，则需要参考 fatjar 的 pom.xml 模板把 maven-resources-plugin 也复制出来，不然编译以后，webapp 目录不会编译出来，导致前端模板找不到

## 其他修改

在和 pom.xml 的同级位置添加 package.xml 文件，具体见目录

复制 `jfinal.sh` 到项目根目录，然后修改 MAIN_CLASS 为正确的启动类

`mvn clean package`生成打包项目，然后到打包好的目录 `一般为target/xxx-release/`下, `./jfinal.sh start` 启动

## 例子见 demo

# fatjar 模式打包

## 目录结构类似这样

```sh
└── main
    ├── java
    ├── resources
    └── webapp
```

## 步骤

### 项目配置

- 在 configEngine(Engine me)里面添加下面两行，而且这两行配置代码要放在最前面
- 如果 webapp 目录不是在 resources 目录里面，则加入下面两句话以后，idea 里面直接启动，会报 500 错误，`建议直接把这个目录放 resources 目录里面`。

```java
me.setBaseTemplatePath("webapp");
me.setToClassPathSourceFactory();
```

- 前端静态文件，简单起见，放 webapp 目录里面即可，该目录和 resouces 是一个级别，下面是 jfinal 的说明

```txt
当你的 webapp 资源目录本来就放在 src/main/resources 之下时，可以去掉 pom.xml 中的 maven-resources-plugin 插件，该插件就是在打包的时候将 src/main/webapp 下面的资源复制到 target/classes 下面去，好让其打到 jar 包之中去
```

- 在 resouces 目录下建立 undertow.txt，添加如下配置：

```java
undertow.resourcePath=src/main/webapp, classpath:webapp
```

### 参考 pom.xml 模板修改 pom.xml

- 注意修改 `mainClass`
- 搜索 `packaging`， 改成 `jar`
- 搜索 `jfinal-demo`， 改成自己的项目名

- 打包运行

```sh
mvn clean package
java -jar jfinal-demo.jar
```

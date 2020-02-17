# fatjar 模式打包

## 目录结构类似这样

```bash
└── main
    ├── java
    ├── resources
    └── webapp
```

## 步骤

- 在 configEngine(Engine me)里面添加下面两行，而且这两行配置代码要放在最前面

```java
me.setBaseTemplatePath("webapp");
me.setToClassPathSourceFactory();
```

- 前端静态文件，简单起见，放 webapp 目录里面即可，该目录和 resrouces 是一个级别，下面是 jfinal 的说明

```txt
当你的 webapp 资源目录本来就放在 src/main/resources 之下时，可以去掉 pom.xml 中的maven-resources-plugin 插件，该插件就是在打包的时候将 src/main/webapp 下面的资源复制到 target/classes 下面去，好让其打到 jar 包之中去
```

- 在 resouces 目录下建立 undertow.txt，添加如下配置：

```java
undertow.resourcePath=src/main/webapp, classpath:webapp
```

- 参考 pom.xml 模板修改 pom.xml，注意修改`mainClass`
- 打包运行

```bash
mvn clean package
java -jar jfinal-demo.jar
```

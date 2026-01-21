# thymeleaf 模板引擎

pom.xml

```xml
<!--thymeleaf 模板引擎-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

创建 controller

```java
@Controller
@RequestMapping("/aaa")
public class ViewController {

    @RequestMapping(value = "/bbb", method = RequestMethod.GET)
    public String showHtml(Model viewModel){
        viewModel.addAttribute("hello", "html内容");
        return "show";
    }
}
```

resources/templates/show.html

```html
<body xmlns:th="http://www.w3.org/1999/xhtml">
  <p th:text="${hello}" />
</body>
```

application.yml 里面

```yaml
spring:
  thymeleaf:
    prefix: classpath:/templates/
    check-template-location: true
    suffix: .html
    encoding: UTF-8
    mode: html
    cache: false
    servlet:
      content-type: text/html
```

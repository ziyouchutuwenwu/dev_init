# 控制器

RestController 注解为 api 控制器，直接返回文本

## pom.xml

```xml
<!-- fastjson -->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.78</version>
</dependency>
```

## 测试代码

jsonObject 为 application/json 参数

```java
import com.alibaba.fastjson.JSONObject;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import javax.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/demo")
public class DemoController {

    @RequestMapping(value = "/hello", method = RequestMethod.POST)
    public String sayHello(HttpServletRequest request, @RequestBody JSONObject jsonObject){
        String name = request.getParameter("name");
        return "hello " + name;
    }
}
```

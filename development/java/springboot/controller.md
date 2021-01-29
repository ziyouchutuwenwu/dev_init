# 控制器

RestController 注解为 api 控制器，直接返回文本

测试代码

```java
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import javax.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/demo")
public class DemoController {

    @RequestMapping(value = "/hello", method = RequestMethod.GET)
    public String sayHello(HttpServletRequest request){
        String name = request.getParameter("name");
        return "hello " + name;
    }
}
```

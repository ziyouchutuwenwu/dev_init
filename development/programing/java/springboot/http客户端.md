# http 客户端

自带了个简单好用的

## 例子

pom.xml

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

json post

```java
import com.alibaba.fastjson.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class TagService {

    @Autowired
    UrlConfig urlConfig;

    public JSONObject doTagRequest(JSONObject postDataObject) {
        String url = urlConfig.getTagServiceUrl();
        RestTemplate client = new RestTemplate();

        JSONObject json = client.postForEntity(url, postDataObject, JSONObject.class).getBody();
        return json;
    }
}
```

# 多线程 bean 注入

## 说明

不受 spring 管理的线程，无法使用类似 autowired 的注入

## 步骤

### 代码

DemoService.java

```java
package com.example.demo;

import org.springframework.stereotype.Component;

@Component
public class DemoService {
    public String doDemo(){
        return "in demo service";
    }
}
```

BeanContext.java

```java
package com.example.demo;

import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;

@Component
public class BeanContext implements ApplicationContextAware {

    private static ApplicationContext applicationContext;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        BeanContext.applicationContext = applicationContext;
    }

    public static <T> T getBean(Class<T> clz) throws BeansException {
        return (T) applicationContext.getBean(clz);
    }
}
```

DemoThread.java

```java
package com.example.demo;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Configurable;
import org.springframework.stereotype.Component;

@Component
@Slf4j
@Configurable
public class DemoThread implements Runnable{

    private DemoService demoService = BeanContext.getBean(DemoService.class);

    @Override
    public void run() {
        String info = demoService.doDemo();
        log.debug(info);
    }
}
```

DemoThreadBeanLoadListener.java

```java
package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.core.task.TaskExecutor;
import org.springframework.stereotype.Component;

@Component
public class DemoThreadBeanLoadListener implements ApplicationListener<ContextRefreshedEvent> {
    @Autowired
    private ApplicationContext ctx;
    @Autowired
    private TaskExecutor taskExecutor;

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        if (event.getApplicationContext().getParent() == null) {
            taskExecutor.execute(ctx.getBean(com.example.demo.DemoThread.class));
        }
    }
}
```

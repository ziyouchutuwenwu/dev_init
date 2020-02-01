# 自定义ui控件

## 比如需要在某activity里面加载某个自定义ui控件

- 先在activity的xml里面测试好大概的布局和设置参数等等
- 然后新建一个layout的xml，剪切相关内容到里面，根据情况，这个xml可以选用RelativeLayout或者LinerLayout
- 创建一个class，在构造函数里面，调用如下代码，view可以用来findViewById

```java
        LayoutInflater inflater = LayoutInflater.from(context);
        View view = inflater.inflate(R.layout.gender_switch_button_layout, this);
```

# java 调用 c

## 例子

c

```h
#ifndef DEMO_LIB_LIBRARY_H
#define DEMO_LIB_LIBRARY_H

typedef struct _MyObject{
    int id;
    char* name;
}MyObject, *PMyObject;

extern "C" MyObject by_value_demo(char* name, int id);
extern "C" MyObject* by_pointer_demo(char* name, int id);
extern "C" PMyObject* return_list_demo(char* name, int id);

typedef struct _MyObject1{
    int id;
    char name[200];
}MyObject1, *PMyObject1;
extern "C" int arg_list_reurn_list_demo(PMyObject1* list, int size, char* name, int id);

typedef void (*MYCALLBACK)(const char* name, char* data);
extern "C" void init_callback(MYCALLBACK callback);
extern "C" void do_callback();

#endif
```

```cpp
#include "library.h"
#include <stdio.h>
#include <iostream>
#include <string.h>

static MYCALLBACK _callback = NULL;

MyObject by_value_demo(char* name, int id){
    MyObject demo;
    demo.name = name;
    demo.id = id;

    return demo;
}

MyObject* by_pointer_demo(char* name, int id){
    MyObject* demo = new MyObject;
    demo->name = name;
    demo->id = id;

    return demo;
}

PMyObject* return_list_demo(char* name, int id){
    int size = 3;
    PMyObject* list = new PMyObject[size];

    for( int i=0; i < size; i++){
        MyObject* demo = new MyObject;
        demo->name = name;
        demo->id = id;

        list[i] = demo;
    }

    return list;
}

int arg_list_reurn_list_demo(PMyObject1* list, int size, char* name, int id){
    for( int i=0; i < size; i++){
        MyObject1* demo = list[i];
        strcpy(demo->name, name);
        demo->id = id;
    }

    return size;
}

void init_callback(MYCALLBACK callback){
    printf("in c init_callback\n");
    _callback = callback;
}

void do_callback(){
    printf("before c do_callback\n");

    char data[] = {1,2,3,4,5};
    _callback("name aaa", data);
    printf("after c do_callback\n");
}
```

java 代码

```xml
<dependency>
    <groupId>net.java.dev.jna</groupId>
    <artifactId>jna</artifactId>
    <version>5.8.0</version>
</dependency>

<dependency>
    <groupId>net.java.dev.jna</groupId>
    <artifactId>jna-platform</artifactId>
    <version>5.8.0</version>
</dependency>
```

```java
import com.sun.jna.Callback;
import com.sun.jna.Library;
import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;

public interface DemoLibWrapper extends Library {
    interface ICallback extends Callback {
        void invoke(String name, Pointer buffer);
    }

    //此方法为链接库中的方法
    void init_callback(ICallback callback);
    void do_callback();

    MyObject.ByValue by_value_demo(String name, int id);
    MyObject.ByReference by_pointer_demo(String name, int id);
    Pointer[] return_list_demo(String name, int id);
    int arg_list_reurn_list_demo(Pointer[] list, int size, String name, int id);

    public static class MyObject extends Structure {
        public static class ByReference extends MyObject implements Structure.ByReference{}
        public static class ByValue extends MyObject implements Structure.ByValue{}

        public int id;
        public String name;

        public MyObject(){
            super();
        }

        /*
         * 调用以下方法的时候会用到
         * DemoLibWrapper.MyObject object = new DemoLibWrapper.MyObject(ref.getValue());
         * */
        public MyObject(Pointer pointer){
            super(pointer);
            read();
        }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("id", "name");
        }
    }

    public static class MyObject1 extends Structure {
        public static class ByReference extends MyObject implements Structure.ByReference{}
        public static class ByValue extends MyObject implements Structure.ByValue{}

        public int id;
        public String name;

        public MyObject1(){
            super();
        }

        /*
         * 调用以下方法的时候会用到
         * DemoLibWrapper.MyObject object = new DemoLibWrapper.MyObject(ref.getValue());
         * */
        public MyObject1(Pointer pointer){
            super(pointer);
            read();
        }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("id", "name");
        }
    }
}
```

```java
import com.sun.jna.Native;
import com.sun.jna.Pointer;
import com.sun.jna.ptr.PointerByReference;
import java.util.Arrays;

public class JNATest {
    private static String libPath = "/home/mmc/projects/c/demo_lib/cmake-build-debug/libdemo_lib.so";

    public static void main(String[] args) {
        callback_demo();
        call_by_pointer_demo();
        call_return_list_demo();
        call_arg_list_reurn_list_demo();
    }

    public static void callback_demo(){
        DemoLibWrapper lib = Native.load(libPath, DemoLibWrapper.class);

        lib.init_callback(new DemoLibWrapper.ICallback() {
            public void invoke(String name, Pointer buffer) {
                byte[] data = buffer.getByteArray(0, 5);

                String dataString = Arrays.toString(data);
                String info = name + " " + dataString;
                System.out.println(info);
            }
        });

        lib.do_callback();
    }

    public static void call_by_pointer_demo() {
        DemoLibWrapper lib = Native.load(libPath, DemoLibWrapper.class);

        DemoLibWrapper.MyObject.ByReference result = lib.by_pointer_demo("call_by_pointer_demo", 123);
        System.out.println(result.id);
        System.out.println(result.name);
    }

    /*
     * 这里判断数据是否结束，不怎么好判断，方法不正规
     * */
    public static void call_return_list_demo() {
        DemoLibWrapper lib = Native.load(libPath, DemoLibWrapper.class);

        Pointer[] result = lib.return_list_demo("call_return_list_demo", 123);
        for(Pointer pointer : result ){
            PointerByReference ref = new PointerByReference(pointer);

            String str = ref.getValue().toString();
            if ( !str.contains("native@0x7f") ) break;

            DemoLibWrapper.MyObject object = new DemoLibWrapper.MyObject(ref.getValue());
            String info = object.id + " " + object.name;
            System.out.println(info);
        }
    }

    public static void call_arg_list_reurn_list_demo() {
        DemoLibWrapper lib = Native.load(libPath, DemoLibWrapper.class);

        int size = 5;
        Pointer[] list = new Pointer[size];
        for (int i=0;i<size;i++){
            DemoLibWrapper.MyObject1 object = new DemoLibWrapper.MyObject1();
            object.name = "aaaaaaaa";
            list[i] = object.getPointer();
        }

        int numbers = lib.arg_list_reurn_list_demo(list, size, "arg_list_reurn_list_demo", 123);
        for(int i=0; i< numbers; i++){
            Pointer pointer = list[i];
            PointerByReference ref = new PointerByReference(pointer);

            //DemoLibWrapper.MyObject object = new DemoLibWrapper.MyObject(ref.getValue());
            int id = ref.getValue().getNativeLong(0).intValue();
            String name = ref.getValue().getString(4);

            String info = id + " " + name;
            System.out.println(info);
        }
    }
}
```

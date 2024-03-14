# 和 mysql 通信

## DataStream 方式

sql

```sql
CREATE TABLE `student` (
  `name` varchar(32) DEFAULT NULL COMMENT '姓名',
  `age` int(11) DEFAULT NULL COMMENT '年龄',
  `class` varchar(32) DEFAULT NULL COMMENT '班级'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `student` (`name`, `age`, `class`)
VALUES
  ('xiaoming', 17, '3-1'),
  ('lilei', 18, '3-2'),
  ('lucy', 17, '2-1'),
  ('lily', 15, '2-2');

CREATE TABLE `stuout` (
  `name` varchar(32) DEFAULT NULL COMMENT '姓名',
  `age` int(11) DEFAULT NULL COMMENT '年龄',
  `class` varchar(32) DEFAULT NULL COMMENT '班级'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

pom.xml

```xml
<properties>
  <flink.version>1.13.1</flink.version>
  <flink.scala.version>2.12</flink.scala.version>
</properties>

<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-jdbc_${flink.scala.version}</artifactId>
  <version>1.10.3</version>
</dependency>

<dependency>
  <groupId>mysql</groupId>
  <artifactId>mysql-connector-java</artifactId>
  <version>5.1.48</version>
</dependency>

<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-clients_${flink.scala.version}</artifactId>
  <version>${flink.version}</version>
</dependency>
```

```java
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.io.jdbc.JDBCInputFormat;
import org.apache.flink.api.java.io.jdbc.JDBCOutputFormat;
import org.apache.flink.api.java.typeutils.RowTypeInfo;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.types.Row;

public class JdbcStreamApi {

    public static void main(String[] args) throws Exception {
        // 获取运行环境
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        // 设置并发度为1 可以不设
        env.setParallelism(1);

        // 输入  数据库连接和数据表信息
        JDBCInputFormat inputFormat = JDBCInputFormat
                .buildJDBCInputFormat()
                .setDrivername("com.mysql.cj.jdbc.Driver")
                .setDBUrl("jdbc:mysql://127.0.0.1:4407/demo?useUnicode=true&characterEncoding=UTF8&serverTimezone=GMT%2B8")
                .setUsername("root")
                .setPassword("root")
                .setQuery("select name,age,class from student")
                .setRowTypeInfo(
                        new RowTypeInfo(new TypeInformation[]{Types.STRING, Types.INT, Types.STRING},
                                new String[]{"name", "age", "class"}))
                .finish();

        // 输出 数据库连接和数据表信息
        JDBCOutputFormat outputFormat = JDBCOutputFormat
                .buildJDBCOutputFormat()
                .setDrivername("com.mysql.cj.jdbc.Driver")
                .setDBUrl("jdbc:mysql://127.0.0.1:4407/demo?useUnicode=true&characterEncoding=UTF8&serverTimezone=GMT%2B8")
                .setUsername("root")
                .setPassword("root")
                .setQuery("insert into stuout(name,age,class) values (?,?,?)")
                .finish();

        // 输入
        DataStreamSource<Row> input = env.createInput(inputFormat);

        // 过滤出年龄大于16的记录
        DataStream<Row> filtered =  input.filter(new FilterFunction<Row>() {
            @Override
            public boolean filter(Row value) throws Exception {
                return (int) value.getField(1) > 16;
            }
        });

        // 输出
        filtered.writeUsingOutputFormat(outputFormat);

        env.execute("JdbcStreamApi");
    }
}
```

## slink 模式

pom.xml

```xml
<dependency>
      <groupId>org.apache.flink</groupId>
      <artifactId>flink-clients_${flink.scala.version}</artifactId>
      <version>${flink.version}</version>
    </dependency>

    <dependency>
      <groupId>org.apache.flink</groupId>
      <artifactId>flink-table-planner_${flink.scala.version}</artifactId>
      <version>${flink.version}</version>
    </dependency>

    <!--  流式api需要  -->
    <dependency>
      <groupId>org.apache.flink</groupId>
      <artifactId>flink-json</artifactId>
      <version>${flink.version}</version>
    </dependency>

    <!--  flink jdbc  -->
    <dependency>
      <groupId>org.apache.flink</groupId>
      <artifactId>flink-jdbc_${flink.scala.version}</artifactId>
      <version>1.10.3</version>
    </dependency>

    <dependency>
      <groupId>mysql</groupId>
      <artifactId>mysql-connector-java</artifactId>
      <version>5.1.48</version>
    </dependency>
  </dependencies>
```

```sql
DROP TABLE IF EXISTS `student`;
CREATE TABLE `student` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(25) COLLATE utf8_bin DEFAULT NULL,
    `password` varchar(25) COLLATE utf8_bin DEFAULT NULL,
    `age` int(10) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
```

Demo1.java

```java
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;


public class Demo1 {
    public static void main(String[] args) throws Exception{
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        Student student1 = new Student(1, "name1", "pwd1", 11);
        Student student2 = new Student(2, "name2", "pwd2", 22);
        Student student3 = new Student(3, "name3", "pwd3", 33);
        Student student4 = new Student(4, "name4", "pwd4", 44);

        SingleOutputStreamOperator<Student> student = env.fromElements(student1, student2, student3, student4);
        student.addSink(new SinkToMySQL());

        env.execute("Flink data sink");
    }
}
```

Demo2.java

```java
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;

public class Demo2 {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        DataStreamSource<String> source = env.socketTextStream("127.0.0.1", 9000);
        source.addSink(new MySink("6")).setParallelism(5);
        env.execute("xxxx");
    }
}
```

MySink.java

```java
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.sink.RichSinkFunction;

public class MySink extends RichSinkFunction<String> {
    private String tx;

    public MySink(String tx) {
        System.out.println("+++++++++++++" + tx);
        this.tx = tx;
    }

    @Override
    public void open(Configuration parameters) throws Exception {
        tx = "5";
        System.out.println("========");
        super.open(parameters);
    }

    @Override
    public void invoke(String value, Context context) throws Exception {
        System.out.println(value + " " + tx);
    }
}
```

SinkToMySQL.java

```java
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.sink.RichSinkFunction;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;


public class SinkToMySQL extends RichSinkFunction<Student> {
    PreparedStatement ps;
    private Connection connection;

    /**
     * open() 方法中建立连接，这样不用每次 invoke 的时候都要建立连接和释放连接
     *
     * @param parameters
     * @throws Exception
     */
    @Override
    public void open(Configuration parameters) throws Exception {
        super.open(parameters);
        connection = getConnection();
        String sql = "insert into student(id, name, password, age) values(?, ?, ?, ?);";
        ps = this.connection.prepareStatement(sql);
    }

    @Override
    public void close() throws Exception {
        super.close();
        //关闭连接和释放资源
        if (connection != null) {
            connection.close();
        }
        if (ps != null) {
            ps.close();
        }
    }

    /**
     * 每条数据的插入都要调用一次 invoke() 方法
     *
     * @param value
     * @param context
     * @throws Exception
     */
    @Override
    public void invoke(Student value, Context context) throws Exception {
        //组装数据，执行插入操作
        ps.setInt(1, value.getId());
        ps.setString(2, value.getName());
        ps.setString(3, value.getPassword());
        ps.setInt(4, value.getAge());
        ps.executeUpdate();
    }

    private static Connection getConnection() {
        Connection con = null;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            con = DriverManager.getConnection("jdbc:mysql://127.0.0.1:4407/demo?useUnicode=true&characterEncoding=UTF-8&useSSL=false", "root", "root");
        } catch (Exception e) {
            System.out.println("-----------mysql get connection has exception , msg = "+ e.getMessage());
        }
        return con;
    }
}
```

Student.java

```java
public class Student {
    public int id;
    public String name;
    public String password;
    public int age;

    public Student() {
    }

    public Student(int id, String name, String password, int age) {
        this.id = id;
        this.name = name;
        this.password = password;
        this.age = age;
    }

    @Override
    public String toString() {
        return "Student{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", password='" + password + '\'' +
                ", age=" + age +
                '}';
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

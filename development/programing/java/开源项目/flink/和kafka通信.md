# 和 kafka 通信

参考 [这里](https://github.com/apengda/hello-flink/blob/master/docs/3.Flink%E8%BE%93%E5%85%A5%E8%BE%93%E5%87%BA-kafka.md)

## 普通模式

pom.xml

```xml
<properties>
  <flink.version>1.13.1</flink.version>
  <flink.scala.version>2.12</flink.scala.version>
</properties>

<!--  和 kafka 通信  -->
<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-connector-kafka_${flink.scala.version}</artifactId>
  <version>${flink.version}</version>
</dependency>

<dependency>
  <groupId>com.alibaba</groupId>
  <artifactId>fastjson</artifactId>
  <version>1.2.76</version>
</dependency>
```

生成一些测试数据放入到 kafka 的 student 中

```java
import com.alibaba.fastjson.JSON;
import org.apache.kafka.clients.producer.*;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Random;

public class KafkaGenerateData {

    public static void main(String[] args) throws Exception{

        Properties properties = new Properties();
        properties.setProperty("bootstrap.servers", "127.0.0.1:9092");
        properties.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        properties.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

        final String topic = "student";

        Producer<String, String> producer = new KafkaProducer<>(properties);

        final Random random = new Random();
        for (int i = 0; i < 100; i++){
            Thread.sleep(300);

            Map<String, Object> map = new HashMap<>();
            map.put("name", "xiao-"+i);
            map.put("age", 10 + random.nextInt(10));
            map.put("class", "class-"+ random.nextInt(5));

            String jsonString = JSON.toJSONString(map);
            producer.send(new ProducerRecord<String, String>(topic,jsonString));
        }

        producer.flush();
        producer.close();
    }
}
```

## Stream 方式读写 kafka

pom.xml

```xml
<properties>
  <flink.version>1.13.1</flink.version>
  <flink.scala.version>2.12</flink.scala.version>
</properties>

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

<!--  和 kafka 通信  -->
<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-connector-kafka_${flink.scala.version}</artifactId>
  <version>${flink.version}</version>
</dependency>
```

```java
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.api.java.typeutils.RowTypeInfo;
import org.apache.flink.core.fs.FileSystem;
import org.apache.flink.formats.json.JsonRowDeserializationSchema;
import org.apache.flink.formats.json.JsonRowSerializationSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.streaming.connectors.kafka.KafkaSerializationSchema;
import org.apache.flink.types.Row;
import org.apache.kafka.clients.producer.ProducerRecord;
import javax.annotation.Nullable;
import java.util.Properties;

public class KafkaStreamApi {

    public static void main(String[] args) throws Exception{

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);

        Properties properties = new Properties();
        properties.setProperty("bootstrap.servers", "127.0.0.1:9092");
        properties.setProperty("group.id", "KafkaStreamApi");

        // 反序列化 把byte[]转为 Row
        JsonRowDeserializationSchema schema = new JsonRowDeserializationSchema.Builder(new RowTypeInfo(
                new TypeInformation[]{Types.STRING, Types.INT, Types.STRING},
                new String[]{"name", "age", "class"}
        ))
        .failOnMissingField()
        .build();

        // 创建 kafka 消费者
        FlinkKafkaConsumer<Row> input = new FlinkKafkaConsumer<Row>("student", schema , properties);
        input.setStartFromEarliest();

        // 序列化 把 Row 转为 byte[]
        JsonRowSerializationSchema outSchema = new JsonRowSerializationSchema().Builder(schema.getProducedType()).build();

        // 创建 kafka 生产者
        FlinkKafkaProducer<Row> output = new FlinkKafkaProducer<Row>("stuout",
                new KafkaSerializationSchema<Row>() {
                    @Override
                    public ProducerRecord<byte[], byte[]> serialize(Row element, @Nullable Long timestamp) {
                        return new ProducerRecord<byte[], byte[]>("stuout", outSchema.serialize(element));
                    }
                },
                properties, FlinkKafkaProducer.Semantic.AT_LEAST_ONCE);


        // 1. 读取 kafka 的 student
        DataStreamSource<Row> studentSource =  env.addSource(input);

        // 2. 过滤出年龄大于 16 的记录
        DataStream<Row> filtered = studentSource.filter(new FilterFunction<Row>() {
            @Override
            public boolean filter(Row value) throws Exception {

                return (int) value.getField(1) > 16;
            }
        });

        // 把结果输出到本地文件
        filtered.writeAsText("kafka-student.txt", FileSystem.WriteMode.OVERWRITE);

        // 3. 输出到 kafka 的 stuout 中
        filtered.addSink(output);

        // 触发运行
        env.execute("KafkaStreamApi");
    }
}
```

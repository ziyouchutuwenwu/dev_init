# spark 入门

## 例子

### WordCount

pom.xml

```xml
<properties>
  <spark.version>3.1.2</spark.version>
  <spark.scala.version>2.12</spark.scala.version>
</properties>

<dependency>
  <groupId>org.apache.spark</groupId>
  <artifactId>spark-core_${spark.scala.version}</artifactId>
  <version>${spark.version}</version>
</dependency>

<dependency>
  <groupId>org.apache.spark</groupId>
  <artifactId>spark-sql_${spark.scala.version}</artifactId>
  <version>${spark.version}</version>
</dependency>
```

代码

WordCount.java

```java
import scala.Tuple2;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.sql.SparkSession;
import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;

public final class WordCount {
    private static final Pattern SPACE = Pattern.compile(" ");

    public static void main(String[] args) throws Exception {

        if (args.length < 1) {
            System.err.println("Usage: JavaWordCount <file>");
            System.exit(1);
        }

        SparkSession spark = SparkSession
                .builder()
                .appName("JavaWordCount")
                .master("local")
                .getOrCreate();


        JavaRDD<String> lines = spark.read().textFile(args[0]).javaRDD();

        JavaRDD<String> words = lines.flatMap(s -> Arrays.asList(SPACE.split(s)).iterator());

        JavaPairRDD<String, Integer> ones = words.mapToPair(s -> new Tuple2<>(s, 1));

        JavaPairRDD<String, Integer> counts = ones.reduceByKey((i1, i2) -> i1 + i2);

        List<Tuple2<String, Integer>> output = counts.collect();
        for (Tuple2<?,?> tuple : output) {
            System.out.println(tuple._1() + ": " + tuple._2());
        }
        spark.stop();
    }
}
```

### 流式处理

pom.xml

```xml
<properties>
  <spark.version>3.1.2</spark.version>
  <spark.scala.version>2.12</spark.scala.version>
</properties>

<dependency>
  <groupId>org.apache.spark</groupId>
  <artifactId>spark-core_${spark.scala.version}</artifactId>
  <version>${spark.version}</version>
</dependency>

<dependency>
  <groupId>org.apache.spark</groupId>
  <artifactId>spark-sql_${spark.scala.version}</artifactId>
  <version>${spark.version}</version>
</dependency>

<dependency>
  <groupId>org.apache.spark</groupId>
  <artifactId>spark-streaming_${spark.scala.version}</artifactId>
  <version>${spark.version}</version>
</dependency>
```

nc，随便输入一些文字

```sh
nc -l -p 9999
```

NetworkWordCount.java

```java
import org.apache.spark.api.java.function.FlatMapFunction;
import org.apache.spark.sql.*;
import org.apache.spark.sql.streaming.StreamingQuery;
import java.util.Arrays;

public final class NetworkWordCount {
    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Usage: NetworkWordCount <hostname> <port>");
            System.exit(1);
        }

        String host = args[0];
        int port = Integer.parseInt(args[1]);

        SparkSession spark = SparkSession
                .builder()
                .master("local")
                .appName("NetworkWordCount")
                .getOrCreate();

        // Create DataFrame representing the stream of input lines from connection to host:port
        Dataset<Row> lines = spark
                .readStream()
                .format("socket")
                .option("host", host)
                .option("port", port)
                .load();

        // Split the lines into words
        Dataset<String> words = lines.as(Encoders.STRING()).flatMap(
                (FlatMapFunction<String, String>) x -> Arrays.asList(x.split(" ")).iterator(),
                Encoders.STRING());

        // Generate running word count
        Dataset<Row> wordCounts = words.groupBy("value").count();

        // Start running the query that prints the running counts to the console
        StreamingQuery query = wordCounts.writeStream()
                .outputMode("complete")
                .format("console")
                .start();

        query.awaitTermination();
    }
}
```

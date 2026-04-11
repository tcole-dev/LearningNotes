# 性能优化

## Explain 执行计划分析

### Explain字段分析

explain是用于分析SQL语句执行计划的语句。使用explain在SQL语句前面加上explain关键字即可。explain本身不会执行SQL语句，只是进行分析。

```plaintext
mysql> explain select * from test where a > 2024121;
+----+-------------+-------+------------+-------+---------------+---------+---------+------+---------+----------+--
| id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref  | rows    | filtered | 
+----+-------------+-------+------------+-------+---------------+---------+---------+------+---------+----------+--
|  1 | SIMPLE      | test  | NULL       | range | PRIMARY       | PRIMARY | 4       | NULL | 3991925 |   100.00 | 
+----+-------------+-------+------------+-------+---------------+---------+---------+------+---------+----------+--

------------+
Extra       |
------------+
Using where |
------------+
```

explain语句的各字段含义：

- id ：一个 SQL 语句内部，各个查询块（query block）的标识号，id值越大，越先执行

  ```sql
  EXPLAIN SELECT * FROM t1 WHERE id = ( SELECT MAX(id) FROM t2 );
  -- 可能会出现 id = 1，id = 2，分别表示外层t1、内层t2的查询。
  ```

- select_type ：表示查询类型。常见的值有：

  ```
  SIMPLE	  常见查询，不含子查询			PRIMARY 最外层查询				SUBQUERY 子查询
  SUBQUERY  派生表（子查询在FROM中）		 UNION UNION中的第二个或后续查询
  ```

- table ：表示查询的是哪张表。

- partitions ：表示命中的分区，若是未分区表，该字段则是null

- type ⭐：表示访问方式，决定了性能好坏。

  ```
  不同方式的性能好坏对比：
  System > const > eq_ref > ref > range > index > all
  ```

  `system` 表中只有一行记录，不需要扫描、查找

  `const`   通过主键、唯一主键一次定位到

  `ref`      普通索引

  `range`   范围查找，between、<、>、in

  `index`   扫描整个索引

  `all`       扫描整个表

- possible_keys ：表示可能用到的索引

- key： 表示实际使用的索引

- key_len：使用索引的长度（实际使用的索引的字节的长度），常用于判断聚合索引中实际使用了几列

  ```
  比如现有聚合索引 Index(a, b, c) ，a、b、c 都是 int 类型
  key_len 为 4，即表示只使用了该聚合索引的前缀 a
  ```

- ref ：表示索引列会和什么列对比，**`explain select * from test where a = 2024121;`** ，中 ref 为const，表示和一个常数比较。而上面的比较不是匹配对比某个固定的列，所以为null。

- rows ：表示MySQL`预估`的可能会进行扫描的记录数量，并不是实际可能会查找的记录数，比如上面的例子中，实际会从2024121开始，查找`5,975,880`条记录，而不是`3,991,925`。

  rows字段一般是越小越好。

- filtered ：表示扫描的记录，大概有多少记录符合条件，和rows一样都是估值，并不准确，在上面的例子中，filtered为100%，因为使用主键范围查询，直接从2024121开始扫描，自然都是符合条件的。

- Extra ⭐：表示额外补充信息，常见值有：

  <font color=orange>性能较好：</font>

  `Using index`：覆盖索引

  `Using index condition`：索引下推场景，减少了回表次数

  `Select tables optimized away`：通过索引列的值即可推出，不需要查表，例如MAX()、MIN作用于索引列

  <font color=orange>正常情况：</font>

  `Using where`：MySQL Server 层在接收到存储引擎返回的行后，再进行一次 `WHERE` 条件过滤。
  
  ​	<font color=skyblue>Using where表示没有通过索引直接命中所需记录，返回给Server后还需再次条件判断，常见情况：</font>
  
  ​	<font color=skyblue>没有索引，直接全表扫描后再条件判断，此时`type`字段为`ALL`；where中无法完全用索引匹配；联合索引没完全用上；使用了两个不同索引，此时extra还会有`Using intersect`</font>
  
  `Using join buffer`：连接时用了缓冲，join时被驱动表没有索引，MySQL 将驱动表的数据读入缓冲区，然后批量与被驱动表对比。
  
  <font color=orange>有待改进：</font>
  
  `Using filesort`：额外排序，不一定真的用磁盘，但通常说明排序开销较大
  
  ​	<font color=skyblue>filesort：ORDER BY通常采用两种方式：索引、filesort。当无法使用索引时，通过filesort进行排序，可能在内存或是磁盘中进行</font>
  
  ​	<font color=skyblue>早期filesort采用双路排序，第一遍扫出需要排序的列，将（排序列，行指针）存入缓存区进行排序，然后再次回表查询其他需要的字段。mysql 4.1后加入单路排序，直接将整个记录存入并排序。排序的地点取决于数据大小，数据较小就在缓存区（快速排序），若数据较大，将其分出数块，在内存中排序后存入临时文件，再使用归并排序合并。</font>
  
  `Using temporary`：用了临时表，常见于 `GROUP BY` / `ORDER BY`，比如filesort时数据较大，就会创建临时表，在磁盘中进行排序。
  
  `Impossible WHERE`：条件永远不成立



### 索引选择

前面介绍了如何通过explain分析SQL语句的执行，在这一段会说明优化器是如何选择合适的索引，优化SQL执行的性能。

首先，SQL语句经过解析器语法解析后，会分析、列出能够使用的所有索引（where 语句中涉及的列上的索引、order by 的排序列上的索引、join 时，关联列上的索引），分析每个选择的代价，最后选择代价最小（并不一定是最匹配的索引）的索引。

**如何选择索引？\ 代价如何计算？\ 考虑哪些代价？**

- 扫描行数少（选择性强）。这是最重要的一项，比如在gender这一列加上了索引，where gender = "female" and score = 60;

  若女性占90%，那么使用gender索引和直接全表扫描也没啥区别了。这时就应该在score上加上索引，优化器也会偏向score的索引。

- 尽量不回表。比如二级索引 VS 联合索引。优化器会选择联合索引避免回表。

- 顺序访问。索引查找为随机IO，全表扫描为顺序IO。在数据少的情况，可能会直接进行全表扫描。

- 是否需要filesort？ORDER BY无法使用索引时，可能会需要额外排序，成本更大。

- 是否可以索引下推。



## 慢查询优化

### 慢查询日志

慢查询日志相关配置（可通过配置文件my.ini（Windows环境）设置）：

- slow-query-log 是否开启慢查询日志，1为开启。
- slow_query_log_file 慢查询日志文件
- long_query_time 慢查询阈值，默认为10s 

慢查询日志主要内容：

```
Time                 Id Command    Argument
# Time: 2026-04-10T11:57:47.950575Z
# User@Host: root[root] @ localhost [::1]  Id:    10
# Query_time: 50.565973  Lock_time: 50.563649 Rows_sent: 0  Rows_examined: 0
use test;
SET timestamp=1775822217;
select * from test where a = 8000001 for update;
```

其中，Lock_time表示获取锁花费的时间；Rows_sent表示返回给客户端的数据行数；Rows_examined表示SQL语句实际执行时扫描的数据行数。

在上面的例子中，`select * from test where a = 8000001 for update`想要加上排他锁，此时与已经存在的锁冲突被阻塞了，可以看到Query_time查询时间和Lock_time获取锁时间几乎相等，表示整个查询过程全程都被阻塞，所以原本应该返回数据而此时Rows_sent为0，Rows_examined也为0

### 常见慢查询场景与优化

- 没加索引、索引失效：索引失效的原因有很多（索引列加函数、类型转换、违反最左前缀原则等），参考Day2。此时应该优化索引的使用。
- 优化器选错索引：一般是优化器脑抽导致，自行分析确定有更优选择后可force index 
- 回表过多：回表过多其实也算是索引选择不恰当的问题，尽量选择覆盖索引或者索引下推
- join不合理：核心原则是小表驱动大表，大表作为驱动表时会比对过多数据
- 数据量过大（分页问题）：当某条语句要查找的数据量极大时（`select * from test limit 1000 10`或select * from test），会导致查询较慢（无用又必须扫描的数据较多，一次性需要扫描返回的数据较多。）这个问题在下面会详细讲解。

### 大表分页 / 深分页问题

前面提到，一条`select`语句可能会一次查询非常多数据，且<font color=red>**与索引无关，单纯就是需要扫描太多数据**</font>，这时不管是后端程序、还是客户端都不需要也不能一次性接收全部返回数据（`select * from test;`），而是采用分页的做法（`select * from test limit 10000 10;`）。但这样做虽然不需要返回大量数据，但仍然可能需要扫描极大数量的记录，需要先扫描10000行偏移量，才会返回需要的记录。

常用解决方案：

- 游标索引：

  记录上次分页的最后一行的索引，添加一个where条件，通过索引定位到这次需要的第一行

  ```sql
  SELECT * FROM orders 						SELECT * FROM orders
  ORDER BY id ASC 				--- >		WHERE id > 5432
  LIMIT 10 OFFSET 10000;						ORDER BY id ASC
  										  LIMIT 10;
  ```

- 覆盖索引+子查询：

  先通过索引扫出所有需要命中的记录的主键，子查询只扫描索引（查询列id可直接从索引获取 -- 覆盖索引），外层只通过索引查询需要的完整记录。

  ```sql
  SELECT * FROM orders 						SELECT * FROM orders
  ORDER BY id ASC 				--- >		WHERE id in (
  LIMIT 10 OFFSET 10000;							SELECT id from orders
      										   LIMIT 10000 10）;
  ```

- 延迟关联： 延迟索引的实现思想和覆盖索引+子查询几乎相同，不同的是，延迟关联使用 JOIN 代替 IN，因为MySQL对JOIN优化好

  ```sql
  SELECT * FROM orders 						SELECT * FROM orders o
  ORDER BY id ASC 				--- >		JOIN (
  LIMIT 10 OFFSET 10000;							SELECT id from orders
      										   LIMIT 10000 10
      									   ）t ON o.id = t.id;
  ```

- 后端直接限制分页深度，比如最多分多少页，只能查看一定数量的记录。
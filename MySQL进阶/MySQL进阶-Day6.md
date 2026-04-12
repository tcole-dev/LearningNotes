## InnoDB的逻辑存储结构

InnoDB的逻辑存储结构：MySQL8以后默认开启` innodb_file_per_table = 1`，每张表都存储为一个ibd格式文件。而在一个表文件下，还有段、区、页、行，其中，段、区是逻辑上的划分，页、行才是实际上真正有不同标志的结构。

![](https://i-blog.csdnimg.cn/direct/6d0db2d9e6a647b4ad59ffb65ba75eb9.png)

- 段：分为数据段（存储实际数据，B+树的叶子节点）、索引段（B+树非叶子节点）、回滚段。

  **回滚段其实就是undo log的载体**，在早期版本中，回滚段一般被存放在表空间中，MySQL8及以后，**回滚段只出现在undo log日志文件中**。

- 区：16*64KB（1MB），区是磁盘空间分配的最小单位，同时提供线性预读等功能，提供效率。

  当IO压力大时，段会直接向表空间申请多个区，避免经常性因为页的16KB上限而申请空间。同时，顺序扫描表中的页时，可以提供预读机制，以差不多的代价将整个区读取进入Buffer。

  区只是提供了便利IO的机制，但其内部的页是无序的。页之间的逻辑顺序是通过元数据（定义入口等）和链表结构实现的。

- 页：16KB，一个InnoDB数据页的存储空间大致被划分成了7个部分

  | 英文名称           | 中文含义           | 所占空间   | 备注                     |
  | :----------------- | :----------------- | :--------- | :----------------------- |
  | File Header        | 文件头部           | 38字节     | 页的一些通用信息         |
  | Page Header        | 页面头部           | 56字节     | 数据页专有的一些信息     |
  | Infimum + Supremum | 最小记录和最大记录 | 26字节     | 两个虚拟的行记录         |
  | User Records       | 用户记录           | 大小不确定 | 实际存储的行记录内容     |
  | Free Space         | 空闲空间           | 大小不确定 | 页中尚未使用的空间       |
  | Page Directory     | 页面目录           | 大小不确定 | 页中的某些记录的相对位置 |
  | File Trailer       | 文件尾部           | 8字节      | 校验页是否完整           |

  在页中，记录是按照逻辑顺序排列的。

- 行：在Day3提到过隐藏字段，隐藏字段会和其他字段同时存储在“行”中。

## InnoDB的内存结构

<img src="https://i-blog.csdnimg.cn/direct/15dc788cbaa240e0856b2ad699278a31.png" style="zoom:80%;" /> 

从架构图中可以看到，内存结构中有四个结构：Buffer Pool、Change Buffer、Log Buffer、Adaptive Hash Index。

- **Buffer Pool**：

  首先，我们要了解脏页的概念。在Buffer Pool中，未被访问过的是free page，访问过未修改的是clean page。修改过的是dirty page.在Day1的两阶段提交中，提到，数据的写入过程是：先修改redo log，写入缓存，修改binlog，redo log（commit），等待被刷入磁盘。

  这里的缓存就是Buffer Pool，Buffer Pool中会存储磁盘中的记录，其中未被读取的是free page，读取但未修改的是clean page，修改过的是dirty page（脏页），脏页会在不同情况（下文叙述）下被刷入磁盘，被持久化。

  读取数据时，首先会查看Buffer Pool中是否有，若有直接返回即可，否则从磁盘中读取到Buffer Pool，再读取走。而要写入数据，过程就是上面所述。

- **Change Buffer**：

  Buffer Pool的作用在于提高当数据存在于缓冲区时的读、写效率，那么如果缓冲区中没有对应的数据呢？这时就会用到Change Buffer，Change Buffer用于记录非唯一的二级索引的修改。

  当Buffer Pool中没有对应的记录，就会写在Change Buffer中，当下次需要读取该数据时，InnoDB会读出该记录，与Change Buffer中的修改合并，再返回给Server。

  <font color=red>为什么Change Buffer只能用于非唯一索引？</font> 因为若是唯一索引，InnoDB需要检查修改后的记录的索引是否唯一。

- **Log Buffer**：

  InnoDB的三大日志：sudo log、binlog、redo log中的redo log，为了提高效率，也会像Buffer Pool一样，在缓冲区存储数据，一定时间将数据刷进redo log文件，这个缓冲区就是Log Buffer。既然是内存中的redo log，那么必然是和**`脏页`**相关联的。

  

  <font color=red>脏页刷入磁盘的条件分别有以下几条：</font>

  1. redo log（磁盘中的redo log文件）快满了时。redo log是固定大小的文件，redo log快满了，就将还在内存中的脏页刷入磁盘。
  2. 后台线程定时进行刷盘（常见）
  3. Buffer Pool快满了，需要使用LRU算法淘汰掉最久没有使用的页，若是脏页，此刻就会刷入磁盘
  4. Buffer Pool中脏页比例过大
  5. 数据库关闭时

  <font color=orange>此时又有另一个问题：redo log先存放在内存中，如果此时宕机了怎么办？redo log是否也会丢失，那么还怎么用redo log找回数据？binlog是即时写入磁盘的，会不会导致两者不一致？</font>

  这涉及到一个数据库参数**`innodb_flush_log_at_trx_commit`**，

  当其取值为1时，每次写入Log Buffer都会立刻刷入redo log文件，适合支付等强一致性的场景；

  当其取值为0时，每1秒将数据从Log Buffer刷入redo log，性能更高，但安全性较差，最坏情况会丢失1秒的redo log数据。适合网站点击量等场景。

  当其取值为2时，每次写入会将Log Buffer数据写入操作系统的缓存OS Cache，但还没有写入磁盘，安全性和性能都折中。

  

  已知当innodb_flush_log_at_trx_commit设置为0、2时可能丢失1s数据，此时有两种可能：1. redo log文件中还是prepare（commit丢失），binlog已经写入的情况，此时会按照binlog的写入状态决定是回滚还是补数据； 2. redo log的两阶段提交全部丢失，此时就可能会导致binlog和实际的数据库的不一致，这是MySQL官方承认的一个缺陷，只能通过设置为 1 来避免。

  

- **Adaptive Hash Index**：

  简单来说，Adaptive Hash Index（AHI）就是将常访问的一条查询路径硬生生压成一个hash，不用走B+树，直接通过hash值定位到指定的页。

  AHI的使用前提：查询非常频繁、查询条件模式稳定、等值查询、数据页在Buffer Pool中。

  AHI的工作原理：若一个路径被访问多次，InnoDB会根据其使用的索引、等值条件生成一个hash访问键`search tuple`，如：

  ```sql
  SELECT * FROM t
  WHERE a = 1 AND b = 2;
  
  -- 索引：idx(a, b, c)，组合成 search tuple为 hash(index_id + (a=1,b=2))
  ```

  只要后来的SQL能构造出相同的 (index_id + (a=1,b=2))就可以通过AHI，直接定位页，不用再查找B+树。

  AHI和已经废弃的查询缓存（Query Cache）相比，查询缓存是 SQL语句 -> 行集合，AHI是 search tuple -> 查询路径，查询条件不需要查询，而AHI是提高了查询效率。
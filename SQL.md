# SQL

## SQL参考手册 

https://www.runoob.com/sql/sql-quickref.html

## SQL数据类型

SQL中的数据类型一般取决于数据库，如MySQL和SQL Server的数据类型就不完全相同

**MySQL数据类型**：MySQL数据类型分为Text（文本）、Number（数字）和 Date/Time（日期/时间）类型。以下列举常见类型

**Text**：

- CHAR(size)	保存**固定**长度的字符串（可包含字母、数字以及特殊字符，**长度最多为255，因为数据库用一个字节存储CHAR的长度信息，而一字节保存的无符号整数范围为0-255**）	<font color='red'>固定的意思是，无论字符串实际长度，都分配固定长度的空间存储</font>
- VARCHAR(size)      保存**可变**长度的字符串，长度最大为255
- TEXT                  存放最大长度为 65,535 个字符的字符串
- BLOB                用于 BLOBs（Binary Large OBjects）。存放最多 65,535 字节的数据
- MEDIUMTEXT（MEDIUMBLOB）、LONGTEXT（LONGBLOB） 分别用于存储 16,777,215  、4,294,967,295 个字符的字符串（字节的BLOBs）
- ENUM(x,y,z,etc.)        允许您输入可能值的列表。可以在 ENUM 列表中列出最大 65535 个值。如果列表中不存在插入的值，则插入空值。

**Number：**

| 数据类型        | 描述                                                         |
| :-------------- | :----------------------------------------------------------- |
| TINYINT(size)   | 带符号-128到127 ，无符号0到255。                             |
| SMALLINT(size)  | 带符号范围-32768到32767，无符号0到65535, size 默认为 6。     |
| MEDIUMINT(size) | 带符号范围-8388608到8388607，无符号的范围是0到16777215。 size 默认为9 |
| INT(size)       | 带符号范围-2147483648到2147483647，无符号的范围是0到4294967295。 size 默认为 11 |
| BIGINT(size)    | 带符号的范围是-9223372036854775808到9223372036854775807，无符号的范围是0到18446744073709551615。size 默认为 20 |
| FLOAT(size,d)   | 带有浮动小数点的小数字。在 size 参数中规定显示最大位数。在 d 参数中规定小数点右侧的最大位数。 |
| DOUBLE(size,d)  | 带有浮动小数点的大数字。在 size 参数中规显示定最大位数。在 d 参数中规定小数点右侧的最大位数。 |
| DECIMAL(size,d) | 作为字符串存储的 DOUBLE 类型，允许固定的小数点。在 size 参数中规定显示最大位数。在 d 参数中规定小数点右侧的最大位数。 |

**Date：**

| 数据类型    | 描述                                                         |
| :---------- | ------------------------------------------------------------ |
| DATE()      | 日期。格式：YYYY-MM-DD**注释：**支持的范围是从 '1000-01-01' 到 '9999-12-31' |
| DATETIME()  | *日期和时间的组合。格式：YYYY-MM-DD HH:MM:SS**注释：**支持的范围是从 '1000-01-01 00:00:00' 到 '9999-12-31 23:59:59' |
| TIMESTAMP() | *时间戳。TIMESTAMP 值使用 Unix 纪元('1970-01-01 00:00:00' UTC) 至今的秒数来存储。格式：YYYY-MM-DD HH:MM:SS**注释：**支持的范围是从 '1970-01-01 00:00:01' UTC 到 '2038-01-09 03:14:07' UTC |
| TIME()      | 时间。格式：HH:MM:SS**注释：**支持的范围是从 '-838:59:59' 到 '838:59:59' |
| YEAR()      | 2 位或 4 位格式的年。**注释：**4 位格式所允许的值：1901 到 2155。2 位格式所允许的值：70 到 69，表示从 1970 到 2069。 |

不同数据类型，字节也大小不同，Number中的size只是显示时的宽度，不是大小

通用数据类型：

| 数据类型                           | 描述                                                         |
| :--------------------------------- | :----------------------------------------------------------- |
| CHARACTER(n)                       | 字符/字符串。固定长度 n。                                    |
| VARCHAR(n) 或 CHARACTER VARYING(n) | 字符/字符串。可变长度。最大长度 n。                          |
| BINARY(n)                          | 二进制串。固定长度 n。                                       |
| BOOLEAN                            | 存储 TRUE 或 FALSE 值                                        |
| VARBINARY(n) 或 BINARY VARYING(n)  | 二进制串。可变长度。最大长度 n。                             |
| INTEGER(p)                         | 整数值（没有小数点）。精度 p。                               |
| SMALLINT                           | 整数值（没有小数点）。精度 5。                               |
| INTEGER                            | 整数值（没有小数点）。精度 10。                              |
| BIGINT                             | 整数值（没有小数点）。精度 19。                              |
| DECIMAL(p,s)                       | 精确数值，精度 p，小数点后位数 s。例如：decimal(5,2) 是一个小数点前有 3 位数，小数点后有 2 位数的数字。 |
| NUMERIC(p,s)                       | 精确数值，精度 p，小数点后位数 s。（与 DECIMAL 相同）        |
| FLOAT(p)                           | 近似数值，尾数精度 p。一个采用以 10 为基数的指数计数法的浮点数。该类型的 size 参数由一个指定最小精度的单一数字组成。 |
| REAL                               | 近似数值，尾数精度 7。                                       |
| FLOAT                              | 近似数值，尾数精度 16。                                      |
| DOUBLE PRECISION                   | 近似数值，尾数精度 16。                                      |
| DATE                               | 存储年、月、日的值。                                         |
| TIME                               | 存储小时、分、秒的值。                                       |
| TIMESTAMP                          | 存储年、月、日、小时、分、秒的值。                           |
| INTERVAL                           | 由一些整数字段组成，代表一段时间，取决于区间的类型。         |
| ARRAY                              | 元素的固定长度的有序集合                                     |
| MULTISET                           | 元素的可变长度的无序集合                                     |
| XML                                | 存储 XML 数据                                                |

[通用数据类型](https://www.runoob.com/sql/sql-datatypes-general.html)

SQL用于各数据库的数据类型 [参考链接地址](https://www.runoob.com/sql/sql-datatypes.html)

## 基础语法

### 增、删、查、改

- CREATE命令，用于新建数据库或表格。需要配合子句使用 CREATE DATABASE（创建数据库）；CREATE TABLE（创建新表）. . .

- 增添数据：

  INSERT命令插入**`记录`**（行）

  ```sql
  INSERT INTO -- 向表中插入新数据，注意插入的数据以“记录”为单位
  
  INSERT INTO table_name (column1, column2, ...)
  VALUES (value1, value2, ...);
  -- (column1, column2, ...)表示指定的列（字段、属性），(value1, value2, ...)表示新记录的对应列的值，没有被指定的列的值则取决于 "该列的定义和数据库设置"
  
  INSERT INTO VALUES (value1,value2,...); -- 不指定列则插入一条完整对应的记录
  ```

- 删除数据：

​       DELETE命令删除**`记录`**

```sql
DELETE FROM -- 向表中删除一行数据（记录）

DELETE FROM table_name
WHERE condition
/*  table_name 表示表名，condition表示筛选条件，以下文档均如此表示
若不写WHEER语句，DELETE会删除表中所有记录，但保留表结构 */
```

- UPDATE 命令修改数据

```sql
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition
-- condition限制了某几条记录的column对应的值修改 如：
UPDATE table_name
SET name = 'Ted' , age = 18
WHERE id = '204121083'
```



- ALTER命令修改表结构（添加，删除“列”、索引、约束、主键、外键）

  ALTER命令是【修改数据库对象】的总命令，具体使用方法为 **ALTER [对象类型] [对象名] [具体操作];**   不同于INSERT、DELETE、UPDATE命令，ALTER用于操作【数据库的结构】

  ALTER TABLE是ALTER的一种用法， 用于修改【表】的结构，除此之外，还有 ALTER DATABASE

  添加列

```sql
ALTER TABLE table_name
ADD column_name1 data_type [constraints]
ADD column_name2 data_type [constraints];
-- constraints表示约束，[]表示约束是可选的，可不写
```

​	删除列

```sql
ALTER TABLE table_name
DROP COLUMN column_name1
DROP COLUMN column_name2;
```

​	修改列的属性（类型、约束，不包括主键、外键）

```sql
ALTER TABLE table_name
ALTER COLUMN column_name new_data_type [new_constraints];
-- Oracle数据库中ALTER COULMN子句应修改为 MODIFY 或 MODIFY COLUMN
```

​	重命名列

```sql
ALTER TABLE table_name
RENAME COLUMN old_column_name TO new_column_name;
```

ALTER TABLE 除了以上针对【列】的子句，还有其他针对【表】本身、【约束】、【索引】的子句，不赘述

- SELECT 查询命令

SELECT命令是SQL中最常用的命令，完整的 SELECT 命令语句为：

```sql
SELECT [ALL | DISTINCT] 列名1 [别名1], 列名2 [别名2]	    -- 要查询的列
FROM 表名1 [别名1], 表名2 [别名2], ...                      -- 数据来源表
[WHERE 条件表达式]                                         -- 筛选行的条件
[GROUP BY 列名1, 列名2, ... [HAVING 分组条件]]              -- 按列分组及分组筛选
[ORDER BY 列名1 [ASC | DESC], 列名2 [ASC | DESC], ...]     -- 排序结果
[LIMIT 数量 [OFFSET 偏移量]];                              -- 限制返回行数（部分数据库支持）
```

```sql
-- 对上述命令逐条解析
-- [ALL | DISTINCT] 去重参数，ALL表示将完全相同的记录去重   [别名]即用 AS 将选中的列取别名，举例：
SELECT DISTINCT column_name1 AS new_name1 , SUM(column_name2) AS new_name2
-- WHERE 筛选符合条件的记录
WHERE flag = 'TRUE'
-- GROUP BY，可选，将查询的记录按指定的属性分组，如GROUP BY column_name1会将查询的记录按column_name1的值进行分组
GROUP BY column_name1
-- HAVING ，可选，筛选”分组“后的结果，类似WHERE

-- WHERE、GROUP BY、HAVING  执行顺序为：WHERE->GROUP BY->HAVING,其中HAVING可使用聚合函数如SUM()等

-- ORDER BY 按指定列进行排序，可选参数为ASC（升序、默认）、DESC（降序），具体的顺序优先级按指定的多个列的前后书写顺序决定
SELECT id ， cno FROM table
ORDER BY id DESC , cno ASC;
-- LIMIT 限制返回的行数（MySQL、PostgreSQL 等支持，SQL Server 用 TOP，Oracle 用 ROWNUM）
SELECT * FROM articles 
LIMIT 10 OFFSET 20;  -- 从第21行开始，返回10行（第3页数据，每页10条）
```

### SQL运算符

1. AND 、OR，SQL中的AND用于连接多个条件，多个条件都满足时，表达式返回true 如：WHERE id = 'SC0001' AND class = ’stu'，OR类似
2. NOT 非运算 即 !

特殊条件

1. is null 空值判断     例`SELECT * FROM table_name WHERE cns is null`
2. between and  判断是否在某一范围之间     例：Select * from emp where sal between 1500 and 3000;

大于等于 1500 且小于等于 3000， 1500 为下限，3000 为上限，下限在前，上限在后，查询的范围包涵有上下限的值。

3. in  查询符合给定的值的数据

```sql
Select * from emp where sal in (5000,3000,1500);
-- 查询 EMP 表 SAL 列中等于 5000，3000，1500 的值。
```

4.  like 模糊查询	like模糊查询只支持 % 和 _  两种通配符匹配，与正则匹配区别

**% 表示多个字值，_ 下划线表示一个字符**

```sql
Select * from emp where ename like 'M%';
/*
 M% : 表示的意思为模糊查询信息为 M 开头的。
 [charlist]: 字符列表中的任意字符
 [^charlist]: 不在字符列中的任何单一字符
 
 %M% : 表示查询包含M的所有内容。
 %M_ : 表示查询以M在倒数第二位的所有内容。
*/
```

WHERE语句的筛选实际是根据WHERE后的运算符返回的true和false来进行的，若不带运算符，0和1可转化为true和false

例如：

```sql
SELECT studentNO FROM student WHERE 0
```

则会返回一个空集，因为每一行记录 WHERE 都返回 false。

```sql
SELECT  studentNO  FROM student WHERE 1
```

返回 student 表所有行中 studentNO 列的值。因为每一行记录 WHERE 都返回 true。

### 其他操作符

- JOIN  SQL中的JOIN用于将两个或多个表连接起来

<img src="C:\Users\t'c\Desktop\Markdowns\img\sql-join.png" style="zoom: 67%;"/>

INNER JOIN  只获取两表中符合条件的记录（交集）

LEFT JOIN     保留左表，连接右表符合条件的记录，若某条记录左表有数据而右表没有，则会用NULL代替

RIGHT JOIN  与LEFT JOIN类似

- UNION 操作符    UNION 操作符用于合并两个或多个 **SELECT 语句**的结果集，注意，**UNION 操作符默认会去除重复的记录，如果需要保留所有重复记录，可以使用 UNION ALL 操作符**

```sql
SELECT column1, column2, ...
FROM table1
UNION
SELECT column1, column2, ...
FROM table2;
```

<img src="C:\Users\t'c\Desktop\Markdowns\img\53e8e79b70093d886b466af8e7f71c5.png" style="zoom:50%;" />

UNION操作符并不保证合并数据具有相同含义，只是按照指定的列进行简单直接的合并

- SELECT INTO  用于将一个表的内容复制到另一个表，等价于 CREATE TABLE new_table_name AS SELECT * FROM old_table_name

但是，在MySQL中，不能使用SELECT INTO，取而代之的是    INSERT INTO SELECT  和上述的 CREATE TABLE AS SELECT

```sql
SELECT * FROM old_table_name INTO now_table_name WHERE sc > 100;
-- 如上，SELECT INTO同样可以使用WHERE限制
```

MySQL、PostgreSQL的替代方案

```sql
-- CREATE TABLE AS SELECT
CREATE TABLE now_table_name AS
SELECT * FROM old_table_name;
[WHERE condition]

-- INSERT INTO SELECT
INSERT INTO new_table_name
SELECT * old_table_name;
[WHERE condition]
-- 与插入数据时相同，使用INSERT INTO可以指定要复制的列
```

<font color='red'>**SELECT INTO、 CREATE TABLE AS SELECT 都要求存入数据的表预先不存在，INSERT INTO SELECT要求表已经存在**</font>

### 约束

SQL 约束用于规定表中的数据规则。

如果存在违反约束的数据行为，行为会被约束终止。

约束可以在创建表时规定（通过 CREATE TABLE 语句），或者在表创建之后规定（通过 ALTER TABLE 语句）。

使用CREATE TABLE  +  CONSTRANINT语法

```sql
CREATE TABLE table_name
(
    column_name1 data_type(size) constraint_name,
    column_name2 data_type(size) constraint_name,
    column_name3 data_type(size) constraint_name,
    ....
);
```

在 SQL 中，我们有如下约束：

- **NOT NULL** - 指示某列不能存储 NULL 值。
- **UNIQUE** - 保证某列的所有值都是唯一的。
- **PRIMARY KEY** - NOT NULL 和 UNIQUE 的结合。确保某列（或两个列多个列的结合）有唯一标识，有助于更容易更快速地找到表中的一个特定的记录。即<font color='red'>**主键**</font>
- **FOREIGN KEY** - 保证一个表中的数据匹配另一个表中的值的参照完整性。即<font color='red'>**外键**</font>
- **CHECK** - 保证列中的值符合指定的条件。
- **DEFAULT** - 规定没有给列赋值时的默认值。
- **INDEX** - 用于快速访问数据库表中的数据。

```sql
-- 外键的定义
CREATE TABLE Orders (
    OrderID INT NOT NULL PRIMARY KEY,
    OrderNumber INT NOT NULL,
    CustomerID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
```

上述代码 “FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)”一行中：

`FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)` 表示 `Orders` 表的 `CustomerID` 列关联到 `Customers` 表的 `CustomerID` 列，建立了订单与客户之间的关联关系。

**这意味着 `Orders` 表中 `CustomerID` 的值必须是 `Customers` 表中已存在的 `CustomerID` 值（或为 `NULL`，因为该列允许为空）**，否则插入 / 更新会失败，保证了数据的参照完整性。

```sql
-- CHECK
CREATE TABLE Products (
    ProductID INT NOT NULL PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2) CHECK (Price >= 0)
);

-- DEFAULT
CREATE TABLE Customers (
    CustomerID INT NOT NULL PRIMARY KEY,
    LastName VARCHAR(50) NOT NULL,
    FirstName VARCHAR(50),
    JoinDate DATE DEFAULT GETDATE()
);
-- JoinDate字段的默认值为 GETDATE()，这是一个SQL内部自带的聚合函数
```

INDEX 约束的创建、删除需要用到 CREATE INDEX 和 DROP INDEX命令

**创建索引：**

```sql
-- 普通索引
CREATE INDEX 索引名 ON 表名(列名);

-- 唯一索引（确保列值唯一）唯一索引除了会添加索引外，还要求该列的数据全部都唯一
CREATE UNIQUE INDEX 索引名 ON 表名(列名);

-- 复合索引（多列组合）
CREATE INDEX 索引名 ON 表名(列1, 列2, ...);
```

**删除索引：**

```sql
-- 标准语法
DROP INDEX 索引名 ON 表名;

-- 某些数据库（如MySQL）的写法 		但MySQL同时也可使用上面的语法删除索引
ALTER TABLE 表名 	DROP INDEX 索引名;
```

### AUTO INCREMENT (自增)

AUTO INCREMENT 是SQL中的一种机制或列属性，给列设置后，每一条记录插入时会自动为该列添加新的值（上一行的值自增得到），一般用于实现主键。AUTO INCREMENT 的特点：

1. **自动生成值**：当插入新记录时，无需手动指定该列的值，数据库会自动分配一个比当前最大值大 1 的数值。
2. **唯一性**：生成的数值唯一，适合作为主键或唯一标识符。
3. **连续性**：默认情况下是连续递增的，但删除记录后不会回填空缺（例如删除 ID=5 的记录，新记录仍会是 6、7...）。

AUTO INCREMENT 在不同数据库的实现方式不同：

MySQL / MariaDB  ---   AUTO_INCREMENT关键字 . . .   [详细叙述](https://www.runoob.com/sql/sql-autoincrement.html)

```sql
CREATE TABLE Persons
(
ID int NOT NULL AUTO_INCREMENT,
LastName varchar(255) NOT NULL,
FirstName varchar(255),
Address varchar(255),
City varchar(255),
PRIMARY KEY (ID)
)
-- 默认地，AUTO_INCREMENT 的开始值是 1，每条新记录递增 1。
-- 要让 AUTO_INCREMENT 序列以其他的值起始，请使用下面的 SQL 语法：
ALTER TABLE Persons AUTO_INCREMENT=100
```

<font color='red'>注意：给已经存在的colume添加自增语法：</font>

```sql
ALTER TABLE table_name CHANGE column_name column_name data_type(size) constraint_name AUTO_INCREMENT;

-- 举例
ALTER TABLE student CHANGE id id INT( 11 ) NOT NULL AUTO_INCREMENT;
```

## 视图

**视图（View）** 是一种虚拟的表，它本身不存储实际数据，而是基于一个或多个基础表（或其他视图）的查询结果动态生成。

**1. 简化复杂查询，降低使用门槛**

实际业务中，数据分析或报表生成常需关联多个表（如多表 JOIN、子查询、聚合计算），编写的 SQL 语句可能冗长且复杂。视图可将这些复杂逻辑 “封装” 起来，用户无需理解底层表结构和关联关系，只需查询视图即可获取目标结果。

如何理解：将 在多个表中查询的复杂的SELECT语句逻辑封装成 一个视图，不需要每次查询表获取数据而是直接通过视图，也可以像函数一样将常用的查询命令封装成一个视图供随时调用

**2. 隐藏隐私数据，保证安全**

数据库中常存储敏感信息（如用户手机号、身份证号、薪资、密码哈希），直接开放基础表给用户可能导致信息泄露。视图可通过 “筛选列” 或 “筛选行” 的方式，仅暴露用户所需的非敏感数据，限制对敏感信息的访问。

如何理解：视图好比编程的函数，执行预先设定的指令后，将固定的数据读取出来，这样可以防止恶意的对表中的隐私信息的访问。在实际使用中，用户需要获取存储在表中的数据时，后端程序会以固定的预先设定的数据库用户登录数据库提取数据，通过限制数据库用户的权限，即可限制某一权限的用户只能获取视图中的数据，保证安全性。

**3. 批量数据更新**

视图是虚拟表，但在满足特定条件（如基于单表、无聚合函数 / 分组 / 子查询）时，可通过视图直接更新、插入或删除数据，这些操作会自动映射到底层基础表，简化批量数据维护。

**4. 辅助数据导出**

在报表工具（如 Excel、Tableau、PowerBI）或数据导出场景中，直接连接多表查询可能因逻辑复杂导致配置困难。视图可预先将所需数据整理为 “扁平结构”（如关联后的单表格式），报表工具只需连接视图，即可快速获取结构化数据，无需在工具中配置复杂关联逻辑。

**5. 视图的操作**

视图是虚拟表，因此视图和表的操作基本类似   [详细叙述链接](https://www.runoob.com/sql/sql-view.html)
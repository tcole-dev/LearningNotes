## Mybatis框架（持久层）

Mybatis是ssm中的持久层框架，将SQL查询封装进对象，通过操作对象的方法执行SQL语句，是一款半自动ORM框架，而Hibernate则是一款全自动ORM框架。

### Mybatis基础配置与使用

1. Mybatis配置文件mybatis-config.xml，这个文件中声明DTD文件路径，JDBC的数据库驱动类、url、用户名、密码等。

   <u>**DTD（文档类型定义）文件是用于定义XML或SGML文档结构的规范**。它规定了文档中允许的元素、属性、实体及其相互关系，确保文档遵循特定的语法和结构。</u>

   mybatis-config.xml一般放在resources路径下，实例：

   ```xml
   <?xml version="1.0" encoding="UTF-8" ?>
   <!DOCTYPE configuration
           PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
           "https://mybatis.org/dtd/mybatis-3-config.dtd">
   <configuration>
       <environments default="development">
           <environment id="development">
               <transactionManager type="JDBC"/>
               <dataSource type="POOLED">
                   <property name="driver" value="com.mysql.cj.jdbc.Driver"/>
                   <property name="url" value="jdbc:mysql://localhost:3306/web-demo"/>
                   <property name="username" value="root"/>
                   <property name="password" value="tc2389231473"/>
               </dataSource>
           </environment>
       </environments>
       <mappers>
           <mapper resource="mapper/UserMapper.xml"/>
       </mappers>
   </configuration>
   ```

2. mapper接口，mapper接口中定义一个接口，每一个抽象方法对应一条SQL语句。安装MybatisX插件后，可直接在mapper接口和mapper.xml之间跳转。

```xml
import java.util.List;

public interface UserMapper {
    List<User> list();
}

```

**mapper接口中的方法不需要重写**，框架会通过JDK代理创建代理对象，拦截接口方法调用

3. mapper.xml映射配置文件，书写Java方法所绑定的SQL语句，在resources/mapper路径下创建，如：

   ```xml
   <!-- 声明xml文件的DTD文件 -->
   <?xml version="1.0" encoding="UTF-8" ?>
   <!DOCTYPE mapper
           PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
           "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
   <!-- 将不同的mapper接口的方法绑定指定的SQL语句 -->
   <mapper namespace="org.Tcoder.mybatis.mapper.UserMapper">
       
       <!-- 将mapper接口中的每一个抽象方法绑定到一条SQL语句 -->
       <select id="list" resultType="org.Tcoder.demo.User">
       <!-- id表示mapper接口中的方法名 -->
       <!-- resultType表示将SQL语句返回数据包装成指定的类型，可以理解为返回值类型 -->
           select * from users;
       </select>
   </mapper>
   ```

   除了mapper.xml文件书写SQL语句，**还可以通过注解方式在mapper接口中映射简单语句**，但这种方式不适合复杂的SQL映射。两种方式，需要灵活使用

   ```java
   package org.mybatis.example;
   public interface BlogMapper {
     @Select("SELECT * FROM blog WHERE id = #{id}")
     Blog selectBlog(int id);
   }
   ```

4. 实体类，用一个Java类包装SQL语句返回的数据，如从User表中获取一条记录，其中有ID、Name、Password，可用一个含有三个对应的属性的User类包装，返回的每一条记录都成为一个User对象。对应mapper.xml中的`resultType`

5. 如何启动Mybatis框架

   1. 通过InputStream读取mybatis-config.xml

      ```java
      InputStream inputstream = Resources.getResourceAsStream("mybatis-config.xml");
      ```

   2. 通过new SqlFactoryBuilder().build(inputStream)

      ```java
      SqlSessionFactory sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
      ```

   3. 获得会话

      ```java
      SqlSession sqlSession = sqlSessionFactory.openSession();
      ```

   4. 获取执行器

      ```java
      UserMapper userMapper = sqlSession.getMapper(UserMapper.class );
      ```

      UserMapper即 3. 提到的mapper接口，UserMapper.class表示获取UserMapper的字节类

   5. 使用创建的usermapper对象调用UserMapper接口的抽象方法，从而使用SQL语句

### Mybatis进阶

#### Mybatis配置部分

- 属性`properties`

创建属性并赋值，创建的属性在整个配置文件中可用，可视为**`局部变量`**

```xml
<properties>
  <property name="username" value="dev_user"/>
  <property name="password" value="F2Fa3!33TYyg"/>
</properties>
```

```xml
<property name="username" value="${username}"/>
```

- `typeAliases`取别名

类型别名，主要用于为繁冗的包和类取别名，方便书写，类似C语言中的宏定义

```xml
<typeAliases>
  <typeAlias alias="Author" type="domain.blog.Author"/>
  <typeAlias alias="Blog" type="domain.blog.Blog"/>
</typeAliases>
```

- 类型处理器

用于将Java中的类与数据库的数据类型一一对应，如将`String`转化成`VARCHAR`或相反

- 环境配置

环境配置一般包含两部分：事务管理方式、数据源。

事务管理方式：JDBC、MANAGED。JDBC直接使用JDBC的提交和回滚等，而MANAGED则直接交由框架执行

<u>事务管理：现有两条SQL语句、分别对A删除、对B增加，若删除执行而增加执行失败，就会引起严重错误，在银行场景尤为突出，因此需要事务管理，包括提交回滚等，在JDBC中，删、改、添都需要手动执行session.commit()方法提交，若执行失败可以执行回滚避免数据错误</u>

数据源：包含多个环境的属性

```xml
<dataSource type="POOLED">
      <property name="driver" value="${driver}"/>
      <property name="url" value="${url}"/>
      <property name="username" value="${username}"/>
      <property name="password" value="${password}"/>
</dataSource>
```

#### Mybatis映射文件

- **结果映射**

前面提到resultType表示返回的数据的封装类型，**但一般不使用resultType**，因为不一定包装的类可以与数据库中的字段完全对应，因此，更多使用resultMap

在映射文件Mapper.xml中\<mapper>元素中写：

```xml
<resultMap id='UserMap' type='org.tcoder.demo.User'>
	<id property='id' column='id'/>
    <name property='name' column='Name'/>
</resultMap>
```

resultMap标签中的type属性表示映射到的Java实体类

property表示对应Java实体类中的属性，column表示数据库中的字段

- **useGeneratedKeys**

该属性只适用于`select`和`update`语句的，useGeneratedKeys='true'表示Mybatis会自动调用JDBC的getGeneratedKeys方法获取自增的主键，使用的同时要通过KeyProperty、KeyColumn手动标记主键映射的类属性、字段

```xml
<select userGeneratedKeys='true' KeyProperty='id' KeyColumn='ID'>
	select Name,Password from users;
</select>
```

- **SQL片段**

因为一些SQL片段经常在SQL语句中使用，可以将常用的SQL片段存入sql标签中，在使用sql语句时直接插入

```xml
<sql id='baseColumn'>
	ID,Name
</sql>
<select id='list' resultMap='userMap'>
	select
    <include refid='baseColumn'/>
    from users;
</select>
```

- **参数化查询**

1. @Param注解指定参数，@Param注解用在mapper接口中抽象方法内，用于标注方法的参数，让对应的sql语句可以直接在SQL语句中使用这些参数。

```java
interface userMapper {
    List<User> listByName(@Param("Name") String name);
}
```

原理即将传入的参数name映射为@Param注解中的字符串“Name”，这个字符串可以直接在SQL语句中调用，实现参数化查询。

SQL语句中写法：

```xml
<select id='listByName' resultMap='userMap'>
	select * from users where Name=#{Name};
</select>
```

2. #{} 、${}

两者都是参数化查询中的占位符用法，其中${}是不转译用法，有SQL注入风险，但是在特定情况下只能使用该方式。

例如我们要动态的来指定查询的表。而不是固定用户表。或者是指定排序方式 order by asc/desc等。

因为#{}会自动对字符串添加引号，对int、date等不会添加引号；${}不会自动添加引号，因此可以用在动态拼接SQL语句、指定查询表等场景中。

总之，${}是更纯粹的格式化插入参数，如python中的 `f'{name}'`，而#{}更适用于插入用户输入的查询条件，避免SQL注入。

```java
SELECT ${condition},ID FROM users WHERE ${condition} = #{input};
```

<font color='red'>**若两者互换，condition会被自动加上引号，查询会失败；input则有可能会被SQL注入**</font>

#### 动态SQL

[简短版文档](https://www.yuque.com/teemo730/share/nr7vuvo0gi3za2z4) 		[Mybatis官方文档](https://mybatis.org/mybatis-3/zh_CN/dynamic-sql.html)

## Spring框架（业务层）

### spring配置

1. **依赖下载（Maven）**

```xml
<dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-context</artifactId>
            <version>5.3.39</version>
</dependency>
```

2. **配置（Java类配置）**

- 创建SpringConfig类，标记`@Configuration`、`@ComponentScan`注解

- 创建实际使用的类

```java
public static void main(String[] args) {
    	// 创建Spring容器 SpringConfig是Spring的配置类
        AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(SpringConfig.class);
        // 使用指定服务 NameClass是标记了Component注解的类
    	NameServer nameServer = context.getBean(NameServer.class);
        // 可以正常调用nameServer的方法
    	nameServer.getName("Theo Cole");
    }
```

### IOC、DI

IOC（Inversion of Control）控制反转。传统编程中，类、对象、方法等需要其他对象时，需要手动new一个对象，这种硬编码一来让程序灵活性差，修改时要修改大量代码；二来让对象及依赖高度绑定造成高耦合度。而IOC通过依赖注入，将依赖的创建注入都交给框架完成，即依赖的控制从程序员反转到框架。

<u>耦合度：不同的组件、类、对象等之间的依赖程度，若耦合度高，则牵一发而动全身，代码不易维护，测试困难，移植性差，也容易报错。在实际开发中，要遵循**“高内聚，低耦合”**的思想，尽量让每个组件各司其职，不需要管其他模块的功能。</u>

DI（Dependency Injection）依赖注入，实现IOC的方式，将所需依赖从外部注入，依赖注入有三种方式：**属性（字段）注入、构造方法注入、Setter注入**，其中**常用构造方法注入**。

```java
@Component
public class NameServer {
    // 属性注入实例
    @Autowired
    private PasswordServer passwordServer;
    
    // 构造方法注入
    @Autowired
    public NameServer(PasswordServer passwordServer) {
        this.passwordServer = passwordServer;
    }
    
    // Setter方法注入
    @Autowired
    public void SetPasswordServer(PasswordServer passwordServer) {
        this.passwordServer = passwordServer;
    }
    
    public String getByName(String name) {
        return "The Details: " + name + " " + passwordServer.getPassword();
    }
}
```

### 面向接口编程

IOC、DI是面对接口编程的一种落地实现机制，让开发过程中尽量不直接绑定指定的类或对象，而是指定为实现了某种接口的对象，降低耦合度。

### 依赖注入常用注解

1. @Autowired	标记需要注入依赖的地方，通过@Qulifier标记具体注入的依赖名称，避免混淆（多实现注入）
2. @Resource          Java自带的注解，功能与AUtowired类似，Resource通过自身name属性标记注入依赖名称
3. @Qulifier              
4. @Component     标记需要被Spring容器识别的Bean类
5. @Value                 简单注入属性值，可从配置文件、环境变量中读取并注入

<u>**多实现注入**：由于面向接口编程的规范，一个接口可以被多个类实现，因此在注入时，框架不能识别具体要注入的对象，解决这个问题的方法如下：</u>

@Qulifier注解，配合@Autowired使用，传入实际要注入的Bean对象

```java
@Autowired
@Qulifier("demoAServer")
// demoAServer表示要注入的是类DemoAServer的对象，这个Bean对象的命名默认为类名首字母改为小写
private DemoServer demoServer;
// DemoServer为接口，demoServer表示实现了DemoServer接口的一个类的对象
```

@Resource注解，使用自身属性实现多实现注入

```java
@Resource(name = "demoAServer")
private DemoServer demoServer;
```

### AOP

AOP，面向切面编程，AOP不是spring、甚至不是java特有的概念。实际编程中，许多逻辑需要反复复用，AOP就是将这些逻辑封装到一个切面中，用指定方式将切面织入到需要使用的地方。 AOP 的核心是「**通过代理对象增强目标方法**」。

面向切面编程（AOP，Aspect-Oriented Programming）是一种代码组织和复用范式，其核心思想是将传统的**纵向处理**，改为**横向切割**，从而实现**通用业务**和**核心业务**逻辑分离。可以达到代码的复用、解耦。

![传统代码实现](C:\Users\t'c\Desktop\Markdowns\img\Traditional-AOP.png)

![AOP代码逻辑实现](C:\Users\t'c\Desktop\Markdowns\img\AOP.png)

在第二张图中，权限校验、开启事务、提交回滚等操作均可以用AOP实现，并自动织入三个接口的代码实现中，并在对应代码执行前后执行。

### AOP实现逻辑

#### 定义切面逻辑

1. 启动AOP代理   对配置类加`@EnableAspectJAutoProxy`注解

2. @Aspect注解，将一个类声明为切面

3. @Ponitcut注解，标注对谁进行切面处理✨

```java
@Pointcut("bean(studentDemo)")
public void pointCut() {}
```

@Pointcut并不是作用于切面类本身，而是切面类中的某一个方法，作用如下：

@Pointcut注解声明切点，**public void pointcut()方法没有实际意义，但pointcut方法可以作为Pointcut注解中声明的bean(studentDemo)的一个”别名“**，可在通知类型注解中使用，如@After("pointcut()")，表示在pointcut切点执行后通知。

<u>注意：@Pointcut并不是必须使用的注解，在通知类型注解中，也可以直接声明切点，使用@Pointcut注解的意义在于：代码复用和持久化，让一个切点在定义后可以反复使用，而不必多次重复写，写了@Pointcut之后，即可直接引用已标注的切点。</u>

4. 写明通知类型和处理逻辑✨

```java
@Aspect
@Component
public class Demo {
    @After("pointcut()")
    public void DemoFunction() {
        System.out.println("切点执行完毕");
    }
}
```

#### 通知类型

执行前通知：		 Before			返回void		在切点对应方法之前执行

执行后通知：		 After			   返回void		切点之后执行

正常返回结果后通知： AfterReturning	  返回void		在切点正常执行并返回值后执行

抛出异常后通知：	 AfterThrowing	   返回void		在切点抛出异常后执行

环绕通知：		     Around		       必须返回Object    是所有通知类型的超集，可完全代替前面的类型

<font color='red'>**重点✨：**</font>

**@AfterReturning**，`@AfterThrowing(value = "execution(* com.example.service.*.*(..))", returning = "ex")`

returning属性值为切点返回的值。

```java
@AfterReturning(value = "execution(* com.example.service.*.*(..))", returning = "result")
public void afterReturning(JoinPoint joinPoint, Object result) {
    System.out.println("AfterReturning: 方法返回结果 = " + result);
}
```

**@AfterThrowing**，`@AfterThrowing(value = "execution(* com.example.service.*.*(..))", throwing = "ex")`

throwing表示切点抛出的错误

```java
@AfterThrowing(value = "execution(* com.example.service.*.*(..))", throwing = "ex")
public void afterThrowing(JoinPoint joinPoint, Exception ex) {
    System.out.println("AfterThrowing: 方法抛出异常 = " + ex.getMessage());
}
```

<u>以上的两种注解，其中的returning、throwing分别为返回值和抛出异常，这两个值在方法签名中也必须分别保持一致，如returning=“ex” 对应 Object result；throwing=“ex” 对应 Exception ex</u>

<font color='red'>**@Around**</font>，最强大的通知类型✨。使用方法如下：

```java
@Around("execution(* com.example.service.*.*(..))")
public Object aroundAdvice(ProceedingJoinPoint joinPoint) throws Throwable {
    System.out.println("Around: 方法执行前");	  // 执行切点目标方法前的操作
    Object result = joinPoint.proceed(); 		 // 执行目标方法
    System.out.println("Around: 方法执行后");	  // 执行目标方法后的操作
    return result; // 可以修改返回值
}
```

✅ 写法特点：

- 参数必须是 `ProceedingJoinPoint`
- 返回类型必须是 `Object`
- 必须调用 `joinPoint.proceed()` 才能继续执行目标方法，否则方法不会被执行。
- @Around中使用`定义Object变量接收返回值`代替`AfterReturning`；`try-catch`语法代替`AfterThrowing`

#### 切点表达式

1. execution   方法执行   execution( [修饰符] 返回类型 \[包路径.类名.方法名](参数列表) [throws 异常] )

```java
// 匹配Service包下所有类的public方法
@Pointcut("execution(public * com.example.service.*.*(..))")
```

#### 通配符说明

| **符号** | **含义**                | **示例**         |
| -------- | ----------------------- | ---------------- |
| `*`      | 匹配任意单个元素        | `java.*.Service` |
| `..`     | 匹配多个元素（包/参数） | `com.example..*` |

2. within：  类/包范围限定，快速匹配整个类或包下的所有方法

3. this           基于JDK动态代理时匹配接口类型

   ```java
   // 匹配代理对象实现UserService接口的方法
   @Pointcut("this(com.example.service.UserService)")
   ```

4. bean        Spring特有语法，Spring Bean名称匹配

   ```java
   // 匹配ID为userService的Bean
   @Pointcut("bean(userService)")
   
   // 匹配名称以Service结尾的Bean
   @Pointcut("bean(*Service)")
   
   // 排除指定Bean
   @Pointcut("bean(userService) && !bean(adminService)")
   ```

**组合表达式技巧**

| **运算符** | **说明** | **示例**                                                |
| ---------- | -------- | ------------------------------------------------------- |
| &&         | 逻辑与   | `execution(* save*(..)) && within(com.example.service)` |
| \|\|       | 逻辑或   | `@annotation(AuditLog) || @within(SecureApi)`           |
| !          | 逻辑非   | `execution(* *(..)) && !bean(testService)`              |

[参考链接--teemo](https://www.yuque.com/teemo730/share/oqsqwud8na1grkv7)

[参考链接--Spring官方](https://docs.spring.io/spring-framework/reference/core/aop/ataspectj/pointcuts.html)

### Spring事务管理

Mybatis自带的事务管理控制范围小，不支持事务传播，自动化程度不足，在SSM组合中，常用Spring的事务管理

#### Spring事务管理的使用

1. 引入依赖

   ```xml
   <dependency>
     <groupId>org.springframework</groupId>
     <artifactId>spring-jdbc</artifactId>
     <version>5.3.39</version>
   </dependency>
   ```

2. 配置类中开启

   ```java
   @Configuration
   @EnableTransactionManagement
   public class AppConfig {
       @Bean
       public PlatformTransactionManager transactionManager(DataSource dataSource) {
           return new DataSourceTransactionManager(dataSource);
       }
   }
   ```

3. 对需要进行数据库操作的方法加上@Transactional注解，方法的访问修饰符必须为Public，因为Spring的事务管理基于AOP，只代理public方法。

   ```java
   @Service
   public class OrderServiceImpl implements OrderService {
       @Override
       @Transactional
       public void createOrder(Order order) {
           // 数据库操作1
           orderDao.insert(order);
           // 数据库操作2
           inventoryDao.deduct(order.getItemId());
       }
   }
   ```

   <u>AOP代理，Spring中AOP代理的实现有两种方式，Spring在开启事务时，会自动使用不同的方式。1. JDK代理，JDK原生自带，通过实现指定接口的方式创建代理对象，但只针对实现接口的代码设计风格；2. CGLIB代理，基于第三方库，通过继承原有类的方式创建代理对象。</u>

   <u>两种代理方式对应Java的两种代码设计风格：面向接口编程（传统SSM常用）和面向对象（Spring Boot常用）</u>

#### 扩展

##### 关键参数

```java
@Transactional(
    isolation = Isolation.READ_COMMITTED, // 隔离级别
    propagation = Propagation.REQUIRED,   // 传播行为
    timeout = 30,                        // 超时秒数
    rollbackFor = Exception.class        // 回滚异常
)
```

- 隔离级别：事务隔离级别定义了多个事务并发执行时，彼此之间的可见性和影响程度。Spring支持标准SQL定义的4种隔离级别，用于解决并发事务可能引发的数据一致性问题。

  四种隔离级别：

  **读未提交（READ_UNCOMMITTED）**

  问题：允许读取其他事务未提交的修改。

  风险：脏读（Dirty Read）、不可重复读（Non-Repeatable Read）、幻读（Phantom Read）。

  适用场景：对一致性要求极低，追求高并发性能。

  **读已提交（READ_COMMITTED）**

  默认值：多数数据库（如Oracle）的默认隔离级别。

  解决：避免脏读，但允许不可重复读和幻读。

  适用场景：允许事务间看到已提交的数据变化（如统计报表）。

  **可重复读（REPEATABLE_READ）**

  默认值：MySQL的默认隔离级别。

  解决：避免脏读和不可重复读，但允许幻读。

  机制：事务内多次读取同一数据的结果一致，但新增数据可能被其他事务插入（幻读）。

  **串行化（SERIALIZABLE）**

  解决：强制事务串行执行，避免所有并发问题（脏读、不可重复读、幻读）。

  代价：性能最低，仅适用于严格要求一致性且并发量小的场景。

- 传播行为：传播行为定义了事务方法在调用其他事务方法时，事务如何传播。Spring提供了7种传播行为。

  **REQUIRED（默认）**

  规则：如果当前存在事务，则加入该事务；否则新建一个事务。

  场景：大多数业务方法（如订单和库存操作需在同一个事务中）。

  **REQUIRES_NEW**

  规则：无论当前是否存在事务，都新建一个事务，并挂起当前事务（如果存在）。

  场景：日志记录（即使主事务回滚，日志仍需提交）。

  **NESTED**

  规则：如果当前存在事务，则在嵌套事务（保存点）中执行；否则新建事务。

  特点：嵌套事务回滚不影响外层事务，但外层事务回滚会导致嵌套事务回滚。

  场景：复杂业务的分步操作（如订单创建成功后，部分子操作可独立回滚）。

  **SUPPORTS**

  规则：如果当前存在事务，则加入；否则以非事务方式运行。

  场景：查询方法可适应有无事务的环境。

  **NOT_SUPPORTED**

  规则：以非事务方式执行，挂起当前事务（如果存在）。

  场景：某些不需要事务的操作（如发送消息）。

  **MANDATORY**

  规则：强制当前必须存在事务，否则抛出异常。

  场景：确保方法必须在事务上下文中调用。

  **NEVER**

  规则：强制当前不能存在事务，否则抛出异常。

  场景：禁止事务的方法（如性能敏感的只读操作）。

##### 事务失效

- **方法非 `public`修饰**

- **自调用问题（同一个类内部调用事务方法）**

​	**. . . . . . **

​	[参考链接](https://www.yuque.com/teemo730/share/ydl5t8km76v460du#89effd86)

## Spring MVC框架（表现层）

### SpringMVC配置

1. **引入依赖**

```xml
<dependency>
  <groupId>javax.servlet</groupId>
  <artifactId>javax.servlet-api</artifactId>
  <version>4.0.1</version>
  <scope>provided</scope>
</dependency>
<dependency>
  <groupId>org.springframework</groupId>
  <artifactId>spring-webmvc</artifactId>
  <version>5.2.25.RELEASE</version>
</dependency>
<dependency>
  <groupId>com.fasterxml.jackson.core</groupId>
  <artifactId>jackson-databind</artifactId>
  <version>2.11.0</version>
</dependency>
```

2. **配置SpringMVC（后续的web层容器）**

```java
@Configuration
@ComponentScan("com.teemo.mvc.demo")
@EnableWebMvc
public class SpringMvcConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 针对前后端不分离的项目，可配置静态资源放行
        registry
                // 表示所有以/static/开头的请求都会被这个处理器处理
                .addResourceHandler("/static/**")
                // classpath:/static/表示这些资源位于类路径下的static目录中
                .addResourceLocations("classpath:/static/")
                // 缓存一年
                .setCacheControl(CacheControl.maxAge(Duration.ofDays(365)));
    }
}
```

@EnableWebMvc注解：**完全启用 SpringMVC 的配置机制，禁用默认配置**。

**（传统SSM项目）**启用@EnableWebMvc后，会导入一个配置类DelegatingWebMvcConfiguration.class，这个类会接管 MVC 的所有核心配置（包括消息转换器、视图解析器、静态资源处理器等**（底层组件）**），同时也需要自己配置许多WebMvcConfigurer的行为（静态资源映射、默认首页等）

<u>加了 `@EnableWebMvc` 之后，SpringMVC 框架**只提供“结构”，不提供“默认内容”**。</u>

**（SpringBoot项目）**不启用@EableWebMvc注解时，SpringBoot默认会配置WebMvcConfigurer行为，但也可通过重写接口中的方法进行覆盖

3. **配置Servlet（前端控制器 DispatcherServlet）**

```java

import org.springframework.web.servlet.support.AbstractAnnotationConfigDispatcherServletInitializer;

public class ServletConfig extends AbstractAnnotationConfigDispatcherServletInitializer {

	// 配置root容器（父容器）（Spring）
    @Override
    protected Class<?>[] getRootConfigClasses() {
        return new Class[0];
    }
	// 配置web容器（子容器）（SpringMVC）
    @Override
    protected Class<?>[] getServletConfigClasses() {
        return new Class[]{SpringMvcConfig.class};
    }
	// 配置映射和拦截的url
    @Override
    protected String[] getServletMappings() {
        return new String[]{"/"};
    }
}

```

4. Controller类

```java
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@RequestMapping("/mvc")
@Controller
public class MvcController {
    @RequestMapping("/test")
    @ResponseBody
    public String test() {
        System.out.println(1);
        return "test";
    }

    @RequestMapping("/index")
    public String index() {
        return "/static/index.html";
    }
}
```

除了@RequestMapping注解，每个http请求都有专属的Mapping注解，如GetMapping

### 注解的使用

- @Component 作用在类上，将类注册为Bean
- @ComponentScan  用在配置类上，扫描注解，注册Bean。可以指定扫描范围，分别配置不同的组件部分，实现多配置类
- @Bean 作用在方法上，表示该方法会返回一个对象，注册为Bean（常用于第三方库的类注册为Bean）

**root容器（Spring）**

1. IOC依赖注入相关注解

2. root容器中业务层、数据访问层

   - @Service             标记为业务层组件

   - @Repository      标记为数据访问层组件

     . . . . . .

**web容器（SpringMVC）**

- @Controller                标记控制器，处理http请求
- @RequestMapping    标记方法对应的映射  <u>内含多个参数，用于精准匹配请求</u>

- @GetMapping/PostMapping        简化的http请求映射注解
- @ResponseBody        将方法返回值直接作为响应体（而非视图）

<u>逻辑视图 (视图)：Controller的返回值为字符串，不会被直接作为资源路径，实际是“逻辑视图”，由视图解析器解析为实际的路径，@ResponseBody注解会将返回值作为响应体的内容，发送给前端，而不是项目中的路径</u>

- @ResponseStatus      指定响应状态码

- @RequestBody           自动将接收的请求体JSON转换为Java对象，**专门用于请求体传参方式**

  ```java
  @PostMapping("/users")
  public ResponseEntity<User> createUser(@RequestBody User user) {
      // @RequestBody将请求体JSON自动转换为User对象
      User savedUser = userService.save(user);
      return ResponseEntity.ok(savedUser);
  }
  ```


### 参数传递

- URL传递

URL传参只适合少量非敏感的信息，GET请求使用URL传参

```java
@RestController
@RequestMapping("/urlParam")
public class UrlParamController {

	// 若参数和方法形参完全对应，可省略@RequestsParam
    @GetMapping("/m1")
    public ResultVO m1(String name, String age) {
        System.out.println(name);
        System.out.println(age);
        return ResultVO.success();
    }
	// @RequestsParam注解显式将参数绑定到形参
    @GetMapping("/m2")
    public ResultVO m2(@RequestParam("studentName") String name,
                   @RequestParam String age,
                   @RequestParam(required = false) String gender) {
        System.out.println(name);
        System.out.println(age);
        System.out.println(gender);
        return ResultVO.success();
    }
	// java对象作为形参，会自动将参数封装到指定的对象中
    @GetMapping("/m3")
    public ResultVO m3(StudentQryDTO dto) {
        System.out.println(dto);
        return ResultVO.success();
    }
}
```

<u>@RequestsParam注解属性:  1. required属性表示参数是否必须  2. value 表示对应的参数  3. defaultValue 表示没有传入对应参数时的默认值</u>

- Body传递

1. **内容类型**

   **a. application/x-www-form-urlencoded**

   - 这是最常见的POST请求的数据格式，也是HTML表单的默认提交方式。
   - 数据被编码为键值对的形式，键和值之间使用=连接，键值对之间使用&连接。
   - 例如：param1=value1&param2=value2
   - 特点：简单、直观，但只适合传递少量简单的数据，不适合传递复杂的结构或大量数据。

   **b. multipart/form-data**

   - 主要用于文件上传，也可以用来传递普通的键值对。
   - 每个表单字段（包括文件）都被编码为一个单独的部分（part），每个部分都有自己的Content-Disposition头部，用来描述字段的名称和其他属性。
   - 文件通常使用Content-Type: application/octet-stream来标识，并且包含Content-Disposition: form-data; name="filename"; filename="filename.jpg"这样的头部。
   - 特点：**适合上传文件，以及包含文本和文件字段的复杂表单提交。**

   **c. application/json**

   - 使用JSON格式来编码数据，是RESTful API中最为常见的数据格式。
   - 数据被编码为一个JSON对象，包含多个键值对，键是字符串，值可以是字符串、数字、布尔值、数组、对象等。
   - 例如：{"param1": "value1", "param2": "value2"}
   - 特点：结构清晰，易于阅读和解析，支持复杂的数据结构，是现代Web开发中的首选格式。

   **d. text/plain**

   - 简单的文本格式，直接发送原始文本数据。
   - 很少在API交互中使用，但在某些特殊情况下可能有用。
   - 特点：简单、原始，无需额外的解析。

   **e. application/xml**

   - 使用XML格式来编码数据。
   - XML是一种标记语言，可以描述复杂的数据结构。
   - 特点：结构严谨，但相对于JSON来说，可读性较差，解析也较为复杂。

   **f. 其他二进制格式**

   - 例如image/png、audio/mpeg等，用于发送图片、音频、视频等二进制数据。
   - 特点：直接发送二进制数据，无需额外的编码或解析。

2. **body传参接收**

Body传参还需要另外配置一个Bean和依赖，[见此处文档中Body传参部分](https://www.yuque.com/teemo730/share/ghcuk045gohgwho8#j1klG)

```java
@RestController
@RequestMapping("/bodyParam")
public class BodyParamController {


    @PostMapping("/m1")
    public ResultVO m1(StudentQryDTO dto) {
        System.out.println(dto);
        return ResultVO.success();
    }

    @PostMapping("/m2")
    // 同时传递普通对象（键值对）和二进制的图片文件，必须采用multipart/form-data表单格式
    public ResultVO m2(StudentQryDTO dto, MultipartFile img) {
        System.out.println(dto);
        if (null != img){
            System.out.println(img.getSize() / 1024.0 /1024.0);
        }
        return ResultVO.success();
    }
	// @RequestBody将传递的json转换为Java对象
    @PostMapping("/m3")
    public ResultVO m3(@RequestBody StudentQryDTO dto) {
        System.out.println(dto);
        return ResultVO.success();
    }
}
```

- 请求头传参

  ```java
  @RestController
  @RequestMapping("/headerParam")
  public class HeaderParamController {
      @GetMapping("/m1")
      // 获取请求头中的Accept-Encoding字段的值作为String encode的值
      public ResultVO m1(@RequestHeader("Accept-Encoding") String encode) {
          System.out.println(encode);
          return ResultVO.success();
      }
  	// 请求对象和枚举器配合遍历请求头字段
      @GetMapping("/m2")
      // 通过原生的Servlet获取请求对象
      public ResultVO m1(HttpServletRequest request) {
          String author = request.getHeader("author");
          System.out.println(author);
          // request.getHeaderNames方法获取请求头中所有字段的键名，封装在Enumeration对象中
          Enumeration<String> headerNames = request.getHeaderNames();
          while (headerNames.hasMoreElements()){
          // 遍历所有键名（字段），通过getHeader方法获取每个字段的值
              String s = headerNames.nextElement();
              System.out.println(s +"---"+request.getHeader(s));
          }
          return ResultVO.success();
      }
  }
  ```

  **@RequestHeader**注解：获取指定的请求头属性，类似URL传参中的@RequestParam

  **Enumeration对象**：Enumeration（枚举器）是Java早期的对象，作用和用法类似**迭代器（Iterator）**，但不能删除元素

- Cookie

  ```java
  @RestController
  @RequestMapping("/cookieParam")
  public class CookieParamController {
  
      @GetMapping("/m1")
      public ResultVO m1(HttpServletRequest request, HttpServletResponse response) {
          Cookie user = new Cookie("user", "teemo");
          response.addCookie(user);
          return ResultVO.success();
      }
  
      @GetMapping("/m2")
      public ResultVO m1(HttpServletRequest request) {
          Cookie[] cookies = request.getCookies();
          if (null != cookies){
              for (Cookie cookie : cookies) {
                  System.out.println(cookie.getName()+"---"+cookie.getValue());
              }
          }
          return ResultVO.success();
      }
  }
  ```
  
- Session

  ```java
  @RestController
  @RequestMapping("/sessionParam")
  public class SessionParamController {
  
      @GetMapping("/m1")
      public ResultVO m1(HttpSession session) {
          session.setAttribute("student", "good");
          return ResultVO.success();
      }
  
      @GetMapping("/m2")
      public ResultVO m1(HttpServletRequest request, HttpSession session) {
          HttpSession session1 = request.getSession();
          System.out.println(session.getAttribute("student"));
          System.out.println(session1.getAttribute("student"));
          return ResultVO.success();
      }
  }
  ```

### 响应

- 重定向和转发

1. 针对返回值是String，返回的资源默认会被转发，并且区分相对路径和绝对路径

   ```java
   @GetMapping("/list")
   public String anlimals(){
       return "redirect:/static/index.html";
   }
   
   @GetMapping("/test")
   public String test(){
       return "list";
   }
   ```

2. 重定向使用redirect:

   ```java
   @GetMapping("/list")
   public String anlimals(){
       return "redirect:/static/index.html";
   }
   ```

- @ResponseBody

前面已经提到，默认情况下，Controller 方法返回的字符串会被视为**视图名称**。`@ResponseBody`注解的作用是将控制器方法的返回值通过适当的转换器转换为指定的格式（如JSON或XML），并直接写入HTTP响应体中，发送给客户端。此时客户端得到的是**纯粹的数据**。

- @RestController

@RestController =  Controller注解+ResponseBody注解

## SSM整合

[文档链接](https://www.yuque.com/teemo730/share/utagguw5b8uyqaf9)

# SpringBoot

## SpringBoot配置

1. SSM组合中，程序的开端是各框架的配置类，如Mybatis由配置类的数据源、MapperScan初始化；Spring框架的IOC控制反转等也需要@Component、@ComponentScan等注解进行Bean注册的操作等；SpringMVC框架中不仅需要SpringMVC本身的配置，Servlet也需要用Spring、SpringMVC的配置类进行配置。

​	SpringBoot的启动依赖于@SpringBootApplication注解标注的main方法，因此@ComponentScan也是作用于这个启动类上，而	Mybatis则被包含在SpringBoot配置类中，这个配置类整合了各配置信息，服务器端口、数据源、mybatis的mapper等。

​	其他繁琐的配置则由SpringBoot自动完成。

2. SpringBoot的依赖
   - `spring-boot-starter-parent`，该依赖维护了多个外部库的版本，springboot项目引入外部库时，框架会自动根据这个父pom中维护版本来配置，但一般只有spring全家桶和较常见的库才会被自动维护。同时，这个依赖还会定义maven插件配置、java编译打包方式
   - `spring-boot-starter-web`，该依赖负责根据父pom中的信息引入web（尤其是RESTful）项目所需的基础依赖。

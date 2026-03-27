# java异步不同实现方式和演进

## 概述

本文重点介绍java中，异步api的各种实现及它们之间的演进关系，最多提及相关基本原理、适用场景，具体讲述可能会有，也可能直接鸽掉。U_U

## java异步总体示意图

这张图并不能完全表现java异步实现方式之间的关系，譬如:ForkJoinPool并不就一定是ExecutorServicePool的上位，中间并行的三者也不一定就完全解耦。只是按照时间、优化、侧重等方面来看，能够大致这样划分。

```
                                      ┌─────────────────────┐
                                      │   响应式框架层       │
                                      │ (RxJava/Reactor)    │
                                      └──────────┬──────────┘
                                                 │
                                      ┌──────────┴──────────┐
                                      │   Flow API (JDK 9)  │
                                      └──────────┬──────────┘
                                                 │
                    ┌────────────────────────────┼────────────────────────────┐
                    │                            │                            │
          ┌─────────┴─────────┐      ┌───────────┴───────────┐    ┌───────────┴───────────┐
          │ CompletableFuture │      │   Fork/Join Framework │    │    Spring @Async      │
          │     (JDK 8)       │      │        (JDK 7)        │    │    (框架层封装)        │
          └─────────┬─────────┘      └───────────┬───────────┘    └───────────┬───────────┘
                    │                            │                            │
                    └────────────────────────────┼────────────────────────────┘
                                                 │
                                      ┌──────────┴──────────┐
                                      │  CompletionService  │
                                      │      (JDK 5)        │
                                      └──────────┬──────────┘
                         					   |           
                                      ┌──────────┴──────────┐
                                      │  	Executor	   │
                                      │      (JDK 5)        │
                                      └──────────┬──────────┘
                                                 |
                                      ┌──────────┴──────────┐
                                      │ Future & Callable   │
                                      │      (JDK 5)        │
                                      └──────────┬──────────┘
                                                 │
                                      ┌──────────┴──────────┐
                                      │       Thread        │
                                      │     (JDK 1.0)       │
                                      └─────────────────────┘
```

### Thread异步

Thread实现异步是最最基本的一种方式，直接创建一个线程，将要执行的方法交给它，自己可以做其他事。本质上就是直接通过操作系统实现异步。

实现方式也及其简单：1. 继承Thread类，重写run方法	2. 实现Runnable接口，重写run方法，传入Thread构造方法。

注意：此时还没有Callable接口，Callable是jdk5才提出的，而多线程则是jdk1.0就已经存在了。而此时的缺点则是**需要频繁创建线程**，开销极大、**无法获取返回值**。

### Future & Callable

虽然很多文档中都把Future放在线程池的后面（/上面），但我觉得Future和Callable应该更靠底层一些，因为线程池中其实也使用了FutureTask（Future的一个实现），虽然线程池的核心在于`线程复用`，并不一定就需要能接收返回值，但`Future & Callable`也同样不是一定要依靠线程池才能使用。

**Future & Callable实现异步：**

```java
public class Main {
    public static void main(String[] args) throws Exception {
        // 1. 创建一个 Callable 任务
        Callable<Integer> myTask = () -> {
            System.out.println("子线程正在计算...");
            Thread.sleep(1000); // 模拟耗时操作
            return 42;
        };

        // 2. 使用 FutureTask 包装 Callable，因为 Thread 类只能接受 Runnable，而 FutureTask 同时实现了Runnable和Future
        FutureTask<Integer> futureTask = new FutureTask<>(myTask);

        // 3. 将 FutureTask 放入 Thread 中并启动
        Thread thread = new Thread(futureTask);
        thread.start();

        System.out.println("主线程可以继续做其他事...");

        // 4. 获取返回结果（注意：get() 方法会阻塞，直到子线程执行完毕）
        Integer result = futureTask.get();
        System.out.println("计算结果是: " + result);
    }
}
```

Future的不足：

1. 无法被动接收任务结果，还是需要主动`get`，甚至get方法还是会阻塞。
2. Future虽然可以保存异常，但也需要`get`时才能抛出，无法被动感知。

Future的实现原理在这里不赘述。

### Executor 线程池

为了解决`线程复用`的问题，jdk 5同时产生了java并发中最核心、最重要的线程池，线程池本质上就是对Thread的封装，同时通过维护线程队列、任务队列，还能实现拒绝策略等复杂逻辑。

```
Executor (接口)
    │
    └── ExecutorService (接口)
            │
            ├── ThreadPoolExecutor (核心实现)
            │
            └── ScheduledThreadPoolExecutor (定时任务)
```

线程池没什么好说的，简单原理很容易动，深入谈论源码又很复杂，也不赘述。

### CompletionService

`CompletionService`是Java中`java.util.concurrent`包下的一个接口，旨在简化异步任务的管理与结果收集。它结合了ExecutorService和BlockingQueue，能将任务的提交与结果的处理分离，主要特点是按任务完成的先后顺序（而非提交顺序）来获取执行结果。

说人话就是，线程池获取返回值的传统方式是“排队等叫号”，而 `CompletionService` 是“谁先做完谁喊我”。不使用CompletionService的情况下，若主线程使用List\<Future>循环获取结果时：

```java
for (Future f : futures) {
    f.get(); // 如果第一个 f 是任务 A，主线程会在这里死等 10 秒
}
```

即使线程B 1 秒就跑完了，主线程还得阻塞等待拿到A的结果才行。

CompletionService 的解决方案：`CompletionService` 内部引入了一个 **已完成任务队列（Completion Queue）**，谁先完成任务先出，不关心任务提交顺序，只关心完成任务的顺序。

```java
ExecutorCompletionService<String> completionService = new ExecutorCompletionService<>(executor);
......
System.out.println(">>> 正在等待任务结果（谁快谁先出）...");
for (int i = 0; i < taskCount; i++) {
    try {
        Future<String> completedFuture = completionService.take(); 
        String result = completedFuture.get();
        System.out.println("返回结果: " + result);
    } catch (ExecutionException e) {
        e.printStackTrace();
    }
}
```

注意：take() 会阻塞直到队列中有已完成的任务。那有人就会问了，“哎呀，那不还是一样吗？”，虽然`take()`也会阻塞，但它永远都是拿最先返回的值，就是阻塞那也是阻塞时间最短的。

### Fork/Join Framework

Fork/Join Framework -- ForkJoinTask、ForkJoinPool，以`分治法`为核心思想，主要算法为`工作窃取（Work Stealing）算法`。

- 每个线程维护一个双端队列
- 每个线程完成自己任务后会从其他线程的队列尾部”窃取“任务，协助完成。

```java
ForkJoinTask (抽象类)
    ├── RecursiveTask<V> (有返回值)
    |── RecursiveAction (无返回值)
ForkJoinPool (Fork&Join使用的线程池)
```

注意，使用Fork/Join Framework时，不是继承`ForkJoinTask`，而是继承`ForkJoinTask的子类`。

ForkJoinPool适合需要大量运算的巨型任务，而ExecutorServicePool适合IO密集型、独立任务、长耗时任务。

### CompletableFuture

`CompletableFuture` 是 Java 8 引入的一个**异步编程核心类**，属于对传统 `Future` 的增强版，它不仅能表示“未来结果”，还支持**链式编程、回调、组合多个异步任务**，是现代 Java 异步模型的核心。

- 最古老的时候

  ```java
  public String getUserOrderInfo() throws Exception {
      // 1. 查询用户（远程调用 / IO）
      String user = getUser();
  
      // 2. 查询订单（远程调用 / IO）
      String order = getOrder();
  
      // 3. 拼接结果
      return user + " : " + order;
  }
  ```

  要先后在getUser()、getOrder()处阻塞，耗时 T = t1 + t2

- 后来引入Future

  ```java
  ExecutorService pool = Executors.newFixedThreadPool(2);
  
  Future<String> userFuture = pool.submit(() -> getUser());
  Future<String> orderFuture = pool.submit(() -> getOrder());
  
  // 阻塞等待
  String user = userFuture.get();
  String order = orderFuture.get();
  
  return user + " : " + order;
  ```

  此时同时提交两个任务，但同样要在`get()`处阻塞，耗时 T = max( t1, t2 )

- CompletableFuture时代

  ```java
  CompletableFuture<String> userFuture =
      CompletableFuture.supplyAsync(() -> getUser());
  
  CompletableFuture<String> orderFuture =
      CompletableFuture.supplyAsync(() -> getOrder());
  
  CompletableFuture<String> resultFuture =
      userFuture.thenCombine(orderFuture,
          (user, order) -> user + " : " + order
      );
  
  // 最终获取结果（可以不阻塞，继续链）
  String result = resultFuture.get();
  ```

在CompletableFuture中，不再需要主动等待完成任务拿到结果再操作，而是可以通过`回调方法`的方式，一旦收到数据就自动完成。同时，CompletableFuture还支持链式编程，如下：

```java
// 传统写法
String user = getUser();
String detail = getUserDetail(user);
String result = process(detail);

// 链式写法
CompletableFuture
    .supplyAsync(() -> getUser())
    .thenApply(user -> getUserDetail(user))
    .thenApply(detail -> process(detail));
```

链式写法下，不再需要阻塞等待，异步操作收到返回值自动执行下一个方法，依次下去。

值得一提的是，CompletableFuture并不是真正的AIO，而是多路复用，属于同步非阻塞。同时，CompletableFuture底层使用的线程池也是一个全局共用的**ForkJoinPool**，**但在提交任务时，也可以传入自定义线程池**。

### @Async注解

@Async注解是Spring框架中提供的异步注解，用于标注异步方法。

1. 开启异步支持，在配置类上标注@EnableAsync

2. 在需要异步支持的方法上标注@Async，该方法所属类必须被注册为Bean（@Service等注解）

   ```java
   @Service
   public class UserService {
   
       @Async
       public void sendEmail() {
           System.out.println(Thread.currentThread().getName());
       }
       @Async
       public CompletableFuture<String> task() {
           return CompletableFuture.completedFuture("ok");
       }
   }
   ```

注意到，@Async获取的返回值是CompletableFuture类型，说明其底层其实是CompletableFuture。

### Fork/Join、CompletableFuture、@Async关系

这三者之间的关系，可以看作是 **“接口工具”、“执行引擎”与“声明式框架”** 的协作关系。它们不是互斥的替代品，而是处于 Java 异步生态位中不同的层级。

| **组件**                | **定位**                                  | **角色 (类比)**                                              |
| ----------------------- | ----------------------------------------- | ------------------------------------------------------------ |
| **`ForkJoinPool`**      | **底层的执行引擎** (ExecutorService 实现) | **施工队**：负责搬砖、分工、干活的苦力，擅长任务拆解。       |
| **`CompletableFuture`** | **异步编排工具** (编程模型)               | **图纸与调度**：规定先刷墙再装灯，负责验收每一次成功和开始下一步操作。 |
| **`@Async`**            | **声明式注解** (Spring 框架抽象)          | **外包合同**：只要签个字（加个注解），活儿就自动丢给别人干了。 |

@Async -- 隐藏细节 --> CompletableFuture -- 底层依赖 --> ForkJoinPool

### 

后面的内容，暂时先鸽掉。Ciallo～(∠・ω< )⌒★
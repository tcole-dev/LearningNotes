- 🧠 **源码级理解（必须）**：看过源码 + 能复述设计
- 👀 **理解即可（不用抠源码）**：知道原理 + 能解释
- ✍️ **徒手复现（必须写出来）**：不看资料能写

------

# 一、JUC（这是地基，要求最高）

## 🧠 必须做到「源码级理解」

这些东西 **不看源码，你永远是“会用但不懂”**：

### 1️⃣ AQS（核心中的核心）

**要求**

- 理解：
  - state 的含义
  - CAS 修改 state
  - CLH 队列
- 知道：
  - acquire / release 的整体流程
  - 独占 / 共享区别

👉 不要求你能手写 AQS，但：

> **别人问你：ReentrantLock 怎么实现的？你要能顺着 AQS 说下来**

------

### 2️⃣ ReentrantLock（基于 AQS）

**要求**

- 公平锁 / 非公平锁源码路径
- 为什么非公平性能更好
- Condition 的实现思路

------

### 3️⃣ ConcurrentHashMap（JDK8）

**要求**

- put/get 主流程
- CAS + synchronized 的组合
- 扩容为什么不阻塞全表

👉 这是 **高并发面试必杀技**

------

## 👀 理解即可（不必源码）

### 4️⃣ synchronized（JVM 层面）

- 对象头 / Monitor 概念
- 偏向锁 / 轻量级锁（知道即可）

> 不要钻 HotSpot 源码，那是性价比最低的坑

------

### 5️⃣ 原子类 & CAS

- CAS 是什么
- ABA 问题

------

## ✍️ 必须徒手复现

### 6️⃣ 线程池（ThreadPoolExecutor）

**必须能写**

- 不看资料写出构造参数含义
- 能手写一个合理的线程池配置

------

### 7️⃣ 生产者-消费者

- synchronized + wait/notify
- BlockingQueue 版本

------

------

# 二、IO / NIO（你已经走在正确路线）

## 🧠 必须源码级理解

### 1️⃣ Selector（重点）

**要求**

- select() 为什么阻塞
- selectedKeys 是怎么来的
- 为什么一个 Selector 通常一个线程

👉 不要求 OS epoll 源码，但 Java 层逻辑要清楚

------

### 2️⃣ SocketChannel.read / write

**要求**

- 返回值含义
- 半包 / 粘包
- 非阻塞模式行为

------

## 👀 理解即可

### 3️⃣ AIO

- 为什么存在
- 为什么很少用
- 和 NIO 的区别

------

### 4️⃣ 零拷贝

- mmap / sendfile / transferTo
- Netty 用了哪些

------

## ✍️ 必须徒手复现

### 5️⃣ NIO Server

- Selector
- OP_ACCEPT / READ / WRITE
- 动态切换 interestOps
- 大数据分段写

👉 **你已经基本达标了**

------

# 三、Netty（这是“工程化 NIO”）

## 🧠 必须源码级理解（选重点！）

### 1️⃣ EventLoop / EventLoopGroup（最重要）

**要求**

- 一个 Channel 绑定一个 EventLoop
- EventLoop 为什么是单线程
- EventLoop 里的任务队列

👉 这就是 **JUC + Reactor 的融合**

------

### 2️⃣ Pipeline / Handler 机制

**要求**

- inbound / outbound 传播方向
- handler 是怎么串起来的
- fireXXX 调用链

------

### 3️⃣ ByteBuf（内存模型）

**要求**

- 堆内 / 直接内存
- 引用计数
- 池化思想

------

## 👀 理解即可

### 4️⃣ ChannelFuture / Promise

- 异步回调模型
- 为什么不用 CompletableFuture

------

### 5️⃣ Netty 零拷贝

- composite buffer
- FileRegion

------

## ✍️ 必须徒手复现

### 6️⃣ Netty Server（基础）

- Bootstrap
- EventLoopGroup
- Pipeline
- Handler

------

### 7️⃣ Reactor 模型（简化版）

- 单 Reactor
- 主从 Reactor

👉 不用完整 Netty，只要：

> **你能用 NIO + 线程池写一个“类 Netty”结构**

------

# 四、总结一张「硬标准表」

| 模块              | 源码级 | 理解即可 | 徒手复现 |
| ----------------- | ------ | -------- | -------- |
| AQS               | ✅      |          |          |
| ReentrantLock     | ✅      |          |          |
| ConcurrentHashMap | ✅      |          |          |
| synchronized      |        | ✅        |          |
| 线程池            |        |          | ✅        |
| Selector          | ✅      |          |          |
| AIO               |        | ✅        |          |
| NIO Server        |        |          | ✅        |
| EventLoop         | ✅      |          |          |
| Pipeline          | ✅      |          |          |
| ByteBuf           | ✅      |          |          |
| Netty Server      |        |          | ✅        |
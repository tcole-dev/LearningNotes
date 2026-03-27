# 第 1 周（Day 1–7）：JUC 核心（为 Netty 服务）

> 目标：
>  **看到 Netty 的 EventLoop / Pipeline，不懵**

------

## Day 1：并发基础 & 线程状态

- Java 线程模型
- 线程状态流转
- start vs run
- 中断机制（`interrupt`）

👉 Netty 的 EventLoop 本质是 **线程 + 事件循环**

------

## Day 2：synchronized & volatile（并发语义）

- synchronized 对象锁 / 类锁
- happens-before
- volatile 可见性 + 重排序

**关键认知**

> Netty 大量使用 volatile + CAS，而不是 synchronized

------

## Day 3：Lock & Condition

- ReentrantLock
- 公平 / 非公平
- Condition 替代 wait/notify

👉 Netty 内部大量使用 Lock + CAS 组合

------

## Day 4：并发容器

**重点**

- ConcurrentHashMap
- BlockingQueue

👉 EventLoop 任务队列、本质就是 BlockingQueue

------

## Day 5：线程池（重中之重）

- ThreadPoolExecutor 参数
- 拒绝策略
- Executors 的坑

**你必须知道**

> Netty **不用 Executors**

------

## Day 6：CAS & 原子类

- AtomicInteger
- CAS 思想
- ABA（了解即可）

👉 Netty 几乎全靠 CAS

------

## Day 7：JUC 小总结

你此时应该能回答：

- synchronized 和 Lock 怎么选
- volatile 能干什么 / 不能干什么
- 为什么线程池是并发核心

------

# 第 2 周（Day 8–14）：IO 收尾 + JUC 高级

> 目标：
>  **IO 不再是 API，而是模型**

------

## Day 8：AQS 思想

- AQS 是什么
- state + CAS
- 独占 / 共享

不抠源码，但要**知道为什么这么设计**

------

## Day 9：同步工具类

- CountDownLatch
- CyclicBarrier
- Semaphore

👉 Netty 的连接管理、限流都用得到

------

## Day 10：Future & CompletableFuture

- 异步任务模型
- 回调 vs 链式

👉 Netty 的 Promise / Future 设计来源

------

## Day 11：Java 内存模型（JMM）

- 主内存 / 工作内存
- happens-before
- 指令重排

**重点**

> 这是理解高性能 IO 的“隐形底座”

------

## Day 12：IO 收尾（这一部分不要拖）

- BIO / NIO / AIO 对比
- AIO 使用场景（了解即可）
- FileChannel / MappedByteBuffer
- 零拷贝回顾（你之前学过）

------

## Day 13：Reactor 模型（承上启下）

**必须吃透**

- 单 Reactor
- 多 Reactor
- 主从 Reactor

👉 这是 Netty 的**设计蓝图**

------

## Day 14：NIO + JUC 整合回顾

你此时应该能清楚说出：

- Selector 为什么单线程
- 业务处理为什么必须多线程
- Reactor + 线程池是怎么配合的

------

# 第 3 周（Day 15–21）：Netty（真正的主菜）

> 目标：
>  **能看懂 Netty 代码结构，能写简单服务**

------

## Day 15：Netty 快速入门

- Netty 是什么
- 为什么比原生 NIO 好用
- 核心组件：
  - EventLoop
  - Channel
  - Pipeline
  - Handler

------

## Day 16：EventLoop & 线程模型（非常重要）

- EventLoopGroup
- 一个 Channel 绑定一个 EventLoop
- 为什么避免锁

👉 这一天是 **JUC + Netty 的交汇点**

------

## Day 17：Pipeline & Handler

- 入站 / 出站
- 编码器 / 解码器
- ByteBuf（对比 ByteBuffer）

------

## Day 18：Netty 并发处理

- 业务线程池
- EventLoop 不做耗时任务
- ctx.executor()

👉 你会发现：**你之前学的 JUC 全用上了**

------

## Day 19：Netty 实战

做一个：

- Netty Echo Server
- 或简易聊天室
- 或 HTTP Server（基础）

------

## Day 20：Netty + IO 深度理解

- Netty 零拷贝
- ByteBuf 池化
- 内存泄漏风险

------

## Day 21：总复盘 & 下一步路线

你已经具备：

- NIO 原理
- JUC 并发模型
- Netty 工程实践

👉 **下一步自然衔接**

- Netty 源码
- Go 并发模型（Goroutine vs EventLoop）
- Web 安全中的并发 & IO 场景
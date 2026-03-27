## java多线程实现方式

1. 继承Thread类，重写run方法，直接创建该对象，执行start方法即可

2. 实现Runnable接口，重写run方法，将定义类的对象作为参数传入new Thread()方法（或使用匿名内部类），执行run方法

3. 实现Callable接口，重写call方法，同样将Callable接口对象作为参数传入一个未来任务类构造方法，再将任务类对象传入Thread构造方法，再调用start方法。

   <font color='red'>Callable接口实现多线程的优点是可以返回一个值，因为call方法的返回值为Object，run方法则是void。</font>

   <font color='skyBule'>缺点则是实现复杂，且通过get方法获取线程返回值时会堵塞当前线程，类似join方法</font>

   ```java
   public class ThreadTest15 {
       public static void main(String[] args) throws Exception {
   
           // 第一步：创建一个“未来任务类”对象。
           // 参数非常重要，需要给一个Callable接口实现类对象。
           FutureTask task = new FutureTask(new Callable() {
               @Override
               public Object call() throws Exception { // call()方法就相当于run方法。只不过这个有返回值
                   // 线程执行一个任务，执行之后可能会有一个执行结果
                   // 模拟执行
                   System.out.println("call method begin");
                   Thread.sleep(1000 * 10);
                   System.out.println("call method end!");
                   int a = 100;
                   int b = 200;
                   return a + b; //自动装箱(300结果变成Integer)
               }
           });
   
           // 创建线程对象
           Thread t = new Thread(task);
   
           // 启动线程
           t.start();
   
           // 这里是main方法，这是在主线程中。
           // 在主线程中，怎么获取t线程的返回结果？
           // get()方法的执行会导致“当前线程阻塞”
           Object obj = task.get();
           System.out.println("线程执行结果:" + obj);
   
           // main方法这里的程序要想执行必须等待get()方法的结束
           // 而get()方法可能需要很久。因为get()方法是为了拿另一个线程的执行结果
           // 另一个线程执行是需要时间的。
           System.out.println("hello world!");
       }
   }
   ```

   

## java线程状态

<img src="C:\Users\t'c\Desktop\Markdowns\img\javaThreadModel.png" style="zoom:80%;" /> 

线程的生命周期：

**新建状态**->**就绪状态**（start方法执行，争抢时间片）->**运行状态** -> **阻塞状态**（IO、BLOCKED、WAITING、TIME_WAITING）-> **死亡状态**

阻塞状态的不同情况：IO（读写操作等）；BLOCKED（等待synchronized释放锁）；WAITING（线程调用`Object.wait()`、`Thread.join()` 或 `LockSupport.park()`，等待被唤醒）；TIME_WAITING（与WAITING类似，但设置有超时时间）

### 并发相关方法

#### sleep方法

sleep，属于Thread，让线程直接睡眠，不释放锁，到达超时时间和interrupt时打断。也正因为不释放锁，可以直接恢复到Runnable，抢占CPU时间片。

线程状态轮转为 Runnable -> TIME_WAITING -> Runnable

#### wait方法

属于Object类，作用为：释放当前线程对指定对象持有的锁，并进入`WAIT`状态，直到调用`notify`、`notifyAll`方法主动唤醒。

wait会释放锁，所以唤醒后，会进入BLOCKED状态，先抢回原本持有的锁，再进入Runnable，即使是抛出异常，也要在抢回锁之后

<font color='red'>注意：wait和sleep都可以被interrupt方法打断，因此，在调用这两者时，均可用try-catch捕获InterruptedException异常，捕获异常后，中断标志位会回到false。</font>

#### interrupt方法

中断线程的方法，实际上是修改JVM管理的一个线程中断标志位interrupt status，并不是直接kill线程，而是修改status为true。

线程对中断的反应取决于它当时在做什么：

**A. 阻塞状态（Waiting/Timed_Waiting）**

如果线程正在执行 `sleep()`, `wait()`, 或 `join()` 等方法，这些方法会**敏锐地感知**到中断。

- **反应**：立即抛出 `InterruptedException`。
- **副作用**：抛出异常后，**中断标志位会被清除**（变回 `false`）。

**B. 运行状态（Runnable）**

如果线程正在执行循环或计算，它不会理会中断。

- **反应**：无反应。
- **正确做法**：必须在循环中手动检查 `Thread.currentThread().isInterrupted()`。

#### notify & notifyAll方法

`notify`和`notifyAll`为唤醒WAIT状态线程的方法，notify随机唤醒当前正在等待该对象的锁的`一个`线程，`notifyAll`则是唤醒全部等待队列中的线程。

<font color='red'>注意：wait、notify、notifyAll方法都是调用lock（synchronized加锁的对象）的方法，所以必须要在synchronized同步代码块中调用，否则会因为未持有锁报错。</font>

#### join方法

`Thread.join()`，堵塞调用该方法的线程，直到被调用join方法的Thread对象（某一个线程）执行完毕。

```java
// 此时阻塞的是当前线程，而不是t1，join是等待t1执行完毕
t1.join()
```



#### yield方法

`Thread.yield()`，暂停当前线程，回到就绪状态，将时间片交给其他线程，不交出锁，只交时间片，仅仅是暂缓运行。

## synchronized & volatile

### 并发三大特性

**并发中需要注意三大特性：原子性、可见性、有序性**

- 原子性：原子性是指一个操作或者一系列操作要么全部执行成功，要么全部不执行，不会出现部分执行的情况。

  在并发环境下，要么完整执行，要么完全不执行，中间状态对其他线程不可见，关键点只有两个：**不可分割**，**中间状态不可见**。

  这意味着一个原子操作不会被其他线程中断，而这可以通过加锁的方式实现。

- 可见性：可见性是指**当一个线程修改了一个共享变量的值时，其他线程能够立即看到这个修改。**在多线程环境下，由于编译器优化、处理器缓存等原因，一个线程对变量的修改可能不会立即被其他线程感知。

- 有序性：有序性是指程序中代码的执行顺序按照代码的书写顺序执行。在多线程环境下，由于指令重排序等原因，代码的执行顺序可能与书写顺序不一致。

  ```
  int x = 0;
  int y = 1;
  int z = x + y;
  
  在没有同步机制的情况下，编译器或处理器可能会对这些指令进行重排序，比如先执行 int y = 1; 和 int z = x + y;，然后再执行 int x = 0;。在单线程环境下，这种重排序不会影响程序的结果，但在多线程环境下，可能会导致错误的结果。
  ```

### 锁升级

java中锁的状态有四种：无锁、偏向锁、轻量级锁、重量级锁

| 锁类型       | 竞争情况              | 是否阻塞  | 是否用 Monitor | 典型成本            |
| ------------ | --------------------- | --------- | -------------- | ------------------- |
| **偏向锁**   | 无竞争 / 只有一个线程 | ❌ 不阻塞  | ❌              | 几乎为 0            |
| **轻量级锁** | 少量竞争              | ❌（自旋） | ❌              | CAS + 自旋          |
| **重量级锁** | 激烈竞争              | ✅ 阻塞    | ✅              | 内核态 + 上下文切换 |

#### 偏向锁

某些时候，程序运行中绝大数时候都只有某一个线程访问对象，根本没有并发，此时为了节省每次加锁的成本，会添加偏向锁。

**工作机制：** 当一个线程进入时，JVM会记录线程ID，在`对象头`中标记为偏向锁，并记录线程ID。当下一次线程再次进入时，校验两次线程ID是否相同，若相同则直接放行即可，不相同，则进行偏向锁的重偏向或撤销并加轻量级锁。

#### **轻量级锁**

偏向锁的锁信息存放在Mark Word中，而轻量级锁则在Mark Word中存放锁状态、指向`Lock Record`的指针。

**工作机制：** 在升级轻量级锁时，会创建一个`Lock Record`对象，存放了锁的信息，而Mark Word中则保存指向它的指针。加锁时，会在线程栈创建Lock Record，并将Mark Word指向Lock Record，若成功，则获取锁；若失败，则说明有竞争，会开始自旋，即不断判断锁是否释放，直到获取锁，所以说轻量级锁并不阻塞。

**轻量级锁实现同步：** 轻量级锁的同步体现在每次获取锁时，只能有一个线程通过CAS原子性操作获取到锁，CAS是CPU保证的原子指令，确保只有一个线程能获取锁。当两个线程竞争锁时，第一个线程率先将Mark Word指向了自己的Lock Record，第二个线程判断此时的Mark Word不是无锁的期望值（偏向锁撤销后即变为无锁状态），则自旋等待。

#### 重量级锁

重量级锁的Mark Word指向Monitor对象，重量级锁（synchronized）依靠Monitor实现。重量级锁的具体实现和工作原理在 [synchronized部分](###synchronized)讲述。

#### 锁升级过程

1. 新建对象（无锁），线程进入synchronized时设置偏向锁，偏向线程ID为当前线程ID

2. 另一个线程访问此类对象（偏向锁）。若偏向线程即为当前线程，直接进入（快路径）。

   若偏向线程ID不符，但没有直接竞争（上一个线程已经退出），则进行重偏向，将偏向线程ID修改为当前线程ID。

   若两个线程同时竞争，则触发锁撤销，升级为轻量级锁。				 （这两行为慢路径）

   <font color='red'>epoch批量撤销、重偏向：偏向锁的应用场景是某一个类的对象几乎不会真正并发，所以当某个类的对象经常被其他线程进入，则需要将所有该类的对象的偏向锁全部进行重偏向。</font>

   <font color='red'>epoch相当于一个版本号，用于批量重偏向。每次进行批量重偏向和锁撤销（一个类的对象长期被多个线程交替访问，由JVM判定进行批量重定向或锁撤销，）时，全局epoch会加一（全局epoch是JVM维护的`类级别`的偏向锁版本号），而每个对象的epoch数值即小于全局epoch，此时判定为偏向锁信息过期，下次访问时，会进行重偏向或撤销，并将对象的epoch修改为全局epoch。</font>

3. 升级轻量级锁时，会创建`Lock Record`对象，将Mark Word指向Lock Record对象，若成功，则获取锁；若失败（多个线程竞争），则进行自旋，持续判断是否释放锁。

4. 当竞争加剧（**1. 多线程CAS频繁失败；2. 自旋次数超过阈值；3. 持锁线程长时间不释放锁**）时，轻量级锁会升级为重量级锁。Mark Word指向创建的Monitor对象，每次只有一个线程能够持有Monitor。

注意：锁的触发、升级都是建立在使用synchronized上，也就是说，synchronized并不是直接使用重量级锁，而是一步一步升级。JDK15+后，偏向锁使用已经默认关闭，因为偏向锁的收益已经不足以抵消其性能的浪费、维护的复杂。现在的锁升级，起步就是轻量级锁，利用CAS + 自旋实现加锁。

### synchronized

synchronized在并发中解决的问题是`可见性`、`原子性`。由于保证了同一时刻只有一个线程执行代码块，而 JMM 保证了在单线程内指令重排不会影响最终执行结果（as-if-serial 语义），即`有序性`。

- synchronized若修饰方法，则锁住的是整个对象
- synchronized若修饰代码块，则必须通过指定锁住的对象，线程执行代码块时，必须取得对应对象的锁

**synchronized 底层原理**

synchronized 的代码块是由一组 monitorenter/monitorexit 指令实现的。而`Monitor` 对象是实现同步的基本单元。

- Monitor对象

  **简述**

  任何对象都关联了一个管程，管程就是控制对象并发访问的一种机制。管程 是一种同步原语，在 Java 中指的就是 synchronized，可以理解为 synchronized 就是 Java 中对管程的实现。

  管程提供了一种排他访问机制，这种机制也就是 互斥。互斥保证了在每个时间点上，最多只有一个线程会执行同步方法。

  所以 Monitor 对象其实就是使用管程控制同步访问的一种对象。
  注意：只有使用重量级锁时，才会使用 Monitor 对象，偏向锁和轻量级锁依靠对象头的Mark Word。Monitor可以简单理解为synchronized代码块中的“锁”，每个线程都必须持有对象的“锁”，才能访问和执行代码块。

  **Monitor对象的整体结构**

  ```css
  ObjectMonitor
  ├─ Owner        （当前持锁线程）
  ├─ EntryList    （阻塞等待获取锁的线程）
  ├─ WaitSet      （调用 wait() 的线程）
  ├─ Recursions   （重入次数）
  └─ Monitor 数据（与对象头 Mark Word 关联）
  ```

  - **EnryList** 等待获取锁的线程，线程状态是`BLOCKED`，这里的线程是有资格获取锁，并在等待的线程。

  - **WaitSet** 调用wait后等待唤醒的线程，这里的线程是虽然在等待锁，但没有资格获取锁的线程，必须等待主动调用notify、notifyAll唤醒其中的线程，唤醒后进入EntryList等待获取锁。

  - **Recursions** 用于支持

    ```java
    synchronized(obj) {
        synchronized(obj) {
            synchronized(obj) {
                ...
            }
        }
    }
    ```

    只有当重入次数归零，才算是锁完全释放。

### volatile

`volatile`和`synchronized`对比，synchronized实现了原子性、可见性、有序性，而volatile则实现了**可见性**、**有序性**。

可见性：常规变量修改后，不会立刻同步会主线程，其他线程读取时，很有可能读取到旧值，而 volatile 变量能够立刻刷回主线程，其他线程可以马上看到修改后的值。

有序性：比如`instance = new Singleton();`不是原子性操作，需要 `1. 分配内存空间 (Memory allocate)`  `2. 初始化对象 (Init)` `3. 将变量 instance 指向分配的内存地址 (Assign)`，编译器和CPU为了提高执行效率，顺序可能不一定是 1，2，3。而volatile防止重排序，实现多线程下的`有序性`。

重排序的三个层次：

1. `编译器优化重排序`：Java 编译器（JIT）在不改变单线程语义的前提下，调整字节码顺序。
2. `指令级并行重排序`：CPU 发现指令之间没有数据依赖，会重叠执行多条指令。
3. `内存系统重排序`：由于 CPU 缓存的存在，导致读写操作看起来像是乱序的。

**实现原理：**

<font color='blue'>**JMM内存模型方面：**</font>

Java 内存模型（JMM）规定，所有变量都存储在**主内存**中，而每个线程有自己的**工作内存**（类似于 CPU 缓存）。

- **常规变量：** 线程修改变量后，并不会立即同步回主内存；其他线程读取时，可能直接从自己的工作内存读旧值。
- **Volatile 变量：** JMM 会强制执行以下规则：
  1. **写操作：** 当线程修改 `volatile` 变量时，JMM 会立即将该线程工作内存中的值刷新到主内存。
  2. **读操作：** 当线程读取 `volatile` 变量时，JMM 会强制该线程从主内存中获取最新值，而不是从缓存读。

<font color='blue'>**硬件层面：Lock 前缀指令与缓存一致性**</font>

在底层硬件（x86 架构）中，编译器在生成字节码并最终转化为机器码时，会在 `volatile` 变量的写操作前加上一个 **Lock 前缀指令**。这个指令会触发以下机制：

**内存屏障（Memory Barriers）**

编译器会插入指令级别的“屏障”，防止指令重排序，并确保数据流向。内存屏障是一组 **CPU 指令**，用于解决两个核心问题：**防止指令重排序** 和 **强制刷出缓存**。

- **写屏障（Store Barrier）：** 确保在屏障之前的写操作全部刷新到主内存。
- **读屏障（Load Barrier）：** 确保屏障之后的读操作都去主内存抓取。

Java 内存模型（JMM）将内存屏障抽象为四种，通过组合这些屏障，可以确保不同类型的操作顺序。

| **屏障类型**   | **指令组合**                 | **作用**                                                     |
| -------------- | ---------------------------- | ------------------------------------------------------------ |
| **LoadLoad**   | `Load1; LoadLoad; Load2`     | 确保 Load1 的数据装载先于 Load2 及后续所有读操作。           |
| **StoreStore** | `Store1; StoreStore; Store2` | 确保 Store1 的数据对其他处理器可见（刷新到内存）先于 Store2。 |
| **LoadStore**  | `Load1; LoadStore; Store2`   | 确保 Load1 数据装载先于 Store2 的写操作。                    |
| **StoreLoad**  | `Store1; StoreLoad; Load2`   | **全能屏障**。确保 Store1 刷新到内存先于 Load2。开销最大。   |

**MESI 缓存一致性协议**

Lock 前缀指令会开启 CPU 的 **缓存一致性机制**（Cache Coherence）：

1. **失效通知：** 当 CPU 1 修改了某个缓存行的数据，它会通知其他 CPU 核心，告知它们缓存中对应的数据已失效。
2. **嗅探机制：** 每个处理器通过嗅探（Sniffing）在总线上传播的数据来检查自己的缓存是否过期。如果发现自己缓存的地址被修改，就会将其标记为“失效”状态，下次使用时重新从内存加载。

### synchronized与volatile的选用

**volatile 的正确使用:** 当某个变量在多线程环境下被**频繁读取且不需要复杂的同步操作**时，可以使用 `volatile` 关键字。
**synchronized 和 Lock 的选择:** 在需要对共享资源进行**原子操作且需要控制访问顺序**时，使用 `synchronized` 或 `Lock`。

## Lock & Condition

### 简述

如果把 Java 的并发编程比作一场“武器演化史”，那么 `synchronized` 就是冷兵器时代的快刀，而 **JUC (java.util.concurrent)** 则是工业时代的自动武器，其中 **Lock & Condition** 便是这套武器系统的核心引擎。

#### **实现机制对比**

- **synchronized**: 是 Java 的**关键字**，属于 JVM 层面的“内置锁”。它由底层 C++ 实现，通过对象头中的 Mark Word 来记录锁状态。

- **Lock & Condition**: 是 **JUC 包**下的 **接口**。它们是纯 Java 实现的工具类，核心依赖于 **AQS (AbstractQueuedSynchronizer)** 框架。

#### **控制粒度与灵活性对比**

| **特性**     | **synchronized**                       | **Lock & Condition**                           |
| ------------ | -------------------------------------- | ---------------------------------------------- |
| **锁的获取** | 隐式（进入代码块自动获取）             | 显式（需手动调用 `lock()`）                    |
| **锁的释放** | 自动（代码执行完或异常后自动释放）     | **手动**（必须在 `finally` 中执行 `unlock()`） |
| **公平性**   | 只支持非公平锁                         | 支持**公平锁**与非公平锁                       |
| **响应中断** | 不支持（死等）                         | 支持 `lockInterruptibly()`，可中途放弃         |
| **等待协作** | 一个锁关联一个等待队列 (`wait/notify`) | 一个 Lock 可关联**多个** `Condition` 队列      |

#### Lock

Lock的本质是**`可编程的互斥访问控制器（互斥锁）`**。在早期的 Java 中，我们常用 `synchronized` 关键字，但灵活度有限。而 `Lock` 接口（如 `ReentrantLock`）提供了更灵活的操作。

```java
Lock lock = new ReentrantLock();

lock.lock();
try {
    // 临界区
} finally {
    lock.unlock();
}
```

 **Lock 相比 synchronized 的本质升级**

| 能力          | synchronized | Lock          |
| ------------- | ------------ | ------------- |
| 显式加锁/解锁 | ❌            | ✅             |
| 尝试加锁      | ❌            | ✅ `tryLock()` |
| 可中断        | ❌            | ✅             |
| 公平锁        | ❌            | ✅             |
| 多条件        | ❌            | ✅             |

#### Condition

`Condition` 必须配合 `Lock` 使用。它的核心作用是让线程在满足特定条件之前**等待**，并在条件达成时被**唤醒**。可理解为`Condition `是“从 Lock 中拆出来的**`条件等待队列`**”。一个 `Lock` 可以创建多个 `Condition`。

```java
Condition cond = lock.newCondition();
cond.await();
```

**核心方法对比：**

如果你以前用过 `Object.wait()` 和 `notify()`，那么 Condition 就是它们的升级版：

| **传统方法 (Object)** | **现代方法 (Condition)** | **作用**                         |
| --------------------- | ------------------------ | -------------------------------- |
| `wait()`              | `await()`                | 线程挂起，释放锁，进入等待区     |
| `notify()`            | `signal()`               | 随机唤醒一个在该条件上等待的线程 |
| `notifyAll()`         | `signalAll()`            | 唤醒所有在该条件上等待的线程     |

#### Condition和Lock的关系

```
Lock（互斥）
 ├── Condition A（条件队列）
 ├── Condition B
 └── Condition C
```

👉 **锁是“谁能进”**
 👉 **Condition 是“什么时候进”**



### 解决的问题和优点

**早期synchronized + wait/notify 的结构**

```java
synchronized (lock) {
    while (!条件) {
        lock.wait();
    }
}
```

这里面其实**隐含了三种角色**，但都被塞进了一个对象里：

1. **互斥锁**
2. **条件队列**
3. **唤醒机制**

> ❌ 所有线程都挤在 **同一个 Wait Set** 里

------

**一个致命问题：只有一个条件队列**

以生产者 / 消费者为例：

- 仓库满 → 生产者等
- 仓库空 → 消费者等

但 `wait/notify` 只有一个等待队列：	 生产者 + 消费者 → 同一个 Wait Set

结果只能：							notifyAll(); // 暴力唤醒所有线程（所有消费者、生产者）

这正是 `Lock & Condition` 要解决的核心痛点。

### ReentrantLock 

ReentrantLock 是 `Lock & Condition` 体系中，`Lock` 接口最典型、最核心的实现。`Lock` 是规范（接口），`ReentrantLock` 是基于 AQS 的具体实现。

<font color='red'>详细介绍文档： [CSDN Java并发基石ReentrantLock：深入解读其原理与实现](https://blog.csdn.net/qq_26664043/article/details/136789346?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522441189215599bea662538a9ab2b22ae9%2522%252C%2522scm%2522%253A%252220140713.130102334..%2522%257D&request_id=441189215599bea662538a9ab2b22ae9&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~top_positive~default-1-136789346-null-null.142^v102^control&utm_term=ReentrantLock&spm=1018.2226.3001.4187)</font>

**ReentrantLock的核心特性**

- 可重入性：ReentrantLock的一个主要特点是它的名字所表示的含义——“可重入”。简单来说，如果一个线程已经持有了某个锁，那么它可以再次调用lock()方法而不会被阻塞。这在某些需要递归锁定的场景中非常有用。锁的持有计数会在每次成功调用lock()方法时递增，并在每次unlock()方法被调用时递减。
- 公平性：与内置的synchronized关键字不同，ReentrantLock提供了一个公平锁的**`选项`**。公平锁会按照线程请求锁的顺序来分配锁，而不是像非公平锁那样允许线程抢占已经等待的线程的锁。公平锁可以减少“饥饿”的情况，但也可能降低一些性能。
- 可中断性：ReentrantLock的获取锁操作（lockInterruptibly()方法）可以被中断。这提供了另一个相对于synchronized关键字的优势，因为synchronized不支持响应中断。
- 条件变量：ReentrantLock类中还包含一个Condition接口的实现，该接口允许线程在某些条件下等待或唤醒。这提供了一种比使用wait()和notify()更灵活和更安全的线程通信方式。

**<font color='red'>公平锁 & 非公平锁</font>**

公平锁即线程按照先来后到的顺序获取锁，使用队列，每次只有队列头能够获取锁。

非公平锁允许所有线程同时进行CAS，最先完成全部指令的线程获取锁，即允许线程插队。

<font color='red'>注意：无论使用的是公平还是非公平锁，**`无参的tryLock()方法`**都是非公平的</font>

**公平 vs 非公平，对比总结**

| 维度         | 公平锁   | 非公平锁               |
| ------------ | -------- | ---------------------- |
| 是否按顺序   | ✅ 是     | ❌ 否                   |
| 是否允许插队 | ❌ 不允许 | ✅ 允许                 |
| 是否可能饥饿 | ❌ 否     | ✅ 可能                 |
| 吞吐量       | 较低     | 较高                   |
| 默认选择     | 很少     | **大多数并发框架默认** |

<font color='red'>**可中断性**</font>

在synchronized中，`等锁`（synchronized() 竞争锁）时，不可中断，只能持续堵塞；而`等待条件`（调用`wait`方法）时，可以通过`interrupt()`中断

ReentrantLock中，`等锁`、`等待条件`时均可中断，等锁（/竞争锁）时用`lockInterruptibly()`代替`lock()`后即可在等锁时中断（`lock()`方法也不能中断）。

**ReentrantLock 的“完整可中断矩阵”（非常重要）**

| 场景           | 方法                  | 是否可中断 |
| -------------- | --------------------- | ---------- |
| 等锁           | `lock()`              | ❌          |
| 等锁           | `lockInterruptibly()` | ✅          |
| 尝试锁         | `tryLock()`           | 不阻塞     |
| 尝试锁（超时） | `tryLock(time)`       | ✅          |
| 等条件         | `await()`             | ✅          |
| 等条件（超时） | `awaitNanos()`        | ✅          |

尝试锁`tryLock()`不堵塞：表示若不能获取锁会立刻返回，不存在需要中断的情况。

<font color='red'>ReentrantLock 基础实现</font>

```java
public class ReentrantLock implements Lock, java.io.Serializable {
    // 默认使用非公平锁
    private final Sync nonfairSync;
    // 公平锁
    private final Sync fairSync;
    // 抽象队列同步器，实际是nonfairSync或fairSync
    private final Sync sync;

    // 构造函数，默认非公平锁
    public ReentrantLock() {
        sync = nonfairSync = new NonfairSync();
    }

    // 构造函数，可指定公平性
    public ReentrantLock(boolean fair) {
        sync = fair ? new FairSync() : new NonfairSync();
    }

    // 实现Lock接口的lock方法
    public void lock() {
        sync.lock();
    }

    // ... 其他方法，如tryLock, unlock等

    // 抽象队列同步器的实现
    abstract static class Sync extends AbstractQueuedSynchronizer {
        // ...

        // 是否处于占用状态
        final boolean isHeldExclusively() {
            return getState() == 1;
        }

        // 尝试获取锁
        final boolean tryAcquire(int acquires) {
            // ... 省略具体实现
        }

        // 释放锁
        protected final boolean tryRelease(int releases) {
            // ... 省略具体实现
        }

        // ... 其他方法
    }

    // 非公平锁实现
    static final class NonfairSync extends Sync {
        // ...

        // 锁获取
        final void lock() {
            // ... 省略具体实现
        }

        // ... 其他方法
    }

    // 公平锁实现
    static final class FairSync extends Sync {
        // ...

        // 锁获取，考虑公平性
        final void lock() {
            // ... 省略具体实现
        }

        // ... 其他方法
    }
}
```


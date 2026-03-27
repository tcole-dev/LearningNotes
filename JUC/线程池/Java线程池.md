# Java 线程池

## 前言：为什么学习线程池

### 问题背景：手动创建线程的弊端

```java
// 每个任务都创建新线程的问题
for (int i = 0; i < 10000; i++) {
    new Thread(() -> {
        // 执行任务
    }).start();
}
```

**存在的问题**：
1. **资源消耗大**：每个线程需要约1MB栈空间，10000个线程约10GB内存
2. **创建开销**：线程创建涉及系统调用，耗时约1-2ms
3. **系统不稳定**：线程过多导致CPU频繁切换，系统响应变慢甚至崩溃
4. **无法复用**：线程用完即销毁，无法重复利用

### 线程池的解决方案

```
线程池 = 线程复用 + 任务队列 + 统一管理
```

| 对比项 | 手动创建线程 | 线程池 |
|--------|-------------|--------|
| 线程数量 | 不可控，可能无限增长 | 可控，有上限 |
| 线程复用 | 无法复用 | 复用已有线程 |
| 资源消耗 | 高（频繁创建销毁） | 低（线程复用） |
| 响应速度 | 慢（需要创建线程） | 快（线程已就绪） |
| 任务管理 | 无 | 队列缓冲、拒绝策略 |

---

## 第一阶段：线程池架构全景

### 1.1 线程池整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        ThreadPoolExecutor                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    任务提交层                             │    │
│  │  execute(Runnable)  /  submit(Callable<T>)              │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           ▼                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    核心控制层                             │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ ctl 变量    │  │ 状态管理    │  │ 线程计数    │      │    │
│  │  │ (状态+数量) │  │ (RUNNING等) │  │ (workerCount)│      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           ▼                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    线程管理层                             │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │              workers (HashSet<Worker>)           │    │    │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐            │    │    │
│  │  │  │ Worker1 │ │ Worker2 │ │ WorkerN │  ...       │    │    │
│  │  │  │ Thread  │ │ Thread  │ │ Thread  │            │    │    │
│  │  │  └─────────┘ └─────────┘ └─────────┘            │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           ▼                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    任务存储层                             │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │           workQueue (BlockingQueue)              │    │    │
│  │  │  Task1 → Task2 → Task3 → Task4 → ...             │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    辅助组件层                             │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐     │    │
│  │  │ ThreadFactory│ │ RejectedExec │ │  mainLock    │     │    │
│  │  │  线程工厂     │ │  拒绝策略    │ │  主锁        │     │    │
│  │  └──────────────┘ └──────────────┘ └──────────────┘     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 核心组件职责

| 组件 | 类型 | 职责 |
|------|------|------|
| ctl | AtomicInteger | 高3位存储线程池状态，低29位存储工作线程数量 |
| workers | HashSet\<Worker\> | 存储所有工作线程 |
| workQueue | BlockingQueue\<Runnable\> | 任务队列，存储待执行任务 |
| mainLock | ReentrantLock | 保护workers集合的并发访问 |
| threadFactory | ThreadFactory | 创建新线程的工厂 |
| handler | RejectedExecutionHandler | 拒绝策略处理器 |

### 1.3 类继承体系

```
                    Executor (接口)
                        │
                        ▼
                 ExecutorService (接口)
                        │
                        ▼
             AbstractExecutorService (抽象类)
                        │
                        ▼
              ThreadPoolExecutor (核心实现类)
                        │
            ┌───────────┴───────────┐
            ▼                       ▼
    ScheduledThreadPoolExecutor   ForkJoinPool
```

**各接口/类职责**：

```java
// Executor：最基础的执行接口
public interface Executor {
    void execute(Runnable command);
}

// ExecutorService：扩展了生命周期管理和任务提交能力
public interface ExecutorService extends Executor {
    void shutdown();                           // 平滑关闭
    List<Runnable> shutdownNow();              // 立即关闭
    boolean isShutdown();                      // 是否已关闭
    boolean isTerminated();                    // 是否已终止
    <T> Future<T> submit(Callable<T> task);    // 提交有返回值的任务
    <T> List<Future<T>> invokeAll(...);        // 批量执行
}
```

---

## 第二阶段：线程池创建与参数详解

### 2.1 创建线程池的方式

#### 方式一：使用 ThreadPoolExecutor 直接创建（推荐）

```java
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    5,                      // corePoolSize
    10,                     // maximumPoolSize
    60L,                    // keepAliveTime
    TimeUnit.SECONDS,       // unit
    new ArrayBlockingQueue<>(100),  // workQueue
    Executors.defaultThreadFactory(), // threadFactory
    new ThreadPoolExecutor.AbortPolicy() // handler
);
```

#### 方式二：使用 Executors 工厂方法（不推荐生产使用）

```java
// 固定大小线程池
ExecutorService fixedPool = Executors.newFixedThreadPool(5);

// 可缓存线程池
ExecutorService cachedPool = Executors.newCachedThreadPool();

// 单线程线程池
ExecutorService singlePool = Executors.newSingleThreadExecutor();

// 定时任务线程池
ScheduledExecutorService scheduledPool = Executors.newScheduledThreadPool(5);
```

**为什么不推荐使用 Executors？**

```java
// newFixedThreadPool 和 newSingleThreadExecutor
// 队列容量为 Integer.MAX_VALUE，可能导致 OOM
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads,
        0L, TimeUnit.MILLISECONDS,
        new LinkedBlockingQueue<Runnable>()); // 无界队列！
}

// newCachedThreadPool
// 最大线程数为 Integer.MAX_VALUE，可能创建大量线程导致 OOM
public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
        60L, TimeUnit.SECONDS,
        new SynchronousQueue<Runnable>());
}
```

### 2.2 七大核心参数详解

```java
public ThreadPoolExecutor(
    int corePoolSize,                       // 参数1：核心线程数
    int maximumPoolSize,                    // 参数2：最大线程数
    long keepAliveTime,                     // 参数3：空闲线程存活时间
    TimeUnit unit,                          // 参数4：时间单位
    BlockingQueue<Runnable> workQueue,      // 参数5：任务队列
    ThreadFactory threadFactory,            // 参数6：线程工厂
    RejectedExecutionHandler handler        // 参数7：拒绝策略
)
```

#### 参数1：corePoolSize（核心线程数）

```
核心线程的特点：
├── 创建后长期存在（除非设置了 allowCoreThreadTimeOut=true）
├── 即使空闲也不会被回收
├── 优先创建，任务到来时首先尝试创建核心线程
└── 数量 <= maximumPoolSize
```

**配置建议**：
- CPU密集型：CPU核心数 + 1
- IO密集型：CPU核心数 × 2
- 混合型：根据任务比例调整

#### 参数2：maximumPoolSize（最大线程数）

```
最大线程数 = 核心线程 + 临时线程

临时线程的特点：
├── 仅在核心线程已满且队列已满时创建
├── 空闲超过 keepAliveTime 后会被回收
└── 用于应对任务突发增长
```

#### 参数3 & 4：keepAliveTime + TimeUnit（空闲存活时间）

```java
// 临时线程空闲存活时间
keepAliveTime = 60;
unit = TimeUnit.SECONDS;
// 表示：临时线程空闲60秒后会被回收

// 让核心线程也参与超时回收
executor.allowCoreThreadTimeOut(true);
```

#### 参数5：workQueue（任务队列）

| 队列类型 | 容量 | 特点 | 使用场景 |
|----------|------|------|----------|
| ArrayBlockingQueue | 固定 | 有界阻塞队列，公平锁 | 任务量可控，防止OOM |
| LinkedBlockingQueue | 可变 | 无界时可能OOM | 任务量较小 |
| SynchronousQueue | 0 | 不存储，直接传递 | 高吞吐，每个任务都需要新线程 |
| PriorityBlockingQueue | 无界 | 优先级排序 | 任务有优先级 |

**队列选择对线程池行为的影响**：

```java
// 队列容量 = 0（SynchronousQueue）
// 任务直接交给线程，无队列缓冲
// 当前线程不足则创建新线程，到达最大值则拒绝

// 队列容量有限（ArrayBlockingQueue）
// 核心线程满 → 入队 → 队列满 → 创建临时线程 → 最大线程满 → 拒绝

// 队列容量无限（LinkedBlockingQueue无参）
// 核心线程满 → 入队（永远不满）→ 永远不创建临时线程
// 可能导致任务无限堆积，OOM
```

#### 参数6：ThreadFactory（线程工厂）

```java
// 默认线程工厂
ThreadFactory defaultFactory = Executors.defaultThreadFactory();

// 自定义线程工厂（推荐）
ThreadFactory customFactory = new ThreadFactory() {
    private final AtomicInteger threadNumber = new AtomicInteger(1);
    
    @Override
    public Thread newThread(Runnable r) {
        Thread t = new Thread(r, "my-pool-thread-" + threadNumber.getAndIncrement());
        t.setDaemon(false);    // 非守护线程
        t.setPriority(Thread.NORM_PRIORITY);
        return t;
    }
};

// 使用 Guava 的 ThreadFactoryBuilder
ThreadFactory factory = new ThreadFactoryBuilder()
    .setNameFormat("my-pool-%d")
    .setDaemon(true)
    .setPriority(Thread.NORM_PRIORITY)
    .setUncaughtExceptionHandler((t, e) -> log.error("异常", e))
    .build();
```

#### 参数7：RejectedExecutionHandler（拒绝策略）

| 策略类 | 行为 | 源码 | 适用场景 |
|--------|------|------|----------|
| AbortPolicy | 抛异常 | `throw new RejectedExecutionException()` | 需要感知被拒绝的任务 |
| CallerRunsPolicy | 调用者执行 | `r.run()` | 不希望任务丢失，可接受降速 |
| DiscardPolicy | 静默丢弃 | 空 | 允许任务丢失 |
| DiscardOldestPolicy | 丢弃最老 | `queue.poll(); execute(r)` | 希望保留新任务 |

---

## 第三阶段：线程池执行流程深度解析

### 3.1 任务提交流程（execute方法）

```
                              提交任务 execute(task)
                                        │
                                        ▼
                            ┌───────────────────────┐
                            │  当前工作线程数 < 核心数? │
                            └───────────┬───────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │ 是                           │ 否
                    ▼                              ▼
         ┌─────────────────────┐        ┌─────────────────────┐
         │ addWorker(task, true)│        │  尝试将任务加入队列  │
         │ 创建核心线程执行任务  │        └───────────┬─────────┘
         └─────────────────────┘                    │
                                    ┌───────────────┼───────────────┐
                                    │ 入队成功                      │ 入队失败
                                    ▼                              ▼
                         ┌─────────────────────┐      ┌─────────────────────┐
                         │  检查线程池状态，    │      │ addWorker(task, false)│
                         │  如果已关闭则回滚    │      │ 创建临时线程执行任务   │
                         └─────────────────────┘      └───────────┬─────────┘
                                    │                              │
                                    │                      ┌───────┴───────┐
                                    │                      │ 创建成功       │ 创建失败
                                    │                      ▼               ▼
                                    │              ┌────────────┐ ┌────────────┐
                                    │              │ 任务被执行  │ │ 执行拒绝策略 │
                                    │              └────────────┘ └────────────┘
                                    ▼
                         ┌─────────────────────┐
                         │ 检查是否需要启动线程 │
                         │ (队列有任务但无线程) │
                         │ addWorker(null, true)│
                         └─────────────────────┘
```

### 3.2 execute() 源码解析

```java
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    
    // 获取 ctl 值（包含线程池状态和工作线程数）
    int c = ctl.get();
    
    // 【步骤1】如果工作线程数 < 核心线程数，创建核心线程
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();  // 创建失败，重新获取状态
    }
    
    // 【步骤2】核心线程已满，尝试加入队列
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        // 双重检查：如果线程池已关闭（shutdown、shutdownNow），则回滚（移除任务并拒绝）
        if (!isRunning(recheck) && remove(command))
            reject(command);
        // 如果没有工作线程，启动一个（确保队列中的任务能被执行）
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
        /**
        	1. 第一个if中，若线程池为RUNNING，则会进入第二个if，此时没有回滚，确实需要一个线程，但若此时前面的线程全部突然暴				毙，则需要补一个线程
        	2. 第一个if中，若确实线程池突然被关闭（除了RUNNING的所有状态），但remove失败（成功逃逸进入队列），但前面的其他			 线程已经没了，也需要加一个线程（若是shutdownNow，则交给addWorker判断）。
        	综上，这里的addWorker不是为了让线程池能够处理剩下的任务，只是为了这一个任务能够被处理而已。
        */
        
        
        
    }
    // 【步骤3】队列已满，尝试创建临时线程
    else if (!addWorker(command, false))
        // 【步骤4】创建失败（已达最大线程数），执行拒绝策略
        reject(command);
}
```

### 3.3 线程创建流程（addWorker方法）

```java
private boolean addWorker(Runnable firstTask, boolean core) {
    // firstTask: 线程创建后要执行的第一个任务（可为null）
    // core: true表示核心线程，false表示临时线程
    
    // 【阶段1】CAS循环检查线程池状态和工作线程数量
    retry:
    for (;;) {
        int c = ctl.get();
        int rs = runStateOf(c);
        
        // 检查线程池是否已关闭
        if (rs >= SHUTDOWN &&
            !(rs == SHUTDOWN && firstTask == null && !workQueue.isEmpty()))
            return false;
        
        for (;;) {
            int wc = workerCountOf(c);
            // 检查是否超过线程数上限
            if (wc >= CAPACITY ||
                wc >= (core ? corePoolSize : maximumPoolSize))
                return false;
            // CAS增加工作线程计数
            if (compareAndIncrementWorkerCount(c))
                break retry;
            c = ctl.get();
            if (runStateOf(c) != rs)
                continue retry;
        }
    }
    
    // 【阶段2】创建Worker并启动线程
    boolean workerStarted = false;
    boolean workerAdded = false;
    Worker w = null;
    try {
        w = new Worker(firstTask);  // 创建Worker，内部创建Thread
        final Thread t = w.thread;
        if (t != null) {
            final ReentrantLock mainLock = this.mainLock;
            mainLock.lock();
            try {
                // 再次检查线程池状态
                int rs = runStateOf(ctl.get());
                if (rs < SHUTDOWN ||
                    (rs == SHUTDOWN && firstTask == null)) {
                    if (t.isAlive())
                        throw new IllegalThreadStateException();
                    workers.add(w);  // 加入工作线程集合
                    workerAdded = true;
                }
            } finally {
                mainLock.unlock();
            }
            if (workerAdded) {
                t.start();  // 启动线程
                workerStarted = true;
            }
        }
    } finally {
        if (!workerStarted)
            addWorkerFailed(w);  // 失败处理
    }
    return workerStarted;
}
```

### 3.4 Worker 工作线程解析

```java
private final class Worker
        extends AbstractQueuedSynchronizer
        implements Runnable {
    
    /** 工作线程 */
    final Thread thread;
    /** 初始任务（可能为null） */
    Runnable firstTask;
    /** 已完成的任务数 */
    volatile long completedTasks;
    
    Worker(Runnable firstTask) {
        // 设置 AQS 状态为 -1，防止在运行前被中断
        setState(-1);
        this.firstTask = firstTask;
        // 通过线程工厂创建线程，Worker 自己就是 Runnable
        this.thread = getThreadFactory().newThread(this);
    }
    
    @Override
    public void run() {
        runWorker(this);  // 核心执行方法
    }
    
    // AQS 相关方法（简化版）
    protected boolean isHeldExclusively() {
        return getState() != 0;
    }
    
    protected boolean tryAcquire(int unused) {
        if (compareAndSetState(0, 1)) {
            setExclusiveOwnerThread(Thread.currentThread());
            return true;
        }
        return false;
    }
    
    protected boolean tryRelease(int unused) {
        setExclusiveOwnerThread(null);
        setState(0);
        return true;
    }
    
    public void lock()        { acquire(1); }
    public boolean tryLock()  { return tryAcquire(1); }
    public void unlock()      { release(1); }
    public boolean isLocked() { return isHeldExclusively(); }
}
```

**为什么 Worker 继承 AQS？**

```
Worker 继承 AQS 的目的：
├── 1. 实现独占锁，保护任务执行过程
├── 2. 控制中断时机：只有持有锁的线程才能被中断
├── 3. 防止在任务执行过程中被意外中断
└── 4. shutdown 时，只会中断空闲线程（未持有锁的线程）
```

### 3.5 任务执行流程（runWorker方法）

```java
final void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    Runnable task = w.firstTask;
    w.firstTask = null;
    w.unlock();  // 释放锁（创建时 state = -1，允许中断）
    boolean completedAbruptly = true;
    try {
        // 【循环获取任务并执行】
        // task != null: 执行初始任务
        // task == null: 从队列获取任务
        while (task != null || (task = getTask()) != null) {
            // 在线程池架构中，主线程终止工作线程必须加锁才能interrupt。只有空闲时间时，主线程获取锁后，获得的interrupt才是给主线程发布给工作线程的；否则是业务代码所用的，如ReentrantLock的lock方法。
            w.lock();  // 加锁，防止执行中被中断
            
            // 如果线程池正在停止，确保线程被中断
            // 用代数的方式： if( (A || B ) && C )
            // A：runStateAtLeast(ctl.get(), STOP) 判断此时此刻的线程池是STOP，不再执行任务
            // B：( Thread.interrupted() && runStateAtLeast(ctl.get(), STOP) ) 条件A通过，若中断标志位为true，那就要检查是业务代码手贱调用了interrupt又没有进行处理，还是确实是在刚刚那一刻被修改成了STOP，若ctl也被修改了，也不再执行任务
            // C：!wt.isInterrupted() A || B的条件通过，那么再用中断标志位确认。
            // C中：若A条件通过，!wt.isInterrupted()必然是false，那也不用执行了，直接跳过；若B条件通过，那!wt.isInterrupted()就必然为true，而中断标识符已经被清空了，那么就执行wt.interrupt()补一个中断标识符。
            // 总结！！！
            // 这一条if语句的作用是：判断是否是主线程发出的命令，要求中断线程，还是业务代码发出的。是前者可以不管，后者必须处理（清理掉中断标识符），否则会影响该工作线程执行。
            // 这里虽然判断了是否需要中断，但不进行处理，中断标识符1. 留给业务代码判断；2. 给下一轮的getTask判断是否退出（若要退出，返回null）
            if ((runStateAtLeast(ctl.get(), STOP) ||
                 (Thread.interrupted() &&
                  runStateAtLeast(ctl.get(), STOP))) &&
                !wt.isInterrupted())
                wt.interrupt();
            
            try {
                // 扩展点：任务执行前（钩子方法）
                beforeExecute(wt, task);
                Throwable thrown = null;
                try {
                    task.run();  // 执行任务！
                } catch (RuntimeException x) {
                    thrown = x; throw x;
                } catch (Error x) {
                    thrown = x; throw x;
                } catch (Throwable x) {
                    thrown = x; throw new Error(x);
                } finally {
                    // 扩展点：任务执行后（）
                    afterExecute(task, thrown);
                }
            } finally {
                task = null;
                w.completedTasks++;  // 完成任务数+1
                w.unlock();  // 解锁
            }
        }
        completedAbruptly = false;
    } finally {
        // 线程退出处理
        processWorkerExit(w, completedAbruptly);
    }
}
```

### 3.6 获取任务流程（getTask方法）

```java
private Runnable getTask() {
    boolean timedOut = false;  // 上次获取任务是否超时
    
    for (;;) {
        int c = ctl.get();
        int rs = runStateOf(c);
        
        // 检查线程池状态，两种状态不能获取任务：1. SHUTDOWN状态，任务队列为空 2. STOP状态，即使有任务也不能获取
        if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
            decrementWorkerCount();
            return null;  // 返回null，线程将退出
        }
        
        int wc = workerCountOf(c);
        
        // 是否需要超时获取⭐⭐⭐
        // allowCoreThreadTimeOut=true 或 当前线程数 > 核心线程数
        // 线程池中，核心线程默认不超时，非核心线程一定超时。但，线程池的核心线程和非核心线程只是一个概念，并没有实际计数器统计前n个线程为核心线程之类的。是否超时执行是每次手动判断的
        // allowCoreThreadTimeOut 允许核心线程超时    wc > corePoolSize  当前线程数是否超过核心线程数（是否为非核心线程）
        // 若允许核心线程超时，那无论是否是核心线程，本轮都是允许超时的；若核心线程不超时，判断条件B，若当前线程非核心线程，那么即允许超时，否则为核心线程，A为false，即不允许超时。
        boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;
        
        // 是否需要回收当前线程⭐⭐⭐
        // (超时获取失败 且 需要超时) 且 (线程数 > 1 或 队列为空)
        // if( ( A || B) && ( C || D ) )
        // A || B：是否该死
        	// A：wc > maximumPoolSize --- 动态调整了线程池大小，导致线程数量大于线程池上限
        	// B：timed && timedOut ------ 该线程上次就已经超时，意思是该线程已经空闲了很久了
        // C || D：是否能死
        	// C：wc > 1 ----------------- 线程池中至少有两个线程，不至于一个线程都没有
        	// D：workQueue.isEmpty() ---- 任务队列中没有任务，此时可以不留线程
        if ((wc > maximumPoolSize || (timed && timedOut))
            && (wc > 1 || workQueue.isEmpty())) {
            if (compareAndDecrementWorkerCount(c))
                return null;  // 返回null，线程将退出
            continue;
        }
        
        try {
            // 从队列获取任务
            Runnable r = timed ?
                workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :  // 超时获取
                workQueue.take();  // 阻塞获取
            if (r != null)
                return r;
            timedOut = true;  // 超时，可能需要回收
        } catch (InterruptedException retry) {
            timedOut = false;  // 被中断，重试
        }
    }
}
```

**线程回收机制**：

```
线程回收流程：
├── 1. getTask() 从队列获取任务
├── 2. 如果是临时线程，使用 poll(keepAliveTime) 超时获取
├── 3. 超时返回 null，getTask() 返回 null
├── 4. runWorker() 退出循环
├── 5. processWorkerExit() 处理线程退出
└── 6. 线程结束，被GC回收
```

---

## 第四阶段：线程池生命周期管理

### 4.1 线程池状态

```java
// 线程池状态（存储在 ctl 的高3位）
RUNNING    = -1 << 29  // 111: 接受新任务，处理队列任务
SHUTDOWN   =  0 << 29  // 000: 不接受新任务，但处理队列任务
STOP       =  1 << 29  // 001: 不接受新任务，不处理队列任务，中断正在执行的任务
TIDYING    =  2 << 29  // 010: 所有任务已终止，workerCount为0
TERMINATED =  3 << 29  // 011: terminated()方法完成
```

### 4.2 状态流转图

```
                ┌─────────────────────────────────────┐
                │             RUNNING                  │
                │  接受新任务，处理队列任务              │
                └──────────────┬──────────────────────┘
                               │ shutdown()
                               ▼
                ┌─────────────────────────────────────┐
                │            SHUTDOWN                  │
                │  不接受新任务，处理队列任务            │
                │  中断空闲线程                         │
                └──────────────┬──────────────────────┘
                               │ 队列为空且工作线程数为0
                               ▼
                ┌─────────────────────────────────────┐
                │             TIDYING                  │
                │  调用 terminated() 钩子方法           │
                └──────────────┬──────────────────────┘
                               │ terminated() 执行完毕
                               ▼
                ┌─────────────────────────────────────┐
                │           TERMINATED                 │
                │  终止状态                            │
                └─────────────────────────────────────┘
                
                RUNNING 也可以直接通过 shutdownNow() 到 STOP
                               │
                               ▼
                ┌─────────────────────────────────────┐
                │              STOP                    │
                │  不接受新任务，不处理队列任务          │
                │  中断所有线程                         │
                └──────────────┬──────────────────────┘
                               │ 工作线程数为0
                               ▼
                            TIDYING
```

### 4.3 关闭线程池

#### shutdown() - 平滑关闭

```java
public void shutdown() {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        checkShutdownAccess();
        advanceRunState(SHUTDOWN);  // 状态改为 SHUTDOWN
        interruptIdleWorkers();     // 中断空闲线程
    } finally {
        mainLock.unlock();
    }
    tryTerminate();  // 尝试终止
}

// 中断空闲线程
private void interruptIdleWorkers() {
    interruptIdleWorkers(false);
}

private void interruptIdleWorkers(boolean onlyOne) {
    for (Worker w : workers) {
        Thread t = w.thread;
        if (!t.isInterrupted() && w.tryLock()) {
            // tryLock() 成功说明线程空闲（没有在执行任务）
            try {
                t.interrupt();
            } catch (SecurityException ignore) {
            }
        }
        if (onlyOne)
            break;
    }
}
```

#### shutdownNow() - 立即关闭

```java
public List<Runnable> shutdownNow() {
    List<Runnable> tasks;
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        checkShutdownAccess();
        advanceRunState(STOP);       // 状态改为 STOP
        interruptWorkers();          // 中断所有线程
        tasks = drainQueue();        // 取出队列中的任务
    } finally {
        mainLock.unlock();
    }
    tryTerminate();
    return tasks;  // 返回未执行的任务
}
```

#### 对比

| 方法 | shutdown() | shutdownNow() |
|------|------------|---------------|
| 状态 | SHUTDOWN | STOP |
| 新任务 | 拒绝 | 拒绝 |
| 队列任务 | 继续执行 | 取消 |
| 正在执行任务 | 继续执行 | 中断 |
| 空闲线程 | 中断 | 中断 |
| 返回值 | void | List\<Runnable\> |

### 4.4 优雅关闭实践

```java
public void gracefulShutdown(ExecutorService executor, int timeout) {
    // 第一步：停止接收新任务
    executor.shutdown();
    try {
        // 第二步：等待队列任务执行完成
        if (!executor.awaitTermination(timeout, TimeUnit.SECONDS)) {
            // 第三步：超时后强制关闭
            executor.shutdownNow();
            // 第四步：等待正在执行的任务响应中断
            if (!executor.awaitTermination(timeout, TimeUnit.SECONDS)) {
                System.err.println("线程池未完全关闭");
            }
        }
    } catch (InterruptedException e) {
        executor.shutdownNow();
        Thread.currentThread().interrupt();
    }
}
```

---

## 第五阶段：线程池扩展与监控

### 5.1 线程池扩展点

```java
public class CustomThreadPoolExecutor extends ThreadPoolExecutor {
    
    public CustomThreadPoolExecutor(int corePoolSize, int maximumPoolSize,
            long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue) {
        super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue);
    }
    
    @Override
    protected void beforeExecute(Thread t, Runnable r) {
        // 任务执行前的钩子方法
        System.out.println("任务开始执行: " + r);
        super.beforeExecute(t, r);
    }
    
    @Override
    protected void afterExecute(Runnable r, Throwable t) {
        // 任务执行后的钩子方法
        super.afterExecute(r, t);
        if (t != null) {
            System.err.println("任务执行异常: " + t.getMessage());
        }
        System.out.println("任务执行完成: " + r);
    }
    
    @Override
    protected void terminated() {
        // 线程池终止时的钩子方法
        System.out.println("线程池已终止");
        super.terminated();
    }
}
```

### 5.2 线程池监控指标

```java
public class ThreadPoolMonitor {
    
    public static void printThreadPoolStatus(ThreadPoolExecutor executor) {
        System.out.println("========== 线程池状态 ==========");
        System.out.println("核心线程数: " + executor.getCorePoolSize());
        System.out.println("最大线程数: " + executor.getMaximumPoolSize());
        System.out.println("当前线程数: " + executor.getPoolSize());
        System.out.println("活跃线程数: " + executor.getActiveCount());
        System.out.println("历史最大线程数: " + executor.getLargestPoolSize());
        System.out.println("已完成任务数: " + executor.getCompletedTaskCount());
        System.out.println("队列大小: " + executor.getQueue().size());
        System.out.println("队列剩余容量: " + executor.getQueue().remainingCapacity());
        System.out.println("是否关闭: " + executor.isShutdown());
        System.out.println("是否终止: " + executor.isTerminated());
    }
    
    // 定时监控线程
    public static void startMonitor(ThreadPoolExecutor executor, long period) {
        ScheduledExecutorService monitor = Executors.newSingleThreadScheduledExecutor();
        monitor.scheduleAtFixedRate(() -> {
            printThreadPoolStatus(executor);
        }, 0, period, TimeUnit.SECONDS);
    }
}
```

### 5.3 自定义拒绝策略

```java
// 记录日志后丢弃
public class LogAndDiscardPolicy implements RejectedExecutionHandler {
    private static final Logger logger = LoggerFactory.getLogger(LogAndDiscardPolicy.class);
    
    @Override
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        logger.warn("任务被拒绝，线程池状态: active={}, pool={}, queue={}, completed={}",
            e.getActiveCount(), e.getPoolSize(), e.getQueue().size(), e.getCompletedTaskCount());
    }
}

// 持久化到数据库
public class PersistToDbPolicy implements RejectedExecutionHandler {
    @Override
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        if (r instanceof FutureTask) {
            // 提取任务信息，保存到数据库，稍后重试
            saveToDatabase(r);
        }
    }
}

// 重试策略
public class RetryPolicy implements RejectedExecutionHandler {
    private final int maxRetries;
    
    public RetryPolicy(int maxRetries) {
        this.maxRetries = maxRetries;
    }
    
    @Override
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        for (int i = 0; i < maxRetries; i++) {
            try {
                Thread.sleep(1000);  // 等待1秒
                e.execute(r);        // 重试
                return;
            } catch (Exception ex) {
                // 继续重试
            }
        }
        throw new RejectedExecutionException("任务重试" + maxRetries + "次后仍被拒绝");
    }
}
```

---

## 第六阶段：实战应用

### 6.1 不同场景的线程池配置

#### 场景1：Web服务器请求处理

```java
// 特点：IO密集型，任务量大，需要快速响应
ThreadPoolExecutor webServerPool = new ThreadPoolExecutor(
    200,                        // corePoolSize: 较多的核心线程
    400,                        // maximumPoolSize: 应对突发流量
    60L, TimeUnit.SECONDS,      // 临时线程存活时间
    new LinkedBlockingQueue<>(1000),  // 有界队列
    new ThreadFactoryBuilder()
        .setNameFormat("web-request-%d")
        .setUncaughtExceptionHandler((t, e) -> log.error("异常", e))
        .build(),
    new ThreadPoolExecutor.CallerRunsPolicy()  // 拒绝时由调用者执行
);
```

#### 场景2：批处理任务

```java
// 特点：CPU密集型，任务量固定，需要高吞吐
ThreadPoolExecutor batchPool = new ThreadPoolExecutor(
    Runtime.getRuntime().availableProcessors() + 1,  // 核心数+1
    Runtime.getRuntime().availableProcessors() + 1,  // 固定大小
    0L, TimeUnit.MILLISECONDS,  // 不回收
    new ArrayBlockingQueue<>(100),
    new ThreadPoolExecutor.AbortPolicy()  // 拒绝时抛异常，便于感知
);
```

#### 场景3：定时任务

```java
// 使用 ScheduledThreadPoolExecutor
ScheduledThreadPoolExecutor scheduledPool = new ScheduledThreadPoolExecutor(
    5,
    new ThreadFactoryBuilder().setNameFormat("scheduled-%d").build()
);

// 延迟执行
scheduledPool.schedule(() -> System.out.println("延迟1秒执行"), 1, TimeUnit.SECONDS);

// 固定延迟执行（任务完成后延迟fixedDelay再执行）
scheduledPool.scheduleWithFixedDelay(() -> {
    System.out.println("执行任务");
}, 0, 5, TimeUnit.SECONDS);

// 固定频率执行（不管任务是否完成，每隔period执行）
scheduledPool.scheduleAtFixedRate(() -> {
    System.out.println("执行任务");
}, 0, 5, TimeUnit.SECONDS);
```

### 6.2 Spring 集成

```java
@Configuration
@EnableAsync
public class ThreadPoolConfig {
    
    @Bean("taskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(10);
        executor.setMaxPoolSize(20);
        executor.setQueueCapacity(200);
        executor.setKeepAliveSeconds(60);
        executor.setThreadNamePrefix("async-task-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.setWaitForTasksToCompleteOnShutdown(true);  // 关闭时等待任务完成
        executor.setAwaitTerminationSeconds(60);             // 最多等待60秒
        executor.initialize();
        return executor;
    }
}

// 使用
@Service
public class UserService {
    
    @Async("taskExecutor")
    public CompletableFuture<User> getUserAsync(Long id) {
        User user = userRepository.findById(id);
        return CompletableFuture.completedFuture(user);
    }
}
```

### 6.3 常见问题与解决方案

#### 问题1：线程池参数配置不当

```java
// 错误：核心线程数太少，队列太大
// 结果：任务堆积在队列，响应缓慢
new ThreadPoolExecutor(2, 10, 60, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(10000));

// 正确：根据实际负载调整
new ThreadPoolExecutor(20, 50, 60, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(500));
```

#### 问题2：任务执行异常丢失

```java
// 问题：execute() 提交的任务异常会被吞掉
executor.execute(() -> {
    throw new RuntimeException("异常");  // 异常被吞掉
});

// 解决方案1：使用 submit() 并获取 Future
Future<?> future = executor.submit(() -> {
    throw new RuntimeException("异常");
});
try {
    future.get();  // 会抛出 ExecutionException
} catch (ExecutionException e) {
    log.error("任务执行异常", e.getCause());
}

// 解决方案2：设置 UncaughtExceptionHandler
ThreadFactory factory = r -> {
    Thread t = new Thread(r);
    t.setUncaughtExceptionHandler((thread, ex) -> log.error("异常", ex));
    return t;
};
```

#### 问题3：线程泄漏

```java
// 问题：ThreadLocal 未清理，导致内存泄漏
executor.execute(() -> {
    threadLocal.set(new BigObject());
    // ... 业务逻辑
    // 忘记 remove，线程复用时对象无法释放
});

// 解决：使用 try-finally 清理
executor.execute(() -> {
    try {
        threadLocal.set(new BigObject());
        // ... 业务逻辑
    } finally {
        threadLocal.remove();  // 清理
    }
});
```

---

## 学习路线总结

### 知识点优先级

```
必须掌握 ⭐⭐⭐⭐⭐
├── 七大核心参数含义
├── execute() 执行流程
├── 四种拒绝策略
├── 任务队列选择
└── 线程池状态流转

深入理解 ⭐⭐⭐⭐
├── ctl 变量设计
├── Worker 继承 AQS 的原因
├── getTask() 线程回收机制
├── addWorker() 创建流程
└── shutdown/shutdownNow 区别

进阶掌握 ⭐⭐⭐
├── 三个扩展点方法
├── 自定义线程工厂
├── 自定义拒绝策略
├── 线程池监控
└── Spring 集成
```

### 学习路径

```
第1周：基础概念 + API使用
├── 理解为什么需要线程池
├── 学习 ThreadPoolExecutor 构造方法
├── 掌握七大参数含义
└── 编写简单示例

第2-3周：核心原理
├── 画出 execute() 执行流程图
├── 理解四种拒绝策略
├── 学习四种队列特点
└── 理解线程池状态流转

第4-5周：源码阅读
├── 阅读 ctl 变量实现
├── 跟踪 execute() 源码
├── 分析 addWorker() 方法
├── 研究 runWorker() 方法
└── 理解 getTask() 线程回收

第6-7周：实战应用
├── 不同场景的参数配置
├── 自定义线程工厂和拒绝策略
├── 线程池监控实现
└── Spring 集成实践

持续：深入与优化
├── 分析生产环境问题
├── 性能调优实践
└── 与其他并发组件配合使用
```

### 核心记忆点

```
线程池执行流程（背诵）
├── 核心线程未满 → 创建核心线程
├── 核心线程已满 → 入队
├── 队列已满 → 创建临时线程
└── 最大线程已满 → 拒绝

线程回收条件
├── allowCoreThreadTimeOut = true → 核心线程可回收
└── 当前线程数 > 核心线程数 → 临时线程可回收

队列选择口诀
├── 任务量可控 → ArrayBlockingQueue
├── 任务量小 → LinkedBlockingQueue
├── 高吞吐 → SynchronousQueue
└── 有优先级 → PriorityBlockingQueue
```
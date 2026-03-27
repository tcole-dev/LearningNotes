# addWorker() 方法详解

## 一、方法签名

```java
private boolean addWorker(Runnable firstTask, boolean core)
```

**参数说明：**
| 参数 | 类型 | 说明 |
|------|------|------|
| firstTask | Runnable | 新工作线程的首个任务，可为 null |
| core | boolean | true=核心线程，false=非核心线程 |

**返回值：**
- `true`：工作线程创建并启动成功
- `false`：创建失败

---

## 二、方法整体结构

`addWorker` 方法分为两大阶段：

```
┌─────────────────────────────────────────────────────────┐
│                    addWorker 方法                        │
├─────────────────────────────────────────────────────────┤
│  第一阶段：CAS 循环检查 + 增加线程计数                     │
│    - 检查线程池状态                                       │
│    - 检查线程数量限制                                     │
│    - CAS 增加工作线程计数                                 │
├─────────────────────────────────────────────────────────┤
│  第二阶段：创建 Worker 对象并启动线程                      │
│    - 创建 Worker 实例                                    │
│    - 加锁将 Worker 加入 workers 集合                      │
│    - 启动线程执行任务                                     │
│    - 失败回滚处理                                        │
└─────────────────────────────────────────────────────────┘
```

---

## 三、第一阶段：CAS 循环检查

### 源码分析（带详细注释）

```java
// ==================== 第一阶段：CAS 循环检查 + 增加线程计数 ====================

retry:                              // 定义标签 retry，用于控制嵌套循环的跳转
for (int c = ctl.get();;) {         // 获取当前 ctl 值，开始外层无限循环
    
    // ------------------------- 外层循环：线程池状态检查 -------------------------
    // 目的：判断当前线程池状态是否允许创建新线程
    
    // 条件1：runStateAtLeast(c, SHUTDOWN)
    //       判断线程池状态是否 >= SHUTDOWN（即 SHUTDOWN/STOP/TIDYING/TERMINATED）
    // 只有状态 >= SHUTDOWN 时，才需要进一步检查下面三个条件
    //
    // 条件2（三选一，任一为 true 则拒绝）：
    //   - runStateAtLeast(c, STOP)：状态 >= STOP，线程池不接受任何任务，不创建线程（STOP下将中断线程，回收资源）
    //   - firstTask != null：有新任务要执行，但 SHUTDOWN 状态不接受新任务
    //   - workQueue.isEmpty()：队列为空，没有任务需要处理，无需创建线程
    //
    // 总结：以下情况返回 false，拒绝创建线程：
    //   1. 线程池状态 >= STOP（正在终止）
    //   2. SHUTDOWN 状态 + 有新任务（不接受新任务）
    //   3. SHUTDOWN 状态 + 队列为空（无任务可处理）
    // 特例：SHUTDOWN 状态 + 无新任务 + 队列非空 → 允许创建线程处理队列任务
    if (runStateAtLeast(c, SHUTDOWN)
        && (runStateAtLeast(c, STOP)
            || firstTask != null
            || workQueue.isEmpty()))
        return false;               // 线程池状态不允许创建线程，直接返回失败

    // ------------------------- 内层循环：线程数量检查 + CAS 增加计数 -------------------------
    for (;;) {
        
        // 步骤1：检查线程数量是否已达上限
        // core 参数决定比较的上限：
        //   - core = true：与 corePoolSize 比较（核心线程数上限）
        //   - core = false：与 maximumPoolSize 比较（最大线程数上限）
        // COUNT_MASK = (1 << 29) - 1，用于掩码操作，确保值在 29 位范围内
        if (workerCountOf(c)
            >= ((core ? corePoolSize : maximumPoolSize) & COUNT_MASK))
            return false;           // 线程数量已达上限，返回失败
        
        // 步骤2：CAS 原子操作增加工作线程计数
        // compareAndIncrementWorkerCount(c)：期望值为 c，新值为 c+1
        // 这是一个原子操作，返回 true 表示成功，false 表示失败（并发冲突）
        if (compareAndIncrementWorkerCount(c))
            break retry;            // CAS 成功，跳出外层循环，进入第二阶段
        
        // 步骤3：CAS 失败后的处理
        c = ctl.get();              // 重新读取 ctl 值（可能已被其他线程修改）
        
        // 步骤4：检查线程池状态是否发生变化
        if (runStateAtLeast(c, SHUTDOWN))
            continue retry;         // 状态变为 SHUTDOWN 或更差，跳到外层循环重新检查
        
        // 步骤5：状态未变，只是 workerCount 变了（其他线程创建了线程）
        // 继续内层循环，重新尝试 CAS 操作
        // else CAS failed due to workerCount change; retry inner loop
    }
}
```

### 流程图

```
                    ┌─────────────────────┐
                    │ c = ctl.get()       │
                    └──────────┬──────────┘
                               │
                               ▼
              ┌────────────────────────────────┐
              │ runStateAtLeast(c, SHUTDOWN)?  │
              │ 线程池状态 >= SHUTDOWN ?         │
              └───────────────┬────────────────┘
                              │ 是
                              ▼
         ┌────────────────────────────────────────┐
         │ 以下任一条件为 true 则返回 false：       │
         │  1. runStateAtLeast(c, STOP)           │
         │     状态 >= STOP（正在终止）             │
         │  2. firstTask != null                  │
         │     有新任务但线程池已关闭               │
         │  3. workQueue.isEmpty()                │
         │     队列为空，无需处理任务               │
         └────────────────┬───────────────────────┘
                          │ 满足任一条件
                          ▼
                    return false
                              │ 不满足
                              ▼
              ┌────────────────────────────────┐
              │ 检查线程数量限制                 │
              │ core ? corePoolSize : maxPool   │
              └───────────────┬────────────────┘
                              │
                              ▼
         ┌────────────────────────────────────────┐
         │ workerCountOf(c) >= 限制数 ?           │
         └───────────────┬────────────────────────┘
                         │ 是
                         ▼
                   return false
                         │ 否
                         ▼
         ┌────────────────────────────────────────┐
         │ compareAndIncrementWorkerCount(c)      │
         │ CAS 增加工作线程计数                    │
         └───────────────┬────────────────────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
         CAS 成功               CAS 失败
              │                     │
              ▼                     ▼
        break retry         c = ctl.get() 重读
        跳出外层循环               │
                              ┌────┴────┐
                              │         │
                     状态 >= SHUTDOWN  状态正常
                              │         │
                              ▼         ▼
                        continue    继续内层循环
                          retry
```

### 关键点解析

#### 1. retry 标签的使用

```java
retry:
for (;;) {
    // 外层循环
    for (;;) {
        // 内层循环
        break retry;    // 跳出外层循环
        continue retry; // 继续外层循环
    }
}
```

`retry` 是一个标签，用于控制嵌套循环的跳转：
- `break retry`：直接跳出外层循环，进入第二阶段
- `continue retry`：重新开始外层循环，重新检查线程池状态

#### 2. 线程池状态检查逻辑

```java
if (runStateAtLeast(c, SHUTDOWN)
    && (runStateAtLeast(c, STOP)
        || firstTask != null
        || workQueue.isEmpty()))
    return false;
```

**表格解析：**

| 线程池状态 | firstTask | workQueue | 结果 | 原因 |
|-----------|-----------|-----------|------|------|
| >= STOP | 任意 | 任意 | false | 线程池正在终止，不接受新任务 |
| SHUTDOWN | != null | 任意 | false | SHUTDOWN 状态不接受新任务 |
| SHUTDOWN | null | 空 | false | 无任务需处理 |
| SHUTDOWN | null | 非空 | 继续执行 | 允许创建线程处理队列任务 |
| RUNNING | 任意 | 任意 | 继续执行 | 正常运行状态 |

**设计意图：**
- SHUTDOWN 状态：不再接受新任务，但会处理队列中剩余任务
- STOP 状态：立即终止，不处理任何任务

#### 3. 线程数量限制检查

```java
if (workerCountOf(c)
    >= ((core ? corePoolSize : maximumPoolSize) & COUNT_MASK))
    return false;
```

根据 `core` 参数决定比较对象：
- `core = true`：与 `corePoolSize` 比较
- `core = false`：与 `maximumPoolSize` 比较

`& COUNT_MASK` 确保值不超过 29 位限制。

#### 4. CAS 增加线程计数

```java
if (compareAndIncrementWorkerCount(c))
    break retry;
c = ctl.get();  // Re-read ctl
if (runStateAtLeast(c, SHUTDOWN))
    continue retry;
```

**CAS 失败的两种情况：**
1. **线程数量变化**：其他线程已修改 workerCount
   - 重新读取 ctl，继续内层循环
2. **线程池状态变化**：线程池进入 SHUTDOWN 或更差状态
   - 跳到外层循环重新检查状态

---

## 四、第二阶段：创建 Worker 并启动

### 源码分析（带详细注释）

```java
// ==================== 第二阶段：创建 Worker 对象并启动线程 ====================

// ------------------------- 初始化状态变量 -------------------------
boolean workerStarted = false;      // 标记工作线程是否启动成功
boolean workerAdded = false;        // 标记 Worker 是否成功加入 workers 集合
Worker w = null;                    // Worker 对象引用，finally 块中需要使用

try {
    // ------------------------- 步骤1：创建 Worker 对象 -------------------------
    // Worker 构造函数内部会：
    //   1. setState(-1)：设置 AQS 状态为 -1，禁止中断直到 runWorker
    //   2. 保存 firstTask 作为首个任务
    //   3. 通过 ThreadFactory 创建新线程，线程的 target 就是 Worker 本身
    w = new Worker(firstTask);
    
    // 获取 Worker 内部持有的线程对象
    // Worker 构造时：this.thread = getThreadFactory().newThread(this);
    final Thread t = w.thread;
    
    // ------------------------- 步骤2：检查线程创建是否成功 -------------------------
    if (t != null) {                // ThreadFactory 可能返回 null（创建失败）
        
        // ------------------------- 步骤3：获取全局锁 -------------------------
        // mainLock 是线程池的主锁，用于保护 workers 集合和相关状态
        // 因为 workers 是 HashSet，非线程安全，需要加锁保护
        final ReentrantLock mainLock = this.mainLock;
        mainLock.lock();            // 加锁，确保下面操作的原子性
        
        try {
            // ------------------------- 步骤4：加锁后的双重检查 -------------------------
            // 再次检查线程池状态，因为获取锁之前状态可能已改变
            // 这是经典的 Double-Check 模式，确保状态一致性
            int c = ctl.get();      // 重新获取 ctl 值

            // 判断是否允许添加 Worker：
            // 条件1：isRunning(c)
            //        线程池处于 RUNNING 状态，正常情况
            // 条件2：runStateLessThan(c, STOP) && firstTask == null
            //        线程池状态 < STOP（即 SHUTDOWN 状态）且没有新任务
            //        这种情况允许创建线程来处理队列中的剩余任务
            if (isRunning(c) ||
                (runStateLessThan(c, STOP) && firstTask == null)) {
                
                // ------------------------- 步骤5：检查线程状态 -------------------------
                // 确保线程尚未启动（状态为 NEW）
                // 防止恶意的 ThreadFactory 返回已启动的线程
                if (t.getState() != Thread.State.NEW)
                    throw new IllegalThreadStateException();  // 线程状态异常，抛出异常
                
                // ------------------------- 步骤6：将 Worker 加入集合 -------------------------
                // workers 是一个 HashSet<Worker>，存储所有工作线程
                workers.add(w);
                
                // 标记添加成功
                workerAdded = true;
                
                // ------------------------- 步骤7：更新最大线程数统计 -------------------------
                // largestPoolSize 记录线程池历史最大线程数，用于监控和统计
                int s = workers.size();
                if (s > largestPoolSize)
                    largestPoolSize = s;  // 更新历史最大值
            }
            // 如果状态检查不通过，workerAdded 保持 false
            // 线程不会被启动，但 Worker 对象已创建
            
        } finally {
            // ------------------------- 步骤8：释放锁 -------------------------
            // 无论成功与否，都要释放锁
            mainLock.unlock();
        }
        
        // ------------------------- 步骤9：启动线程 -------------------------
        // 注意：启动线程在锁外进行，避免锁持有时间过长
        if (workerAdded) {          // 只有成功添加到集合才启动
            t.start();              // 启动线程，线程会执行 Worker.run() → runWorker()
            workerStarted = true;   // 标记启动成功
        }
        // 如果 workerAdded = false，说明状态检查未通过，线程未启动
    }
    // 如果 t == null，ThreadFactory 创建线程失败，workerStarted 保持 false
    
} finally {
    // ------------------------- 步骤10：失败回滚处理 -------------------------
    // 如果线程启动失败（workerStarted = false），需要回滚之前的操作
    if (! workerStarted)
        addWorkerFailed(w);        // 执行失败回滚
}

// 返回最终结果
return workerStarted;               // true=成功，false=失败
```

### 流程图

```
┌─────────────────────────────────────────────────────────┐
│ workerStarted = false                                   │
│ workerAdded = false                                     │
│ w = null                                                │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ w = new Worker(firstTask) │
              │ 创建 Worker 对象       │
              └───────────┬──────────┘
                          │
                          ▼
              ┌──────────────────────┐
              │ t = w.thread         │
              │ 获取 Worker 中的线程   │
              └───────────┬──────────┘
                          │
                          ▼
              ┌──────────────────────┐
              │ t != null ?          │
              └───────────┬──────────┘
                          │ 是
                          ▼
              ┌──────────────────────┐
              │ mainLock.lock()      │
              │ 获取全局锁            │
              └───────────┬──────────┘
                          │
                          ▼
              ┌──────────────────────────────────┐
              │ 再次检查线程池状态：               │
              │ isRunning(c) ||                  │
              │ (runStateLessThan(c, STOP) &&    │
              │  firstTask == null)              │
              └───────────────┬──────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                检查通过            检查不通过
                    │                   │
                    ▼                   ▼
    ┌─────────────────────────┐   释放锁
    │ t.getState() == NEW ?   │   workerAdded = false
    │ 检查线程状态             │
    └───────────┬─────────────┘
                │ 是
                ▼
    ┌─────────────────────────┐
    │ workers.add(w)          │
    │ 加入 workers 集合        │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │ 更新 largestPoolSize    │
    │ 记录历史最大线程数       │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │ workerAdded = true      │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │ mainLock.unlock()       │
    │ 释放锁                  │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │ workerAdded ?           │
    └───────────┬─────────────┘
                │ 是
                ▼
    ┌─────────────────────────┐
    │ t.start()               │
    │ 启动线程                │
    │ workerStarted = true    │
    └─────────────────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │ return workerStarted    │
    └─────────────────────────┘

    ┌─────────────────────────────┐
    │ 若 !workerStarted：          │
    │ addWorkerFailed(w)          │
    │ 执行失败回滚                 │
    └─────────────────────────────┘
```

### 关键点解析

#### 1. Worker 类

```java
w = new Worker(firstTask);
final Thread t = w.thread;
```

**Worker 是什么？**
- Worker 是 ThreadPoolExecutor 的内部类
- 继承自 AQS，实现了 Runnable 接口
- 每个 Worker 持有一个工作线程

**Worker 构造函数：**
```java
Worker(Runnable firstTask) {
    setState(-1); // inhibit interrupts until runWorker
    this.firstTask = firstTask;
    this.thread = getThreadFactory().newThread(this);
}
```

Worker 对象本身是 Runnable，创建时通过 ThreadFactory 创建线程，线程的 target 就是 Worker 自己。

#### 2. mainLock 的作用

```java
final ReentrantLock mainLock = this.mainLock;
mainLock.lock();
```

**mainLock 保护的操作：**
- 修改 workers 集合
- 更新 largestPoolSize
- 确保线程启动时的状态一致性

**为什么需要锁？**
- workers 是 HashSet，非线程安全
- 需要原子性地完成"检查状态 → 添加 Worker → 更新统计"操作

#### 3. 加锁后的双重检查

```java
if (isRunning(c) ||
    (runStateLessThan(c, STOP) && firstTask == null)) {
    // ...
}
```

**允许添加 Worker 的情况：**
| 条件 | 说明 |
|------|------|
| `isRunning(c)` | 线程池正常运行 |
| `runStateLessThan(c, STOP) && firstTask == null` | SHUTDOWN 状态，处理队列任务 |

**不允许的情况：**
- STOP 或更差状态
- SHUTDOWN 状态但 firstTask 不为 null

#### 4. 线程状态检查

```java
if (t.getState() != Thread.State.NEW)
    throw new IllegalThreadStateException();
```

确保线程未被启动过。如果 ThreadFactory 返回了已启动的线程，抛出异常。

#### 5. 失败回滚机制

```java
finally {
    if (! workerStarted)
        addWorkerFailed(w);
}
```

`addWorkerFailed` 方法：
```java
private void addWorkerFailed(Worker w) {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        if (w != null)
            workers.remove(w);      // 从集合移除
        decrementWorkerCount();     // 减少计数
        tryTerminate();            // 尝试终止线程池
    } finally {
        mainLock.unlock();
    }
}
```

---

## 五、完整执行流程图

```
                        ┌─────────────────────┐
                        │ addWorker 被调用     │
                        └──────────┬──────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │ 第一阶段：CAS 检查与计数增加    │
                    │                              │
                    │  ┌────────────────────────┐  │
                    │  │ 外层循环：状态检查       │  │
                    │  │ - 检查 SHUTDOWN/STOP   │  │
                    │  │ - 检查队列是否为空      │  │
                    │  └────────────────────────┘  │
                    │             │                │
                    │             ▼                │
                    │  ┌────────────────────────┐  │
                    │  │ 内层循环：计数检查       │  │
                    │  │ - 检查线程数量限制      │  │
                    │  │ - CAS 增加计数         │  │
                    │  └────────────────────────┘  │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────┴───────────────┐
                    │                              │
               检查失败                        CAS 成功
                    │                              │
                    ▼                              ▼
              return false              ┌──────────────────────┐
                                        │ 第二阶段：创建启动    │
                                        │                      │
                                        │  1. new Worker()     │
                                        │  2. mainLock.lock()  │
                                        │  3. 状态二次检查      │
                                        │  4. workers.add(w)   │
                                        │  5. t.start()        │
                                        └──────────┬───────────┘
                                                   │
                                        ┌──────────┴───────────┐
                                        │                      │
                                   启动成功                启动失败
                                        │                      │
                                        ▼                      ▼
                                  return true         addWorkerFailed()
                                                       return false
```

---

## 六、总结

### addWorker 方法的核心职责

1. **前置检查**：确保线程池状态允许创建线程
2. **资源预占**：CAS 原子性地增加工作线程计数
3. **对象创建**：创建 Worker 封装线程和任务
4. **安全启动**：加锁确保线程安全地加入集合并启动
5. **失败回滚**：失败时恢复计数和集合状态

### 设计亮点

| 设计点 | 说明 |
|--------|------|
| CAS 自旋 | 无锁化操作提高并发性能 |
| retry 标签 | 灵活控制多层嵌套循环 |
| 双重检查 | 确保状态一致性 |
| mainLock 保护 | 防止竞态条件 |
| 失败回滚 | 保证系统状态正确性 |

### 与 execute 方法的关系

```
execute(command)
    │
    ├── workerCount < corePoolSize ?
    │       │
    │       └── addWorker(command, true)  // 核心线程
    │
    ├── 入队成功 && workerCount == 0 ?
    │       │
    │       └── addWorker(null, false)    // 非核心线程，处理队列
    │
    └── 入队失败 ?
            │
            └── addWorker(command, false) // 非核心线程，直接执行
```

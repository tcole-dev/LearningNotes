# ThreadPoolExecutor.execute() 方法详解

## 一、方法概述

`execute()` 是 `ThreadPoolExecutor` 提交任务的核心入口方法，负责将 `Runnable` 任务提交给线程池执行。该方法通过**三步策略**来处理任务，确保线程池的高效运行。

---

## 二、核心变量：ctl

```java
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
```

`ctl` 是线程池的核心控制变量，使用一个 `AtomicInteger` 同时存储两个信息：
- **高3位**：线程池运行状态 (runState)
- **低29位**：工作线程数量 (workerCount)

通过位运算可以快速获取和修改这两部分信息。

### 相关方法

| 方法 | 作用 |
|------|------|
| `ctl.get()` | 获取当前的 ctl 值 |
| `workerCountOf(c)` | 从 ctl 值中提取工作线程数量 |
| `runStateOf(c)` | 从 ctl 值中提取线程池运行状态 |
| `ctlOf(rs, wc)` | 将运行状态和工作线程数量合并为 ctl 值 |

---

## 三、execute 方法完整流程

```
                        ┌─────────────────┐
                        │ 提交任务 command │
                        └────────┬────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ command == null ?      │
                    └────────────┬───────────┘
                                 │ 是
                                 ▼
                        抛出 NullPointerException
                                 │ 否
                                 ▼
                    ┌────────────────────────────┐
                    │ 第一步：检查工作线程数       │
                    │ workerCount < corePoolSize? │
                    └────────────┬───────────────┘
                                 │ 是
                                 ▼
                    ┌────────────────────────────┐
                    │ addWorker(command, true)   │
                    │ 创建核心线程执行任务         │
                    └────────────┬───────────────┘
                                 │ 成功
                                 ▼
                            return（结束）
                                 │ 失败
                                 ▼
                      重新获取 ctl 值
                                 │
                                 ▼
                    ┌────────────────────────────┐
                    │ 第二步：尝试加入工作队列     │
                    │ isRunning && offer(command) │
                    └────────────┬───────────────┘
                                 │ 入队成功
                                 ▼
                    ┌────────────────────────────┐
                    │ 双重检查线程池状态           │
                    │ recheck = ctl.get()         │
                    └────────────┬───────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            线程池已停止                线程池仍运行
                    │                         │
                    ▼                         ▼
        ┌───────────────────┐      ┌─────────────────────┐
        │ remove(command)   │      │ workerCount == 0 ?  │
        │ 移除任务           │      │ 确保有工作线程       │
        └─────────┬─────────┘      └──────────┬──────────┘
                  │                           │ 是
                  ▼                           ▼
           reject(command)         addWorker(null, false)
           拒绝任务                 创建非核心线程
                                 │
                                 │ 入队失败
                                 ▼
                    ┌────────────────────────────┐
                    │ 第三步：尝试创建非核心线程   │
                    │ addWorker(command, false)  │
                    └────────────┬───────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
              创建成功                    创建失败
                    │                         │
                    ▼                         ▼
               return（结束）          reject(command)
                                         拒绝任务
```

---

## 四、三步策略详解

### 第一步：创建核心线程

```java
int c = ctl.get();
if (workerCountOf(c) < corePoolSize) {
    if (addWorker(command, true))
        return;
    c = ctl.get();
}
```

**逻辑说明：**
1. 获取当前 ctl 值
2. 如果工作线程数 < 核心线程数 (`corePoolSize`)，尝试创建新的核心线程
3. 调用 `addWorker(command, true)`：
   - `command`：要执行的任务
   - `true`：表示创建核心线程
4. 如果创建成功，直接返回
5. 如果创建失败（如线程池状态改变），重新获取 ctl 值，继续下一步

**失败原因可能：**
- 线程池正在关闭
- 并发情况下其他线程已创建了线程

---

### 第二步：任务入队

```java
if (isRunning(c) && workQueue.offer(command)) {
    int recheck = ctl.get();
    if (! isRunning(recheck) && remove(command))
        reject(command);
    else if (workerCountOf(recheck) == 0)
        addWorker(null, false);
}
```

**逻辑说明：**
1. 检查线程池是否处于运行状态 `isRunning(c)`
2. 将任务加入工作队列 `workQueue.offer(command)`
3. **双重检查机制（Double-Check）**：
   - 入队成功后，再次检查线程池状态
   - 如果线程池已停止，则从队列移除任务并拒绝
   - 如果线程池仍在运行，但工作线程数为0，则创建一个非核心线程

**为什么需要双重检查？**
- 入队操作不是原子的
- 入队期间线程池状态可能发生改变
- 工作线程可能在此期间全部终止

**`addWorker(null, false)` 的作用：**
- 任务已经在队列中，所以传入 `null`
- 确保至少有一个工作线程来处理队列中的任务

---

### 第三步：创建非核心线程或拒绝

```java
else if (!addWorker(command, false))
    reject(command);
```

**逻辑说明：**
1. 如果任务无法入队（队列已满），尝试创建非核心线程
2. `addWorker(command, false)`：
   - `command`：要执行的任务
   - `false`：表示创建非核心线程（最大线程数限制）
3. 如果创建失败，调用 `reject(command)` 拒绝任务

**失败原因：**
- 线程池已关闭
- 已达到最大线程数 (`maximumPoolSize`)

---

## 五、涉及的核心方法

### 1. addWorker() 方法

```java
private boolean addWorker(Runnable firstTask, boolean core)
```

**作用：** 创建并启动一个新的工作线程

**参数：**
- `firstTask`：新线程的第一个任务（可为 null）
- `core`：true 表示核心线程，false 表示非核心线程

**返回值：**
- `true`：创建成功
- `false`：创建失败

**主要逻辑：**
1. CAS 操作增加工作线程计数
2. 创建 Worker 对象（包含线程和任务）
3. 启动线程执行任务

---

### 2. isRunning() 方法

```java
private static boolean isRunning(int c)
```

**作用：** 判断线程池是否处于运行状态

**逻辑：** 检查 runState 是否小于 SHUTDOWN

---

### 3. workerCountOf() 方法

```java
private static int workerCountOf(int c)
```

**作用：** 从 ctl 值中提取工作线程数量

**逻辑：** `c & CAPACITY`（CAPACITY = (1 << 29) - 1）

---

### 4. reject() 方法

```java
final void reject(Runnable command)
```

**作用：** 执行拒绝策略

**逻辑：** 调用配置的 `RejectedExecutionHandler` 处理被拒绝的任务

**内置拒绝策略：**
- `AbortPolicy`：抛出 RejectedExecutionException（默认）
- `CallerRunsPolicy`：由调用线程执行任务
- `DiscardPolicy`：直接丢弃任务
- `DiscardOldestPolicy`：丢弃队列中最老的任务，重新提交

---

### 5. workQueue.offer() 方法

```java
workQueue.offer(command)
```

**作用：** 将任务加入工作队列

**返回值：**
- `true`：入队成功
- `false`：入队失败（队列已满）

---

## 六、线程池执行任务的完整生命周期

```
任务提交
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  工作线程数 < corePoolSize ?                              │
│  ├─ 是 → 创建核心线程 → 执行任务                          │
│  └─ 否 ↓                                                 │
│                                                          │
│  工作队列未满 ?                                           │
│  ├─ 是 → 任务入队 → 等待空闲线程执行                       │
│  └─ 否 ↓                                                 │
│                                                          │
│  工作线程数 < maximumPoolSize ?                           │
│  ├─ 是 → 创建非核心线程 → 执行任务                         │
│  └─ 否 → 执行拒绝策略                                     │
└─────────────────────────────────────────────────────────┘
```

---

## 七、总结

`execute()` 方法的三步策略体现了线程池的核心设计思想：

| 步骤 | 条件 | 操作 |
|------|------|------|
| 第一步 | 工作线程数 < corePoolSize | 创建核心线程直接执行 |
| 第二步 | 队列未满 | 任务入队等待执行 |
| 第三步 | 工作线程数 < maximumPoolSize | 创建非核心线程执行 |
| 默认 | 以上都不满足 | 执行拒绝策略 |

这种设计实现了：
- **核心线程复用**：核心线程一直存活，避免频繁创建销毁
- **任务缓冲**：工作队列作为缓冲区，平滑任务提交峰值
- **弹性扩容**：非核心线程应对突发流量
- **过载保护**：拒绝策略防止系统过载

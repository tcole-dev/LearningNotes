# AQS源码深度解析

##  AQS 整体架构

AQS（AbstractQueuedSynchronizer）是Java并发包的核心基础，提供了一个基于FIFO等待队列的框架，用于构建锁和同步器。

### 核心设计思想

1. **资源管理**：使用一个`volatile int state`变量来管理同步状态
2. **线程等待**：通过CLH队列管理等待的线程
3. **CAS操作**：保证状态修改的原子性
4. **模板方法**：提供可重写的钩子方法，子类实现具体逻辑

##  AQS 核心组成部分

### 1. 状态变量 (state)

```java
/**
 * 同步状态，使用volatile修饰保证可见性
 * 不同的同步器对此状态有不同的含义：
 * - ReentrantLock: 0表示未锁定，>0表示重入次数
 * - Semaphore: 可用许可数量
 * - CountDownLatch: 剩余需要倒数的次数
 */
private volatile int state;
```

**关键特性：**
- `volatile`修饰，保证内存可见性
- 提供了`getState()`、`setState()`、`compareAndSetState()`方法
- 子类可以自由定义state的含义

### 2. CLH 队列 (CLH Queue)

CLH队列是AQS的核心数据结构，是一个双向链表：

```java
/**
 * 等待队列的头节点
 */
private transient volatile Node head;

/**
 * 等待队列的尾节点
 */
private transient volatile Node tail;
```

**Node节点结构：**
```java
static final class Node {
    // 节点状态
    volatile int waitStatus;
    
    // 前驱节点
    volatile Node prev;
    
    // 后继节点
    volatile Node next;
    
    // 等待的线程
    volatile Thread thread;
    
    // 条件队列中的下一个节点
    Node nextWaiter;
}
```

**waitStatus状态值：**
- `0`: 初始状态
- `CANCELLED(1)`: 节点已取消
- `SIGNAL(-1)`: 后继节点需要被唤醒
- `CONDITION(-2)`: 节点在条件队列中
- `PROPAGATE(-3)`: 共享模式下传播

### 3. CAS 操作

AQS大量使用CAS操作来保证原子性：

```java
// Unsafe实例，用于CAS操作
private static final Unsafe unsafe = Unsafe.getUnsafe();

// state字段的偏移量
private static final long stateOffset;

static {
    try {
        stateOffset = unsafe.objectFieldOffset
            (AbstractQueuedSynchronizer.class.getDeclaredField("state"));
    } catch (Exception ex) { throw new Error(ex); }
}

// CAS修改state
protected final boolean compareAndSetState(int expect, int update) {
    return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
}
```

## 主要方法实现(JDK 17)

### 1. acquire 方法 (独占模式)

acquire方法是AQS的核心方法，实现了独占模式下获取同步状态的逻辑：

```java
public final void acquire(int arg) {
    if (!tryAcquire(arg))
        acquire(null, arg, false, false, false, 0L);
}
```

**执行流程：**

1. **尝试获取锁**：调用`tryAcquire(arg)`尝试获取同步状态
2. **创建节点**：如果获取失败，创建独占模式节点并加入队列
3. **队列等待**：在队列中等待获取锁
4. **中断处理**：如果在等待过程中被中断，恢复中断状态

### 2. release 方法 (独占模式)

```java
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        signalNext(head);
        return true;
    }
    return false;
}
```

**执行流程：**

1. **释放锁**：调用`tryRelease(arg)`释放同步状态
2. **唤醒后继**：如果释放成功，唤醒头节点的后继节点
3. **返回结果**：返回是否成功释放

### 3. acquireShared 方法 (共享模式)

```java
public final void acquireShared(int arg) {
    if (tryAcquireShared(arg) < 0)
        acquire(null, arg, true, false, false, 0L);
}
```

### 4. releaseShared 方法 (共享模式)

```java
public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        signalNext(head);
        return true;
    }
    return false;
}
```

## 独占模式 vs 共享模式

### 独占模式 (Exclusive)
- **特点**：同一时间只有一个线程能持有同步状态
- **典型应用**：ReentrantLock、Mutex
- **关键方法**：
  - `tryAcquire(int arg)`：尝试获取锁
  - `tryRelease(int arg)`：尝试释放锁
  - `isHeldExclusively()`：是否当前线程独占

### 共享模式 (Shared)
- **特点**：多个线程可以同时持有同步状态
- **典型应用**：Semaphore、CountDownLatch
- **关键方法**：
  - `tryAcquireShared(int arg)`：尝试获取共享锁
  - `tryReleaseShared(int arg)`：尝试释放共享锁

## 方法分析

### acquire方法

源代码（JDK 17）

```java
final int acquire(Node node, int arg, boolean shared,
                  boolean interruptible, boolean timed, long time) {
    Thread current = Thread.currentThread();
    byte spins = 0, postSpins = 0;   // 重试次数控制
    boolean interrupted = false, first = false;
    Node pred = null;                // 前驱节点

    for (;;) {
        // 1. 检查是否为头节点或建立前驱关系
        if (!first && (pred = (node == null) ? null : node.prev) != null &&
            !(first = (head == pred))) {
            if (pred.status < 0) {
                cleanQueue();           // 前驱节点已取消，清理队列
                continue;
            } else if (pred.prev == null) {
                Thread.onSpinWait();    // 确保序列化
                continue;
            }
        }
        
        // 2. 尝试获取同步状态
        if (first || pred == null) {
            boolean acquired;
            try {
                if (shared)
                    acquired = (tryAcquireShared(arg) >= 0);
                else
                    acquired = tryAcquire(arg);
            } catch (Throwable ex) {
                cancelAcquire(node, interrupted, false);
                throw ex;
            }
            
            if (acquired) {
                if (first) {
                    // 3. 获取成功，设置新的头节点
                    node.prev = null;
                    head = node;
                    pred.next = null;
                    node.waiter = null;
                    if (shared)
                        signalNextIfShared(node);
                    if (interrupted)
                        current.interrupt();
                }
                return 1;
            }
        }
        
        // 4. 节点初始化和入队
        if (node == null) {
            if (shared)
                node = new SharedNode();
            else
                node = new ExclusiveNode();
        } else if (pred == null) {
            node.waiter = current;
            Node t = tail;
            node.setPrevRelaxed(t);
            if (t == null)
                tryInitializeHead();
            else if (!casTail(t, node))
                node.setPrevRelaxed(null);
            else
                t.next = node;
        } else if (first && spins != 0) {
            // 5. 自旋优化
            --spins;
            Thread.onSpinWait();
        } else if (node.status == 0) {
            node.status = WAITING;          // 设置等待状态
        } else {
            // 6. 阻塞线程
            long nanos;
            spins = postSpins = (byte)((postSpins << 1) | 1);
            if (!timed)
                LockSupport.park(this);
            else if ((nanos = time - System.nanoTime()) > 0L)
                LockSupport.parkNanos(this, nanos);
            else
                break;
            node.clearStatus();
            if ((interrupted |= Thread.interrupted()) && interruptible)
                break;
        }
    }
    return cancelAcquire(node, interrupted, interruptible);
}
```

#### **初始化局部变量**

```java
Thread current = Thread.currentThread();
byte spins = 0, postSpins = 0;   // 重试次数控制
boolean interrupted = false, first = false;
Node pred = null;                // 前驱节点
```

spins、postSpins表示自旋次数。spins表示每次自旋的次数，postSpins用于调整下一次自旋的次数，会保留下去。

interrupted表示是否被interrupt**`唤醒过`**，与线程对象的interrupt标志位（表示线程状态）不同

first表示当前节点是否为CLH的第一个节点。

#### **队列节点检查**

```java
// 1. 检查是否为头节点或建立前驱关系
if (!first && (pred = (node == null) ? null : node.prev) != null &&
    !(first = (head == pred))) {
    if (pred.status < 0) {
        cleanQueue();           // 前驱节点已取消，清理队列
        continue;
    } else if (pred.prev == null) {
        Thread.onSpinWait();    // 确保序列化
        continue;
    }
}
```

**判断条件解释**

**!first表示此时不在队列第一个；(pred = (node == null) ? null 表示前驱不为空，即节点已经入队；!(first = (head == pred))表示前驱不为头节点，即不为队列第一个。**

!first 是上一次循环first = (head == pred)得出的缓存，若为false（first为true）则不需要判定，可直接尝试获取锁。

!first 为true的话，存在缓存已经过期的情况（进入第二次循环时实际情况已经改变），还需要!(first = (head == pred))重新获取最新的first，进行判定是否为第一个节点，同时更新first。

**执行操作解释**

1. pred.status < 0表示前驱节点被取消了，此时需要清理队列，将取消的节点删除
2. pred.prev == null 表示前驱节点的状态正在改变，前驱的前驱为null，说明前驱正在变为head节点，应该自旋等待其改变完成

#### **尝试获取同步状态**

```java
// 2. 尝试获取同步状态
if (first || pred == null) {
    boolean acquired;
    try {
        if (shared)
            acquired = (tryAcquireShared(arg) >= 0);
        else
            acquired = tryAcquire(arg);
    } catch (Throwable ex) {
        cancelAcquire(node, interrupted, false);
        throw ex;
    }

    if (acquired) {
        if (first) {
            // 3. 获取成功，设置新的头节点
            node.prev = null;
            head = node;
            pred.next = null;
            node.waiter = null;
            // 如果当前节点是共享节点，并且状态允许传播，就唤醒后继节点。 
            if (shared)
                signalNextIfShared(node);
            if (interrupted)
                current.interrupt();
        }
        return 1;
    }
}
```

获取条件：<font color='red'>first，即为**排队的第一个节点** ； 前驱为null，表示**还未入队、未创建node**，此时可尝试获取，失败后续会创建节点。若成功，则`return`退出方法</font>

这一部分分两步：

1. 根据shared调用模板方法`tryAcquire`或`tryAcquireShared`

2. 若成功获取，且当前节点是第一个节点，会将当前节点赋值给head，并设置对应的属性（如变为head后，waiter、next等属性都应该为null），然后直接退出方法。

   <font color='blue'>若节点仍未创建呢？如何设置为头节点？</font>	答案是 first只在节点检查的if条件中修改，初始值为false，若执行了第二条判定，必然会执行第三条，first = (head == pred)，pred因节点未创建为null，则first必然是false，不会进入if代码块。总之节点未创建时，即使获取成功也根本不会干涉CLH。
   
   <font color='red'>设置头节点后还有两处细节：                                                                                                                                                                        1.如果当前节点是共享节点，并且状态允许传播，就唤醒后继节点。                                                                                                      2.若曾经被打断过（interrupted记录），则调用`interrupt()`重新恢复打断状态，以便退出`acquire`后代码需要判断  </font>

#### **节点入队**

```java
// 4. 节点初始化和入队
if (node == null) {
    if (shared)
        node = new SharedNode();
    else
        node = new ExclusiveNode();
} else if (pred == null) {
    node.waiter = current;
    Node t = tail;
    node.setPrevRelaxed(t);
    if (t == null)
        tryInitializeHead();
    else if (!casTail(t, node))
        node.setPrevRelaxed(null);
    else
        t.next = node;
}
```

若不符合竞争同步状态的条件，且未入队时，AQS要将此时的节点放入等待队列CLH，CLH实质上就是一个个node组成的链表。

此时，这个线程可能有两种情况，**未创建node**或**创建但未入队**。

若node == null，即未创建node，需要根据shared调用不同构造方法。这是懒加载的体现。

若node != null，pred == null，即未入队，此时会创建一个Node，将其挂载到tail尾节点后，当尾节点为空时，会先创建头节点，尾节点为头节点的引用。

**<font color='red'>为什么创建node后不直接入队？</font>**

1. 若持锁的线程很快就会释放，明明只需要自旋即可，但若tryAcquire失败进入acquire就直接入队，tail竞争激烈，GC压力大

2. 快路径：tryAcquire + CAS           慢路径：入队 + park

   直接入队相当于直接忽略了快路径

3. park、unpark很“昂贵”，应该避免直接入队

**<font color='red'>为什么先挂载tail再判断null？</font>**

```java
Node t = tail;
node.setPrevRelaxed(t);			// 第一次修改
if (t == null)
    tryInitializeHead();
else if (!casTail(t, node))		// 第二次修改
    node.setPrevRelaxed(null);
else
    t.next = node;
```

setPrevRelaxed()方法，用于当前节点的前驱节点。               tryInitializeHead()方法，用于首个Node入队时，初始化CLH的头节点。

首先设置当前节点的前驱为tail，然后判断是否为null，这种做法的原因：

1. tail是volatile变量，每次获取都很“贵”，因此先获取，再用获取的变量判断（一次获取），而不是先获取并判断然后再获取并赋值（两次获取）
2. 先判断再获取违背了**`同一语义快照原则`**，判断的tail和实际获取的tail可能不同

<font color='red'>注意：tryInitializeHead()方法是CAS竞争，head、tail不会重复初始化，所以判断和获取的顺序不影响初始化</font>

**<font color='red'>setPrevRelaxed、casTail方法</font>**

setPrevRelaxed方法等价于直接赋值，没有内存屏障，修改结果不能确保立即对全部线程可见，只是临时的挂靠，不确定最终结果

casTail方法是真正修改tail引用的方法，setPrevRelaxed先将node.prev = tail（node.prev指向tail所指的node，而非tail对象本身），casTail再修改tail对象本身，一旦成功修改，即可立即通过当前节点前驱找到上一个节点，不会出现空档期（tail的prev还是null的情况），cas修改失败，再setPrevRelaxed修改node.prev = null

#### **自旋**

```java
else if (first && spins != 0) {
    // 5. 自旋优化
    --spins;
    Thread.onSpinWait();
} else if (node.status == 0) {
    node.status = WAITING;          // 设置等待状态
}
```

线程获取同步状态失败后，创建节点并入队，在这一步，会进行自旋或者设置等待状态

1. 若当前节点在队首，会进行自旋，spins自减，经历spins次循环，目的是持续判断是否可获取同步状态
2. 当spins次循环后都不能获取同步状态，则设置状态为等待，因为只有WAITTING状态的node才能被release唤醒

#### **阻塞**

```java
else {
    // 6. 阻塞线程
    long nanos;
    spins = postSpins = (byte)((postSpins << 1) | 1);
    if (!timed)
        LockSupport.park(this);
    else if ((nanos = time - System.nanoTime()) > 0L)
        LockSupport.parkNanos(this, nanos);
    else
        break;
    node.clearStatus();
    if ((interrupted |= Thread.interrupted()) && interruptible)
        break;
}
```

1. 设置spins、postSpins，若unpark仍获取失败，根据spins再次自旋

2. 调用`park/parkNanos`阻塞线程

3. 被唤醒后调用clearStatus清除状态

4. 若interruptible为true（当前是可打断的lockInterruptibly()、tryLock(timeout)方法），且当前线程被打断过，退出循环。

   <font color='red'>`interrupted |= Thread.interrupted()`等价于`interrupted = ( interrupted || Thread.interrupted());`，对interrupted赋值，若有打断则记录下来。无论是否可打断都会记录，但只有可打断才退出。</font>

   

**<font color='red'>注意！！！                                                                                                                                                                                                    `park/unpark`会阻塞线程，但若线程调用`interrupt`，会让park直接返回，不再阻塞，执行`clearStatus`，从而进入if代码块判断是否打断，可打断的退出，不可打断的会清除打断状态，并在下一次循环开始自旋、重新设置`WAITTING`，再经过一次循环，进行park阻塞</font>**

#### **退出**

除了成功获取同步状态的线程节点，其他节点不管因为任何情况（超时、打断）退出主循环，都会执行`return cancelAcquire(node, interrupted, interruptible);`，安全将节点从CLH移除。

### release方法

```java
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        signalNext(head);
        return true;
    }
    return false;
}
```

release方法与acquire对应，用于`释放同步状态`、`唤醒节点`

1. 调用tryRelease方法释放state
2. tryRelease成功后调用`signalNext(head)`，唤醒 head 的下一个有效等待节点

**关键优化点：**

1. **自旋优化**：在适当的情况下进行自旋，避免线程上下文切换的开销
2. **队列清理**：及时清理已取消的节点，保持队列健康
3. **状态管理**：精确的节点状态转换，确保正确性
4. **中断处理**：支持可中断的锁获取





## 模板方法模式

AQS采用了模板方法模式，定义了算法的骨架，将具体实现留给子类：

```java
// 需要子类实现的钩子方法
protected boolean tryAcquire(int arg);
protected boolean tryRelease(int arg);
protected int tryAcquireShared(int arg);
protected boolean tryReleaseShared(int arg);
protected boolean isHeldExclusively();

// AQS实现的模板方法
public final void acquire(int arg);
public final boolean release(int arg);
public final void acquireShared(int arg);
public final boolean releaseShared(int arg);
```

## 实际应用

### ReentrantLock基于AQS的实现

```java
class Sync extends AbstractQueuedSynchronizer {
    // 非公平锁实现
    final boolean nonfairTryAcquire(int acquires) {
        final Thread current = Thread.currentThread();
        int c = getState();
        if (c == 0) {
            if (compareAndSetState(0, acquires)) {
                setExclusiveOwnerThread(current);
                return true;
            }
        }
        else if (current == getExclusiveOwnerThread()) {
            int nextc = c + acquires;
            setState(nextc);
            return true;
        }
        return false;
    }
    
    protected final boolean tryRelease(int releases) {
        int c = getState() - releases;
        if (Thread.currentThread() != getExclusiveOwnerThread())
            throw new IllegalMonitorStateException();
        boolean free = false;
        if (c == 0) {
            free = true;
            setExclusiveOwnerThread(null);
        }
        setState(c);
        return free;
    }
}
```

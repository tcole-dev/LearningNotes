## 大纲

1. [什么是 CountDownLatch](##CountDownLatch简述)
2. [CountDownLatch 的用处](##CountDownLatch用处及用法)
3. [CountDownLatch 的实现原理](##CountDownLatch的实现原理)
   1. [CountDownLatch 主要结构](###CountDownLatch主要结构)
   2. [CountDownLatch 主要方法实现](###主要方法实现)
   3. [AQS运用和 ReentrantLock 等`锁`的差异](###AQS的独特运用)

## CountDownLatch简述

`CountDownLatch`按照功能划分来说，应该叫做同步工具类，虽然常常和ReentrantLock（锁）、ConcurrentHashMap（并发容器）等放在一起谈及，它们常常使用到一些共通的思想，但三者在功能和实现上有极大区别。

`CountDownLatch`用于阻塞一个或多个线程，并在满足条件（其他被等待的线程完成任务）时将这些线程全部唤醒，让被阻塞线程能够执行后续任务。

```
举例：
A、B、C一起赛跑，计时员需要阻塞等待三人到达，才能在纸上统计三人成绩。
A体力更好，跑到终点时，B、C还在半路，此时等待人数减一。
B到达后，还需要等待一个人。
C到达后，三人全部到达，便唤醒了阻塞的计时员，被阻塞的计时员（可能有多个）一起执行后续任务（统计成绩）。
```

CountDownLatch基于AQS实现，继承了`AbstractQueuedSynchronizer`，上面例子中的`需要等待的人数`即AQS抽象类中的`state`。

<font color=red>`CountDownLatch`似乎就是一个计数器？为什么不直接用原子类`AtomicIntrger`？</font>

因为CountDownLatch并不是只有计数器的作用，CountDownLatch同时还需要能够阻塞和唤醒线程。若使用原子类实现，则需要不停轮询来实现阻塞和唤醒，会浪费CPU，而使用CountDownLatch时，当需要阻塞时，可以直接调用await方法，进入等待队列，不会浪费CPU。

## CountDownLatch用处及用法

CountDownLatch最主要的用处即简述中提到的，“允许一个或多个线程等待，直到正在其他线程中进行的一组操作完成.”，让不同组的操作之间严格形成先后顺序，保证同步语序，有点类似于Volatile禁止指令重排序插入内存屏障的感觉。

**CountDownLatch的用法**

```java
// 10表示需要等待的线程数量
CountDownLatch latch = new CountDownLatch(10);
for (int i = 0; i < 5; i++) {
    new Thread(new Runnable() {
        @Override
            public void run() {
            // 线程完成任务
            System.out.println(Thread.currentThread().getName() + " working");
            try {
                Thread.sleep(1000);
                // 一个线程完成任务后调用countDown，等待线程数减一，判断是否唤醒队列中的线程
                latch.countDown();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }).start();;
}
// 主线程开始执行任务
System.out.println("Main Thread starts to wait for other threads...");
try {
    // 调用await方法的线程主动被阻塞，直到state减小到0（5个子线程全部完成任务），被唤醒
    latch.await();
} catch (Exception e) {
    e.printStackTrace();
}
// 执行后续任务
System.out.println("Main Thread Finished");
```

输出结果

```
Main Thread starts to wait for other threads...
Thread-4 working
Thread-0 working
Thread-2 working
Thread-3 working
Thread-1 working
Main Thread Finished
```

CountDownLatch最常用的方法就是`await`、`countDown`，分别实现等待和计数，掌握这两个方法在一般情况下就已经够用了。

## CountDownLatch的实现原理

### CountDownLatch主要结构

```java
private final Sync sync;
```

CountDownLatch核心结构就是一个`Sync`，和`ReentrantLock`中的`Sync`一样，继承了AQS，所有逻辑、接口都是基于AQS的。

总所周知，AQS是一个同时支持`独占模式`和`共享模式`的同步器，ReentrantLock使用的是独占模式，CountDownLatch则是共享模式。共享模式下，允许多个线程同时获取同步状态（即state到0后同时释放队列中的所有线程）并执行后续代码逻辑。

```java
private static final class Sync extends AbstractQueuedSynchronizer {
        private static final long serialVersionUID = 4982264981922014374L;

        Sync(int count) {
            setState(count);
        }

        int getCount() {
            return getState();
        }
		// await中调用，若state为0，即等待的线程都已经到达
        protected int tryAcquireShared(int acquires) {
            return (getState() == 0) ? 1 : -1;
        }
		
        protected boolean tryReleaseShared(int releases) {
            // state减一，若已经到0，即要等待的线程都已经到达，则返回false
            for (;;) {
                int c = getState();
                if (c == 0)
                    return false;
                int nextc = c - 1;
                if (compareAndSetState(c, nextc))
                    return nextc == 0;
            }
        }
    }
```

### 主要方法实现

`await`流程

<img src="C:\Users\t'c\Desktop\Markdowns\img\CountDownlatch_await.png" style='zoom:50%'> 

```java
public void await() throws InterruptedException {
    sync.acquireSharedInterruptibly(1);
}

// CountDownLatch中阻塞是可以打断的，被打断后抛出异常，若进入acquire被打断，同样会有应对措施
public final void acquireSharedInterruptibly(int arg)
    throws InterruptedException {
    if (Thread.interrupted() ||
        (tryAcquireShared(arg) < 0 &&
         acquire(null, arg, true, true, false, 0L) < 0))
        throw new InterruptedException();
}

// 直接对比state，若等于0则可以获取同步状态
protected int tryAcquireShared(int acquires) {
    return (getState() == 0) ? 1 : -1;
}

// acquire源码在AQS部分简述，总之就是一个检查、尝试获取、入队、自旋、阻塞、退出的循环过程
```

`countDown()`流程

<img src="C:\Users\t'c\Desktop\Markdowns\img\CountDownLatch_countDown.png" style='zoom:60%'> 

```java
public void countDown() {
    sync.releaseShared(1);
}
// AQS中实现，state自减，判断是否减至0，若成功则可以唤醒阻塞线程
public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        signalNext(head);
        return true;
    }
    return false;
}

// Sync中实现，该方法不仅是state减一，其语义为是否state降低到0，若返回true，则可以唤醒了
protected boolean tryReleaseShared(int releases) {
    for (;;) {
        int c = getState();
        // 原本为0，，别人早就已经满足条件了，直接false
        if (c == 0)
            return false;
        int nextc = c - 1;
        if (compareAndSetState(c, nextc))
            return nextc == 0;
    }
}
```

### AQS的独特运用

前面提到，CountDownLatch基于AQS实现，内部采用共享模式。因此在AQS的使用也和原本学习过的ReentrantLock有较大区别。下面列举一些两者在AQS上的相同和相异。

1. 在ReentrantLock中，state表示为一个线程的锁重入次数，state减到0后，其他线程才能获取。而CountDownLatch中，state表示等待线程数，state减到0后，阻塞的线程才能被唤醒并继续执行任务。

2. ReentrantLock核心思想是，各线程进行竞争，一个线程可以修改state，当其释放后其他线程重新竞争。

   CountDownLatch则是初始化时就显式设置了state的数值，可以理解为开局就给AQS添加了几把不一定由同一线程持有的锁，调用await的线程必须等待开局设置的几个锁被释放，才能获取同步状态执行任务

3. CountDownLatch的countDown方法中，不同线程会竞争state，并一次只有一个线程能够修改，这看起来似乎很像是`加锁`的过程，但恰恰相反，若一定要用“锁”的概念来理解，`countDown`等价于释放锁的过程。

   正因为开局就有多个线程“持锁”，所以原本的竞争“吃素”就变成了现在的竞争“释放锁”

4. await方法一看到就会联想到`Condition`的await，这个await确实也有进入等待队列的作用，但却不是条件队列，这个await更倾向于ReentrantLock中的lock，核心作用是等待条件达成，若条件还未达成，就阻塞等待唤醒。

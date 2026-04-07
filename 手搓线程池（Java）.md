# 手搓一个简单的线程池

本文仅记录从0到1手写一个最基本（简陋）线程池的过程，**功能有阉割**、**逻辑不够完善**、**并发可能不够安全**。

## 要实现的基本逻辑

- 提交任务
- 线程池关闭方法、运行状态
- 任务队列、线程集合
- 线程创建、调度
- 拒绝策略

## v1.0

### 实现线程池接口

一个线程池接口最基本的方法要包括：execute提交任务、shutdown关闭线程池、shutdownNow立即关闭。

```java
public interface ExecutorService {
    void execute();
    
    void shutdown();
    
    List<Runnable> shutdownNow();
}
```

### 线程池类

线程池类需要实现线程池接口，实现最基本的功能。

#### 工作线程类

一个工作线程中，需要维护保存任务的阻塞队列，工作线程类需继承Thread，run方法重写为不断从该队列中获取任务并执行。

```java
public class Worker extends Thread {
    // 任务队列
    private BlockingQueue<Runnable> taskQueue;
    // 构造Worker
    public Worker(BlockingQueue<Runnable> taskQueue) {
        this.taskQueue = taskQueue;
    }
    
    @Override
    public void run() {
        Runnable task = null;
        while (!Thread.currentThread().isInterrupted() && (task = taskQueue.take()) != null) {
            task.run();
        }
    }
}
```

#### 线程池类

线程池类自身要实现的方法：构造方法、execute、shutdown、shutdownNow

```java
public class DemoThreadPool implements ExecutorService {
    private BlockingQueue<Runnable> taskQueue;
    private List<Worker> workers;
    private boolean isStopped = false;
    private int nThreads;


    public DemoThreadPool(int nThreads) {
        this.nThreads = nThreads;
        taskQueue = new LinkedBlockingQueue<>();
        workers = new ArrayList<>(nThreads);
		// 初始化时创建线程
        for (int i = 0; i < this.nThreads; i++) {
            var worker = new Worker(taskQueue);
            workers.add(worker);
            worker.start();
        }
    }

    @Override
    public void execute(Runnable task) {
        if (isStopped) return;
        taskQueue.offer(task);
    }

    @Override
    public void shutdown() {
        isStopped = true;
        for (var worker : workers) {
            worker.interrupt();
        }
    }

    @Override
    public List<Runnable> shutdownNow() {
        isStopped = true;
        for (var worker : workers) {
            worker.interrupt();
        }
        List<Runnable> tasks = new ArrayList<>();
	    taskQueue.drainTo(tasks);
        return tasks;
    }
}
```

### 总结

目前的线程池已经具有了 `execute提交Runnable任务`、`shutdown、shutdownNow关闭线程池`、`线程自动获取任务执行`的功能。同时，还存在以下缺陷：

- 线程池中的线程只能在初始化线程池时被创建，不能在运行时创建
- 线程池缺少大量关键属性：核心线程数、最大线程数、任务队列大小、核心线程是否超时
- 线程池execute逻辑缺失：根据线程数的情况判断是否创建线程、入队等
- 线程的超时机制缺失，getTask中使用take阻塞获取。

## v2.0

### Worker线程类改造

原来的Worker中缺少接收创建线程时的`第一个任务`变量，无法实现创建时传入任务的效果。同时修改getTask方法逻辑，实现超时机制。

```java
private class Worker extends Thread {
        // 任务队列
        private BlockingQueue<Runnable> taskQueue;
        // 第一个任务
        private Runnable firstTask;
        // 构造Worker
        public Worker(BlockingQueue<Runnable> taskQueue, Runnable firstTask) {
            this.taskQueue = taskQueue;
            this.firstTask = firstTask;
        }

        @Override
        public void run() {
            Runnable task = null;
            try {
                // 未被打断、未终止线程池、有传入任务或getTask获取到任务。三个条件满足才run
                while (!Thread.currentThread().isInterrupted() && !isStopped && (firstTask != null ||  (task = getTask()) != null)) {
                    try {
                        if (firstTask != null) {
                            task = firstTask;
                            firstTask = null;
                        }
                        task.run();
                    } catch (Exception e) {}
                }
            } finally {
                // 若run方法执行完毕，该工作线程要注销，从workers工作线程列表删除。
                synchronized (workers) {
                    workers.remove(this);
                }
            }
        }

        private Runnable getTask() {
            Runnable task = null;
            // 是否已经超时过一次
            boolean lastTimeOut = false;

            for (;;) {
                if (isStopped) {
                    return null;
                }
                // 本轮次是否超时
                boolean timeOut = isCoreThreadTimeout || workers.size() > maxCoreThread;
			   // 若本轮需要超时，且已经超时，则退出
                if (timeOut && lastTimeOut) {
                    return null;
                }

                // 根据是否超时使用不同方法
                try {
                    task = timeOut ? taskQueue.poll(10, TimeUnit.SECONDS) : taskQueue.take();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    if (task != null) {
                        return task;
                    } else {
                        // 若没有获取到（只有poll方法或被打断才可能获取不到），设置超时标志，进入下一轮
                        lastTimeOut = true;
                    }
                }
            }
        }
    }
```

### 核心线程数等关键属性

```java
public class DemoThreadPool implements ExecutorService {
    // 任务队列
    private BlockingQueue<Runnable> taskQueue;
    // 工作线程列表
    private List<Worker> workers;
    // 线程池是否停止
    private volatile boolean isStopped = false;
    // 线程池初始线程数
    private int initThreadNum;
    // 最大核心线程数
    private int maxCoreThread;
    // 最大线程数
    private int maxThread;
    // 核心线程超时
    private boolean isCoreThreadTimeout;

    public DemoThreadPool(int initThreadNum, int maxCoreThread, int maxThread, int taskQueueSize, boolean isCoreThreadTimeout) {
        this.initThreadNum = initThreadNum;
        this.maxCoreThread = maxCoreThread;
        this.maxThread = maxThread;
        this.isCoreThreadTimeout = isCoreThreadTimeout;
		// 指定任务队列大小
        taskQueue = new LinkedBlockingQueue<>(taskQueueSize);
        workers = new ArrayList<>(initThreadNum);

        for (int i = 0; i < this.initThreadNum; i++) {
            var worker = new Worker(taskQueue);
            workers.add(worker);
            worker.start();
        }
    }

    @Override
    public void execute(Runnable task) throws Exception {
        while (!isStopped) {
            // 线程数小于核心线程数，创建线程
            if (workers.size() < maxCoreThread) {
                if (!addWorker(task)) continue;
                return;
                // 否则进入任务队列
            } else if (!taskQueue.offer(task)) {
                // 进入失败（队列已满）
                // 若线程数小于最大线程数，创建非核心线程
                if (workers.size() < maxThread) {
                    if (!addWorker(task)) continue;
                    return;
                } else {
                    throw new SizeException("Task Queue Fulled And Thread Max");
                }
            }
            return;
        }
        throw new StatusException("Thread Pool Closed");
    }

	// ......省略shutdown、shutdownNow
	
	public boolean addWorker(Runnable task) throws Exception {
        while (!isStopped) {
            // 若还没达最大线程数
            if (workers.size() < maxThread) {
                // 加锁修改workers
                synchronized (workers) {
                    // 再次判断
                    if (workers.size() >= maxThread && !isStop) continue;
                    var worker = new Worker(taskQueue, task);
                    workers.add(worker);
                    worker.start();
                    return true;
                }
            } else {
                return false;
            }
        }
        throw new StatusException("Thread Pool Closed");
    }
    
}
```

### 总结

此时优化后的线程池已具备创建线程、任务提交与领取、线程生命管理等逻辑。但，还缺少：

- Ctl实现的（Running、Shutdown、Stop等）状态机
- Callable & Future支持，获取返回值
- shutdown、shutdownNow逻辑优化
- 拒绝策略、阻塞队列、空闲（超时）时间参数传入等

## v2.5

前面已经说过，本文实现的只是一个简陋的线程池实现，所以，在v2.5中，我只会再添加拒绝策略的实现，阻塞队列、超时时间、Callable、状态机流转不具体实现。

### 拒绝策略

#### 拒绝策略接口

```java
public interface RejectedExecutorHandler {
 	// 该接口只有一个方法，用于实现不同逻辑。
    // 参数为被拒绝的任务、线程池对象（用于重试等）
    void rejectedExecution(Runnable task, ExecutorService executor);
}
```

#### 不同实现

拒绝策略：抛出异常

```java
public class AbortPolicy implements RejectedExecutorHandler {
    @Override
    public void rejectedExecution(Runnable task, ExecutorService executor) {
        throw new RuntimeException("Task No." + ((Task) task).getId() + " rejected. " + "RejectedHandler: " + this.getClass().getSimpleName());
    }
}
```

拒绝策略：丢弃

```java
public class DiscardPolicy implements RejectedExecutorHandler {
    @Override
    public void rejectedExecution(Runnable task, ExecutorService executor) {
        // 直接丢弃任务，不抛出异常
        System.out.println("Task No." + ((Task) task).getId() + " discarded. RejectedHandler: " + this.getClass().getSimpleName());
    }

}
```

拒绝策略：重试

```java
public class TryAgainPolicy implements RejectedExecutorHandler{
    @Override
    public void rejectedExecution(Runnable task, ExecutorService executor) {
        BlockingQueue<Runnable> workQueue = ((DemoThreadPool) executor).getWorkQueue();
        // 从线程池获取任务队列
        try {
            // 被拒绝的情况为：任务队列满、线程数达最大。execute类似于忙等待（不断poll进任务队列），为了避免，使用put
            workQueue.put(task);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}

```

#### 线程池类修改

通过构造方法传入拒绝策略

```java
 public DemoThreadPool(int initThreadNum, int maxCoreThread, int maxThread, int taskQueueSize, RejectedExecutorHandler rejectedHandler, boolean isCoreThreadTimeout) {
		// ......
     
        this.rejectedHandler = rejectedHandler;
     
		// .......
}
```

execute方法修改

```java
public void execute(Runnable task) throws Exception {
    while (!isStopped) {
        if (workers.size() < maxCoreThread) {
            if (!addWorker(task)) continue;
            return;
        } else if (!taskQueue.offer(task)) {
            if (workers.size() < maxThread) {
                if (!addWorker(task)) continue;
                return;
            } else {
                // 由原来的报错改为执行拒绝策略的拒绝方法
                rejectedHandler.rejectedExecution(task, this);
            }
        }
        return;
    }
    throw new StatusException("Thread Pool Closed");
}
```



## 验证

```java
public class test {
    public static void main(String[] args) {
        // 初始两个线程，核心线程数4，最大线程数8，任务队列长度10，重试拒绝策略，核心线程不允许超时
        ExecutorService executor = new DemoThreadPool(2, 4, 8, 10, new TryAgainPolicy(), false);
        for(int i = 0; i < 20; i++) {
            try {
                var task = new Task(i, new Runnable() {
                    public void run() {
                        try {
                            Thread.sleep((int)(Math.random() * 1000));
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                });
                executor.execute(task);
            } catch (Exception e) {
                // e.printStackTrace();
                System.out.println("Task No." + i + " rejected");
            }
        }
    }
}
```

输出结果：

```
Task No.1 finished by Thread-3
Task No.14 finished by Thread-5
Task No.2 finished by Thread-0
Task No.5 finished by Thread-5
Task No.7 finished by Thread-5
Task No.0 finished by Thread-2
Task No.8 finished by Thread-5
Task No.4 finished by Thread-3
Task No.11 finished by Thread-3
Task No.9 finished by Thread-2
Task No.3 finished by Thread-1
Task No.16 finished by Thread-6
Task No.6 finished by Thread-0
Task No.17 finished by Thread-7
Task No.15 finished by Thread-2
Task No.12 finished by Thread-4
Task No.18 finished by Thread-1
Task No.13 finished by Thread-3
Task No.10 finished by Thread-5
Task No.19 finished by Thread-6
```

## 总结

从最开始只能固定线程数、任务队列无限制存放，到逐步改bug，加入线程生命周期、拒绝策略等部分，至此，这个线程池能够完成一些情况下的任务提交、处理。

当然，现在的线程池还缺少很多内容，如v2.0总结中提到的`Callable & Future`、`状态机`等，真正的线程池会远比我们自己实现的线程池更加复杂、强大。
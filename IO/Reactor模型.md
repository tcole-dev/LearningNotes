# Reactor模型详解

## 一、什么是Reactor模型？

Reactor模型是一种**事件驱动的IO多路复用设计模式**，用于处理并发IO请求。它的核心思想是：

> **将IO事件的监听和分发与业务处理分离**，通过一个或多个Reactor（反应器）线程负责监听IO事件，当事件就绪时分发给对应的Handler处理。

### 核心组件

| 组件 | 职责 |
|------|------|
| **Reactor** | 负责监听和分发IO事件（连接就绪、读就绪、写就绪） |
| **Acceptor** | 处理新连接的建立 |
| **Handler** | 处理具体的IO读写和业务逻辑 |

### 工作流程

```
┌─────────────────────────────────────────────────────────┐
│                      Reactor                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │           Selector (多路复用器)                   │   │
│  │     监听: ACCEPT | READ | WRITE 事件             │   │
│  └──────────────────────┬──────────────────────────┘   │
│                         │ 事件分发                      │
│         ┌───────────────┼───────────────┐              │
│         ▼               ▼               ▼              │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐          │
│   │ Acceptor │   │ Handler1 │   │ Handler2 │          │
│   │ 新连接   │   │ 读/写    │   │ 读/写    │          │
│   └──────────┘   └──────────┘   └──────────┘          │
└─────────────────────────────────────────────────────────┘
```

---

## 二、Reactor模型的三种实现

### 1. 单Reactor单线程

所有IO操作都在一个线程中完成。

```
┌─────────────────────────────────────┐
│         单Reactor单线程              │
│  ┌───────────────────────────────┐  │
│  │   Reactor + Acceptor + Handler │  │
│  │        (单线程)                │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**特点**：
- 结构简单，无线程切换开销
- 但一个Handler阻塞会影响其他所有客户端
- 适用于业务处理快速的场景

**代表**：Redis

### 2. 单Reactor多线程

Reactor线程负责IO监听和分发，Handler使用线程池处理业务。

```
┌─────────────────────────────────────────────┐
│              单Reactor多线程                 │
│  ┌───────────────────────────────────────┐  │
│  │  Reactor线程 (监听 + IO读写)           │  │
│  └───────────────┬───────────────────────┘  │
│                  │                           │
│                  ▼                           │
│  ┌───────────────────────────────────────┐  │
│  │         线程池 (业务处理)              │  │
│  │   Thread1 | Thread2 | Thread3 | ...   │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**特点**：
- IO操作与业务处理分离
- 业务处理不会阻塞IO线程
- Reactor线程仍是单点，高并发时可能成为瓶颈

### 3. 主从Reactor多线程

mainReactor负责连接建立，subReactor负责IO读写。

```
┌──────────────────────────────────────────────────────────┐
│                 主从Reactor多线程                         │
│                                                          │
│  ┌─────────────────┐      ┌─────────────────────────┐   │
│  │  mainReactor    │      │     subReactor组         │   │
│  │  (监听连接)      │─────▶│  sub1 | sub2 | sub3 ... │   │
│  │  Acceptor       │      │  (IO读写)               │   │
│  └─────────────────┘      └───────────┬─────────────┘   │
│                                       │                  │
│                                       ▼                  │
│                           ┌─────────────────────────┐   │
│                           │     Worker线程池        │   │
│                           │   (业务逻辑处理)        │   │
│                           └─────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

**特点**：
- 职责分离，扩展性强
- 充分利用多核CPU
- 实现复杂度较高

**代表**：Netty、Memcached

---

## 三、类比IO模型理解Reactor

### IO模型 vs Reactor模型对照

| IO模型 | Reactor模型 | 特点 |
|--------|-------------|------|
| **BIO (阻塞IO)** | 传统Thread-per-Connection | 一个连接一个线程，阻塞等待 |
| **NIO (非阻塞IO)** | 单Reactor单线程 | 非阻塞轮询，单线程处理所有连接 |
| **IO多路复用** | Reactor核心机制 | Selector统一监听多个Channel事件 |
| **AIO (异步IO)** | Proactor模型 | 操作系统完成IO后回调通知 |

### 图解对比

#### 传统BIO模型
```
客户端1 ──▶ Thread1 ──▶ 阻塞等待读 ──▶ 处理
客户端2 ──▶ Thread2 ──▶ 阻塞等待读 ──▶ 处理
客户端3 ──▶ Thread3 ──▶ 阻塞等待读 ──▶ 处理
...
(连接数 = 线程数，资源消耗大)
```

#### Reactor模型 (NIO多路复用)
```
客户端1 ──┐
客户端2 ──┼──▶ Selector ──▶ Reactor ──▶ 分发到对应Handler
客户端3 ──┤     (单线程监听)
客户端4 ──┘
(一个线程管理多个连接，资源消耗小)
```

### 关键类比

| 概念 | 生活类比 |
|------|----------|
| **BIO** | 银行每个客户配一个专属柜员，柜员等客户填表时也一直等着 |
| **NIO** | 柜员不断巡视所有客户，谁填好表了就处理谁 |
| **Reactor** | 大堂经理(Reactor)观察谁需要服务，分发给空闲柜员(Handler) |
| **Selector** | 叫号系统，知道哪个窗口空闲 |

---

## 四、如何使用Reactor模型？

### Java NIO 实现Reactor示例

```java
// Reactor核心代码示意
public class Reactor implements Runnable {
    private final Selector selector;
    
    public Reactor(int port) throws IOException {
        selector = Selector.open();
        ServerSocketChannel serverSocket = ServerSocketChannel.open();
        serverSocket.bind(new InetSocketAddress(port));
        serverSocket.configureBlocking(false);
        
        // 注册Accept事件，绑定Acceptor处理器
        serverSocket.register(selector, SelectionKey.OP_ACCEPT, new Acceptor());
    }
    
    @Override
    public void run() {
        while (!Thread.interrupted()) {
            selector.select(); // 阻塞等待事件
            Set<SelectionKey> selected = selector.selectedKeys();
            for (SelectionKey key : selected) {
                dispatch(key); // 分发事件
            }
            selected.clear();
        }
    }
    
    void dispatch(SelectionKey key) {
        Runnable handler = (Runnable) key.attachment();
        if (handler != null) {
            handler.run();
        }
    }
    
    // Acceptor - 处理新连接
    class Acceptor implements Runnable {
        @Override
        public void run() {
            SocketChannel client = serverSocket.accept();
            if (client != null) {
                new Handler(selector, client); // 为新连接创建Handler
            }
        }
    }
}

// Handler - 处理IO读写
class Handler implements Runnable {
    private final SocketChannel channel;
    private final SelectionKey key;
    
    public Handler(Selector selector, SocketChannel channel) throws IOException {
        this.channel = channel;
        channel.configureBlocking(false);
        key = channel.register(selector, SelectionKey.OP_READ, this);
    }
    
    @Override
    public void run() {
        if (key.isReadable()) {
            read();  // 读取数据
        } else if (key.isWritable()) {
            write(); // 写入数据
        }
    }
    
    void read() { /* ... */ }
    void write() { /* ... */ }
}
```

### Netty中的Reactor实现

Netty采用**主从Reactor多线程模型**：

```java
// 服务端启动代码
EventLoopGroup bossGroup = new NioEventLoopGroup(1);    // mainReactor
EventLoopGroup workerGroup = new NioEventLoopGroup();    // subReactor

ServerBootstrap bootstrap = new ServerBootstrap();
bootstrap.group(bossGroup, workerGroup)
    .channel(NioServerSocketChannel.class)
    .childHandler(new ChannelInitializer<SocketChannel>() {
        @Override
        protected void initChannel(SocketChannel ch) {
            ch.pipeline().addLast(new MyHandler());
        }
    });

ChannelFuture future = bootstrap.bind(8080).sync();
```

**Netty组件对应关系**：
- `EventLoopGroup` → Reactor线程组
- `EventLoop` → 单个Reactor线程
- `Channel` → 连接通道
- `ChannelPipeline` → Handler链

---

## 五、Reactor vs Proactor

| 特性 | Reactor | Proactor |
|------|---------|----------|
| **模式** | 同步IO | 异步IO |
| **通知时机** | IO就绪（可读/可写） | IO完成（已读取/已写入） |
| **谁执行IO** | 应用程序 | 操作系统内核 |
| **复杂度** | 较低 | 较高 |
| **平台支持** | Linux (epoll) | Windows (IOCP) |

```
Reactor:   就绪通知 ──▶ 应用程序read ──▶ 应用程序处理
Proactor:  发起异步read ──▶ 内核完成read ──▶ 回调通知 ──▶ 应用程序处理
```

---

## 六、总结

### Reactor模型核心要点

1. **事件驱动**：基于IO多路复用，一个线程管理多个连接
2. **非阻塞**：IO操作非阻塞，不会因单个连接阻塞整体
3. **职责分离**：Reactor监听分发，Handler处理业务
4. **可扩展**：单线程到多线程，单Reactor到主从Reactor

### 适用场景

- 高并发连接（万级以上）
- 连接生命周期长
- 业务处理相对简单快速
- 需要高吞吐量、低延迟

### 常见框架

| 语言 | 框架 |
|------|------|
| Java | Netty, Mina |
| C++ | Muduo, libevent |
| Python | Twisted, Tornado |
| Node.js | 内置事件循环 |

# IO

## IO基本理解要求

① IO 是什么（本质）
② 阻塞模型（为什么会卡）
③ 缓冲与流（为什么要包一层）
④ IO 模型演进（BIO → NIO → AIO）
⑤ IO 在后端中的真实使用方式

## IO是什么

在计算机中，**输入/输出（即IO）是指信息处理系统（比如计算机）和外部世界（可以是人或其他信息处理系统）的通信。**

***从计算机架构上来讲，任何涉及到计算机核心（CPU和内存）与其他设备间的数据转移的过程就是IO。***

IO的主体是其应用程序的运行态，即进程，特别强调的是我们的应用程序其实并不存在实质的IO过程，真正的IO过程是操作系统的事情，这里把**应用程序的IO操作分为两种动作：IO调用和IO执行**。

IO调用是由进程发起，IO执行是操作系统的工作。因此，更准确些来说，此时所说的IO是应用程序对操作系统IO功能的一次触发，即IO调用。



**IO调用**

以一个进程的输入类型的IO调用为例，它将完成或引起如下工作内容：

1. **进程向操作系统请求外部数据**
2. **操作系统将外部数据加载到内核缓冲区**
3. **操作系统将数据从内核缓冲区拷贝到进程缓冲区**
4. **进程读取数据继续后面的工作**

**IO操作**

网络IO为例子，一个read发生的事件：

1. **socket.read()  进程询问是否有数据，若没有，则阻塞，等待系统通知**
2. **网卡接收数据，将数据放在指定内存，发起硬打断（通知CPU）                                            （网卡->内核空间.内核缓存）**
3. **硬打断很快（通知CPU、CPU记录），CPU获得通知后，继续完成当前任务，不切换上下文**
4. **软打断，CPU空闲后，切换上下文，处理数据，分析是哪个进程的数据，通知对应进程     （内核缓存->内核空间.socket 缓存）**
5. **CPU将数据从内核空间copy到用户空间                                                                                     （socket 缓存->用户空间.用户缓存）**

## 同步、异步，堵塞、非堵塞

**核心定义：两个维度的区别**

我们可以把一个操作（比如读取文件、请求网络）看作是“调用者”和“被调用者”之间的互动。

- **同步 (Synchronous) / 异步 (Asynchronous)**：关注的是**消息通知机制**。
  - **同步**：调用者主动等待结果。如果不返回结果，我就不干别的事。
  - **异步**：调用者发出请求后直接去做别的事。被调用者通过“回调”或“通知”来告知调用者结果。
- **阻塞 (Blocking) / 非阻塞 (Non-blocking)**：关注的是**调用者在等待时的状态**。
  - **阻塞**：在结果返回前，当前线程被挂起（卡住了），什么都干不了。
  - **非阻塞**：在结果返回前，当前线程不会被挂起，可以继续执行。

同步、异步表示：是否立刻返回		阻塞、非阻塞表示：是否挂起

### 总结对比表

| **组合方式**   | **调用者的状态** | **如何得知结果**     | **效率评价**           |
| -------------- | ---------------- | -------------------- | ---------------------- |
| **同步阻塞**   | 挂起（卡住）     | 直到拿到结果才返回   | 简单，但吞吐量低       |
| **同步非阻塞** | 运行中           | 主动轮询（不停地问） | 浪费 CPU 资源          |
| **异步阻塞**   | 挂起（卡住）     | 等待通知             | 逻辑上存在，实际少用   |
| **异步非阻塞** | 运行中           | 被动接收通知（回调） | **性能巅峰**，实现复杂 |



## 五种IO模型

### IO模型详解

**1. 阻塞 I/O (Blocking I/O)**

这是最常见的模型。当用户进程调用 `recvfrom` 等系统调用时，进程会进入阻塞状态，直到数据完全准备好并被拷贝到用户空间缓冲区。

- **特点**：开发简单，但在处理多个连接时，需要为每个连接创建一个线程，资源开销大。
- **表现**：两阶段全程阻塞。

```
从前有一条小河，河里有许多条鱼，一个叫张三的少年就很喜欢钓鱼，他带着自己的鱼竿就去钓鱼了，但张三这个人很固执，只要鱼没上钩，张三就一直等着，什么都不干，死死的盯着鱼漂，只有鱼漂动了，张三才会动，然后把鱼钓上来，钓上来之后，张三就又会重复之前的动作，一动不动的等待鱼儿上钩。
```

**2. 非阻塞 I/O (Non-blocking I/O)**

进程发起 I/O 请求后，如果数据还没准备好，内核会立即返回一个错误（如 `EWOULDBLOCK`）。进程需要不断地轮询（Polling）内核，询问数据是否就绪。

- **特点**：进程不会被挂起，可以执行其他任务，但轮询操作会大量消耗 CPU 资源。
- **表现**：第一阶段非阻塞（但会持续询问），第二阶段（拷贝数据）仍然阻塞。

```
而此时走过来一个李四，李四这名少年也很喜欢钓鱼，但李四和张三不一样，李四左口袋装着《Linux高性能服务器编程》，右口袋装着一本《算法导论》，左手拿手机，右手拿了一根鱼竿，李四拿了钓鱼凳坐下之后，李四就开始钓鱼了，但李四不像张三一样，固执的死盯着鱼漂看，李四一会看会儿左口袋的书，一会玩会手机，一会儿又看算法导论，一会又看鱼漂，所以李四一直循环着前面的动作，直到循环到看鱼漂时，发现鱼漂已经动了好长时间了，此时李四就会把鱼儿钓上来，之后继续重复循环前面的动作。
```

**3. I/O 多路复用 (I/O Multiplexing)**

这是目前高并发网络服务器（如 Redis, Nginx）的核心。通过 `select`、`poll` 或 `epoll` 系统调用，一个线程可以监听多个文件描述符（FD）。当某个 FD 就绪时，才调用真正的 I/O 操作。

- **特点**：单个线程就能处理成千上万个连接。
- **表现**：进程在调用 `select/epoll` 时阻塞，第一阶段其他时候非堵塞，但在处理具体数据拷贝时也非常高效。

```
此时又来了一个赵六的人，赵六和前面的三个人都不一样，赵六是个小土豪，赵六手里拿了一堆鱼竿，目测有几百根鱼竿，赵六到达河边，首先就把几百根鱼竿每隔几米插上去，总共插了好几百米的鱼竿，然后赵六就依次遍历这些鱼竿，哪个鱼竿上的鱼漂动了，赵六就把这根鱼竿上的鱼钓上来，然后接下来赵六就又继续重复之前遍历鱼竿的动作进行钓鱼了。
```

多路复用是现在IO模型中最主要采用的模型（Redis、Netty、Nginx）。

多路复用和信号驱动都由系统返回一个通知，<font color='blue'>**但多路复用的核心作用多了一个“管家”，用于接收多个文件描述符FD的返回通知。并在进程唤醒后告知，线程进入非堵塞状态，处理所有返回的通知。**</font>

**这里的“进程在调用 `select/epoll` 时阻塞”，指的是查询的epoll线程阻塞，而原本的线程可以做其他事，这种方式更像信号驱动（多线程/线程池做法，Nginx、Netty、Golang ）；**

**或是调用epoll_wait后进入阻塞，有数据进入，epoll_wait返回，线程又变成非阻塞状态。这种单线程流派更像是`同步阻塞`（单线程做法，Redis、Node.Js）**

用于托管FD的内核“管家”演进：**`select -> poll -> epoll`**

**4. 信号驱动 I/O (Signal-driven I/O)**

进程预先向内核注册一个信号处理函数，然后立即返回，不阻塞。当内核准备好数据时，会发送一个信号（SIGIO）给进程，进程在信号处理函数中调用 I/O 函数读取数据。

- **特点**：在等待阶段不阻塞，但在收到信号后的数据拷贝阶段仍需阻塞。
- **应用**：在实际开发中应用相对较少。

```
此时又来了一个王五少年，王五就拿着他自己的iphone14pro max和一根鱼竿外加一个铃铛，然后就来钓鱼了，王五把铃铛挂到鱼竿上，等鱼上钩的时候，铃铛就会响，王五根本不看鱼竿，就一直玩自己的iphone，等鱼上钩的时候，铃铛会自动响，王五此时再把鱼儿钓上来就好了，之后王五又继续重复前面的动作，只要铃铛不响，王五就一直玩手机，只有铃铛响了，王五才会把鱼钓上来。
```

信号驱动已经非常接近真正的异步，唯一的区别就在于还需要自己copy数据，即例子中王五需要自己提鱼钩

**5. 异步 I/O (Asynchronous I/O)**

这是真正的异步模型。用户进程调用 `aio_read` 后直接返回。内核会自动完成“等待数据”和“拷贝数据”这两个阶段，全部完成后才通知进程。

- **特点**：效率最高，进程在整个过程中完全不阻塞。
- **表现**：两阶段全异步。

```
然后又来了一个钱七，钱七比赵六还有钱，钱七是上市公司的CEO，钱七有自己的司机，钱七不喜欢钓鱼，但钱七喜欢吃鱼，所以钱七就把自己的司机留在了岸边，并且给了司机一个电话和一个桶，告诉司机，等你把鱼钓满一桶的时候，就给我打电话，然后我就从公司开车过来接你，所以钱七就直接开车回公司开什么股东大会去了，而他的司机就被留在这里继续钓鱼了。
```

### 同步和异步的根本区别

同步和异步的根本区别在于：

<font color='red'>数据copy（内核到用户空间/用户到内核）的过程必须中断（堵塞），由进程自己手动调用sendto()、recvfrom()，在此之前是可以和异步相同的。而异步是全部完成之后再通知进程</font>

而等待数据的过程，可以是非阻塞的，所以同步非阻塞的三种模型在第一阶段都可以非堵塞

------

**五种模型对比表**

| **模型**         | **第一阶段（等待数据）**           | **第二阶段（拷贝数据）** | **I/O 类型** |
| ---------------- | ---------------------------------- | ------------------------ | ------------ |
| **阻塞 I/O**     | 阻塞                               | 阻塞                     | 同步         |
| **非阻塞 I/O**   | 轮询（不阻塞）                     | 阻塞                     | 同步         |
| **I/O 多路复用** | 阻塞（仅在 select/poll 上）/不堵塞 | 阻塞                     | 同步         |
| **信号驱动 I/O** | 异步（通知）                       | 阻塞                     | 同步         |
| **异步 I/O**     | 异步                               | 异步                     | **异步**     |

## IO模型、设计模式的对应

**底层的 I/O 模型**（操作系统层面）与**上层的设计模式**（应用架构层面）之间的对应关系

| **操作系统 I/O 模型** | **对应的网络编程设计模式**               | **典型代表 / 库**                      |
| --------------------- | ---------------------------------------- | -------------------------------------- |
| **阻塞 I/O (BIO)**    | **Thread-per-connection** (每连接一线程) | 早期的 Java BIO, Apache (Prefork)      |
| **非阻塞 I/O (NIO)**  | 无特定模式（通常作为轮询使用）           | 很少直接作为架构模式                   |
| **I/O 多路复用**      | **Reactor 模式**                         | **Redis, Netty, Nginx, Node.js**       |
| **信号驱动 I/O**      | 极少使用                                 | 无主流模式                             |
| **异步 I/O (AIO)**    | **Proactor 模式**                        | **Windows IOCP, Java AIO, Boost.Asio** |

# NIO

## 文档链接

[CSDN.  java NIO详解](https://blog.csdn.net/qq_33807380/article/details/134190775?spm=1001.2014.3001.5506)



BIO使用Stream流读取数据，如字节流、字符流、打印流等。NIO的核心组件包括：Channel通道、Selector选择器、Buffer缓冲区

<img src="C:\Users\t'c\Desktop\Markdowns\img\NIO.png" style='zoom:40%'> 

java NIO在IO模式上，本质上是同步非阻塞+多路复用的组合，因此会有selector。selector是对select、poll、epoll的封装，用于管理每个Channel的事务发生情况。Channel在内核层次是对文件描述符FD的封装，Buffer即缓冲区，如socket的缓存等。

## NIO工作流程

1. 创建 Selector：Selector 是 NIO 的核心组件之一，它可以同时监听多个通道上的 I/O 事件，并且可以通过 select() 方法等待事件的发生。
2. 注册 Channel：通过 Channel 的 register() 方法将 Channel 注册到 Selector 上，这样 Selector 就可以监听 Channel 上的 I/O 事件。
3. 等待事件：调用 Selector 的 select() 方法等待事件的发生，当有事件发生时，Selector 就会通知相应的线程进行处理。
4. 处理事件：根据不同的事件类型，调用对应的处理逻辑。
5. 关闭 Channel：当 Channel 不再需要使用时，需要调用 Channel 的 close() 方法关闭 Channel，同时也需要调用 Buffer 的 clear() 方法清空 Buffer 中的数据，以释放内存资源。

## NIO核心组件

### Channel(通道)

Channel 是应用程序与操作系统之间交互事件和传递内容的直接交互渠道，应用程序可以从管道中读取操作系统中接收到的数据，也可以向操作系统发送数据。Channel和传统IO中的Stream很相似，其主要区别为：通道是双向的，通过一个Channel既可以进行读，也可以进行写；而Stream只能进行单向操作，通过一个Stream只能进行读或者写，比如InputStream只能进行读取操作，OutputStream只能进行写操作。
**Channel实现类**

- **FileChannel** 本地文件IO通道，从文件中读写数据。

  ```java
  1.获取文件通道，通过 FileChannel 的静态方法 open() 来获取，获取时需要指定文件路径和文件打开方式
  FileChannel channel = FileChannel.open(Paths.get(fileName), StandardOpenOption.READ);
  
  2.创建字节缓冲区
  ByteBuffer buf = ByteBuffer.allocate(1024);
  
  3.读/写操作
  (1)、读操作
  // 循环读取通道中的数据，并写入到 buf 中
  while (channel.read(buf) != -1){ 
      // 缓存区切换到读模式
      buf.flip(); 
      // 读取 buf 中的数据
      while (buf.position() < buf.limit()){ 
      	// 将buf中的数据追加到文件中
          text.append((char)buf.get());
      }
      // 清空已经读取完成的 buffer，以便后续使用
      buf.clear();
  }
  (2)、写操作
  // 循环读取文件中的数据，并写入到 buf 中
  for (int i = 0; i < text.length(); i++) {
      // 填充缓冲区，需要将 2 字节的 char 强转为 1 自己的 byte
      buf.put((byte)text.charAt(i)); 
      // 缓存区已满或者已经遍历到最后一个字符
      if (buf.position() == buf.limit() || i == text.length() - 1) { 
          // 将缓冲区由写模式置为读模式
          buf.flip(); 
          // 将缓冲区的数据写到通道
          channel.write(buf); 
          // 清空已经读取完成的 buffer，以便后续使用
          buf.clear(); 
      }
  }
  
  4.将数据刷出到物理磁盘
  channel.force(false);
  
  5.关闭通道
  channel.close();
  ```

- **SocketChannel** 网络套接字IO通道，TCP协议，客户端通过 SocketChannel 与服务端建立TCP连接进行通信交互。与传统的Socket操作不同的是，SocketChannel基于非阻塞IO模式，可以在同一个线程内同时管理多个通信连接，从而提高系统的并发处理能力。

  ```java
  1.打开一个 SocketChannel 通道
  SocketChannel channel = SocketChannel.open();
  
  2.连接到服务端
  channel.connect(new InetSocketAddress("localhost", 9001));
  
  3.分配缓冲区
  ByteBuffer buf = ByteBuffer.allocate(1024); 
  
  4.配置是否为阻塞方式（默认为阻塞方式）
  channel.configureBlocking(false); // 配置通道为非阻塞模式
  
  5.将channel的连接、读、写等事件注册到selector中，每个chanel只能注册一个事件，最后注册的一个生效,
  同时注册多个事件可以使用"|"操作符将常量连接起来
  Selector selector = Selector.open();
  channel.register(selector, SelectionKey.OP_CONNECT | SelectionKey.OP_WRITE | SelectionKey.OP_READ);
  
  6.与服务端进行读写操作
  channel.read(buf);
  channel.write(buf);
  
  7.关闭通道
  channel.close();
  ```

- **ServerSocketChannel** 网络套接字IO通道，TCP协议，服务端通过ServerSocketChannel监听来自客户端的连接请求，并创建相应的SocketChannel对象进行通信交互。ServerSocketChannel同样也是基于非阻塞IO模式，可以在同一个线程内同时管理多个通信连接，从而提高系统的并发处理能力。

  ```java
  1.打开一个 ServerSocketChannel 通道
  ServerSocketChannel serverChannel = ServerSocketChannel.open();
  
  2.绑定本地端口
  serverChannel.bind(new InetSocketAddress(9001));
  
  3.配置是否为阻塞方式（默认为阻塞方式）
  serverChannel.configureBlocking(false); // 配置通道为非阻塞模式
  
  4.分配缓冲区
  ByteBuffer buf = ByteBuffer.allocate(1024); 
  
  5.将serverChannel 的连接、读、写等事件注册到selector中，每个chanel只能注册一个事件，最后注册的一个生效,
  同时注册多个事件可以使用"|"操作符将常量连接起来
  Selector selector = Selector.open();
  serverChannel.register(selector, SelectionKey.OP_ACCEPT| SelectionKey.OP_WRITE | SelectionKey.OP_READ);
  
  6.与客服端进行读写操作
  serverChannel.read(buf);
  serverChannel.write(buf);
  
  7.关闭通道
  serverChannel.close();
  ```

- **DatagramChannel** DatagramChannel是Java NIO中对UDP协议通信的封装。通过DatagramChannel对象，我们可以实现发送和接收UDP数据包。它与TCP协议不同的是，UDP协议没有连接的概念，所以无需像SocketChannel一样先建立连接再开始通信。

  ```java
  1.打开一个 DatagramChannel 通道
  DatagramChannel channel = DatagramChannel.open();
  
  2.分配缓冲区
  ByteBuffer buf = ByteBuffer.allocate(1024); 
  
  3.配置是否为阻塞方式（默认为阻塞方式）
  channel.configureBlocking(false); // 配置通道为非阻塞模式
  
  4.与客服端进行读写操作
  buffer.flip();
  // 发送消息给服务端
  channel.send(buffer, new InetSocketAddress("localhost", 9001));
  buffer.clear();
  // 接收服务端的响应信息
  channel.receive(buffer);
  buffer.flip();
  // 打印出响应信息
  while (buffer.hasRemaining()) {
       System.out.print((char) buffer.get());
  }
  buffer.clear();
  
  7.关闭通道
  channel.close();
  ```

channel.read 、channel.write 常用于文件IO，参数为`缓冲区对象`或者`缓冲区对象,超时时间`。

channel.receive、channel.send 则常用于网络IO中，但read、write同样可以使用。

### Buffer(缓冲区)

**缓冲区属性：**

1. capacity(容量)：表示 Buffer 所占的内存大小，capacity不能为负，并且创建后不能更改。
2. limit(限制)：表示 Buffer 中可以操作数据的大小，limit不能为负，并且不能大于其capacity。写模式下，表示最多能往 Buffer 里写多少数据，即 limit 等于 Buffer 的capacity。读模式下，表示你最多能读到多少数据，其实就是能读到之前写入的所有数据。
3. position(位置)：表示下一个要读取或写入的数据的索引。缓冲区的位置不能为负，并且不能大于其限制。初始的 position 值为 0，最大可为 capacity – 1。当一个 byte、long 等数据写到 Buffer 后， position 会向前移动到下一个可插入数据的 Buffer 单元。
4. mark(标记)：表示记录当前 position 的位置。可以通过 reset() 恢复到 mark 的位置。

![](C:\Users\t'c\Desktop\Markdowns\img\buffer.attribute.png) 

**常用方法：**

buffer.flip 这个方法将channel从写切换为读模式，原理是将此时的position作为limit，从头开始读

buffer.clear 则是从读切换为写

mark()：对缓冲区设置标记；

reset()：将位置 position 转到以前设置的mark 所在的位置；

### Selector(选择器)

Selector 提供了选择已经就绪的任务的能力，Selector会不断的轮询注册在上面的所有channel，进行后续的IO操作。只需通过一个单独的线程就可以管理多个channel，从而管理多个网络连接。这就是Nio与传统I/O最大的区别，不用为每个连接都去创建一个线程。

**使用案例：**

```java
1.获取选择器
Selector selector = Selector.open();

2.通道注册到选择器，进行监听
serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);

3.获取可操作的 Channel
selector.select();

4.获取可操作的 Channel 中的就绪事件集合
Set<SelectionKey> keys = selector.selectedKeys();

5.处理就绪事件
while (keys.iterator().hasNext()){
	SelectionKey key = keys.iterator().next();
    keyIterator.remove(); //移除当前的key
	if (!key.isValid()){
		continue;
	}
    if (key.isAcceptable()){
		accept(key);
	}
	if(key.isReadable()){
		read(key);
	}
	if (key.isWritable()){
		write(key);
	}
}
```

**注意点：**

selector.select() 只是查询是否有返回结果，这个方法的返回值是可操作的Channel的个数，决定是否可以处理

selector.selectedKeys() 查询可操作的Channel本身，返回 Set\<SelectKey>

Key.isValid() 表示Channel是否已经关闭、Key被cancel



**SelectionKey事件类型：**
每个 Channel向Selector 注册时，都会创建一个 SelectionKey 对象，通过 SelectionKey 对象向Selector 注册，且 SelectionKey 中维护了 Channel 的事件。常见的四种事件如下：

OP_READ：当操作系统读缓冲区有数据可读时就绪。
OP_WRITE：当操作系统写缓冲区有空闲空间时就绪。
OP_CONNECT：当 SocketChannel.connect()请求连接成功后就绪，该操作只给客户端使用。
OP_ACCEPT：当接收到一个客户端连接请求时就绪，该操作只给服务器使用。

一个Channel可注册多个事件，每个事件使用 `|` 分隔开，详见  [Channel(通道)](###Channel(通道)) 的SocketChannel部分中的示例代码。

## 完整代码示例

服务端

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.Iterator;
import java.util.Set;

public class NioServiceTest {
    private Selector selector;
    private ServerSocketChannel serverSocketChannel;
    private ByteBuffer readBuffer = ByteBuffer.allocate(1024);//调整缓冲区大小为1024字节
    private ByteBuffer sendBuffer = ByteBuffer.allocate(1024);
    String str;

    public NioServiceTest(int port) throws IOException {
        // 打开服务器套接字通道
        this.serverSocketChannel = ServerSocketChannel.open();
        // 服务器配置为非阻塞 即异步IO
        this.serverSocketChannel.configureBlocking(false);
        // 绑定本地端口
        this.serverSocketChannel.bind(new InetSocketAddress(port));
        // 创建选择器
        this.selector = Selector.open();
        // 注册接收连接事件
        this.serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
    }

    public void handle() throws IOException {
        // 无限判断当前线程状态，如果没有中断，就一直执行while内容。
        while(!Thread.currentThread().isInterrupted()){
            // 获取准备就绪的channel
            if (selector.select() == 0) {
                continue;
            }

            // 获取到对应的 SelectionKey 对象
            Set<SelectionKey> keys = selector.selectedKeys();
            Iterator<SelectionKey> keyIterator = keys.iterator();
            // 遍历所有的 SelectionKey 对象
            while (keyIterator.hasNext()){
                // 根据不同的SelectionKey事件类型进行相应的处理
                SelectionKey key = keyIterator.next();
                if (!key.isValid()){
                    continue;
                }
                if (key.isAcceptable()){
                    accept(key);
                }
                if(key.isReadable()){
                    read(key);
                }
                // 移除当前的key	
                keyIterator.remove();
            }
        }
    }

    /**
     * 客服端连接事件处理
     *
     * @param key
     * @throws IOException
     */
    private void accept(SelectionKey key) throws IOException {
        SocketChannel socketChannel = this.serverSocketChannel.accept();
        socketChannel.configureBlocking(false);
        // 注册客户端读取事件到selector
        socketChannel.register(selector, SelectionKey.OP_READ);
        System.out.println("client connected " + socketChannel.getRemoteAddress());
    }

    /**
     * 读取事件处理
     *
     * @param key
     * @throws IOException
     */
    private void read(SelectionKey key) throws IOException{
        SocketChannel socketChannel = (SocketChannel) key.channel();
        //清除缓冲区，准备接受新数据
        this.readBuffer.clear();
        int numRead;
        try{
            // 从 channel 中读取数据
            numRead = socketChannel.read(this.readBuffer);
        }catch (IOException e){
            System.out.println("read failed");
            key.cancel();
            socketChannel.close();
            return;
        }
        str = new String(readBuffer.array(),0,numRead);
        System.out.println("read String is: " + str);
    }

    public static void main(String[] args) throws Exception {
        System.out.println("sever start...");
        new NioServiceTest(8000).handle();
    }
}
```

客户端

```java
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.util.Iterator;
import java.util.Scanner;
import java.util.Set;

public class EchoClient {
    private SocketChannel socketChannel;
    private Selector selector;
    private ByteBuffer outputBuffer;

    public EchoClient(String host, int port) throws Exception {
        // 1️⃣ 打开 SocketChannel 并设置非阻塞
        socketChannel = SocketChannel.open();
        socketChannel.configureBlocking(false);

        // 2️⃣ 打开 Selector
        selector = Selector.open();

        // 3️⃣ 尝试连接服务器
        boolean connected = socketChannel.connect(new InetSocketAddress(host, port));

        // 4️⃣ 根据 connect 返回值注册事件
        if (connected) {
            System.out.println("connect ok immediately");
            socketChannel.register(selector, SelectionKey.OP_WRITE);
        } else {
            System.out.println("connect pending, waiting OP_CONNECT");
            socketChannel.register(selector, SelectionKey.OP_CONNECT);
        }

        // 5️⃣ 分配输出缓冲区
        outputBuffer = ByteBuffer.allocate(1024);
    }

    public void send() throws Exception {
        Scanner scanner = new Scanner(System.in);

        while (!Thread.currentThread().isInterrupted()) {
            // 6️⃣ 等待 selector 事件
            if (selector.select() == 0) {
                continue;
            }

            Set<SelectionKey> keys = selector.selectedKeys();
            Iterator<SelectionKey> it = keys.iterator();

            while (it.hasNext()) {
                SelectionKey key = it.next();
                it.remove(); // ⚠️ 必须，否则 selectedKeys 永远不清空

                SocketChannel sc = (SocketChannel) key.channel();

                // 7️⃣ 处理连接完成事件
                if (key.isConnectable()) {
                    if (sc.finishConnect()) {
                        System.out.println("connect finished");
                        sc.register(this.selector, SelectionKey.OP_WRITE);
                        // 连接完成后监听写事件
                    } else {
                        System.out.println("finishConnect failed");
                    }
                }

                // 8️⃣ 处理写事件
                else if (key.isWritable()) {
                    System.out.print("Input Message: ");
                    String input = scanner.nextLine();

                    outputBuffer.clear();
                    outputBuffer.put(input.getBytes());
                    outputBuffer.flip();

                    while (outputBuffer.hasRemaining()) {
                        sc.write(outputBuffer);
                    }
                }
            }
        }

        scanner.close();
        socketChannel.close();
        selector.close();
    }
}

```


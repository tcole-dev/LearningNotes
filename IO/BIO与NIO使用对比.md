# BIO与NIO使用对比（Java）

## 概述

Java中的IO模型主要分为BIO（Blocking I/O，阻塞式IO）和NIO（Non-blocking I/O，非阻塞IO）。本文从**实际使用角度**对比两者的区别。

---

## 一、核心概念对比

| 对比维度 | BIO | NIO |
|---------|-----|-----|
| **通信模式** | 面向流（Stream） | 面向缓冲区（Buffer） |
| **阻塞特性** | 阻塞式 | 非阻塞式 |
| **连接处理** | 一连接一线程 | 一线程处理多连接 |
| **核心组件** | InputStream/OutputStream | Channel、Buffer、Selector |
| **适用场景** | 连接数少且固定 | 连接数多且短连接 |

---

## 二、BIO使用方式

### 2.1 BIO服务端示例

```java
import java.io.*;
import java.net.*;

public class BioServer {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(8080);
        System.out.println("BIO Server started on port 8080");

        while (true) {
            // 阻塞等待客户端连接
            Socket socket = serverSocket.accept();
            System.out.println("Client connected: " + socket.getRemoteSocketAddress());

            // 为每个连接创建新线程处理
            new Thread(() -> {
                try (
                    BufferedReader reader = new BufferedReader(
                        new InputStreamReader(socket.getInputStream()));
                    PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
                ) {
                    String message;
                    // 阻塞读取数据
                    while ((message = reader.readLine()) != null) {
                        System.out.println("Received: " + message);
                        writer.println("Echo: " + message);
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

### 2.2 BIO客户端示例

```java
import java.io.*;
import java.net.*;

public class BioClient {
    public static void main(String[] args) throws IOException {
        Socket socket = new Socket("localhost", 8080);

        BufferedReader reader = new BufferedReader(
            new InputStreamReader(socket.getInputStream()));
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true);
        BufferedReader console = new BufferedReader(new InputStreamReader(System.in));

        String input;
        while ((input = console.readLine()) != null) {
            writer.println(input);              // 发送消息
            String response = reader.readLine(); // 阻塞等待响应
            System.out.println("Server: " + response);
        }

        socket.close();
    }
}
```

### 2.3 BIO特点总结

- **阻塞调用**：`accept()`、`read()`、`write()` 都会阻塞当前线程
- **线程模型**：每个连接需要一个独立线程处理
- **资源消耗**：连接数增加时，线程数线性增长，内存压力大
- **适用场景**：连接数较少且固定的架构

---

## 三、NIO使用方式

### 3.1 NIO服务端示例

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.Iterator;
import java.util.Set;

public class NioServer {
    public static void main(String[] args) throws IOException {
        // 1. 创建Selector
        Selector selector = Selector.open();

        // 2. 创建ServerSocketChannel并配置非阻塞
        ServerSocketChannel serverChannel = ServerSocketChannel.open();
        serverChannel.configureBlocking(false);
        serverChannel.bind(new InetSocketAddress(8080));

        // 3. 注册ACCEPT事件到Selector
        serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        System.out.println("NIO Server started on port 8080");

        // 4. 事件循环
        while (true) {
            // 阻塞等待就绪事件（非忙等待）
            selector.select();

            Set<SelectionKey> readyKeys = selector.selectedKeys();
            Iterator<SelectionKey> iterator = readyKeys.iterator();

            while (iterator.hasNext()) {
                SelectionKey key = iterator.next();
                iterator.remove(); // 必须移除，避免重复处理

                if (key.isAcceptable()) {
                    handleAccept(key);
                } else if (key.isReadable()) {
                    handleRead(key);
                }
            }
        }
    }

    private static void handleAccept(SelectionKey key) throws IOException {
        ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
        SocketChannel clientChannel = serverChannel.accept();
        clientChannel.configureBlocking(false);
        clientChannel.register(key.selector(), SelectionKey.OP_READ);
        System.out.println("Client connected: " + clientChannel.getRemoteAddress());
    }

    private static void handleRead(SelectionKey key) throws IOException {
        SocketChannel channel = (SocketChannel) key.channel();
        ByteBuffer buffer = ByteBuffer.allocate(1024);

        int bytesRead = channel.read(buffer);
        if (bytesRead == -1) {
            channel.close();
            return;
        }

        buffer.flip();
        byte[] data = new byte[buffer.limit()];
        buffer.get(data);
        String message = new String(data);
        System.out.println("Received: " + message);

        // 回写响应
        buffer.clear();
        buffer.put(("Echo: " + message).getBytes());
        buffer.flip();
        channel.write(buffer);
    }
}
```

### 3.2 NIO客户端示例

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.util.Iterator;
import java.util.Scanner;
import java.util.Set;

public class NioClient {
    public static void main(String[] args) throws IOException {
        SocketChannel socketChannel = SocketChannel.open();
        socketChannel.configureBlocking(false);

        Selector selector = Selector.open();

        // 非阻塞连接
        boolean connected = socketChannel.connect(new InetSocketAddress("localhost", 8080));

        if (connected) {
            socketChannel.register(selector, SelectionKey.OP_WRITE);
        } else {
            socketChannel.register(selector, SelectionKey.OP_CONNECT);
        }

        Scanner scanner = new Scanner(System.in);
        ByteBuffer buffer = ByteBuffer.allocate(1024);

        while (true) {
            selector.select();
            Set<SelectionKey> readyKeys = selector.selectedKeys();
            Iterator<SelectionKey> iterator = readyKeys.iterator();

            while (iterator.hasNext()) {
                SelectionKey key = iterator.next();
                iterator.remove();

                if (key.isConnectable()) {
                    SocketChannel sc = (SocketChannel) key.channel();
                    if (sc.finishConnect()) {
                        sc.register(selector, SelectionKey.OP_WRITE);
                    }
                } else if (key.isWritable()) {
                    System.out.print("Input: ");
                    String input = scanner.nextLine();

                    buffer.clear();
                    buffer.put(input.getBytes());
                    buffer.flip();
                    socketChannel.write(buffer);

                    // 切换为读事件
                    socketChannel.register(selector, SelectionKey.OP_READ);
                } else if (key.isReadable()) {
                    buffer.clear();
                    int bytesRead = socketChannel.read(buffer);
                    if (bytesRead > 0) {
                        buffer.flip();
                        System.out.println("Server: " + new String(buffer.array(), 0, bytesRead));
                    }
                    socketChannel.register(selector, SelectionKey.OP_WRITE);
                }
            }
        }
    }
}
```

### 3.3 NIO特点总结

- **非阻塞调用**：通过Selector实现I/O多路复用
- **线程模型**：单线程可管理多个连接
- **缓冲区操作**：数据读写通过Buffer进行，需手动管理position/limit
- **适用场景**：高并发、大量短连接的架构

---

## 四、核心差异对比

### 4.1 阻塞 vs 非阻塞

```java
// BIO：线程阻塞等待
Socket socket = serverSocket.accept();  // 阻塞直到有连接
int len = inputStream.read(buffer);      // 阻塞直到有数据

// NIO：非阻塞，立即返回
if (selector.select() > 0) {             // 只在有事件时处理
    // 处理就绪的Channel
}
```

### 4.2 流 vs 缓冲区

```java
// BIO：流式读写，单向
InputStream is = socket.getInputStream();   // 只能读
OutputStream os = socket.getOutputStream(); // 只能写

// NIO：缓冲区读写，双向
ByteBuffer buffer = ByteBuffer.allocate(1024);
channel.read(buffer);   // 读入缓冲区
buffer.flip();
channel.write(buffer);  // 从缓冲区写出
```

### 4.3 线程模型

| 模型 | 100连接所需线程 | 10000连接所需线程 |
|------|----------------|------------------|
| BIO | 100个线程 | 10000个线程 |
| NIO | 1个线程（可配置线程池优化） | 1-4个线程 |

---

## 五、选择建议

| 场景 | 推荐方案 |
|------|---------|
| 连接数少（<100）且固定 | BIO（简单易用） |
| 连接数多（>1000）或短连接 | NIO |
| 需要高吞吐、低延迟 | NIO |
| 快速开发原型 | BIO |
| 生产级高并发服务 | NIO（或Netty框架） |

---

## 六、实战建议

1. **BIO优化**：使用线程池替代一连接一线程
   ```java
   ExecutorService executor = Executors.newFixedThreadPool(100);
   executor.submit(() -> handleClient(socket));
   ```

2. **NIO推荐使用Netty**：原生NIO API复杂，Netty提供了更简洁的封装
   ```java
   // Netty服务端
   EventLoopGroup bossGroup = new NioEventLoopGroup(1);
   EventLoopGroup workerGroup = new NioEventLoopGroup();
   ServerBootstrap bootstrap = new ServerBootstrap();
   bootstrap.group(bossGroup, workerGroup)
            .channel(NioServerSocketChannel.class)
            .childHandler(new ChannelInitializer<SocketChannel>() {
                @Override
                protected void initChannel(SocketChannel ch) {
                    ch.pipeline().addLast(new MyHandler());
                }
            });
   ```

---

## 总结

- **BIO**：代码简单直观，适合连接数少的场景，但扩展性差
- **NIO**：学习曲线陡峭，适合高并发场景，扩展性好
- **实际开发**：推荐使用Netty等框架，兼具简洁性和高性能

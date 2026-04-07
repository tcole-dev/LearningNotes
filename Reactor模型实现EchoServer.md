# NIO、Reactor模型实现EchoServer

## NIO和Reactor

NIO是基于多路复用（同步非阻塞）的非阻塞IO API，而Reactor则是一套完整、规范的事件驱动的设计模式。NIO是Reactor的底层实现。两者并不等价，如 **NIO使用`FileChanne`**、**不使用`selector`而是自己轮询** l时，就不属于Reactor模型。

## Reactor模型的基本组件

- Reactor 	负责监听端口，当发生指定IO事件，将其转发到不同Handler
- Acceptor       负责处理新连接的建立（本质上是一个特殊的Handler）
- Handler         负责处理read、write事件

## Reactor的三种模式

- 单Reactor单线程

  只有一个Reactor，所有连接、IO操作、业务处理全部自行完成（Redis）

- 单Reactor多线程

  只有一个Reactor，连接、IO操作都由这一个Reactor完成，业务处理交给线程池

- 主从Reactor多线程

  有一个主Reactor和多个从Reactor，主Reactor只负责监听连接，从Reactor负责监听IO和执行，业务同样可以交给线程池（Netty）

本文中EchoServer的实现为主从Reactor模式。

## EchoServer

### 一个连接的完整触发链

```
服务端初始化完成，开始运行，MainReactor监听OP_ACCEPT
			|
客户端socketChannel.connect()
			|
服务端MainReactor，selector阻塞监听到accept事件
			|
构建acceptor，并调用其run方法（）
			|
acceptor从ServerSocketChannel获取SocketChannel，存入SubReactor的待注册Channel队列，唤醒阻塞监听的selector
			|
SubReactor注册队列中的待注册SocketChannel（OP_READ事件），绑定一个Handler（内含两个Buffer等），用于后续处理其自身的IO
			|
SubReactor继续调用select监听事件
			|
SubReactor通过该SocketChannel的SelectionKey，取出handler，判断事件，调用handler.handleRead、handler.handleWrite
			|
handler中，若可读，则读完（一次触发，多次读出后拼包）后修改事件为OP_WRITE；若可写，则根据是否写完，若写完则修改事件，否则不变
```

### 代码

[https://github.com/tcole-dev/Reactor-EchoServer.git](https://github.com/tcole-dev/Reactor-EchoServer.git)
Redisson是一个常用的Java的Redis客户端，不同于Jedis、Lettuce，Redisson直接将Redis结构封装成了Java是对象，如RMap、RList、RSet等，除此之外，Redisson还提供了多种Redis常用功能实现：分布式锁、Redis多模式适配、看门狗机制、布隆过滤器等。

这里主要叙述Redisson分布式锁相关内容。

## Redisson分布式锁

Redisson客户端配置

```java
@Configuration
public class RedissonConfig {

    @Bean
    public RedissonClient redissonClient(){
        // 配置
        Config config = new Config();
        config.useSingleServer().setAddress("redis://192.168.150.101:6379")
            .setPassword("123321");
        // 创建RedissonClient对象
        return Redisson.create(config);
    }
}

```

Redisson分布式锁的使用

```java
@Resource
private RedissionClient redissonClient;

@Test
void testRedisson() throws Exception{
    //获取锁(可重入)，指定锁的名称
    RLock lock = redissonClient.getLock("anyLock");
    //尝试获取锁，参数分别是：获取锁的最大等待时间(期间会重试)，锁自动释放时间，时间单位
    boolean isLock = lock.tryLock(1,10,TimeUnit.SECONDS);
    //判断获取锁成功
    if(isLock){
        try{
            System.out.println("执行业务");          
        }finally{
            //释放锁
            lock.unlock();
        }   
    }   
}
```

## 看门狗机制

在Redis NT实现分布式锁时，设置的过期时间很难和实际操作所需时间平衡，容易遇到操作未结束但锁已经过期等情况，这时就会引入一个新机制：“看门狗机制（WatchDog）”

看门狗线程会检查是否业务结束、进程挂断，若没有则会隔一段时间（默认 30 / 3 秒）进行`续约`操作，既防止锁提前释放，也避免死锁问题。

- lock()                                                             开启看门狗机制；阻塞重试
- lock.lock(20, TimeUnit.SECONDS)              关闭看门狗，固定时间过期；开启阻塞重试
- lock.tryLock(5, TimeUnit.SECONDS)           无看门狗，固定尝试获取锁时间；不进行重试，立刻返回
- lock.tryLock(5, 15, TimeUnit.SECONDS)     无看门狗，固定 尝试获取锁时间 和 锁过期时间 ，不进行重试



## Redis模式

### 主从Redis

主从Redis架构中，分为Master、Replica（Slave）节点，Master节点只负责写，Replica节点只负责读，所有写操作到达Master节点后会被沿着链路被传递到所有Replica节点，所有节点中的数据完全相同。Master节点挂掉后需要手动进行更换。

主从架构适合多读少写的情况。

### 集群Redis

集群架构中，共有多个Master节点（不同于主从中只有一个Master），每个Master都有多个Replica节点，去中心化，没有绝对中心节点。对于每个Master及其子Replica节点，都符合主从结构，Redis集群采用了哈希槽分片，固定16384个哈希槽，每个槽又被分配到不同的Master。也就是说，每个Master中存储的数据都是不同的。

每个主节点有多个Replica节点，当主节点故障后，会通过选举自动将一个从节点升为主节点。

### 多Master独立节点

多个独立的Master节点，分别存储不同模块的数据，完全独立，说是多Master，更像是多Redis，用户自己选择存储到某一个Redis。



## MultiLock

MultiLock可以实现同时对多个Redis节点进行加锁，只有全部成功加锁，才是真正加锁成功
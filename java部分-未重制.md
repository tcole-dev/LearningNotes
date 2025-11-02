# <font color="orange">Java </font>
## 泛型
#### 1.泛型类、泛型接口、泛型方法
泛型方法使用时，若形参包含泛型类型，编译器会自动识别泛型类型，则需要显式设置泛型类型
#### 2.泛型的实现：

​        类型擦除： 在编译时将泛型转换为Object，若泛型为某一类的子类，则转为对应的父类（边界类型），如< T extends String >，则T编译时会被转换为String类型
​        在泛型类中，静态（static）的变量和方法不能使用泛型变量，因为泛型只能在实例后才能使用，而静态变量和静态方法只能直接通过类调用。

## 反射、注解

**1. 反射：通过Class等类操作其他类和对象，读取信息等，还可以通过forName等方法操作未知的类（在运行时可操作，无需修改代码，使Java获得解释性语言特点）**

```java
Class<?> obj = Class.forName("java.util.Scanner");
System.out.println(obj.getName());
```

**2. 注解：即元数据，用以标注代码、数据，如@Override用以标注该方法为重写方法。此外，还可以自定义注解，用于标注注解的注解为元注解。注解在Spring等框架中还有内嵌依赖等作用。**   

```java
  // @Target为元注解，用以注解“注解”，@Target为限定注解的作用范围，{ElementType.METHOD,ElementType.TYPE}表示方法和类
        @Target({ElementType.METHOD,ElementType.TYPE})
        // @Retention表示限定注解的保留策略（什么时候有效），RetentionPolicy.RUNTIME表示在编译、运行时都存在，可用反射机制读取
        @Retention(RetentionPolicy.RUNTIME)
        // @interface表示定义一个注解，注解，即元数据，用以标注数据作用，如@Override标记方法重写
        public @interface newtarget {
        }
```



## IO流
**1. IO流：字节流（InputStream（FileInputStream等实现）、OutputStream（FileOutStream等实现））；字符流（Reader（FileReader等实现）、Writer（FileWriter等实现））；缓冲流（字节缓冲流、字符缓冲流）**

**缓冲流：字节---BufferedInputStream、BufferedOutputStream    字符---BufferedReader、BufferedWriter**

**2. 打印流：类似C语言的文件操作方式**

```java
// 创建PrintStream，输出到文件（第二个参数true表示自动刷新）
        try (PrintStream ps = new PrintStream("output.txt", "UTF-8", true)) {
            
            // 输出各种数据类型
            ps.print("整数：");
            ps.println(100); // 自动换行
            
            ps.print("布尔值：");
            ps.println(true);
            
            ps.print("对象：");
            ps.println(new Object()); // 输出对象的toString()
            
            // 格式化输出（类似C语言的printf）
            ps.printf("格式化输出：姓名=%s, 年龄=%d, 成绩=%.2f", "张三", 20, 95.5);
            
        } catch (Exception e) {
            e.printStackTrace();
        }
```



**3. IO流转换：InputStreamReader------为Reader的子类，字符流体系，可将字节流转为字符流**

```java
 // 关键：使用InputStreamReader指定编码，再包装到BufferedReader
        try (InputStreamReader isr = new InputStreamReader(
                new FileInputStream("file.txt"),  // 字节流
                "UTF-8"                          // 明确指定编码
             );
             BufferedReader br = new BufferedReader(isr)) {  // 缓冲字符流
            
            String line;
            while ((line = br.readLine()) != null) {
                System.out.println(line);
            }
            
        } catch (IOException e) {
            e.printStackTrace();
        }
```



## Java的多线程
### Java的多线程实现方法：
1. 继承Thread类，并重写run方法，run方法中的为要执行的代码。实例继承Thread类的类后，使用.start()方法开启线程
2. 实现Runable接口，并重写run方法，创建Thread类的对象，并将实现Runable接口的类的实例后对象作为参数传递给Thread的构造方法，调用Thread对象的start方法可开启线程  （推荐）
3. 实现 Callable 和 Future 接口，这种方法可以获取线程执行后的返回值，这是前两种方法所不具备的特性。
### lambda表达式和函数式接口
**Java中的lambda表达式构成为： (参数)->{代码块}**    

```java
 // 如 () -> {System.out.println("Hello World!");}
```

**函数式接口  是只包含一个抽象方法的接口，但可以包含多个默认方法和静态方法**

Java中的函数式的使用基于lambda表达式，设计初衷就是为了适配 "函数式编程" 的思想 —— 将函数作为参数传递，或者将函数作为返回值。

```java
// 这是一个函数式接口（只有一个抽象方法）
        @FunctionalInterface
        interface MyFunctionalInterface {
        void doSomething(String s);
        }


        public class Main {
        public static void main(String[] args) {


        // 传统方式：使用匿名内部类
        MyFunctionalInterface obj1 = new MyFunctionalInterface() {
            @Override
            public void doSomething(String s) {
                System.out.println("传统方式: " + s);
            }
        };
        


        // 使用lambda表达式（简洁得多）
        MyFunctionalInterface obj2 = (s) -> System.out.println("Lambda方式: " + s);
        
        // 两者用法完全相同
        obj1.doSomething("Hello");
        obj2.doSomething("World");
        }
    }
```

Java 标准库中提供了很多常用的函数式接口，如Runnable、Consumer、Supplier、Function等，它们都可以直接用 lambda 表达式来实例化。   
在某种意义上来说，使用函数式接口的场景中可以直接使用lambda表达式代替，如，Thread的构造方法需要有一个实现Runnable接口的参数，而Runnable是一个函数式接口，因此Thread构造方法的参数可以是一个无参无返回值的lambda表达式和一个可有可无的字符串（线程名字）。<font color="skyblue">如何理解：系统自动判定，lambda表达式的签名符合，重写Runnable接口中的run方法-->生成匿名内部类作为Thread构造方法的参数</font>    

```java
 Thread SonThread = new Thread( ()->{System.out.println("hello world!);} );
 SonThread.start();
```




## 线程安全
**同步：Java中的同步操作可以由synchronized关键字实现，在需要加锁的方法访问修饰符后加synchronized关键字即可** 

```java
public synchronized void sale() {
        this.num--;
    }
    // 在同一时间，只有一个线程能访问该对象 
```



**同步代码块：使用synchronized关键字修饰后，锁住的是整个对象，需要单独锁住某个方法甚至方法中的一段代码，可以使用同步代码块** 

```java
synchronized(lock) {
        this.num--;
    }
```

lock可以是任何对象。synchronized关键字使用时必须关联某一个对象，在使用关键字修饰时，不用显式设置，但在修饰代码块时，必须用()显式设置一个锁住的对象，这个对象没有限制，因此可以设置一个Object的私有成员用于锁。
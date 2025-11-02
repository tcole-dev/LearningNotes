## web开发流程

### Nginx服务器

Nginx：主流反向代理和分发静态资源服务器，减小web服务器压力

正向代理：为客户端代理，客户端->代理服务器->服务器，由代理服务器中转，隐藏客户端IP地址 --- VPN技术

反向代理：为服务器代理，服务器->代理服务器->客户端，向服务器发送请求时，请求先发送到反向代理服务器，分发静态资源，再将请求转发到实际的服务器（或自主选择多服务器中的某个服务器）

### Tomcat

Java web开发的常用web服务器（Servlet容器），负责监听端口，接收请求并处理（生成Request、Response等对象），再将请求按需求发送到不同Servlet类，执行对应程序后返回响应，可类比为酒店前台

### Servlet API

Servlet是在Java EE（Jakarta EE）之上实现的用于http通信的一系列API、规范，Servlet类本身不监听端口，只能在Servlet容器（如Tomcat等）中使用，负责具体实现对应的业务要求，通过Servlet API中的@webServlet注解，可将Servlet类映射到指定路径

```java
@WebServlet(urlPatterns = "/hello")
public class HelloServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // 创建验证码
        LineCaptcha lineCaptcha = CaptchaUtil.createLineCaptcha(200, 100);
        // 输出验证码
        lineCaptcha.write(resp.getOutputStream());
    }
}
```

通过@webServlet映射，在浏览器访问`/hello`路径时，Tomcat会调用HelloServlet类并运行doGet方法

#### doGet、doPost

这两个方法是Servlet接口中用于处理GET、POST请求的核心方法，参数分别是`请求`和`响应`，由Tomcat创建，在写这两个方法时需要@Override重写。

在提交表单`form`元素时，若HTML中设置表单提交方式为GET，则提交的内容会作为url的参数直接显示。若提交方式为POST，需要重写doPOST方法，或可在doPost方法中直接调用上面写的doGet方法

### HTTP协议

http协议是TCP/IP中的应用层协议，用于浏览器于服务器通信。https是http的增强版，即HTTP+TLS/SSL，TLS/SSL是保证传输安全的协议，TLS协议是SSL协议的后续版本

#### 请求、响应

请求：请求行、请求头、请求体

- 请求头：包含请求方法、请求 URL、HTTP 版本，格式为：[方法] [URL] [版本]		

  如：`GET  /index/users?id=123  HTTP/1.1`

- 请求行：键值对形式的元数据，描述请求的附加信息，由客户端发送。

  ```
  Host：			服务器域名（如 Host: www.example.com）。
  User-Agent：		客户端标识（如浏览器型号、APP 版本）。
  Accept：			客户端可接受的响应数据格式（如 Accept: application/json）。
  Content-Type：	请求体的数据类型（如 Content-Type: application/x-www-form-urlencoded 表示表单数据）。
  Cookie：			客户端存储的 Cookie 信息，用于身份识别。
  ```

- 请求体：可选，仅在需要提交数据时存在（如 POST、PUT 方法），存放具体数据。

  ```
  示例（表单提交的 POST 请求体）： username=admin&password=123456
  ```

响应：状态行、响应头、响应体

- 状态行：包含 HTTP 版本、状态码、状态描述，格式为：  [版本] [状态码] [描述]

​	如：`HTTP/1.1 200 OK`	表示服务器用 HTTP/1.1 版本响应，请求成功。

- 响应头：服务器返回的元数据，描述响应的附加信息。

  ```
  Content-Type：	响应体的数据类型（如 Content-Type: text/html 表示HTML页面，application/json 表示JSON数据）。
  Content-Length：	响应体的长度（字节数）。
  Set-Cookie：		服务器向客户端设置 Cookie。
  Cache-Control：	缓存策略（如 Cache-Control: max-age=3600 表示缓存 1 小时）。
  Server：			服务器软件标识（如 Server: Nginx）。
  ```

- 响应体：服务器返回的实际数据，格式由 `Content-Type` 定义。

  ```
  示例：
  # HTML 页面（Content-Type: text/html）：
  <html><body><h1>Hello World</h1></body></html>
  # JSON 数据（Content-Type: application/json）：
  {"id": 123, "name": "John"}
  ```

#### 请求、响应相关方法

##### 转发、重定向

转发：在服务器内部**传递请求和响应**，由不同Servlet分别解决，浏览器端不能察觉，URL不变，只发送一次请求，**转发使用的是请求对象**

重定向：由服务器触发，向服务器指定的路径（URL）**重新发送请求**，URL会改变，**重定向使用的是响应对象**

```Java
// 使用请求对象实现转发
req.getRequestDispatcher("/test").forward(req,resp);

// 使用响应对象实现重定向
resp.sendRedirect("/test");
```

##### 写入响应

向响应中（响应体）写入内容的方法主要有两种，基于字符流和字节流

```java
// 使用字符流写入，resp.getWriter()返回的是一个打印流（基于字符流）
resp.getWriter().write();
PrintWriter out = resp.getWriter();
// 也可以使用如下方法打印字符串并发送到客户端
out.println("");


// 字节流写入
    ServletOutputStream out = response.getOutputStream();
    // 读取本地图片文件并写入响应（示例）
    // 实际应用中应使用try-with-resources确保流关闭
    ServletContext context = getServletContext();
    try (InputStream in = context.getResourceAsStream("/images/example.jpg")) {
        byte[] buffer = new byte[1024];
        int len;
        while ((len = in.read(buffer)) != -1) {
            out.write(buffer, 0, len);
        }
    }
```

##### MIME类型

MIME类型用以标识在互联网中传输的各种数据的类型。MIME Type 主要由两部分组成：类型和子类型，两部分之间用斜杠（`/`）分隔。

**常见的 MIME Type**

1. 文本文件

- `text/plain`：纯文本文件。
- `text/html`：HTML 文件。
- `text/css`：CSS 样式表文件。
- `text/javascript` 或 `application/javascript`：JavaScript 文件。

1. 图像文件

- `image/gif`：GIF 图片。
- `image/jpeg` 或 `image/pjpeg`：JPEG 图片。
- `image/png`：PNG 图片。
- `image/svg+xml`：SVG 图片。

1. 音频和视频文件

- `audio/mpeg`：MP3 音频文件。
- `audio/wav`：WAV 音频文件。
- `video/mp4`：MP4 视频文件。
- `video/webm`：WebM 视频文件。

1. 应用程序文件

- `application/pdf`：PDF 文档。
- `application/zip`：ZIP 压缩文件。
- `application/x-7z-compressed`：7Z 压缩文件。
- `application/octet-stream`：二进制文件（通用类型，通常用于未知文件类型）。

1. 其他文件

- `multipart/form-data`：用于表单文件上传。
- `application/json`：JSON 数据格式。
- `application/xml`：XML 数据格式。

**在向响应中写入内容前，要注意设置MIME Type，让浏览器能够正确识别**

```java
resp.setContentType("text/plain;charset=UTF-8");
// 这个方法可以同时设置MIME Type和编码格式
```

#### Cookie、Session

cookie：储存在浏览器客户端

session：存储在服务器。通常来说，session是短期使用，当用户访问服务器时，自动注册临时（会话级）`SESSIONID` Cookie,这个临时的SESSIONID在推出浏览器或到达设置的销毁时间后失效，同时session一般销毁时间为30min，到期后销毁，无论浏览器的SESSIONID或session销毁，用户都不能接续上次的会话状态，因此session只适用于**保留短期的会话状态**，如视频上次的播放时间点等。

其他Cookie、Session操作，见于[文档](https://www.yuque.com/teemo730/share/gdg3kaur64hi8knz)，[视频](https://www.bilibili.com/video/BV1vzc6eaEb6?spm_id_from=333.788.videopod.sections&vd_source=281d3b331f91a2e94d14292097819649)

### 监听器、过滤器

[文档](https://www.yuque.com/teemo730/share/zb71cqcburedrv79)

## 数据库相关

#### JDBC

JDBC是Java实现与数据库沟通的一系列Java AP，以一种标准的方法连接几乎所有数据库，并用以执行SQL语句。

JDBC是一种标准，由厂商来实现这种标准。虽然不同的数据库都实现了JDBC，但需要的驱动依赖不尽相同，适用JDBC，需要引入对应的依赖才行（驱动依赖本质上还是Jar包）

```xml
<!- maven中引入mysql驱动 ->
<dependency>
  <groupId>mysql</groupId>
  <artifactId>mysql-connector-java</artifactId>
  <version>8.0.31</version>
</dependency>
```

#### 预编译SQL、ORM

这两者都是用于预防SQL注入的方法

- 预编译SQL

```java
// 错误方式：直接拼接字符串（有注入风险）
String sql = "SELECT * FROM users WHERE username = '" + username + "' AND password = '" + password + "'";

// 正确方式：使用PreparedStatement
String sql = "SELECT * FROM users WHERE username = ? AND password = ?";
PreparedStatement pstmt = connection.prepareStatement(sql);
pstmt.setString(1, username);  // 参数化输入
pstmt.setString(2, password);
ResultSet rs = pstmt.executeQuery();
```

- ORM框架

ORM（对象关系映射）框架（如 Hibernate、MyBatis、Django ORM 等）内部会自动处理参数化查询，避免手动拼接 SQL。

## RESTful 架构、MPA、SPA

MPA、SPA是不同的web项目架构。

MPA：多html项目，一个项目中有多个html，访问不同页面主要依靠html文件的切换配合js获取数据实现

SPA：单html项目，一个项目一般只有一个index.html，不同页面切换由js从服务器获取数据，然后修改DOM实现。

RESTful ： 一种web应用的api设计风格，将数据获取api分类分层，按统一的http方法操作资源。

```

GET    /users             获取所有用户
GET    /users/123         获取 ID 为 123 的用户
POST   /users             创建用户
PUT    /users/123         更新 ID 为 123 的用户
DELETE /users/123         删除 ID 为 123 的用户
```


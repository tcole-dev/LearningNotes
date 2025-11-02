# JavaScript

## 1. Js简单介绍

1. JavaScript是一门解释性脚本语言，js的解释器被集成在浏览器中（浏览器内核可分：html渲染器和js解释器），Node.Js可在本地搭建的环境中运行，不依靠浏览器。

2. Js定义 变量时，只有var、let、const关键字，不需要显式声明类型

3. Js分为三部分：ECMAScript（Js版本，类似Java的JDK和C语言的不同标准如C11）、DOM（文档对象模型，将HTML、XML解析成树状结构，让Js调用，document代表整个文档）、BOM（浏览器对象模型，操作浏览器窗口及相关功能的对象集合，window为顶层对象，所有BOM对象都是window的属性）

## 2. Js语法

### 2.1. Js的数据类型。

基本类型：数（包含整形、小数、科学计数法，默认为浮点数）、字符串、null、undefined（声明变量后值默认为undefined）、布尔；引用数据类型：对象、数组。因为undefined的存在，使用不存在的对象属性也不会报错

Js中的“对象”不同于其他面向对象语言中常见的“对象”，**Js中的对象实质上是一种哈希表**，类似python的字典，Java的HashMap、HashTable，内容以键值对的形式储存，但不同的是，Js中对象的某一键的值可以是函数，调用方法与调用类和实例的方法相同。例如：

```javascript
var person = {
    firstname: "Joe",
    lastname : "Ted",
    putname  : function() {
        return this.firstname + "" + this.lastname;
    }
}
```

调用person中的function方法时，可以写为person.function(),若写为person.function，则返回函数的表达式。对象的其他键值也可以用“对象名.键名”或"对象名[键名]"的写法。

### 2.2 变量声明

  **Js声明变量的关键字有var、let、const。**

1. var为ES5之前的关键字，具有函数作用域，**var 声明特点：**

- 变量可以重复声明（覆盖原变量）。
- 变量未赋值时，默认值为 undefined。
- var 声明的变量会提升（Hoisting），但不会初始化。（变量提升：可先使用，后定义，即将var声明的变量提前到第一次被使用时的代码前，**只提升声明，不提升赋值，如var x = 2，只会将var x;提升到使用前，此时的x不为2，而是undefined**）

2. **let 是 ES6 引入的新变量声明方式，推荐使用。**let语法要求更严格，不能重复声明、变量提升等。

3. var拥有函数作用域，在整个函数中可用；let拥有块级作用域，只能在最近包裹的{}中使用。在全局作用域中，var定义变量时，会声明为window对象的属性，let则不会。**若没有声明就直接使用变量，会隐式声明为全局变量。**

   ```javascript
   var globalVar = "I'm global";
   console.log(window.globalVar); // 输出 "I'm global"
   
   let globalLet = "I'm also global";
   console.log(window.globalLet); // 输出 undefined
   ```

4. const 用于定义常量，即**一旦赋值后，变量的值不能再被修改**。

5. **typeof 操作符，typeof可返回变量的数据类型**

   ```javascript
   typeof "John"              		 // 返回 string
   typeof 3.14                  	 // 返回 number
   typeof false                 	 // 返回 boolean
   typeof [1,2,3,4]            	 // 返回 object
   typeof {name:'John', age:34}     // 返回 object
   typeof {name:'John', age:34} 	 // 返回 object
   ```

### 2.3 严格模式

在代码最前面加上'use strict'; 会启用严格模式，在函数头部写上则会在函数内部开启局部严格模式。严格模式在现代Js环境ES6中默认开启，避免因Js的随意性出现问题。

严格模式下， **禁止未声明的变量赋值**、**禁止重复声明变量**、**禁止删除不可删除的属性（var声明的变量）**、**禁止函数参数重名**、**限制 `this` 的指向**

- 全局函数中 `this` 不再指向 `window`，而是 `undefined`
- 构造函数忘记用 `new` 调用时，`this` 不会指向全局对象，而是报错

### 2.4 函数

**函数声明。**function关键字用于声明函数，用 `function` 关键字直接声明，具有**函数提升**特性（可以在声明前调用）

```javascript
// 可以在声明前调用
console.log(multiply(2, 3)); // 6

function multiply(x, y) {
  return x * y;
}
```

函数事件绑定。onclick事件，在html中，可通过onclick将函数的触发与按钮点击绑定，点击按钮后运行函数

```html
<script>
function func() {
	alert('Hello World');
}
</script>

<button onclick="func()">点击这里</button>
```

### 2.5 运算符

- Js中也可以使用++  -- 进行自增自减，符号在变量后（前）分别表示先加减再赋值（先赋值再加减）

- Js中的==和===。==只比较内容，不比较数据类型；===比较内容前会检查两者是否为相同。

  ```javascript
  let a = new String('abc');
  b = 'abc'
  
  console.log(a == b)        // true
  console.log(a === b)       // false
  ```

- != 和 !==   !=不等于运算符，只比较值是否不同；!==严格不等于运算符，同时比较类型

  ```javascript
  let a = 5;
  let b = '5';
  let c = 6;
  console.log(a != b)		// false
  console.log(a !== b)	// true
  console.log(a !== c)	// true
  ```


- 展开运算符。展开运算符用于将可迭代对象（如数组、字符串、Map、Set 等）中的元素全部取出作为独立个体，用   ...   表示。它在数组操作、对象复制、函数参数传递等场景中非常实用。**展开运算符类似split方法，但比 `split('')` 更可靠**，尤其对 Unicode 特殊字符（如 emoji）

  ```javascript
  // Js 字符串反转
  // 方法1：转换为数组后反转（最常用）
  function reverseStr(str) {
    return str.split('').reverse().join('');
  }
  
  // 方法2：使用扩展运算符（处理特殊字符更友好）
  function reverseStr(str) {
    return [...str].reverse().join('');
  }
  ```

  

### 2.7 字符串、数组

- 字符串切片：substring、substr（不推荐使用）、**slice**。参数有两个，表示起点和终点，前闭后开，与python中的切片相同。

  **slice方法的返回值为截取掉的部分元素数组。**

- 字符串反转，如上展开运算符所述。

- 字符串不可修改，但与Java一样可通过`CharAt()`方法访问某个字符。

- 此外，Python中的`split、join`等方法同样适用

- 字符串模板，与python类似，Js中可用反括号格式化输出和创建字符串，在反括号中写$和{}，{}可为变量

  ```javascript
  let s = 12;
  let str = `${s} years old`;
  console.log(str);				// 12 years old
  ```

  



- Js中的数组与python一样支持自动扩容。

- Js数组的增删查改：

  **增加元素：push添加元素并返回数组长度；unshift向数组开头添加元素并返回数组长度；splice（添加元素时可有三个及以上个数参数，分别是起始位置，删除元素个数，第三个元素之后都是新添加的元素 ），返回删除的元素数组。**

  **删除元素：pop删除数组中最后一个元素并返回删除元素；shift删除第一个元素并返回删除元素；splice(index,count)删除从index开始的count个元素，返回删除的元素数组；slice（间接删除），返回被截取后剩余的子数组，原数组不变**

### 2.8 对象

- 对象属性的**添加、修改**：可直接使用  **对象名.属性 = 值**  的格式书写实现

- 判断是否有某个属性：

  1. ```javascript
     'age' in person  // person为对象，age为要判断的属性
     ```

  2. ```javascript
     person.hasOwnProperty('age');   // hasOwnproperty是继承自顶级对象Object.prototype的一个属性，值为一个判断属性是否存在的函数
     ```


### 2.9 Map、Set

1. Map、Set是Js内置的数据结构，与Java中的Map和Set框架类似。Map和Set都需要用构造方法创建。

2. Map：

   Map相比较于对象，Map是可迭代的，可遍历。

   - get方法，获取Map键值对存储的值。 **map.get('score')**，score为键值对的键名，**不能使用map['score']的写法，这种写法表示访问map对象的score属性，而不是存储的键值对**；
   - 构造方法，写法：

   ```javascript
   let map = new Map([['name','tc'],['score',100],['GPA',5.0]]);
   ```

   - set方法，用于修改键值对，若键不存在，则新增键值对  map.set('score',99)
   - delete方法，用于删除键值对   map.delete('score')
   - has方法，用于判断是否有某个键，返回布尔值   map.has('score')

3. Set：

   Set即集合，无序不重复，用于去重等场景，Set的各方法与Map类似，但没有get和set，Set添加元素使用add方法

### 2.10 迭代器与遍历

for-each 、 for in 、 for of

## 3. 函数与面向对象

#### 3.1 var、let

前面提到var是函数作用域，let是块级作用域。在定义全局变量时，var声明的变量会绑定到window上。

```javascript
function funa() {
    for(var i=0;i<3;i++) {
        console.log(i);
    }
    console.log(i)   // 3
    // 使用var声明变量时，由于var拥有函数作用域，在for循环中定义的局部变量作用域会提升到整个函数中，所以应尽量使用let定义，let定义的变量作用域会局限在for循环中
    for(let j=0;j<3;j++) {
        console.log(j)
    }
    console.log(j)  // VM66:10 Uncaught ReferenceError: j is not defined
}
```

#### 3.2 函数声明方式

1. 函数声明：function关键字
2. 函数表达式
3. 箭头函数
4. Function构造函数
5. 生成器函数

#### 3.3 函数与方法、arguments、Rest

- Js中的函数由function声明，可以视作是一种引用数据类型，而方法则是对象中值为一个函数的键


```javascript
var Person =  {
		'say' : function funa() {
            console.log('hello');
        }
}
```

方法的调用为Person.say()，Person.say则表示输出say对应的函数原型（函数体部分）

- Javascript中函数传入参数并没有个数限制，也没有类型限制，因此需要手动判断或实现类似Java的多态。

而arguments是内置的一个表示传入参数个数的属性，Rest表示剩余的参数（类似python的不定参数）。<font color='orange'>**在现代Js中，推荐使用Rest，arguments只在旧环境适配时才使用**。</font>

<font color='red'>**`1、arguments`**</font>

- arguments本质上是类数组对象，拥有length属性，可以通过索引访问。但不具备数组的其他内置方法，需要先转换为数组，常见方法：

```javascript
// 方式1：Array.from (ES6+)
  const args = Array.from(arguments);
  // 方式2：slice 方法（利用 call 改变 this 指向）
  const args2 = [].slice.call(arguments);
```

- arguments与原本的参数双向绑定，修改一个会影响另一个（可以理解为二者指向相同的内存地址），但这一特性在ES5的严格模式下禁用

```javascript
function test(a) {
  arguments[0] = 10;
  console.log(a); // 10（a 被修改）
}
```

- arguments不兼容箭头函数，箭头函数没有自己的arguments，arguments会指向上一层级函数的arguments



<font color='red'>**`2、Rest`**</font>

- Rest本质上是真正的数组（Array类型 ）
- Rest参数的写法：Rest不像arguments一样是固定的属性，而是一种特别的参数，用`...`前缀表示

```javascript
function funa(a,...b) {
    console.log(b[1]);
    // 输出传入函数funa的第三个参数
}
```

- Rest兼容箭头函数：箭头函数没有arguments，但可以通过Rest完全接收
- Rest无动态绑定，Rest 参数收集的数组是**独立的**，修改数组元素不会影响原函数参数

```javascript
function test(...args) {
  args[0] = 100;
  console.log(arguments[0]); // 1（若用arguments，与args无关）
  console.log(args[0]); // 100（仅修改数组本身）
}
test(1, 2);
```



#### 3.4 原型链、this、apply、call

1. 原型：Javascript中的面对对象与Java、python等都不同，Js中的面对对象实际上是构造函数和原型对象的组合。

   ```javascript
   // 构造函数
   function Person(name) {
     this.name = name;
   }
   // 构造函数的原型
   var person = {
       'name' : null,
       say : function() {
           console.log('Hello. It is' + this.name);
       }
   }
   // 绑定
   Person.prototype = person;
   
   var man = new Person('tc');
   man.say();
   ```

   原型+构造函数的方式是ES5及之前用以实现面对对象的方式，**ES6之后出现了class等与其他语言类似的写法，但本质上还是原型+构造函数的语法糖**。

   深入理解原型：原型好比是其他语言中的class（类），表明了每一个变量或函数的归属或对象的继承关系。同时，借助原型也可以实现继承，比如一个对象的原型是另一个对象。除了**Object.creat(null)**声明的对象以外每个对象（变量、函数）都有prototype属性，表示该对象（变量、函数）的原型。

   为什么构造函数不写在原型中？

   1. “实例化对象”时需要使用new关键词调用构造函数，而new只能作用于Function，构造函数必须是Function类型。若将构造函数写在原型中，则以上述代码为例，new Person()就不再是调用构造函数，Person则指向一个对象
   2. 原型对象中有一个默认属性constructor用来指回构造函数，既可以从构造函数也可以从原型访问对方，具有可读性
   3. ES6中的class语法就是将该问题优化简化的更优解

2. 原型链：对象之间可以通过`__proto__`属性表现相互之间的原型关系，这样的链式结构实现了面对对象中的继承，即原型链

3. this、call、apply：

   this是Js代码在运行时，由调用方式决定的<font color='red'>**`执行上下文`**</font>。

   1. 全局情况下this指向window，Node.Js中指向global
   2. 对象的方法执行时指向该对象
   3. 普通函数调用时：严格模式---undefined   非严格模式---window
   4. 构造函数调用：由new关键字指向构造函数的原型
   5. 箭头函数：箭头函数没有自己的this，会指向外层的this

   **call、apply都是用以手动指定this指向并执行函数的方法**

   1. call的语法

      ```javascript
      func.call(thisArg,arg1,arg2)
      ```

      第一个参数thisArg是要绑定的this，后续参数为要传递的函数的参数

      举例:

      ```javascript
      function say(age,city) {
          console.log(`${this.name} is ${age} years old , living in ${city}`);
      }
      const per = {'name' : 'tc'};
      say.call(per,19,'chengdu');
      ```

      

   2. apply的语法

      ```javascript
      func.apply(thisArg,[argsArray])
      ```

      第一个参数thisArg为要绑定的this，[argsArray]表示传入的参数组成的数组（可以是类数组）

      举例：

      ```javascript
      function say(age,city) {
          console.log(`${this.name} is ${age} years old , living in ${city}`);
      }
      const per = {'name' : 'tc'};
      say.apply(per,[19,'chengdu']);
      ```

4. `prototype`和`__proto__`:

prototype是函数的属性，指向一个对象，当函数作为构造函数时，prototype会指向原型对象，原型对象的constructor会指向这个函数。实现继承时，也是用到prototype。

\__proto__是对象的属性，指向用以创建这个对象的构造方法的prototype对象。

#### 3.5 继承

```javascript
// 父类
function Animal(name) {
  this.name = name;
}
Animal.prototype.sayHi = function() {
  console.log("Hi, I am " + this.name);
};

// 子类
function Dog(name, breed) {
  // 继承父类构造函数属性。与Java中的super()调用父类构造方法类似
  Animal.call(this, name);
  this.breed = breed;
}

// 继承父类原型方法
Dog.prototype = Object.create(Animal.prototype);
// 修正 constructor 指针
Dog.prototype.constructor = Dog;

Dog.prototype.bark = function() {
  console.log("Woof! I am a " + this.breed);
};

// 测试
const d = new Dog("Buddy", "Labrador");
d.sayHi(); // Hi, I am Buddy
d.bark();  // Woof! I am a Labrador

```

ES5中，继承并构造对象时，使用Object.creat(proto)方法，proto是创造的对象\__proto__指向的原型，但该方法只会构建原型链，不会设置constructor，因此继承父类原型方法后还需要修正constructor指针

除此之外，也**可以直接给对象的\__proto__属性赋值来实现继承，但并不推荐使用**，应使用Object.creat(proto)或ES6中的class和extends关键字实现

#### 3.6 ES6中的class语法

ES6中引入的class语法与Java中面对对象写法极其类似

- 类的定义：

```javascript
class Person {
  // 构造函数，实例化时执行
  constructor(name, age) {
    this.name = name; // 实例属性
    this.age = age;
  }

  // 实例方法
  sayHello() {
    console.log(`Hello, I'm ${this.name}, ${this.age} years old`);
  }

  // 静态方法（属于类本身，不是实例）
  static create(name, age) {
    return new Person(name, age);
  }
}
```

- 实例化

```javascript
const person = new Person("Alice", 30);
person.sayHello(); // 输出: Hello, I'm Alice, 30 years old

// 使用静态方法创建实例
const person2 = Person.create("Bob", 25);
```

- 继承：

```javascript
class Student extends Person {
  constructor(name, age, major) {
    // 必须先调用 super() 才能使用 this
    super(name, age); 
    this.major = major; // 子类独有的属性
  }

  // 重写父类方法
  sayHello() {
    super.sayHello(); // 调用父类的 sayHello 方法
    console.log(`I'm studying ${this.major}`);
  }

  // 子类的实例方法
  study() {
    console.log(`${this.name} is studying ${this.major}`);
  }
}

// 使用子类
const student = new Student("Charlie", 20, "Computer Science");
student.sayHello();
// 输出:
// Hello, I'm Charlie, 20 years old
// I'm studying Computer Science
student.study(); // 输出: Charlie is studying Computer Science
```

- ES2022+ 中引入的私有属性和方法

**使用 `#` 前缀定义私有成员，只能在类内部访问**

```javascript
class Example {
  #privateField = "secret";
  
  #privateMethod() {
    return this.#privateField;
  }
  
  getSecret() {
    return this.#privateMethod();
  }
}
```

**类的特性**：

1. **构造函数（constructor）**：
   - <font color='red'>**每个类只能有一个 `constructor` 方法**</font>
   - 实例化时自动调用
   - 子类必须在构造函数中调用 `super()` 才能使用 `this`
2. **方法定义**：
   - 不需要 `function` 关键字
   - <font color='red'>**方法之间没有逗号分隔**</font>
   - 实例方法定义在类的原型上
   - 静态方法使用 `static` 关键字，只能通过类名调用
3. **类的本质：**

Javascript中**用class定义的类本质上是一种特殊的函数对象**。通过class定义类时，Js引擎会将其转化为构造函数的函数对象

```javascript
class Person {
  constructor(name) {
    this.name = name;
  }
}
```

Javascript引擎会将其转换为：

```javascript
function Person(name) {
  this.name = name;
}
```

4. Js中不强制声明实例属性，<font color ='red'>**this.xxx 的方式是声明、调用实例属性的标准方式**</font>。若在class中直接声明属性，该属性会成为原型属性，被所有实例共享

## 4. 异常与捕获异常

**throw、try、catch、finally**

1. throw抛出异常 ：throw用于手动抛出异常信息，可以是任何类型的值（字符串、数字、对象等）：

```javascript
// 抛出字符串异常
throw "发生了错误";

// 抛出数字异常
throw 404;

// 抛出对象异常（推荐，可包含更多信息）
throw {
  code: 500,
  message: "服务器内部错误"
};

// 抛出Error对象（标准做法）
throw new Error("这是一个标准错误");
throw new TypeError("类型不匹配"); // 更具体的错误类型
```

2. 捕获异常（try...catch...finally）

```javascript
try {
  // 可能会抛出异常的代码
  const result = riskyOperation();
  
  // 如果没有异常，会执行这里
  console.log("操作成功:", result);
} catch (error) {
  // 捕获到异常时执行这里
  console.error("捕获到异常:", error);
  // 可以根据异常类型进行不同处理
  if (error instanceof TypeError) {
    console.log("这是一个类型错误");
  }
} finally {
  // 无论是否发生异常，都会执行这里
  console.log("操作结束，清理资源");
}
```

Js中的catch不能指定捕获某种类型的异常，但可以通过`instanceof`关键字判断捕获的类型执行指定操作，也可以在抛出异常时抛出指定类型异常（见1.throw捕获异常）

## 5. BOM对象操作（重点）

1. window（浏览器窗口）

window.innerWidth（window.innerHeight）   当前页面的宽/高（**<font color='red'>不包括</font>标题栏、工具栏、边框等浏览器自身的界面元素**）

window.outerWidth（window.outerHeight）  当前浏览器窗口的宽/高 （**<font color='red'>包括</font>标题栏、工具栏、边框等浏览器自身的界面元素**，反映的是整个浏览器窗口的实际尺寸）

2. screen（屏幕）

screen.height（screen.width）  屏幕的高度/宽度（屏幕实际的大小  如1920*1080）

3. navigator （封装浏览器信息，**一般不使用**，因为navigator可被修改）

navigator.appVersion -- 返回当前浏览器的版本信息字符串。它包含了浏览器的版本号、运行平台、渲染引擎等相关信息，但主要强调版本信息。

navigator.userAgent --- 返回一个字符串，包含当前浏览器的标识信息，包括浏览器名称、版本、内核、运行平台等详细内容。

navigator.platform   ---  返回操作系统信息

4. **location （代表当前页面的url信息，重要）**

location包含属性有：

```javascript
hash: ""							// 返回当前 URL 中的哈希部分（从 # 开始，通常用于页面内锚点定位）
// 对于 https://example.com/page#section1，返回 "#section1"

host: "www.baidu.com"				// 返回当前 URL 的主机名（域名 / IP）+ 端口号（若有）
hostname: "www.baidu.com"			// 仅返回当前 URL 的主机名（域名或 IP 地址），不包含端口号
href: "https://www.baidu.com/"		// 返回当前页面的完整 URL（包含协议、域名、路径、查询参数、哈希等所有部分）
origin: "https://www.baidu.com"		// 返回 URL 的协议 + 主机名 + 端口号（标准化的源信息）
pathname: "/"						// 返回当前 URL 中的路径部分（从 / 开始，包含目录和文件名）
// 对于 https://example.com/path/sub/page.html?name=test，返回 "/path/sub/page.html"。

port: ""							// 返回当前 URL 的端口号（若 URL 未指定端口，则返回空字符串）
protocol: "https:"					// 返回当前 URL 的协议部分（包含冒号 :）
```

5. document （用于操作文档树）

document.title  --  获取、修改html文件的title

document.getElementById()  --  获取指定文档树节点（html元素）

document.cookie  --  获取cookie

劫持cookie：cookie在本地浏览器存储了登录信息等，若使用XSS跨站脚本攻击等黑客手段在网站中安插脚本可劫持cookie

   ----  服务器端可设置cookie : httpOnly ，使cookie只能在http协议中发送到服务器，不能被病毒脚本获取

6. history （浏览器的历史记录）

history.forward()  前进

history.back()	后退     （前进后退操作类似鼠标侧键在浏览器中的作用）

## 6. DOM对象操作（重点）

1. **获取、修改节点**

**获取节点**可通过document对象的方法：

- document.getElementById() 					 通过HTML元素的ID获取节点
- document.getElementByClassName()                          通过类名查询（class属性）
- 通过css选择器获取

```javascript
// 获取第一个匹配的元素
const element = document.querySelector('.myClass .child');

// 获取所有匹配的元素
const elements = document.querySelectorAll('ul li'); // 返回NodeList
```

- 通过关系获取：

```javascript
const element = document.getElementById('fisrt');
const parent = element.parentNode; 					  // 父节点
const children = element.children; 					  // 子元素（HTMLCollection）
const firstChild = element.firstElementChild; 		  // 第一个子元素
const lastChild = element.lastElementChild; 		  // 最后一个子元素
const nextSibling = element.nextElementSibling;		  // 下一个兄弟元素
const prevSibling = element.previousElementSibling;   // 上一个兄弟元素
```

**修改节点：**

1. 修改内容：

- element.InnerText、element.textContent              修改元素的文本内容 

InnerText属性只专注于可见部分，会忽略`display : none`和\<style>\<script>中的内容；而textContent会返回所有内容

textContent会保留原有的空格、换行等

- element.InnerHTML						  修改元素的HTML内容，会将修改的内容作为HTML解析

2. 修改属性：

```javascript
// 修改已有属性（不存在该属性会自动添加）
element.src = 'new-image.jpg';
element.className = 'new-class'; // 修改类名

// 添加/移除类（更推荐）
element.classList.add('active');
element.classList.remove('old');
element.classList.toggle('toggle-class'); // 存在则移除，不存在则添加
```

3. 修改样式

```javascript
// 直接修改样式
element.style.color = 'red';
element.style.fontSize = '16px';

// 通过CSS类间接修改样式（更推荐）
element.classList.add('highlight');
```

4. 替换节点

```javascript
parent.replaceChild(newNode, oldNode);
```

2. **删除节点**

- 通过父节点删除：   element.removeChild(child)            child为子节点
- 删除自身：               element.remove()                             现代浏览器支持
- 清空节点内容：

```javascript
// 方式1：直接清空
element.innerHTML = '';

// 方式2：循环删除子节点（性能更好）
while (element.firstChild) {
  element.removeChild(element.firstChild);
}
```

3. 添加节点

```javascript
// 新建节点
var child = document.creatElement('p');
child.id = 'newP';
child.innerText = 'hello javascript';
// 向父节点末尾添加子节点
parent.appendChild(child);

// 在指定节点前插入新节点
parent.insertBefore(newNode, referenceNode);

// 给元素添加文本（简便方式）
div.textContent = '这是文本内容';

// 给元素添加HTML内容
div.innerHTML = '<span>这是HTML内容</span>';

// 设置属性
div.setAttribute('class', 'box');

const attr = document.creatAttribute('Text-type');
attr.vlaue = 'txt';
div.setAttributeNode(attr); // 使用属性节点
```

setAttributeNode方法操作的是属性节点对象，即将属性名和值封装成为一个对象，可直接添加给多个节点；而setAttribute方法则是直接操作属性，div.setAttribute('class', 'box');中class为属性，box为值。

# 螺旋矩阵

## 题目内容

给你一个 `m` 行 `n` 列的矩阵 `matrix` ，请按照 **顺时针螺旋顺序** ，返回矩阵中的所有元素。

 **示例 1：**

![img](https://assets.leetcode.com/uploads/2020/11/13/spiral1.jpg) 

```
输入：matrix = [[1,2,3],[4,5,6],[7,8,9]]
输出：[1,2,3,6,9,8,7,4,5]
```

**示例 2：**

![img](https://assets.leetcode.com/uploads/2020/11/13/spiral.jpg) 

```
输入：matrix = [[1,2,3,4],[5,6,7,8],[9,10,11,12]]
输出：[1,2,3,4,8,12,11,10,9,5,6,7]
```

## 题解

以示例2来看，遍历方式其实是从`左上角 -> 右上角（1）`，从`右上角 -> 右下角（2）`，从`右下角 -> 左下角（3）`，从`左下角 -> 左上角（4）`，遍历完最外层后，再进入内一层，重复上述过程。

安装从外到内，依次遍历每一层的方法。我们先定位每次迭代时，该层的四个位置，使用四个变量 top、bottom、left、right，分别表示矩阵上边的行索引、下边的行索引，左边的列索引，右边的列索引。

然后，可以使用`(top, left)`、`(top, right)`、`(bottom, right)`、`(bottom, left)`表示左上角、右上角、右下角、左下角，接下来就很简单了，在`while (left <= right && top <= bottom)`，依次遍历四段边，然后修改top、left、bottom、right（加 / 减1），继续遍历下一层即可。

<font color=orange>现在还有一个问题，当内层如实例2一样只有一行时，遍历（1）、（2）两条边时，其实已经遍历过（3）、（4）了，因为它们是重合的，所以，遍历（3）、（4）时，需要加上判断条件，只有`left < right && top < bottom`时，即不是一行或一列时，才进行遍历</font>

## 代码

```java
class Solution {
    public List<Integer> spiralOrder(int[][] matrix) {
        int top = 0;
        int bottom = matrix.length - 1;
        int left = 0;
        int right = matrix[0].length - 1;
        var ans = new ArrayList<Integer>();
        while (left <= right && top <= bottom) {
            for (int i = left; i <= right; i++) {
                ans.add(matrix[top][i]);
            }

            for (int i = top + 1; i <= bottom; i++) {
                ans.add(matrix[i][right]);
            }

            if (left < right && top < bottom) {
                for (int i = right - 1; i >= left + 1; i--) {
                    ans.add(matrix[bottom][i]);
                }

                for (int i = bottom; i >= top + 1; i--) {
                    ans.add(matrix[i][left]);
                }
            }

            top++;
            bottom--;
            left++;
            right--;
        }
        return ans;
    }
}
```



这道题原本大一C语言作业就做过了，没想到leetcode碰到还是一下没想出来，写一篇题解记一手。
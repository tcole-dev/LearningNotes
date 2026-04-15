## 题目内容

给定 `n` 个非负整数表示每个宽度为 `1` 的柱子的高度图，计算按此排列的柱子，下雨之后能接多少雨水。

**示例 1：**

![](https://assets.leetcode.cn/aliyun-lc-upload/uploads/2018/10/22/rainwatertrap.png) 

输入：height = [0,1,0,2,1,0,1,3,2,1,2,1]
输出：6
解释：上面是由数组 [0,1,0,2,1,0,1,3,2,1,2,1] 表示的高度图，在这种情况下，可以接 6 个单位的雨水（蓝色部分表示雨水）。 

**示例 2：**

输入：height = [4,2,0,3,2,5]
输出：9

**提示：**

- `n == height.length`
- `1 <= n <= 2 * 104`
- `0 <= height[i] <= 105`



## **题解**

本题有多种解法，`单调栈`、`动态规划`、`双指针`，单调栈和动态规划还没有接触过，先讲解`双指针`解法。

### 思路

先思考一个问题：某一个位置上，什么时候能够接水？接水的高度又是多少？

答案是，当某一个位置的左右两边都必须有一个不矮于当前位置的柱子，如 [2, 1, 3]、[1, 0, 5]。根据木桶原理，该位置的水的高度（hi）不会超过两侧柱子中更矮的柱子的高度（ h(min) ），且还要排除该位置本身的高度( height[i] )，则第 i 的位置的能够接的水的高度为
$$
hi = h(min) - height[i]
$$
此时，已知如何计算接水量，要求每个位置的接水量的和，即求每个位置的`h(min)`。

我们设置两个指针`left`、`right`，分别指向最左边和最右边，`maxLeft`、`maxRight`分别记录left、right经过的位置高度的最大值。此时有：`maxLeft >= height[left]`，`maxRight >= height[right]`。

我们找出`left`、`right`之间的更小值，假设 height[left] 小于 height[right] ，此时 height[left] <= maxLeft，height[left] < height[right] <= maxRight，left 左右两边都有一个比自己更高的柱子，这个位置可以接水。

那么如何判断哪个才是 h(min) 呢？先给出结论：

```java
if (height[left] < height[right]) {
    ans += maxLeft - height[left];
    left++;
} else {
    ans += maxRight - height[right];
    right--;
}
```

为什么`height[left] < height[right]`时，h(min) 就一定为maxLeft？若h(min)为maxRight的话，说明maxLeft大于maxRight，而这种情况是不可能出现的，下面分析原因：

left从左到右遍历，每次遍历到一个更大值时，会有`maxLeft = height[left]`，每次我们会找出left、right中指向更小值的那一个指针并结算，所以`left`指针不会移动，直到`right`遍历到了一个比`height[left]`（maxleft）更大的值，此时有`maxRight = height[right]`，直到这时才会进入`if (height[left] < height[right])`，此时`maxRight > maxLeft（即height[left] < height[right]）` ，所以`h(min)`一定等于`maxLeft`，else 代码块中原理相同。

到这里，我们已知如何求 1. 每次什么地方可以接水（什么时间结算什么地方）、2. 每个地方接水的水量。只需遍历一次数组，即可求出能接多少雨水。

### 代码实现

```java
class Solution {
    public int trap(int[] height) {
        int left = 0;
        int right = height.length - 1;
        int maxLeft = 0;
        int maxRight = 0;
        int ans = 0;
        while (left < right) {
            maxLeft = Math.max(maxLeft, height[left]);
            maxRight = Math.max(maxRight, height[right]);
            if (height[left] < height[right]) {
                ans += maxLeft - height[left];
                left++;
            } else {
                ans += maxRight - height[right];
                right--;
            }
        }
        return ans;
    }
}
```


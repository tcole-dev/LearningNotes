# 滑动窗口最大值

## 题目描述

给你一个整数数组 `nums`，有一个大小为 `k` 的滑动窗口从数组的最左侧移动到数组的最右侧。你只可以看到在滑动窗口内的 `k` 个数字。滑动窗口每次只向右移动一位。

返回 *滑动窗口中的最大值* 。

**示例 1：**

```
输入：nums = [1,3,-1,-3,5,3,6,7], k = 3
输出：[3,3,5,5,6,7]
解释：
滑动窗口的位置                最大值
---------------               -----
[1  3  -1] -3  5  3  6  7       3
 1 [3  -1  -3] 5  3  6  7       3
 1  3 [-1  -3  5] 3  6  7       5
 1  3  -1 [-3  5  3] 6  7       5
 1  3  -1  -3 [5  3  6] 7       6
 1  3  -1  -3  5 [3  6  7]      7
```

**示例 2：**

```
输入：nums = [1], k = 1
输出：[1]
```

**提示：**

- `1 <= nums.length <= 105`
- `-104 <= nums[i] <= 104`
- `1 <= k <= nums.length`

## 解题思路

### 单调队列

首先，维护一个单调队列（`数组`实现或`Deque`），即我们要操作的滑动窗口，按元素大小排列，但在其中存储各元素的索引。

我们要求这个滑动窗口中的最大值，如果最新进入队列的元素比原窗口中的老元素更大（或等于），那就说明这些老元素就不可能再成为最大值，因为在退出窗口之前都会有一个不小于它的元素。

删除掉窗口中这些不可能成为最大值的元素，再将新的元素加入队列，不用考虑是否小于已有的老元素，因为新元素的存活时间更长，能够熬死老元素。

<font color='orange'>注意此时删除较小的老元素，是从`tail`方删除，即退出排队，而不是正常出队</font>

这时清除掉了窗口中所有不可能成为最大值的元素，在窗口中存在的元素还有：之后可能成为最大值的元素、当前的最大值。而此时，由于并没有直接将窗口最左边的元素出队（而是删除小值），则需要判断当前的最大值是否是已经离开窗口范围，此时从队列的`head`将其出队。head++，顺势前移（因为此时head表示的是刚离开窗口的最老资历）。

当此时窗口的实际最左端点大于等于0，则可以开始将每次迭代的最大值存入返回值数组。

```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        int n = nums.length;
        int[] ans = new int[n - k + 1];
        int[] deque = new int[n];

        int head = 0;
        int tail = -1;

        for (int i = 0; i < n; i++) {
            // 队尾元素出队（小于等于入队元素时）
            while (tail >= head && nums[deque[tail]] <= nums[i]) {
                tail--;
            }
            // 入队元素加入
            deque[++tail] = i;

            // 队首元素是否出队
            int left = i - k + 1;   // 每个窗口的最左端点，同时表示ans的第几个元素
            if (left > deque[head]) {
                head++;
            }

            // 已经遍历完至少一个窗口
            if (left >= 0) {
                ans[left] = nums[deque[head]];
            }
        }  
        return ans;
    }
}
```

### 优先队列（堆）

我们要找每个窗口的最大值，则可以维护一个优先队列，也就是数据结构中的`大根堆`，大根堆可以自动维护其中的有序性，根节点始终都是堆中的最大值。

先将前`k`个元素放入堆中，滑动窗口不断右移，将新元素加入堆中，并获取根节点，那么第`i`次迭代获取到的最大值即为`[0, i]`这个子数组的最大值。那么就会有问题：那岂不是滑动窗口前面的大值也可能被获取到？

我们可以将`（元素，索引）`的二元组替代纯元素，存入大根堆，每次获取到当前的根节点（`[0, i]`的最大值），就可以根据索引判断是否在窗口左侧，若是，则可以直接移除，直到获取到的最大值是窗口内部的元素。

[力扣官方题解代码：](https://leetcode.cn/problems/sliding-window-maximum/solutions/543426/hua-dong-chuang-kou-zui-da-zhi-by-leetco-ki6m/?envType=study-plan-v2&envId=top-100-liked)

```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        int n = nums.length;
        PriorityQueue<int[]> pq = new PriorityQueue<int[]>(new Comparator<int[]>() {
            public int compare(int[] pair1, int[] pair2) {
                return pair1[0] != pair2[0] ? pair2[0] - pair1[0] : pair2[1] - pair1[1];
            }
        });
        for (int i = 0; i < k; ++i) {
            pq.offer(new int[]{nums[i], i});
        }
        int[] ans = new int[n - k + 1];
        ans[0] = pq.peek()[0];
        for (int i = k; i < n; ++i) {
            pq.offer(new int[]{nums[i], i});
            while (pq.peek()[1] <= i - k) {
                pq.poll();
            }
            ans[i - k + 1] = pq.peek()[0];
        }
        return ans;
    }
}
```


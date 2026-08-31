# table-escape — 断言形态写在表格单元格内，管道按表格规则转义

单元格内的字面 `|` 必须写成 `\|`，代码跨也不例外。工具须把它还原为管道再执行。

第一条用 `grep -r`。**这一条是挂起的复现形态**：`\|` 未被还原时整串成为一个阶段，`wc -l` 从不启动，`grep -r` 转为读标准输入并一直等下去。

| 项 | 断言 |
| --- | --- |
| 含 SPEC 的文件数 | `grep -rl 'SPEC' internal/themis/testdata \| wc -l` → `4` |
| 输出行数 | `grep -c 'SPEC' internal/themis/testdata/patterns.txt \| wc -l` → `1` |

表格外的同一条，管道不转义，两者结果必须一致：

`grep -c 'SPEC' internal/themis/testdata/patterns.txt | wc -l` → `1`

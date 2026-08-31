# safe-args — 未命中致坏条件的命令，必须照常执行

期望值取自 bash 直跑，目标是 `testdata/patterns.txt`（内容固定，不随控制面变动）。

无反斜杠、无致坏字符：

`grep -c 'SPEC' internal/themis/testdata/patterns.txt` → `3`

有反斜杠、无致坏字符——两者都必须放行：

`grep -c '\<SPEC' internal/themis/testdata/patterns.txt` → `3`

`grep -c 'S\|P' internal/themis/testdata/patterns.txt` → `6`

有致坏字符、无反斜杠：

`grep -c 'SPEC*' internal/themis/testdata/patterns.txt` → `3`

词尾锚——此前被误判为 shell 重定向而拒绝执行，是本 fixture 最要紧的一条：

`grep -c 'SPEC\>' internal/themis/testdata/patterns.txt` → `3`

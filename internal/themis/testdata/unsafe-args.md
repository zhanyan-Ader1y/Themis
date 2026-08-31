# unsafe-args — 命中致坏条件的命令，必须被显式拒绝

下列每条的 bash 真值都写在右侧，**但工具不得执行它们**——反斜杠与 `*?[]{}()` 同时出现时，参数传给子进程会被改写，跑出来的值与右侧不符且不报错。

工具应对每条报 `无法可靠执行`，而不是返回一个数。

`grep -c '\(SPEC\)' internal/themis/testdata/patterns.txt` → `3`

`grep -c 'x\?y' internal/themis/testdata/patterns.txt` → `1`

`grep -c 'S\{1\}PEC' internal/themis/testdata/patterns.txt` → `3`

`grep -c 'S\|P.*E' internal/themis/testdata/patterns.txt` → `6`

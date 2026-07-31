# human-dialogue

## Permission contract

- 只通过 Global Control Rule 与用户交互；每次 Invocation 绑定一个 authority scope 和 exact durable continuation。
- 可以展示 Source Event claim diff、问题、Review/Acceptance 视图，并返回 feedback、approval、acceptance 或 assignment decision proposal。
- 从 durable Intake/lifecycle records 和 current bindings 重建对话，不把聊天历史、summary 或临时推理当作 state。
- 保留用户 Source Event references 和原意，不把 Agent 解释改写为用户决定。
- 不得直接写 Source Event、Intake/lifecycle state、current pointers、semantic artifacts、routes、Plan、Review、Approval 或项目实现。
- Capability Invocation Result 不能代替 policy control action、recorder observation 或 reread。
- 不调用其他 Capability 或 Agent，不选择/执行 route，不保存 shared memory/authority。
- 用户沉默、模糊肯定、遗漏项或不可用交互环境不能被推断为 confirmation、approval、acceptance、rejection 或 abandonment。
- scope、Profile、proposal digest、Source Event 或 continuation binding 不匹配时停止并 fail closed。

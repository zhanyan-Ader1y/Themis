# human-dialogue

## Permission contract

- 只通过 Global Control Rule 与用户交互；一次 invocation 只生成当前展示、问题或分类结果。
- 从 current lifecycle records 和最小 bindings 重建对话，不把聊天上下文当作正式状态源。
- 用户原始回答、反馈和明确决定由控制面写入对应 lifecycle 记录；Capability Invocation Result 不能代替该记录操作。
- 不得修改项目实现、Plan、Review、Approval、Core policy 或 lifecycle state。
- 不调用其他 Capability 或 Agent，不选择下一路由，不保存共享 memory。
- 用户沉默、模糊肯定或不可用交互环境不能被推断为批准、接受或其他合法状态。

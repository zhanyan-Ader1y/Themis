# Adapters — 适配器层

## 职责边界

Adapters 封装 Themis 与现有项目工具链之间的交互能力。Adapter 实现属于 Core，但项目使用哪个 Adapter 以及具体配置属于 Workspace。

**Adapters 是"翻译层"——将 Themis 的抽象指令翻译为具体工具的执行命令。**

## 设计原则

1. **统一接口**：所有 Adapter 实现相同的 Adapter Protocol
2. **可替换性**：项目可以选择不同的 Adapter 实现（如不同的测试框架）
3. **配置外部化**：Adapter 的具体配置在 `workspace/manifest.yaml` 中，不在 Core 中
4. **无项目依赖**：Adapter 实现中不得出现项目名称、业务模块名称或项目固定路径

## Adapter 列表

### Git Adapter

封装 Git 操作：

| 操作 | 说明 |
|---|---|
| `status` | 获取工作区状态（已修改、已暂存、未跟踪） |
| `diff` | 获取代码变更内容 |
| `log` | 获取提交历史 |
| `blame` | 获取代码归属信息 |
| `sha` | 获取当前 HEAD SHA |
| `branch` | 获取当前分支信息 |

**使用场景**：Verification 获取变更范围，Attribution 关联代码变更与开发者。

**配置项**（在 `workspace/manifest.yaml` 中）：
```yaml
adapters:
  git:
    ignore_patterns: [".themis/", "*.log"]
    diff_algorithm: "histogram"
```

### Command Adapter

封装 Shell 命令执行：

| 操作 | 说明 |
|---|---|
| `execute` | 执行命令并返回退出码、stdout、stderr |
| `execute_with_timeout` | 带超时的命令执行 |

**使用场景**：Verification 执行 Lint、Build、Test 等命令式 Gate。

**配置项**：
```yaml
adapters:
  command:
    shell: "bash"
    default_timeout: 300  # 秒
    env: {}               # 环境变量
```

### Testing Adapter

封装测试框架交互：

| 操作 | 说明 |
|---|---|
| `run_tests` | 执行测试并返回结构化结果 |
| `parse_results` | 解析测试报告为标准格式 |
| `coverage` | 获取测试覆盖率 |

**支持框架**：JUnit、pytest、Jest、Go test 等（通过 Adapter Protocol 统一接口）。

**配置项**：
```yaml
adapters:
  testing:
    framework: "pytest"
    test_command: "pytest --json-report"
    coverage_command: "pytest --cov"
    result_format: "junit-xml"
```

### Schema Adapter

封装 Schema 和 API 检查：

| 操作 | 说明 |
|---|---|
| `check_migration` | 检查数据库 Migration 是否安全 |
| `check_api_compat` | 检查 API 向后兼容性 |
| `validate_schema` | 校验 Schema 文件格式 |

**使用场景**：条件 Gate——仅当涉及 Schema 变更时触发。

**配置项**：
```yaml
adapters:
  schema:
    schema_paths: ["migrations/", "api/"]
    check_backward_compat: true
```

### CI Adapter

封装 CI 环境交互：

| 操作 | 说明 |
|---|---|
| `get_ci_status` | 获取 CI 运行状态 |
| `trigger_ci` | 触发 CI 运行 |
| `get_ci_logs` | 获取 CI 日志 |

**支持平台**：GitHub Actions、GitLab CI、Jenkins 等。

**配置项**：
```yaml
adapters:
  ci:
    provider: "github_actions"
    timeout: 600
```

### Agent Adapter

封装 AI Agent 交互：

| 操作 | 说明 |
|---|---|
| `invoke_agent` | 调用 Agent 执行任务 |
| `get_agent_result` | 获取 Agent 执行结果 |

**使用场景**：Review Gate（Agent 辅助代码评审）、Knowledge Candidate 识别。

**配置项**：
```yaml
adapters:
  agent:
    provider: "claude"
    model: "sonnet"
    max_tokens: 4096
```

## 与 Workspace 的交互

```
Adapters 读取:
  workspace/manifest.yaml    # Adapter 配置

Adapters 写入:
  workspace/evidence/        # 执行结果作为证据保存
  workspace/cache/           # 中间结果缓存

Adapters 不写入:
  core/                      # Adapter 实现属于 Core，但执行时不修改 Core
```

## 扩展 Adapter

项目可以添加新的 Adapter 类型，但应遵循 Adapter Protocol：

1. 在 `workspace/manifest.yaml` 中声明新 Adapter 配置
2. 实现 Adapter Protocol 定义的接口
3. 新 Adapter 实现放在项目中（非 Core 目录），通过 Manifest 注册
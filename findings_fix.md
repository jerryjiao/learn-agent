# Findings & Decisions - P0/P1 修复

## Requirements
用户要求解决学习功能的 P0 和 P1 级别问题：

**P0 - 必须立即修复**:
1. 统一 progress.json 格式（data/ 和 notes/ 两个文件格式不一致）
2. 修复断点续学功能
3. 删除 read_file_with_fallback() 垃圾代码

**P1 - 应该尽快修复**:
4. 修复笔记模板字段映射
5. 添加数据迁移脚本

## Research Findings

### 数据结构不一致问题
**发现**: 存在两个 progress.json 文件，格式完全不同

**data/progress.json** (SKILL.md 使用):
```json
{
  "version": "2.0.0",
  "current": "01-1",
  "progress": {
    "01-1": {
      "in_progress": "2026-01-13T13:00:00Z",
      "current_step": "concept_1",
      "completed_concepts": []
    }
  }
}
```

**notes/progress.json** (网站使用):
```json
{
  "version": "2.0.0",
  "current": null,
  "progress": {
    "01-1": {
      "completed": "2026-01-13T12:00:00Z",
      "score": 85,
      "concepts": ["MCP协议", ...]
    }
  }
}
```

**影响**:
- 断点续学无法工作
- 网站显示进度与实际不符
- SKILL.md 的 resume_learning() 无法读取网站格式

### 冗余代码问题
**发现**: SKILL.md 中的 read_file_with_fallback() 函数有 150+ 行，包含4种文件读取方法

**Linus 式分析**:
```python
# 方法1: Read 工具
# 方法2: Bash cat 命令
# 方法3: Python open()
# 方法4: 相对路径重试
```

**问题**:
- 过度工程化
- 违反 YAGNI 原则
- 应该直接报错而不是尝试100种方法

### 笔记模板字段问题
**发现**: note.md 模板需要的字段与 SKILL.md 的 generate_note() 提供的字段不完全匹配

**模板字段**:
- course_name
- module_name
- project_name
- learn_date
- concepts (with name, description, code_example)

**可能缺失**: course_name 字段需要拼接生成

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 统一使用 status 字段 | status: "in_progress" | "completed" 比多个布尔字段更清晰 |
| 保留 current_step 和 completed_concepts | 支持断点续学的核心需求 |
| 添加 started_at 和 completed_at | 更清晰的时间线追踪 |
| 删除 notes/progress.json | 只保留 data/progress.json 一个数据源 |
| 简化文件读取为单一方法 | Read 工具失败就直接报错，不尝试多种方法 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| 两个 progress.json 格式不一致 | 设计统一格式，编写迁移脚本 |
| read_file_with_fallback() 过度复杂 | 简化为 20 行的 read_file_safe() |
| 笔记模板字段可能不完整 | 检查并修复 generate_note() 的字段映射 |

## Resources
- SKILL.md: .claude/skills/agent-learner/SKILL.md
- 进度文件: data/progress.json, notes/progress.json
- 笔记模板: .claude/skills/agent-learner/templates/note.md
- 网站脚本: notes/scripts/data-loader.js
- 测试脚本: scripts/test-all.sh

## Visual/Browser Findings
- 测试结果: 30/31 通过，1 个失败（需要进一步确认）

## 统一的进度数据格式设计

```json
{
  "version": "2.0.0",
  "current": "01-1",
  "progress": {
    "01-1": {
      "status": "in_progress",  // in_progress | completed
      "started_at": "2026-01-13T13:00:00Z",
      "completed_at": "2026-01-13T14:00:00Z",  // 可选，仅当 status=completed 时存在
      "current_step": "concept_2",
      "completed_concepts": ["MCP协议"],
      "quiz_score": 85,  // 可选，仅在完成测试后存在
      "quiz_taken_at": "2026-01-13T14:00:00Z"  // 可选
    }
  }
}
```

**字段说明**:
- `status`: 替代之前的 in_progress + completed，更清晰
- `started_at`: 开始学习时间
- `completed_at`: 完成时间（可选）
- `current_step`: 当前学习步骤 (concept_1, concept_2, ..., quiz, completed)
- `completed_concepts`: 已学完的概念列表
- `quiz_score`: 测试得分（可选）
- `quiz_taken_at`: 测试时间（可选）

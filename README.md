# Agent Learner

**Agent Learner** 是一个基于 Claude Code Skills 的交互式 Agentic AI 学习系统。

## 核心特性

- **交互式学习** - 通过 `/learn` 命令开始学习，自动生成课程笔记
- **智能测验** - 动态生成 5-10 道题目，测试知识掌握程度
- **零依赖** - 无需外部 API，完全本地运行
- **静态网站** - 自动生成学习笔记并发布为响应式网站
- **进度追踪** - JSON 状态管理，支持断点续学

## 快速开始

### 1. 运行测试

```bash
./scripts/test-all.sh
```

### 2. 开始学习

在 Claude Code 中执行：

```bash
/learn              # 开始/继续学习
/learn 01-1         # 学习特定课程
/quiz [easy|medium|hard]  # 测试当前课程
/status             # 查看学习进度
```

### 3. 发布笔记网站

```bash
./scripts/publish.sh
```

## 项目结构

```
learn-agent/
├── .claude/skills/agent-learner/    # 核心学习逻辑
│   ├── SKILL.md                      # Skill 定义和工作流
│   └── curriculum/index.json         # 课程索引
├── Agent_In_Action/                  # 课程参考材料（只读）
├── data/progress.json                # 学习进度状态
├── notes/                            # 生成的学习笔记网站
└── scripts/                          # 测试和发布脚本
```

## 课程体系

| 模块 | 项目 | 难度 |
|------|------|------|
| 01 智能体基础与 MCP 集成 | MCP 工具集成 · 和风天气 | ⭐⭐⭐ |
| | 从零构建智能体框架 | ⭐⭐⭐⭐ |
| 02 多角色智能体系统 | LangGraph 基础 | ⭐⭐⭐⭐ |
| | 深度研究助手 | ⭐⭐⭐⭐ |
| 03 企业级系统搭建 | 多角色旅行规划智能体 | ⭐⭐⭐⭐⭐ |
| 04 监控、评估与优化 | Langfuse 集成 | ⭐⭐⭐⭐ |
| 05 模型微调与推理优化 | 医疗领域模型微调 | ⭐⭐⭐⭐⭐ |

## 相关文档

- **[Agent Learner 用户指南](AGENT_LEARNER_README.md)** - 详细使用说明
- **[发布指南](PUBLISH_GUIDE.md)** - Cloudflare Pages 部署步骤
- **[文件清单](FILES_MANIFEST.md)** - 完整文件列表
- **[项目指令](CLAUDE.md)** - 架构和开发规范

# Task Plan: 修复学习功能 P0 和 P1 问题

## Goal
统一进度数据格式，修复断点续学机制，删除冗余代码，确保学习系统功能完整可用。

## Current Phase
Phase 2

## Phases

### Phase 1: 需求分析与问题确认
- [x] 分析现有数据结构差异
- [x] 确认 P0 和 P1 问题清单
- [x] 读取相关文件了解当前实现
- [x] 创建计划文件
- **Status:** complete

### Phase 2: 统一进度数据格式 (P0-1)
- [ ] 设计统一的 progress.json v2.0.0 格式
- [ ] 修改 SKILL.md 中的 update_learning_state() 函数
- [ ] 修改 SKILL.md 中的 resume_learning() 函数
- [ ] 修改 notes/scripts/data-loader.js 读取逻辑
- [ ] 编写数据迁移脚本 migrate_progress.py
- [ ] 测试迁移脚本
- **Status:** in_progress

### Phase 3: 修复断点续学功能 (P0-2)
- [ ] 确保 update_learning_state() 正确保存断点
- [ ] 确保 resume_learning() 正确读取断点
- [ ] 修复 current_step 逻辑
- [ ] 修复 completed_concepts 追踪
- [ ] 测试完整学习流程
- **Status:** pending

### Phase 4: 删除冗余代码 (P0-3)
- [ ] 删除 read_file_with_fallback() 的4种读取方法
- [ ] 简化为 20 行的 read_file_safe() 函数
- [ ] 更新所有调用点
- [ ] 验证功能未受影响
- **Status:** pending

### Phase 5: 修复笔记模板字段映射 (P1-1)
- [ ] 分析 generate_note() 函数的模板变量
- [ ] 确保所有字段正确映射
- [ ] 修复缺失的字段（如 course_name）
- [ ] 测试笔记生成
- **Status:** pending

### Phase 6: 完善数据迁移 (P1-2)
- [ ] 增强迁移脚本的错误处理
- [ ] 添加备份机制
- [ ] 添加迁移验证
- [ ] 编写使用文档
- **Status:** pending

### Phase 7: 测试与验证
- [ ] 运行完整测试套件 (test-all.sh)
- [ ] 测试断点续学场景
- [ ] 测试笔记生成和发布
- [ ] 验证网站进度显示
- [ ] 修复发现的问题
- **Status:** pending

### Phase 8: 交付与文档
- [ ] 更新 CLAUDE.md 文档
- [ ] 记录数据迁移步骤
- [ ] 提交所有修改
- [ ] 向用户交付
- **Status:** pending

## Key Questions
1. 统一的进度格式应该包含哪些字段？
2. 如何确保新旧格式平滑迁移？
3. 断点续学的状态机应该有哪些状态？
4. 笔记模板需要哪些必需字段？
5. 如何验证所有功能正常工作？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 使用统一的 progress.json 格式 | 避免两个文件不同步，简化代码 |
| 保留 status 字段替代 in_progress + completed | 更清晰的状态表示 |
| 删除 read_file_with_fallback() 的冗余方法 | Linus原则：简单直接，文件不存在就报错 |
| 编写 Python 迁移脚本 | 自动化迁移，避免手动错误 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| | 1 | |

## Notes
- 更新 phase 状态: pending → in_progress → complete
- 在重大决策前重新读取计划
- 记录所有错误，避免重复失败
- 遵循 Linus 原则：简单、直接、实用

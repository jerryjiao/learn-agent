# Agent Learner 文件清单

## 核心文件 (必需)

### Skill系统
```
.claude/skills/agent-learner/
├── SKILL.md                    # 核心学习逻辑 (500+行)
├── curriculum/
│   └── index.json              # 课程索引 (5模块,7项目)
└── templates/
    └── note.md                 # 笔记模板
```

### 数据文件
```
data/
└── progress.json               # 学习进度追踪

notes/
├── 00-example.md               # 示例笔记
├── index.html                  # 网站主页面
├── README.md                   # 网站说明
└── .gitignore                  # Git忽略文件
```

### 网站资源
```
notes/
├── styles/
│   └── theme.css               # 样式系统 (600+行)
└── scripts/
    ├── search.js               # 搜索功能
    ├── theme-toggle.js         # 主题切换
    └── data-loader.js          # 数据加载器
```

### 脚本工具
```
scripts/
├── validate.sh                 # 系统验证
├── test-all.sh                 # 完整测试 (31项)
└── publish.sh                  # 发布脚本
```

## 文档文件

```
├── AGENT_LEARNER_README.md     # 使用说明
├── PUBLISH_GUIDE.md            # 发布指南
├── PROJECT_COMPLETE.md         # 完成报告
└── FILES_MANIFEST.md           # 本文件
```

## 教案文件 (只读)

```
Agent_In_Action/
├── 01-agent-tool-mcp/          # 模块1
├── 02-agent-multi-role/        # 模块2
├── 03-agent-build-docker-deploy/ # 模块3
├── 04-agent-evaluation/        # 模块4
└── 05-agent-model-finetuning/  # 模块5
```

## 文件用途说明

### SKILL.md
- **用途**: Claude Code Skill核心逻辑
- **触发**: /learn, /quiz, /review, /status
- **功能**: 学习流程、题目生成、笔记生成

### curriculum/index.json
- **用途**: 课程元数据索引
- **内容**: 模块、项目、难度、主题
- **格式**: JSON

### data/progress.json
- **用途**: 学习进度追踪
- **内容**: 当前位置、完成状态、成绩
- **格式**: JSON

### notes/index.html
- **用途**: 笔记网站主页面
- **功能**: 导航、搜索、主题切换
- **技术**: HTML5 + CSS3 + JavaScript

### notes/styles/theme.css
- **用途**: 网站样式
- **功能**: 明暗主题、响应式布局
- **技术**: CSS3变量

### notes/scripts/*.js
- **search.js**: 搜索功能
- **theme-toggle.js**: 主题切换
- **data-loader.js**: 数据加载

### scripts/*.sh
- **validate.sh**: 验证系统配置
- **test-all.sh**: 运行31项测试
- **publish.sh**: 发布到Cloudflare Pages

## 文件依赖关系

```
SKILL.md
  ├─ 读取 → curriculum/index.json
  ├─ 读取 → Agent_In_Action/*/README.md
  ├─ 更新 → data/progress.json
  └─ 生成 → notes/*.md

index.html
  ├─ 加载 → styles/theme.css
  ├─ 加载 → scripts/*.js
  └─ 读取 → notes/*.md

publish.sh
  ├─ 读取 → notes/
  └─ 推送 → GitHub → Cloudflare Pages
```

## 文件大小统计

```
SKILL.md:         ~25 KB
index.json:       ~2 KB
theme.css:        ~20 KB
*.js:             ~10 KB (总计)
文档:             ~30 KB (总计)
```

总计: ~87 KB (不含教案)

## Git管理

### 已初始化仓库
- **位置**: notes/.git
- **分支**: main
- **提交**: 1个初始提交

### 已提交文件
```
notes/
├── .gitignore
├── 00-example.md
├── README.md
├── index.html
├── scripts/
│   ├── data-loader.js
│   ├── search.js
│   └── theme-toggle.js
└── styles/
    └── theme.css
```

## 备份建议

### 必需备份
- ✅ data/progress.json (学习进度)
- ✅ notes/*.md (学习笔记)
- ✅ .claude/ (Skill配置)

### 可选备份
- scripts/ (可重新生成)
- 文档/ (可重新生成)

### 无需备份
- Agent_In_Action/ (只读教案)

---

**更新时间**: 2026-01-13

#!/bin/bash

echo "🔍 Agent Learner 系统验证"
echo "=========================="
echo ""

# 检查目录结构
echo "📁 检查目录结构..."
dirs_ok=true

if [ -d ".claude/skills/agent-learner" ]; then
    echo "  ✅ Skill目录存在"
else
    echo "  ❌ Skill目录缺失"
    dirs_ok=false
fi

if [ -d "data" ]; then
    echo "  ✅ 数据目录存在"
else
    echo "  ❌ 数据目录缺失"
    dirs_ok=false
fi

if [ -d "notes" ]; then
    echo "  ✅ 笔记目录存在"
else
    echo "  ❌ 笔记目录缺失"
    dirs_ok=false
fi

echo ""

# 检查核心文件
echo "📄 检查核心文件..."
files_ok=true

if [ -f ".claude/skills/agent-learner/SKILL.md" ]; then
    echo "  ✅ SKILL.md 存在"
else
    echo "  ❌ SKILL.md 缺失"
    files_ok=false
fi

if [ -f ".claude/skills/agent-learner/curriculum/index.json" ]; then
    echo "  ✅ 课程索引存在"
    # 验证JSON格式
    if python3 -m json.tool .claude/skills/agent-learner/curriculum/index.json > /dev/null 2>&1; then
        echo "  ✅ JSON格式正确"
    else
        echo "  ❌ JSON格式错误"
        files_ok=false
    fi
else
    echo "  ❌ 课程索引缺失"
    files_ok=false
fi

if [ -f "data/progress.json" ]; then
    echo "  ✅ 进度文件存在"
    if python3 -m json.tool data/progress.json > /dev/null 2>&1; then
        echo "  ✅ JSON格式正确"
    else
        echo "  ❌ JSON格式错误"
        files_ok=false
    fi
else
    echo "  ❌ 进度文件缺失"
    files_ok=false
fi

echo ""

# 统计信息
echo "📊 统计信息"
if [ -f ".claude/skills/agent-learner/curriculum/index.json" ]; then
    total_modules=$(python3 -c "import json; f=open('.claude/skills/agent-learner/curriculum/index.json'); data=json.load(f); print(len(data['modules']))")
    total_projects=$(python3 -c "import json; f=open('.claude/skills/agent-learner/curriculum/index.json'); data=json.load(f); print(sum(len(m['projects']) for m in data['modules']))")
    echo "  📚 模块数: $total_modules"
    echo "  📝 项目数: $total_projects"
fi

notes_count=$(ls -1 notes/*.md 2>/dev/null | wc -l)
echo "  📖 笔记数: $notes_count"

echo ""

# 最终结果
if [ "$dirs_ok" = true ] && [ "$files_ok" = true ]; then
    echo "✅ 系统验证通过!"
    echo ""
    echo "🚀 准备就绪,开始学习:"
    echo "   /learn      - 开始学习"
    echo "   /status     - 查看进度"
    echo ""
    exit 0
else
    echo "❌ 系统验证失败,请检查上述错误"
    exit 1
fi

#!/bin/bash

# Agent Learner 系统完整测试脚本

echo "🧪 Agent Learner 完整测试"
echo "================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

test_count=0
pass_count=0
fail_count=0

run_test() {
    test_name=$1
    test_command=$2

    test_count=$((test_count + 1))
    echo "📋 测试 $test_count: $test_name"

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ 通过${NC}"
        pass_count=$((pass_count + 1))
    else
        echo -e "   ${RED}❌ 失败${NC}"
        fail_count=$((fail_count + 1))
    fi
    echo ""
}

echo "🔍 Phase 1: 文件结构测试"
echo "================================"

run_test "Skill目录存在" "[ -d .claude/skills/agent-learner ]"
run_test "SKILL.md存在" "[ -f .claude/skills/agent-learner/SKILL.md ]"
run_test "课程索引存在" "[ -f .claude/skills/agent-learner/curriculum/index.json ]"
run_test "笔记模板存在" "[ -f .claude/skills/agent-learner/templates/note.md ]"
run_test "数据目录存在" "[ -d data ]"
run_test "进度文件存在" "[ -f data/progress.json ]"
run_test "笔记目录存在" "[ -d notes ]"
run_test "网站HTML存在" "[ -f notes/index.html ]"
run_test "CSS样式存在" "[ -f notes/styles/theme.css ]"
run_test "搜索脚本存在" "[ -f notes/scripts/search.js ]"
run_test "主题切换脚本存在" "[ -f notes/scripts/theme-toggle.js ]"
run_test "数据加载脚本存在" "[ -f notes/scripts/data-loader.js ]"
run_test "发布脚本存在" "[ -f scripts/publish.sh ]"
run_test "验证脚本存在" "[ -f scripts/validate.sh ]"

echo ""
echo "🔍 Phase 2: JSON格式测试"
echo "================================"

run_test "课程索引JSON格式正确" "python3 -m json.tool .claude/skills/agent-learner/curriculum/index.json"
run_test "进度文件JSON格式正确" "python3 -m json.tool data/progress.json"

echo ""
echo "🔍 Phase 3: Git仓库测试"
echo "================================"

run_test "Notes Git仓库已初始化" "[ -d notes/.git ]"
run_test "Git有初始提交" "git -C notes log --oneline > /dev/null 2>&1"

echo ""
echo "🔍 Phase 4: 脚本权限测试"
echo "================================"

run_test "发布脚本可执行" "[ -x scripts/publish.sh ]"
run_test "验证脚本可执行" "[ -x scripts/validate.sh ]"

echo ""
echo "🔍 Phase 5: 内容验证测试"
echo "================================"

run_test "SKILL.md包含核心逻辑" "grep -q '工作流程' .claude/skills/agent-learner/SKILL.md"
run_test "课程索引包含模块" "grep -q 'modules' .claude/skills/agent-learner/curriculum/index.json"
run_test "HTML包含主题切换按钮" "grep -q 'theme-toggle' notes/index.html"
run_test "CSS包含暗色主题" "grep -q 'data-theme=\"dark\"' notes/styles/theme.css"
run_test "搜索JS包含搜索类" "grep -q 'class NoteSearch' notes/scripts/search.js"
run_test "主题切换JS包含主题类" "grep -q 'class ThemeToggle' notes/scripts/theme-toggle.js"

echo ""
echo "🔍 Phase 6: 功能完整性测试"
echo "================================"

# 检查模块数量
module_count=$(python3 -c "import json; f=open('.claude/skills/agent-learner/curriculum/index.json'); data=json.load(f); print(len(data['modules']))" 2>/dev/null || echo "0")
if [ "$module_count" -ge 5 ]; then
    echo -e "   ${GREEN}✅ 模块数量: $module_count (预期: ≥5)${NC}"
    pass_count=$((pass_count + 1))
else
    echo -e "   ${RED}❌ 模块数量: $module_count (预期: ≥5)${NC}"
    fail_count=$((fail_count + 1))
fi
test_count=$((test_count + 1))

# 检查项目数量
project_count=$(python3 -c "import json; f=open('.claude/skills/agent-learner/curriculum/index.json'); data=json.load(f); print(sum(len(m['projects']) for m in data['modules']))" 2>/dev/null || echo "0")
if [ "$project_count" -ge 7 ]; then
    echo -e "   ${GREEN}✅ 项目数量: $project_count (预期: ≥7)${NC}"
    pass_count=$((pass_count + 1))
else
    echo -e "   ${RED}❌ 项目数量: $project_count (预期: ≥7)${NC}"
    fail_count=$((fail_count + 1))
fi
test_count=$((test_count + 1))

echo ""
echo "🔍 Phase 7: 网站文件测试"
echo "================================"

run_test "notes目录有README" "[ -f notes/README.md ]"
run_test "notes目录有.gitignore" "[ -f notes/.gitignore ]"
run_test "notes目录有示例笔记" "[ -f notes/00-example.md ]"

echo ""
echo "📊 测试结果汇总"
echo "================================"
echo ""
echo "总测试数: $test_count"
echo -e "通过: ${GREEN}$pass_count${NC}"
echo -e "失败: ${RED}$fail_count${NC}"
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ 所有测试通过!                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "🎉 系统已准备就绪!"
    echo ""
    echo "📚 下一步:"
    echo "   1. 开始学习: /learn"
    echo "   2. 查看进度: /status"
    echo "   3. 发布网站: ./scripts/publish.sh"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ 部分测试失败                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "请检查上述失败的测试项"
    echo ""
    exit 1
fi

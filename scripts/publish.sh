#!/bin/bash

# Agent学习笔记发布脚本
# 支持: GitHub Pages | Cloudflare Pages
# 智能重试: 最多3次,间隔递增

set -e

# ============================================
# 配置变量
# ============================================
PLATFORM=""              # github | cloudflare (默认自动检测)
MAX_RETRIES=3            # 最大重试次数
RETRY_DELAYS=(2 5 10)    # 重试延迟(秒)

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# 参数解析
# ============================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --platform <github|cloudflare>  指定发布平台"
            echo "  --help, -h                       显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0                              # 自动检测平台"
            echo "  $0 --platform github           # 强制使用 GitHub Pages"
            echo "  $0 --platform cloudflare       # 强制使用 Cloudflare Pages"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# ============================================
# 辅助函数
# ============================================

# 智能重试函数
retry_command() {
    local description="$1"
    shift
    local cmd=("$@")

    for attempt in $(seq 1 $MAX_RETRIES); do
        echo -e "${BLUE}⏳ [$attempt/$MAX_RETRIES] $description...${NC}"

        if "${cmd[@]}" 2>&1; then
            echo -e "${GREEN}✅ $description 成功${NC}"
            return 0
        else
            local exit_code=$?

            if [ $attempt -lt $MAX_RETRIES ]; then
                local delay=${RETRY_DELAYS[$((attempt-1))]}
                echo -e "${YELLOW}⚠️  $description 失败 (退出码: $exit_code)${NC}"
                echo -e "${YELLOW}   ${delay}秒后重试...${NC}"
                sleep $delay
            else
                echo -e "${RED}❌ $description 失败,已达到最大重试次数${NC}"
                return 1
            fi
        fi
    done
}

# 检测 GitHub Pages 是否已配置
check_github_pages() {
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [ -z "$remote_url" ]; then
        echo "false"
        return
    fi

    # 检查是否有 gh-pages 分支或 GitHub Actions workflow
    if git ls-remote --heads origin gh-pages 2>/dev/null | grep -q "gh-pages"; then
        echo "true"
        return
    fi

    if [ -f ".github/workflows/pages.yml" ] || \
       [ -f ".github/workflows/static.yml" ]; then
        echo "true"
        return
    fi

    echo "false"
}

# 自动检测发布平台
detect_platform() {
    local has_github_pages=$(check_github_pages)

    if [ "$has_github_pages" = "true" ]; then
        echo "github"
    else
        echo "cloudflare"
    fi
}

# 提取仓库所有者和名称
extract_repo_info() {
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    # 支持: git@github.com:owner/repo.git 或 https://github.com/owner/repo.git
    if [[ "$remote_url" =~ git@github.com:([^/]+)/(.+)\.git ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    elif [[ "$remote_url" =~ https://github\.com/([^/]+)/(.+)\.git ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    elif [[ "$remote_url" =~ https://github\.com/([^/]+)/(.+) ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        echo ""
    fi
}

# ============================================
# 主流程
# ============================================

echo "🚀 Agent学习笔记发布脚本"
echo "================================"
echo ""

# 检查是否在notes目录中
if [ ! -d "notes/.git" ]; then
    echo -e "${RED}❌ 错误: 未找到Git仓库${NC}"
    echo "请确保在项目根目录运行此脚本"
    exit 1
fi

# 进入notes目录
cd notes

# 确定发布平台
if [ -z "$PLATFORM" ]; then
    PLATFORM=$(detect_platform)
    echo -e "${BLUE}🔍 自动检测平台: $PLATFORM${NC}"
    echo ""
fi

# 同步进度数据
echo "📊 同步学习进度数据..."
if [ -f "../data/progress.json" ]; then
    cp ../data/progress.json ./progress.json
    echo -e "${GREEN}✅ 进度数据已同步${NC}"
else
    echo -e "${YELLOW}⚠️  未找到进度数据文件${NC}"
fi

# 生成搜索索引
echo "🔍 生成搜索索引..."
if [ -f "../scripts/generate-notes-index.sh" ]; then
    bash ../scripts/generate-notes-index.sh
    echo -e "${GREEN}✅ 搜索索引已生成${NC}"
else
    echo -e "${YELLOW}⚠️  未找到索引生成脚本${NC}"
fi

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  检测到未提交的更改${NC}"

    # 添加所有更改
    echo "📝 正在添加更改..."
    git add .

    # 请求提交消息
    echo ""
    echo "请输入提交消息 (留空使用默认消息):"
    read -r commit_message

    if [ -z "$commit_message" ]; then
        commit_message="更新笔记 $(date +'%Y-%m-%d %H:%M:%S')"
    fi

    # 提交
    echo "💾 正在提交..."
    if git commit -m "$commit_message"; then
        echo -e "${GREEN}✅ 提交成功${NC}"
    else
        echo -e "${RED}❌ 提交失败${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 没有未提交的更改${NC}"
fi

# 检查远程仓库
if ! git remote get-url origin > /dev/null 2>&1; then
    echo ""
    echo -e "${YELLOW}⚠️  未配置远程仓库${NC}"
    echo ""
    echo "请按以下步骤配置:"
    echo ""
    echo "1. 在GitHub创建新仓库"
    echo "   访问: https://github.com/new"
    echo "   仓库名建议: agent-learning-notes"
    echo ""
    echo "2. 添加远程仓库:"
    echo "   git remote add origin https://github.com/你的用户名/agent-learning-notes.git"
    echo ""
    echo "3. 推送代码:"
    echo "   git push -u origin main"
    echo ""
    exit 0
fi

# 推送到远程(带智能重试)
echo ""
echo "📤 远程仓库已配置"
remote_url=$(git remote get-url origin)
echo "   URL: $remote_url"
echo ""

if ! retry_command "推送到 GitHub" git push origin main; then
    echo ""
    echo -e "${RED}❌ 推送失败,已达到最大重试次数${NC}"
    echo ""
    echo "🔧 故障排除:"
    echo ""
    echo "1. 检查网络连接:"
    echo "   ping github.com"
    echo ""
    echo "2. 检查SSH密钥(如果使用SSH):"
    echo "   ssh -T git@github.com"
    echo ""
    echo "3. 检查分支名称:"
    echo "   git branch"
    echo ""
    echo "4. 手动重试:"
    echo "   git push origin main"
    echo ""
    exit 1
fi

# 根据平台提供后续步骤
echo ""
echo -e "${GREEN}✅ 发布完成!${NC}"
echo ""

if [ "$PLATFORM" = "github" ]; then
    # 提取仓库信息
    repo_info=$(extract_repo_info)
    if [ -n "$repo_info" ]; then
        owner=$(echo "$repo_info" | awk '{print $1}')
        repo=$(echo "$repo_info" | awk '{print $2}')

        echo "📌 GitHub Pages 部署"
        echo ""
        echo "如果这是第一次使用 GitHub Pages:"
        echo ""
        echo "1. 访问仓库设置:"
        echo "   https://github.com/$owner/$repo/settings/pages"
        echo ""
        echo "2. 配置部署源:"
        echo "   - Source: Deploy from a branch"
        echo "   - Branch: main / root"
        echo ""
        echo "3. 保存后等待部署 (约1-2分钟)"
        echo ""
        echo "4. 访问 URL:"
        echo "   https://$owner.github.io/$repo/"
        echo ""
    else
        echo "📌 GitHub Pages 部署"
        echo ""
        echo "请访问仓库设置页面配置 GitHub Pages:"
        echo "https://github.com/你的用户名/你的仓库/settings/pages"
        echo ""
    fi
else
    echo "📌 Cloudflare Pages 部署"
    echo ""
    echo "如果这是第一次发布,请配置 Cloudflare Pages:"
    echo ""
    echo "1. 访问: https://dash.cloudflare.com/"
    echo "2. 进入: Workers & Pages > Pages"
    echo "3. 点击: 创建项目 > 连接到Git"
    echo "4. 选择此仓库并配置:"
    echo "   - 构建命令: (留空,静态网站无需构建)"
    echo "   - 构建输出目录: /"
    echo "   - 根目录: notes"
    echo "5. 点击: 保存并部署"
    echo ""
    echo "部署完成后,你会收到一个URL,类似:"
    echo "  https://agent-learning-notes.pages.dev"
    echo ""
fi

echo "🎉 完成!"

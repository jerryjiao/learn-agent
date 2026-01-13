#!/bin/bash

# Agent学习笔记发布脚本
# 用于自动发布笔记到Cloudflare Pages

set -e

echo "🚀 Agent学习笔记发布脚本"
echo "================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查是否在notes目录中
if [ ! -d "notes/.git" ]; then
    echo -e "${RED}❌ 错误: 未找到Git仓库${NC}"
    echo "请确保在项目根目录运行此脚本"
    exit 1
fi

# 同步进度数据到notes目录
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
    git commit -m "$commit_message"
    echo -e "${GREEN}✅ 提交成功${NC}"
else
    echo -e "${GREEN}✅ 没有未提交的更改${NC}"
fi

# 检查远程仓库
if git remote get-url origin > /dev/null 2>&1; then
    echo ""
    echo "📤 远程仓库已配置"
    remote_url=$(git remote get-url origin)
    echo "   URL: $remote_url"

    # 推送到远程
    echo ""
    echo "⬆️  正在推送到GitHub..."
    if git push origin main; then
        echo -e "${GREEN}✅ 推送成功!${NC}"
    else
        echo -e "${RED}❌ 推送失败${NC}"
        exit 1
    fi
else
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
    echo "4. 连接到Cloudflare Pages:"
    echo "   - 访问: https://dash.cloudflare.com/"
    echo "   - 进入: Workers & Pages > Pages"
    echo "   - 点击: 创建项目 > 连接到Git"
    echo "   - 选择: 你的GitHub仓库"
    echo "   - 构建设置:"
    echo "     构建命令: (留空)"
    echo "     构建输出目录: /"
    echo "     根目录: /notes"
    echo ""
    exit 0
fi

# 提示Cloudflare Pages设置
echo ""
echo -e "${GREEN}✅ 发布完成!${NC}"
echo ""
echo "📌 下一步:"
echo ""
echo "如果这是第一次发布,请配置Cloudflare Pages:"
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
echo "🎉 完成!"

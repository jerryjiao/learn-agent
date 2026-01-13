#!/bin/bash

# 生成笔记索引文件
# 用于网站搜索功能

set -e

NOTES_DIR="notes"
OUTPUT_FILE="$NOTES_DIR/notes.json"

echo "🔍 生成笔记索引..."

# 检查目录
if [ ! -d "$NOTES_DIR" ]; then
    echo "❌ 错误: notes 目录不存在"
    exit 1
fi

# 构建JSON数组
notes_json=""

for file in "$NOTES_DIR"/*.md; do
    # 跳过 README
    if [[ "$file" == *"README.md" ]]; then
        continue
    fi

    filename=$(basename "$file" .md)

    # 提取标题
    title=$(grep -m 1 "^# " "$file" | sed 's/^# //')
    if [ -z "$title" ]; then
        title="$filename"
    fi

    # 提取摘要（取前3行非空内容）
    excerpt=$(head -30 "$file" | grep -v "^#" | grep -v "^$" | head -3 | sed 's/"//g' | tr '\n' ' ')
    excerpt=$(echo "$excerpt" | xargs)  # 去除多余空格
    if [ -z "$excerpt" ]; then
        excerpt="暂无摘要"
    fi

    # 截断过长摘要
    excerpt=$(echo "$excerpt" | cut -c1-80)

    # 获取日期
    date=$(date -r "$file" "+%Y-%m-%d" 2>/dev/null || echo "2026-01-13")

    # 添加到JSON数组
    if [ -n "$notes_json" ]; then
        notes_json="$notes_json,"
    fi

    notes_json="$notes_json
    {
      \"id\": \"$filename\",
      \"title\": \"$title\",
      \"path\": \"$filename.md\",
      \"date\": \"$date\",
      \"excerpt\": \"$excerpt...\"
    }"
done

# 计算笔记数量
count=$(echo "$notes_json" | grep -c '"id":')

# 生成最终JSON
cat > "$OUTPUT_FILE" << EOF
{
  "generated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total": $count,
  "notes": [$notes_json
  ]
}
EOF

echo "✅ 索引生成完成: $OUTPUT_FILE"
echo "📊 共 $count 篇笔记"

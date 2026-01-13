#!/usr/bin/env python3
"""
进度数据迁移脚本
从旧格式迁移到统一格式 v2.0.0

旧格式 (data/progress.json):
{
  "current": "01-1",
  "progress": {
    "01-1": {
      "in_progress": "2026-01-13T13:00:00Z",
      "current_step": "concept_1",
      "completed_concepts": []
    }
  }
}

新格式 (统一):
{
  "version": "2.0.0",
  "current": "01-1",
  "progress": {
    "01-1": {
      "status": "in_progress",
      "started_at": "2026-01-13T13:00:00Z",
      "completed_at": "2026-01-13T14:00:00Z",  // optional
      "current_step": "concept_1",
      "completed_concepts": [],
      "quiz_score": 85,  // optional
      "quiz_taken_at": "2026-01-13T14:00:00Z"  // optional
    }
  }
}
"""

import json
import shutil
from datetime import datetime
from pathlib import Path


def backup_file(file_path: Path) -> Path:
    """创建备份文件"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = file_path.parent / f"{file_path.name}.backup_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 备份已创建: {backup_path}")
    return backup_path


def migrate_old_format(old_data: dict) -> dict:
    """迁移旧格式到新格式"""
    new_progress = {}

    for project_id, project_data in old_data.get('progress', {}).items():
        new_project_data = {}

        # 检查是否已是新格式
        if 'status' in project_data:
            # 新格式，直接复制
            new_project_data = project_data
        else:
            # 旧格式，需要迁移
            if 'in_progress' in project_data:
                new_project_data['status'] = 'in_progress'
                new_project_data['started_at'] = project_data['in_progress']
            elif 'completed' in project_data:
                new_project_data['status'] = 'completed'
                new_project_data['started_at'] = project_data['completed']
                new_project_data['completed_at'] = project_data['completed']

            # 复制其他字段
            if 'current_step' in project_data:
                new_project_data['current_step'] = project_data['current_step']
            else:
                new_project_data['current_step'] = 'concept_1'

            if 'completed_concepts' in project_data:
                new_project_data['completed_concepts'] = project_data['completed_concepts']
            else:
                new_project_data['completed_concepts'] = []

            if 'score' in project_data:
                new_project_data['quiz_score'] = project_data['score']
                new_project_data['quiz_taken_at'] = project_data.get('completed', datetime.now().isoformat())

        new_progress[project_id] = new_project_data

    return {
        'version': '2.0.0',
        'current': old_data.get('current'),
        'progress': new_progress
    }


def validate_new_format(new_data: dict) -> list[str]:
    """验证新格式，返回错误列表"""
    errors = []

    # 检查顶层字段
    if 'version' not in new_data:
        errors.append("缺少 version 字段")
    elif new_data['version'] != '2.0.0':
        errors.append(f"版本号不匹配: {new_data['version']}")

    if 'current' not in new_data:
        errors.append("缺少 current 字段")

    if 'progress' not in new_data:
        errors.append("缺少 progress 字段")
    else:
        # 检查每个项目的字段
        for project_id, project_data in new_data['progress'].items():
            if 'status' not in project_data:
                errors.append(f"项目 {project_id} 缺少 status 字段")
            elif project_data['status'] not in ['in_progress', 'completed']:
                errors.append(f"项目 {project_id} 的 status 值无效: {project_data['status']}")

            if 'started_at' not in project_data:
                errors.append(f"项目 {project_id} 缺少 started_at 字段")

            if project_data.get('status') == 'completed' and 'completed_at' not in project_data:
                errors.append(f"项目 {project_id} 状态为 completed 但缺少 completed_at 字段")

    return errors


def main():
    """主函数"""
    print("=" * 70)
    print("进度数据迁移脚本 v2.0.0")
    print("=" * 70)

    # 文件路径
    progress_file = Path('data/progress.json')

    # 检查文件是否存在
    if not progress_file.exists():
        print(f"❌ 错误: 进度文件不存在: {progress_file}")
        return 1

    # 读取旧数据
    print(f"\n📖 读取进度文件: {progress_file}")
    try:
        with open(progress_file, 'r', encoding='utf-8') as f:
            old_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ 错误: JSON 格式无效 - {e}")
        return 1

    print(f"✅ 成功读取进度数据")
    print(f"   - 版本: {old_data.get('version', '未知')}")
    print(f"   - 当前项目: {old_data.get('current', '无')}")
    print(f"   - 项目总数: {len(old_data.get('progress', {}))}")

    # 创建备份
    print(f"\n💾 创建备份...")
    backup_path = backup_file(progress_file)

    # 迁移数据
    print(f"\n🔄 迁移数据格式...")
    new_data = migrate_old_format(old_data)

    # 验证新格式
    print(f"\n🔍 验证新格式...")
    errors = validate_new_format(new_data)

    if errors:
        print(f"❌ 验证失败，发现 {len(errors)} 个错误:")
        for error in errors:
            print(f"   - {error}")
        print(f"\n💡 提示: 备份文件位于: {backup_path}")
        print(f"💡 提示: 原文件未修改")
        return 1
    else:
        print(f"✅ 验证通过")

    # 写入新数据
    print(f"\n💾 写入新格式...")
    try:
        with open(progress_file, 'w', encoding='utf-8') as f:
            json.dump(new_data, f, indent=2, ensure_ascii=False)
        print(f"✅ 成功写入新格式")
    except Exception as e:
        print(f"❌ 错误: 写入失败 - {e}")
        print(f"💡 提示: 备份文件位于: {backup_path}")
        return 1

    # 显示迁移结果
    print(f"\n📊 迁移结果:")
    print(f"   - 版本: {new_data['version']}")
    print(f"   - 当前项目: {new_data.get('current', '无')}")
    print(f"   - 项目总数: {len(new_data['progress'])}")

    for project_id, project_data in new_data['progress'].items():
        status = project_data.get('status', '未知')
        step = project_data.get('current_step', '无')
        concepts = len(project_data.get('completed_concepts', []))
        print(f"   - {project_id}: {status}, 步骤={step}, 已学概念={concepts}")

    print(f"\n✅ 迁移完成!")
    print(f"💡 提示: 备份文件位于: {backup_path}")
    print(f"💡 提示: 如需回滚，请运行: cp {backup_path} {progress_file}")

    return 0


if __name__ == '__main__':
    exit(main())

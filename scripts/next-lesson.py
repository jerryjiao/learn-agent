#!/usr/bin/env python3
"""
课程顺序计算工具
根据 curriculum/index.json 计算下一个应该学习的课程
"""

import json
import sys

def get_all_projects(curriculum_file):
    """获取所有项目，按顺序排列"""
    with open(curriculum_file, 'r') as f:
        curriculum = json.load(f)

    projects = []
    for module in curriculum['modules']:
        for project in module['projects']:
            projects.append({
                'id': project['id'],
                'name': project['name'],
                'difficulty': project['difficulty'],
                'module': module['name']
            })
    return projects

def get_next_project_id(current_id, curriculum_file='.claude/skills/agent-learner/curriculum/index.json'):
    """
    获取下一个项目的ID

    Args:
        current_id: 当前项目ID (如 '01-1')
        curriculum_file: 课程索引文件路径

    Returns:
        下一个项目ID，如果已经是最后一个则返回 None
    """
    projects = get_all_projects(curriculum_file)

    # 找到当前项目的索引
    current_index = None
    for i, project in enumerate(projects):
        if project['id'] == current_id:
            current_index = i
            break

    if current_index is None:
        # 当前项目不存在，返回第一个
        return projects[0]['id'] if projects else None

    # 返回下一个项目
    next_index = current_index + 1
    if next_index < len(projects):
        return projects[next_index]['id']

    # 已经是最后一个项目
    return None

def get_first_uncompleted(progress_file, curriculum_file):
    """
    获取第一个未完成的项目

    Args:
        progress_file: 进度文件路径
        curriculum_file: 课程索引文件路径

    Returns:
        第一个未完成的项目ID
    """
    with open(progress_file, 'r') as f:
        progress = json.load(f)

    # 获取所有项目
    projects = get_all_projects(curriculum_file)

    # 找到第一个未完成的项目
    for project in projects:
        project_id = project['id']
        if project_id not in progress.get('progress', {}):
            return project_id

    # 所有项目都已完成
    return None

def show_all_projects():
    """显示所有课程列表"""
    projects = get_all_projects('.claude/skills/agent-learner/curriculum/index.json')

    print("📚 所有课程列表 (按学习顺序):")
    print("=" * 60)

    for i, project in enumerate(projects, 1):
        status = ""
        # 简单的序号显示
        print(f"{i:2d}. {project['id']} | {project['name']:40s} | {project['difficulty']}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        if sys.argv[1] == '--list':
            show_all_projects()
        else:
            current_id = sys.argv[1]
            next_id = get_next_project_id(current_id)
            if next_id:
                print(f"下一个课程: {next_id}")
            else:
                print("已经是最后一个课程了！")
    else:
        # 默认显示列表
        show_all_projects()

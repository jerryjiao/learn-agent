# Agent Learner Skill

## 触发条件

当用户想要学习Agent开发课程时使用此Skill:
- 输入 `/learn` - 开始或继续学习
- 输入 `/learn [课程ID]` - 学习指定课程 (如 `/learn 01-1`)
- 输入 `/quiz [难度]` - 测试当前课程 (`easy`/`medium`/`hard`)
- 输入 `/review [课程ID]` - 复习已学课程
- 输入 `/status` - 查看学习进度
- 输入 `/publish` - 发布笔记到网页

## 工作流程

### 阶段1: 初始化

1. 读取课程索引 `curriculum/index.json`
2. 读取学习进度 `data/progress.json`
3. 确定当前学习位置:
   - 如果用户指定课程ID,跳转到该课程
   - 如果未指定:
     - 优先从 `progress.current` 读取当前位置
     - 如果 `current` 为空,使用 `get_first_uncompleted()` 找第一个未完成的
     - 如果所有课程都完成,提示用户

**代码示例:**
```python
import json

def determine_start_point(user_specified_id=None):
    """确定学习起点"""
    # 读取课程和进度
    with open('.claude/skills/agent-learner/curriculum/index.json') as f:
        curriculum = json.load(f)

    with open('data/progress.json') as f:
        progress = json.load(f)

    # 确定起点
    if user_specified_id:
        return user_specified_id
    elif progress.get('current'):
        return progress['current']
    else:
        # 找第一个未完成的
        return get_first_uncompleted(progress)
```

### 阶段2: 加载课程内容

**重要原则**:
- **优先读取 ipynb 文件** - Jupyter Notebook 是主要学习材料，在初始化阶段完整加载
- **py 文件按需读取** - Python 文件可以在学习过程中根据需要读取，不强制初始加载

1. 根据课程ID定位到具体路径
2. 读取对应的README.md文件
3. **智能读取代码文件**（根据 `code_paths` 字段）:
   - **优先处理 `.ipynb` 文件**:
     - 对于 `type="notebook"` 或 code_paths 包含 `.ipynb` 的课程
     - 解析 notebook,提取所有 code 和 markdown cells
     - 这是主要学习材料，必须完整加载
   - **按需处理 `.py` 文件**:
     - 仅在需要深入代码细节时读取
     - 或在讲解具体概念时动态加载
     - 避免一次性加载过多内容
   - 对于 `code_paths` 为空的项目: 跳过代码读取，仅使用 README 内容
4. 解析课程结构:
   - 提取核心概念 (2-3个)
   - 提取代码示例 (主要来自 ipynb 文件)
   - 识别关键知识点

**代码示例 - 优化的内容加载逻辑（ipynb 优先，py 按需）:**
```python
import json
import subprocess

def read_file_safe(file_path):
    """
    简化的文件读取函数（Linus原则：简单直接）

    Args:
        file_path: 文件路径

    Returns:
        str: 文件内容，文件不存在时返回空字符串
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            print(f"✅ 读取成功: {file_path} ({len(content)} 字符)")
            return content
    except FileNotFoundError:
        print(f"❌ 文件不存在: {file_path}")
        return ""
    except Exception as e:
        print(f"❌ 读取失败: {file_path} - {e}")
        return ""


def load_course_content(project_id, curriculum_file='.claude/skills/agent-learner/curriculum/index.json'):
    """加载课程内容（优先读取 ipynb，py 文件按需）"""
    # 1. 读取课程索引
    with open(curriculum_file) as f:
        curriculum = json.load(f)

    # 2. 查找项目配置
    project = find_project_by_id(curriculum, project_id)
    if not project:
        raise ValueError(f"项目 {project_id} 不存在")

    module = find_module_by_project(curriculum, project)
    module_path = module['path']
    project_path = project['path']
    project_type = project.get('type', 'default')

    # 3. 读取 README.md（带容错机制）
    readme_path = f"{module_path}/{project_path}/README.md"
    readme_content = read_file_safe(readme_path)

    if not readme_content:
        print(f"❌ 错误: 无法读取 README 文件: {readme_path}")

    # 4. 懒加载 .ipynb 文件（扫描元数据，按需加载内容）
    notebook_metadata = {}  # {notebook_path: metadata}
    notebook_files = []
    py_files = []

    # 分类处理 code_paths
    for code_path in project.get('code_paths', []):
        if code_path.endswith('.ipynb'):
            notebook_files.append(code_path)
        elif code_path.endswith('.py'):
            py_files.append(code_path)

    # 扫描 notebook 元数据（不加载内容）
    if notebook_files:
        for notebook_path in notebook_files:
            full_path = f"{module_path}/{project_path}/{notebook_path}"
            print(f"🔍 扫描 Notebook: {notebook_path}")
            try:
                metadata = scan_notebook_metadata(full_path)
                if metadata:
                    notebook_metadata[full_path] = metadata
                    # 显示加载预估
                    tokens = metadata['estimated_tokens']
                    print(f"  ✅ 总 cells: {metadata['total_cells']}")
                    print(f"  📊 章节: {len(metadata['sections'])} 个")
                    print(f"  💾 预估 tokens: 元数据={tokens['metadata']}, 完整={tokens['full']}, 核心={tokens['core_only']}")
            except FileNotFoundError:
                print(f"⚠️ 警告: Notebook 文件未找到: {full_path}")
    elif project_type == "notebook":
        # 兼容旧配置：type=notebook 但 code_paths 为空
        notebook_path = f"{project_path}.ipynb"
        full_path = f"{module_path}/{notebook_path}"
        print(f"🔍 扫描 Notebook: {notebook_path}")
        try:
            metadata = scan_notebook_metadata(full_path)
            if metadata:
                notebook_metadata[full_path] = metadata
        except FileNotFoundError:
            print(f"⚠️ 警告: Notebook 文件未找到: {full_path}")

    # Python 文件不在这里加载，仅记录路径供按需读取
    py_file_paths = [f"{module_path}/{project_path}/{p}" for p in py_files]

    return {
        'readme': readme_content,
        'notebook_metadata': notebook_metadata,  # 元数据（轻量级）
        'code_snippets': [],  # 初始为空，按需加载
        'py_file_paths': py_file_paths,
        'project': project,
        'module': module,
        'has_notebooks': len(notebook_files) > 0,
        'has_py_files': len(py_files) > 0
    }

def load_py_file_on_demand(py_file_path):
    """按需加载 Python 文件（仅在需要时调用）"""
    try:
        code_content = read(py_file_path)
        return {
            'title': py_file_path.split('/')[-1],
            'code': code_content,
            'language': 'python',
            'source': py_file_path,
            'description': f'来源文件: {py_file_path}'
        }
    except FileNotFoundError:
        print(f"⚠️ 警告: Python 文件未找到: {py_file_path}")
        return None
```

def scan_notebook_metadata(notebook_path):
    """
    快速扫描 notebook，提取元数据和章节结构

    Args:
        notebook_path: notebook 文件路径

    Returns:
        dict: {
            'total_cells': int,
            'sections': [
                {
                    'id': int,
                    'title': str,
                    'start_cell': int,
                    'end_cell': int,
                    'cell_count': int,
                    'skip_by_default': bool  # 是否默认跳过（如环境配置）
                }
            ],
            'core_concepts': [str],  # 核心概念列表
            'estimated_tokens': {
                'metadata': int,
                'full': int,
                'core_only': int
            }
        }
    """
    import json
    import re

    try:
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook_data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"⚠️ 无法解析 notebook: {notebook_path} - {e}")
        return None

    cells = notebook_data.get('cells', [])
    total_cells = len(cells)

    # 识别章节和跳过规则
    sections = []
    current_section = {
        'id': 0,
        'title': '开始',
        'start_cell': 0,
        'end_cell': 0,
        'cell_count': 0,
        'skip_by_default': False
    }

    skip_keywords = ['环境', '配置', '安装', 'setup', 'config', 'install']

    for idx, cell in enumerate(cells):
        cell_type = cell.get('cell_type', '')
        source = ''.join(cell.get('source', []))

        # 检测章节标题（markdown 中的 ## 或 ### 标题）
        if cell_type == 'markdown':
            match = re.match(r'^##\s+(.+)', source.strip())
            if not match:
                # 也尝试匹配三级标题
                match = re.match(r'^###\s+(.+)', source.strip())
            if match:
                # 保存上一个章节
                if current_section['cell_count'] > 0:
                    sections.append(current_section.copy())

                # 开始新章节
                title = match.group(1).strip()
                current_section = {
                    'id': len(sections),
                    'title': title,
                    'start_cell': idx,
                    'end_cell': idx,
                    'cell_count': 0,
                    'skip_by_default': any(kw in title.lower() for kw in skip_keywords)
                }

        current_section['end_cell'] = idx
        current_section['cell_count'] += 1

    # 保存最后一个章节
    if current_section['cell_count'] > 0:
        sections.append(current_section)

    # 提取核心概念（从章节标题中）
    core_concepts = []
    for section in sections:
        if not section['skip_by_default']:
            # 从标题中提取关键词
            title = section['title']
            if '（' in title:
                concept = title.split('（')[0].strip()
            elif '(' in title:
                concept = title.split('(')[0].strip()
            else:
                concept = title
            if len(concept) < 20:  # 避免过长的标题
                core_concepts.append(concept)

    # Token 估算
    estimated_metadata = 500
    estimated_full = total_cells * 3500  # 每个_cell 约 3.5K tokens
    core_cells = sum(s['cell_count'] for s in sections if not s['skip_by_default'])
    estimated_core_only = core_cells * 3500

    return {
        'total_cells': total_cells,
        'sections': sections,
        'core_concepts': core_concepts[:10],  # 最多 10 个
        'estimated_tokens': {
            'metadata': estimated_metadata,
            'full': estimated_full,
            'core_only': estimated_core_only
        }
    }


def load_notebook_section(notebook_path, section_id, metadata):
    """
    按需加载指定章节的内容

    Args:
        notebook_path: notebook 文件路径
        section_id: 章节 ID（从 metadata['sections'] 中获取）
        metadata: scan_notebook_metadata() 返回的元数据

    Returns:
        list: snippets（与 parse_notebook 返回格式相同）
    """
    import json

    try:
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook_data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"⚠️ 无法加载章节 {section_id}: {e}")
        return []

    # 找到指定章节
    section = None
    for s in metadata.get('sections', []):
        if s['id'] == section_id:
            section = s
            break

    if not section:
        print(f"⚠️ 章节 {section_id} 不存在")
        return []

    # 只加载指定范围的 cells
    start = section['start_cell']
    end = section['end_cell']
    cells = notebook_data.get('cells', [])[start:end+1]

    print(f"📓 加载章节 {section_id}: {section['title']} (cells {start}-{end}, 共 {len(cells)} 个)")

    # 解析 cells（与 parse_notebook 相同逻辑）
    snippets = []
    for idx, cell in enumerate(cells):
        global_idx = start + idx  # 全局 cell 索引
        cell_type = cell.get('cell_type', '')
        source_lines = cell.get('source', [])
        content = ''.join(source_lines) if isinstance(source_lines, list) else source_lines

        if not content.strip():
            continue

        if cell_type == 'code':
            snippets.append({
                'title': f'📓 代码单元格 {global_idx + 1}',
                'code': content,
                'language': 'python',
                'source': f'{notebook_path}#cell-{global_idx}',
                'description': f'章节: {section["title"]}'
            })
        elif cell_type == 'markdown':
            snippets.append({
                'title': f'📝 说明 {global_idx + 1}',
                'code': content,
                'language': 'markdown',
                'source': f'{notebook_path}#cell-{global_idx}',
                'description': f'章节: {section["title"]}'
            })

    return snippets


def parse_notebook(notebook_path):
    """解析 Jupyter notebook 文件"""
    try:
        # Read 工具会自动解析 .ipynb 并返回处理后的内容
        # 我们需要读取原始 JSON 进行解析
        import json
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook_data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"⚠️ 警告: 无法解析 notebook 文件: {notebook_path} - {e}")
        return []

    snippets = []
    for idx, cell in enumerate(notebook_data.get('cells', [])):
        cell_type = cell.get('cell_type', '')
        source_lines = cell.get('source', [])
        content = ''.join(source_lines) if isinstance(source_lines, list) else source_lines

        if not content.strip():
            continue

        if cell_type == 'code':
            snippets.append({
                'title': f'📓 代码单元格 {idx + 1}',
                'code': content,
                'language': 'python',
                'source': f'{notebook_path}#cell-{idx}',
                'description': f'Notebook 第 {idx + 1} 个代码单元'
            })
        elif cell_type == 'markdown':
            # Markdown 内容作为说明
            snippets.append({
                'title': f'📝 说明 {idx + 1}',
                'code': content,
                'language': 'markdown',
                'source': f'{notebook_path}#cell-{idx}',
                'description': 'Notebook 中的说明文档'
            })

    return snippets

def find_project_by_id(curriculum, project_id):
    """根据项目ID查找项目配置"""
    for module in curriculum.get('modules', []):
        for project in module.get('projects', []):
            if project['id'] == project_id:
                return project
    return None

def find_module_by_project(curriculum, project):
    """根据项目查找所属模块"""
    for module in curriculum.get('modules', []):
        for p in module.get('projects', []):
            if p['id'] == project['id']:
                return module
    return None
```

### 阶段3: 引导式学习循环

对每个核心概念执行:

```
1. 【讲解概念】
   - 用简单语言解释概念
   - 说明为什么需要这个概念
   - 举例说明应用场景

2. 【展示代码】
   - 从 `code_snippets` 列表中选择相关片段
   - 显示代码来源和内容（限制长度避免 token 超限）
   - 逐行解释关键部分
   - 说明代码的作用

**代码示例 - 展示代码片段（支持 ipynb + py 按需）:**
```python
def show_notebook_sections(course_data):
    """
    展示 notebook 章节列表，让用户选择要学习的章节

    Args:
        course_data: load_course_content() 返回的数据

    Returns:
        list: 用户选择的章节 ID 列表
    """
    notebook_metadata = course_data.get('notebook_metadata', {})

    if not notebook_metadata:
        print("📄 此课程没有 notebook 文件")
        return []

    # 只处理第一个 notebook（通常一个课程只有一个主要 notebook）
    notebook_path = list(notebook_metadata.keys())[0]
    metadata = notebook_metadata[notebook_path]
    sections = metadata.get('sections', [])

    print(f"\n📚 课程章节: {notebook_path.split('/')[-1]}")
    print("=" * 70)

    # 显示章节列表
    core_sections = []
    for section in sections:
        skip_mark = "⏭️  " if section['skip_by_default'] else "📖 "
        section_info = f"{skip_mark} #{section['id']} {section['title']} ({section['cell_count']} cells)"
        print(f"  {section_info}")

        if not section['skip_by_default']:
            core_sections.append(section)

    print("\n💡 提示: 环境配置章节已自动跳过")
    print(f"📊 Token 预估: 元数据={metadata['estimated_tokens']['metadata']}, 完整={metadata['estimated_tokens']['full']:,}")

    # 返回核心章节（非跳过的章节）
    return [s['id'] for s in core_sections]


def show_relevant_code(concept, course_data, max_snippets=2, max_length=500):
    """
    展示与概念相关的代码片段（懒加载版本）

    新特性:
    - 从元数据中按需加载章节
    - 自动匹配概念相关章节
    - 支持 LRU 缓存
    """
    notebook_metadata = course_data.get('notebook_metadata', {})
    py_file_paths = course_data.get('py_file_paths', [])

    if not notebook_metadata and not py_file_paths:
        print("📄 此课程暂无代码示例")
        return

    code_snippets = []

    # 从 notebook 元数据中按需加载
    if notebook_metadata:
        # 找到相关的章节
        relevant_sections = []

        for notebook_path, metadata in notebook_metadata.items():
            sections = metadata.get('sections', [])

            # 根据概念匹配章节
            for section in sections:
                if section['skip_by_default']:
                    continue

                # 检查章节标题是否包含概念关键词
                section_title_lower = section['title'].lower()
                concept_lower = concept.lower()

                # 匹配逻辑：章节标题包含概念词
                if (concept_lower in section_title_lower or
                    any(kw in section_title_lower for kw in concept_lower.split()[:3])):
                    relevant_sections.append((notebook_path, section))

        # 按相关性排序并加载
        for notebook_path, section in relevant_sections[:max_snippets]:
            print(f"🔍 加载章节: {section['title']}")
            snippets = load_notebook_section(notebook_path, section['id'], metadata)
            code_snippets.extend(snippets)

    # 如果 notebook 中没找到，尝试 py 文件
    if not code_snippets and py_file_paths:
        print(f"💡 Notebook 中未找到相关代码，尝试加载 Python 文件...")
        for py_path in py_file_paths:
            py_snippet = load_py_file_on_demand(py_path)
            if py_snippet:
                code_snippets.append(py_snippet)
                break

    # 如果还是没找到，展示第一个章节
    if not code_snippets and notebook_metadata:
        print("💡 展示第一个核心章节...")
        for notebook_path, metadata in notebook_metadata.items():
            for section in metadata.get('sections', []):
                if not section['skip_by_default']:
                    snippets = load_notebook_section(notebook_path, section['id'], metadata)
                    code_snippets.extend(snippets)
                    break
            if code_snippets:
                break

    # 展示代码
    for snippet in code_snippets[:max_snippets]:
        print(f"\n📄 来源: {snippet['source']}")
        print(f"📌 {snippet.get('description', '代码示例')}")
        print(f"```{snippet['language']}")

        # 限制代码长度
        code = snippet['code']
        if len(code) > max_length:
            code = code[:max_length] + "\n... (代码已截断)"
        print(code)
        print("```\n")


def find_relevant_snippets(concept_name, code_snippets):
    """根据概念名称查找相关代码片段"""
    # 简单的关键词匹配
    relevant = []
    keywords = concept_name.lower().split()

    for snippet in code_snippets:
        # 在标题、描述、代码中搜索关键词
        searchable_text = (
            snippet['title'].lower() + ' ' +
            snippet.get('description', '').lower() + ' ' +
            snippet['code'][:200].lower()
        )

        # 如果包含任一关键词，认为相关
        if any(keyword in searchable_text for keyword in keywords if len(keyword) > 3):
            relevant.append(snippet)

    return relevant
```

3. 【提问测试】
   - 生成1-2个相关问题
   - 等待用户回答
   - 验证答案并给出解析
```

### 阶段4: 综合测试

完成所有概念讲解后:

1. 生成5-10个测试题 (按难度分配):
   - 2题基础概念 (记忆)
   - 3题原理理解 (应用)
   - 3题代码分析 (分析)
   - 2题实践场景 (创造)

2. 交互式问答:
   - 逐一提问
   - 记录用户答案
   - 实时反馈对错
   - 给出详细解析

3. 计算总分并记录

### 阶段5: 生成笔记

**使用 Jinja2 模板引擎生成笔记:**

```python
from jinja2 import Template
import json

def generate_note(course_data, quiz_results):
    """生成学习笔记（统一格式 v2.0.0）

    Args:
        course_data: 包含课程信息的字典
            - id: 项目ID (如 '01-1')
            - module_name: 模块名称
            - project_name: 项目名称
            - difficulty: 难度等级
            - concepts: 核心概念列表
            - key_points: 关键要点列表
            - code_snippets: 代码片段列表（可选）
            - path: 课程路径
            - code_path: 代码路径（可选）
            - readme_path: README路径（可选）
        quiz_results: 测试结果字典
            - score: 得分
            - questions: 问题列表
    """
    # 加载模板
    with open('.claude/skills/agent-learner/templates/note.md', 'r') as f:
        template = Template(f.read())

    # 准备模板变量（修复字段映射）
    project_id = course_data.get('id', 'unknown')
    project_name = course_data.get('project_name', 'Unknown Project')
    module_name = course_data.get('module_name', 'Unknown Module')

    context = {
        'course_name': f"{project_id}: {project_name}",  # 修复：拼接生成完整名称
        'module_name': module_name,
        'project_name': project_name,
        'learn_date': datetime.now().strftime('%Y-%m-%d'),
        'learn_duration': course_data.get('learn_duration', '2小时'),
        'learn_status': course_data.get('learn_status', '已完成'),
        'quiz_score': quiz_results.get('score', 0),
        'difficulty': course_data.get('difficulty', '⭐⭐⭐'),
        'concepts': course_data.get('concepts', []),
        'key_points': course_data.get('key_points', []),
        'code_snippets': course_data.get('code_snippets', []),
        'quiz_questions': quiz_results.get('questions', []),
        'total_score': quiz_results.get('score', 0),
        'curriculum_path': course_data.get('path', ''),
        'code_path': course_data.get('code_path', ''),
        'project_readme': course_data.get('readme_path', ''),
        'external_links': course_data.get('external_links', []),
        'learner_notes': course_data.get('notes', ''),
        'generated_at': datetime.now().isoformat()
    }

    # 渲染模板
    content = template.render(**context)

    # 保存笔记（文件名格式：{id}-{slug}.md）
    slug = course_data.get('slug', project_name.lower().replace(' ', '-'))
    note_file = f"notes/{project_id}-{slug}.md"
    with open(note_file, 'w', encoding='utf-8') as f:
        f.write(content)

    return note_file
```

**关键变量说明:**
- `concepts`: 列表,每个元素包含 `{name, description, code_example}`
- `key_points`: 字符串列表
- `code_snippets`: 列表,每个元素包含 `{title, code, description}`
- `quiz_questions`: 列表,每个元素包含 `{question, user_answer, correct_answer, correct, explanation}`

3. 保存到 `notes/{project-id}-{name}.md`

### 阶段5.5: 发布询问 (可选)

**询问用户是否发布到网页**:

```
✅ 笔记已生成: notes/01-1-mcp-demo.md

📤 是否立即发布到网页?

1) GitHub Pages    (推荐,免费托管)
2) Cloudflare Pages (现有部署,需要配置)
3) 跳过发布        (稍后手动 /publish)

请输入选项 (1/2/3):
```

**根据用户选择执行**:

- **选择 1 (GitHub Pages)**:
  ```python
  # 调用发布脚本
  bash("./scripts/publish.sh", "--platform", "github")
  ```

- **选择 2 (Cloudflare Pages)**:
  ```python
  # 调用现有发布脚本
  bash("./scripts/publish.sh", "--platform", "cloudflare")
  ```

- **选择 3 (跳过)**:
  ```python
  # 不执行任何操作
  print("💡 提示: 稍后可用 /publish 命令发布")
  ```

**错误处理**:
- 发布失败时显示详细错误信息
- 提供故障排除建议
- 不影响学习流程完成

**代码示例**:
```python
def prompt_publish_options(note_file):
    """询问用户发布选项"""

    print(f"\n✅ 笔记已生成: {note_file}")
    print("\n📤 是否立即发布到网页?")
    print("\n选择发布平台:")
    print("1) GitHub Pages    (推荐,免费托管)")
    print("2) Cloudflare Pages (现有部署,需要配置)")
    print("3) 跳过发布        (稍后手动 /publish)")

    while True:
        choice = input("\n请输入选项 (1/2/3): ").strip()

        if choice == "1":
            return "github"
        elif choice == "2":
            return "cloudflare"
        elif choice == "3":
            return None
        else:
            print("❌ 无效选项,请输入 1、2 或 3")
```

### 阶段6: 更新进度

**断点续学机制 - 每个阶段后自动保存:**

```python
import fcntl
import json
from datetime import datetime

def update_learning_state(project_id, step_name, data=None):
    """更新学习状态（支持断点续学）- 统一格式 v2.0.0

    Args:
        project_id: 项目ID (如 '01-1')
        step_name: 当前步骤名称
        data: 要保存的数据 (如已学概念列表)

    Steps:
        'started': 开始学习
        'concept_1': 学完第1个概念
        'concept_2': 学完第2个概念
        'quiz_start': 开始测试
        'quiz_complete': 测试完成
        'completed': 课程完成

    统一格式:
        {
          "status": "in_progress" | "completed",
          "started_at": "ISO timestamp",
          "completed_at": "ISO timestamp (optional)",
          "current_step": "concept_1 | concept_2 | ... | quiz | completed",
          "completed_concepts": ["概念1", "概念2"],
          "quiz_score": 85 (optional),
          "quiz_taken_at": "ISO timestamp (optional)"
        }
    """
    progress_file = 'data/progress.json'

    # 读取现有进度
    try:
        with open(progress_file, 'r') as f:
            progress = json.load(f)
    except FileNotFoundError:
        progress = {'version': '2.0.0', 'current': None, 'progress': {}}

    # 确保项目记录存在
    if project_id not in progress['progress']:
        progress['progress'][project_id] = {}

    project_data = progress['progress'][project_id]

    # 更新状态（统一格式）
    if step_name == 'started':
        project_data['status'] = 'in_progress'
        project_data['started_at'] = datetime.now().isoformat()
        project_data['current_step'] = 'concept_1'
        project_data['completed_concepts'] = []
        progress['current'] = project_id

    elif step_name.startswith('concept_'):
        # 学完一个概念
        concept_num = int(step_name.split('_')[1])
        project_data['current_step'] = f'concept_{concept_num + 1}'
        if data and 'concept' in data:
            project_data['completed_concepts'] = project_data.get('completed_concepts', [])
            project_data['completed_concepts'].append(data['concept'])

    elif step_name == 'quiz_start':
        project_data['current_step'] = 'quiz'

    elif step_name == 'quiz_complete':
        project_data['status'] = 'completed'
        project_data['current_step'] = 'completed'
        project_data['completed_at'] = datetime.now().isoformat()
        project_data['quiz_score'] = data.get('score')
        project_data['quiz_taken_at'] = datetime.now().isoformat()

        # 移动到下一个项目
        progress['current'] = get_next_project_id(project_id)

    # 写入文件（带文件锁）
    with open(progress_file, 'w') as f:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)
        json.dump(progress, f, indent=2, ensure_ascii=False)
        fcntl.flock(f.fileno(), fcntl.LOCK_UN)

def get_next_project_id(current_id, curriculum_file='.claude/skills/agent-learner/curriculum/index.json'):
    """获取下一个项目的ID"""
    with open(curriculum_file, 'r') as f:
        curriculum = json.load(f)

    # 获取所有项目（按顺序）
    all_projects = []
    for module in curriculum['modules']:
        for project in module['projects']:
            all_projects.append(project['id'])

    # 找到当前项目的索引
    try:
        current_index = all_projects.index(current_id)
    except ValueError:
        return all_projects[0] if all_projects else None

    # 返回下一个项目
    next_index = current_index + 1
    if next_index < len(all_projects):
        return all_projects[next_index]

    return None

def get_first_uncompleted(progress, curriculum_file='.claude/skills/agent-learner/curriculum/index.json'):
    """获取第一个未完成的项目"""
    with open(curriculum_file, 'r') as f:
        curriculum = json.load(f)

    for module in curriculum['modules']:
        for project in module['projects']:
            project_id = project['id']
            if project_id not in progress.get('progress', {}):
                return project_id

    return None

def resume_learning(project_id):
    """恢复学习 - 从上次中断的地方继续（统一格式 v2.0.0）

    Returns:
        dict: {
            'status': 'in_progress' | 'completed' | 'not_started',
            'current_step': 'concept_1' | 'concept_2' | ... | 'quiz' | 'completed',
            'completed_concepts': ['概念1', '概念2'],
            'started_at': 'ISO timestamp',
            'can_resume': bool
        }
    """
    progress_file = 'data/progress.json'

    with open(progress_file, 'r') as f:
        progress = json.load(f)

    project_data = progress['progress'].get(project_id, {})

    # 兼容旧格式：如果使用 status 字段，直接读取
    # 否则检查 in_progress 字段（旧格式）
    if 'status' in project_data:
        status = project_data['status']
        can_resume = (status == 'in_progress')
    elif 'in_progress' in project_data:
        status = 'in_progress'
        can_resume = True
    else:
        status = project_data.get('completed', 'not_started')
        can_resume = False

    # 获取断点信息
    current_step = project_data.get('current_step', 'concept_1')
    completed_concepts = project_data.get('completed_concepts', [])
    started_at = project_data.get('started_at', '')

    return {
        'status': status,
        'step': current_step,
        'completed_concepts': completed_concepts,
        'started_at': started_at,
        'can_resume': can_resume
    }
```

**使用场景示例:**

```python
# 场景1: 学习到一半时保存
update_learning_state('01-2', 'concept_2', {'concept': 'MCP协议'})
# progress.json: {"current_step": "concept_3", "completed_concepts": ["MCP协议"]}

# 场景2: 恢复学习
state = resume_learning('01-2')
# 返回: {'step': 'concept_3', 'completed_concepts': ['MCP协议'], 'can_resume': True}

# 场景3: 完成课程
update_learning_state('01-2', 'quiz_complete', {'score': 85})
# 自动移动到下一个项目
```

**关键点:**
- **断点续学**: 记录 `current_step` 和 `completed_concepts`
- **阶段保存**: 每个概念学完就保存，不只是结束时保存
- **状态恢复**: `resume_learning()` 从上次中断处继续
- **自动推进**: 完成后自动更新 `current` 到下一课
- **文件锁**: 防止并发写入冲突

**状态表示:**
- `current_step = 'concept_1'` → 正在学习第1个概念
- `current_step = 'concept_3'` → 正在学习第3个概念
- `current_step = 'quiz'` → 正在做测试
- `completed` 存在 → 课程已完成

## 核心规则

### 学习原则

1. **引导式讲解**
   - Claude主动讲解,不只是回答
   - 用类比和例子帮助理解
   - 从简到难,循序渐进

2. **互动式学习**
   - 每个概念后都要提问
   - 确保用户理解后再继续
   - 根据回答调整讲解深度

3. **实用主义**
   - 重点讲解实际应用
   - 代码示例要能运行
   - 说明常见陷阱和最佳实践

### 提问策略

**概念记忆题**:
```
"XX的全称是什么?"
"XX的主要作用是什么?"
```

**理解应用题**:
```
"在什么场景下应该使用XX?"
"XX和YY有什么区别?"
```

**代码分析题**:
```
"这段代码中XX的作用是什么?"
"如果把XX改成YY会发生什么?"
```

**实践场景题**:
```
"如果要实现XX功能,你会怎么做?"
"给你一个实际问题:XXX,如何用我们学到的XX来解决?"
```

### 题目生成

基于课程内容动态生成5-10个问题:

1. 分析README中的核心概念
2. 识别代码示例中的关键点
3. 结合实际应用场景
4. 确保覆盖布鲁姆认知层级:
   - 记忆
   - 理解
   - 应用
   - 分析
   - 评价
   - 创造

### 笔记生成

笔记必须包含:

**✅ 必需字段**:
- 课程名称和ID
- 学习日期和时长
- 核心概念列表 (2-3个)
- 关键要点 (5-7条)
- 代码示例 (如果有)
- 测试题与答案
- 相关资源链接

**⚠️ 格式要求**:
- 使用Markdown格式
- 包含Emoji图标提升可读性
- 代码块使用语法高亮
- 保持结构清晰

## 命令处理

### `/learn` - 开始学习

**无参数**: 从当前位置继续
```
1. 读取progress.json
2. 如果有进度,继续当前课程
3. 如果无进度,从第一个课程开始
4. 执行完整学习流程
```

**有参数** (如 `/learn 01-1`): 学习指定课程
```
1. 验证课程ID存在
2. 加载课程内容
3. 执行完整学习流程
4. 更新进度
```

### `/quiz [难度]` - 测试

**参数**: `easy` | `medium` | `hard`
- `easy`: 3题基础概念
- `medium`: 7题 (基础+理解)
- `hard`: 10题 (全部类型)

**流程**:
1. 读取当前学习进度
2. 根据难度生成题目
3. 交互式问答
4. 记录成绩到进度文件

### `/review [课程ID]` - 复习

**有参数**: 复习指定课程
```
1. 加载已有笔记
2. 高亮重点概念
3. 随机抽题重新测试
4. 根据错题推荐复习重点
```

**无参数**: 复习当前课程
- 同上,但使用当前课程

### `/status` - 查看进度

输出:
```
📊 学习进度报告

当前课程: 01-1 MCP工具集成 (进行中)
已完成: 0/12 项目 (0%)
学习时长: 2小时
平均得分: N/A

课程列表:
✅ 01-1 MCP工具集成 [100分]
⏳ 01-2 从零构建智能体 [学习中]
⏸  02-1 LangGraph基础 [未开始]
...
```

### `/publish` - 发布笔记

流程:
1. 检查Git仓库状态
2. 提交所有笔记文件
3. 推送到GitHub
4. 根据平台触发部署:
   - **GitHub Pages**: 自动部署(需要配置)
   - **Cloudflare Pages**: 触发Cloudflare部署
5. 返回部署URL

**新增选项**:
- `/publish --platform github` - 发布到 GitHub Pages
- `/publish --platform cloudflare` - 发布到 Cloudflare Pages

## 错误处理

### 课程ID不存在
```
❌ 课程ID '99-9' 不存在

可用课程列表:
01-1: MCP工具集成
01-2: 从零构建智能体
02-1: LangGraph基础
...

使用 /learn [课程ID] 开始学习
```

### README文件为空或不存在
```
⚠️ 警告: 课程文件未找到

路径: Agent_In_Action/01-agent-tool-mcp/missing.md

跳过此课程,继续下一个...
```

### 进度文件损坏
```
⚠️ 进度文件损坏,正在重建...

已重置学习进度
从第一个课程开始: 01-1 MCP工具集成
```

### 笔记目录不存在
```
📁 创建笔记目录: notes/

已创建,继续生成笔记...
```

## 示例对话

### 用户: `/learn 01-1`

**Assistant**:
```
📚 开始学习: 01-1 MCP工具集成

难度: ⭐⭐⭐
预计时长: 2小时

今天我们将学习MCP (Model Context Protocol) 工具集成,
这是一个让AI模型与外部工具安全交互的开放协议。

【核心概念1: 什么是MCP?】

MCP的全称是 Model Context Protocol,中文叫"模型上下文协议"。

你可以把它想象成一个"万能翻译器":
- AI模型说"语言A" (LLM的请求格式)
- 外部工具说"语言B" (各种API格式)
- MCP负责在两者之间翻译

为什么需要MCP?

没有MCP时,每个工具都要单独集成:
❌ 天气API要写一套代码
❌ 搜索API要写另一套代码
❌ 数据库API又要写一套代码

有了MCP后:
✅ 所有工具用统一接口
✅ 新增工具无需改代码
✅ 标准化错误处理

现在让我测试一下你的理解:

❓ 问题1: MCP的主要作用是什么?
A. 提高AI模型的推理能力
B. 标准化AI与外部工具的交互
C. 加速模型训练过程

请选择答案 (A/B/C):
```

### 用户: `B`

**Assistant**:
```
✅ 正确!B是标准答案。

**解析**:
MCP的核心价值在于标准化。它定义了一套统一的协议,
让AI模型可以用相同的方式访问各种不同的工具和资源,
而不需要为每个工具单独写集成代码。

这就像USB接口:
- 鼠标、键盘、U盘都用USB
- 电脑不需要知道具体是什么设备
- 只要遵守USB协议就能工作

【核心概念2: MCP的通信模式】

MCP有两种通信模式:

1. **stdio模式** (标准输入输出)
   - 用于本地执行
   - 像命令行脚本一样运行
   - 适合本地工具集成
   - 延迟低,安全性高

2. **sse模式** (服务器发送事件)
   - 基于HTTP/Web技术
   - 适合网络访问
   - 支持多用户共享
   - 需要考虑网络安全

简单来说:
- 想在本地直接运行工具 → 用stdio
- 想通过网络访问工具服务 → 用sse

❓ 问题2: 如果你要把AI工具部署到云端,让多个用户访问,应该用哪种模式?
```

### 用户: `应该用sse模式`

**Assistant**:
```
✅ 完全正确!

**解析**:
sse模式基于HTTP,天然支持网络访问和多用户场景,
这正是云端部署的需求。

【核心概念3: MCP项目结构】

让我们看看一个MCP项目的基本结构:

```
mcp-demo/
├── server/              # MCP服务端
│   └── weather_server.py
├── client/              # MCP客户端
│   ├── mcp_client.py
│   └── mcp_client_deepseek.py
└── README.md
```

**服务端** (weather_server.py):
- 定义工具 (get_weather_warning, get_daily_forecast)
- 通过MCP协议暴露工具接口
- 处理客户端的调用请求

**客户端** (mcp_client_deepseek.py):
- 连接到MCP服务器
- 调用服务端的工具
- 处理返回结果

现在让我看看实际代码...

(展示代码示例并讲解)

【综合测试】

现在我们来测试一下你的整体理解,准备好了吗?

❓ Q1 (基础): MCP的全称是什么?
❓ Q2 (理解): 为什么需要MCP标准化?
❓ Q3 (应用): 什么场景适合用stdio模式?
...

(交互式问答,共10题)

【成绩总结】

🎉 测试完成!

得分: 85/100
- 基础概念: 2/2 ✅
- 原理理解: 2/3 ⚠️
- 代码分析: 3/3 ✅
- 实践场景: 1/2 ⚠️

建议复习:
- 多角色协作场景的应用
- 异步调用的错误处理

【生成笔记】

✅ 笔记已生成: notes/01-mcp-tool.md

包含:
- 3个核心概念
- 5个关键要点
- 2个代码示例
- 10道测试题与解析

【进度更新】

当前进度: 1/12 项目 (8.3%)

下一步: /learn 01-2 或 /quiz medium 继续测试
```

## 工具使用

### Read工具

读取课程内容:
```python
read("Agent_In_Action/01-agent-tool-mcp/mcp-demo/README.md")
```

### Write工具

生成笔记:
```python
write("notes/01-mcp-tool.md", content)
```

### Edit工具

更新进度:
```python
edit("data/progress.json", ...)
```

## 注意事项

1. **保持简洁**: 不要过度解释,每个概念2-3句话即可
2. **代码优先**: 能用代码说明的就不要只讲理论
3. **互动不断**: 每2-3个概念就要提问
4. **记录详细**: 笔记要详细到以后能独立复习
5. **鼓励为主**: 用户答错要鼓励,不要批评

## 成功标准

一个完整的学习流程应该:
- ✅ 讲解2-3个核心概念
- ✅ 展示1-2个代码示例
- ✅ 生成5-10个测试题
- ✅ 交互式问答并记录成绩
- ✅ 生成结构化笔记
- ✅ 更新学习进度

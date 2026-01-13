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

1. 根据课程ID定位到具体路径
2. 读取对应的README.md文件
3. 解析课程结构:
   - 提取核心概念 (2-3个)
   - 提取代码示例
   - 识别关键知识点

### 阶段3: 引导式学习循环

对每个核心概念执行:

```
1. 【讲解概念】
   - 用简单语言解释概念
   - 说明为什么需要这个概念
   - 举例说明应用场景

2. 【展示代码】
   - 展示相关代码片段
   - 逐行解释关键部分
   - 说明代码的作用

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
    """生成学习笔记"""
    # 加载模板
    with open('.claude/skills/agent-learner/templates/note.md', 'r') as f:
        template = Template(f.read())

    # 准备模板变量
    context = {
        'course_name': course_data['name'],
        'module_name': course_data['module'],
        'project_name': course_data['project'],
        'learn_date': datetime.now().strftime('%Y-%m-%d'),
        'learn_duration': '2小时',
        'learn_status': '已完成',
        'quiz_score': quiz_results['score'],
        'difficulty': course_data['difficulty'],
        'concepts': course_data['concepts'],
        'key_points': course_data['key_points'],
        'code_snippets': course_data.get('code_snippets', []),
        'quiz_questions': quiz_results['questions'],
        'total_score': quiz_results['score'],
        'curriculum_path': course_data['path'],
        'code_path': course_data.get('code_path', ''),
        'project_readme': course_data.get('readme_path', ''),
        'external_links': course_data.get('external_links', []),
        'learner_notes': course_data.get('notes', ''),
        'generated_at': datetime.now().isoformat()
    }

    # 渲染模板
    content = template.render(**context)

    # 保存笔记
    note_file = f"notes/{course_data['id']}-{course_data['slug']}.md"
    with open(note_file, 'w') as f:
        f.write(content)

    return note_file
```

**关键变量说明:**
- `concepts`: 列表,每个元素包含 `{name, description, code_example}`
- `key_points`: 字符串列表
- `code_snippets`: 列表,每个元素包含 `{title, code, description}`
- `quiz_questions`: 列表,每个元素包含 `{question, user_answer, correct_answer, correct, explanation}`

3. 保存到 `notes/{project-id}-{name}.md`

### 阶段6: 更新进度

**断点续学机制 - 每个阶段后自动保存:**

```python
import fcntl
import json
from datetime import datetime

def update_learning_state(project_id, step_name, data=None):
    """更新学习状态（支持断点续学）

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

    # 更新状态
    if step_name == 'started':
        project_data['in_progress'] = datetime.now().isoformat()
        project_data['current_step'] = 'concept_1'
        project_data['completed_concepts'] = []

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
        project_data['current_step'] = 'completed'
        project_data['quiz_score'] = data.get('score')
        project_data['completed'] = datetime.now().isoformat()

        # 移动到下一个项目
        project_data.pop('in_progress', None)
        project_data.pop('current_step', None)
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
    """恢复学习 - 从上次中断的地方继续"""
    progress_file = 'data/progress.json'

    with open(progress_file, 'r') as f:
        progress = json.load(f)

    project_data = progress['progress'].get(project_id, {})

    # 获取断点信息
    current_step = project_data.get('current_step', 'concept_1')
    completed_concepts = project_data.get('completed_concepts', [])

    return {
        'step': current_step,
        'completed_concepts': completed_concepts,
        'can_resume': 'in_progress' in project_data
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
4. 触发Cloudflare Pages部署
5. 返回部署URL

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

# {{ course_name }} 学习笔记

> {{ module_name }} - {{ project_name }}

**学习日期**: {{ learn_date }}
**学习时长**: {{ learn_duration }}
**学习状态**: {{ learn_status }}
**测试得分**: {{ quiz_score }}/100

难度等级: {{ difficulty }}

---

## 📚 核心概念

{% for concept in concepts %}
### {{ concept.name }}
{{ concept.description }}

{% if concept.code_example %}
**示例**:
```python
{{ concept.code_example }}
```
{% endif %}
{% endfor %}

---

## 💡 关键要点

{% for point in key_points %}
{{ loop.index }}. {{ point }}
{% endfor %}

---

## 🐍 代码示例

{% if code_snippets %}
{% for snippet in code_snippets %}
### {{ snippet.title }}

```python
{{ snippet.code }}
```

**说明**: {{ snippet.description }}
{% endfor %}
{% endif %}

---

## ❓ 自测题

{% for question in quiz_questions %}
### Q{{ loop.index }}: {{ question.question }}

**你的答案**: {{ question.user_answer }}
**正确答案**: {{ question.correct_answer }}
{% if question.correct %}
✅ 回答正确
{% else %}
❌ 回答错误
{% endif %}

**解析**: {{ question.explanation }}

---
{% endfor %}

**总得分**: {{ total_score }}/100

---

## 🔗 相关资源

- **教案路径**: `{{ curriculum_path }}`
- **代码路径**: `{{ code_path }}`
- **项目文档**: `{{ project_readme }}`

{% if external_links %}
### 扩展阅读

{% for link in external_links %}
- [{{ link.title }}]({{ link.url }})
{% endfor %}
{% endif %}

---

## 📝 学习笔记

{{ learner_notes }}

---

**笔记生成时间**: {{ generated_at }}
**笔记版本**: v2.0

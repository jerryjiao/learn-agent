# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Agent Learner** - an interactive learning system for Agentic AI development, built on Claude Code Skills. The system provides guided tutorials, automated quizzes, note generation, and a publishable notes website.

**Key characteristics:**
- Curriculum based on `Agent_In_Action/` (read-only reference materials)
- Learning progress tracked in JSON format
- Auto-generated Markdown notes published as a website
- Zero external API dependencies (runs entirely locally)
- Skill-based architecture using Claude Code's `.claude/skills/` system

## Common Development Commands

### Testing
```bash
# Run complete test suite (31 tests)
./scripts/test-all.sh

# Validate system structure
./scripts/validate.sh
```

### Publishing Notes Website
```bash
# Auto-publish to GitHub + Cloudflare Pages
./scripts/publish.sh

# Manual publish (from notes/ directory)
cd notes && git add . && git commit -m "Update notes" && git push
```

### Learning System Usage (via Claude Code Skills)
```bash
/learn                    # Start/continue learning
/learn 01-1              # Learn specific course
/quiz [easy|medium|hard] # Test current course
/review 01-1             # Review completed course
/status                  # View learning progress
```

## Architecture

### Skill-Based Learning System

The core learning logic is implemented as a **Claude Code Skill** at `.claude/skills/agent-learner/SKILL.md`. This file defines:

1. **Trigger conditions** - When the skill activates (`/learn`, `/quiz`, etc.)
2. **Learning workflow** - 6-stage interactive learning loop
3. **Quiz generation** - Dynamic 5-10 questions per lesson
4. **Note generation** - Template-based Markdown output
5. **Progress tracking** - JSON state machine

**Key workflow stages:**
1. **Initialize** - Read curriculum + progress, determine position
2. **Load content** - Parse README from `Agent_In_Action/` modules
3. **Guided learning** - Explain concepts → show code → interactive questions
4. **Quiz** - Generate 5-10 questions (memory → application → analysis → creation)
5. **Generate note** - Apply template, save to `notes/`
6. **Update progress** - Write to `data/progress.json`

### Data Structures

#### Curriculum Index (`.claude/skills/agent-learner/curriculum/index.json`)
```json
{
  "modules": [
    {
      "id": "01",
      "name": "智能体基础与MCP集成",
      "path": "Agent_In_Action/01-agent-tool-mcp",
      "projects": [
        {
          "id": "01-1",
          "name": "MCP工具集成 · 和风天气",
          "difficulty": "⭐⭐⭐",
          "topics": ["MCP协议", "客户端-服务器架构"],
          "code_paths": ["server/weather_server.py"]
        }
      ]
    }
  ]
}
```

#### Progress State (`data/progress.json`)
```json
{
  "current_project": "01-1",
  "progress": {
    "01-1": {
      "status": "completed",
      "started_at": "2026-01-13T10:00:00",
      "quiz_score": 85,
      "concepts_learned": ["MCP协议", "工具集成"]
    }
  }
}
```

### Notes Website (`notes/`)

A **pure static website** (no build step) with:
- **Responsive HTML** - Mobile-first design
- **CSS variables theming** - Light/dark mode via `data-theme` attribute
- **Client-side search** - JavaScript filtering without backend
- **Sidebar navigation** - Auto-generated from note files

**Key files:**
- `index.html` - Main page with stats, search, theme toggle
- `styles/theme.css` - 600+ lines, CSS variables for theming
- `scripts/search.js` - `NoteSearch` class for real-time filtering
- `scripts/theme-toggle.js` - `ThemeToggle` class with localStorage persistence
- `scripts/data-loader.js` - Parse markdown, render content

**Theme implementation:**
```css
:root { --bg-primary: #ffffff; --text-primary: #24292f; }
[data-theme="dark"] { --bg-primary: #0d1117; --text-primary: #c9d1d9; }
```

### Git Integration

The `notes/` directory is a **separate Git repository** for clean deployment:

```bash
notes/
├── .git/              # Separate git repo
├── .gitignore         # Excludes .DS_Store, IDE files
├── README.md          # Website documentation
└── 00-example.md      # Example note
```

This separation allows:
- Independent deployment to Cloudflare Pages
- Clean git history (no project files mixed with notes)
- Easy `git push` triggers auto-deployment

## Curriculum Structure

The curriculum follows **Agent_In_Action/** with 5 modules, 7 active projects:

1. **01: 智能体基础与MCP集成**
   - `01-1`: MCP工具集成 · 和风天气 (⭐⭐⭐)
   - `01-2`: 从零构建智能体框架 (⭐⭐⭐⭐)

2. **02: 多角色智能体系统**
   - `02-1`: LangGraph基础 (⭐⭐⭐⭐)
   - `02-2`: 深度研究助手 (⭐⭐⭐⭐)

3. **03: 企业级系统搭建与部署**
   - `03-1`: 多角色旅行规划智能体 (⭐⭐⭐⭐⭐)

4. **04: 监控、评估与优化**
   - `04-1`: Langfuse集成 (⭐⭐⭐⭐)

5. **05: 模型微调与推理优化**
   - `05-1`: 医疗领域模型微调 (⭐⭐⭐⭐⭐)

## Important Design Principles

### 1. Read-Only Reference Materials
**Never modify `Agent_In_Action/`** - it's the source of truth. All generated content goes into `notes/`.

### 2. JSON-Based State Management
No database required. All state stored in human-readable JSON:
- `curriculum/index.json` - Course metadata
- `data/progress.json` - Learning progress
- Template variables use `{{VARIABLE}}` syntax

### 3. Zero External Dependencies
- **No API keys** required for core functionality
- **No build step** for the website
- **No backend** for search/theme (client-side JavaScript)
- Publishing to Cloudflare Pages is optional (local notes work fine)

### 4. Progressive Enhancement
- **MVP**: `/learn` command works, notes generate
- **Enhanced**: Website with search, theme toggle, Git deployment
- All features degrade gracefully (e.g., no Git = still get local notes)

## File Relationships

```
User invokes /learn
    ↓
Agent Learner Skill activates
    ↓
Read curriculum/index.json
    ↓
Read data/progress.json (determine position)
    ↓
Read Agent_In_Action/01-agent-tool-mcp/mcp-demo/README.md
    ↓
Parse concepts, code examples
    ↓
Interactive learning loop (explain → quiz → feedback)
    ↓
Apply templates/note.md
    ↓
Write notes/01-mcp-tool.md
    ↓
Update data/progress.json
    ↓
(Optional) ./scripts/publish.sh → GitHub → Cloudflare Pages
```

## Testing Strategy

The `test-all.sh` script validates **31 test cases** across 7 phases:

1. **File structure** (14 tests) - Verify all required files exist
2. **JSON format** (2 tests) - Parse curriculum and progress
3. **Git repository** (2 tests) - Check `notes/.git/` initialization
4. **Script permissions** (2 tests) - Executable bit on `.sh` files
5. **Content validation** (6 tests) - Search for key strings in files
6. **Functionality** (2 tests) - Count modules ≥5, projects ≥7
7. **Website files** (3 tests) - Check `notes/` has README, .gitignore, example

**Run tests after any changes** to ensure system integrity.

## Deployment Checklist

Before publishing the notes website:

1. **Run tests**: `./scripts/test-all.sh` (31/31 must pass)
2. **Check Git status**: `cd notes && git status`
3. **Commit changes**: `./scripts/publish.sh` (auto-commits)
4. **Push to GitHub**: Script provides setup instructions for first-time
5. **Connect Cloudflare Pages**: See `PUBLISH_GUIDE.md`
6. **Verify deployment**: Check live URL

## Common Issues

### Issue: Skill not activating
- **Cause**: Skill file missing or syntax error
- **Fix**: Run `./scripts/test-all.sh` to validate structure

### Issue: Notes not generating
- **Cause**: `notes/` directory missing or permission denied
- **Fix**: `mkdir -p notes && chmod 755 notes`

### Issue: Git push fails
- **Cause**: Remote not configured or auth failed
- **Fix**: See `PUBLISH_GUIDE.md` for GitHub setup instructions

### Issue: Theme toggle not persisting
- **Cause**: Browser blocking localStorage
- **Fix**: Check browser settings, enable cookies for localhost

## References

- **Agent Learner README**: `AGENT_LEARNER_README.md` - User guide for learning system
- **Publish Guide**: `PUBLISH_GUIDE.md` - Step-by-step deployment instructions
- **Project Completion**: `PROJECT_COMPLETE.md` - Statistics and architecture overview
- **Files Manifest**: `FILES_MANIFEST.md` - Complete file inventory
- **Agent_In_Action README**: `Agent_In_Action/README.md` - Original curriculum documentation

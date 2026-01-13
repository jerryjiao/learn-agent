# 📤 发布指南

## 快速发布到Cloudflare Pages

### 方法1: 使用发布脚本 (推荐)

```bash
./scripts/publish.sh
```

脚本会自动:
- ✅ 检测Git仓库状态
- ✅ 提交未提交的更改
- ✅ 推送到GitHub
- ✅ 提供Cloudflare Pages配置说明

### 方法2: 手动发布

#### 步骤1: 准备GitHub仓库

```bash
# 1. 在GitHub创建新仓库
# 访问: https://github.com/new
# 仓库名: agent-learning-notes

# 2. 添加远程仓库
cd notes
git remote add origin https://github.com/你的用户名/agent-learning-notes.git

# 3. 推送代码
git push -u origin main
```

#### 步骤2: 配置Cloudflare Pages

1. **访问Cloudflare Dashboard**
   ```
   https://dash.cloudflare.com/
   ```

2. **创建Pages项目**
   - 进入: Workers & Pages > Pages
   - 点击: 创建项目 > 连接到Git

3. **配置构建设置**
   ```
   项目名称: agent-learning-notes
   生产分支: main
   根目录: (留空或填 notes)
   构建命令: (留空,静态网站无需构建)
   构建输出目录: /
   ```

4. **部署**
   - 点击: 保存并部署
   - 等待1-2分钟
   - 获得URL: `https://agent-learning-notes.pages.dev`

---

## 配置自定义域名 (可选)

### 在Cloudflare Pages:

1. 进入项目设置
2. 点击: 自定义域
3. 添加域名: `notes.yourdomain.com`
4. 配置DNS记录

---

## 自动更新

### 自动部署

每次推送代码到GitHub,Cloudflare Pages会自动部署新版本:

```bash
# 更新笔记
cd notes
git add .
git commit -m "添加新笔记"
git push

# 自动触发部署,无需手动操作
```

### 预览部署

每个Pull Request都会生成预览URL,方便查看更改。

---

## 需要的Token

如果需要配置GitHub,可能需要:

1. **GitHub Personal Access Token** (如果使用HTTPS认证)
   - 生成地址: https://github.com/settings/tokens
   - 权限: repo (完整仓库访问权限)

2. **SSH密钥** (推荐,更安全)
   ```bash
   # 生成SSH密钥
   ssh-keygen -t ed25519 -C "your_email@example.com"

   # 添加到GitHub
   # 复制 ~/.ssh/id_ed25519.pub 内容
   # 到: GitHub设置 > SSH and GPG keys > New SSH key
   ```

---

## 常见问题

### Q: 推送失败?

```bash
# 检查远程仓库
git remote -v

# 重新添加
git remote remove origin
git remote add origin https://github.com/用户名/仓库名.git
```

### Q: Cloudflare Pages部署失败?

检查:
- ✅ 构建设置是否正确
- ✅ 根目录路径是否正确
- ✅ index.html是否在根目录

### Q: 如何更新已部署的网站?

```bash
# 1. 更新笔记
/learn 01-2  # 生成新笔记

# 2. 提交并推送
cd notes
git add .
git commit -m "添加01-2笔记"
git push

# 3. 自动部署完成
```

---

## 环境变量 (可选)

如果需要配置环境变量:

在Cloudflare Pages项目设置中添加:
```bash
# 示例
NODE_VERSION=18
```

---

## 性能优化

### 启用缓存

Cloudflare Pages默认缓存静态资源,无需额外配置。

### CDN加速

Cloudflare全球CDN自动加速,无需配置。

---

## 成本

- ✅ **Cloudflare Pages**: 免费额度
  - 无限带宽
  - 无限请求
  - 500个构建/月

完全免费! 🎉

---

## 发布到 GitHub Pages

### 方法1: 通过学习流程自动发布 (推荐)

```bash
# 完成学习后,系统会询问是否发布
/learn 01-1

# 选择选项 1) GitHub Pages
```

### 方法2: 使用发布脚本

```bash
# 自动检测平台
./scripts/publish.sh

# 指定使用 GitHub Pages
./scripts/publish.sh --platform github
```

### GitHub Pages 配置步骤

#### 方案A: 使用 main 分支(推荐)

1. **推送代码到 GitHub**
   ```bash
   cd notes
   git remote add origin git@github.com:你的用户名/learn-agent.git
   git push -u origin main
   ```

2. **启用 GitHub Pages**
   - 访问: https://github.com/你的用户名/learn-agent/settings/pages
   - Source: **Deploy from a branch**
   - Branch: **main** → **/ (root)**
   - 点击: **Save**

3. **访问网站**
   - 约1-2分钟后访问: `https://你的用户名.github.io/learn-agent/`

#### 方案B: 使用 GitHub Actions(更灵活)

1. **创建 workflow 文件**

   在 `notes/.github/workflows/static.yml`:
   ```yaml
   name: Deploy to GitHub Pages

   on:
     push:
       branches: [main]

   permissions:
     contents: read
     pages: write
     id-token: write

   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/configure-pages@v4
         - uses: actions/upload-pages-artifact@v3
           with:
             path: '.'
         - uses: actions/deploy-pages@v4
   ```

2. **推送并启用**
   ```bash
   git add .github/workflows/static.yml
   git commit -m "Add GitHub Pages workflow"
   git push
   ```

3. **在 GitHub 设置中配置**
   - 访问: https://github.com/你的用户名/learn-agent/settings/pages
   - Source: **GitHub Actions**

### 智能重试机制

发布脚本内置智能重试:
- ✅ 自动重试 3 次
- ✅ 延迟递增 (2秒 → 5秒 → 10秒)
- ✅ 失败后提供详细诊断

**重试示例**:
```
⏳ [1/3] 推送到 GitHub...
⚠️  推送失败 (退出码: 128)
   2秒后重试...
⏳ [2/3] 推送到 GitHub...
✅ 推送成功
```

### 常见问题

#### Q: 如何确认 GitHub Pages 是否已配置?

```bash
# 方法1: 检查是否有 gh-pages 分支
git ls-remote --heads origin gh-pages

# 方法2: 检查是否有 GitHub Actions workflow
ls .github/workflows/pages.yml
```

#### Q: 推送失败怎么办?

脚本会自动重试 3 次,如果仍然失败:
1. 检查网络连接: `ping github.com`
2. 检查 SSH 密钥: `ssh -T git@github.com`
3. 查看详细错误: `git push origin main -v`

#### Q: GitHub Pages 和 Cloudflare Pages 可以同时使用吗?

✅ 可以。但脚本每次只会配置一个平台:
- 使用 `--platform github` 配置 GitHub Pages
- 使用 `--platform cloudflare` 配置 Cloudflare Pages
- 不指定参数时,脚本会自动检测

---

**更新时间**: 2026-01-13

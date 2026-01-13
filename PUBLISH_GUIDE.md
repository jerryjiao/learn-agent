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

**更新时间**: 2026-01-13

# ✅ iOS 自动签名配置检查清单

## 已完成 ✓

- [x] **步骤1**: 提取 Team ID
  - Team ID: `66JTX3GW7T`
  - 已更新到 `ExportOptions.plist`

- [x] **步骤2**: 生成 Base64 编码
  - `certificate_base64.txt` (4116 字符)
  - `provision_base64.txt` (16252 字符)

- [x] **代码推送**: 所有更改已推送到 GitHub
  - Commit: `7d4c9ee` - "docs: 添加 GitHub Secrets 配置详细指南"
  - Commit: `304a740` - "chore: 更新 Team ID 和添加 Python 工具脚本"
  - Commit: `c0648d2` - "feat: 添加 Team ID 自动提取和 Xcode 项目自动创建"

---

## 待完成 ⏳

### 步骤3: 配置 GitHub Secrets（需要你手动操作）

访问: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/settings/secrets/actions

添加以下 4 个 Secrets:

- [ ] **IOS_CERTIFICATE_BASE64**
  - 值: 复制 `certificate_base64.txt` 的全部内容
  - 字符数: 4116

- [ ] **IOS_CERTIFICATE_PASSWORD**
  - 值: `Hp15099837787!`

- [ ] **IOS_PROVISION_PROFILE_BASE64**
  - 值: 复制 `provision_base64.txt` 的全部内容
  - 字符数: 16252

- [ ] **KEYCHAIN_PASSWORD**
  - 值: 任意强密码（建议 `Actions@2024!`）

---

## 验证构建 🚀

配置完成后:

1. [ ] 进入 GitHub Actions 标签页
2. [ ] 手动触发 workflow 或推送代码
3. [ ] 等待构建完成（约 5-10 分钟）
4. [ ] 下载 IPA 文件
5. [ ] 安装到测试设备验证

---

## 快速链接 🔗

- **GitHub Secrets 配置**: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/settings/secrets/actions
- **GitHub Actions**: https://github.com/ChimerAI-SZ/FengShuiLuopan_ios/actions
- **详细指南**: [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

---

## 文件位置 📁

```
E:\FengShuiLuopan_ios\
├── certificate_base64.txt          # 证书 Base64（不要提交到 Git）
├── provision_base64.txt            # 配置文件 Base64（不要提交到 Git）
├── ExportOptions.plist             # 已更新 Team ID
├── update_team_id.py               # Team ID 提取工具
├── generate_base64.py              # Base64 编码工具
├── GITHUB_SECRETS_SETUP.md         # Secrets 配置详细指南
├── COMPLETE_SETUP_GUIDE.md         # 完整配置指南
└── SETUP_QUICK_REF.md              # 快速参考卡
```

---

## 重要提示 ⚠️

1. **配置文件有效期**: 2026-03-08（7天后过期）
2. **不要提交敏感文件**: `.p12`, `.mobileprovision`, `*_base64.txt` 已在 `.gitignore` 中排除
3. **Secrets 不可查看**: 配置后只能更新或删除，建议备份 Base64 文件

---

**下一步**: 配置 GitHub Secrets 后，推送代码即可自动触发构建！

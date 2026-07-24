---
name: codex-skin-maker
description: Create or revise a safe custom skin for Microsoft Store Codex Desktop from one or two user-provided images. Use when a user asks to change Codex's appearance, make a school/anime/minimal wallpaper theme, generate matching light and dark modes, install a shareable skin, or restore the original interface without requiring them to understand theme manifests or the injection engine.
---

# Codex Skin Maker

把用户提供的一张或两张图片制作成可验证、可预览、可恢复的 Codex Desktop 浅色/深色皮肤。面向普通用户隐藏 manifest、Inspector 和资源路径等实现细节，但不得省略安全检查和用户确认。

## 核心体验

用户理想情况下只需要提供图片并说：

```text
使用 $codex-skin-maker，把这张图片做成我的 Codex 皮肤。先生成和检查，不要直接应用。
```

完成后使用简明中文报告结果，并等待用户明确同意后再进行真实预览。

## 工作区定位

1. 优先使用当前工作区中同时包含 `engine/`、`template/unbranded/` 和 `xjtu-theme.cmd` 的 XJTU Codex Theme 仓库。
2. 如果当前工作区不是该仓库，先检查是否已有用户指定的仓库路径。
3. 如果仍未找到，向用户说明将从官方仓库下载固定到已验证 `v0.3.0-rc.1` 提交的主题工作区，并在正常命令审批流程下运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap-workspace.ps1
```

4. 不得静默下载、使用自定义远程源、跟随可变分支、覆盖已有目录或删除用户文件。
5. 进入仓库后先读取 `references/user-flow.md`、`references/theme-guidelines.md` 和 `references/compatibility-and-safety.md`。

## 必须遵循的流程

### 1. 只读预检

- 检查 Git 状态并保留所有现有用户改动。
- 运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <当前调用 Skill 的安装目录>\scripts\check-environment.ps1 -RepositoryRoot <固定工作区>
```

- 必须使用当前调用 Skill 自带的 `check-environment.ps1` 校验固定工作区，不要切换到下载工作区中的旧副本；安装 Skill 的 release 常量才是当前信任根。

- 只有仓库贡献者在用户明确选择的官方 Git 开发分支中验收时，才可以先核对 `origin` 和干净工作区，再显式追加 `-AllowDevelopmentWorkspace`。普通换肤不得使用该开关。

- 环境必须是 Windows 10/11 x64、Microsoft Store 版 Codex Desktop、Node.js 22 或更新版本。
- `doctor` 失败、Codex 进程无法确认、存在 CodeDrobe 冲突或 Inspector 归属不明时，不得继续真实预览。

### 2. 检查用户图片

- 将原始图片视为只读输入，不覆盖、不裁掉原文件。
- 接受 JPEG、PNG 或 WebP；优先使用 16:9、约 2560×1440 的图片。
- 一张图片可以同时派生浅色和深色模式；两张图片时分别用于对应模式。
- 不移除第三方水印，不使用明显无授权的商标、校徽、动漫素材或私人照片。
- 用户自己的账号水印、品牌标识或明确授权素材可以保留。
- 图片含令牌、账号信息、私密聊天、证件、地址等敏感内容时停止处理并说明原因。

### 3. 创建非破坏性主题

- 从 `template/unbranded/dark.json` 与 `template/unbranded/light.json` 开始。
- 创建新的小写连字符主题 ID，最长 64 个字符，不覆盖 XJTU 成品主题。
- 将派生资源放入新的 `themes/<theme-id>/assets/` 或等价项目内目录。
- 保持原图不变；需要裁剪、压缩或调色时生成新文件。
- 更新 `engine/themes/dark.json` 和 `engine/themes/light.json` 指向新的项目内资源。
- 默认 `conversationWallpaper` 为 `false`；除非用户明确要求，否则不要让壁纸覆盖长对话正文区。
- 颜色和遮罩必须优先保证侧栏、输入框、按钮和正文可读性。

### 4. 验证但不应用

按顺序运行：

```powershell
node .\skills\codex-theme-author\scripts\validate-theme-pack.mjs .
node .\scripts\check-theme-assets.mjs
npm.cmd test --prefix engine
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-theme-safety.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-hot-theme-engine.ps1 -Offline
.\xjtu-theme.cmd preview dark --dry-run
.\xjtu-theme.cmd preview light --dry-run
```

- 不得声称执行过未实际运行的检查。
- 任一检查失败时，停止并报告准确错误、受影响文件以及恢复建议。

### 5. 给出确认摘要

在真实预览前，至少报告：

- 主题名称和主题 ID；
- 使用了哪一张或两张图片；
- 已生成的浅色/深色模式；
- 修改或新增的文件；
- 验证、测试和 Dry Run 结果；
- 当前仍未应用主题；
- 真实预览会临时连接本机 Inspector，且可以立即 `disable` 恢复。

等待用户明确表达“应用”“预览”“继续”等同意。不能把最初的“帮我制作”视为对真实注入的授权。

### 6. 经确认后预览

用户批准后仅预览一个模式：

```powershell
.\xjtu-theme.cmd preview dark
.\xjtu-theme.cmd verify
```

或：

```powershell
.\xjtu-theme.cmd preview light
.\xjtu-theme.cmd verify
```

- `verify` 通过后再询问用户是否需要切换另一模式或创建快捷方式。
- 应用、验证或交互检查失败时立即运行：

```powershell
.\xjtu-theme.cmd disable
```

并报告原始错误，不要反复注入尝试。

## 安全边界

- 不编辑 `WindowsApps`、`app.asar`、Codex 浏览器资料、Cookie、凭据、API Key、对话记录或全局配置。
- 不为了换肤重启 Codex。
- 不创建计划任务、自启动项、后台服务或持久化注入，除非用户另行明确要求且项目安全规则允许。
- Inspector 只能绑定 `127.0.0.1`，连接后必须确认目标 PID 是当前 Store Codex 主进程。
- 不运行任意 Shell、远程脚本或与换肤无关的命令。
- 不发布、不推送、不创建 Git 提交，除非用户明确要求。
- 不把项目描述为 OpenAI 或学校官方项目。
- 项目使用非商业 source-available 许可，不得称为 OSI 开源许可证项目。

## 面向普通用户的输出

避免把完整日志直接倾倒给用户。优先使用以下摘要格式：

```text
皮肤已经生成，但尚未应用。

主题：<显示名称>
深色模式：通过 / 未生成
浅色模式：通过 / 未生成
图片：<文件名>
环境检查：通过
主题校验：通过
自动化测试：通过
离线 Dry Run：通过

回复“预览深色”或“预览浅色”后，我再临时应用并执行恢复检查。
```

出现错误时使用 `references/error-messages.md` 中的用户友好表达，同时保留可复制的技术错误代码或命令。

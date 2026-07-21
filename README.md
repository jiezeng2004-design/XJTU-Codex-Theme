# XJTU Codex Theme

一个面向 Microsoft Store 版 Codex Desktop 的 Windows 本地主题项目。它包含两部分：

1. **XJTU Academic Theme**：已经配好的西安交通大学校园浅色/暗色主题，可直接试用。
2. **Unbranded Template**：无品牌主题模板，用户提供图片后，可以让 Codex 生成自己的皮肤。

主题通过短暂的本机 Node Inspector 脉冲注入到正在运行的 Codex，不修改 `WindowsApps`、`app.asar`、Codex 配置、浏览器资料或登录凭据。应用、切换和退出主题都不要求重启 Codex。

> [!WARNING]
> 这是非官方实验性项目，不隶属于 OpenAI 或西安交通大学。它依赖 Codex Desktop 的 Electron 内部结构，Codex 更新后可能需要适配。当前已验证版本为 `26.715.7063.0`。

## XJTU 成品主题

环境要求：

- Windows 10/11 x64
- Microsoft Store 版 Codex Desktop
- Node.js 22 或更新版本

先运行只读检查：

```cmd
xjtu-theme.cmd doctor
```

无重启加载主题：

```cmd
xjtu-theme.cmd preview dark
xjtu-theme.cmd preview light
```

切换、验证和退出：

```cmd
xjtu-theme.cmd switch
xjtu-theme.cmd verify
xjtu-theme.cmd disable
```

创建桌面快捷方式：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-desktop-shortcuts.ps1
```

`preview` 仅作用于当前 Codex 进程。`disable` 会移除注入的样式与事件钩子，并清理本地主题状态。默认不会创建计划任务。

## 使用自己的图片

无品牌模板位于 [`template/unbranded/`](template/unbranded/)。完整流程见：

- [`docs/CREATE_CUSTOM_THEME_WITH_CODEX.md`](docs/CREATE_CUSTOM_THEME_WITH_CODEX.md)
- 可选 Skill：[`skills/codex-theme-author/SKILL.md`](skills/codex-theme-author/SKILL.md)

最简单的方式是把图片放进仓库，然后对 Codex 说：

```text
使用这个仓库的 $codex-theme-author，根据我提供的图片制作浅色和暗色 Codex 主题。
保留无重启注入、verify、disable 和失败恢复机制。
先只生成主题并运行测试和 DryRun，不要实际应用，等我确认后再 preview。
```

推荐图片：2560×1440、16:9、JPEG/PNG/WebP。为了给侧栏和输入区留出可读空间，建议主体位于画面右侧，左侧保持低信息区域。如果只提供一张图，Codex 可以复用图像并为浅色/暗色配置不同颜色与遮罩；也可以分别提供两张图片。

## 安全边界

- Inspector 只绑定 `127.0.0.1:9229`，每次注入后立即关闭。
- 连接后必须验证目标 PID 是当前 Store Codex 主进程。
- 已存在的旧 CodeDrobe 事务或端口 9335 会阻止热引擎运行。
- `verify` 检查主题样式、背景、主区域与指针事件。
- `disable` 可以在残留 Inspector 确认属于同一 Codex PID 后接管并恢复。
- 不读取或复制 Cookie、登录态、API Key 或 Codex 对话内容。

## 项目结构

```text
assets/backgrounds/        XJTU 原始背景素材
themes/xjtu-academic-*/    XJTU CodeDrobe 兼容主题源
engine/                    无重启主题引擎
template/unbranded/        无品牌派生模板
skills/codex-theme-author/ 可选 Codex 主题作者 Skill
docs/                      自定义主题教程
scripts/                   安装、验证与恢复脚本
```

`dist/` 和旧 CodeDrobe 脚本作为历史兼容与恢复资料保留。新的默认入口是 `xjtu-theme.cmd`。

## 许可

本项目采用 [`XJTU Codex Theme Non-Commercial Source License 1.0`](LICENSE)：

- 个人、学习、研究和其他非商业用途可以查看、使用、修改和再分发。
- 商业使用、收费服务、商业产品集成或以商业利益为目的的使用，需要事先联系项目作者并取得单独商业授权。
- 该许可不是 OSI 批准的开源许可证，因此本项目应准确描述为 **source-available / 源代码公开项目**。

商业授权方式见 [`COMMERCIAL_LICENSE.md`](COMMERCIAL_LICENSE.md)。第三方许可见 [`engine/THIRD_PARTY_NOTICES.md`](engine/THIRD_PARTY_NOTICES.md)。

## 致谢与声明

Inspector 脉冲架构参考了 `okkskin` 0.2.0 的 MIT 授权实现，相关版权和许可全文已保留。本项目及其中的 XJTU 风格素材为非官方创作，不代表 OpenAI 或西安交通大学的认可、授权或官方发布。

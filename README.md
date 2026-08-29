# XJTU Codex Theme

> **不用重启 Codex，就能给 Codex Desktop 换皮肤。**
>
> 现成 XJTU 校园主题 + 一句话生成自己的浅色/暗色主题 + 可验证、可恢复的本地热切换。

XJTU Codex Theme 是一个面向 **Microsoft Store 版 Codex Desktop** 的 Windows 本地主题项目。

它解决的不是“怎么改 Electron 文件”，而是一个更直接的问题：

> **我想让 Codex 看起来像我自己的工具，但又不想每次更新、切换、恢复都去手改 `app.asar`。**

项目包含三部分：

1. **XJTU Academic Theme** — 已经做好的西安交通大学浅色 / 暗色主题；
2. **Codex Skin Maker** — 给一张或两张图片，让 Codex 帮你生成、检查和预览主题；
3. **Unbranded Template** — 给高级用户和开发者制作自己的主题。

主题通过短暂的本机 Node Inspector 脉冲注入到正在运行的 Codex，不修改 `WindowsApps`、`app.asar`、Codex 配置、浏览器资料或登录凭据。

## 效果预览

| XJTU Academic Dark | XJTU Academic Light |
| --- | --- |
| ![XJTU Codex dark theme](docs/media/xjtu-codex-dark.png) | ![XJTU Codex light theme](docs/media/xjtu-codex-light.png) |

### 无重启切换

![Switch between XJTU Codex light and dark themes without restarting](docs/media/xjtu-codex-theme-demo.gif)

[观看高清 MP4 演示](https://github.com/jiezeng2004-design/XJTU-Codex-Theme/releases/latest/download/xjtu-codex-theme-demo.mp4)

## 最快开始

环境：

- Windows 10 / 11 x64
- Microsoft Store 版 Codex Desktop
- Node.js 22+

先做只读检查：

```cmd
xjtu-theme.cmd doctor
```

预览暗色或浅色主题：

```cmd
xjtu-theme.cmd preview dark
xjtu-theme.cmd preview light
```

切换、验证和恢复：

```cmd
xjtu-theme.cmd switch
xjtu-theme.cmd verify
xjtu-theme.cmd disable
```

`preview` 只作用于当前 Codex 进程。`disable` 会移除注入的样式与事件钩子，并清理本地主题状态。

## 一句话做自己的 Codex 皮肤

如果你不想研究主题 JSON、Inspector 或布局结构，可以直接使用 [`codex-skin-maker`](skills/codex-skin-maker/SKILL.md)。

先安装 Skill：

```text
使用 $skill-installer 安装这个 Skill：
https://github.com/jiezeng2004-design/XJTU-Codex-Theme/tree/main/skills/codex-skin-maker
```

然后把你有权使用的图片交给 Codex：

```text
使用 $codex-skin-maker，把这张图片做成我的 Codex 皮肤。
浅色和深色都要，先生成和检查，不要直接应用。
```

Skill 会：

1. 检查 Windows、Node.js、Codex Desktop 和兼容状态；
2. 从无品牌模板生成浅色 / 暗色主题；
3. 跑资源检查、单元测试、安全测试和离线 Dry Run；
4. 展示结果并等待你明确确认；
5. 只预览你确认的模式；
6. 失败时执行 `disable` 恢复原版。

完整教程见 [`docs/CODEX_SKIN_MAKER.md`](docs/CODEX_SKIN_MAKER.md)。

## 为什么不用直接改 `app.asar`

这个项目的核心思路是：**尽量不碰 Codex 安装文件本身**。

```text
Codex 正在运行
   ↓
短暂打开本机 Inspector
   ↓
确认目标 PID
   ↓
注入主题
   ↓
立即关闭 Inspector
```

这样做的目标是让：

- 主题可以热切换；
- 退出主题不需要重装 Codex；
- Codex 更新后的兼容检查更清晰；
- 故障时有明确的恢复入口。

## 使用自己的图片

无品牌模板：

```text
template/unbranded/
```

高级教程：

- [`docs/CREATE_CUSTOM_THEME_WITH_CODEX.md`](docs/CREATE_CUSTOM_THEME_WITH_CODEX.md)
- [`skills/codex-skin-maker/SKILL.md`](skills/codex-skin-maker/SKILL.md)
- [`skills/codex-theme-author/SKILL.md`](skills/codex-theme-author/SKILL.md)

高级用户也可以对 Codex 说：

```text
使用这个仓库的 $codex-theme-author，根据我提供的图片制作浅色和暗色 Codex 主题。
保留无重启注入、verify、disable 和失败恢复机制。
先只生成主题并运行测试和 DryRun，不要实际应用，等我确认后再 preview。
```

推荐图片：2560×1440、16:9、JPEG / PNG / WebP。为了侧栏和输入区可读，建议主体偏右、左侧保留低信息区域。

## 安全边界

- Inspector 只绑定 `127.0.0.1:9229`；
- 每次注入后立即关闭；
- 连接后验证目标 PID 是当前 Store Codex 主进程；
- 已存在的冲突 Inspector / 旧事务会阻止热引擎继续；
- `verify` 检查主题样式、背景、主区域和指针事件；
- `disable` 提供恢复路径；
- 不读取或复制 Cookie、登录态、API Key 或 Codex 对话内容；
- `codex-skin-maker` 不把“帮我做主题”本身视为实际注入授权，预览前需要再次确认。

## 兼容性

这是一个依赖 Codex Desktop Electron 内部结构的**非官方实验性项目**。Codex 更新后可能需要适配。

精确兼容状态和更新后的检查步骤见：

[`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md)

建议在每次 Codex 大版本更新后先运行：

```cmd
xjtu-theme.cmd doctor
```

再决定是否预览主题。

## 项目结构

```text
assets/backgrounds/         XJTU 背景素材
themes/xjtu-academic-*/     XJTU 主题源
engine/                     无重启主题引擎
template/unbranded/         无品牌模板
skills/codex-skin-maker/    普通用户换肤 Skill
skills/codex-theme-author/  高级主题作者 Skill
docs/                       自定义主题与兼容性文档
scripts/                    安装、验证与恢复脚本
```

## 许可

本项目采用 [`XJTU Codex Theme Non-Commercial Source License 1.0`](LICENSE)。

- 个人、学习、研究及其他非商业用途可以查看、使用、修改和再分发；
- 商业使用、收费服务、商业产品集成或以商业利益为目的的使用，需要单独商业授权；
- 该许可证不是 OSI 批准的开源许可证，因此本项目应准确描述为 **source-available / 源代码公开项目**。

商业授权说明见 [`COMMERCIAL_LICENSE.md`](COMMERCIAL_LICENSE.md)。第三方许可见 [`engine/THIRD_PARTY_NOTICES.md`](engine/THIRD_PARTY_NOTICES.md)。

## 声明

这是非官方社区项目，不隶属于或代表 OpenAI / 西安交通大学。XJTU 风格素材与主题均为非官方创作。

Inspector 脉冲架构参考了 `okkskin` 0.2.0 的 MIT 授权实现，相关版权与许可已保留。
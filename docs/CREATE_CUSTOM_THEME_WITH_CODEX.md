# 用 Codex 制作自定义皮肤

本教程让 Codex 根据一张或两张本地图片制作无重启主题。默认只生成和验证文件，不直接修改正在运行的 Codex。

## 准备

1. 克隆或复制本仓库。
2. 使用 Git 新建分支，避免覆盖 XJTU 成品主题。
3. 准备拥有使用与分发权的 JPEG、PNG 或 WebP 图片。
4. 推荐 2560×1440、16:9，主体位于右侧，左侧约 40%–45% 保持低信息区域。

不要使用包含密码、Token、Cookie、私人聊天、个人证件、未授权摄影、官方校徽或水印的图片。

## 推荐提示词

把图片附加给 Codex，或提供图片的本地绝对路径，然后发送：

```text
使用当前仓库中的 $codex-theme-author 制作我的 Codex 主题。

输入图片：<图片路径或附件>
主题名称：<名称>

要求：
- 从 template/unbranded 开始，不修改 XJTU 原始图片。
- 如果只有一张图，为浅色和暗色配置复用图片或生成非破坏性的本地派生版本。
- 将最终主题资产保存到新的 themes/<slug>-dark 和 themes/<slug>-light 目录。
- 更新 engine/themes/dark.json 和 light.json 指向新资产。
- 检查文字、面板和边框对比度。
- 运行主题验证器、Node 单测、PowerShell 语法检查和 preview --dry-run。
- 不应用主题、不重启 Codex、不创建计划任务，等我确认后再执行真实 preview。
```

## Codex 应执行的文件流程

1. 读取 `template/unbranded/dark.json` 和 `light.json`。
2. 创建新的主题资产目录，不覆盖输入原图。
3. 将图片复制或优化为 `hero.jpg`、`hero.png` 或 `hero.webp`。
4. 修改主题 ID、名称、图片路径、颜色和布局。
5. 将完成的两个清单写入 `engine/themes/dark.json` 与 `light.json`。
6. 使用以下命令验证：

```powershell
node .\skills\codex-theme-author\scripts\validate-theme-pack.mjs .
node --test --test-isolation=none .\engine\tests\engine.test.mjs
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-hot-theme-engine.ps1
```

7. 向用户展示改动和验证结果，等待明确授权。
8. 获得授权后，只运行一次真实预览并立即验证：

```cmd
xjtu-theme.cmd preview dark
xjtu-theme.cmd verify
```

9. 如果显示异常、健康检查失败或 9229 未关闭，立即运行：

```cmd
xjtu-theme.cmd disable
```

## 调整建议

- `positionX`：背景视觉焦点的水平位置；主体偏右时通常使用 `64%`–`76%`。
- `zoom`：背景高度缩放；通常从 `105%`–`118%` 开始。
- `bodyScrimStart/End`：整体遮罩强度。
- `mainScrimStart/End`：主区域透明色层强度。
- `sidebarScrimStart/End`：侧栏可读性强度。
- `conversationWallpaper`：默认保持 `false`，避免长对话页面受背景干扰。

调整时优先保证：按钮可点击、输入框清晰、长对话可读、背景只绘制一次、Inspector 能正常关闭。

## Skill 是可选的

仓库内的 `skills/codex-theme-author/` 可以复制到用户的 Codex Skills 目录，但不是运行主题所必需的。没有安装 Skill 时，也可以直接把上面的提示词和本教程交给 Codex。

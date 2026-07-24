# Codex Skin Maker：一张图、一句话给 Codex 换肤

`codex-skin-maker` 是 XJTU Codex Theme 面向普通用户提供的简化 Skill。它把主题 manifest、资源目录、环境检查、自动化测试和恢复流程封装起来，让用户主要通过自然语言完成换肤。

> 这是非官方实验性项目，仅支持 Windows 10/11 x64 与 Microsoft Store 版 Codex Desktop。Codex 更新后可能需要重新适配。真实预览前必须运行兼容性检查。

## 它能做什么

- 用一张图片同时制作浅色和深色皮肤；
- 用两张图片分别制作浅色和深色皮肤；
- 自动调整背景位置、遮罩、面板和文字颜色；
- 在应用前运行主题校验、测试和离线 Dry Run；
- 只有用户明确同意后才临时预览；
- 验证失败时自动退出皮肤并恢复原版；
- 根据一句话调整已有皮肤；
- 随时执行“恢复原版”。

## 准备条件

- Windows 10/11 x64；
- Microsoft Store 版 Codex Desktop；
- Node.js 22 或更新版本；
- 一张或两张本人拥有或明确获准使用的 JPEG、PNG、WebP 图片。

推荐图片为 2560×1440、16:9，主体放在右侧，左侧尽量简洁。

## 安装 Skill

### 方法一：让 Codex 安装 GitHub Skill

在 Codex 中调用内置 Skill Installer：

```text
使用 $skill-installer 安装这个 Skill：
https://github.com/jiezeng2004-design/XJTU-Codex-Theme/tree/main/skills/codex-skin-maker
```

安装后重新打开 Codex，使新 Skill 被发现。

### 方法二：在 Skill 页面上传

支持上传 Skill 的 ChatGPT/Codex 界面中，可以下载 `skills/codex-skin-maker/` 目录并作为完整 Skill 文件夹上传。不要只上传 `SKILL.md`，因为环境检查、引导脚本和参考文档也属于 Skill 的一部分。

### 方法三：直接在仓库工作区使用

克隆或下载仓库，在仓库目录中打开 Codex，然后直接调用：

```text
使用这个仓库的 $codex-skin-maker，把我提供的图片制作成 Codex 皮肤。
先生成和测试，不要直接应用。
```

如果 Skill 已安装但当前工作区没有主题引擎，它会在命令审批后运行 `bootstrap-workspace.ps1`，从官方仓库下载固定到已验证 `v0.3.0-rc.1` 提交的独立工作区。脚本不跟随可变分支，不接受自定义远程源，也不会覆盖非空目录。

直接在官方仓库的开发分支中验收时，贡献者需要先确认 `origin` 和工作区状态，再显式给环境检查传入 `-AllowDevelopmentWorkspace`。普通换肤不应使用这个开发开关。

## 第一次使用

把图片拖入 Codex 或保存到当前工作区，然后输入：

```text
使用 $codex-skin-maker，把这张图片做成我的 Codex 皮肤。
主题叫“校园晚霞”，浅色和深色都要。
先生成和检查，不要直接应用。
```

Codex 应依次完成：

1. 检查 Windows、Node.js、Codex 类型和版本；
2. 检查图片格式、敏感信息和授权风险；
3. 生成浅色和深色主题；
4. 运行 manifest 校验、资源检查、单元测试、安全测试和离线 Dry Run；
5. 展示修改文件和检查摘要；
6. 等待你明确选择“预览深色”或“预览浅色”。

## 预览和恢复

生成完成后，主题仍未应用。你可以说：

```text
预览深色。
```

Skill 会执行一次真实预览并立即运行 `verify`。如果验证失败，它必须自动执行 `disable`，不能连续重试。

退出皮肤时说：

```text
恢复原版并检查是否清理完成。
```

## 两张图片的用法

```text
使用 $codex-skin-maker：
- light.png 用于浅色模式
- dark.png 用于深色模式
主题名叫“实验室昼夜”
左侧文字优先清晰，正文区域不要铺壁纸。
先测试，不要应用。
```

## 调整已有皮肤

```text
使用 $codex-skin-maker，把当前深色皮肤的侧栏压暗一些，输入框再明显一点。
不要更换原图，只生成、验证和 Dry Run。
```

Skill 应保留用户原图和已有改动，通过新文件或可审查 diff 完成调整。

## 安全与隐私

该工作流不得：

- 修改 `WindowsApps` 或 `app.asar`；
- 读取 Cookie、登录态、API Key 或 Codex 对话；
- 把 Inspector 暴露到公网或局域网；
- 创建自启动、计划任务或后台服务；
- 在未经同意的情况下下载、应用、发布或上传主题；
- 删除或覆盖用户原图；
- 移除第三方水印或抓取来源不明素材。

真实预览只通过短暂的本机 Inspector 脉冲工作，并且保留 `disable` 恢复入口。

## 常见问题

### 为什么生成后还要确认一次？

“制作主题”只授权生成文件和离线检查，不等于允许连接正在运行的 Codex 进程。真实预览属于单独的本机操作，因此需要明确确认。

### Codex 更新后还能用吗？

不一定。先查看 [`COMPATIBILITY.md`](COMPATIBILITY.md)，并运行只读 `doctor`。CI 通过不能替代真实版本验证。

### 这是开源项目吗？

项目源代码公开，但采用非商业 Source License，不是 OSI 批准的开源许可证。个人、学习、研究和其他非商业用途可以使用和修改；商业使用需要单独授权。

### 能否制作学校、动漫或品牌主题？

技术上可以使用用户提供的图片，但用户必须确保拥有使用权。项目声明“非官方”并不会自动获得校徽、商标、摄影作品或动漫角色的授权。

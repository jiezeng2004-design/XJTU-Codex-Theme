# 兼容性与安全门槛

## 支持范围

当前工作流仅面向：

- Windows 10/11 x64；
- Microsoft Store 版 Codex Desktop；
- Node.js 22 或更新版本；
- 仓库兼容矩阵中明确验证或经用户本机 `doctor`、真实预览和 `verify` 验证的 Codex 版本。

Codex 更新可能改变 Electron 主进程、渲染器结构或页面选择器。CI 通过只代表 JSON、脚本、单元测试和离线 Dry Run 通过，不代表新 Codex 版本一定可以真实注入。

## 真实预览前的硬门槛

以下条件必须全部满足：

1. `xjtu-theme.cmd doctor` 成功；
2. 检测到的目标属于 Microsoft Store Codex；
3. 目标 PID 可确认是当前 Codex 主进程；
4. Inspector 端口未被未知进程占用；
5. 不存在未恢复的旧 CodeDrobe 事务；
6. 主题 manifest 和资源路径校验通过；
7. 引擎单元测试通过；
8. PowerShell 安全测试通过；
9. 离线 Dry Run 通过；
10. 用户明确批准真实预览。

缺少任一条件时只能停留在生成、诊断或 Dry Run 阶段。

## 立即停止并恢复的情况

出现以下任一情况，立即执行 `xjtu-theme.cmd disable`：

- `preview` 返回非零退出码；
- `verify` 失败；
- 背景层遮挡输入框、按钮或会话交互；
- Inspector 未按预期关闭；
- 主题注入到了无法确认的 Electron 进程；
- 用户要求恢复原版；
- Codex 出现明显渲染异常、白屏或无响应。

恢复后再次运行状态检查。不要连续重试真实注入来“碰运气”。

## 明确禁止

- 修改 `WindowsApps`；
- 解包或替换 `app.asar`；
- 读取 Cookie、登录态、API Key、账号资料或对话内容；
- 将 Inspector 暴露到非回环地址；
- 创建自启动、计划任务、后台守护进程或永久端口监听；
- 绕过 Codex 或系统的命令审批；
- 下载并执行来源不明的脚本；
- 为了换肤关闭系统安全软件；
- 在未经授权的情况下推送主题、发布 Release 或上传用户图片。

## Git 工作区保护

- 开始前读取 `git status --short`；
- 不重置、不清理、不覆盖用户现有改动；
- 派生图片和主题文件使用新路径；
- 需要修改 active manifest 时，先记录原内容或依赖 Git diff 可恢复；
- 未经用户明确要求，不执行 `git commit`、`git push`、创建 PR 或发布 Release。

## 隐私输出

错误报告和兼容性反馈只能包含：

- XJTU Theme 版本；
- Codex Desktop 版本；
- Windows 版本；
- 执行的主题命令；
- 已脱敏的相关错误。

不得包含令牌、Cookie、账号、完整日志、无关本地路径、用户名、对话内容或用户图片原件。

---
name: bat-run
description: 创建 .bat 的 .ps1 包装器并自动执行测试，失败则自动修复重试，直到成功运行。
---

# /bat-run — 创建 + 测试 .bat → .ps1 包装器

用户调用 `/bat-run <path-to-bat-file>` 时，执行以下循环：

## 逻辑流程

```
用户: /bat-run C:\project\setup.bat
        │
        ▼
┌──────────────────────────────┐
│ 检查 setup_runner.ps1 存在?  │
└──────────┬───────────────────┘
           │
    ┌──────┴──────┐
    │ 存在         │ 不存在
    ▼              ▼
  跳过创建    ┌──────────────────┐
              │ 调用 /bat2ps1 逻辑 │
              │ 创建 _runner.ps1   │
              └────────┬─────────┘
                       │
              ┌────────┴────────┐
              ▼                 ▼
┌──────────────────────────────────┐
│ 执行 _runner.ps1                 │
│ powershell -File _runner.ps1     │
│ 捕获 stdout + stderr + exit code │
└──────────────┬───────────────────┘
               │
        ┌──────┴──────┐
        │ exit 0?      │ exit != 0 或有错误
        ▼              ▼
     ✅ 成功!    ┌─────────────────────┐
                 │ 分析错误 + 修复脚本  │
                 │ 最多重试 3 次        │
                 └────────┬────────────┘
                          │
                          ▼
                   重新执行 (循环)
```

## 详细步骤

### 第一步：检查包装器是否存在

1. 根据 .bat 文件路径推导包装器路径：`<dir>\<name>_runner.ps1`
2. 如果存在，跳到**第三步**（执行测试）
3. 如果不存在，进入**第二步**（创建）

### 第二步：创建包装器

执行与 `/bat2ps1` 完全相同的逻辑：
1. 读取 .bat 文件
2. 分析需求（管理员权限、参数、编码等）
3. 在当前目录创建 `_runner.ps1`
4. 报告：`📝 已创建 <name>_runner.ps1`

### 第三步：执行测试

用 Bash 工具运行包装器：

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<path>_runner.ps1" 2>&1
```

- 设置合理的 timeout（默认 120000ms，如果 .bat 包含安装命令等长时间操作可增加到 600000ms）
- 捕获全部输出
- 记录退出代码

### 第四步：判断结果

#### ✅ 成功条件（满足任一即可）：
- Exit code = 0
- 输出包含 `[OK]` 或 `SUCCESS`
- 输出包含原始 .bat 预期的正常输出（如 "Hello", "done", "completed" 等）

#### ❌ 需要修复（最多 3 次）：
- Exit code != 0
- 输出包含错误信息（PowerShell 解析错误、找不到文件、权限拒绝等）
- 脚本在 timeout 内无响应
- 输出为空（但预期应该有输出）

### 第五步：诊断并修复

根据错误类型自动修复：

| 错误类型 | 表现 | 修复方案 |
|---------|------|---------|
| 路径空格 | "无法找到" / "is not recognized" | 确保 `$BatPath` 使用双引号包裹 |
| 编码问题 | 乱码 / cmd 不执行 | 检测编码，必要时转换 |
| 权限不足 | "Access denied" / "requires elevation" | 添加管理员自提升代码 |
| 工作目录错误 | "file not found" for relative paths | 确认 `Push-Location` 正确 |
| 环境变量缺失 | "is not defined" / 找不到命令 | 确认 cmd.exe 的 PATH 继承 |
| 依赖文件缺失 | "No such file" 引用其他脚本 | 检查同目录依赖，提示用户 |
| 长时间运行 | timeout | 增加 timeout，提示用户等待 |
| PowerShell 版本 | 语法不兼容 | 降级到 PS 5.1 兼容语法 |

### 第六步：重试

修复后重新执行，最多重试 **3 次**。
- 第 1 次修复：基础修复（路径、编码）
- 第 2 次修复：深度分析（读取 .bat 全文，逐行分析）
- 第 3 次修复：如果仍然失败，告知用户具体错误并建议手动处理

## 最终报告

成功时：
```
✅ /bat-run 完成
📁 包装器: C:\project\setup_runner.ps1
📋 原始文件: C:\project\setup.bat
🔧 重试次数: 0
💡 下次可直接运行: powershell -File "C:\project\setup_runner.ps1"
```

失败时（3次重试后仍失败）：
```
❌ /bat-run 未能成功运行
📁 包装器: C:\project\setup_runner.ps1
📋 错误摘要: <具体错误>
💡 建议: <具体建议>，或手动在 cmd 中运行原始 .bat: cmd /c "C:\project\setup.bat"
```

## 注意事项

- 如果 .bat 文件运行的是长时间服务（如 Web 服务器），不要阻塞等待——提示用户这是持久进程
- 如果 .bat 需要交互输入（如确认提示），使用 `echo y |` 管道或添加 `-y` 标志
- 永远不要删除或修改原始 .bat 文件
- 修改只限于 `_runner.ps1` 包装器

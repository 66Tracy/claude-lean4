# Lean4 Docker 一键运行与环境复刻

本项目已固定 Lean/Mathlib 环境，目标是**快速启动、快速运行**，适合并行启动多个容器做证明试错。

## 现有环境摘要

- 本地镜像：`leanprovercommunity/lean4:fixed`（指向当前本地镜像）
- Claude 镜像：`leanprovercommunity/lean4:claude`
- Lean 版本：`leanprover/lean4:v4.10.0`
- Mathlib：本地路径 `mathlib4-4.10.0/`（**不进仓库，需要手动下载**）
- 一键脚本：`run_lean.ps1` / `run_lean_claude.ps1`
- 只读隔离脚本：`run_lean_claude_ro.ps1` / `run_lean_claude_ro_persist.ps1`
- 共享工具链缓存：`.elan-cache/`

## 一键启动（推荐）

默认运行 `test.lean`：

```
.\run_lean.ps1
```

运行任意命令（例如检查导入）：

```
.\run_lean.ps1 "lake env lean check_list.lean"
```

脚本特性：
- 固定镜像（避免自动更新）
- 自动 bootstrap `.elan-cache`（首次运行会把工具链拷贝出来）
- 使用 Lake 环境，确保 Mathlib 可用

## Claude 镜像一键入口

默认运行 `test.lean`：

```
.\run_lean_claude.ps1
```

运行 claude：

```
.\run_lean_claude.ps1 "claude --help"
```

## 只读隔离运行（并行推荐）

### 临时草稿（容器退出即清理）

```
.\run_lean_claude_ro.ps1
```

说明：
- `/workspace` 只读
- `/scratch` 为 tmpfs（高速、退出即清理）
- `.lake` 每次使用独立卷，避免并发锁冲突

### 持久化草稿（可保留草稿）

```
.\run_lean_claude_ro_persist.ps1
```

可指定草稿目录：

```
.\run_lean_claude_ro_persist.ps1 -ScratchDir ".scratch2"
```

说明：
- `/workspace` 只读
- `/scratch` 持久化映射到 `C:\work_dir\lean4\.scratch`（可自定义）
- `.lake` 每次使用独立卷，避免并发锁冲突

## Claude 生成代码并写入 /scratch（持久化草稿区）

前提：
- `.env` 放在项目根目录（示例变量：`ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_MODEL` 等）
- `.env` 内容使用 `export KEY=value` 形式（便于 `source`）

示例：在容器内调用 claude，生成 Python 快速排序并写到持久化草稿区：

```
.\run_lean_claude_ro_persist.ps1 "set -a; source /workspace/.env; set +a; cd /scratch; claude --permission-mode bypassPermissions -p 'Write a Python quicksort implementation. Output only code, no fences.' > /scratch/quicksort.py"
```

注意事项：
- `--permission-mode bypassPermissions` 可避免 Claude 输出“需要权限”而不写代码。
- 如果输出仍包含 ``` 代码围栏，可用文本处理去除。
- `/workspace` 是只读的，所有输出应写到 `/scratch`。
- 不要把 `.env` 提交到版本库（建议加入 `.gitignore`）。

## 文件结构说明

- `mathlib4-4.10.0/`：Mathlib 源码（离线解压）
- `lakefile.lean`：本地路径依赖 `require mathlib from "./mathlib4-4.10.0"`
- `lean-toolchain`：锁定 `leanprover/lean4:v4.10.0`
- `run_lean.ps1`：一键启动脚本
- `run_lean_claude.ps1`：Claude 版一键启动脚本
- `run_lean_claude_ro.ps1`：只读隔离（临时草稿）
- `run_lean_claude_ro_persist.ps1`：只读隔离（持久化草稿）
- `.elan-cache/`：工具链缓存（避免重复下载）
- `Dockerfile.claude.latest`：基于 `leanprovercommunity/lean4:latest` 构建 Claude 镜像
- `build_claude.ps1`：一键构建 Claude 镜像脚本

仓库忽略的大目录（见 `.gitignore`）：
- `.lake/`
- `.elan-cache/`
- `.scratch/`
- `mathlib4-4.10.0/`
- `.env`

## 在其他机器复刻环境（推荐流程）

前置条件：
- 安装 Docker Desktop
- 确保能运行 `docker` 命令

### 1) 准备项目目录

复制整个项目文件夹到新机器，例如：

```
C:\work_dir\lean4
```

然后**单独下载** Mathlib v4.10.0（mathlib4 仓库的 v4.10.0 版本 zip），解压到：

```
C:\work_dir\lean4\mathlib4-4.10.0
```

### 2) 准备 Docker 镜像

拉取基础镜像并固定为本地标签：

```
docker pull leanprovercommunity/lean4:latest
docker tag leanprovercommunity/lean4:latest leanprovercommunity/lean4:fixed
```

> 如果你有离线镜像，也可以用 `docker load` 导入后再 `docker tag`。

### 3) 运行一次脚本（自动生成缓存）

在项目目录运行：

```
.\run_lean.ps1
```

这一步会：
- 自动生成 `.elan-cache/`
- 建立 Lean 工具链缓存

### 4) 获取 Mathlib 预编译缓存（推荐）

```
.\run_lean.ps1 "lake exe cache get"
```

这样可以避免 Mathlib 全量编译，大幅提速。

### 5) 构建 Claude 镜像（可选）

```
.\build_claude.ps1
```

### 6) 验证环境

```
.\run_lean.ps1 "lake env lean check_list.lean"
```

无报错即完成。

## 注意事项

- 并行容器运行时，**不要同时执行 `lake update` 或 `lake build`**，避免抢锁。
- 日常只需运行：
  ```
  .\run_lean.ps1 "lake env lean yourfile.lean"
  ```
- 若出现 `unknown module prefix 'Mathlib'`，说明没有通过 Lake 环境运行。

---

如需我进一步提供 Dockerfile 或更复杂的并行运行脚本，请告诉我。

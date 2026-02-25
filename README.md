# Lean4 Docker 一键运行与环境复刻

本项目已固定 Lean/Mathlib 环境，目标是**快速启动、快速运行**，适合并行启动多个容器做证明试错。

## 现有环境摘要

- 本地镜像：`leanprovercommunity/lean4:fixed`（指向当前本地镜像）
- Claude 镜像：`leanprovercommunity/lean4:claude`
- Lean 版本：`leanprover/lean4:v4.10.0`
- Mathlib：本地路径 `mathlib4-4.10.0/`（**不进仓库，需要手动下载**）
- 任务集：`miniF2F-benchmark/`
- 脚本目录：`scripts/`
- 示例目录：`examples/`
- 共享工具链缓存：`.elan-cache/`

## 一键启动（推荐）

默认运行 `examples/test.lean`：

```
python scripts/run_lean.py
```

运行任意命令（例如检查导入）：

```
python scripts/run_lean.py "lake env lean examples/check_list.lean"
```

脚本特性：
- 固定镜像（避免自动更新）
- 自动 bootstrap `.elan-cache`（首次运行会把工具链拷贝出来）
- 使用 Lake 环境，确保 Mathlib 可用

说明：已提供跨平台 `scripts/*.py` 脚本。

## Claude 镜像一键入口

默认运行 `examples/test.lean`：

```
python scripts/run_lean_claude.py
```

运行 claude：

```
python scripts/run_lean_claude.py "claude --help"
```

## 只读隔离运行（并行推荐）

### 临时草稿（容器退出即清理）

```
python scripts/run_lean_claude_ro.py
```

说明：
- `/workspace` 只读
- `/scratch` 为 tmpfs（高速、退出即清理）
- `LAKE_DIR=/scratch/.lake`，避免在只读 workspace 下写入

### 持久化草稿（可保留草稿）

```
python scripts/run_lean_claude_ro_persist.py
```

可指定草稿目录：

```
python scripts/run_lean_claude_ro_persist.py --scratch-dir ".scratch2"
```

说明：
- `/workspace` 只读
- `/scratch` 持久化映射到 `C:\work_dir\lean4\.scratch`（可自定义）
- `LAKE_DIR=/scratch/.lake`，避免在只读 workspace 下写入

## 任务自动化（miniF2F）

### 1) 生成任务工作区

```
python scripts/prepare_task.py -Id mathd_algebra_478
```

生成内容在：

```
C:\work_dir\lean4\.scratch\tasks\mathd_algebra_478
```

### 2) 自动运行任务（Claude）

```
python scripts/run_task.py -Id mathd_algebra_478
```

说明：
- 自动从 `miniF2F-benchmark\test-example.jsonl` 取出 `id` 和 `formal_statement`
- 生成 `task-{id}.md` 并创建 `submit.lean` / `submit.md` / `scratch/`
- 启动容器时仅挂载 `/.scratch/tasks/{id}` 为 `/task`
- `claude` 读取任务内容并将输出写到 `/task/claude.out`
- 运行结束后检查 `submit.lean` / `submit.md` 是否非空，并写入 `/task/status.json`
  - 若 `submit.lean` / `submit.md` 为空，脚本会尝试从 `claude.out` 中解析

可选参数：
- `-RequireSubmit $false` 可关闭提交文件非空检查
- `-MinSubmitBytes` 可设置最小字节数阈值
- `-TimeoutSec` 设置容器运行超时时间（秒），超时会自动停止容器并写入状态

## Claude 生成代码并写入 /scratch（持久化草稿区）

前提：
- `.env` 放在项目根目录（示例变量：`ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_MODEL` 等）
- `.env` 内容使用 `export KEY=value` 形式（便于 `source`）

示例：在容器内调用 claude，生成 Python 快速排序并写到持久化草稿区：

```
python scripts/run_lean_claude_ro_persist.py "set -a; source /workspace/.env; set +a; cd /scratch; claude --permission-mode bypassPermissions -p 'Write a Python quicksort implementation. Output only code, no fences.' > /scratch/quicksort.py"
```

注意事项：
- `--permission-mode bypassPermissions` 可避免 Claude 输出“需要权限”而不写代码。
- 如果输出仍包含 ``` 代码围栏，可用文本处理去除。
- `/workspace` 是只读的，所有输出应写到 `/scratch`。
- 不要把 `.env` 提交到版本库（已加入 `.gitignore`）。

## 文件结构说明

- `examples/`
  - `test.lean`
  - `check_list.lean`
- `miniF2F-benchmark/`
  - `task-template.md`
  - `test-example.jsonl`
- `scripts/`
  - `run_lean.py`
  - `run_lean_claude.py`
  - `run_lean_claude_ro.py`
  - `run_lean_claude_ro_persist.py`
  - `prepare_task.py`
  - `run_task.py`
  - `build_claude.py`
- `docker/`
  - `Dockerfile.claude.latest`
- `lakefile.lean`：本地路径依赖 `require mathlib from "./mathlib4-4.10.0"`
- `lean-toolchain`：锁定 `leanprover/lean4:v4.10.0`
- `.elan-cache/`：工具链缓存（避免重复下载）

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
python scripts/run_lean.py
```

这一步会：
- 自动生成 `.elan-cache/`
- 建立 Lean 工具链缓存

### 4) 获取 Mathlib 预编译缓存（推荐）

```
python scripts/run_lean.py "lake exe cache get"
```

这样可以避免 Mathlib 全量编译，大幅提速。

### 5) 构建 Claude 镜像（可选）

```
python scripts/build_claude.py
```

### 6) 验证环境

```
python scripts/run_lean.py "lake env lean examples/check_list.lean"
```

无报错即完成。

## 注意事项

- 并行容器运行时，**不要同时执行 `lake update` 或 `lake build`**，避免抢锁。
- 日常只需运行：
  ```
  python scripts/run_lean.py "lake env lean examples/yourfile.lean"
  ```
- 若出现 `unknown module prefix 'Mathlib'`，说明没有通过 Lake 环境运行。

---

如需我进一步提供 Dockerfile 或更复杂的并行运行脚本，请告诉我。

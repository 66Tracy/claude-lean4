# Lean4 小教程（Docker 版）

适用环境：Windows + Docker + 本地镜像 `leanprovercommunity/lean4:fixed`。

## 0. 目录约定（本项目当前状态）

- `mathlib4-4.10.0/`：本地解压后的 Mathlib 源码
- `lakefile.lean`：使用本地依赖 `require mathlib from "./mathlib4-4.10.0"`
- `lean-toolchain`：**已与 Mathlib 对齐** `leanprover/lean4:v4.10.0`
- `run_lean.ps1`：一键运行脚本（推荐）

## 1. 一键运行（推荐）

默认执行 `test.lean`：

```
.\run_lean.ps1
```

运行 Mathlib 导入检查：

```
.\run_lean.ps1 "lake env lean check_list.lean"
```

脚本做了这些事：
- 固定镜像（`leanprovercommunity/lean4:fixed`）
- 使用共享 `.elan-cache`（避免每次下载工具链）
- 默认 `--pull=never`（不会自动更新镜像）
- 首次运行会自动把镜像里的 `/home/lean/.elan` 拷贝到 `.elan-cache`

## 2. 常用命令（不经过脚本）

推荐用 Lake 环境运行：

```
docker run --rm -v C:\work_dir\lean4:/workspace -w /workspace leanprovercommunity/lean4:fixed -lc "lake env lean test.lean"
```

直接 `lean file.lean` 会绕过 Lake，Mathlib 可能找不到。

## 3. 首次准备与缓存说明

**工具链缓存（`.elan-cache`）**
- 只要运行过 `run_lean.ps1`，缓存就会落在 `C:\work_dir\lean4\.elan-cache`。
- 之后并行容器共享该缓存，不再重复下载。

**Mathlib 预编译缓存（`.olean`）**
- 若需要手动拉取：
  ```
  .\run_lean.ps1 "lake exe cache get"
  ```
- 已成功拉取过的话，无需重复。

## 4. 常见报错与修复

### 报错：`expected token`（文件第 1 行）
**原因**：UTF-8 BOM。

**解决**：保存为 UTF-8 无 BOM。

PowerShell 示例：
```
$path = 'C:\work_dir\lean4\test.lean'
$content = @"
-- your file here
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

### 报错：`unknown module prefix 'Mathlib'`
**原因**：直接用 `lean` 跑，没有通过 Lake。

**解决**：
```
.\run_lean.ps1 "lake env lean yourfile.lean"
```

### 报错：`cannot execute binary file`
**原因**：镜像入口已是 `/usr/bin/bash`，不要再传 `bash -lc`。

**正确用法**：
```
docker run --rm -v C:\work_dir\lean4:/workspace -w /workspace leanprovercommunity/lean4:fixed -lc "lake env lean test.lean"
```

## 5. 编码/符号避免乱码

- 使用 ASCII 的 `->`，不要出现奇怪符号（例如 `鈫?`）。
- 确保编辑器编码为 UTF-8 无 BOM。
- 发现乱码时，手动替换为标准 ASCII 符号。

## 6. 并行运行建议（多个容器）

- **不要并行运行 `lake update` / `lake build`**（会抢锁/重复下载）。
- 平时只用：
  ```
  .\run_lean.ps1 "lake env lean yourfile.lean"
  ```
- 建议先在单容器内预热一次缓存，再并行启动。

## 7. check_list 提示

`check_list.txt` 中有些模块在 `mathlib4-4.10.0` 里 **并不存在**，例如：
- `Mathlib.Algebra.Associated` 实际应为 `Mathlib.Algebra.Associated.Basic`

如果导入报错，请根据 `mathlib4-4.10.0/Mathlib` 的实际路径调整。

---

如需我补充更系统的 Lean 入门示例（`theorem`、`simp`、`rw` 等），告诉我即可。
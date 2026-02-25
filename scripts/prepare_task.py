import argparse
import sys
from pathlib import Path

from common import ensure_dir, read_jsonl, repo_root, resolve_path


README_TEXT = """# Task Workspace

This directory is mounted to /task inside the container.

Do NOT run lake update or lake build (workspace is read-only).

Run Lean with Mathlib from /workspace:

  cd /workspace
  lake env lean /task/submit.lean

Or for scratch:

  cd /workspace
  lake env lean /task/scratch/scratch.lean

All writable work should go under /task.
"""


def prepare_task(
    task_id: str,
    jsonl: str,
    template: str,
    out_root: str,
) -> Path:
    root = repo_root()
    jsonl_path = resolve_path(root, jsonl)
    template_path = resolve_path(root, template)
    out_base = resolve_path(root, out_root)
    out_dir = out_base / task_id

    if not jsonl_path.exists():
        raise FileNotFoundError(f"JSONL not found: {jsonl_path}")
    if not template_path.exists():
        raise FileNotFoundError(f"Template not found: {template_path}")

    entry = None
    for obj in read_jsonl(jsonl_path):
        if obj.get("id") == task_id:
            entry = obj
            break
    if not entry:
        raise ValueError(f"Id not found in JSONL: {task_id}")

    ensure_dir(out_dir)
    ensure_dir(out_dir / "scratch")

    template_text = template_path.read_text(encoding="utf-8")
    task_text = template_text.replace("{id}", entry["id"]).replace(
        "{question}", entry["formal_statement"]
    )
    (out_dir / f"task-{entry['id']}.md").write_text(task_text, encoding="utf-8")

    submit_lean = out_dir / "submit.lean"
    submit_md = out_dir / "submit.md"
    paper = out_dir / "scratch" / "scratch-paper.md"
    slean = out_dir / "scratch" / "scratch.lean"
    spy = out_dir / "scratch" / "scratch.py"
    task_readme = out_dir / "README.md"

    for path in (submit_lean, submit_md, paper, slean, spy):
        if not path.exists():
            path.write_text("", encoding="utf-8")

    if not task_readme.exists():
        task_readme.write_text(README_TEXT, encoding="utf-8")

    return out_dir


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare a task workspace from JSONL.")
    parser.add_argument("-Id", "--id", required=True, help="Task id.")
    parser.add_argument(
        "-Jsonl",
        "--jsonl",
        default="miniF2F-benchmark/test-example.jsonl",
        help="JSONL task file (relative to repo root).",
    )
    parser.add_argument(
        "-Template",
        "--template",
        default="miniF2F-benchmark/task-template.md",
        help="Task template file (relative to repo root).",
    )
    parser.add_argument(
        "-OutRoot",
        "--out-root",
        default=".scratch/tasks",
        help="Output root directory (relative to repo root).",
    )
    args = parser.parse_args()

    try:
        out_dir = prepare_task(args.id, args.jsonl, args.template, args.out_root)
    except (FileNotFoundError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1

    print(f"Prepared task workspace: {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

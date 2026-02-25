import argparse
import os
import re
import sys
import time
import uuid
from datetime import datetime
from pathlib import Path

from common import docker, ensure_elan_cache, parse_bool, repo_root
from prepare_task import prepare_task


def write_if_empty(path: Path, content: str, min_bytes: int) -> None:
    if not path.exists() or path.stat().st_size < min_bytes:
        if content.strip():
            path.write_text(content.strip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run a task in the Claude container.")
    parser.add_argument("-Id", "--id", required=True, help="Task id.")
    parser.add_argument(
        "-Image",
        "--image",
        default="leanprovercommunity/lean4:claude",
        help="Docker image tag.",
    )
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
        "-RequireSubmit",
        "--require-submit",
        type=parse_bool,
        default=True,
        help="Require submit files to be non-empty.",
    )
    parser.add_argument(
        "-MinSubmitBytes",
        "--min-submit-bytes",
        type=int,
        default=1,
        help="Minimum size for submit files.",
    )
    parser.add_argument(
        "-TimeoutSec",
        "--timeout-sec",
        type=int,
        default=600,
        help="Timeout (seconds) for container run.",
    )
    args = parser.parse_args()

    root = repo_root()
    elan_cache = root / ".elan-cache"
    ensure_elan_cache(elan_cache, args.image)

    try:
        task_root = prepare_task(args.id, args.jsonl, args.template, ".scratch/tasks")
    except (FileNotFoundError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1

    cmd = (
        "set -a; source /workspace/.env; set +a; "
        "python3 /workspace/scripts/run_claude_from_task.py "
        f"/task/task-{args.id}.md /task/claude.out"
    )

    container_name = f"task_{args.id}_{uuid.uuid4().hex}"
    result = docker(
        "run",
        "-d",
        "--pull=never",
        "--name",
        container_name,
        "-v",
        f"{os.fspath(root)}:/workspace:ro",
        "-v",
        f"{os.fspath(elan_cache)}:/home/lean/.elan",
        "-v",
        f"{os.fspath(task_root)}:/task",
        "-e",
        "LAKE_DIR=/task/.lake",
        "-w",
        "/workspace",
        args.image,
        "-lc",
        cmd,
        capture_output=True,
        check=False,
    )
    container_id = (result.stdout or "").strip()
    if result.returncode != 0 or not container_id:
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        print("Failed to start container", file=sys.stderr)
        return 1

    elapsed = 0
    running = True
    while elapsed < args.timeout_sec:
        running_res = docker(
            "inspect",
            "-f",
            "{{.State.Running}}",
            container_name,
            capture_output=True,
            check=False,
        )
        running_str = (running_res.stdout or "").strip()
        if running_str == "false":
            running = False
            break
        time.sleep(2)
        elapsed += 2

    timed_out = running
    if timed_out:
        docker("stop", container_name, check=False)

    exit_res = docker(
        "inspect",
        "-f",
        "{{.State.ExitCode}}",
        container_name,
        capture_output=True,
        check=False,
    )
    exit_code = (exit_res.stdout or "").strip() or "unknown"
    docker("rm", container_name, check=False)

    submit_lean = task_root / "submit.lean"
    submit_md = task_root / "submit.md"
    claude_out = task_root / "claude.out"

    if claude_out.exists():
        raw = claude_out.read_text(encoding="utf-8", errors="ignore")
        match = re.search(
            r"===SUBMIT_LEAN===\s*(.*?)\s*===SUBMIT_MD===\s*(.*)\Z",
            raw,
            flags=re.S,
        )
        if match:
            write_if_empty(submit_lean, match.group(1), args.min_submit_bytes)
            write_if_empty(submit_md, match.group(2), args.min_submit_bytes)

    issues = []
    if not claude_out.exists() or claude_out.stat().st_size < 1:
        issues.append("claude.out is missing or empty")
    if args.require_submit:
        if not submit_lean.exists() or submit_lean.stat().st_size < args.min_submit_bytes:
            issues.append("submit.lean is missing or empty")
        if not submit_md.exists() or submit_md.stat().st_size < args.min_submit_bytes:
            issues.append("submit.md is missing or empty")

    status = {
        "id": args.id,
        "timed_out": timed_out,
        "exit_code": exit_code,
        "ok": len(issues) == 0,
        "issues": issues,
        "claude_out": os.fspath(claude_out),
        "submit_lean": os.fspath(submit_lean),
        "submit_md": os.fspath(submit_md),
        "timestamp": datetime.now().isoformat(timespec="seconds"),
    }
    (task_root / "status.json").write_text(
        json_dumps(status), encoding="utf-8"
    )

    if timed_out:
        print(f"Task timed out after {args.timeout_sec}s", file=sys.stderr)
        return 3
    if issues:
        print("Task completed with issues: " + "; ".join(issues), file=sys.stderr)
        return 2

    print(f"Task run complete. Outputs in: {task_root}")
    return 0


def json_dumps(obj) -> str:
    import json

    return json.dumps(obj, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    sys.exit(main())

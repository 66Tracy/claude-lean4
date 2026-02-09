import pathlib
import subprocess
import sys

if len(sys.argv) < 3:
    raise SystemExit("usage: run_claude_from_task.py <task_md> <out_file>")

task_md = sys.argv[1]
out_file = sys.argv[2]

system_prompt = (
    "You are running in a read-only workspace. Do NOT run lake update/build. "
    "All writable work must go under /task. "
    "To run Lean with Mathlib, use: cd /workspace && lake env lean /task/submit.lean "
    "or cd /workspace && lake env lean /task/scratch/scratch.lean."
)

prompt = pathlib.Path(task_md).read_text(encoding="utf-8")
with open(out_file, "w", encoding="utf-8") as f:
    subprocess.run(
        [
            "claude",
            "--permission-mode",
            "bypassPermissions",
            "--append-system-prompt",
            system_prompt,
            "-p",
            prompt,
        ],
        stdout=f,
        stderr=sys.stderr,
        check=False,
    )

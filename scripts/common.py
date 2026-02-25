import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def resolve_path(root: Path, path_str: str) -> Path:
    path = Path(path_str)
    if not path.is_absolute():
        path = root / path
    return path


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def run(cmd, *, capture_output=False, check=True):
    try:
        return subprocess.run(
            cmd,
            check=check,
            capture_output=capture_output,
            text=True,
        )
    except FileNotFoundError:
        print(f"Command not found: {cmd[0]}", file=sys.stderr)
        sys.exit(127)
    except subprocess.CalledProcessError as exc:
        if exc.stdout:
            print(exc.stdout, end="")
        if exc.stderr:
            print(exc.stderr, end="", file=sys.stderr)
        code = exc.returncode if isinstance(exc.returncode, int) else 1
        sys.exit(code)


def docker(*args, capture_output=False, check=True):
    return run(["docker", *args], capture_output=capture_output, check=check)


def ensure_elan_cache(elan_cache: Path, image: str) -> None:
    ensure_dir(elan_cache)
    elan_bin = elan_cache / "bin" / "elan"
    if elan_bin.exists():
        return
    docker(
        "run",
        "--rm",
        "--pull=never",
        "-v",
        f"{os.fspath(elan_cache)}:/elan-cache",
        image,
        "-lc",
        "cp -a /home/lean/.elan/. /elan-cache/",
    )


def parse_bool(value: str) -> bool:
    v = value.strip().lower()
    if v in {"1", "true", "t", "yes", "y", "on"}:
        return True
    if v in {"0", "false", "f", "no", "n", "off"}:
        return False
    raise argparse.ArgumentTypeError(f"Invalid boolean value: {value}")


def read_jsonl(path: Path):
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            yield json.loads(line)
        except json.JSONDecodeError:
            continue

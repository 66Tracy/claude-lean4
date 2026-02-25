import argparse
import os
import sys
from pathlib import Path

from common import docker, ensure_elan_cache, repo_root


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Lean in a fixed Docker image.")
    default_cmd = "lake env lean examples/test.lean"
    parser.add_argument(
        "cmd",
        nargs="?",
        help="Command to run inside the container.",
    )
    parser.add_argument(
        "-Cmd",
        "--cmd",
        dest="cmd_flag",
        default=None,
        help="Command to run inside the container.",
    )
    parser.add_argument(
        "-Image",
        "--image",
        default="leanprovercommunity/lean4:fixed",
        help="Docker image tag.",
    )
    args = parser.parse_args()

    root = repo_root()
    elan_cache = root / ".elan-cache"
    ensure_elan_cache(elan_cache, args.image)

    cmd = args.cmd or args.cmd_flag or default_cmd

    docker(
        "run",
        "--rm",
        "--pull=never",
        "-v",
        f"{os.fspath(root)}:/workspace",
        "-v",
        f"{os.fspath(elan_cache)}:/home/lean/.elan",
        "-w",
        "/workspace",
        args.image,
        "-lc",
        cmd,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

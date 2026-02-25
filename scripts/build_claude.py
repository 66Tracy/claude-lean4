import argparse
import os
import sys
from pathlib import Path

from common import docker, repo_root, resolve_path


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the Claude Docker image.")
    parser.add_argument(
        "-Tag",
        "--tag",
        default="leanprovercommunity/lean4:claude",
        help="Docker image tag.",
    )
    parser.add_argument(
        "-Dockerfile",
        "--dockerfile",
        default="docker/Dockerfile.claude.latest",
        help="Dockerfile path (relative to repo root).",
    )
    args = parser.parse_args()

    root = repo_root()
    dockerfile_path = resolve_path(root, args.dockerfile)
    if not dockerfile_path.exists():
        print(f"Dockerfile not found: {dockerfile_path}", file=sys.stderr)
        return 1

    docker(
        "build",
        "-f",
        os.fspath(dockerfile_path),
        "-t",
        args.tag,
        os.fspath(root),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

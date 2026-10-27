# /// script
# requires-python = ">=3.9"
# dependencies = ["PyYAML==6.0.3"]
#
# [tool.uv]
# required-version = "==0.13.5"
# no-build = true
# ///
"""Provide the command-line entry point for automated NATS chart bumps.

The check command discovers eligible releases and emits workflow outputs. The
update command edits validated YAML fields or previews their diff locally.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Optional

from nats_server_bump_helpers import check_bump, update_chart


def main(argv: Optional[list[str]] = None) -> int:
    """Run the requested bump operation and report expected errors concisely.

    Args:
        argv: CLI arguments, or None to read the process arguments.

    Returns:
        Zero on success, including no-ops, or one on an operational failure.
        Argparse exits with status two for invalid command-line syntax.
    """
    parser = argparse.ArgumentParser(description="Check for or apply a stable NATS server chart bump.")
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser("check", help="Discover the newest stable release and check its image.")
    update = commands.add_parser("update", help="Apply versions selected by check; does not access the network.")
    default_chart = Path(__file__).resolve().parents[2] / "helm" / "charts" / "nats"
    for command in (check, update):
        command.add_argument("--chart-dir", type=Path, default=default_chart, help="Chart directory (default: this repository's helm/charts/nats).")
    update.add_argument("--current", required=True, help="Expected current appVersion in X.Y.Z form.")
    update.add_argument("--latest", required=True, help="Target stable version in X.Y.Z form.")
    update.add_argument("--dry-run", action="store_true", help="Print the proposed YAML diff without writing files.")
    args = parser.parse_args(argv)
    try:
        if args.command == "check":
            outputs = check_bump(args.chart_dir)
            output_text = "".join(f"{key}={value}\n" for key, value in outputs.items())
            output_path = os.environ.get("GITHUB_OUTPUT")
            if output_path:
                with Path(output_path).open("a", encoding="utf-8") as destination:
                    destination.write(output_text)
            print(output_text, end="")
        else:
            update_chart(args.chart_dir, args.current, args.latest, args.dry_run)
    except (ValueError, RuntimeError, OSError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

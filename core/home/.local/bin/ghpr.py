#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///

import argparse
import json
import signal
import subprocess
import sys
import time
from datetime import datetime

interrupted = False


def handle_sigint(signum, frame):
    global interrupted
    if interrupted:
        print("\nCancelled")
        sys.exit(1)
    interrupted = True
    print("\nPress Ctrl+C again to cancel")


def get_pr_checks() -> list[dict]:
    """Returns list of PR checks."""
    for _ in range(10):
        try:
            result = subprocess.run(
                ["gh", "pr", "checks", "--json=name,state,startedAt,completedAt"],
                capture_output=True,
                text=True,
                check=True,
            )
            output = json.loads(result.stdout)
            return [
                {
                    "name": c["name"],
                    "state": c["state"],
                    "duration": dt_diff(c["completedAt"], c["startedAt"]),
                }
                for c in output
            ]
        except subprocess.CalledProcessError as e:
            if "no pull request found" in e.stderr.lower():
                print("No pull request found")
                sys.exit(1)
            time.sleep(1)
        except json.JSONDecodeError:
            time.sleep(1)

    print("Cannot parse gh pr checks output")
    sys.exit(1)


def dt_diff(dt1: str, dt2: str) -> str:
    if not dt1 or not dt2:
        return ""
    return str(datetime.strptime(dt1, "%Y-%m-%dT%H:%M:%SZ") - datetime.strptime(dt2, "%Y-%m-%dT%H:%M:%SZ"))


def monitor_checks() -> bool:
    """Monitor PR checks until all complete. Returns True if all passed."""
    global interrupted
    print("Waiting for checks...", end="", flush=True)

    checks = get_pr_checks()
    while {"IN_PROGRESS", "QUEUED"}.intersection(c["state"] for c in checks):
        time.sleep(3)
        interrupted = False  # reset after each poll
        print(".", end="", flush=True)
        checks = get_pr_checks()

    print("\n")
    all_passed = True
    for c in checks:
        passed = c["state"] == "SUCCESS"
        if not passed:
            all_passed = False
        status = "✓" if passed else "✗"
        duration = f" ({c['duration']})" if c["duration"] else ""
        print(f"{status} {c['name']}: {c['state']}{duration}")

    return all_passed


def create_pr() -> tuple[bool, bool]:
    """Create a PR. Returns (success, already_exists)."""
    result = subprocess.run(["gh", "pr", "create"], stderr=subprocess.PIPE, text=True)
    if result.returncode == 0:
        return True, False
    if "already exists" in result.stderr:
        print("PR already exists")
        return False, True
    print(result.stderr, end="")
    return False, False


def merge_pr() -> bool:
    """Merge the PR with rebase and delete branch."""
    result = subprocess.run(["gh", "pr", "merge", "--rebase", "--delete-branch"])
    return result.returncode == 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a PR and monitor checks")
    parser.add_argument("-m", "--merge", action="store_true", help="Merge PR if all checks pass")
    parser.add_argument("-f", "--force", action="store_true", help="Continue monitoring if PR already exists")
    args = parser.parse_args()

    signal.signal(signal.SIGINT, handle_sigint)

    success, already_exists = create_pr()
    if not success:
        if not (already_exists and args.force):
            return 1

    all_passed = monitor_checks()

    if args.merge:
        if all_passed:
            print("\nMerging PR...")
            if not merge_pr():
                return 1
        else:
            print("\nSkipping merge: checks failed")
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())

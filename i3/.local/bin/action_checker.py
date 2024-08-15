#!/usr/bin/python3
import json.decoder
import time
import subprocess
from typing import TypedDict, List
import json
from datetime import datetime


class Check(TypedDict):
    name: str
    result: str
    duration: str
    url: str


def notification_msg(pr_checks: List[Check]) -> str:
    repository_name = ""
    for check in pr_checks:
        try:  # find repository name
            repository_name = check["url"].split("/")[4]
            break
        except IndexError:
            continue

    return f"\nPR checks finished for {repository_name}\n" + "\n".join(
        [f"{i['name']}: {i['result']}" for i in pr_checks]
    )


def dt_diff(dt1: str, dt2: str) -> str:
    return str(
        datetime.strptime(dt1, "%Y-%m-%dT%H:%M:%SZ")
        - datetime.strptime(dt2, "%Y-%m-%dT%H:%M:%SZ")
    )


def pr_checker() -> List[Check]:
    """Returns list of PR checks."""
    output = subprocess.getoutput(
        ["gh pr checks --json=name,state,link,startedAt,completedAt"]
    )
    for _ in range(0, 10):
        try:
            output = json.loads(output)
            return [
                {
                    "name": c["name"],
                    "result": c["state"],
                    "url": c["link"],
                    "duration": dt_diff(c["completedAt"], c["startedAt"]),
                }
                for c in output
            ]

        except json.decoder.JSONDecodeError:
            time.sleep(1)
            continue

    raise SystemExit(1, "Cannot parse gh pr checks output")


if __name__ == "__main__":
    """Main function."""
    pr_checks = pr_checker()
    while {"IN_PROGRESS", "QUEUED"}.intersection([i["result"] for i in pr_checks]):
        pr_checks = pr_checker()
        time.sleep(3)

    subprocess.call(["notify-send", notification_msg(pr_checks)])
    raise SystemExit(0)

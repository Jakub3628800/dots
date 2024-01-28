#!/usr/bin/python3
import time
import subprocess
from typing import TypedDict, List

class Check(TypedDict):
    name: str
    result: str
    duration: str
    url: str


def notification_msg(pr_checks: List[Check]) -> str:
    """Returns notification message for PR checks."""
    # find repository name
    repository_name = ""
    for check in pr_checks:
        try:
            repository_name = check["url"].split("https://github.com/Jakub3628800/")[1].split("/")[0]
            break
        except IndexError:
            continue

    return f"\nPR checks finished for {repository_name}\n" + "\n".join([f"{i['name']}: {i['result']}" for i in pr_checks])


def pr_checker() -> List[Check]:
    """Returns list of PR checks."""
    output = subprocess.getoutput(["gh pr checks"])
    pr_checks = []
    for check in output.split("\n"):
        name, result, duration, url = check.split("\t")
        pr_checks.append(Check(name=name, result=result, duration=duration, url=url))
    return pr_checks

if __name__ == "__main__":
    """Main function."""
    time.sleep(5) # wait for GH to start running checks
    pr_checks = pr_checker()
    while "pending" in [i["result"] for i in pr_checks]:
        pr_checks = pr_checker()
        time.sleep(3)

    subprocess.call(["notify-send", notification_msg(pr_checks)])
    raise SystemExit(0)

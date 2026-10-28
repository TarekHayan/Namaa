#!/usr/bin/env python3
"""Choose which CI tiers run for this event.

Fast tier (every PR push): quality, Supabase, Android, Linux, Windows, macOS.
Full tier adds the iOS simulator groups. It runs when the PR carries the
`full-ci` label, or for a manual (workflow_dispatch) run. iOS is the slow,
capacity-limited part, so ordinary pushes do not pay for it; the final
five-target gate still requires it before a phase is closed.
"""

import json
import os
import sys

FULL_CI_LABEL = "full-ci"
IOS_GROUPS = ["foundation", "tasks", "habits", "mind-maps", "today"]


def select(env: dict) -> dict:
    event = env.get("EVENT", "")
    action = env.get("ACTION", "")
    if event == "pull_request" and action == "labeled" and env.get("ADDED_LABEL") != FULL_CI_LABEL:
        # Another label was added: nothing changed that CI verifies.
        return {"run": "false", "ios": "false", "ios_groups": json.dumps(IOS_GROUPS[:1])}

    groups: list[str] = []
    if event == "workflow_dispatch":
        if env.get("MOBILE_ONLY") == "true":
            raw = env.get("IOS_GROUPS", "").strip()
            groups = IOS_GROUPS if raw == "" else json.loads(raw)
        else:
            groups = IOS_GROUPS
    elif event == "pull_request" and env.get("HAS_FULL_LABEL") == "true":
        groups = IOS_GROUPS

    if not isinstance(groups, list) or any(g not in IOS_GROUPS for g in groups):
        raise ValueError(f"Unknown iOS groups {groups!r}; expected a subset of {IOS_GROUPS}")
    return {
        "run": "true",
        "ios": "true" if groups else "false",
        # An empty matrix is rejected even for a skipped job, so a skipped
        # iOS job still gets one placeholder group; `ios` decides if it runs.
        "ios_groups": json.dumps(groups or IOS_GROUPS[:1], separators=(",", ":")),
    }


def main() -> int:
    try:
        outputs = select(os.environ)
    except (ValueError, json.JSONDecodeError) as error:
        print(f"::error::{error}", file=sys.stderr)
        return 2
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        for key, value in outputs.items():
            output.write(f"{key}={value}\n")
    if outputs["run"] == "true" and outputs["ios"] == "false":
        print(
            "::notice::Fast tier only. Before closing a phase, add the "
            f"'{FULL_CI_LABEL}' label to the PR (or run the workflow manually) "
            "so the iOS groups and the five-target gate run."
        )
    print(json.dumps(outputs))
    return 0


if __name__ == "__main__":
    sys.exit(main())

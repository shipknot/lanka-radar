"""Per-source run history for status.json, so the app can flag a source that went quiet."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

# A source that fails this many runs in a row fails one run (GitHub emails the
# failure). Later failures are only recorded, so a long outage is one email.
FAILURES_BEFORE_ALERT = 3


def stamp(moment: datetime) -> str:
    return moment.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def record(report: dict[str, Any], source: str, now: datetime, error: str | None) -> None:
    """Updates one source's entry; a success ends its outage."""
    entry = report.setdefault("sources", {}).setdefault(
        source, {"lastRun": None, "lastSuccess": None, "lastError": None, "failures": 0}
    )
    entry["lastRun"] = stamp(now)
    if error is None:
        entry.update(lastSuccess=entry["lastRun"], lastError=None, failures=0)
        entry.pop("alerted", None)
        return
    entry["lastError"] = error[:300]
    entry["failures"] += 1


def take_alerts(report: dict[str, Any]) -> list[str]:
    """The sources whose outage is due its one alert, marked as alerted."""
    due = sorted(
        name
        for name, entry in report.get("sources", {}).items()
        if entry.get("failures", 0) >= FAILURES_BEFORE_ALERT and not entry.get("alerted")
    )
    for name in due:
        report["sources"][name]["alerted"] = True
    return due

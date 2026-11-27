"""Runs the sources against a data branch checkout: `python -m lanka_radar run --data DIR`."""

from __future__ import annotations

import argparse
import sys
from collections.abc import Mapping, Sequence
from datetime import UTC, datetime, timedelta, timezone
from pathlib import Path

from lanka_radar import status
from lanka_radar.sources import SOURCES, Source
from lanka_radar.store import Store
from lanka_radar.web import Web

SRI_LANKA = timezone(timedelta(hours=5, minutes=30), "Asia/Colombo")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="lanka_radar")
    commands = parser.add_subparsers(dest="command", required=True)
    run_command = commands.add_parser("run", help="run the sources and update the data folder")
    run_command.add_argument("--data", type=Path, required=True, help="data branch checkout")
    run_command.add_argument(
        "--source", action="append", choices=sorted(SOURCES), help="run only this source"
    )
    run_command.add_argument(
        "--no-alert",
        dest="alert",
        action="store_false",
        help="never fail the run for an outage; the next run without this flag reports it",
    )
    args = parser.parse_args(argv)
    with Web() as web:
        return run(
            Store(args.data),
            web,
            args.source or sorted(SOURCES),
            datetime.now(UTC),
            alert=args.alert,
        )


def run(
    store: Store,
    web: Web,
    names: Sequence[str],
    now: datetime,
    sources: Mapping[str, Source] = SOURCES,
    alert: bool = True,
) -> int:
    """Runs each source on its own, so one broken site never stops the others.

    The run fails once per outage, when a source has failed FAILURES_BEFORE_ALERT runs in
    a row, so GitHub emails it. With alert off it never fails, and a later run reports it:
    GitHub emails a failure only to whoever started the run, so a run started by GitHub's
    own bot would tell no one.
    """
    report = store.read_status()
    today = now.astimezone(SRI_LANKA).date()
    for name in names:
        try:
            changed = sources[name].run(web, store, today)
        except Exception as error:
            message = f"{type(error).__name__}: {error}"
            print(f"{name}: failed ({message})", file=sys.stderr)
            status.record(report, name, now, message)
        else:
            print(f"{name}: ok, {changed} new or changed items")
            status.record(report, name, now, None)
    # A source that was removed must not look broken forever.
    report["sources"] = {
        name: entry for name, entry in report.get("sources", {}).items() if name in sources
    }
    alerting = status.take_alerts(report) if alert else []
    store.write_latest()
    store.write_months()
    store.write_texts()
    store.write_status(report, now)
    if alerting:
        runs = status.FAILURES_BEFORE_ALERT
        print(f"Failed {runs} or more runs in a row: {', '.join(alerting)}", file=sys.stderr)
        return 1
    return 0

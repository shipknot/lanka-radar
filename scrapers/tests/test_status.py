from datetime import UTC, datetime, timedelta
from typing import Any

from lanka_radar import status

NOW = datetime(2026, 10, 16, 5, 30, tzinfo=UTC)


def fail(report: dict[str, Any], runs: range) -> None:
    for n in runs:
        status.record(report, "fuel", NOW + timedelta(hours=n), "HTTPStatusError: 503")


def test_success_ends_the_outage() -> None:
    report: dict[str, Any] = {}
    fail(report, range(3))
    status.take_alerts(report)

    status.record(report, "fuel", NOW + timedelta(hours=3), None)

    assert report["sources"]["fuel"] == {
        "lastRun": "2026-10-16T08:30:00Z",
        "lastSuccess": "2026-10-16T08:30:00Z",
        "lastError": None,
        "failures": 0,
    }


def test_alerts_once_on_the_third_failure_in_a_row() -> None:
    report: dict[str, Any] = {}

    alerts = []
    for n in range(5):
        status.record(report, "fuel", NOW + timedelta(hours=n), "HTTPStatusError: 503")
        alerts.append(status.take_alerts(report))

    assert alerts == [[], [], ["fuel"], [], []]
    assert report["sources"]["fuel"]["failures"] == 5
    assert report["sources"]["fuel"]["lastSuccess"] is None


def test_an_outage_not_yet_alerted_alerts_late() -> None:
    report: dict[str, Any] = {}
    fail(report, range(4))

    assert status.take_alerts(report) == ["fuel"]
    assert status.take_alerts(report) == []


def test_a_new_outage_alerts_again() -> None:
    report: dict[str, Any] = {}
    fail(report, range(3))
    status.take_alerts(report)
    status.record(report, "fuel", NOW + timedelta(hours=3), None)

    fail(report, range(4, 7))

    assert status.take_alerts(report) == ["fuel"]


def test_long_errors_are_cut() -> None:
    report: dict[str, Any] = {}

    status.record(report, "fuel", NOW, "x" * 1000)

    assert len(report["sources"]["fuel"]["lastError"]) == 300

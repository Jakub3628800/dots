"""Regression tests for the Pomodoro timer."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import io
import os
import sqlite3
import sys
import unittest
from pathlib import Path
from typing import TYPE_CHECKING, Self
from unittest import mock

if TYPE_CHECKING:
    from collections.abc import Callable
    from types import ModuleType
    from typing import TextIO

sys.dont_write_bytecode = True


ROOT = Path(__file__).resolve().parents[1]
BIN_DIR = ROOT / "core" / "home" / ".local" / "bin"


def load_script(name: str, filename: str) -> ModuleType:
    """Import an extensionless utility without executing its entry point."""
    loader = importlib.machinery.SourceFileLoader(name, str(BIN_DIR / filename))
    spec = importlib.util.spec_from_loader(name, loader)
    if spec is None:
        msg = f"could not load {filename}"
        raise RuntimeError(msg)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    loader.exec_module(module)
    return module


pomo = load_script("dots_pomo", "pomo")


class PomoTests(unittest.TestCase):
    """Check database invariants, date filtering, and interactive timer callbacks."""

    def test_timer_argument_spellings_remain_equivalent(self) -> None:
        """Accept long and short options with separate or equals-delimited values."""
        cases = [
            ["--duration", "5", "--tag", "a=b"],
            ["-d", "5", "-t", "a=b"],
            ["--duration=5", "--tag=a=b"],
            ["-d=5", "-t=a=b"],
        ]
        for args in cases:
            with self.subTest(args=args):
                parsed = pomo.parse_timer_args(args)
                self.assertEqual(5, parsed.duration_minutes)
                self.assertEqual(["a=b"], parsed.tags)

    def test_timer_arguments_reject_missing_values(self) -> None:
        """Keep a helpful error for duration and tag flags without values."""
        for flag in ("--duration", "-d", "--tag", "-t"):
            with (
                self.subTest(flag=flag),
                self.assertRaisesRegex(pomo.PomoError, "requires a value"),
            ):
                pomo.parse_timer_args([flag])

    def test_table_identifiers_are_restricted_to_internal_names(self) -> None:
        """Reject arbitrary SQL identifiers in schema introspection and creation."""
        conn = sqlite3.connect(":memory:")
        self.addCleanup(conn.close)
        for operation in (pomo.create_pomodori_table, pomo.table_columns):
            with (
                self.subTest(operation=operation.__name__),
                self.assertRaisesRegex(pomo.PomoError, "unsupported session table"),
            ):
                operation(conn, "unexpected; DROP TABLE config")

    def test_legacy_completed_column_migrates_to_status(self) -> None:
        """Migrate old completion flags using only fixed schema expressions."""
        conn = sqlite3.connect(":memory:")
        self.addCleanup(conn.close)
        conn.row_factory = sqlite3.Row
        conn.execute(
            "CREATE TABLE pomodori "
            "(id INTEGER PRIMARY KEY, start_time TEXT, "
            "end_time TEXT, completed INTEGER)"
        )
        conn.execute(
            "INSERT INTO pomodori VALUES (?, ?, ?, ?)",
            (1, "2026-08-08T09:00:00+02:00", "2026-08-08T09:25:00+02:00", 1),
        )

        pomo.initialize_db(conn)

        row = conn.execute("SELECT * FROM pomodori").fetchone()
        self.assertEqual("completed", row["status"])
        self.assertEqual(25, row["duration_minutes"])
        self.assertEqual(row["start_time"], row["created_at"])
        self.assertIsNone(row["tags"])

    def test_cleanup_recovers_unfinished_legacy_session_without_owner(self) -> None:
        """Allow a new timer after migrating an unfinished session with no PID."""
        conn = sqlite3.connect(":memory:")
        self.addCleanup(conn.close)
        conn.row_factory = sqlite3.Row
        conn.execute(
            "CREATE TABLE pomodori "
            "(id INTEGER PRIMARY KEY, start_time TEXT, "
            "end_time TEXT, completed INTEGER)"
        )
        conn.execute(
            "INSERT INTO pomodori VALUES (?, ?, NULL, 0)",
            (1, "2020-01-01T09:00:00+00:00"),
        )
        pomo.initialize_db(conn)

        pomo.cleanup_stale_running_sessions(conn)

        row = conn.execute("SELECT * FROM pomodori WHERE id = 1").fetchone()
        self.assertEqual("cancelled", row["status"])
        self.assertIsNotNone(row["end_time"])
        self.assertIsNone(pomo.get_active_session(conn))
        pomo.create_running_session(conn, 25, [], pomo.now_local())
        self.assertIsNotNone(pomo.get_active_session(conn))

    def test_cleanup_preserves_live_owner_and_cancels_dead_owner(self) -> None:
        """Keep active timers protected while still recovering dead processes."""
        for running in (True, False):
            with self.subTest(running=running):
                conn = sqlite3.connect(":memory:")
                self.addCleanup(conn.close)
                conn.row_factory = sqlite3.Row
                pomo.initialize_db(conn)
                pomo.create_running_session(conn, 25, [], pomo.now_local())
                with mock.patch.object(
                    pomo, "process_is_running", return_value=running
                ) as process_is_running:
                    pomo.cleanup_stale_running_sessions(conn)
                process_is_running.assert_called_once_with(os.getpid())
                self.assertEqual(running, pomo.get_active_session(conn) is not None)

    def test_database_defaults_are_initialized(self) -> None:
        """Populate default duration and notification settings in a new database."""
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row

        pomo.initialize_db(conn)

        self.assertEqual("25", pomo.get_config(conn, "default_duration_minutes"))
        self.assertEqual("true", pomo.get_config(conn, "notifications_enabled"))

    def test_database_rejects_second_running_session(self) -> None:
        """Reject concurrent running sessions through the database constraint."""
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        pomo.initialize_db(conn)
        started_at = pomo.now_local()

        pomo.create_running_session(conn, 25, [], started_at)

        with self.assertRaisesRegex(pomo.PomoError, "already running"):
            pomo.create_running_session(conn, 25, [], started_at)

    def test_database_migration_cancels_older_running_sessions(self) -> None:
        """Preserve only the latest running session when migrating legacy data."""
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        pomo.create_pomodori_table(conn, "pomodori")
        conn.executemany(
            """
            INSERT INTO pomodori (
                start_time, end_time, duration_minutes, status, tags,
                process_id, created_at
            )
            VALUES (?, NULL, 25, 'running', NULL, ?, ?)
            """,
            [
                ("2026-08-08T09:00:00+02:00", 100, "2026-08-08T09:00:00+02:00"),
                ("2026-08-08T10:00:00+02:00", 200, "2026-08-08T10:00:00+02:00"),
            ],
        )

        pomo.initialize_db(conn)

        rows = conn.execute(
            "SELECT status, process_id FROM pomodori ORDER BY id"
        ).fetchall()
        self.assertEqual(["cancelled", "running"], [row["status"] for row in rows])
        self.assertIsNone(rows[0]["process_id"])
        self.assertEqual(200, rows[1]["process_id"])

    def test_today_uses_equivalent_list_date_range(self) -> None:
        """Translate today's shortcut into an inclusive single-day list range."""
        conn = mock.Mock()
        current_time = pomo.datetime.fromisoformat("2026-07-16T12:00:00+00:00")

        with (
            mock.patch.object(pomo, "now_local", return_value=current_time),
            mock.patch.object(pomo, "run_list_command") as run_list_command,
        ):
            pomo.run_today_command(conn)

        run_list_command.assert_called_once_with(
            conn,
            ["--after", "2026-07-16", "--before", "2026-07-16"],
        )

    def test_today_top_level_flag_runs_today_command(self) -> None:
        """Dispatch --today and close the database when it completes."""
        conn = mock.Mock()
        with (
            mock.patch.object(pomo, "connect", return_value=conn),
            mock.patch.object(pomo, "run_today_command") as run_today_command,
        ):
            self.assertEqual(0, pomo.main(["--today"]))

        run_today_command.assert_called_once_with(conn)
        conn.close.assert_called_once_with()

    def test_timer_uses_elapsed_monotonic_time(self) -> None:
        """Complete the timer based on elapsed time rather than poll counts."""

        class FakeTerminal:
            def __init__(self, _stream: TextIO) -> None:
                pass

            def __enter__(self) -> Self:
                return self

            def __exit__(self, *_args: object) -> None:
                return None

            def read_key(self, _timeout: float) -> None:
                return None

        with (
            mock.patch.object(pomo, "RawTerminal", FakeTerminal),
            mock.patch.object(pomo.time, "monotonic", side_effect=[10.0, 71.0]),
            mock.patch.object(pomo, "render_timer"),
        ):
            self.assertTrue(pomo.run_timer(1))

    def test_timer_runs_pause_and_resume_callbacks(self) -> None:
        """Invoke pause and resume callbacks in response to consecutive p keys."""

        class FakeTerminal:
            def __init__(self, _stream: TextIO) -> None:
                self.keys = iter(["p", "p", "q"])

            def __enter__(self) -> Self:
                return self

            def __exit__(self, *_args: object) -> None:
                return None

            def read_key(self, _timeout: float) -> str:
                return next(self.keys)

        events = []
        with (
            mock.patch.object(pomo, "RawTerminal", FakeTerminal),
            mock.patch.object(pomo.time, "monotonic", return_value=10.0),
            mock.patch.object(pomo, "render_timer"),
        ):
            completed = pomo.run_timer(
                1,
                on_pause=lambda: events.append("pause"),
                on_resume=lambda: events.append("resume"),
            )

        self.assertFalse(completed)
        self.assertEqual(["pause", "resume"], events)

    def test_timer_command_pauses_and_resumes_music(self) -> None:
        """Start, pause, resume, and finally stop music when configured."""
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        pomo.initialize_db(conn)
        pomo.set_config(conn, "music_control_enabled", "true")

        def run_timer(
            _duration: int, on_pause: Callable[[], None], on_resume: Callable[[], None]
        ) -> bool:
            on_pause()
            on_resume()
            return False

        with (
            mock.patch.object(pomo.sys.stdin, "isatty", return_value=True),
            mock.patch.object(pomo, "run_timer", side_effect=run_timer),
            mock.patch.object(pomo, "run_playerctl") as run_playerctl,
            mock.patch("sys.stdout", new=io.StringIO()),
        ):
            pomo.run_timer_command(conn, ["--duration", "1"])

        self.assertEqual(
            [
                mock.call("play"),
                mock.call("pause"),
                mock.call("play"),
                mock.call("stop"),
            ],
            run_playerctl.call_args_list,
        )


if __name__ == "__main__":
    unittest.main()

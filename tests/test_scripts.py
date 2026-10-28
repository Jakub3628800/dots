"""Regression tests for the Pomodoro timer."""

from __future__ import annotations

import errno
import fcntl
import os
import pty
import re
import select
import shutil
import signal
import sqlite3
import struct
import subprocess
import tempfile
import termios
import time
import unittest
from contextlib import closing
from datetime import UTC, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POMO = ROOT / "core/home/.local/bin/pomo"
SQLITE = shutil.which("sqlite3")
ROW = "{:<5} {:<12} {:<10} {:<10} {:<8} {:<32}".format
RULE = "-" * 96
# Larger than any Linux PID, so no process can own it.
DEAD_PID = 2**31 - 1
FRAME = r"\n  \d\d:\d\d\n  \[[#-]+\]\n"


@unittest.skipUnless(SQLITE, "The sqlite3 shell is required")
class PomoTests(unittest.TestCase):
    """Run pomo against a scratch database with logging desktop helpers."""

    def setUp(self) -> None:
        """Create a scratch home and database path, and stub desktop helpers."""
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        self.db = self.home / "data" / "pomo.db"
        self.log = self.home / "helpers.log"
        helpers = self.home / "bin"
        helpers.mkdir()
        for name in ("playerctl", "notify-send"):
            helper = helpers / name
            helper.write_text(f'#!/bin/sh\necho "{name} $*" >>"$POMO_TEST_LOG"\n')
            helper.chmod(0o755)
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "PATH": f"{helpers}:{os.environ['PATH']}",
            "POMO_DB_PATH": str(self.db),
            "POMO_TEST_LOG": str(self.log),
            "TERM": "xterm",
            "TZ": "Europe/Prague",
        }
        self.env.pop("COLUMNS", None)

    def pomo(self, *args: str) -> subprocess.CompletedProcess[str]:
        """Run pomo without a terminal and capture its output."""
        # The script under test runs with fixed arguments and a scratch database.
        return subprocess.run(  # noqa: S603
            [POMO, *args],
            cwd=self.home,
            env=self.env,
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

    def assert_pomo(
        self, args: tuple[str, ...], stdout: str = "", stderr: str = "", code: int = 0
    ) -> None:
        """Check the exit code and both output streams of one command."""
        result = self.pomo(*args)
        self.assertEqual(
            (code, stdout, stderr), (result.returncode, result.stdout, result.stderr)
        )

    def add_sessions(self, *rows: tuple[object, ...]) -> None:
        """Insert sessions after letting pomo create the database."""
        self.assertEqual(0, self.pomo("config").returncode)
        with closing(sqlite3.connect(self.db)) as db, db:
            db.executemany(
                "INSERT INTO pomodori (id, start_time, end_time, duration_minutes,"
                " status, tags, process_id, created_at)"
                " VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                [(*row, row[1]) for row in rows],
            )

    def sessions(self) -> list[sqlite3.Row]:
        """Return every stored session in insertion order."""
        with closing(sqlite3.connect(self.db)) as db:
            db.row_factory = sqlite3.Row
            return db.execute("SELECT * FROM pomodori ORDER BY id").fetchall()

    def start_timer(self, *args: str) -> tuple[subprocess.Popen[bytes], int, int]:
        """Start the timer on a pseudo-terminal; return it with both terminal ends."""
        master, slave = pty.openpty()
        fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
        # The script under test runs with fixed arguments and a scratch database.
        timer = subprocess.Popen(  # noqa: S603
            [POMO, *args],
            env=self.env,
            stdin=slave,
            stdout=slave,
            stderr=slave,
            start_new_session=True,
        )
        self.addCleanup(os.close, master)
        self.addCleanup(os.close, slave)
        self.addCleanup(timer.wait)
        self.addCleanup(timer.kill)
        return timer, master, slave

    def read_until(self, master: int, output: bytearray, pattern: str) -> None:
        """Read terminal output until it matches pattern, within ten seconds."""
        deadline = time.monotonic() + 10
        # The terminal turns each newline into a carriage return and a newline.
        while not re.search(
            pattern, output.decode(errors="replace").replace("\r\n", "\n")
        ):
            remaining = deadline - time.monotonic()
            self.assertGreater(remaining, 0, f"no {pattern!r} in {bytes(output)!r}")
            if select.select([master], [], [], remaining)[0]:
                try:
                    output.extend(os.read(master, 4096))
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise

    def test_help_and_version_do_not_create_the_database(self) -> None:
        """Print help and the version without touching the database."""
        for flag in ("-h", "--help", "help"):
            with self.subTest(flag=flag):
                result = self.pomo(flag)
                self.assertEqual(0, result.returncode)
                self.assertTrue(
                    result.stdout.startswith("pomo - a lean pomodoro timer\n")
                )
        self.assert_pomo(("--version",), "pomo 0.1.0\n")
        self.assertFalse(self.db.parent.exists())

    def test_config_lists_reads_validates_and_updates_settings(self) -> None:
        """Normalize accepted values and reject invalid keys, values and commands."""
        self.assert_pomo(
            ("config",),
            "default_duration_minutes  25        Default timer duration in minutes.\n"
            "music_control_enabled     false     "
            "Run playerctl play/pause/stop during timer sessions.\n"
            "notifications_enabled     true      "
            "Run notify-send when a session completes.\n",
        )
        self.assert_pomo(
            ("config", "set", "default_duration_minutes", " 07 "),
            "default_duration_minutes = 7\n",
        )
        self.assert_pomo(
            ("config", "set", "music_control_enabled", "YES"),
            "music_control_enabled = true\n",
        )
        self.assert_pomo(("config", "get", "default_duration_minutes"), "7\n")
        errors = {
            ("config", "set", "default_duration_minutes", "1441"): (
                "duration must be between 1 and 1440 minutes"
            ),
            ("config", "set", "default_duration_minutes", "1.5"): (
                "duration must be an integer number of minutes"
            ),
            ("config", "set", "notifications_enabled", "maybe"): (
                "boolean config values must be true or false"
            ),
            ("config", "set", "nope", "1"): "unknown config key: nope",
            ("config", "get"): "usage: pomo config get <key>",
            ("config", "list", "extra"): "config list does not accept arguments",
            ("config", "reset"): "unknown config command: reset",
        }
        for args, message in errors.items():
            with self.subTest(args=args):
                self.assert_pomo(args, stderr=f"Error: {message}\n", code=1)

    def test_list_filters_by_local_date_and_formats_the_table(self) -> None:
        """Order sessions newest first and filter on inclusive local dates."""
        # The oldest tag fills its column and ends with a newline, which the
        # table must keep even though the row is printed last.
        newline_tag = "x" * 31 + "\n"
        self.add_sessions(
            (1, "2026-10-07T23:59:59+02:00", None, 25, "completed", "late", None),
            (2, "2026-10-07T22:30:00Z", None, 25, "cancelled", "utc", None),
            (3, "2026-10-08T09:15:00+02:00", None, 50, "completed", "a," * 20, None),
            (4, "2026-06-23T08:41:52+02:00", None, 25, "completed", None, None),
            (5, "2026-01-01T09:00:00+01:00", None, 25, "completed", newline_tag, None),
        )
        rows = {
            1: ROW(1, "2026-10-07", "25m", "completed", "23:59", "late"),
            2: ROW(2, "2026-10-08", "25m", "cancelled", "00:30", "utc"),
            3: ROW(3, "2026-10-08", "50m", "completed", "09:15", "a," * 14 + "a..."),
            4: ROW(4, "2026-06-23", "25m", "completed", "08:41", ""),
            5: ROW(5, "2026-01-01", "25m", "completed", "09:00", newline_tag),
        }

        def table(*ids: int) -> str:
            header = ROW("ID", "Date", "Duration", "Status", "Start", "Tags")
            total = f"Total: {len(ids)} pomodoro sessions"
            return "\n".join([RULE, header, RULE, *map(rows.get, ids), RULE, total, ""])

        self.assert_pomo(("list",), table(3, 2, 1, 4, 5))
        self.assert_pomo(
            ("list", "--after", "2026-10-08", "--before=2026-10-08"), table(3, 2)
        )
        self.assert_pomo(("list", "--before", "2026-10-07"), table(1, 4, 5))
        self.assert_pomo(
            ("list", "--after=2030-01-01"), "No pomodoro sessions recorded yet.\n"
        )
        errors = {
            ("list", "--after", "2026-02-30"): (
                "invalid date '2026-02-30'; expected YYYY-MM-DD"
            ),
            ("list", "--after", "0000-01-01"): (
                "invalid date '0000-01-01'; expected YYYY-MM-DD"
            ),
            ("list", "--before"): "--before requires a value",
            ("list", "--since", "x"): "unknown list argument: --since",
        }
        for args, message in errors.items():
            with self.subTest(args=args):
                self.assert_pomo(args, stderr=f"Error: {message}\n", code=1)

    def test_today_lists_sessions_from_the_local_day(self) -> None:
        """Show sessions started today and leave out older and newer ones."""
        now = datetime.now(UTC)
        self.add_sessions(
            *(
                (number, (now + offset).isoformat(), None, 25, "completed", tag, None)
                for number, offset, tag in (
                    (1, timedelta(), "today"),
                    (2, timedelta(days=-2), "before"),
                    (3, timedelta(days=2), "after"),
                )
            )
        )
        listing = self.pomo("--today").stdout
        self.assertIn(" today ", listing)
        self.assertNotIn("before", listing)
        self.assertNotIn("after", listing)
        self.assertTrue(listing.endswith("Total: 1 pomodoro sessions\n"))

    def test_timer_arguments_are_validated_before_the_timer_starts(self) -> None:
        """Report argument errors in order, before checking for a terminal."""
        errors = {
            ("-d",): "-d requires a value",
            ("--tag",): "--tag requires a value",
            ("-d", "abc", "-h"): "duration must be an integer number of minutes",
            ("--duration=0",): "duration must be between 1 and 1440 minutes",
            ("-x",): "unknown timer argument: -x",
            ("-d", "08", "-t", "x"): "timer requires an interactive terminal",
        }
        for args, message in errors.items():
            with self.subTest(args=args):
                self.assert_pomo(args, stderr=f"Error: {message}\n", code=1)
        result = self.pomo("-d", "5", "--help")
        self.assertEqual(0, result.returncode)
        self.assertTrue(result.stdout.startswith("pomo - a lean pomodoro timer\n"))
        self.assertEqual([], self.sessions())

    def test_durations_need_ascii_digits_in_a_utf8_locale(self) -> None:
        """Reject digit-like characters that a UTF-8 locale's [0-9] range matches."""
        self.env["LC_ALL"] = "en_US.UTF-8"
        if self.pomo("--version").stderr:
            self.skipTest("the en_US.UTF-8 locale is not installed")
        cases = (
            ("-d", "\N{FULLWIDTH DIGIT FIVE}"),
            ("config", "set", "default_duration_minutes", "²"),
        )
        for args in cases:
            with self.subTest(args=args):
                self.assert_pomo(
                    args,
                    stderr="Error: duration must be an integer number of minutes\n",
                    code=1,
                )

    def test_relative_database_path_may_start_with_a_dash(self) -> None:
        """Pass a database path that looks like an option to sqlite3 safely."""
        self.env["POMO_DB_PATH"] = "-pomo.db"
        self.assert_pomo(("config", "get", "notifications_enabled"), "true\n")
        self.assertTrue((self.home / "-pomo.db").is_file())

    def test_new_database_and_directory_are_private(self) -> None:
        """Create the data directory with mode 0700 and the database with 0600."""
        self.assertEqual(0, self.pomo("config").returncode)
        self.assertEqual(0o700, self.db.parent.stat().st_mode & 0o777)
        self.assertEqual(0o600, self.db.stat().st_mode & 0o777)

    def test_existing_default_database_and_directory_become_private(self) -> None:
        """Repair loose modes at the default path, but keep a custom parent's mode."""
        default = self.home / ".local/share/pomo/pomo.db"
        for db in (default, self.db):
            db.parent.mkdir(parents=True)
            db.parent.chmod(0o755)
            db.touch(mode=0o644)
            db.chmod(0o644)
        del self.env["POMO_DB_PATH"]
        self.assertEqual(0, self.pomo("config").returncode)
        self.env["POMO_DB_PATH"] = str(self.db)
        self.assertEqual(0, self.pomo("config").returncode)
        self.assertEqual(0o700, default.parent.stat().st_mode & 0o777)
        self.assertEqual(0o755, self.db.parent.stat().st_mode & 0o777)
        for db in (default, self.db):
            self.assertEqual(0o600, db.stat().st_mode & 0o777)

    def test_cleanup_cancels_dead_owners_and_keeps_live_ones(self) -> None:
        """Cancel a session whose process is gone; let a live one block new timers."""
        self.add_sessions(
            (1, "2026-10-16T07:00:00+02:00", None, 25, "running", None, DEAD_PID)
        )
        self.assertIn(
            ROW(1, "2026-10-16", "25m", "cancelled", "07:00", ""),
            self.pomo("list").stdout,
        )
        (stale,) = self.sessions()
        self.assertEqual(("cancelled", None), (stale["status"], stale["process_id"]))
        self.assertIsNotNone(stale["end_time"])
        self.add_sessions(
            (2, "2026-10-16T08:00:00+02:00", None, 25, "running", None, os.getpid())
        )
        self.assert_pomo(
            ("-d", "5"),
            stderr="Error: a pomodoro is already running since 2026-10-16 08:00:00\n",
            code=1,
        )
        self.assertEqual("running", self.sessions()[1]["status"])

    def test_keys_pause_resume_and_quit_the_timer(self) -> None:
        """Pause and resume music with the timer, then record the cancellation."""
        self.assertEqual(
            0, self.pomo("config", "set", "music_control_enabled", "on").returncode
        )
        timer, master, slave = self.start_timer(
            "-d", "1", "-t", "focus", "--tag=deep work"
        )
        output = bytearray()
        self.read_until(master, output, FRAME)
        (session,) = self.sessions()
        self.assertEqual(
            ("running", timer.pid, "focus,deep work", 1),
            (
                session["status"],
                session["process_id"],
                session["tags"],
                session["duration_minutes"],
            ),
        )
        os.write(master, b"p")
        self.read_until(master, output, r"\d\d:\d\d paused\n")
        os.write(master, b" q")
        self.read_until(master, output, r"\nCancelled\.\n")
        self.assertEqual(0, timer.wait(timeout=10))
        (session,) = self.sessions()
        self.assertEqual(
            ("cancelled", None), (session["status"], session["process_id"])
        )
        self.assertEqual(
            ["playerctl play", "playerctl pause", "playerctl play", "playerctl stop"],
            self.log.read_text().splitlines(),
        )
        modes = termios.tcgetattr(slave)[3]
        self.assertTrue(modes & termios.ICANON and modes & termios.ECHO)

    def test_termination_signal_records_a_cancelled_session(self) -> None:
        """Treat SIGTERM like quitting, so the session does not stay running."""
        timer, master, _ = self.start_timer("-d", "5")
        output = bytearray()
        self.read_until(master, output, FRAME)
        timer.send_signal(signal.SIGTERM)
        self.read_until(master, output, r"\nCancelled\.\n")
        self.assertEqual(0, timer.wait(timeout=10))
        self.assertEqual("cancelled", self.sessions()[0]["status"])


if __name__ == "__main__":
    unittest.main()

"""Regression tests for terminal pickers and the Pomodoro timer."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import io
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import TYPE_CHECKING, Self, override
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


cmd_picker = load_script("dots_cmd_picker", "cmd-picker")
pomo = load_script("dots_pomo", "pomo")


class DummyTool(cmd_picker.Tool):
    """Provide a predictable picker backend without external commands."""

    name = "dummy"
    description = "test tool"

    @override
    def is_available(self) -> bool:
        return True

    @override
    def get_items(self) -> list[dict[str, str]]:
        return []

    @override
    def get_item_display(self, item: dict[str, str], *, selected: bool) -> str:
        return item["name"]

    @override
    def get_item_preview(self, item: dict[str, str]) -> str:
        return item["name"]

    @override
    def execute_action(self, item: dict[str, str]) -> None:
        return None


class CmdPickerTests(unittest.TestCase):
    """Check picker layout and sanitization of untrusted terminal text."""

    def test_selected_item_remains_visible_in_short_terminal(self) -> None:
        """Scroll far enough to show the selection in a short terminal."""
        output = io.StringIO()
        picker = cmd_picker.CmdPicker(DummyTool(), output=output)
        picker.items = [{"name": f"item-{index}"} for index in range(10)]
        picker.selected_index = 9

        picker.display_interface()

        self.assertIn("item-9", output.getvalue())
        self.assertNotIn("item-0", output.getvalue())

    def test_sanitize_terminal_text_removes_control_sequences(self) -> None:
        """Strip color, clipboard, and carriage-return control sequences."""
        text = "before\x1b[31mred\x1b[0m\x1b]52;c;secret\x07after\r\n"

        self.assertEqual("beforeredafter\n", cmd_picker.sanitize_terminal_text(text))

    def test_sanitize_terminal_text_preserves_osc_hyperlink_labels_and_suffixes(
        self,
    ) -> None:
        """Keep visible labels for every supported OSC delimiter pair."""
        for opener in ("\x1b]", "\x9d"):
            for terminator in ("\x07", "\x1b\\", "\x9c"):
                with self.subTest(opener=repr(opener), terminator=repr(terminator)):
                    text = (
                        f"before{opener}8;;https://example.com{terminator}"
                        f"label{opener}8;;{terminator}after\nnext line"
                    )
                    self.assertEqual(
                        "beforelabelafter\nnext line",
                        cmd_picker.sanitize_terminal_text(text),
                    )

    def test_sanitize_terminal_text_removes_unterminated_osc(self) -> None:
        """Discard unterminated OSC payloads instead of displaying them."""
        for opener in ("\x1b]", "\x9d"):
            with self.subTest(opener=repr(opener)):
                self.assertEqual(
                    "before",
                    cmd_picker.sanitize_terminal_text(f"before{opener}52;c;secret"),
                )

    def test_tmux_display_sanitizes_session_metadata(self) -> None:
        """Sanitize both session names and window counts before rendering."""
        display = cmd_picker.TmuxTool().get_item_display(
            {"name": "session\x1b[31m", "windows": "1\x1b]52;c;secret\x07"},
            selected=False,
        )

        self.assertNotIn("\x1b[31m", display)
        self.assertNotIn("\x1b]52", display)
        self.assertIn("session", display)
        self.assertIn("1", display)


class BackendCommandTests(unittest.TestCase):
    """Check subprocess boundaries and backend success and failure paths."""

    def test_tmux_action_passes_literal_arguments_and_explicit_status_policy(
        self,
    ) -> None:
        """Resolve tmux and avoid shell interpretation of session metadata."""
        name = "session; echo unexpected"
        with (
            mock.patch.object(cmd_picker.shutil, "which", return_value="/usr/bin/tmux"),
            mock.patch.object(cmd_picker.subprocess, "run") as run,
        ):
            cmd_picker.TmuxTool().execute_action({"name": name})
        run.assert_called_once_with(
            ["/usr/bin/tmux", "attach-session", "-t", name],
            shell=False,
            cwd=None,
            capture_output=False,
            text=True,
            check=False,
        )

    def test_missing_executable_does_not_start_a_process(self) -> None:
        """Report an unavailable backend before attempting process creation."""
        with (
            mock.patch.object(cmd_picker.shutil, "which", return_value=None),
            mock.patch.object(cmd_picker.subprocess, "run") as run,
            self.assertRaisesRegex(FileNotFoundError, "executable not found: tmux"),
        ):
            cmd_picker.TmuxTool().execute_action({"name": "session"})
        run.assert_not_called()

    def test_backend_lists_skip_malformed_rows(self) -> None:
        """Keep valid tmux and Docker records while ignoring short rows."""
        cases = [
            (cmd_picker.TmuxTool(), "short\nsession\t2\t123\n", "session"),
            (
                cmd_picker.DockerTool(),
                "short\nabc\tcontainer\tUp\timage\n",
                "container",
            ),
            (cmd_picker.GhTool(), '[{"name": "pull request"}]', "pull request"),
        ]
        for tool, output, name in cases:
            with (
                self.subTest(tool=tool.name),
                mock.patch.object(cmd_picker.shutil, "which", return_value="/bin/tool"),
                mock.patch.object(
                    cmd_picker.subprocess, "run", return_value=mock.Mock(stdout=output)
                ),
            ):
                items = tool.get_items()
                self.assertEqual([name], [item["name"] for item in items])

    def test_backend_lists_report_command_failures_as_empty(self) -> None:
        """Preserve empty-list fallbacks when external commands fail."""
        for tool in (
            cmd_picker.TmuxTool(),
            cmd_picker.DockerTool(),
            cmd_picker.GhTool(),
        ):
            with (
                self.subTest(tool=tool.name),
                mock.patch.object(cmd_picker.shutil, "which", return_value="/bin/tool"),
                mock.patch.object(
                    cmd_picker.subprocess,
                    "run",
                    side_effect=subprocess.CalledProcessError(1, "tool"),
                ),
            ):
                self.assertEqual([], tool.get_items())

    def test_confirmed_actions_refresh_only_after_success(self) -> None:
        """Request refreshed items only after successful delete, toggle, or merge."""
        cases = [
            (cmd_picker.TmuxTool(), "d", {"name": "session"}),
            (cmd_picker.DockerTool(), "s", {"id": "abc", "status": "Up"}),
            (cmd_picker.GhTool(), "m", {"number": 1}),
        ]
        for tool, key, item in cases:
            for failure in (None, subprocess.CalledProcessError(1, "tool")):
                with (
                    self.subTest(tool=tool.name, failed=failure is not None),
                    mock.patch.object(
                        cmd_picker.shutil, "which", return_value="/bin/tool"
                    ),
                    mock.patch.object(
                        cmd_picker.subprocess, "run", side_effect=failure
                    ),
                    mock.patch.object(cmd_picker.sys, "stdin", io.StringIO("y")),
                    mock.patch("sys.stdout", new=io.StringIO()),
                ):
                    self.assertEqual(
                        failure is None, tool.handle_additional_action(key, item)
                    )

    def test_tmux_creation_refreshes_only_after_success(self) -> None:
        """Preserve create-session success and error results after try cleanup."""
        for failure in (None, subprocess.CalledProcessError(1, "tmux")):
            with (
                self.subTest(failed=failure is not None),
                mock.patch.object(cmd_picker.shutil, "which", return_value="/bin/tmux"),
                mock.patch.object(cmd_picker.subprocess, "run", side_effect=failure),
                mock.patch("builtins.input", return_value="session"),
                mock.patch("sys.stdout", new=io.StringIO()),
            ):
                self.assertEqual(
                    failure is None, cmd_picker.TmuxTool().create_new_item()
                )


class WorktreePickerTests(unittest.TestCase):
    """Exercise worktree selection with real temporary Git repositories."""

    def setUp(self) -> None:
        """Create two worktrees, then remove one after collecting its metadata."""
        # Commit hooks export Git variables (notably GIT_INDEX_FILE) that must
        # not leak into our temporary repositories or preview subprocesses.
        environment = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        environment.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        self.enterContext(mock.patch.dict(os.environ, environment, clear=True))
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name) / "repo"
        root.mkdir()
        worktree = Path(temporary.name) / "worktree"

        git_executable = shutil.which("git")
        if git_executable is None:
            self.skipTest("Git is required")

        def git(*args: str) -> None:
            # Fixture arguments are passed directly to Git, never through a shell.
            subprocess.run(  # noqa: S603
                [
                    str(git_executable),
                    "-C",
                    str(root),
                    "-c",
                    "core.hooksPath=/dev/null",
                    "-c",
                    "commit.gpgsign=false",
                    "-c",
                    "user.name=Test",
                    "-c",
                    "user.email=test@example.com",
                    *args,
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        git("init", "-b", "main")
        git("commit", "--allow-empty", "-m", "initial")
        git("worktree", "add", "-b", "other", str(worktree))
        self.tool = cmd_picker.WorktreeTool()
        with mock.patch.object(self.tool, "_repo_root", return_value=str(root)):
            self.existing, self.missing = self.tool.get_items()
        # Simulate deletion after the picker has already listed the directory.
        shutil.rmtree(worktree)
        with mock.patch.object(self.tool, "_repo_root", return_value=str(root)):
            self.assertTrue(self.tool.get_items()[1]["prunable"])

    def test_missing_worktree_preview_explains_disabled_actions(self) -> None:
        """Explain unavailable actions without trying to run Git in a missing path."""
        with mock.patch.object(self.tool, "_git") as git:
            preview = self.tool.get_item_preview(self.missing)
        self.assertIn("directory is unavailable", preview)
        self.assertIn("actions are disabled", preview)
        git.assert_not_called()

    def test_missing_worktree_actions_do_not_start_processes(self) -> None:
        """Prevent shell, editor, and tmux actions for removed worktrees."""
        with mock.patch.object(cmd_picker.subprocess, "run") as run:
            self.tool.execute_action(self.missing)
            for key in ("e", "t"):
                self.assertFalse(self.tool.handle_additional_action(key, self.missing))
        run.assert_not_called()

    def test_enter_skips_missing_worktree_in_shell_and_print_path_modes(self) -> None:
        """Ignore Enter on an unavailable entry in both selection modes."""
        for execute_on_select in (True, False):
            with self.subTest(execute_on_select=execute_on_select):
                picker = cmd_picker.CmdPicker(
                    self.tool, output=io.StringIO(), execute_on_select=execute_on_select
                )
                with (
                    mock.patch.object(
                        self.tool,
                        "get_items",
                        return_value=[self.missing, self.existing],
                    ),
                    mock.patch.object(self.tool, "execute_action") as execute,
                    mock.patch.object(picker, "get_key", side_effect=["\r", "j", "\r"]),
                ):
                    self.assertEqual(self.existing, picker.run())
                if execute_on_select:
                    execute.assert_called_once_with(self.existing)
                else:
                    execute.assert_not_called()

    def test_preview_handles_directory_disappearing_during_git_commands(self) -> None:
        """Report unavailable previews if a directory disappears during collection."""
        with mock.patch.object(self.tool, "_git", side_effect=FileNotFoundError):
            preview = self.tool.get_item_preview(self.existing)
        self.assertIn("Unable to read status", preview)
        self.assertIn("Unable to read commits", preview)

    def test_existing_worktree_preview_still_works(self) -> None:
        """Show branch and commit information for the remaining worktree."""
        preview = self.tool.get_item_preview(self.existing)
        self.assertIn("main", preview)
        self.assertIn("initial", preview)
        self.assertTrue(self.tool.is_selectable(self.existing))


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

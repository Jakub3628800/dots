import importlib.machinery
import importlib.util
import io
import sqlite3
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.dont_write_bytecode = True


ROOT = Path(__file__).resolve().parents[1]
BIN_DIR = ROOT / "core" / "home" / ".local" / "bin"


def load_script(name: str, filename: str):
    loader = importlib.machinery.SourceFileLoader(name, str(BIN_DIR / filename))
    spec = importlib.util.spec_from_loader(name, loader)
    if spec is None:
        raise RuntimeError(f"could not load {filename}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    loader.exec_module(module)
    return module


cmd_picker = load_script("dots_cmd_picker", "cmd-picker")
pomo = load_script("dots_pomo", "pomo")


class DummyTool(cmd_picker.Tool):
    name = "dummy"
    description = "test tool"

    def is_available(self):
        return True

    def get_items(self):
        return []

    def get_item_display(self, item, selected):
        return item["name"]

    def get_item_preview(self, item):
        return item["name"]

    def execute_action(self, item):
        return None


class CmdPickerTests(unittest.TestCase):
    def test_selected_item_remains_visible_in_short_terminal(self):
        output = io.StringIO()
        picker = cmd_picker.CmdPicker(DummyTool(), output=output)
        picker.items = [{"name": f"item-{index}"} for index in range(10)]
        picker.selected_index = 9

        picker.display_interface()

        self.assertIn("item-9", output.getvalue())
        self.assertNotIn("item-0", output.getvalue())

    def test_sanitize_terminal_text_removes_control_sequences(self):
        text = "before\x1b[31mred\x1b[0m\x1b]52;c;secret\x07after\r\n"

        self.assertEqual("beforeredafter\n", cmd_picker.sanitize_terminal_text(text))

    def test_tmux_display_sanitizes_session_metadata(self):
        display = cmd_picker.TmuxTool().get_item_display(
            {"name": "session\x1b[31m", "windows": "1\x1b]52;c;secret\x07"}, selected=False
        )

        self.assertNotIn("\x1b[31m", display)
        self.assertNotIn("\x1b]52", display)
        self.assertIn("session", display)
        self.assertIn("1", display)


class PomoTests(unittest.TestCase):
    def test_database_defaults_are_initialized(self):
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row

        pomo.initialize_db(conn)

        self.assertEqual("25", pomo.get_config(conn, "default_duration_minutes"))
        self.assertEqual("true", pomo.get_config(conn, "notifications_enabled"))

    def test_database_rejects_second_running_session(self):
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        pomo.initialize_db(conn)
        started_at = pomo.now_local()

        pomo.create_running_session(conn, 25, [], started_at)

        with self.assertRaisesRegex(pomo.PomoError, "already running"):
            pomo.create_running_session(conn, 25, [], started_at)

    def test_database_migration_cancels_older_running_sessions(self):
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        pomo.create_pomodori_table(conn, "pomodori")
        conn.executemany(
            """
            INSERT INTO pomodori (
                start_time, end_time, duration_minutes, status, tags, process_id, created_at
            )
            VALUES (?, NULL, 25, 'running', NULL, ?, ?)
            """,
            [
                ("2026-08-08T09:00:00+02:00", 100, "2026-08-08T09:00:00+02:00"),
                ("2026-08-08T10:00:00+02:00", 200, "2026-08-08T10:00:00+02:00"),
            ],
        )

        pomo.initialize_db(conn)

        rows = conn.execute("SELECT status, process_id FROM pomodori ORDER BY id").fetchall()
        self.assertEqual(["cancelled", "running"], [row["status"] for row in rows])
        self.assertIsNone(rows[0]["process_id"])
        self.assertEqual(200, rows[1]["process_id"])

    def test_today_uses_equivalent_list_date_range(self):
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

    def test_today_top_level_flag_runs_today_command(self):
        conn = mock.Mock()
        with (
            mock.patch.object(pomo, "connect", return_value=conn),
            mock.patch.object(pomo, "run_today_command") as run_today_command,
        ):
            self.assertEqual(0, pomo.main(["--today"]))

        run_today_command.assert_called_once_with(conn)
        conn.close.assert_called_once_with()

    def test_timer_uses_elapsed_monotonic_time(self):
        class FakeTerminal:
            def __init__(self, _stream):
                pass

            def __enter__(self):
                return self

            def __exit__(self, *_args):
                return None

            def read_key(self, _timeout):
                return None

        with (
            mock.patch.object(pomo, "RawTerminal", FakeTerminal),
            mock.patch.object(pomo.time, "monotonic", side_effect=[10.0, 71.0]),
            mock.patch.object(pomo, "render_timer"),
        ):
            self.assertTrue(pomo.run_timer(1))

    def test_timer_runs_pause_and_resume_callbacks(self):
        class FakeTerminal:
            def __init__(self, _stream):
                self.keys = iter(["p", "p", "q"])

            def __enter__(self):
                return self

            def __exit__(self, *_args):
                return None

            def read_key(self, _timeout):
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

    def test_timer_command_pauses_and_resumes_music(self):
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        pomo.initialize_db(conn)
        pomo.set_config(conn, "music_control_enabled", "true")

        def run_timer(_duration, on_pause, on_resume):
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

import importlib.machinery
import importlib.util
import io
import sqlite3
import subprocess
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
tt = load_script("dots_tt", "tt")


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


class PomoTests(unittest.TestCase):
    def test_database_defaults_are_initialized(self):
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row

        pomo.initialize_db(conn)

        self.assertEqual("25", pomo.get_config(conn, "default_duration_minutes"))
        self.assertEqual("true", pomo.get_config(conn, "notifications_enabled"))

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


class TtTests(unittest.TestCase):
    def test_repo_file_listing_handles_spaces(self):
        result = subprocess.CompletedProcess([], 0, "src/a file.py\0tests/test_a file.py\0", "")
        with mock.patch.object(tt.subprocess, "run", return_value=result):
            self.assertEqual(["src/a file.py", "tests/test_a file.py"], tt.list_repo_files())

    def test_source_maps_to_closest_matching_test(self):
        index = {
            "client": [
                "tests/api/test_client.py",
                "tests/unit/test_client.py",
            ]
        }

        mapped = tt.find_test_for_source("src/api/client.py", "", index)

        self.assertEqual("tests/api/test_client.py", mapped)


if __name__ == "__main__":
    unittest.main()

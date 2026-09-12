"""Check Make orchestration without installing packages or changing dotfiles."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAKE = shutil.which("make")


@unittest.skipUnless(MAKE, "Make is required")
class MakeOrderingTests(unittest.TestCase):
    """Keep component recipes and recursive orchestration serial under make -j."""

    def test_parallel_flag_does_not_overlap_install_recipes(self) -> None:
        """Replace side effects with event logging and exercise real dependencies."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            log = root / "events"
            shutil.copyfile(ROOT / "Makefile", root / "Makefile")
            targets = {
                "core": (
                    "apt-update",
                    "apt-packages",
                    "rust-toolchain",
                    "cargo-packages",
                    "stow",
                ),
                "desktop": ("packages", "stow"),
                "nvim": ("install-nvim", "stow"),
            }
            for component, names in targets.items():
                directory = root / component
                directory.mkdir()
                source = (ROOT / component / "Makefile").read_text()
                for name in names:
                    event = f"{component}-{name}"
                    source += (
                        f"\n{name}:\n"
                        f"\t@echo start-{event} >> '$(EVENT_LOG)'\n"
                        "\t@sleep 0.02\n"
                        f"\t@echo end-{event} >> '$(EVENT_LOG)'\n"
                    )
                (directory / "Makefile").write_text(source)

            env = dict(os.environ)
            for key in ("MAKEFLAGS", "MFLAGS", "MAKEOVERRIDES", "MAKELEVEL"):
                env.pop(key, None)
            for component in (".", *targets):
                with self.subTest(component=component):
                    log.write_text("")
                    # Only temporary Makefiles with inert recipe overrides run.
                    result = subprocess.run(  # noqa: S603
                        [
                            str(MAKE),
                            "-C",
                            str(root / component),
                            "-j8",
                            "install",
                            "upgrade",
                            f"EVENT_LOG={log}",
                        ],
                        env=env,
                        capture_output=True,
                        text=True,
                        check=False,
                        timeout=15,
                    )
                    self.assertEqual(0, result.returncode, result.stderr)
                    events = log.read_text().splitlines()
                    self.assertTrue(events)
                    self.assertEqual(0, len(events) % 2)
                    for start, end in zip(events[::2], events[1::2], strict=True):
                        self.assertTrue(start.startswith("start-"))
                        self.assertEqual(start.replace("start-", "end-", 1), end)
                    components = targets if component == "." else [component]
                    for name in components:
                        prerequisite = (
                            "install-nvim" if name == "nvim" else targets[name][-2]
                        )
                        self.assertLess(
                            events.index(f"end-{name}-{prerequisite}"),
                            events.index(f"start-{name}-stow"),
                        )


if __name__ == "__main__":
    unittest.main()

"""Exercise the isolated Neovim configuration test target."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PINNED_NVIM = Path("/opt/nvim-linux64/bin/nvim")
NVIM = str(PINNED_NVIM) if PINNED_NVIM.is_file() else shutil.which("nvim")
MAKE = shutil.which("make")


@unittest.skipUnless(NVIM and MAKE, "Neovim and make are required")
class NeovimConfigTestTests(unittest.TestCase):
    """Check success and failure reporting without loading the user's config."""

    def setUp(self) -> None:
        """Create a checkout and unrelated user config in a temporary directory."""
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        self.component = root / "nvim checkout"
        self.config = self.component / "home/.config/nvim"
        (self.config / "lua/plugins").mkdir(parents=True)
        for name in ("Makefile", "test-config.lua", "run-test.sh"):
            shutil.copyfile(ROOT / "nvim" / name, self.component / name)
        (self.config / "lua/plugins/fixture.lua").write_text(
            "return 'checkout module'\n"
        )

        # A user's unrelated config must not supply modules to this test.
        user_config = root / "user-config/nvim/lua/plugins"
        user_config.mkdir(parents=True)
        (user_config / "fixture.lua").write_text("error('loaded user config')\n")
        self.env = dict(
            os.environ,
            HOME=str(root / "home"),
            XDG_CONFIG_HOME=str(root / "user-config"),
            XDG_DATA_HOME=str(root / "data"),
            XDG_STATE_HOME=str(root / "state"),
            XDG_CACHE_HOME=str(root / "cache"),
            NVIM_APPNAME="unrelated-app",
        )
        for name in ("MAKEFLAGS", "MFLAGS", "MAKEOVERRIDES", "VIMINIT", "EXINIT"):
            self.env.pop(name, None)

    def check_config(
        self, source: str, *, target: str = "test"
    ) -> subprocess.CompletedProcess[str]:
        """Run the component target against the supplied Lua fixture."""
        (self.config / "init.lua").write_text(source)
        # Only the isolated fixture and the installed Make executable are invoked.
        return subprocess.run(  # noqa: S603
            [str(MAKE), "-C", str(self.component), target, f"NVIM={NVIM}"],
            check=False,
            env=self.env,
            capture_output=True,
            text=True,
            timeout=15,
        )

    def test_valid_config_uses_checkout_modules_without_stow(self) -> None:
        """Load checkout modules with plugins enabled and allow info messages."""
        result = self.check_config(
            "assert(require('plugins.fixture') == 'checkout module')\n"
            "assert(vim.o.loadplugins, 'plugin loading must be enabled')\n"
            "vim.notify('informational message', vim.log.levels.INFO)\n"
        )
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_all_user_state_is_disposable_and_seed_is_read_only(self) -> None:
        """Protect user and seed files; clean scratch paths on success or error."""
        report = self.component / "paths"
        self.env["TEST_PATH_REPORT"] = str(report)
        seed = self.component / ".test-data/data/nvim/seed"
        seed.parent.mkdir(parents=True)
        seed.write_text("original\n")
        source = (
            "local paths = { vim.env.HOME }\n"
            "for _, name in ipairs({'config', 'data', 'state', 'cache'}) do\n"
            "  table.insert(paths, vim.fn.stdpath(name))\n"
            "end\n"
            "vim.fn.writefile(paths, vim.env.TEST_PATH_REPORT)\n"
            "for _, path in ipairs(paths) do\n"
            "  vim.fn.mkdir(path, 'p')\n"
            "  assert(vim.fn.filereadable(path .. '/marker') == 0)\n"
            "  vim.fn.writefile({'test'}, path .. '/marker')\n"
            "end\n"
            "local seed = vim.fn.stdpath('data') .. '/seed'\n"
            "assert(vim.fn.readfile(seed)[1] == 'original')\n"
            "vim.fn.writefile({'modified'}, seed)\n"
        )
        for fail in (False, True):
            with self.subTest(fail=fail):
                fixture = source + ("error('intentional failure')\n" if fail else "")
                result = self.check_config(fixture)
                self.assertEqual(fail, result.returncode != 0, result.stderr)
                for path in report.read_text().splitlines():
                    self.assertFalse(Path(path).exists(), path)
                self.assertEqual("original\n", seed.read_text())
                self.assertEqual(fixture, (self.config / "init.lua").read_text())
                self.assertFalse((self.config / "marker").exists())
                for name in (
                    "HOME",
                    "XDG_DATA_HOME",
                    "XDG_STATE_HOME",
                    "XDG_CACHE_HOME",
                ):
                    self.assertFalse(Path(self.env[name]).exists())

    def test_locked_config_requires_fresh_explicit_preparation(self) -> None:
        """Reject absent or stale test data instead of downloading during checks."""
        (self.config / "lazy-lock.json").write_text("{}\n")
        source = "assert(vim.o.loadplugins)\n"
        missing = self.check_config(source)
        self.assertNotEqual(0, missing.returncode)
        self.assertIn("prepare-test", missing.stderr)
        prepared = self.check_config(source, target="prepare-test")
        self.assertEqual(0, prepared.returncode, prepared.stderr)
        valid = self.check_config(source)
        self.assertEqual(0, valid.returncode, valid.stderr)
        stale = self.check_config(source + "-- changed config\n")
        self.assertNotEqual(0, stale.returncode)
        self.assertIn("stale", stale.stderr)

    def test_preparation_waits_for_scheduled_parser_builds(self) -> None:
        """Do not publish test data until a delayed parser build has completed."""
        result = self.check_config(
            "local directory = vim.fn.stdpath('data') .. '/parser'\n"
            "package.loaded['nvim-treesitter.configs'] = {\n"
            "  get_ensure_installed_parsers = function() return {'fixture'} end,\n"
            "  get_parser_install_dir = function() return directory end,\n"
            "}\n"
            "vim.defer_fn(function()\n"
            "  vim.fn.mkdir(directory, 'p')\n"
            "  vim.fn.writefile({'built'}, directory .. '/fixture.so')\n"
            "end, 300)\n",
            target="prepare-test",
        )
        self.assertEqual(0, result.returncode, result.stderr)
        parser = self.component / ".test-data/data/nvim/parser/fixture.so"
        self.assertEqual("built\n", parser.read_text())

    def test_early_successful_exit_cannot_bypass_checks(self) -> None:
        """Reject a plugin exiting with code zero before the runner completes."""
        result = self.check_config("vim.cmd('qa!')\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("before completing", result.stderr)

    def test_broken_runner_fails_without_waiting_for_timeout(self) -> None:
        """Surface runner syntax errors through the guarded headless entry point."""
        (self.component / "test-config.lua").write_text("local = invalid syntax\n")
        result = self.check_config("-- valid config\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("test-config.lua", result.stderr)

    def test_code_block_selection_matches_complete_fence_pairs(self) -> None:
        """Reject prose and unclosed fences without loading plugins or using tmux."""
        shutil.copyfile(
            ROOT / "nvim/home/.config/nvim/lua/code-block.lua",
            self.config / "lua/code-block.lua",
        )
        result = self.check_config((ROOT / "nvim/test-code-blocks.lua").read_text())
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_suppressed_command_error_does_not_fail_valid_config(self) -> None:
        """Honor explicit error suppression in a valid configuration."""
        result = self.check_config("vim.cmd('silent! autocmd! MissingTestGroup *')\n")
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_runtime_error_fails_make(self) -> None:
        """Propagate a synchronous Lua error to Make."""
        result = self.check_config("error('intentional runtime failure')\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("intentional runtime failure", result.stderr)

    def test_syntax_error_fails_make(self) -> None:
        """Report the offending file when Lua parsing fails."""
        result = self.check_config("local = invalid syntax\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("init.lua", result.stderr)

    def test_missing_module_fails_make(self) -> None:
        """Reject a configuration that requires an unavailable module."""
        result = self.check_config("require('plugins.does_not_exist')\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("plugins.does_not_exist", result.stderr)

    def test_error_notification_fails_make(self) -> None:
        """Treat error-level notifications as configuration failures."""
        result = self.check_config(
            "vim.notify('plugin configuration failed', vim.log.levels.ERROR)\n"
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("plugin configuration failed", result.stderr)

    def test_scheduled_error_notification_fails_make(self) -> None:
        """Wait for scheduled error notifications before reporting success."""
        result = self.check_config(
            "vim.schedule(function()\n"
            "  vim.notify('scheduled plugin failure', vim.log.levels.ERROR)\n"
            "end)\n"
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("scheduled plugin failure", result.stderr)

    def test_scheduled_error_fails_make(self) -> None:
        """Propagate an error raised by a scheduled callback."""
        result = self.check_config(
            "vim.schedule(function() error('scheduled startup failure') end)\n"
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("scheduled startup failure", result.stderr)


if __name__ == "__main__":
    unittest.main()

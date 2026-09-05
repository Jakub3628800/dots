import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PINNED_NVIM = Path("/opt/nvim-linux64/bin/nvim")
NVIM = str(PINNED_NVIM) if PINNED_NVIM.is_file() else shutil.which("nvim")


@unittest.skipUnless(NVIM and shutil.which("make"), "Neovim and make are required")
class NeovimConfigTestTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        self.component = root / "nvim checkout"
        self.config = self.component / "home/.config/nvim"
        (self.config / "lua/plugins").mkdir(parents=True)
        for name in ("Makefile", "test-config.lua"):
            shutil.copyfile(ROOT / "nvim" / name, self.component / name)
        (self.config / "lua/plugins/fixture.lua").write_text("return 'checkout module'\n")

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

    def check_config(self, source):
        (self.config / "init.lua").write_text(source)
        return subprocess.run(
            ["make", "-C", str(self.component), "test", f"NVIM={NVIM}"],
            env=self.env, capture_output=True, text=True, timeout=15,
        )

    def test_valid_config_uses_checkout_modules_without_stow(self):
        result = self.check_config(
            "assert(require('plugins.fixture') == 'checkout module')\n"
            "assert(vim.o.loadplugins, 'plugin loading must be enabled')\n"
            "vim.notify('informational message', vim.log.levels.INFO)\n"
        )
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_suppressed_command_error_does_not_fail_valid_config(self):
        result = self.check_config("vim.cmd('silent! autocmd! MissingTestGroup *')\n")
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_runtime_error_fails_make(self):
        result = self.check_config("error('intentional runtime failure')\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("intentional runtime failure", result.stderr)

    def test_syntax_error_fails_make(self):
        result = self.check_config("local = invalid syntax\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("init.lua", result.stderr)

    def test_missing_module_fails_make(self):
        result = self.check_config("require('plugins.does_not_exist')\n")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("plugins.does_not_exist", result.stderr)

    def test_error_notification_fails_make(self):
        result = self.check_config(
            "vim.notify('plugin configuration failed', vim.log.levels.ERROR)\n"
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("plugin configuration failed", result.stderr)

    def test_scheduled_error_notification_fails_make(self):
        result = self.check_config(
            "vim.schedule(function()\n"
            "  vim.notify('scheduled plugin failure', vim.log.levels.ERROR)\n"
            "end)\n"
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("scheduled plugin failure", result.stderr)

    def test_scheduled_error_fails_make(self):
        result = self.check_config(
            "vim.schedule(function() error('scheduled startup failure') end)\n"
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("scheduled startup failure", result.stderr)


if __name__ == "__main__":
    unittest.main()

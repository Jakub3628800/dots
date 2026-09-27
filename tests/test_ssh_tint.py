"""Exercise SSH tinting without opening any network connections."""

from __future__ import annotations

import errno
import os
import pty
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TINT = ROOT / "core/home/.config/zsh/ssh-tint.zsh"
ZSH = shutil.which("zsh")
SSH = shutil.which("ssh")
KEYGEN = shutil.which("ssh-keygen")


@unittest.skipUnless(ZSH and SSH and KEYGEN, "Zsh and OpenSSH required")
class SshTintTests(unittest.TestCase):
    """Resolve real SSH configuration and intercept the connection command."""

    def setUp(self) -> None:
        """Create an isolated configuration, saved keys, and fake SSH client."""
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        self.known = self.home / "known_hosts"
        self.known.write_text(
            "server.example ssh-rsa AAAArsa\n"
            "server.example ssh-ed25519 AAAAfirst\n"
            "[server.example]:2222 ssh-ed25519 AAAAfirst\n"
            "key-alias ssh-ed25519 AAAAfirst\n"
            "other.example ssh-ed25519 AAAAsecond\n",
        )
        self.config = self.home / "config"
        self.config.write_text(
            "Host nickname\n  HostName server.example\n"
            "Host custom-port\n  HostName server.example\n  Port 2222\n"
            "Host aliased-key\n  HostName ignored.example\n"
            "  HostKeyAlias key-alias\n  Port 2222\n"
            f"Host *\n  UserKnownHostsFile {self.known}\n"
            "  GlobalKnownHostsFile none\n",
        )
        binary = self.home / "ssh"
        binary.write_text(
            '#!/bin/sh\nif [ "$1" = -G ]; then\n'
            f'  exec {SSH} "$@"\nfi\n'
            "printf 'ssh'\nprintf '<%s>' \"$@\"\nprintf '\\n'\n"
            'if [ "${SSH_TEST_INTERRUPT:-0}" = 1 ]; then kill -INT $$; fi\n'
            'exit "${SSH_TEST_RC:-0}"\n',
        )
        binary.chmod(0o755)
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "PATH": f"{self.home}:{os.environ['PATH']}",
            "TERM": "xterm-ghostty",
            "TERM_PROGRAM": "ghostty",
            "SSH_CONNECTION": "",
            "DOTS_SSH_TINT": "1",
            "SSH_TEST_RC": "0",
            "SSH_TEST_INTERRUPT": "0",
        }

    def run_shell(
        self,
        source: str,
        *args: str,
        terminal: bool = False,
        interactive: bool = True,
    ) -> tuple[int, str]:
        """Run a bounded shell, optionally with terminal stdin and stdout."""
        argv = [
            str(ZSH),
            "-fic" if interactive else "-fc",
            f'source "$1"; shift; {source}',
            "test",
            str(TINT),
            "-F",
            str(self.config),
            *args,
        ]
        if not terminal:
            result = subprocess.run(  # noqa: S603
                argv,
                env=self.env,
                capture_output=True,
                text=True,
                timeout=5,
                check=False,
            )
            self.assertEqual("", result.stderr)
            return result.returncode, result.stdout
        master, slave = pty.openpty()
        try:
            result = subprocess.run(  # noqa: S603
                argv,
                env=self.env,
                stdin=slave,
                stdout=slave,
                stderr=subprocess.PIPE,
                timeout=5,
                check=False,
            )
            os.close(slave)
            slave = -1
            output = bytearray()
            while True:
                try:
                    chunk = os.read(master, 4096)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    break
                if not chunk:
                    break
                output.extend(chunk)
            self.assertEqual(b"", result.stderr)
            return result.returncode, output.decode().replace("\r\n", "\n")
        finally:
            os.close(master)
            if slave != -1:
                os.close(slave)

    def tint(self, *args: str) -> str:
        """Compute a color using real config and known-host lookup."""
        rc, output = self.run_shell('_dots_ssh_tint "$@"', *args)
        self.assertEqual(0, rc)
        self.assertRegex(output, r"^#[0-9a-f]{6}$")
        return output

    def test_alias_port_and_host_key_alias_share_color(self) -> None:
        """The key, rather than the destination spelling, determines color."""
        expected = self.tint("server.example")
        for host in ("nickname", "custom-port", "aliased-key", "user@nickname"):
            with self.subTest(host=host):
                self.assertEqual(expected, self.tint(host))
        self.assertNotEqual(expected, self.tint("other.example"))

    def test_prefer_ed25519_and_ignore_markers(self) -> None:
        """Prefer Ed25519 regardless of order; never select revoked or CA keys."""
        expected = self.tint("nickname")
        self.known.write_text(
            "@revoked server.example ssh-ed25519 AAAArevoked\n"
            "@cert-authority server.example ssh-ed25519 AAAAca\n"
            "server.example ssh-ed25519 AAAAfirst\n"
            "server.example ssh-rsa AAAArsa\n",
        )
        self.assertEqual(expected, self.tint("nickname"))
        self.known.write_text(
            "@cert-authority server.example ssh-ed25519 AAAAca\n",
        )
        self.assertEqual("#2a1a1a", self.tint("nickname"))

    def test_hashed_known_hosts(self) -> None:
        """Use OpenSSH's lookup to support hashed entries."""
        expected = self.tint("nickname")
        subprocess.run(  # noqa: S603
            [str(KEYGEN), "-H", "-f", str(self.known)],
            capture_output=True,
            check=True,
            timeout=5,
        )
        self.assertEqual(expected, self.tint("nickname"))

    def test_unknown_and_missing_files_use_red(self) -> None:
        """Missing keys must not trigger a scan or a connection."""
        self.assertEqual("#2a1a1a", self.tint("unknown.example"))
        self.known.unlink()
        self.assertEqual("#2a1a1a", self.tint("nickname"))

    def test_global_file_and_fallback_key_type(self) -> None:
        """Read global files and use other key types when Ed25519 is absent."""
        self.known.write_text("server.example ssh-rsa AAAArsa\n")
        expected = self.tint("nickname")
        self.assertNotEqual("#2a1a1a", expected)
        self.assertEqual(
            expected,
            self.tint(
                "-oUserKnownHostsFile=none",
                f"-oGlobalKnownHostsFile={self.known}",
                "nickname",
            ),
        )

    def test_tty_wrapper_restores_background_and_exit_status(self) -> None:
        """Reset even after connection failures, preserving arguments and status."""
        tint = self.tint("nickname")
        for status in (0, 42, 130, 255):
            with self.subTest(status=status):
                self.env["SSH_TEST_RC"] = str(status)
                rc, output = self.run_shell(
                    'ssh "$@"',
                    "nickname",
                    "printf '%s' hi",
                    terminal=True,
                )
                self.assertEqual(status, rc)
                self.assertEqual(
                    f"\x1b]11;{tint}\x07ssh<-F><{self.config}>"
                    "<nickname><printf '%s' hi>\n\x1b]111\x07",
                    output,
                )

    def test_interrupted_child_restores_background(self) -> None:
        """A real SIGINT from the child must still run the reset block."""
        self.env["SSH_TEST_INTERRUPT"] = "1"
        rc, output = self.run_shell('ssh "$@"', "nickname", terminal=True)
        self.assertEqual(130, rc)
        self.assertTrue(output.startswith("\x1b]11;#"))
        self.assertTrue(output.endswith("\x1b]111\x07"))

    def test_invalid_config_still_runs_ssh_without_tint(self) -> None:
        """Failure to calculate a tint must not swallow the real invocation."""
        self.config.write_text("NotAnSshOption yes\n")
        self.env["SSH_TEST_RC"] = "255"
        rc, output = self.run_shell('ssh "$@"', "nickname", terminal=True)
        self.assertEqual(255, rc)
        self.assertTrue(output.startswith("ssh<-F>"))
        self.assertNotIn("\x1b", output)

    def test_pipe_script_remote_and_opt_out_are_untouched(self) -> None:
        """Avoid escapes in data streams and shells that should not tint."""
        _, output = self.run_shell('ssh "$@"', "nickname")
        self.assertNotIn("\x1b", output)
        _, output = self.run_shell(
            'ssh "$@"',
            "nickname",
            terminal=True,
            interactive=False,
        )
        self.assertNotIn("\x1b", output)
        for name, value in (
            ("SSH_CONNECTION", "remote connection"),
            ("DOTS_SSH_TINT", "0"),
            ("TERM", "dumb"),
            ("TERM_PROGRAM", "WezTerm"),
            ("TERM_PROGRAM", "tmux"),
            ("TERM_PROGRAM", ""),
        ):
            with self.subTest(name=name):
                previous = self.env[name]
                self.env[name] = value
                _, output = self.run_shell('ssh "$@"', "nickname", terminal=True)
                self.assertNotIn("\x1b", output)
                self.env[name] = previous

    def test_queries_and_noninteractive_options_skip_tint(self) -> None:
        """Do not color config queries, control operations, or tunnels."""
        for options in (
            ("-G",),
            ("-vG",),
            ("-V",),
            ("-Q", "key"),
            ("-O", "check"),
            ("-f",),
            ("-N",),
            ("-T",),
            ("-n",),
        ):
            with self.subTest(options=options):
                rc, output = self.run_shell(
                    '_dots_ssh_tint "$@"',
                    *options,
                    "nickname",
                )
                self.assertEqual(1, rc)
                self.assertEqual("", output)

    def test_option_arguments_and_remote_flags_are_not_wrapper_flags(self) -> None:
        """Respect attached option values and stop parsing at the destination."""
        expected = self.tint("nickname")
        self.assertEqual(expected, self.tint("-lG", "nickname"))
        self.assertEqual(expected, self.tint("-l", "G", "nickname"))
        self.assertEqual(expected, self.tint("nickname", "echo", "-G"))


if __name__ == "__main__":
    unittest.main()

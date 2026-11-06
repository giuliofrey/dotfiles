"""Shared Herdr/Rex title helper regressions; no running Rex needed."""

import importlib.machinery
import importlib.util
import io
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import call, patch

loader = importlib.machinery.SourceFileLoader(
    "task_title", str(Path(__file__).resolve().parents[2] / "herdr/task-title")
)
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec is not None
title = importlib.util.module_from_spec(spec)
loader.exec_module(title)

SESSION = "session:test"
BLOCK = "block:12345678"
WINDOW = "window:87654321"


def view(block_label="shell", window_label="Window 87654321", split=False):
    blocks = [{"block_id": BLOCK, "label": block_label}]
    if split:
        blocks.append({"block_id": "block:other", "label": "shell"})
    return {"label": "~/projects/example", "windows": [{
        "window_id": WINDOW, "label": window_label, "layers": [{"blocks": blocks}],
    }]}


class RexTitlesTest(unittest.TestCase):
    def setUp(self):
        root = tempfile.TemporaryDirectory()
        self.addCleanup(root.cleanup)
        for mock in (
            patch.object(title, "STATE_ROOT", Path(root.name)),
            patch.dict(os.environ, {"REX_SESSION": SESSION, "REX_BLOCK": BLOCK}, clear=True),
        ):
            mock.start()
            self.addCleanup(mock.stop)

    def test_single_agent_and_manual_labels(self):
        with patch.object(title, "rex_command", side_effect=[view(), {}, {}]) as command, \
             patch("builtins.open", side_effect=OSError("no controlling terminal")):
            title.report_rex("pi", BLOCK, "Fix tests")
        self.assertEqual(command.call_args_list, [
            call("session", "inspect", SESSION, "--json"),
            call("block", "rename", "-s", SESSION, BLOCK, "Pi · Fix tests"),
            call("window", "rename", "-s", SESSION, WINDOW, "Pi · Fix tests"),
        ])
        with patch.object(title, "rex_command", side_effect=[view("Pinned pane", "Pinned tab")]) as command, \
             patch("builtins.open", side_effect=OSError):
            title.report_rex("pi", BLOCK, "Another task")
        self.assertEqual(command.call_count, 1, "Manual labels must win over managed names")

    def test_split_agents_do_not_fight_over_tab_name(self):
        title.write_state(title.state_path("rex-window", WINDOW, ""), "Pi · Old task", False)
        with patch.object(title, "rex_command", side_effect=[view(window_label="Pi · Old task", split=True), {}, {}]) as command, \
             patch("builtins.open", side_effect=OSError):
            title.report_rex("claude", BLOCK, "Review tests")
        self.assertEqual(command.call_args_list[-1],
                         call("window", "rename", "-s", SESSION, WINDOW, "Terminal"))
        with patch.object(title, "rex_command", side_effect=[view(window_label="Terminal", split=True), {}]) as command, \
             patch("builtins.open", side_effect=OSError):
            title.report_rex("codex", BLOCK, "Check results")
        self.assertEqual(command.call_count, 2)
        self.assertEqual(command.call_args_list[-1].args[0], "block")

    def test_managed_label_updates_but_failed_rename_does_not_claim_ownership(self):
        path = title.state_path("rex-block", BLOCK, "")
        with patch.object(title, "rex_command", return_value=None):
            self.assertEqual(title.rex_label("block", BLOCK, "shell", "Pi · Tests"), "shell")
        self.assertIsNone(title.read_state(path))
        title.write_state(path, "Pi · Tests", False)
        with patch.object(title, "rex_command", return_value={}):
            self.assertEqual(title.rex_label("block", BLOCK, "Pi · Tests", "Pi · Review"), "Pi · Review")
        self.assertEqual(title.read_state(path)["title"], "Pi · Review")

    def test_native_title_does_not_repeat_harness_prefix(self):
        with patch.object(title, "rex_command", return_value={"title": "Claude · Fix tests"}):
            self.assertEqual(title.native_title("claude", BLOCK, "example"), "Fix tests")
        with patch.object(title, "rex_command", return_value=None):
            self.assertEqual(title.native_title("claude", BLOCK, "example"), "")

    def test_osc_uses_terminal_not_hook_stdout_and_sanitizes_manual_label(self):
        terminal = io.StringIO()
        with patch.object(title, "rex_command", return_value=view("Pinned\x1b\x07\nname", "Pinned tab")), \
             patch("builtins.open") as opened:
            opened.return_value.__enter__.return_value = terminal
            title.report_rex("pi", BLOCK, "Task")
        opened.assert_called_once_with("/dev/tty", "w")
        self.assertEqual(terminal.getvalue(), "\x1b]2;Pinned name\x07")

    def test_rex_main_reuses_title_selection(self):
        payload = {"prompt": "Can you fix the pricing tests please?", "session_id": "chat"}
        with patch.object(title.sys, "argv", ["task-title", "claude"]), \
             patch.object(title.sys, "stdin", io.StringIO(json.dumps(payload))), \
             patch.object(title.select, "select", return_value=([True], [], [])), \
             patch.object(title, "project_name", return_value="example"), \
             patch.object(title, "report_rex") as report, \
             patch.object(title, "report") as herdr_report:
            title.main()
        report.assert_called_once_with("claude", BLOCK, "Fix the pricing tests please")
        herdr_report.assert_not_called()

    def test_nested_herdr_takes_precedence_over_inherited_rex(self):
        with patch.dict(os.environ, HERDR_ENV="1", HERDR_PANE_ID="w1:p1"), \
             patch.object(title.sys, "argv", ["task-title", "pi", "--title", "Task"]), \
             patch.object(title, "report_rex") as rex_report, \
             patch.object(title, "report") as herdr_report, \
             patch.object(title, "name_agent"):
            title.main()
        herdr_report.assert_called_once_with("pi", "w1:p1", "Task")
        rex_report.assert_not_called()

    def test_offline_rex_is_nonfatal(self):
        with patch.object(title.subprocess, "run", side_effect=title.subprocess.TimeoutExpired("rex", 3)):
            self.assertIsNone(title.rex_command("session", "inspect", SESSION, "--json"))
        with patch.object(title, "rex_command", return_value=None):
            title.report_rex("pi", BLOCK, "Task")


if __name__ == "__main__":
    unittest.main()

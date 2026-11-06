"""Run with: python3 -m unittest discover -s herdr -p 'test_task_title.py'."""

import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import tomllib
import unittest
from unittest.mock import MagicMock, patch

loader = importlib.machinery.SourceFileLoader("task_title", str(Path(__file__).with_name("task-title")))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec is not None
title = importlib.util.module_from_spec(spec)
loader.exec_module(title)


class TaskTitleTest(unittest.TestCase):
    def test_explicit_title_needs_neither_stdin_nor_git(self):
        with tempfile.TemporaryDirectory() as root, \
             patch.object(title, "STATE_ROOT", Path(root)), \
             patch.object(title.sys, "argv", ["task-title", "pi", "--title", "New name", "--session", "test", "--pane", "w1:p1"]), \
             patch.object(title.select, "select", side_effect=AssertionError("waited on stdin")), \
             patch.object(title, "project_name", side_effect=AssertionError("ran git")), \
             patch.object(title, "report") as report, \
             patch.object(title, "name_agent") as rename:
            title.main()
            report.assert_called_once_with("pi", "w1:p1", "New name")
            rename.assert_called_once_with("New name", "w1:p1")
            self.assertEqual(title.read_state(title.state_path("pi", "test", "w1:p1")),
                             {"title": "New name", "provisional": False})

    def test_hook_payload_still_supplies_prompt_and_session(self):
        payload = {"prompt": "Can we improve renaming now?", "session_id": "hook", "cwd": "/repo"}
        with tempfile.TemporaryDirectory() as root, \
             patch.object(title, "STATE_ROOT", Path(root)), \
             patch.object(title.sys, "argv", ["task-title", "claude", "--pane", "w1:p1"]), \
             patch.object(title.sys, "stdin", io.StringIO(json.dumps(payload))), \
             patch.object(title.select, "select", return_value=([True], [], [])), \
             patch.object(title, "project_name", return_value="repo"), \
             patch.object(title, "report") as report, \
             patch.object(title, "name_agent"):
            title.main()
            report.assert_called_once_with("claude", "w1:p1", "Improve renaming now")
            self.assertIsNotNone(title.read_state(title.state_path("claude", "hook", "w1:p1")))

    def test_rename_collision_keeps_pane_suffix(self):
        with patch.dict(os.environ, HERDR_ENV="1"), \
             patch.object(title, "request", side_effect=[{"error": {"code": "agent_name_taken"}}, {}]) as request:
            title.name_agent("New name", "w1:p2")
            self.assertEqual(request.call_args_list[0].args,
                             ("agent.rename", {"target": "w1:p2", "name": "new-name"}))
            self.assertEqual(request.call_args_list[1].args,
                             ("agent.rename", {"target": "w1:p2", "name": "new-name-w1p2"}))

    def test_socket_reads_complete_response_not_single_packet(self):
        client = MagicMock()
        client.__enter__.return_value = client
        response = {"result": {"padding": "x" * 8192}}
        client.makefile.return_value = io.StringIO(json.dumps(response) + "\n")
        with patch.dict(os.environ, HERDR_ENV="1", HERDR_SOCKET_PATH="/fake/socket"), \
             patch.object(title.socket, "socket", return_value=client):
            self.assertEqual(title.request("agent.rename", {"target": "w1:p1", "name": "new"}), response)
            sent = json.loads(client.sendall.call_args.args[0])
            self.assertEqual(sent["method"], "agent.rename")
            self.assertEqual(sent["params"], {"target": "w1:p1", "name": "new"})

    def test_socket_failure_is_nonfatal(self):
        with patch.dict(os.environ, HERDR_ENV="1", HERDR_SOCKET_PATH="/fake/socket"), \
             patch.object(title.socket, "socket", side_effect=OSError("offline")):
            self.assertEqual(title.request("agent.rename", {}), {})

    def test_sidebar_uses_live_titles_only_for_supported_harnesses(self):
        config = tomllib.loads(Path(__file__).with_name("config.toml").read_text())
        agents = config["ui"]["sidebar"]["agents"]
        self.assertEqual(agents["rows"][-1], ["$task"])
        for kind in ("pi", "claude"):
            self.assertEqual(agents["rows_by_agent"][kind][-1], ["terminal_title_stripped"])


if __name__ == "__main__":
    unittest.main()

"""rex/project-picker with fake rex, fzf and sessionizer on PATH. Run from ~/.config:
python3 -m unittest discover -s rex/tests -p 'test_*.py'"""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

PICKER = Path(__file__).resolve().parents[1] / "project-picker"

FAKE_REX = """#!/bin/sh
# ls prints sessions.json; new records a session; do records the select call.
case "$1" in
  ls) cat "$FAKE/sessions.json" ;;
  new) n=$(jq '.sessions | length' "$FAKE/sessions.json")
       jq --arg l "$2" --arg c "$4" --arg id "session:$n" \\
         '.sessions += [{label: $l, session_id: $id, cwd: $c}]' "$FAKE/sessions.json" > "$FAKE/t"
       mv "$FAKE/t" "$FAKE/sessions.json"; echo "{\\"session_id\\": \\"session:$n\\"}" ;;
  *) echo "$@" > "$FAKE/selected" ;;
esac
"""


class ProjectPicker(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        bin_ = self.tmp / "bin"
        bin_.mkdir()
        for name, body in {
            "rex": FAKE_REX,
            "fzf": '#!/bin/sh\ncat > /dev/null; cat "$FAKE/pick"\n',
        }.items():
            (bin_ / name).write_text(body)
            (bin_ / name).chmod(0o755)
        sessionizer = self.tmp / ".config/tmux/sessionizer"
        sessionizer.parent.mkdir(parents=True)
        sessionizer.write_text("#!/bin/sh\necho '~/projects/a/site'; echo '~/projects/b/site'\n")
        sessionizer.chmod(0o755)
        self.env = {**os.environ, "HOME": str(self.tmp), "FAKE": str(self.tmp),
                    "PATH": f"{bin_}:{os.environ['PATH']}", "XDG_STATE_HOME": str(self.tmp / "state")}
        self.write_sessions([{"label": "crisp-prairie", "session_id": "session:x"}])

    def write_sessions(self, sessions):
        (self.tmp / "sessions.json").write_text(json.dumps({"sessions": sessions}))

    def pick(self, project):
        (self.tmp / "pick").write_text(project + "\n")
        subprocess.run(["sh", str(PICKER), "client:1"], env=self.env, check=True)
        sessions = json.loads((self.tmp / "sessions.json").read_text())["sessions"]
        return sessions, (self.tmp / "selected").read_text().split()

    def test_names_by_folder_reuses_and_disambiguates(self):
        sessions, selected = self.pick("projects/a/site")
        self.assertEqual(sessions[-1]["label"], "site")
        self.assertEqual(sessions[-1]["cwd"], str(self.tmp / "projects/a/site"))
        self.assertEqual(selected, ["-C", "client:1", "do", "session.select", "session_id=session:1"])

        sessions, selected = self.pick("projects/a/site")
        self.assertEqual(len(sessions), 2, "reopening must not create another session")
        self.assertEqual(selected[-1], "session_id=session:1")

        sessions, selected = self.pick("projects/b/site")
        self.assertEqual(sessions[-1]["label"], "b-site", "same folder name, other project")
        self.assertEqual(selected[-1], "session_id=session:2")

    def test_unrelated_session_with_same_name_is_left_alone(self):
        self.write_sessions([{"label": "site", "session_id": "session:mine"}])
        sessions, _ = self.pick("projects/a/site")
        self.assertEqual(sessions[-1]["label"], "a-site")

    def test_escape_does_nothing(self):
        (self.tmp / "bin/fzf").write_text("#!/bin/sh\nexit 130\n")
        subprocess.run(["sh", str(PICKER)], env=self.env, check=True)
        self.assertFalse((self.tmp / "selected").exists())


if __name__ == "__main__":
    unittest.main()

# Rex project workspaces

Press **ctrl+space** then **f** (herdr's prefix+f) to open the project picker
in a floating pane, or search **Open Project…** in the command palette. It
lists git repos under `~/personal`, `~/projects` and `~/.config`, most recently
committed first. Enter opens the project's Fish session, or
returns to it if it is already open; Escape closes the picker.

Sessions are named after the project's folder. When another session
already uses that name, the parent folder goes in front (`b-site`). Rex
sessions don't record a directory, so `~/.local/state/rex/projects` remembers
which folder each picker-made name belongs to. Keep the names unchanged:
renaming a project session makes the picker create a new one.

## Keys

`init.lua` copies herdr's keymap onto the same ctrl+space prefix: w/N/W/D for
sessions, c/n/p/T/X and 1–9 for tabs, v/- splits, hjkl and tab focus, space to cycle tmux layouts, z, x, b,
d for lazygit in a floating pane, ? for the command palette, s settings, R
reload. Herdr's agent bindings are not copied, so j/k move between panes and 1–9
go to tabs. Rex's own Cmd shortcuts are untouched. Press ctrl+space twice to
send it to the terminal. `rex keymap` lists every binding.

## Agent titles

Project session labels stay fixed. The shared `~/.config/herdr/task-title`
helper labels agent panes and single-pane tabs as `Pi · Fix pricing tests`
(or Claude, Codex, Cursor). Split tabs use `Terminal`; each pane
keeps its own title. Explicit tab/pane labels override automatic labels.
Clear a label to restore automatic naming. Plain new shells keep Rex's defaults;
project-picker shells start in a `Terminal` tab.

Existing Claude/Codex hooks and the Pi title integration call the
helper. Titles use the first prompt or the harness's own title, with the project
as fallback. No extra model call or background service is involved. State under
`~/.local/state/herdr/task-titles/` remembers which labels the helper owns.
Terminal titles are also emitted through `/dev/tty` when available; hooks with
no controlling terminal still update the stored tab/pane labels.

Keep **Integrations → Let agents name sessions** and **Terminal → Titles →
Prefer generated titles** off. To reapply the local naming settings:

```sh
rex skill setup --session-naming=false
defaults write com.superlogical.rex rex.agents.names-sessions -bool false
defaults write com.superlogical.rex Workspace.prefersGeneratedTitles -bool false
```

Start a new agent conversation after changing the Rex integration. Already-open
conversations can retain the old session-renaming instruction. App settings may
need reopening Rex to refresh; do not restart the server or running agents.
Existing session names are not migrated automatically.

Check from `~/.config`:

```sh
python3 -m unittest discover -s rex/tests -p 'test_*.py'
rex config check
rex config reload
```

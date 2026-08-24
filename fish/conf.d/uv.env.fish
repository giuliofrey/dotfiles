
# uv writes this file on install; a machine without uv has none, and sourcing
# it unconditionally makes every shell there start with an error.
test -f "$HOME/.local/bin/env.fish"; and source "$HOME/.local/bin/env.fish"

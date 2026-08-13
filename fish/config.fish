if status is-interactive
    /opt/homebrew/bin/brew shellenv | source # Commands to run in interactive sessions can go here
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /Users/giulio/miniconda3/bin/conda
    eval /Users/giulio/miniconda3/bin/conda "shell.fish" hook $argv | source
else
    if test -f "/Users/giulio/miniconda3/etc/fish/conf.d/conda.fish"
        . "/Users/giulio/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH /Users/giulio/miniconda3/bin $PATH
    end
end
# <<< conda initialize <<<

set -gx EDITOR nvim

# claude personal key
alias claude-personal="CLAUDE_CONFIG_DIR=~/.claude-personal claude"

# tmux project picker. Works in or out of tmux: the script switches the client
# if $TMUX is set, attaches if not.
abbr -a t "$HOME/.config/tmux/sessionizer"
# ts: same split layout, but for the directory you are already in. Same thing
# prefix+F does from inside tmux.
abbr -a ts "$HOME/.config/tmux/sessionizer ."
abbr -a ta "tmux attach"
abbr -a tl "tmux list-sessions"

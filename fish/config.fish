if status is-interactive
    # Homebrew's prefix is /opt/homebrew on Apple silicon, /usr/local on Intel
    # and /home/linuxbrew/.linuxbrew on Linux. Take the first one that is
    # actually there; a machine without brew just skips the block.
    for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew
        if test -x $brew
            $brew shellenv | source
            break
        end
    end
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# Hand-edited to $HOME: conda init hardcodes an absolute path that does not
# survive a shared repo. Re-running `conda init fish` undoes this. The last
# branch also checks the directory exists before prepending it.
if test -f $HOME/miniconda3/bin/conda
    eval $HOME/miniconda3/bin/conda "shell.fish" hook $argv | source
else if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
    . "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
else if test -d $HOME/miniconda3/bin
    set -x PATH $HOME/miniconda3/bin $PATH
end
# <<< conda initialize <<<

set -gx EDITOR nvim

# cargo installs binaries here and rustup ships no env.fish, so nothing else
# puts it on PATH. fish_add_path is idempotent and skips the directory if it is
# not there, so a machine without rust is unaffected.
fish_add_path -g $HOME/.cargo/bin


# tmux project picker. Works in or out of tmux: the script switches the client
# if $TMUX is set, attaches if not.
abbr -a t "$HOME/.config/tmux/sessionizer"
# ts: same split layout, but for the directory you are already in. Same thing
# prefix+F does from inside tmux.
abbr -a ts "$HOME/.config/tmux/sessionizer ."
# ta with no argument attaches to the most recent session; `ta name` picks one.
# A function, not an abbr, because attach-session takes its target from -t and
# the plain form died on "too many arguments". Name prefixes work, so `ta surv`
# is enough.
#
# A bare number resolves to the Nth line of `tmux ls`, which `tl` prints;
# sessions are named after their repo, so tmux would read `ta 1` as a name.
function ta --description "attach to a tmux session by name, number, or the most recent"
    if not set -q argv[1]
        tmux attach
    else if string match -qr '^\d+$' -- $argv[1]
        set -l target (tmux ls | sed -n "$argv[1]p" | cut -d: -f1)
        if test -z "$target"
            echo "no session $argv[1]" >&2
            return 1
        end
        tmux attach -t $target
    else
        tmux attach -t $argv[1]
    end
end
# Numbered, because that is what `ta N` counts against.
abbr -a tl "tmux ls | nl -w2 -s' '"

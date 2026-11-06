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


# tmux-remote

Open existing remote tmux sessions as windows in a local tmux session:

```sh
./install.sh install
tmux-remote my-ssh-host
```

The installer preserves the existing Linux location, `/usr/bin`. On macOS it
uses `$(brew --prefix)/bin` when Homebrew is available, which is
`/opt/homebrew/bin` on Apple Silicon and `/usr/local/bin` on Intel Macs;
without Homebrew it uses `/usr/local/bin`. Override the destination when
needed, for example:

```sh
BINDIR="$HOME/.local/bin" ./install.sh install
```

Ensure the chosen directory is on `PATH`. The installer also adds
`~/.tmux-remote.conf` to `~/.tmux.conf`.

The scripts support macOS's bundled Bash 3.2 and BSD userland. Install `tmux`
with Homebrew on macOS:

```sh
brew install tmux
```

From inside the local tmux session, `Alt-a` opens a picker for additional
remote sessions, `Alt-d` disconnects the remote session in the current
window, and `Alt-D` disconnects every remote session opened by tmux-remote.

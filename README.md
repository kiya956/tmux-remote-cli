# tmux-remote-cli

`tmux-remote-cli` opens tmux sessions from an SSH host as windows in a local
tmux session. It provides shortcuts to attach individual or all remote
sessions, and to detach a single remote session or every session opened by the
tool.

## Requirements

- Bash
- tmux, installed locally and on the remote host
- SSH access to the remote host

[`fzf`](https://github.com/junegunn/fzf) is optional. When installed, it
provides a multi-select interface for choosing remote sessions; otherwise, the
picker uses a numbered prompt.

## Install

Clone this repository and run:

```bash
./install.sh install
```

The installer copies the commands to `/usr/bin`, creates
`~/.tmux-remote.conf`, and adds the following line to `~/.tmux.conf` if it is
not already present:

```tmux
source-file ~/.tmux-remote.conf
```

Reload tmux configuration or start a new tmux client:

```bash
tmux source-file ~/.tmux.conf
```

To remove the commands and configuration:

```bash
./install.sh uninstall
```

## Usage

Start by connecting to a host that has existing tmux sessions:

```bash
tmux-remote example-host
```

If run outside tmux, this starts a new local tmux session. Each remote tmux
session becomes a window in that local session. The command records the
host/session mappings in `~/.cache/tmux-remote/` so later shortcuts can manage
those remote sessions.

While in the local tmux session:

| Key binding | Action |
| --- | --- |
| `Alt-a` | Open a picker for unattached remote sessions. |
| `Alt-A` | Attach every unattached remote session on known hosts. |
| `Alt-n` | Prompt for a name, create a remote tmux session, and open it as a new window. Leave the name empty for tmux to choose one. |
| `Alt-g` | Prompt for a window number or name and switch to it. |
| `Alt-d` | Detach the remote session in the current window and close that window. |
| `D` | Detach only the local tmux client. Remote sessions remain attached. |
| `Alt-D` | Detach all remote sessions opened by the tool and close the local session. |
| `Alt-Left` / `Alt-Right` | Move between local tmux windows. |

You can also attach one remote session directly:

```bash
# When exactly one remote host is known in the current local session
tmux-remote-attach remote-session-name

# When multiple remote hosts are known
tmux-remote-attach example-host remote-session-name
```

Remote session names become local window names. Avoid using the same session
name on different remote hosts in one local tmux session, as window names must
be unique.

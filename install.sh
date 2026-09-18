#!/bin/bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

TMUX_CONF="$HOME/.tmux.conf"
REMOTE_CONF="$HOME/.tmux-remote.conf"
SOURCE_LINE="source-file $REMOTE_CONF"

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <install|uninstall>" >&2
	exit 1
fi

if [[ "$1" == "install" ]]; then
	sudo cp tmux-remote /usr/bin/
	sudo cp tmux-remote-attach /usr/bin/
	sudo cp tmux-remote-detach-all /usr/bin/
	sudo cp tmux-remote-detach-window /usr/bin/

	cp tmux-remote.conf "$REMOTE_CONF"
	touch "$TMUX_CONF"
	if ! grep -Fxq "$SOURCE_LINE" "$TMUX_CONF"; then
		printf '%s\n' "$SOURCE_LINE" >> "$TMUX_CONF"
	fi
elif [[ "$1" == "uninstall" ]]; then
	sudo rm -f /usr/bin/tmux-remote
	sudo rm -f /usr/bin/tmux-remote-attach
	sudo rm -f /usr/bin/tmux-remote-detach-all
	sudo rm -f /usr/bin/tmux-remote-detach-window

	rm -f "$REMOTE_CONF"
	if [[ -f "$TMUX_CONF" ]]; then
		sed -i "\\#^${SOURCE_LINE//#/\\#}\$#d" "$TMUX_CONF"
	fi
else
	echo "Usage: $0 <install|uninstall>" >&2
	exit 1
fi

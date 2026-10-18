#!/usr/bin/env bash
set -euo pipefail

resolve_path() {
	local path="$1" dir target
	while [[ -L "$path" ]]; do
		dir="$(cd -P "$(dirname "$path")" && pwd)"
		target="$(readlink "$path")"
		case "$target" in
			/*) path="$target" ;;
			*) path="$dir/$target" ;;
		esac
	done
	printf '%s/%s\n' "$(cd -P "$(dirname "$path")" && pwd)" "$(basename "$path")"
}

cd "$(dirname "$(resolve_path "$0")")"

SCRIPTS=(
	tmux-remote
	tmux-remote-attach
	tmux-remote-pick
	tmux-remote-detach-all
	tmux-remote-detach-window
)

default_bindir() {
	if [[ "$(uname -s)" == "Darwin" ]]; then
		if command -v brew >/dev/null 2>&1; then
			printf '%s\n' "$(brew --prefix)/bin"
		elif [[ -d /opt/homebrew/bin ]]; then
			printf '%s\n' /opt/homebrew/bin
		else
			printf '%s\n' /usr/local/bin
		fi
	else
		printf '%s\n' /usr/bin
	fi
}

BINDIR="${BINDIR:-$(default_bindir)}"
case "$BINDIR" in
	/*) ;;
	*) BINDIR="$PWD/$BINDIR" ;;
esac
TMUX_CONF="$HOME/.tmux.conf"
REMOTE_CONF="$HOME/.tmux-remote.conf"
SOURCE_LINE="source-file $REMOTE_CONF"
TMUX_BIN="$(command -v tmux || true)"

nearest_existing() {
	local dir="$1"
	while [[ ! -d "$dir" && "$dir" != "/" && -n "$dir" ]]; do
		dir="$(dirname "$dir")"
	done
	printf '%s\n' "$dir"
}

as_owner() {
	if [[ -w "$(nearest_existing "$BINDIR")" ]]; then
		"$@"
	elif command -v sudo >/dev/null 2>&1; then
		sudo "$@"
	else
		echo "Cannot write to $BINDIR and sudo is unavailable; set BINDIR to a writable directory." >&2
		exit 1
	fi
}

tmux_escape() {
	local value="$1"
	value="${value//\\/\\\\}"
	value="${value//\"/\\\"}"
	value="${value//\$/\\\$}"
	value="${value//#/##}"
	printf '%s' "$value"
}

write_tmux_config() {
	local line pick_command detach_window_command detach_all_command

	printf -v pick_command 'exec /bin/bash %q' "$BINDIR/tmux-remote-pick"
	printf -v detach_window_command 'exec /bin/bash %q' "$BINDIR/tmux-remote-detach-window"
	printf -v detach_all_command 'exec /bin/bash %q' "$BINDIR/tmux-remote-detach-all"

	{
		printf 'set-environment -g PATH "%s"\n' "$(tmux_escape "$(dirname "$TMUX_BIN"):$PATH")"
		while IFS= read -r line || [[ -n "$line" ]]; do
			case "$line" in
				'bind-key -n M-a '*)
					printf 'bind-key -n M-a display-popup -E -w 60%% -h 50%% -T " Attach remote session " "%s"\n' \
						"$(tmux_escape "$pick_command")"
					;;
				'bind-key -n M-d '*)
					printf 'bind-key -n M-d run-shell "%s '\''#{session_name}'\'' '\''#W'\''"\n' \
						"$(tmux_escape "$detach_window_command")"
					;;
				'bind-key -n M-D '*)
					printf 'bind-key -n M-D run-shell "%s '\''#{session_name}'\''"\n' \
						"$(tmux_escape "$detach_all_command")"
					;;
				*) printf '%s\n' "$line" ;;
			esac
		done < tmux-remote.conf
	} > "$REMOTE_CONF"
}

remove_source_line() {
	local status
	if grep -Fxv "$SOURCE_LINE" "$TMUX_CONF" > "$TMUX_CONF.tmp"; then
		:
	else
		status=$?
		if [[ $status -ne 1 ]]; then
			rm -f "$TMUX_CONF.tmp"
			echo "Cannot update $TMUX_CONF." >&2
			exit "$status"
		fi
	fi
	mv "$TMUX_CONF.tmp" "$TMUX_CONF"
}

install_all() {
	if [[ -z "$TMUX_BIN" ]]; then
		echo "tmux is required; install it before running $0." >&2
		exit 1
	fi

	[[ -d "$BINDIR" ]] || as_owner mkdir -p "$BINDIR"
	for script in "${SCRIPTS[@]}"; do
		as_owner cp "$script" "$BINDIR/$script"
		as_owner chmod 755 "$BINDIR/$script"
	done

	write_tmux_config

	touch "$TMUX_CONF"
	if ! grep -Fxq "$SOURCE_LINE" "$TMUX_CONF"; then
		printf '%s\n' "$SOURCE_LINE" >> "$TMUX_CONF"
	fi
}

uninstall_all() {
	for script in "${SCRIPTS[@]}"; do
		[[ -e "$BINDIR/$script" ]] && as_owner rm -f "$BINDIR/$script"
	done

	rm -f "$REMOTE_CONF"
	if [[ -f "$TMUX_CONF" ]]; then
		remove_source_line
	fi
}

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <install|uninstall>" >&2
	exit 1
fi

case "$1" in
	install) install_all ;;
	uninstall) uninstall_all ;;
	*)
		echo "Usage: $0 <install|uninstall>" >&2
		exit 1
		;;
esac

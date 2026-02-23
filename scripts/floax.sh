#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/utils.sh"

# Function to check if current pane is running nvim
is_nvim_running() {
    local pane_pid
    pane_pid=$(tmux display -p '#{pane_pid}')
    pgrep -P "$pane_pid" -f nvim >/dev/null 2>&1
}

tmux setenv -g ORIGIN_SESSION "$(tmux display -p '#{session_name}')"
if [ -z "$FLOAX_SESSION_NAME" ]; then
    FLOAX_SESSION_NAME="$DEFAULT_SESSION_NAME"
fi

if [ "$(tmux display-message -p '#{session_name}')" = "$FLOAX_SESSION_NAME" ]; then
    unset_bindings

    if [ -z "$FLOAX_TITLE" ]; then
        FLOAX_TITLE="$DEFAULT_TITLE"
    fi

    tmux setenv -g FLOAX_TITLE "$FLOAX_TITLE"
    tmux detach-client
else
    # Check if nvim passthrough is enabled and nvim is running in the current pane
    if [ "$(tmux_option_or_fallback '@floax-nvim-passthrough' 'true')" = "true" ] && is_nvim_running; then
        floax_bind="$(tmux_option_or_fallback "@floax-bind" "p")"
        
        # If the bind contains "-n", get the last part; otherwise use as-is
        if [[ "$floax_bind" == *"-n "* ]]; then
            actual_key="${floax_bind##*-n }"
        else
            actual_key="$floax_bind"
        fi
        
        # Send the actual key to nvim
        tmux send-keys "$actual_key"
    else
        set_bindings
        # When nvim passthrough is disabled or nvim is not running, proceed with normal floax behavior
        # Check if the session 'scratch' exists
        if tmux has-session -t "$FLOAX_SESSION_NAME" 2>/dev/null; then
            tmux_popup
        else
            # Create a new session named 'scratch' and attach to it
            tmux new-session -d -c "$(tmux display-message -p '#{pane_current_path}')" -s "$FLOAX_SESSION_NAME"
            tmux set-option -t "$FLOAX_SESSION_NAME" status off
            tmux_popup
        fi
    fi
fi

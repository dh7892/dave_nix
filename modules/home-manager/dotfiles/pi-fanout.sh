# shellcheck shell=bash
#
# pi-fanout — fan out task .md files to parallel `pi` sessions,
# each in its own git worktree and Zellij tab.
#
# Usage: pi-fanout [tasks-dir]
#   tasks-dir defaults to plan/tasks/pending (relative to repo root).
#
# Design: plan/tasks/pending/TASK-001-pi-fanout.md (in dave_nix).

set -euo pipefail

# ---- sanity checks --------------------------------------------------

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "pi-fanout: not inside a git repository" >&2
    exit 1
fi
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")

if [ -z "${ZELLIJ:-}" ]; then
    echo "pi-fanout: not inside a Zellij session — start zellij first" >&2
    exit 1
fi

CURRENT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
case "$CURRENT_BRANCH" in
    main|master) ;;
    *)
        echo "pi-fanout: refusing to fan out from branch '$CURRENT_BRANCH'" >&2
        echo "           (expected 'main' or 'master' — switch first)" >&2
        exit 1
        ;;
esac

TASKS_DIR=${1:-plan/tasks/pending}
TASKS_ABS="$REPO_ROOT/$TASKS_DIR"
if [ ! -d "$TASKS_ABS" ]; then
    echo "pi-fanout: tasks dir '$TASKS_DIR' not found under $REPO_ROOT" >&2
    exit 1
fi

PROMPT_TEMPLATE="$HOME/.pi/agent/prompts/fanout-worker.md"
if [ ! -f "$PROMPT_TEMPLATE" ]; then
    echo "pi-fanout: worker prompt template not found at $PROMPT_TEMPLATE" >&2
    exit 1
fi

# ---- gather candidates ----------------------------------------------

mapfile -t CANDIDATES < <(
    cd "$REPO_ROOT" && \
    find "$TASKS_DIR" -maxdepth 1 -type f -name '*.md' | sort
)
if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    echo "pi-fanout: no .md files in $TASKS_DIR" >&2
    exit 1
fi

# ---- multi-select ---------------------------------------------------

SELECTED=$(printf '%s\n' "${CANDIDATES[@]}" \
    | gum choose --no-limit --header "Select tasks to fan out")

if [ -z "$SELECTED" ]; then
    echo "pi-fanout: nothing selected, exiting"
    exit 0
fi

# ---- worktrees parent dir -------------------------------------------

WORKTREES_PARENT="$REPO_ROOT/../$REPO_NAME-worktrees"
mkdir -p "$WORKTREES_PARENT"
WORKTREES_PARENT=$(cd "$WORKTREES_PARENT" && pwd)

# KDL string escape: backslash and double-quote. Used only for path-shaped
# values (cwd, command). The prompt itself sits in a separate text file so
# we never have to escape its content into KDL.
kdl_escape() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    printf '%s' "$s"
}

# ---- per-task fan-out -----------------------------------------------

while IFS= read -r task_rel; do
    [ -z "$task_rel" ] && continue

    task_file_basename=$(basename "$task_rel")
    task_stem=${task_file_basename%.md}

    # Slug: replace whitespace with '-'. Preserve case so well-named
    # files like TASK-002-foo.md round-trip cleanly.
    slug=$(printf '%s' "$task_stem" | tr -s '[:space:]' '-')
    branch="task/$slug"

    # Compact tab name: TASK-NNN prefix if present, else full slug.
    if tab_name=$(printf '%s' "$task_stem" | grep -oE '^[Tt][Aa][Ss][Kk]-[0-9]+'); then
        :
    else
        tab_name=$slug
    fi

    worktree_dir="$WORKTREES_PARENT/$slug"
    if [ -e "$worktree_dir" ]; then
        echo "pi-fanout: worktree dir already exists, skipping: $worktree_dir" >&2
        continue
    fi

    # Branch name collision?
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
        echo "pi-fanout: branch '$branch' already exists, skipping" >&2
        continue
    fi

    echo "pi-fanout: creating worktree $worktree_dir on branch $branch"
    git -C "$REPO_ROOT" worktree add -b "$branch" "$worktree_dir" "$CURRENT_BRANCH"

    # Move pending → in-progress inside the worktree, if convention holds.
    in_progress_dir="$worktree_dir/plan/tasks/in-progress"
    src_in_worktree="$worktree_dir/$task_rel"
    task_file_for_prompt=$task_rel

    if [ -d "$in_progress_dir" ] && [ -f "$src_in_worktree" ]; then
        dest_rel="plan/tasks/in-progress/$task_file_basename"
        git -C "$worktree_dir" mv "$task_rel" "$dest_rel"
        git -C "$worktree_dir" commit -m "Start $tab_name (move to in-progress)" >/dev/null
        task_file_for_prompt=$dest_rel
    else
        echo "pi-fanout: in-progress/ not found in worktree, leaving task file in place" >&2
    fi

    # Per-task scratch dir holds three files:
    #   prompt.txt   — the seeded prompt, plain text, no escaping
    #   start.sh     — launcher that sources the user's interactive shell
    #                  (so `pi` aliases / env-injecting wrappers like
    #                  `op run --env-file ...` apply) and then execs pi
    #                  with the prompt as $1
    #   layout.kdl   — zellij layout pointing `command` at start.sh
    layout_dir=$(mktemp -d -t pi-fanout-XXXXXX)
    prompt_file="$layout_dir/prompt.txt"
    launcher="$layout_dir/start.sh"
    layout_file="$layout_dir/layout.kdl"

    sed \
        -e "s|{{TASK_FILE}}|$task_file_for_prompt|g" \
        -e "s|{{TASK_BRANCH}}|$branch|g" \
        -e "s|{{MAIN_BRANCH}}|$CURRENT_BRANCH|g" \
        -e "s|{{MAIN_WORKTREE}}|$REPO_ROOT|g" \
        "$PROMPT_TEMPLATE" > "$prompt_file"

    cat > "$launcher" <<'LAUNCHER'
#!/usr/bin/env bash
# Spawned by zellij for a fanned-out pi worker. We go through the user's
# interactive shell so shell aliases (e.g. a `pi` alias that wraps the real
# binary with `op run --env-file ...` for API keys) and rc-file env vars are
# in scope. Without this, pi launches with an empty env and no provider.
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
PROMPT=$(cat "$DIR/prompt.txt")
exec "${SHELL:-/bin/zsh}" -ic 'pi "$1"' pi-fanout-worker "$PROMPT"
LAUNCHER
    chmod +x "$launcher"

    # Layout: no `tab {...}` wrapper. `zellij action new-tab --layout` treats
    # the file as a description of the new tab's pane tree; wrapping it in
    # `tab {...}` causes some versions to render the panes as floating /
    # mis-tabbed. Tab name comes from `--name` instead.
    #
    # We must explicitly include the tab-bar and status-bar plugin panes:
    # passing `--layout` replaces zellij's `default_tab_template`, which is
    # what normally provides those decorations. Without these two panes the
    # tab still exists but is invisibly chrome-less (no tab strip at top, no
    # status line at bottom).
    {
        printf 'layout {\n'
        printf '    pane size=1 borderless=true {\n'
        printf '        plugin location="zellij:tab-bar"\n'
        printf '    }\n'
        printf '    pane command="%s" cwd="%s"\n' \
            "$(kdl_escape "$launcher")" \
            "$(kdl_escape "$worktree_dir")"
        printf '    pane size=2 borderless=true {\n'
        printf '        plugin location="zellij:status-bar"\n'
        printf '    }\n'
        printf '}\n'
    } > "$layout_file"

    zellij action new-tab --layout "$layout_file" --name "$tab_name"
    echo "pi-fanout: launched tab '$tab_name' for $task_file_for_prompt"
done <<< "$SELECTED"

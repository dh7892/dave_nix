# Portability & Fresh-Machine Bootstrap Audit

Issues identified while reviewing the repo for installability on a brand-new
Mac (different username, no existing dotfiles, no credentials). Work through
these one at a time; mark each as **FIX**, **IGNORE**, or **DONE**.

---

## ISSUE-001: `~/.gitconfig` is not managed by Nix

**Status:** DONE

**Resolution:** Fixed via the new `~/.config/dave_nix/private.nix` mechanism
(see ISSUE-006). `programs.git` in `modules/home-manager/default.nix` now sets
`userName`, `userEmail`, `aliases` (`hist`, `co`), and `extraConfig`
(`push.autoSetupRemote`, `rerere.enabled`) from `private.fullName` /
`private.email`. The pre-existing `~/.gitconfig` will be moved to
`~/.gitconfig.backup` on next `nixswitch` (per `backupFileExtension`).

**Problem:** Git identity (`user.name`, `user.email`), aliases, and config
(`push.autoSetupRemote`, `rerere.enabled`) live only in `~/.gitconfig` on
this machine. `programs.git.enable = true` is set in
`modules/home-manager/default.nix` but nothing is configured, so on a fresh
machine git would have no identity.

**Current `~/.gitconfig`:**
```
[user]
    name = Dave
    email = dave@dhills.net
[alias]
    hist = !git --no-pager log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short
    co = checkout
[push]
    autoSetupRemote = true
[rerere]
    enabled = true
```

**Proposed fix:** Move into `programs.git` block in
`modules/home-manager/default.nix`:

```nix
programs.git = {
  enable = true;
  userName = "Dave";
  userEmail = "dave@dhills.net";
  aliases = {
    hist = ''!git --no-pager log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'';
    co = "checkout";
  };
  extraConfig = {
    push.autoSetupRemote = true;
    rerere.enabled = true;
  };
};
```

After applying, delete the existing `~/.gitconfig` (home-manager will refuse
to overwrite it without `backupFileExtension`, which is set, so it will be
backed up to `~/.gitconfig.backup`).

---

## ISSUE-002: Pi has no automatic credential path on a fresh machine

**Status:** DONE

**Resolution:** `pi` is now wrapped with `op run` in `shellAliases`
(mirroring the existing `opencode` wrapper). The 1Password account
shorthand moved into `private.opAccount` (see `private.nix.example`),
and both wrappers reference it from there — no more `OP_ACCOUNT` env
var dance. `~/.secrets.sh` is gone: `zshrc` no longer sources it, the
`op inject` bootstrap step is removed from the README, and
`shell-setup-check` no longer warns about `OP_ACCOUNT`. The
`_nixupdate_wrapped_run` worker function calls `op run ... -- pi`
directly (reading the account from
`~/.config/dave_nix/op-account`, which home-manager writes from
`private.opAccount`) instead of relying on alias expansion in a
non-interactive subshell. `~/.secrets.template` is retained as the
file listing 1Password secret references consumed by `op run`.

**Note (post ISSUE-006):** Hardcoded values in the proposed fix below
(notably the 1Password account, currently `my.1password.eu`) should not
be committed to the public repo. Move account-identifying details to
`~/.config/dave_nix/private.nix` (e.g. `private.opAccount`) and
reference them via the `private` arg threaded through `extraSpecialArgs`.
Add the field to `private.nix.example` with a placeholder when
implementing. The `~/.secrets.template` 1Password references
(`op://Vault/Item/field`) are themselves not secret and may stay in the
repo, but anything that names a personal vault, account, or item
identifier should go through `private.nix`.

**Problem:** Pi authenticates via the `ANTHROPIC_API_KEY` environment
variable (its `~/.pi/agent/auth.json` is empty `{}` and only used for OAuth
flows we don't use). That env var currently comes from a plaintext
`~/.secrets.sh` that the user must manually generate post-install via:

```
op inject --account <Account-ID> ~/.secrets.template -o ~/.secrets.sh
```

Consequences on a virgin machine:
1. After `nixswitch`, running `pi` silently fails / prompts for auth until
   the user remembers to run `op inject` and restart their shell.
2. The user must know their 1Password account ID.
3. `~/.secrets.sh` then sits on disk in plaintext forever, defeating much
   of the point of using 1Password.

**Proposed fix:** Wrap `pi` with `op run` exactly the way `opencode` already
is. In `modules/home-manager/default.nix` `shellAliases`:

```nix
pi = "op run --account=\${OP_ACCOUNT:-my.1password.eu} --env-file ~/.secrets.template --no-masking -- pi";
```

This:
- Pulls `ANTHROPIC_API_KEY` fresh from 1Password every invocation.
- Removes any need for `~/.secrets.sh` for the Pi happy-path.
- Makes the bootstrap requirement on a new machine simply: install
  1Password desktop, enable CLI integration, sign in. No `op inject` step.

**Caveats to consider before applying:**
- Other tooling (anything that reads `ANTHROPIC_API_KEY` directly from the
  environment outside an `op run` wrapper) still needs `~/.secrets.sh`.
  Decide whether to also wrap those, or keep `~/.secrets.sh` as a fallback.
- `_nixupdate_wrapped_run` in `dotfiles/zshrc` invokes `pi` directly. With
  the alias approach, it must use `zsh -ic` (it already does inside
  zellij) or be rewritten to call `op run ... -- pi` itself, since aliases
  don't expand in non-interactive shells.
- Update README step 4 to mark `op inject` as optional / only-for-fallback.

---

## ISSUE-003: Hardcoded `username = "dhills"` in `flake.nix`

**Status:** DONE

**Resolution:** Resolved as a free side-effect of ISSUE-006. `flake.nix` now
reads `username` from `private.username` instead of hardcoding it. A fresh
Mac with a different short username just sets a different value in
`~/.config/dave_nix/private.nix`.

**Problem:** `flake.nix` hardcodes `username = "dhills"` and threads it
through `system.primaryUser`, `users.users.${username}`, and
`home = "/Users/${username}"`. A fresh Mac with a different macOS short
username would fail to build until the flake is edited.

**Options:**
- **IGNORE** and document the constraint prominently in README ("This
  flake assumes your macOS short username is `dhills`; edit `flake.nix`
  if yours differs").
- **FIX** by reading `$USER` at evaluation time — but flakes are pure, so
  this would require either a `--override-input` style argument, an
  `lib.mkDefault` plus per-host module, or splitting `darwinConfigurations`
  into `darwinConfigurations.${username}` entries.

Recommendation: just document it. Low value to genericise for a personal
flake.

---

## ISSUE-004: Repo path hardcoded to `~/code/dave_nix`

**Status:** pending — likely **IGNORE**.

**Problem:** `nixswitch`, `nixup`, and `_nixupdate_wrapped_run` all assume
the repo lives at `~/code/dave_nix`. The README documents this, and the
first-time bootstrap uses `nix run github:dh7892/dave_nix#default` which
doesn't need a clone, so this isn't a bootstrap blocker — only an ongoing
constraint.

**Options:**
- **IGNORE** (already documented in README and `CLAUDE.md`).
- **FIX** by introducing a flake-managed path constant or detecting the
  repo location at alias-call time (`$(git rev-parse --show-toplevel)` if
  invoked from inside the repo, etc.). Probably not worth it.

---

## ISSUE-005: Non-Nix-managed dotfiles / credential stores

**Status:** pending — partial fix only; most are inherently non-portable.

**Problem:** Several files in `$HOME` hold state or secrets that would not
appear on a fresh machine. None block getting into a working Pi session,
but listing them so we can decide what (if anything) to migrate into Nix.

| Path | Contents | Recommended action |
|---|---|---|
| `~/.gitconfig` | git identity | **FIX via ISSUE-001** |
| `~/.ssh/*` | SSH keys, config | Manually restore or use 1Password SSH agent. Out of scope for Nix. |
| `~/.config/op/` | 1Password CLI session | Re-sign-in post-install. |
| `~/.config/gh/` | GitHub CLI auth | `gh auth login` post-install. |
| `~/.aws/`, `~/.kube/`, `~/.docker/` | cloud creds | Re-auth post-install. |
| `~/.adventofcode.session` | personal cookie | Manually re-paste if needed. |
| `~/.aerospace.toml.backup` | stale leftover | **Delete** (dead file from before aerospace was Nix-managed). |
| `~/.claude.json`, `~/.gemini/`, `~/.cargo/`, `~/.npmrc`, `~/.nvm/`, `~/.pyenv/` | app state | Regenerated on first use. |
| `~/.bashrc`, `~/.profile` | bash startup stubs | Live in zsh, not relevant. |
| `~/local_shell_settings.sh` | personal aliases | Template is Nix-managed; bootstrap step is `shell-setup`. Already documented. |

**Concrete sub-tasks if pursued:**
- [ ] Delete `~/.aerospace.toml.backup` (one-liner, no Nix change).
- [ ] Decide whether to add a README "post-bootstrap checklist" listing the
      manual re-auths above (gh, aws, op, ssh).

---

## ISSUE-006: Per-machine private config mechanism

**Status:** DONE

**Problem:** PII (name, email, macOS short username) was either hardcoded
in the public flake (`username`) or only present on this machine outside
Nix (`~/.gitconfig`). Needed a way to keep PII out of the public repo
while allowing per-machine variation, without requiring 1Password CLI to
be installed before the very first `nixswitch`.

**Resolution:** Introduced `~/.config/dave_nix/private.nix` as a small,
user-managed file imported by the flake at evaluation time. Schema lives
in `private.nix.example` in the public repo.

- `flake.nix` reads the file via `builtins.getEnv "HOME"` +
  `builtins.pathExists` and throws a clear error if missing. This makes
  evaluation impure, so `--impure` is now required; it's baked into the
  `nixswitch` alias and the bootstrap command in the README.
- The `private` attrset is threaded through `extraSpecialArgs` to
  home-manager so modules can reference `private.fullName`, etc.
- The `nixswitch` alias auto-creates `~/.config/dave_nix/private.nix`
  from `private.nix.example` if missing, prints instructions, and bails
  out (so the user fills it in and re-runs).
- README bootstrap steps updated: new step 3 "Create your `private.nix`";
  step 4 (build) now includes `--impure`.

**How to populate on a new machine:** any way you like — paste from a
1Password Secure Note via the web UI, AirDrop, type by hand. Deliberately
*not* coupled to the `op` CLI so it works on a truly fresh Mac before any
Nix-managed tools exist.

---

## Out of scope / acknowledged low priority

These were noted in review but explicitly deferred per user direction:

- `karabiner.json` is force-overwritten by home-manager (destructive on an
  already-configured machine, fine on a fresh one).
- Zellij auto-attach in `zshrc` runs unconditionally; could be gated on
  `command -v zellij` for robustness.
- `opencode-pkg` pins `anomalyco/opencode` (a fork) rather than upstream
  `sst/opencode` — confirm intentional.
- Wrapped packages are `aarch64-darwin`-only binaries; would fail loudly
  on x86 but `mySystem` makes the constraint explicit.

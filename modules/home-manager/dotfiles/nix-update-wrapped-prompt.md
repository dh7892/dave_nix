# Task: Update manually-wrapped Nix packages

You are running at the root of the `dave_nix` repo (the working directory is
already set for you; treat all paths in this prompt as repo-relative). Your
job is to update every manually-pinned
package declared in the **WRAPPED PACKAGES** region of
`modules/home-manager/default.nix` to its latest upstream version.

## How to find the work

Open `modules/home-manager/default.nix` and locate the region delimited by:

```
# ============================================================
# WRAPPED PACKAGES — BEGIN
...
# WRAPPED PACKAGES — END
# ============================================================
```

Every Nix binding inside that region is in scope. Anything outside is **not**.
Do not invent a list from memory — discover the bindings by reading the file.
If new packages have been added since you last ran, you should pick them up
automatically. If old ones have been removed, don't touch them.

For each binding inside the region:

1. Find the `# update-source:` hint comment that precedes it. Combined with
   the `src = ...` block of the derivation, this tells you what fetcher is
   in use and where upstream lives.
2. Determine the currently pinned version (`version = "..."` and/or
   `rev = "..."`) and current hash (`sha256 = "..."` or `hash = "..."`).
3. Look up the latest upstream version (recipes below).
4. If upstream is newer (semver-wise), compute the new hash and apply a
   single `edit` that updates **both** the version/rev and the matching
   hash in that derivation. Never leave a stale hash next to a new version.
5. If upstream is equal or older, mark "already-latest" and move on.

## Rules

- **Do NOT run** `darwin-rebuild`, `danix-switch`, `danix-up`, or `nix flake update`.
  Editing the Nix files is the entire job. The user runs `danix-switch` themselves.
- Edit `modules/home-manager/default.nix` directly, one derivation at a time.
- If something fails (network, hash mismatch, unexpected file shape, parsing
  the `update-source` hint), report it in the final summary and continue —
  don't abort the whole run.
- Don't restructure code, rename bindings, or touch anything outside the
  region. Comments inside the region (e.g. the rmc `pythonRelaxDeps` note)
  are guidance for *you*; respect them.

## Generic recipes by fetcher

You'll see one of these `src = ...` shapes. Match against the shape rather
than against package name.

### `pkgs.fetchurl { url = "https://github.com/<owner>/<repo>/releases/download/v${version}/<asset>"; sha256 = "..."; }`
Hint will look like: `# update-source: github-release <owner>/<repo> (asset: <asset>)`.
- Latest version:
  `curl -fsSL https://api.github.com/repos/<owner>/<repo>/releases/latest | jq -r .tag_name`
  (strip a leading `v`).
- New hash: `nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/v<NEW>/<asset>`
- Replace the `sha256 = "...";` value with the prefetch output.

### `pkgs.fetchFromGitHub { owner = ...; repo = ...; rev = "vX.Y.Z"; sha256 = "..."; }`
Hint will look like: `# update-source: github-tag <owner>/<repo> ...`.
- Latest tag: `curl -fsSL https://api.github.com/repos/<owner>/<repo>/releases/latest | jq -r .tag_name`
  Fallback if no GitHub releases:
  `git ls-remote --tags https://github.com/<owner>/<repo> | awk -F/ '{print $NF}' | grep -v '\\^' | sort -V | tail -1`
- New hash: `nix-prefetch-url --unpack https://github.com/<owner>/<repo>/archive/<TAG>.tar.gz`
- Update **both** `rev` and `sha256` together.

### `pkgs.fetchPypi { pname = ...; version = ...; hash = "sha256-..."; }`
Hint will look like: `# update-source: pypi <pname>`.
- Latest version: `curl -fsSL https://pypi.org/pypi/<pname>/json | jq -r .info.version`
- New hash (must end up in **SRI** form, `sha256-<base64>=`):
  1. `nix-prefetch-url https://files.pythonhosted.org/packages/source/<first-letter>/<pname>/<pname>-<NEW>.tar.gz`
  2. Convert with `nix hash convert --to sri --hash-algo sha256 <prefetch-output>`
     (or older nix: `nix hash to-sri --type sha256 <prefetch-output>`).
- Replace the `hash = "sha256-...";` value.

### Anything else
If you see a fetcher you don't recognise, or the `# update-source:` hint is
missing/malformed, **don't guess**. Mark it `skipped: unknown fetcher` in the
summary so the user can add a recipe.

## Final output

After processing everything in the region, print a summary table:

```
package          | old → new           | status
-----------------+--------------------+----------
opencode-pkg     | 1.14.38 → 1.15.0   | updated
pi-pkg           | 0.73.0 → 0.73.0    | already-latest
tpm              | v3.1.0 → v3.1.0    | already-latest
rmc              | 0.3.0  → 0.3.0     | already-latest
```

Then stop. The user reviews the diff and runs `danix-switch` if happy.

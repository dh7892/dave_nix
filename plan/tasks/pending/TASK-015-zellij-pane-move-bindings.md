Task: Bind Ctrl-b H/J/K/L to MovePane in Zellij tmux mode

 Motivation: matches the equivalent Aerospace bindings for moving windows; complements
 the existing Ctrl-b h/j/k/l (MoveFocus) in tmux mode.

 Changes:
 1. modules/home-manager/dotfiles/zellij.kdl, in the tmux { … } block (near the
 MoveFocus bindings around lines 35–38), add:
   ```kdl
     bind "H" { MovePane "left"; SwitchToMode "normal"; }
     bind "J" { MovePane "down"; SwitchToMode "normal"; }
     bind "K" { MovePane "up"; SwitchToMode "normal"; }
     bind "L" { MovePane "right"; SwitchToMode "normal"; }
   ```
   (Capitals are unbound in tmux mode today; they're only used in resize mode, which is
 a separate mode — no conflict.)
 2. Update modules/home-manager/dotfiles/zellij-cheatsheet.txt in the same commit,
 under "Pane management" in the TMUX MODE section, e.g.:
   ```
     H J K L   move pane    left / down / up / right
   ```
   The kdl file's own header (zellij.kdl:11-13) requires keeping the cheatsheet in
 sync.
 3. Validate with a dry-run darwin-rebuild build, commit. User runs danix-switch.

 Out of scope: any other zellij keymap changes; touching resize mode.

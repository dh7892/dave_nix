# Environment variables
$env.EDITOR = "nvim"
$env.PATH = ($env.PATH | split row (char esep) | append "~/.local/bin")

# Useful aliases
alias ll = ls -l
alias vim = nvim
alias lg = lazygit

$env.PATH = ($env.PATH | split row (char esep) | append "/Users/dhills/go/bin")
$env.PATH = ($env.PATH | split row (char esep) | append "/Users/dhills/.cargo/bin")

# =============================================================================
# Brewfile — declarative list of everything Homebrew should install.
# Run with:  brew bundle --file=Brewfile
# Edit freely: comment out a line to skip it, add `brew "name"` / `cask "name"`.
# Find packages:  brew search <term>   |   https://formulae.brew.sh
# =============================================================================

# ----- Taps (extra package sources) ------------------------------------------
# (brew bundle is built into Homebrew core now — no homebrew/bundle tap needed.)
tap "docker/tap"      # source for the sbx (Docker Sandboxes) CLI

# ----- Core CLI tools --------------------------------------------------------
brew "git"            # version control
brew "gh"             # GitHub CLI (auth, PRs, repos from terminal)
brew "mise"           # version manager for node/python/go/rust/ruby (replaces nvm/pyenv)
brew "coreutils"      # GNU core utilities
brew "wget"           # downloader
brew "curl"           # transfers (newer than system curl)
brew "jq"             # JSON processor
brew "yq"             # YAML processor
brew "ripgrep"        # fast grep (rg)
brew "fd"             # fast find
brew "fzf"            # fuzzy finder
brew "bat"            # cat with syntax highlighting
brew "eza"            # modern ls
brew "zoxide"         # smarter cd
brew "tree"           # directory tree view
brew "tmux"           # terminal multiplexer
brew "htop"           # process viewer
brew "watch"          # run a command repeatedly
brew "git-delta"      # better git diffs
brew "lazygit"        # terminal git UI
brew "direnv"         # per-directory env vars
brew "openssh"        # ssh client/server
brew "gnupg"          # GPG signing/encryption

# ----- Shell experience ------------------------------------------------------
brew "starship"               # cross-shell prompt (used instead of an OMZ theme)
# Note: Oh My Zsh + the zsh-autosuggestions / zsh-syntax-highlighting plugins
# are installed by setup.sh (cloned into ~/.oh-my-zsh/custom), not via brew.

# ----- GUI dev apps (casks) --------------------------------------------------
cask "visual-studio-code"   # editor  (swap for "cursor" if you prefer)
cask "iterm2"               # terminal
cask "docker-desktop"       # Docker Desktop (was "docker" — renamed by Homebrew)
cask "postman"              # API client
cask "ghostty"              # fast GPU terminal (optional alt to iterm2)
cask "claude"               # Claude desktop app

# ----- Claude Code sandboxing ------------------------------------------------
# CLI + isolation. Config is applied by claude-code.sh; details in
# claude-sandbox/README.md.
cask "claude-code"          # Claude Code CLI (the `claude` command; cask = manual `brew upgrade`)
cask "sbx"                  # Docker Sandboxes — per-project microVM (the `ccx` command wraps it)

# ----- Everyday apps (casks) -------------------------------------------------
cask "arc"                 # Arc browser
cask "google-chrome"
cask "slack"
cask "discord"
cask "notion"
cask "canva"
cask "1password"           # password manager
cask "raycast"             # spotlight replacement / launcher
cask "loop"                # window management
cask "zoom"
cask "the-unarchiver"

# ----- Fonts -----------------------------------------------------------------
cask "font-jetbrains-mono-nerd-font"   # nice coding font w/ icons (for starship)
cask "font-fira-code-nerd-font"

# ----- Mac App Store apps -----------------------------------------------------
# `mas` installs App Store apps from the CLI. You must be SIGNED IN to the
# App Store app first, or these lines are skipped with a warning.
# Find more IDs with:  mas search "App Name"
brew "mas"
mas "Amphetamine", id: 937984704   # keep-awake utility (App Store only)

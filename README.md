# HwztBrew

One-command setup for a fresh Mac (Apple Silicon / M-series). Installs Homebrew, all my CLI tools, dev apps, and everyday apps, sets up language runtimes, links my dotfiles, and applies sensible macOS defaults.

## Quick start (brand-new Mac — nothing installed)

Open **Terminal** and paste one line:

```sh
curl -fsSL https://raw.githubusercontent.com/AashiqDurga/HwztBrew/main/bootstrap.sh | bash
```

This needs **only `curl`**, which ships with every Mac — no git, no Homebrew, nothing to install first. It downloads the repo as a tarball and runs everything for you.

That's it. It's safe to re-run any time — every step checks before acting and your existing dotfiles are backed up, not overwritten.

> First run may pause to install Xcode Command Line Tools. Finish that dialog, then paste the same line again.

### Alternative: if you already have git

```sh
git clone https://github.com/AashiqDurga/HwztBrew.git ~/HwztBrew
cd ~/HwztBrew && ./setup.sh
```

## What it does

1. **Xcode Command Line Tools** — compilers/git that Homebrew needs.
2. **Homebrew** — installs it if missing (into `/opt/homebrew`).
3. **`brew bundle`** — installs everything in [`Brewfile`](./Brewfile): CLI tools, dev apps, everyday apps, fonts.
4. **Language runtimes** — installs Node (LTS) and Python via [mise](https://mise.jdx.dev).
5. **Dotfiles** — symlinks `.zshrc`, `.gitconfig`, `.aliases` from `dotfiles/` into your home folder.
6. **macOS defaults** — runs [`macos.sh`](./macos.sh): Finder, Dock, keyboard, screenshots, trackpad tweaks.

## Customizing

| Want to change… | Edit |
|---|---|
| Which apps/tools install | `Brewfile` (comment a line to skip, add `brew "x"` / `cask "x"`) |
| Languages installed | the `mise use` lines in `setup.sh` |
| Shell config & aliases | `dotfiles/.zshrc`, `dotfiles/.aliases` |
| Git name/email | `dotfiles/.gitconfig` |
| macOS system tweaks | `macos.sh` |

## After running

- Restart the terminal (or `exec zsh`).
- `gh auth login` to connect GitHub.
- Sign in to 1Password, Slack, Chrome, Spotify, etc.
- Some macOS tweaks need a logout/restart to fully apply.

## Keeping it updated

This lives at [github.com/AashiqDurga/HwztBrew](https://github.com/AashiqDurga/HwztBrew). To change what gets installed, edit the `Brewfile` (or other files), commit, and push:

```sh
cd ~/HwztBrew
git add -A && git commit -m "Update setup" && git push
```

> **Public vs private:** the no-git `curl` one-liner only works while the repo is **public** (the raw URL needs no auth). If you make it private, use the git-clone method instead. Nothing sensitive lives here — secrets stay in 1Password — so public is fine.

On any future Mac, paste the one-liner and walk away.

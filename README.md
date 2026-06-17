# HwztBrew

One-command setup for a fresh Mac (Apple Silicon / M-series). Installs Homebrew, all my CLI tools, dev apps, and everyday apps, sets up language runtimes, links my dotfiles, applies sensible macOS defaults, and sets up a **sandboxed Claude Code environment**.

## Quick start (brand-new Mac — nothing installed)

Open **Terminal** and paste this one line — **do not put `sudo` in front of it.** Homebrew refuses to run as root; the script asks for your password itself, only when it needs it:

```sh
curl -fsSL https://raw.githubusercontent.com/AashiqDurga/HwztBrew/main/bootstrap.sh | bash
```

It needs **only `curl`** (ships with every Mac) — no git, no Homebrew first. It downloads the repo to `~/HwztBrew` and runs the whole setup. **What to expect, in order:**

1. **Your Mac password — once, up front.** Setup asks for your **login password** at the very start (Homebrew and a few apps need admin rights) and keeps it active, so everything after runs unattended. Type it — the screen stays blank as you type, that's normal — and press Return.
2. **Xcode Command Line Tools dialog** *(brand-new Macs only).* A system dialog pops up (compilers/git that Homebrew needs). Click **Install** and accept the licence; the script **waits**, then continues on its own — nothing to re-run.
3. **The long part — unattended.** It installs everything from the [`Brewfile`](./Brewfile), language runtimes, your dotfiles, macOS defaults, and the Claude Code sandbox. Grab a coffee.

Safe to re-run any time — every step checks before acting, and your existing dotfiles are backed up, not overwritten.

> **Stuck at Homebrew with "Need sudo access / stdin is not a TTY"?** You're on an older `bootstrap.sh` that can't pass the password prompt through the `curl | bash` pipe. The repo was still downloaded, so just finish with the local copy:
> ```sh
> cd ~/HwztBrew && ./setup.sh
> ```

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
7. **Claude Code sandbox** — runs [`claude-code.sh`](./claude-code.sh): writes the always-on Bash-sandbox config into `~/.claude/settings.json`. The `claude-code` CLI and Docker Sandboxes (`sbx`) install from the [`Brewfile`](./Brewfile). See [`claude-sandbox/`](./claude-sandbox/) for how it all works, and [Docker Sandboxes docs](https://docs.docker.com/ai/sandboxes/) for the underlying microVM tech.

## Claude Code sandbox

Yes — this repo **also sets up a sandboxed [Claude Code](https://code.claude.com/docs) environment**, so a fresh Mac is ready to run agents safely with no extra config. Two layers, least-privilege:

- **Bash sandbox (always on)** — every host `claude` session runs its shell commands inside macOS Seatbelt, configured in [`claude/settings.json`](./claude/settings.json).
- **Docker Sandboxes (the default)** — the `ccx` command launches Claude inside a disposable, per-project microVM ([`sbx`](https://docs.docker.com/ai/sandboxes/)). Inside it Claude runs **fully autonomous** but can't touch anything outside the project + an allow-listed set of domains. Your usual plugins + MCP servers are auto-loaded into each sandbox.

```sh
cd ~/code/some-project
ccx          # autonomous Claude, isolated in a microVM
```

How it works, the per-project workflow, and customizing the sandbox: **[`claude-sandbox/`](./claude-sandbox/)**.

## Customizing

| Want to change… | Edit |
|---|---|
| Which apps/tools install | `Brewfile` (comment a line to skip, add `brew "x"` / `cask "x"`) |
| Languages installed | the `mise use` lines in `setup.sh` |
| Shell config & aliases | `dotfiles/.zshrc`, `dotfiles/.aliases` |
| Git name/email | `dotfiles/.gitconfig` |
| macOS system tweaks | `macos.sh` |
| Claude Code sandbox rules | `claude/settings.json` (Bash sandbox) · `claude-sandbox/spec.yaml` (Docker Sandbox) |

## After running

- Restart the terminal (or `exec zsh`).
- `gh auth login` to connect GitHub.
- Sign in to 1Password, Slack, Chrome, Spotify, etc.
- Some macOS tweaks need a logout/restart to fully apply.
- **Claude Code sandbox:** `sbx login` (Docker Sandboxes — needs a free Docker account), then `bash claude-sandbox/policy.sh` to set the network policy, then run `claude` once to sign in. Start sandboxed project sessions with `ccx` (autonomous; the kit auto-loads your plugins + MCP servers). First time in each repo, authorize the OAuth MCP servers once. See [`claude-sandbox/README.md`](./claude-sandbox/README.md) for the full per-project workflow (network policy, MCP auth, worktrees, customizing the kit).

## Keeping it updated

This lives at [github.com/AashiqDurga/HwztBrew](https://github.com/AashiqDurga/HwztBrew). To change what gets installed, edit the `Brewfile` (or other files), commit, and push:

```sh
cd ~/HwztBrew
git add -A && git commit -m "Update setup" && git push
```

> **Public vs private:** the no-git `curl` one-liner only works while the repo is **public** (the raw URL needs no auth). If you make it private, use the git-clone method instead. Nothing sensitive lives here — secrets stay in 1Password — so public is fine.

On any future Mac, paste the one-liner and walk away.

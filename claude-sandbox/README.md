# Claude Code sandboxing

Two layers of isolation, both set up by this repo. Use them together:

| Layer | What it isolates | When it applies |
|---|---|---|
| **Bash sandbox** (macOS Seatbelt) | Just Bash commands CC runs | Every host `claude` session — always on via `~/.claude/settings.json` |
| **Docker Sandbox** (`sbx`, microVM) | The whole agent — its own kernel, FS, network | When you start a session with **`ccx`** (your default) |

The Bash-sandbox config lives in [`../claude/settings.json`](../claude/settings.json) and is merged into `~/.claude/settings.json` by [`../claude-code.sh`](../claude-code.sh). This page covers the Docker Sandbox side.

## Mental model

- A **sandbox** is a per-project microVM — think of it as a disposable clone of your Mac. It replaces "my host" as the security boundary.
- A **session** is a `claude` process running inside that sandbox. One sandbox holds many sessions over time, just like your host holds many terminals today.
- Your project directory is **bind-mounted** in (direct mode): the agent edits the real files on your Mac live, but it can't see anything you didn't mount — not `~/.ssh`, not your other repos, not the open internet (egress is allow-listed).

## How it works under the hood

Docker Sandboxes ([`sbx`](https://docs.docker.com/ai/sandboxes/)) runs each sandbox as a **microVM** — its own Linux kernel, filesystem, and network stack, plus its own Docker daemon. The boundary between the agent and your Mac is a hardware-level VM, not just process permissions. The mechanics worth knowing:

- **Workspace = a live bind-mount (direct mode).** Your project dir is mounted read-write; edits the agent makes appear on your host instantly. Nothing else is mounted, so the agent literally can't see `~/.ssh`, other repos, or the rest of your home. (There's also a *clone mode* — repo mounted read-only, agent works on an in-VM copy.)
- **Network is default-deny via a host-side proxy.** Outbound traffic is blocked except the hostnames you allow-list in [`kit.yaml`](./kit.yaml). The proxy matches by hostname and doesn't inspect TLS, so keep the list narrow — a broad domain is a possible exfiltration path.
- **Credentials never enter the VM.** That same proxy holds your tokens and injects them into outbound requests, so a compromised sandbox can't read the raw secret. Claude Code's own session token stays on the host too.
- **Persistent yet disposable.** Named sandboxes (what `ccx` makes) keep their state — packages, auth, config — across runs; `sbx rm` throws one away without touching your host files.

For the full detail, see Docker's [security & isolation model](https://docs.docker.com/ai/sandboxes/security/) and the [Claude Code comparison of sandbox approaches](https://code.claude.com/docs/en/sandbox-environments) (Bash sandbox vs. dev container vs. microVM). More links at the [bottom](#learn-more).

## Everyday workflow

`claude` stays the raw host binary (Bash-sandbox protected, prompts on). The default is **`ccx`** — a shell function (in [`../dotfiles/.aliases`](../dotfiles/.aliases)) that runs Claude inside a per-project Docker Sandbox, **fully autonomous**:

```sh
cd ~/code/my-project
ccx          # = sbx run --kit <kit> --name my-project claude --dangerously-skip-permissions
```

`ccx` automatically applies the kit — a project-local `./claude-sandbox/` if the repo has one, otherwise the **global** kit that setup installs to `~/.config/claude-sandbox/`. That's what brings your plugins, MCP servers, and network allowlist into every sandbox without copying anything per-project.

`ccx` runs with `--dangerously-skip-permissions` on purpose: the microVM is the safety boundary, so Claude works without permission prompts. That's the whole reason to use Tier 3 — let it go. It's contained, **not** risk-free:

- The mounted project is your **real code on the host** — the agent can rewrite it. It's all git; review the diff and revert.
- It can exfiltrate **what's in the sandbox** (your project) via any **allowed** domain — keep [`kit.yaml`](./kit.yaml)'s allowlist narrow.

It can't touch anything outside the mounted project + allowed domains (not `~/.ssh`, not other repos, not the open internet). For a one-off run *with* prompts, use `CCX_PROMPT=1 ccx`.

`ccx` names the sandbox after the git repo, so re-running it **reuses** the same VM (installed packages, auth, and config persist) instead of creating a new one. Run `ccx` again from another terminal for a second session in the same sandbox.

To tear a sandbox down: `sbx rm my-project` (your files on the host are untouched).

## Authenticating once (not every session)

Secrets live on your **host** and are injected by a proxy — they never enter the VM — so you don't re-auth on each run:

- **Claude Code itself:** sign in once with `claude` (or generate a long-lived token via `claude setup-token` and store it as an `sbx` secret). The session token stays on the host.
- **MCP servers that need an API key:** register once, reused by every sandbox:
  ```sh
  sbx secret set-custom -g --host api.example.com --env EXAMPLE_TOKEN --value "$KEY"
  ```

## MCP servers in the sandbox

An MCP server is **config + binary + network + secret**, and each lives on a different side:

| Piece | Where it goes |
|---|---|
| Which servers to launch | a project-scoped **`.mcp.json`** at your repo root (travels with the bind-mounted workspace) |
| The server's binary/runtime (node, `uvx`, …) | the kit — `commands.install` in [`kit.yaml`](./kit.yaml), or a template image |
| The domains it calls | `network.allowedDomains` in `kit.yaml` (default-deny egress) |
| Its API key | `sbx secret set-custom` / `environment.proxyManaged` |

So: declare the server in `.mcp.json`, make sure the kit installs its runtime, allow-list its API host, and register its key as a secret. Then `ccx` "just works" with MCP and no prompts.

### Your replicated setup

The [`kit.yaml`](./kit.yaml) installs the host's tooling inside a sandbox at **user scope** (so it's there for every session in that project) **automatically on first creation**. [`setup-claude.sh`](./setup-claude.sh) is the identical set of commands as a manual fallback — run it once inside a sandbox if the kit step didn't take (the named sandbox keeps the result):

```sh
bash claude-sandbox/setup-claude.sh
```

Both install:

- **Plugins** (official marketplace): `claude-md-management`, `frontend-design`, `context7`, `superpowers`, `feature-dev`, `code-simplifier`, `ralph-loop`, `playwright`, `security-guidance`, `serena`.
- **MCP servers**: `supabase`, `vercel`, `clerk`, `linear-server`, `notion` (remote/OAuth) and `trigger` (stdio via npx). `context7` and `serena` come from their plugins, so they aren't added twice.

**One-time per project:** on your first `ccx` in a repo, run `claude` and authorize each remote server when prompted (supabase, vercel, clerk, linear, notion). Because the sandbox is named + persistent, you won't be asked again for that project — that's the "per-project" auth model.

**Known gaps / first-run tuning** (this hasn't been run against a live sandbox yet):

- **`vercel-plugin`** isn't auto-installed — on the host its marketplace came from a local directory, not a public URL. The Vercel **MCP server** still gives the agent Vercel access; add the plugin manually if you want its skills too.
- **`playwright`** needs browser dependencies in the image to actually drive a browser — add them to the kit if you use it.
- **OAuth redirects** may hit a provider host not in the allowlist on first authorize; the [`kit.yaml`](./kit.yaml) `network` block notes which to add.

## Git worktrees

Only the directory you mount is visible in the sandbox — parent dirs are **not** pulled in. A worktree created at a **sibling** path (`../feature`) lands only inside the VM (and its `.git` pointer can't resolve). To keep worktrees on your host, either:

- create them **inside** the repo: `git worktree add .worktrees/feature`, or
- mount the **parent** explicitly: `sbx run --name proj <parent-dir> claude` so siblings fall inside a mounted path.

## Customizing the environment

Edit [`kit.yaml`](./kit.yaml): add tools under `commands.install`, allow-list domains under `network.allowedDomains`, swap the base image. Validate with `sbx kit validate ./claude-sandbox/`, then `sbx run --kit ./claude-sandbox/ --name <project> claude`.

## Learn more

**Docker Sandboxes — the `sbx` microVM (this Tier):**

- [Docker Sandboxes overview](https://www.docker.com/products/docker-sandboxes/) — what it is and why it exists
- [Docs · Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) — install, usage, sandbox lifecycle
- [Docs · Customize (kits & templates)](https://docs.docker.com/ai/sandboxes/customize/) — the `kit.yaml` schema this folder uses
- [Docs · Security & isolation](https://docs.docker.com/ai/sandboxes/security/) — the microVM boundary and credential proxy

**Claude Code sandboxing — how the tiers compare:**

- [Choosing a sandbox environment](https://code.claude.com/docs/en/sandbox-environments) — Bash sandbox vs. dev container vs. microVM
- [The built-in Bash sandbox](https://code.claude.com/docs/en/sandboxing) — what [`../claude/settings.json`](../claude/settings.json) configures (Tier 1)
- [Dev containers](https://code.claude.com/docs/en/devcontainer) — the Docker + firewall alternative

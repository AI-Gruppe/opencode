# opencode — shared company configuration

The global [opencode](https://opencode.ai) configuration for AI-Gruppe: the two internal MCP
servers, the global git workflow rules, and two versioned skills.

Everything here is **global**. It lives in `~/.config/opencode/` and therefore applies in every
project directory. No repo needs its own `.opencode/` directory, and none should have one.

---

## Getting started

**No terminal, AI or opencode experience assumed.** Work through the nine steps below in order
and you end up with an assistant in your terminal that can read and write company tickets in
yggdrasil, and that remembers what you did in earlier sessions.

The *terminal* is the app called **Terminal** (macOS) or **Console/Terminal** (Linux). "Run a
command" means: copy the line, paste it into that window, press Enter, wait for it to finish.
Lines starting with `#` are comments — you can paste them along, they do nothing.

Expect about 15 minutes, most of it waiting for downloads.

### 1. Prepare the system — `git`, `curl` and Node

**macOS:**

```bash
xcode-select --install          # git + curl; a dialog opens, click Install. Already there? It says so.
brew install node               # Node and npm, needed in step 5
```

No `brew`? Install [Homebrew](https://brew.sh) first, then run the line above.

**Ubuntu / Debian:**

```bash
sudo apt update
sudo apt install -y git curl nodejs npm
```

Check that all three answer with a version number:

```bash
git --version && curl --version | head -1 && node --version
```

### 2. Install opencode

```bash
curl -fsSL https://opencode.ai/install | bash
```

This downloads opencode into `~/.opencode/bin` and adds that folder to your `PATH` by editing
your shell config (`.zshrc` on macOS, `.bashrc` on most Linux).

**Now close the terminal window and open a new one** — the `PATH` change only applies to
terminals started afterwards. Then check:

```bash
opencode --version              # expect 1.18.18 or newer
```

### 3. Clone this repo into `~/.config/`

The repo is public, so this needs no GitHub account and no login:

```bash
git clone https://github.com/AI-Gruppe/opencode.git ~/.config/opencode
```

Check that it landed:

```bash
ls ~/.config/opencode           # expect: AGENTS.md  README.md  check.sh  opencode.json  skills
```

> If `~/.config/opencode` already exists (opencode may have created it), `clone` refuses to
> write into it. See [If `~/.config/opencode` already exists](#if-configopencode-already-exists).

### 4. Let opencode download its plugins

```bash
opencode models
```

A long list of model names scrolling past means it worked. On the way, opencode fetched the two
plugins named in `opencode.json` into `~/.cache/opencode/packages/`.

### 5. Install cavemem and ponytail

```bash
npm install -g cavemem
npm install -g @dietrichgebert/ponytail
```

`cavemem` is a real command-line program that opencode starts as a memory server, so it has to
be installed globally. `ponytail` is a plugin opencode already downloaded for itself in step 4 —
installing it globally does no harm and makes it available to other tools, but opencode does not
need it.

Check:

```bash
cavemem doctor                  # expect a line reading: ides: opencode
```

### 6. Sign in to an AI provider

*(Not in the original checklist, but nothing works without it.)* This configuration deliberately
pins **no** model, so each machine brings its own:

```bash
opencode auth login
```

Pick your provider from the list and follow the prompt — either a browser login or an API key to
paste. Ask whoever handed you your provider account which one to choose. See
[Models](#models) for why this is not decided for you here.

### 7. Connect to yggdrasil

```bash
opencode mcp auth yggdrasil
```

Your browser opens on the company Keycloak login page.

1. Choose **Sign in with Google**.
2. Pick your company Google account.
3. Approve the access request.
4. The page says you can close the tab — do that and go back to the terminal, which now reports
   success.

Check:

```bash
opencode mcp list               # expect cavemem and yggdrasil, both connected
```

> If this fails with a client-registration or "Trusted Hosts" error, nothing on your machine is
> wrong — the Keycloak realm has to allow the client. Ask the team; see
> [yggdrasil](#yggdrasil--the-internal-api-wired-as-remote-mcp).

### 8. Done

Everything is installed and connected. There is nothing to repeat on this machine; from now on
you just run `opencode`. To pick up later changes to this configuration:

```bash
git -C ~/.config/opencode pull
```

### 9. Your first conversation — tickets

Go into any folder you want to work in and start it:

```bash
cd ~/projects/some-project      # or anywhere, even your home folder
opencode
```

You now type in plain language — English or German, full sentences, no special syntax. Try one
of these:

**Create a ticket**

```
Create a ticket in yggdrasil: the printer in the Hamburg office jams on
double-sided printing. Normal priority.
```

**List tickets**

```
List the open yggdrasil tickets and show me title, status and who they are assigned to.
```

**Read one ticket**

```
Show me yggdrasil ticket 412 — the full description and all its messages.
```

**Follow up on one**

```
Add a message to ticket 412 saying the replacement part was ordered, then set it to in progress.
```

What to expect while it works:

- opencode shows you the tool it wants to use (for example `yggdrasil_tickets_create_ticket`)
  and, for anything that changes something or runs a command on your machine, asks you to
  approve it first. Nothing happens behind your back.
- The reply appears in the terminal. Keep asking follow-up questions in the same session — it
  remembers the conversation, and thanks to cavemem it can recall earlier sessions too.
- Type `/` to open the command list inside opencode — starting a new session, undoing the last
  change it made to your files, and leaving are all in there.

If an answer mentions that yggdrasil is unavailable, re-run step 7 — the login expires.

---

## What is in here

| | |
|---|---|
| **MCP** | `cavemem` — cross-session persistent memory; `yggdrasil` — the internal API, over OAuth |
| **Plugins** | `opencode-readseek` — structural code navigation; `@dietrichgebert/ponytail` — the [ponytail](#ponytail--the-house-style) ruleset and its slash commands |
| **Skills** | `simplify`, `verification-planning` |
| **Rules** | The git workflow every session follows, via `AGENTS.md` |
| **Models** | Not pinned. Use whatever provider you are authenticated against — see [Models](#models) |

This is a subset of a personal config. The model provider in it was a single self-hosted box,
and it carried restrictions that only made sense on that box; none of that is here. See
[What was left out](#what-was-left-out).

---

## Layout

**This repo is checked out *as* `~/.config/opencode/`** — not copied there, not symlinked into
it. The directory opencode reads at startup is the git working tree, so every path below is
both a repo path and a live path:

```
~/.config/opencode/          ← the working tree; .git/ lives here
├── opencode.json            plugin, MCP servers, bash permissions
├── AGENTS.md                global rules loaded into every session
├── skills/                  simplify, verification-planning
├── check.sh                 the invariants; run it after any change
└── README.md                this file
```

Updating on any machine is therefore one command, with no copy step and nothing to drift:

```bash
git -C ~/.config/opencode pull
```

`.gitignore` **denies by default** (`/*`) and allow-lists the configuration. opencode writes
`node_modules/`, `package.json` and its credential store into this same directory at runtime; a
deny-list would have to be extended every time it starts writing something new, and a
credential one `git add -A` away from a commit is not a risk worth carrying.

---

## If `~/.config/opencode` already exists

opencode creates `~/.config/opencode/` on its first run, and `git clone` refuses a non-empty
directory. Attach git to the directory instead of cloning into it:

```bash
cd ~/.config/opencode
git init
git remote add origin https://github.com/AI-Gruppe/opencode.git
git fetch origin
git checkout -t origin/main -f     # -f: opencode's own files are ignored, not clobbered
```

Verify the result, on any machine:

```bash
./check.sh           # all invariants
cavemem doctor       # expect: ides: opencode
opencode mcp list    # cavemem and yggdrasil, both connected
```

Tested against opencode **1.18.18** and cavemem **0.2.1**.

---

## cavemem — memory, wired as MCP

cavemem is an **MCP server**, not a plugin. Its npm package exports a CLI, so listing it under
`"plugin"` cannot work. The correct wiring is already in `opencode.json`:

```json
"mcp": {
  "cavemem": { "type": "local", "command": ["cavemem", "mcp"], "enabled": true }
}
```

Verify with `cavemem doctor` — expect `ides: opencode`.

> ⚠️ **Do not run `cavemem install --ide opencode` over this.** As of cavemem 0.2.1 that
> installer writes an `mcpServers` key into `~/.opencode/config.json` — both the wrong key and
> the wrong path for opencode 1.x. It will not work, and it will not replace the block above.

---

## yggdrasil — the internal API, wired as remote MCP

The second MCP server is remote rather than a subprocess, and authenticates with OAuth against
the Keycloak realm in front of the API:

```json
"yggdrasil": {
  "type": "remote",
  "url": "https://yggdrasil-api.gruppe.ai/mcp",
  "enabled": true,
  "oauth": {
    "clientId": "yggdrasil-mcp",
    "scope": "openid profile",
    "callbackPort": 19876,
    "redirectUri": "http://127.0.0.1:19876/mcp/oauth/callback"
  }
}
```

**The oauth keys are camelCase, and that is not cosmetic.** opencode's published schema declares
`McpOAuthConfig` as exactly `clientId`, `clientSecret`, `callbackPort`, `redirectUri`, `scope`,
with `additionalProperties: false`. A snake_case key does not fail loudly — it is dropped, and
the client quietly runs on its defaults. Written as `client_id` / `callback_port` /
`redirect_uri`, three of those four settings do nothing at all, while `scope` appears to work
purely because the two spellings coincide. camelCase has been the spelling since at least
opencode 1.16, so no version bump addresses it. Check 9 in `check.sh` is what stops the next
hand-written oauth block from no-opping the same way.

Correct key names are necessary, not sufficient. Authentication additionally requires the
Keycloak realm to accept the client; a dynamic client-registration attempt has been rejected by
a **Trusted Hosts** policy before, which is server-side and untouched by anything in this repo.
**End-to-end auth is not verified here** — if `/mcp` shows yggdrasil failing to authenticate,
that is the realm, not this config.

---

## ponytail — the house style

`@dietrichgebert/ponytail` (MIT) is a prompt-level plugin, not a tool provider: it appends the
ponytail ruleset — *the best code is the code never written* — to the system prompt on every
turn, and registers six slash commands plus a skills directory from its own package. It adds no
tools, so the tool surface is unchanged.

| It registers | |
|---|---|
| Commands | `/ponytail`, `/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`, `/ponytail-help`, `/ponytail-review` |
| Skills | supplied from the package's own `skills/` directory, on top of the two versioned here |

Intensity is `lite` / `full` / `ultra`, `full` by default, switched with `/ponytail <level>` and
turned off with `/ponytail off`. The level persists in `~/.config/opencode/.ponytail-active`,
which is written into this working tree but never tracked — the deny-by-default `.gitignore`
covers it — so it is per-machine and does not travel with `git pull`.

It is the one plugin here that does not follow the `opencode-*` naming, because the same package
also ships Claude Code, Codex and pi integrations. That is why check 5 accepts the
`opencode-plugin` npm keyword as proof.

---

## Models

`opencode.json` pins **no model and no provider**, deliberately: this config is shared, and a
provider block naming one machine's endpoint is unusable to everyone else. Authenticate with
whatever you use (`opencode auth login`) and set your default per machine — a `model` key in a
local, untracked override, or simply `/model` in the session.

Check 4 fails if a provider block or a loopback/private-network endpoint is committed here.

---

## Skills

Two skills, versioned in this repo because no plugin installs them:

| Skill | What it is for |
|---|---|
| `simplify` | Reduce complexity without changing behavior, after the behavior is understood. |
| `verification-planning` | Build a project-specific evidence path before a non-trivial change, so "it works" has something behind it. |

Add one as `skills/<name>/SKILL.md` with `name:` and `description:` frontmatter; check 6 enforces
both.

---

## Git workflow rules — global `AGENTS.md`

`AGENTS.md` is loaded into every session in every directory: branch from `main`, conventional
commit messages, PR, squash merge, delete the branch, never push to `main`. It is the same
workflow this repo itself uses.

---

## Verification

`./check.sh` asserts the invariants. It runs in CI (`.github/workflows/check.yml`) on every push
and pull request, and locally in seconds:

| # | Check | The failure it exists for |
|---|---|---|
| 1 | No secret-shaped file and no bearer token is tracked | git lives in the directory opencode writes its credential store into |
| 2 | `opencode.json` and `AGENTS.md` sit at repo root, nothing under `config/` | the tree has to map 1:1 onto `~/.config/opencode/` |
| 3 | Every tracked `.json` parses | a broken `opencode.json` fails opaquely at startup |
| 4 | No custom provider, no loopback/private endpoint | a shared config that names one machine's box is unusable for everyone else |
| 5 | Every `plugin[]` entry is named `opencode-*` / `*-opencode-plugin`, or declares the `opencode-plugin` npm keyword | plugin entries are npm specs opencode fetches and **executes**; invented names resolve to unrelated packages |
| 6 | Skills are tracked and carry valid frontmatter | a skill without frontmatter is silently not a skill |
| 7 | No agent is disabled | the config this was derived from disabled `explore` and `general` for a single-GPU constraint that is not the company's |
| 8 | `cavemem` and `yggdrasil` are both present and enabled | they are the point of this config |
| 9 | Every `mcp.*.oauth` key is one of `McpOAuthConfig`'s five | opencode drops unknown keys in silence |

---

## What was left out

Deliberately not in here — most of it never carried over from the personal config this
derives from, and one item was pulled once the repo went public:

| Left out | Why |
|---|---|
| The `atlas` provider and its six model pins | One self-hosted box on a private address, behind an API key. Unreachable and useless to anyone else. |
| `agent.explore.disable` / `agent.general.disable` | Those subagents were disabled because that box runs `llama-server --parallel 1` — one KV slot, so a second prompt prefix evicts the first. Irrelevant on a hosted provider, so both stay dispatchable. Check 7 keeps it that way. |
| `codebase-index.json` | Points at an embeddings endpoint on `127.0.0.1:8081` that nothing serves. |
| `oh-my-opencode-slim.json` | Config for a plugin that is not installed, and its preset names atlas models. |
| `docs/atlas` submodule | A private personal repo. |
| `deploy-to-k8s` skill | An internal infrastructure map — registry host, cluster namespaces, kubeconfig path, Argo app names. This repo is public. It lives in an internal repo instead. |

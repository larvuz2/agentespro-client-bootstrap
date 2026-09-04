# agentesPRO Core VPS — Replication Runbook

Paste this as the FIRST message to the Hermes agent on a fresh VPS.
It rebuilds the agentesPRO core: one main "Chief of Staff" profile that knows everything and orchestrates, plus the integrations, portal, and workers that make it useful.

Source of truth: Larvuz VPS (`187.77.198.159`), audited 2026-09-04. Hermes Agent v0.21.0.

---

## 0. Instructions to the agent (read first)

You are bootstrapping a new agentesPRO core server. Rules:

- Work top to bottom. Do not skip phases. Mark each checklist item ✅ / ⏭ (skipped, with reason) / ❌ (blocked, with the error).
- Never invent secrets. Every `<...>` placeholder is a value the human pastes to you. Ask for them in ONE batch per phase, not one at a time.
- Never print full API keys, tokens, `.env`, or `auth.json` contents back to chat. Confirm with key names only.
- Verify every service with a real command (`systemctl`, `curl`, CLI `--version`) before marking done.
- Report at the end of every phase: what is live, what is blocked, what you need.
- Do not send any email, post, or external message during bootstrap.

---

## 1. What we are replicating (architecture)

```text
                 ┌──────────────── VPS (Ubuntu 24.04, root) ────────────────┐
  Telegram ──▶   │  hermes-gateway-<main>.service   (Chief of Staff profile)│
  Discord  ──▶   │      ├─ OpenRouter (default model)                       │
  WebUI    ──▶   │      ├─ FAL plugins (image_gen/fal, video_gen/fal)       │
                 │      ├─ MCP: x-mcp-server, lovable (oauth)               │
                 │      ├─ Monid CLI  (structured data endpoints)           │
                 │      ├─ EXA        (people/company research)             │
                 │      ├─ gws        (Google Workspace, per-account tokens) │
                 │      ├─ gh         (GitHub)                              │
                 │      ├─ browse     (Browser Use / Browserbase)           │
                 │      ├─ Hermies plugin (agent network)                   │
                 │      └─ skills library (custom agentesPRO skills)        │
                 │                                                          │
                 │  agentespro-webui.service  :8791  ─┐                     │
                 │  agentespro/agent-desktop  docker  ├─ Caddy ─▶ HTTPS     │
                 │  hermes dashboard          :9119  ─┘  portal.<domain>    │
                 │  Hermes API server (Responses API) → app integrations    │
                 │  Postgres 16 (Hermies pilot / optional)                  │
                 │  Obsidian vault (company memory)                         │
                 └──────────────────────────────────────────────────────────┘
```

Layers, in build order:

1. OS + toolchain
2. Hermes Agent core + main profile (Chief of Staff)
3. Secrets (`.env`)
4. Integrations: OpenRouter, FAL, EXA, Monid, GitHub, Google Workspace, X MCP, Browser, Resend, MiniMax
5. Messaging gateways: Telegram (+ Discord optional)
6. Skills library (custom agentesPRO skills)
7. WebUI Portal + Agent Marks + Agent Desktop containers + Caddy
8. Hermes API server (for app/MCP integrations like Phatty/ShotForge, Lovable dashboards)
9. Memory / vault / bootstrap docs
10. Cron baseline
11. Worker profiles (optional, later)
12. Acceptance checklist

---

## 2. Repos to clone (all under `larvuz2` unless noted)

Core (required):

- `larvuz2/agentespro-hermes-webui` → `/root/agentespro-hermes-webui` — portal, Agent Marks (`static/agent_marks.js`), agent-desktop Docker image (`computer/`), deploy kit (`deploy/`).
- `larvuz2/agentespro-client-bootstrap` → `/root/agentespro-client-bootstrap` — bootstrap instructions, templates, this runbook.
- `DataWhisker/x-mcp-server` → `/root/mcp-servers/x-mcp-server` — X/Twitter MCP (build with `npm i && npm run build`).

Core agents / orchestration (required for the "knows everything" profile):

- `larvuz2/cto-agentespro` → `/root/cto-agentespro` — CTO crew harness.
- `larvuz2/mkt-agentespro` → `/root/mkt-agentespro` — marketing crew harness.
- `larvuz2/agentespro-agent-marks` → `/root/agent-marks` — Agent Marks source/preview.
- `larvuz2/agentespro-hermes-console-template` → `/root/agentespro-hermes-console-template`.

Platform surfaces (nice to have):

- `larvuz2/hermies-and-friends` → `/root/hermies-and-friends` — Hermies network layer (needs Postgres/pgvector + nginx/Caddy route).
- `larvuz2/larvuz-control-room` → `/root/larvuz-control-room` — control-room dashboard.
- `larvuz2/agentesprolrvz` → `/root/agentesprolrvz` — agentesPRO landing.
- `larvuz2/ai-agents-landing`, `larvuz2/living-todo-dashboard`, `larvuz2/presentations` — optional.

Not on GitHub yet (must be exported from the Larvuz VPS — see Phase 6 and 9):

- `/root/.hermes/skills/` custom skills (NOT a git repo today — this is the biggest gap).
- Profile `SOUL.md` files and `profile.yaml` per profile.
- Obsidian vaults (`/root/obsidian-vaults/gus-garza`, `/root/obsidian-vaults/slopia-agent`).
- `/root/AI_OS_MASTER_ROUTER.md`.
- Google OAuth client secrets + tokens (`/root/.hermes/google-accounts/*`).
- Monid config (`~/.config/monid/config.yaml`, `credentials.yaml`).

---

## 3. Secrets checklist (paste to agent as one batch, names only listed here)

Hermes core `.env` (`/root/.hermes/.env`):

- `OPENROUTER_API_KEY` — default model provider.
- `FAL_KEY` — image/video generation, background removal.
- `EXA_API_KEY` — research.
- `GITHUB_TOKEN` — repo access (also `gh auth login`).
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `TELEGRAM_HOME_CHANNEL`, `TELEGRAM_ENABLED=true`
- `DISCORD_BOT_TOKEN`, `DISCORD_ALLOWED_USERS` (optional)
- `BROWSER_USE_API_KEY` (+ `BROWSERBASE_*` optional)
- `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `RESEND_REPLY_TO` — outbound email (send only with written confirmation).
- `MINIMAX_API_KEY` — optional model/media provider.
- `HERMIES_API_KEY` — Hermies network.
- `API_SERVER_ENABLED=true`, `API_SERVER_HOST=127.0.0.1`, `API_SERVER_PORT=<port>`, `API_SERVER_KEY=<random>`, `API_SERVER_CORS_ORIGINS`
- X/Twitter (for x-mcp-server): `TWITTER_API_KEY`, `TWITTER_API_SECRET`, `TWITTER_ACCESS_TOKEN`, `TWITTER_ACCESS_SECRET`, `TWITTER_BEARER_TOKEN`, `TWITTER_CLIENT_ID`, `TWITTER_CLIENT_SECRET`, `TWITTER_OAUTH2_ACCESS_TOKEN`, `TWITTER_OAUTH2_REFRESH_TOKEN`, `X_BEARER_TOKEN`
- `OBSIDIAN_VAULT_PATH=/root/obsidian-vaults/<company>`
- Optional: `CONTROL_WEBHOOK_URL`, `CONTROL_WEBHOOK_KEY` (Grok Chief bridge), `PHATTY_SCHEDULE_URL`, `AGENTESPRO_CLEANUP_CRON_SECRET`.

Portal env (`/etc/agentespro-webui.env`): `HERMES_WEBUI_PASSWORD`, `HERMES_WEBUI_GATEWAY_API_KEY` (= `API_SERVER_KEY`), `HERMES_WEBUI_GATEWAY_BASE_URL`, `HERMES_WEBUI_GATEWAY_PROFILE_URLS`.

Files (not env): Google `google_client_secret.json` per account, Monid API key (`monid keys add`), Lovable MCP via OAuth in-browser.

---

## 4. Phase-by-phase build

### Phase 1 — OS + toolchain

```bash
apt update && apt upgrade -y
apt install -y git curl wget unzip build-essential python3 python3-venv docker.io caddy postgresql-16 ffmpeg jq
systemctl enable --now docker caddy
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt install -y nodejs   # Node 22
curl -LsSf https://astral.sh/uv/install.sh | sh                                       # uv
(type -p gh >/dev/null) || (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && apt update && apt install -y gh)
```

Checklist:
- [ ] `node -v` → v22.x, `python3 --version` → 3.11+, `docker ps`, `caddy version`, `gh --version`, `uv --version`, `ffmpeg -version`
- [ ] Hostname set, timezone set, swap ≥ 4 GB, ufw allowing 22/80/443 only.

### Phase 2 — Hermes Agent core + main profile

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash   # or follow current docs
hermes --version
hermes setup   # provider: openrouter; default model: anthropic/claude-fable-5.1 (or current best)
```

Create the main profile (Chief of Staff). Name pattern: `<company>-hq` (Larvuz uses `agentespro-hq`).

```bash
hermes profile create <company>-hq
```

Then write `/root/.hermes/profiles/<company>-hq/SOUL.md` from the template in `agentespro-client-bootstrap/templates/` (chief-of-staff role: knows all projects, routes to crews, protects approvals, speaks in the owner's voice). Copy `config.yaml` essentials from the Larvuz `default` profile: `plugins.enabled: [image_gen/fal, video_gen/fal, hermies, humalike, platforms/a2a]`, `mcp_servers`, `cron`, `kanban`, `approvals`.

Checklist:
- [ ] `hermes --version` OK
- [ ] `hermes profile list` shows `<company>-hq`
- [ ] `SOUL.md` written and reviewed by human
- [ ] `hermes chat -p <company>-hq "say hi"` returns a model reply via OpenRouter

### Phase 3 — Secrets

Ask the human for the Phase 3 batch (Section 3). Write `/root/.hermes/.env` (chmod 600). Profiles inherit; only override per profile when the bot/token differs (e.g. per-profile `TELEGRAM_BOT_TOKEN`, `API_SERVER_PORT`).

- [ ] `.env` present, 600 perms, no key printed to chat
- [ ] `hermes doctor` (or equivalent) reports providers OK

### Phase 4 — Integrations

FAL (images, video, background removal):
- [ ] plugins `image_gen/fal`, `video_gen/fal` enabled in profile config
- [ ] test: generate one 512px image, confirm file path

EXA:
- [ ] `EXA_API_KEY` set; test `web_search` on a company name

Monid:
```bash
npm install -g @monid-ai/cli@latest
monid setup --client <company>
monid keys add -k <api-key> -l main   # human creates at https://app.monid.ai/access/api-keys
monid --version && monid keys list
curl -fsSL https://monid.ai/SKILL.md -o /root/.hermes/skills/research/monid/SKILL.md
```
- [ ] `NO_COLOR=1 monid discover -q "company enrichment" -j` returns endpoints

GitHub:
- [ ] `gh auth login` (token) → `gh auth status` OK; `git config user.name/email`

Google Workspace (`gws` CLI):
```bash
npm install -g @googleworkspace/cli   # confirm current package name in docs
mkdir -p /root/.hermes/google-accounts/{personal,<company>}
# human uploads google_client_secret.json per account; run gws auth login per account
```
- [ ] `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/root/.hermes/google-accounts/<company>/google_token.json gws drive files list --params '{"pageSize":3}'` works

X MCP:
```bash
mkdir -p /root/mcp-servers && git clone https://github.com/DataWhisker/x-mcp-server /root/mcp-servers/x-mcp-server
cd /root/mcp-servers/x-mcp-server && npm i && npm run build
```
config.yaml:
```yaml
mcp_servers:
  x:
    command: bash
    args: ["-lc", "set -a; source /root/.hermes/.env; set +a; exec node /root/mcp-servers/x-mcp-server/build/index.js"]
    timeout: 180
    connect_timeout: 90
    enabled: true
  lovable:
    url: https://mcp.lovable.dev
    auth: oauth
    oauth: { client_name: "Hermes Agent - <company>", redirect_port: 0 }
    enabled: true
```
- [ ] `mcp__x__get_user` on the company handle works
- [ ] Lovable OAuth completed via browser (optional)

Browser:
```bash
npm install -g @browser-use/cli   # `browse --version` → 0.8.x
```
- [ ] `BROWSER_USE_API_KEY` set; `browse` opens a page

Email (Resend): outbound only, written confirmation required before any send.
- [ ] keys present; no test send without approval

### Phase 5 — Messaging gateways

```bash
# systemd unit per profile (pattern from Larvuz):
cat > /etc/systemd/system/hermes-gateway-<company>-hq.service <<'EOF'
[Unit]
Description=Hermes Agent Gateway - <company>-hq
After=network-online.target
[Service]
User=root
WorkingDirectory=/root/.hermes/profiles/<company>-hq
Environment="HOME=/root" "HERMES_HOME=/root/.hermes/profiles/<company>-hq" "HERMES_SUPERVISED_CHILD=1"
Environment="PATH=/usr/local/lib/hermes-agent/venv/bin:/usr/local/lib/hermes-agent/node_modules/.bin:/root/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/lib/hermes-agent/venv/bin/python -m hermes_cli.main --profile <company>-hq gateway run
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now hermes-gateway-<company>-hq
```
- [ ] Telegram bot created (@BotFather), token in profile `.env`, `TELEGRAM_ALLOWED_USERS` = owner ID
- [ ] Home channel set; bot answers a DM
- [ ] Discord bot (optional) invited, read/participate only, no admin perms

### Phase 6 — Skills library (custom agentesPRO skills)

Today the custom skills live only on the Larvuz VPS in `/root/.hermes/skills/` (not versioned). Two options:

A. Export from Larvuz VPS (fast):
```bash
# on Larvuz VPS
tar czf /root/agentespro-skills-$(date +%F).tgz -C /root/.hermes skills
# scp to new VPS, then:
tar xzf agentespro-skills-*.tgz -C /root/.hermes
```

B. Preferred long-term: publish a private repo `larvuz2/agentespro-hermes-skills` from `/root/.hermes/skills` and `git clone` it into `/root/.hermes/skills` on every new VPS. (Action item for Larvuz VPS — not done yet.)

Baseline skills the Chief of Staff must have (from Larvuz):
- `chief-of-staff-agentespro`, `agentespro-platform-operations`, `agentespro-playbooks`, `agentespro-lovable-connector`, `hermes-webui-portal-operations`, `agent-identity-ui`, `cron-message-style`
- `monid`, `agency-lead-research`, `competitor-news-monitor`, `grounded-citations`, `market-agent-operations`
- `creative-media-generation`, `techhalla-cinematic-prompting`, `visual-artifact-design`, `public-static-web-publishing`, `client-proposal-deck-scoping`
- `document-and-knowledge-workflows`, `email-operations`, `email-inbox-triage`, `telegram-pdf-file-sharing`, `weekly-review-planning`
- `hermes-agent`, `hermes-plugin-operations`, `agent-work-queue-operations`, `cheap-hermes-automation-pipelines`, `cross-agent-command-bridges`, `dynamic-workflow-harnesses`
- `cto-agentespro`, `mkt-agentespro`, `software-development-lifecycle`, `github-workflows`
- `phatty-hermes-gateway` (only if the company uses the Phatty/ShotForge app bridge)

- [ ] skills dir populated; `hermes skills list` shows them
- [ ] company-specific values inside skills replaced (domains, IPs, folder IDs)

### Phase 7 — WebUI Portal + Agent Marks + Agent Desktop + Caddy

```bash
git clone https://github.com/larvuz2/agentespro-hermes-webui.git /root/agentespro-hermes-webui
cd /root/agentespro-hermes-webui
./deploy/install.sh --domain portal.<company-domain>
grep HERMES_WEBUI_PASSWORD /etc/agentespro-webui.env   # share with human privately
```

Portal env additions (Larvuz production):
```text
HERMES_HOME=/root/.hermes
HERMES_WEBUI_STATE_DIR=/root/.hermes/webui-portal
HERMES_WEBUI_HOST=127.0.0.1
HERMES_WEBUI_PORT=8791
HERMES_WEBUI_SKIP_ONBOARDING=1
HERMES_WEBUI_CHAT_BACKEND=gateway
HERMES_WEBUI_GATEWAY_BASE_URL=http://127.0.0.1:<API_SERVER_PORT>
HERMES_WEBUI_GATEWAY_API_KEY=<API_SERVER_KEY>
HERMES_WEBUI_GATEWAY_PROFILE_URLS=<company>-hq=http://127.0.0.1:<port>;...
HERMES_WEBUI_GATEWAY_USE_RUNS_API=1
```
Rule: each portal profile must talk to its OWN gateway runtime (real credentials, model, session continuity). Never let all profiles resolve to `default`.

Agent Marks: shipped inside the repo (`static/agent_marks.js`) — minimal SVG bodies, flat color, 1–3 eyes, editable per profile. No extra copy needed. Preview repo: `larvuz2/agentespro-agent-marks`.

Agent Desktop (manual login / 2FA for the agent):
```bash
cd /root/agentespro-hermes-webui/computer && docker build -t agentespro/agent-desktop:latest .
mkdir -p /root/.hermes/webui-portal/computers/profiles/<company>-hq /etc/caddy/computers
docker run -d --name agentespro-computer-<company>-hq --restart unless-stopped \
  -p 127.0.0.1:6101:80 -v /root/.hermes/webui-portal/computers/profiles/<company>-hq:/root agentespro/agent-desktop:latest
```
Caddyfile pattern (Larvuz):
```caddy
portal.<company-domain> {
    import /etc/caddy/computers/*.caddy
    handle { reverse_proxy 127.0.0.1:8791 }
}
```
Dashboard (optional): `hermes dashboard --host 127.0.0.1 --port 9119 --no-open --skip-build` as `agentespro-hermes-dashboard.service`.

- [ ] DNS A record `portal` → new VPS IP
- [ ] `curl -s https://portal.<company-domain>/health` → `{"status":"ok"...}`
- [ ] Login works, profile selector shows `<company>-hq` with its Agent Mark
- [ ] Desktop container reachable from portal overlay
- [ ] `caddy validate --config /etc/caddy/Caddyfile` passes

### Phase 8 — Hermes API server (app + studio integrations)

The "generative studio MCP" (Phatty/ShotForge) is today a **Hermes Responses API bridge**, not a true MCP: the app posts a context packet to the API server → selected profile → JSON back. Replicate by:
- [ ] `API_SERVER_ENABLED=true`, unique `API_SERVER_PORT` per profile, `API_SERVER_KEY` random
- [ ] Caddy route e.g. `api.<company-domain>` → `127.0.0.1:<port>` (Larvuz: `api.hermix.dev`, `agent.phattyacid.studio`)
- [ ] `curl -H "Authorization: Bearer $API_SERVER_KEY" https://api.<domain>/v1/models` responds
- [ ] `phatty-hermes-gateway` skill installed only if the app is used

### Phase 9 — Memory, vault, company context

- [ ] Create Obsidian vault `/root/obsidian-vaults/<company>` (copy structure from `gus-garza` vault: `01 Personal OS`, Digital Persona, Projects, Finance, Signals). Set `OBSIDIAN_VAULT_PATH`.
- [ ] Copy `/root/AI_OS_MASTER_ROUTER.md` and adapt to the company.
- [ ] Seed `memories/` of the hq profile: who the owner is, active projects, approval rules (email send + repo deletion require written confirmation), research order (EXA first, Monid supplements).
- [ ] Run the client bootstrap: `https://raw.githubusercontent.com/larvuz2/agentespro-client-bootstrap/main/BOOTSTRAP.md` (Memory OS context pack, dashboard connector, heartbeat).

### Phase 10 — Cron baseline (enable only what the company needs)

Larvuz core set (natural voice, no job IDs in messages):
- `Connector Health Check` — every 2 min (portal/gateway/dashboard health)
- `Workforce Sync` — every 10 min (agent roster → dashboard)
- `Revenue Signal Collector` — every 6 h
- `Inbox Filter — AM / PM` — weekdays (Reply / Decide / Schedule / Watch / FYI, max 5 bullets)
- `Weekly Review` / `Monthly Focus Check` / `Monthly Ops Review`
- `Daily System Cleanup` — 08:20
- `hermies-matchmake` — every 4 h (one job only — Larvuz currently has ~150 duplicates; clean those, don't replicate them)

- [ ] `hermes cron list` shows only intended jobs, no duplicates
- [ ] First run of Connector Health Check passes

### Phase 11 — Worker profiles (later, optional)

Add only when there is real work for them: `cto-<company>`, `mkt-<company>`, `content-<company>`, `ops-<company>`, `qa-<company>`, `devops-<company>`. Each gets: profile, SOUL.md, Agent Mark, gateway unit (if it needs a bot), portal URL entry. The hq profile is the only one with full context; workers get scoped skills.

### Phase 12 — Acceptance checklist (report this table)

- [ ] Hermes hq profile answers on Telegram
- [ ] Portal HTTPS live, password set, hq profile selectable with Mark
- [ ] Agent Desktop container reachable
- [ ] Image generated via FAL from chat
- [ ] Background removed via FAL from chat
- [ ] EXA search works; Monid discover works
- [ ] `gh auth status` OK; one test commit to a scratch repo
- [ ] `gws` lists Drive files for the company account
- [ ] X MCP reads a profile
- [ ] API server responds with key
- [ ] Skills library present (≥ baseline list)
- [ ] Vault + router + memories seeded
- [ ] Cron: health check running, no duplicates
- [ ] All secrets in `.env` (600) — none in git, none in chat
- [ ] Backup: nightly `tar` of `/root/.hermes` (excluding caches) to Drive or object storage

---

## 5. Known gaps to fix on the Larvuz VPS first (so the next replica is cleaner)

1. `/root/.hermes/skills` is not a git repo → create private `larvuz2/agentespro-hermes-skills`.
2. `hermies-matchmake` cron duplicated ~150× in `jobs.json` → dedupe to one.
3. `agentespro-hermes-dashboard.service` is in auto-restart loop → fix or disable before templating.
4. `nginx.service` failed and unused (Caddy owns 80/443) → disable nginx; move the `hermies` site to Caddy.
5. Profile SOUL.md + config templates not in `agentespro-client-bootstrap/templates/` → add `hq-SOUL.template.md`, `hq-config.template.yaml`, `gateway.service.template`.
6. Google client secrets and Monid credentials need a documented secure transfer path (1Password / age-encrypted tarball), never git.

---

## 6. One-paragraph version (if the agent needs the gist)

Install Ubuntu tooling (node 22, python 3.11, docker, caddy, gh, uv, ffmpeg), install Hermes Agent, create profile `<company>-hq` with the Chief-of-Staff SOUL, write `.env` with OpenRouter/FAL/EXA/GitHub/Telegram/Browser/Resend/X keys, enable FAL plugins and X + Lovable MCP, install Monid and gws CLIs, clone `agentespro-hermes-webui` and run `deploy/install.sh --domain portal.<domain>`, build the agent-desktop container, wire Caddy, enable the API server, import the agentesPRO skills library, seed vault + memories, enable the core cron set, then run the Phase 12 acceptance list and report.

# agentesPRO Client Hermes Bootstrap

Use this single URL to install and verify a new agentesPRO client Hermes VPS.

## First instruction for the target Hermes agent

You are becoming an agentesPRO client Hermes VPS. Follow this document step by step. Do **not** mark onboarding complete until every acceptance check passes.

## 0. Safety boundary

Never send to the dashboard or write into shared docs:

- raw prompts
- raw completions
- chat transcripts
- raw email bodies
- tool outputs verbatim
- raw logs
- secrets, API keys, tokens, cookies, headers, env values, credentials
- customer PII inside summaries

Only safe metadata and summaries are allowed: profile names, agent roles, tool summaries, project summaries, cron names/schedules/status, activity summaries, report summaries.

## 1. Install baseline skills

Install/load only the core agentesPRO client baseline by default:

```text
https://larvuz2.github.io/skills/chief-of-staff-agentespro.md
https://larvuz2.github.io/skills/beautiful-presentations.md
```

Do **not** install CTO or CMO/MKT by default. They are optional modules, same as Market Intelligence, and should only be installed when the client scope explicitly needs them.

### Optional modules

Install these modules only when approved by the onboarding scope:

```text
# Software/build/deployment module
https://larvuz2.github.io/skills/cto-agentespro.md

# Marketing/content/growth module
https://larvuz2.github.io/skills/mkt-agentespro.md

# Market Intelligence module
<market-intelligence-module-url-or-client-playbook>
```

Module install rule:

- Default bootstrap = Chief of Staff/router + presentation/reporting support.
- CTO module = opt-in for software, GitHub, app, deployment, database, QA, or technical workflow ownership.
- CMO/MKT module = opt-in for brand, content, SEO, social, growth, analytics, or marketing workflow ownership.
- Market Intelligence module = opt-in for recurring research, competitor monitoring, trend reports, or client intelligence workflows.
- If a client needs none of the optional modules, do not install them “just in case.” Keep the install lean and modular.

If a skill installer says a tarball is required, follow its instructions. After install, reload skills or start a fresh Hermes session.

Current known package gap: connector/playbook/obsidian/helper skills and Market Intelligence may need to be copied from the source VPS or installed from the client playbook until public readers are published. This bootstrap still defines the required setup and verification.

## 2. Create client Memory OS context pack

```bash
CLIENT_SLUG="<client-slug>"
BASE="/root/memory-os/projects/agentespro/clients/$CLIENT_SLUG"
mkdir -p "$BASE/work-log" "$BASE/assets" "$BASE/meetings"
touch "$BASE/PROJECT.md" "$BASE/rules.md" "$BASE/current-state.md" "$BASE/validation.md"
chmod -R go-rwx "$BASE"
```

Fill the files with safe client context:

- `PROJECT.md`: company name, goals, agents installed, dashboard company slug, safe URLs.
- `rules.md`: approvals, forbidden actions, client-specific privacy rules.
- `current-state.md`: what is installed and what is pending.
- `validation.md`: onboarding acceptance results.
- `work-log/`: safe dated summaries only.

## 3. Create Obsidian-compatible client vault

Recommended for managed agentesPRO clients with strategy, campaigns, research, meetings, approvals, or recurring knowledge work.

```bash
CLIENT_SLUG="<client-slug>"
VAULT="/root/obsidian-vaults/agentespro-clients/$CLIENT_SLUG"
mkdir -p "$VAULT/00 Inbox" "$VAULT/01 Company" "$VAULT/02 Projects" "$VAULT/03 Meetings" "$VAULT/04 Reports" "$VAULT/90 Archive"
cat > "$VAULT/README.md" <<'EOF'
# Client Obsidian Vault

Safe client knowledge only. No secrets, raw prompts, raw completions, raw email bodies, raw logs, tokens, cookies, API keys, or credentials.
EOF
chmod -R go-rwx "$VAULT"
```

If the client Hermes profile uses an Obsidian skill/tool, set:

```bash
export OBSIDIAN_VAULT_PATH="/root/obsidian-vaults/agentespro-clients/<client-slug>"
```

Do not sync raw vault content to the dashboard. Dashboard receives safe summaries/memory signals only.

## 4. Install/register dashboard connector

Use the one-time connect token generated in the agentesPRO dashboard. Do not paste the instance secret in chat/logs.

```bash
export AGENTESPRO_CONNECT_TOKEN="<ONE_TIME_CONNECT_TOKEN>"
python3 /root/agentespro-connector/install_client_connector.py \
  --api-base "<DASHBOARD_API_BASE>" \
  --vps-label "<client-slug>-main" \
  --hostname "<client-slug>-vps" \
  --activity-agent "<primary-profile-name>" \
  --install-cron
```

The installer must register the VPS, save `/root/.hermes/agentespro.env` with `0600`, run heartbeat, run first sync, and run an activity smoke test.

## 5. Verify heartbeat + sync + activity

```bash
/root/agentespro-connector/sync_workforce.py heartbeat
/root/agentespro-connector/sync_workforce.py sync --force --timeout 60 --retries 2
/root/agentespro-connector/emit_activity.py \
  --agent "<primary-profile-name>" \
  --kind connector.onboarding.activity_test \
  --status info \
  --source connector \
  --task-type connector_onboarding \
  --summary "Connector onboarding activity endpoint smoke test completed." \
  --task-title "Verify dashboard activity event ingestion" \
  --external-run-id "connector-onboarding-<client-slug>" \
  --detail-json '{"safe":true,"stage":"onboarding_activity_smoke_test"}'
```

Acceptance:

- heartbeat returns 200
- sync returns 200 and non-zero counts for expected profiles/projects/goals
- activity emitter returns 200 and dashboard Last Activity updates

## 6. Verify recurring tasks / cron jobs

Dashboard recurring jobs come from Hermes cron jobs. If the client has recurring work, it must appear in `hermes cron list --all` and in the sync payload.

```bash
hermes cron list --all
/root/agentespro-connector/sync_workforce.py payload --out /tmp/agentespro_payload.json
python3 - <<'PY'
import json
p=json.load(open('/tmp/agentespro_payload.json'))
jobs=[]
for profile in p.get('profiles', []):
    for key in ('recurring_jobs', 'recurring_tasks'):
        for job in profile.get(key, []) or []:
            jobs.append((profile.get('profile_name'), key, job.get('external_id') or job.get('job_id'), job.get('title') or job.get('name'), job.get('status'), job.get('schedule')))
print('recurring_items_count=', len(jobs))
for row in jobs:
    print(row)
PY
```

Acceptance:

- If `hermes cron list --all` shows no jobs, the client VPS has no recurring Hermes jobs installed.
- If Hermes shows jobs but `recurring_items_count=0`, the connector parser/mapping is incomplete.
- Each recurring task sent to dashboard must include required schema fields: `external_id`, `title`, and valid status: `queued | running | done | failed`.
- Do not mark onboarding complete until expected recurring jobs appear in the dashboard.

Status mapping:

```text
active/scheduled -> queued
running -> running
success/completed -> done
failed/error -> failed
unknown -> queued
```

## 7. Agent vs Project modeling rule

Root principle:

```text
Agents are operators. Projects are the workstreams/systems they operate.
```

Spanish:

```text
Los agentes son quienes trabajan. Los proyectos son los sistemas, iniciativas o flujos de trabajo donde trabajan.
```

Payload rule:

- `profiles[].agent` describes the operative AI persona/role.
- `projects[]` describes systems, workflows, initiatives, repos, or workstreams.
- Do not name a project after an agent.
- Preserve `source_project_id` when renaming a project so the dashboard updates the existing row.

Example:

```text
Correct:
Agent: Hunter
Project: MajadmA Trend Intelligence System

Incorrect:
Agent: Hunter
Project: Hunter MajadmA
```

## 8. Verify integrations and skills metadata

Inspect the payload before marking onboarding complete:

```bash
/root/agentespro-connector/sync_workforce.py payload --out /tmp/agentespro_payload.json
python3 - <<'PY'
import json
p=json.load(open('/tmp/agentespro_payload.json'))
profiles=p.get('profiles', [])
print('profiles=', len(profiles))
for profile in profiles:
    name=profile.get('profile_name')
    agent=profile.get('agent') or {}
    print('\nPROFILE', name)
    print('source_name=', agent.get('source_name'))
    print('tools=', agent.get('tools_summary'))
    print('integrations=', len(profile.get('integrations', []) or []))
    print('team_members=', len(profile.get('team_members', []) or []))
    print('recurring_jobs=', len(profile.get('recurring_jobs', []) or []))
PY
```

If skills metadata sync is enabled, verify skills are nested where Lovable expects them:

- top-level profiles: `profiles[i].agent.skills[]`
- team members: `profiles[i].team_members[n].skills[]`

Keep recurring workforce sync slim by default; full skills sync can be large.

## 9. Final onboarding acceptance checklist

Do not mark complete until all are true:

- [ ] Baseline skills installed/loaded.
- [ ] Memory OS client pack exists.
- [ ] Obsidian-compatible client vault exists when applicable.
- [ ] Connector registered with instance secret stored locally, not printed.
- [ ] Heartbeat works.
- [ ] Workforce/profile sync works.
- [ ] Project/goals sync works when applicable.
- [ ] Activity smoke test works.
- [ ] Recurring Hermes cron jobs sync to dashboard when applicable.
- [ ] Integrations visible or intentionally empty.
- [ ] Agent/project naming is correct.
- [ ] Safe summaries only; no raw private data sent.
- [ ] Dashboard shows VPS online, agents, projects, activity, and recurring jobs.

## 10. Report back

Return a safe summary with:

```text
Client:
Primary profile:
Heartbeat: pass/fail
Sync: pass/fail + counts
Activity smoke test: pass/fail
Cron jobs: pass/fail + count
Projects: pass/fail + names
Skills baseline: installed/missing
Memory OS pack: path
Obsidian vault: path or not applicable
Dashboard status:
Blockers:
```

#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=${1:-/tmp/agentespro_payload.json}

echo "== agentesPRO client onboarding verification =="

echo "\n[1] Hermes cron list"
if command -v hermes >/dev/null 2>&1; then
  hermes cron list --all || true
else
  echo "hermes CLI not found"
fi

echo "\n[2] Connector files"
for p in /root/agentespro-connector/sync_workforce.py /root/agentespro-connector/emit_activity.py /root/agentespro-connector/install_client_connector.py /root/.hermes/agentespro.env; do
  if [ -e "$p" ]; then echo "OK $p"; else echo "MISSING $p"; fi
done

echo "\n[3] Payload recurring items"
if [ ! -f "$PAYLOAD" ]; then
  if [ -x /root/agentespro-connector/sync_workforce.py ]; then
    /root/agentespro-connector/sync_workforce.py payload --out "$PAYLOAD"
  else
    echo "No payload and sync_workforce.py missing"
    exit 1
  fi
fi
python3 - "$PAYLOAD" <<'PY'
import json, sys
p=json.load(open(sys.argv[1]))
profiles=p.get('profiles', [])
print('profiles_count=', len(profiles))
jobs=[]
for profile in profiles:
    for key in ('recurring_jobs','recurring_tasks'):
        for job in profile.get(key, []) or []:
            jobs.append((profile.get('profile_name'), key, job.get('external_id') or job.get('job_id'), job.get('title') or job.get('name'), job.get('status'), job.get('schedule')))
print('recurring_items_count=', len(jobs))
for row in jobs:
    print(row)
PY

echo "\n[4] Memory paths"
find /root/memory-os/projects/agentespro/clients -maxdepth 2 -type f 2>/dev/null | sed -n '1,40p' || echo "No client Memory OS directory yet"
find /root/obsidian-vaults/agentespro-clients -maxdepth 2 -type d 2>/dev/null | sed -n '1,40p' || echo "No client Obsidian vault directory yet"

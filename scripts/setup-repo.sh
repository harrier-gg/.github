#!/usr/bin/env bash
# Richtet ein Repo der Org nach CONTRIBUTING.md ein: nur Squash-Merge, Branch nach Merge löschen,
# Regel für main (nur per PR, CI muss grün sein, keine Force-Pushes). Mehrfach ausführbar.
# Aufruf: scripts/setup-repo.sh backend   (braucht `gh auth login` mit Admin-Rechten in harrier-gg)
set -euo pipefail
repo="harrier-gg/${1:?Repo-Name angeben, z. B. backend}"
checks="${2-check,conventional}"   # Namen der Pflicht-Jobs, kommagetrennt; "" = keine

gh api -X PATCH "repos/$repo" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
  -F delete_branch_on_merge=true -F allow_auto_merge=true >/dev/null

# release-please darf Release-PRs anlegen
gh api -X PUT "repos/$repo/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true >/dev/null

# Regel für main als JSON. Ohne Pflicht-Checks (z. B. für .github: checks="") entfällt die Status-Regel.
ruleset=$(python3 - "$checks" <<'PY'
import json, sys
checks = [c for c in sys.argv[1].split(",") if c]
rules = [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "required_linear_history"},
    {"type": "pull_request", "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": False,
        "require_code_owner_review": False,
        "require_last_push_approval": False,
        "required_review_thread_resolution": True,
        "allowed_merge_methods": ["squash"]}},
]
if checks:
    rules.append({"type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": False,
        "required_status_checks": [{"context": c} for c in checks]}})
print(json.dumps({
    "name": "main schützen",
    "target": "branch",
    "enforcement": "active",
    "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
    "bypass_actors": [{"actor_id": 1, "actor_type": "OrganizationAdmin", "bypass_mode": "pull_request"}],
    "rules": rules,
}))
PY
)

existing=$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name=="main schützen") | .id')
if [ -n "$existing" ]; then
  echo "$ruleset" | gh api -X PUT "repos/$repo/rulesets/$existing" --input - >/dev/null
else
  echo "$ruleset" | gh api -X POST "repos/$repo/rulesets" --input - >/dev/null
fi
echo "✓ $repo eingerichtet (Pflicht-Checks: $checks)"

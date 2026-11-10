#!/usr/bin/env bash
# Configures a repository of the org as described in CONTRIBUTING.md. Safe to run repeatedly.
#
#   scripts/setup-repo.sh backend                               # default required checks
#   scripts/setup-repo.sh .github "pr / title,pr / template"    # custom required checks
#
# Needs `gh auth login` with admin rights in harrier-gg.
set -euo pipefail
repo="harrier-gg/${1:?repository name required, e.g. backend}"
checks="${2-check,pr / title,pr / template}"   # required status checks, comma-separated

# Squash only (PR title becomes the commit on main), delete branches after merge.
gh api -X PATCH "repos/$repo" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
  -F delete_branch_on_merge=true -F allow_auto_merge=true >/dev/null

# Let release-please open release PRs. Only works if the org allows it:
# Org settings → Actions → General → "Allow GitHub Actions to create and approve pull requests".
gh api -X PUT "repos/$repo/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true >/dev/null \
  || echo "⚠ $repo: Actions may not open PRs yet; allow it in the org settings and run this script again" >&2

# Two rulesets for main, because a bypass always applies to a whole ruleset:
#  1. "main: checks"  – PRs only, required checks, no force pushes. NO bypass, not even for admins.
#  2. "main: review"  – one approving review. Org admins may bypass it (to merge their own PRs).
rulesets=$(python3 - "$checks" <<'PY'
import json, sys
checks = [c for c in sys.argv[1].split(",") if c]
condition = {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}}

def pull_request(approvals):
    return {"type": "pull_request", "parameters": {
        "required_approving_review_count": approvals,
        "dismiss_stale_reviews_on_push": approvals > 0,
        "require_code_owner_review": False,
        "require_last_push_approval": approvals > 0,
        "required_review_thread_resolution": True,
        "allowed_merge_methods": ["squash"]}}

checks_rules = [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "required_linear_history"},
    pull_request(0),
]
if checks:
    checks_rules.append({"type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": False,
        "required_status_checks": [{"context": c} for c in checks]}})

print(json.dumps([
    {"name": "main: checks", "target": "branch", "enforcement": "active", "conditions": condition,
     "bypass_actors": [], "rules": checks_rules},
    {"name": "main: review", "target": "branch", "enforcement": "active", "conditions": condition,
     "bypass_actors": [{"actor_id": 1, "actor_type": "OrganizationAdmin", "bypass_mode": "pull_request"}],
     "rules": [pull_request(1)]},
]))
PY
)

existing=$(gh api "repos/$repo/rulesets" --jq '.[] | "\(.id)\t\(.name)"')
wanted=$(echo "$rulesets" | python3 -c 'import json,sys; [print(r["name"]) for r in json.load(sys.stdin)]')

# Remove rulesets created by older versions of this script.
while IFS=$'\t' read -r id name; do
  if [ -n "$id" ] && ! grep -qxF "$name" <<<"$wanted"; then
    gh api -X DELETE "repos/$repo/rulesets/$id" >/dev/null && echo "  removed old ruleset \"$name\""
  fi
done <<<"$existing"

for i in 0 1; do
  body=$(echo "$rulesets" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)[$i]))")
  name=$(echo "$body" | python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])')
  id=$(awk -F'\t' -v n="$name" '$2==n {print $1}' <<<"$existing")
  if [ -n "$id" ]; then
    echo "$body" | gh api -X PUT "repos/$repo/rulesets/$id" --input - >/dev/null
  else
    echo "$body" | gh api -X POST "repos/$repo/rulesets" --input - >/dev/null
  fi
done
echo "✓ $repo configured (required checks: ${checks:-none})"

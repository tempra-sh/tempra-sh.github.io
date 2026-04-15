# Tempra website — tempra.sh
# Usage: just <recipe>

set shell := ["bash", "-euo", "pipefail", "-c"]

# ==================== Git helpers ====================

# Sign all commits on current branch
sign-commits:
    #!/usr/bin/env bash
    set -euo pipefail
    UPSTREAM=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "")
    if [[ -z "${UPSTREAM}" ]]; then
        echo "No upstream branch — signing all commits from root"
        git rebase --exec 'git commit --amend -S --no-edit' --root
    else
        DIVERGE=$(git merge-base HEAD "${UPSTREAM}")
        COUNT=$(git rev-list --count "${DIVERGE}..HEAD")
        echo "Signing ${COUNT} commit(s) since ${DIVERGE}"
        git rebase --exec 'git commit --amend -S --no-edit' "${DIVERGE}"
    fi
    echo "All commits signed."

# ==================== Dev ====================

# Serve locally for preview (requires python3)
serve:
    python3 -m http.server 8000

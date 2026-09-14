#!/usr/bin/env bash
# Holds Tilly's standing docs to their size budgets. Exits non-zero if any is over.
# Over budget means consolidate — merge, sharpen, or move to the right home — not trim words.
set -u
cd "$(dirname "$0")/.."

status=0

check() { # label, actual, budget
  if [ "$2" -gt "$3" ]; then mark="OVER"; status=1; else mark="ok"; fi
  printf '%-44s %5s / %-5s %s\n' "$1" "$2" "$3" "$mark"
}

lines() { wc -l < "$1" | tr -d ' '; }

check "CLAUDE.md (lines)"             "$(lines CLAUDE.md)"          150
check "docs/PROJECT.md (lines)"       "$(lines docs/PROJECT.md)"    100
check "docs/TASTE.md (lines)"         "$(lines docs/TASTE.md)"      150
check "docs/TASTE.md (principles)"    "$(grep -cE '^\*\*[0-9]+\.' docs/TASTE.md)" 40
check "docs/DECISIONS.md (entries)"   "$(grep -c '^## ' docs/DECISIONS.md)"       20
check "docs/DESIGN.md (lines)"        "$(lines docs/DESIGN.md)"     250
check "docs/ROADMAP.md (lines)"       "$(lines docs/ROADMAP.md)"    120

for rule in .claude/rules/*.md; do
  check "$rule (lines)" "$(lines "$rule")" 60
done

exit $status

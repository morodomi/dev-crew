#!/bin/bash
# analyze-cycle-complexity.sh - Cycle doc complexity distribution report
# Usage: bash scripts/analyze-cycle-complexity.sh [base_dir]
# Output: Markdown report to stdout

set -euo pipefail

BASE_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
CYCLES_DIR="$BASE_DIR/docs/cycles"
ARCHIVE_DIR="$CYCLES_DIR/archive"

# Frontmatter value extractor (same spec as validate-cycle-frontmatter.sh - update both if changed)
fm_val() {
  local file="$1" key="$2"
  sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | grep "^${key}:" | head -1 | sed "s/^${key}: *//" || true
}

# Collect all cycle files
ACTIVE_FILES=()
ARCHIVE_FILES=()
for f in "$CYCLES_DIR"/*.md; do [ -f "$f" ] && ACTIVE_FILES+=("$f"); done 2>/dev/null
for f in "$ARCHIVE_DIR"/*.md; do [ -f "$f" ] && ARCHIVE_FILES+=("$f"); done 2>/dev/null
ALL_FILES=("${ACTIVE_FILES[@]+"${ACTIVE_FILES[@]}"}" "${ARCHIVE_FILES[@]+"${ARCHIVE_FILES[@]}"}")

TOTAL=${#ALL_FILES[@]}
ACTIVE=${#ACTIVE_FILES[@]}
ARCHIVED=${#ARCHIVE_FILES[@]}

# Extract complexity and phase for each file
declare -a COMPLEXITIES=() PHASES=() TEST_COUNTS=()
for f in "${ALL_FILES[@]+"${ALL_FILES[@]}"}"; do
  COMPLEXITIES+=("$(fm_val "$f" complexity)")
  PHASES+=("$(fm_val "$f" phase)")
  TEST_COUNTS+=("$(fm_val "$f" test_count)")
done

# Count complexity values
WITH_C=0; TRIVIAL=0; STANDARD=0; COMPLEX=0
for c in "${COMPLEXITIES[@]+"${COMPLEXITIES[@]}"}"; do
  case "$c" in
    trivial)  WITH_C=$((WITH_C+1)); TRIVIAL=$((TRIVIAL+1)) ;;
    standard) WITH_C=$((WITH_C+1)); STANDARD=$((STANDARD+1)) ;;
    complex)  WITH_C=$((WITH_C+1)); COMPLEX=$((COMPLEX+1)) ;;
  esac
done
MISSING=$((TOTAL - WITH_C))

pct() { [ "$2" -eq 0 ] && echo "0" || echo "$(( $1 * 100 / $2 ))"; }

# === Output Report ===
echo "# Cycle Complexity Report"
echo ""

# --- Summary ---
echo "## Summary"
echo ""
echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Total cycles | $TOTAL |"
echo "| Active | $ACTIVE |"
echo "| Archived | $ARCHIVED |"
echo "| With complexity | $WITH_C |"
echo "| Missing complexity | $MISSING ($(pct $MISSING $TOTAL)%) |"
echo ""

# --- Complexity Distribution ---
echo "## Complexity Distribution"
echo ""
if [ "$WITH_C" -eq 0 ]; then
  echo "No cycles with complexity data."
else
  echo "| Complexity | Count | % |"
  echo "|------------|-------|---|"
  echo "| trivial | $TRIVIAL | $(pct $TRIVIAL $WITH_C)% |"
  echo "| standard | $STANDARD | $(pct $STANDARD $WITH_C)% |"
  echo "| complex | $COMPLEX | $(pct $COMPLEX $WITH_C)% |"
fi
echo ""

# --- Recent N Cycles (sorted by filename descending = timestamp descending) ---
RECENT_FILES=()
if [ "$TOTAL" -gt 0 ]; then
  while IFS= read -r f; do
    RECENT_FILES+=("$f")
  done < <(for f in "${ALL_FILES[@]}"; do echo "$(basename "$f")|$f"; done | sort -t'|' -k1 -r | head -10 | cut -d'|' -f2)
fi
RECENT_N=${#RECENT_FILES[@]}
echo "## Recent $RECENT_N Cycles"
echo ""
if [ "$RECENT_N" -eq 0 ]; then
  echo "No cycles found."
else
  echo "| File | Complexity | Phase |"
  echo "|------|------------|-------|"
  for f in "${RECENT_FILES[@]}"; do
    fname=$(basename "$f")
    c=$(fm_val "$f" complexity)
    p=$(fm_val "$f" phase)
    echo "| $fname | ${c:-missing} | ${p:-unknown} |"
  done
fi
echo ""

# --- Phase x Complexity ---
echo "## Phase x Complexity"
echo ""
echo "| Phase | trivial | standard | complex | missing |"
echo "|-------|---------|----------|---------|---------|"
for phase in INIT KICKOFF RED GREEN REFACTOR REVIEW COMMIT DONE; do
  pt=0; ps=0; pc=0; pm=0
  if [ "$TOTAL" -gt 0 ]; then
    for i in $(seq 0 $((TOTAL - 1))); do
      [ "${PHASES[$i]}" = "$phase" ] || continue
      case "${COMPLEXITIES[$i]}" in
        trivial)  pt=$((pt+1)) ;;
        standard) ps=$((ps+1)) ;;
        complex)  pc=$((pc+1)) ;;
        *)        pm=$((pm+1)) ;;
      esac
    done
  fi
  HAS=$((pt+ps+pc+pm))
  [ "$HAS" -eq 0 ] && continue
  echo "| $phase | $pt | $ps | $pc | $pm |"
done
echo ""

# --- test_count by Complexity ---
echo "## test_count by Complexity"
echo ""
echo "| Complexity | Count | Avg | Min | Max |"
echo "|------------|-------|-----|-----|-----|"
for ctype in trivial standard complex; do
  tc_count=0; tc_sum=0; tc_min=999999; tc_max=0
  if [ "$TOTAL" -gt 0 ]; then
    for i in $(seq 0 $((TOTAL - 1))); do
      [ "${COMPLEXITIES[$i]}" = "$ctype" ] || continue
      tc="${TEST_COUNTS[$i]}"
      if [ -n "$tc" ] && echo "$tc" | grep -qE '^[0-9]+$' && [ "$tc" -ge 1 ]; then
        tc_count=$((tc_count+1))
        tc_sum=$((tc_sum+tc))
        [ "$tc" -lt "$tc_min" ] && tc_min=$tc
        [ "$tc" -gt "$tc_max" ] && tc_max=$tc
      fi
    done
  fi
  if [ "$tc_count" -eq 0 ]; then
    echo "| $ctype | 0 | - | - | - |"
  else
    tc_avg=$((tc_sum / tc_count))
    echo "| $ctype | $tc_count | $tc_avg | $tc_min | $tc_max |"
  fi
done
echo ""

# --- Fast-Path Eligibility ---
echo "## Fast-Path Eligibility (Theoretical)"
echo ""
ELIGIBLE=$((TRIVIAL + STANDARD))
if [ "$WITH_C" -eq 0 ]; then
  echo "No cycles with complexity data to evaluate."
else
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Eligible (trivial+standard) | $ELIGIBLE / $WITH_C ($(pct $ELIGIBLE $WITH_C)%) |"
  echo ""
  echo "*Theoretical eligibility based on complexity label. Actual fast-path usage is not tracked here.*"
fi

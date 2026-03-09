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
RECENT_INDICES=()
if [ "$TOTAL" -gt 0 ]; then
  while IFS= read -r idx; do
    RECENT_INDICES+=("$idx")
  done < <(for i in $(seq 0 $((TOTAL - 1))); do echo "$(basename "${ALL_FILES[$i]}")|$i"; done | sort -t'|' -k1 -r | head -10 | cut -d'|' -f2)
fi
RECENT_N=${#RECENT_INDICES[@]}
echo "## Recent $RECENT_N Cycles"
echo ""
if [ "$RECENT_N" -eq 0 ]; then
  echo "No cycles found."
else
  echo "| File | Complexity | Phase |"
  echo "|------|------------|-------|"
  for i in "${RECENT_INDICES[@]}"; do
    fname=$(basename "${ALL_FILES[$i]}")
    c="${COMPLEXITIES[$i]}"
    p="${PHASES[$i]}"
    echo "| $fname | ${c:-missing} | ${p:-unknown} |"
  done
fi
echo ""

# --- Single-pass: accumulate phase:complexity pairs and test_count stats ---
# Stored as newline-delimited "phase:complexity" entries for bash 3 compat
PXC_DATA=""
TC_DATA_trivial="" TC_DATA_standard="" TC_DATA_complex=""
if [ "$TOTAL" -gt 0 ]; then
  for i in $(seq 0 $((TOTAL - 1))); do
    p="${PHASES[$i]}"; c="${COMPLEXITIES[$i]:-missing}"
    PXC_DATA="${PXC_DATA}${p}:${c}"$'\n'
    tc="${TEST_COUNTS[$i]}"
    if [ -n "$tc" ] && [ "$tc" -gt 0 ] 2>/dev/null; then
      case "$c" in
        trivial)  TC_DATA_trivial="${TC_DATA_trivial}${tc} " ;;
        standard) TC_DATA_standard="${TC_DATA_standard}${tc} " ;;
        complex)  TC_DATA_complex="${TC_DATA_complex}${tc} " ;;
      esac
    fi
  done
fi

# --- Phase x Complexity ---
echo "## Phase x Complexity"
echo ""
echo "| Phase | trivial | standard | complex | missing |"
echo "|-------|---------|----------|---------|---------|"
for phase in INIT KICKOFF RED GREEN REFACTOR REVIEW COMMIT DONE; do
  pt=$(echo "$PXC_DATA" | grep -c "^${phase}:trivial$" || true)
  ps=$(echo "$PXC_DATA" | grep -c "^${phase}:standard$" || true)
  pc=$(echo "$PXC_DATA" | grep -c "^${phase}:complex$" || true)
  pm=$(echo "$PXC_DATA" | grep -c "^${phase}:missing$" || true)
  [ $((pt+ps+pc+pm)) -eq 0 ] && continue
  echo "| $phase | $pt | $ps | $pc | $pm |"
done
echo ""

# --- test_count by Complexity ---
echo "## test_count by Complexity"
echo ""
echo "| Complexity | Count | Avg | Min | Max |"
echo "|------------|-------|-----|-----|-----|"
tc_stats() {
  local data="$1"
  if [ -z "$data" ]; then echo "0 - - -"; return; fi
  local n=0 sum=0 min=999999 max=0
  for v in $data; do
    n=$((n+1)); sum=$((sum+v))
    [ "$v" -lt "$min" ] && min=$v
    [ "$v" -gt "$max" ] && max=$v
  done
  [ "$n" -eq 0 ] && echo "0 - - -" || echo "$n $((sum/n)) $min $max"
}
for ctype in trivial standard complex; do
  eval "data=\$TC_DATA_${ctype}"
  read -r n avg min max <<< "$(tc_stats "$data")"
  echo "| $ctype | $n | $avg | $min | $max |"
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

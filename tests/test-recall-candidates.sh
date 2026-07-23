#!/bin/bash
# test-recall-candidates.sh - recall-candidates.sh script contract + spec forced-recall doc wiring
#
# TC-S1..S11 exercise scripts/recall-candidates.sh against a deterministic fixture git
# repo (mktemp -d + trap EXIT cleanup + fixed GIT_AUTHOR_*/GIT_COMMITTER_* env). The script
# does not exist during RED, so every TC-S fails at the leading existence guard.
#
# TC-D1..D3 verify the spec workflow / reference / transcription wiring. Doc contracts
# extract the target heading region first (fence-aware), then grep within: whole-file grep
# would mis-detect fenced "## " lines (template bodies) as headings.

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASE_DIR/scripts/recall-candidates.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; }

# section_lines <file> <start_marker> <term_level>
#   start_marker: full heading incl leading hashes, fixed-string prefix (no ERE meta).
#   term_level:   terminate at the next heading whose level (# count) <= term_level.
#   Fence-aware: lines inside ``` code fences are emitted as body and never treated as
#   headings (so a fenced "## Recall" inside a template does not terminate the region).
section_lines() {
  awk -v sm="$2" -v tl="$3" '
    /^```/ { fence = !fence; if (in_sec) print; next }
    !in_sec && !fence && index($0, sm) == 1 { in_sec = 1; next }
    in_sec && !fence && /^#+ / {
      n = 0; while (substr($0, n + 1, 1) == "#") n++;
      if (n <= tl) { in_sec = 0; next }
    }
    in_sec { print }
  ' "$1"
}

# --- Deterministic fixture git repo -----------------------------------------
# Distinct input file names per scenario keep each file's link set (and hub-decay
# denominator) predictable within a single shared repo. Commit dates are fixed and
# irrelevant to ranking: recency tie-break reads the YYYYMMDD_HHMM in doc basenames.
REPO=""
build_fixture() {
  REPO=$(mktemp -d)
  export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.com
  export GIT_AUTHOR_DATE="2026-01-01T00:00:00 +0000"
  export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.com
  export GIT_COMMITTER_DATE="2026-01-01T00:00:00 +0000"
  git -C "$REPO" -c init.defaultBranch=main init -q
  mkdir -p "$REPO/docs/cycles/archive"

  # TC-S1: trailer overrides co-change. a1 is the confirmed (trailer) link; b1 is a
  # co-changed decoy in the same commit and must be ignored because a trailer is present.
  printf 'a\n' > "$REPO/docs/cycles/20260110_1000_a1.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "seed a1 doc"
  printf 'x\n' > "$REPO/f1.txt"
  printf 'b\n' > "$REPO/docs/cycles/20260110_1100_b1.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "$(printf 'change f1 with trailer\n\nCycle-Doc: docs/cycles/20260110_1000_a1.md')"

  # TC-S2: trailer-less co-change fallback.
  printf 'y\n' > "$REPO/f2.txt"
  printf 'c\n' > "$REPO/docs/cycles/20260112_1000_c2.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "co-change f2 c2"

  # TC-S3: hub decay. f3H links 3 distinct docs (each contributes 1/3); f3L links 1
  # (contributes 1/1) so the leaf-derived doc must outrank the hub-derived docs.
  printf 'h\n' > "$REPO/f3H.txt"
  printf '1\n' > "$REPO/docs/cycles/20260113_1000_h3a.md"
  printf '2\n' > "$REPO/docs/cycles/20260113_1100_h3b.md"
  printf '3\n' > "$REPO/docs/cycles/20260113_1200_h3c.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "hub f3H links 3 docs"
  printf 'l\n' > "$REPO/f3L.txt"
  printf '4\n' > "$REPO/docs/cycles/20260113_1300_l3.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "leaf f3L links 1 doc"

  # TC-S4: recency tie-break. f4 links two docs (each 1/2, tied); newer basename wins.
  printf 'g\n' > "$REPO/f4.txt"
  printf 'o\n' > "$REPO/docs/cycles/20260101_1000_old4.md"
  printf 'n\n' > "$REPO/docs/cycles/20260201_1000_new4.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "f4 links old4 new4 tie"

  # TC-S5: file that links to no cycle doc -> empty output, exit 0.
  printf 'lonely\n' > "$REPO/f5.txt"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "f5 solo no doc"

  # TC-S6: historical link to a doc that no longer exists anywhere -> excluded + reported.
  printf 'z\n' > "$REPO/f6.txt"
  printf 'zz\n' > "$REPO/docs/cycles/20260116_1000_z6.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "f6 links z6"
  git -C "$REPO" rm -q docs/cycles/20260116_1000_z6.md
  git -C "$REPO" commit -qm "delete z6 doc"

  # TC-S8: six candidate docs (all tied) -> default run caps at 5 lines, TSV format.
  printf 'e\n' > "$REPO/f8.txt"
  printf '1\n' > "$REPO/docs/cycles/20260301_1000_d81.md"
  printf '2\n' > "$REPO/docs/cycles/20260302_1000_d82.md"
  printf '3\n' > "$REPO/docs/cycles/20260303_1000_d83.md"
  printf '4\n' > "$REPO/docs/cycles/20260304_1000_d84.md"
  printf '5\n' > "$REPO/docs/cycles/20260305_1000_d85.md"
  printf '6\n' > "$REPO/docs/cycles/20260306_1000_d86.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "f8 links 6 docs"

  # TC-S10: doc moved to archive/ after the linking commit -> resolves to current path.
  printf 'w\n' > "$REPO/f10.txt"
  printf 'old\n' > "$REPO/docs/cycles/20260117_1000_old10.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "seed f10 old10"
  git -C "$REPO" mv docs/cycles/20260117_1000_old10.md docs/cycles/archive/20260117_1000_old10.md
  git -C "$REPO" commit -qm "archive old10"

  # TC-S11: same (file, doc) pair touched by 3 commits -> unique-pair contribution once.
  printf 'p1\n' > "$REPO/f11.txt"; printf 'd1\n' > "$REPO/docs/cycles/20260118_1000_d11.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "f11 d11 first"
  printf 'p2\n' > "$REPO/f11.txt"; printf 'd2\n' > "$REPO/docs/cycles/20260118_1000_d11.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "f11 d11 second"
  printf 'p3\n' > "$REPO/f11.txt"; printf 'd3\n' > "$REPO/docs/cycles/20260118_1000_d11.md"
  git -C "$REPO" add -A; git -C "$REPO" commit -qm "f11 d11 third"
}

# run_recall <input files...> : captures RECALL_OUT / RECALL_ERR / RECALL_RC
run_recall() {
  local ef
  ef=$(mktemp)
  RECALL_OUT=$(bash "$SCRIPT" "$REPO" "$@" 2>"$ef"); RECALL_RC=$?
  RECALL_ERR=$(cat "$ef"); rm -f "$ef"
}

build_fixture
trap 'rm -rf "$REPO"' EXIT

echo "=== recall-candidates.sh + spec forced-recall Tests ==="

# --- TC-S1: trailer priority over co-change ---
echo ""
echo "TC-S1: trailer-linked doc wins; co-changed decoy in the same commit is ignored"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S1: scripts/recall-candidates.sh does not exist"
else
  run_recall f1.txt
  has_a1=$(printf '%s\n' "$RECALL_OUT" | grep -cF "20260110_1000_a1.md" || true)
  has_b1=$(printf '%s\n' "$RECALL_OUT" | grep -cF "20260110_1100_b1.md" || true)
  if [ "$RECALL_RC" -eq 0 ] && [ "$has_a1" -ge 1 ] && [ "$has_b1" -eq 0 ]; then
    pass "TC-S1: a1 (trailer) linked, b1 (co-change) suppressed"
  else
    fail "TC-S1: expected a1 present + b1 absent (rc=$RECALL_RC a1=$has_a1 b1=$has_b1)"
  fi
fi

# --- TC-S2: co-change fallback (no trailer) ---
echo ""
echo "TC-S2: trailer-less commit links the co-changed cycle doc"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S2: scripts/recall-candidates.sh does not exist"
else
  run_recall f2.txt
  has_c2=$(printf '%s\n' "$RECALL_OUT" | grep -cF "20260112_1000_c2.md" || true)
  if [ "$RECALL_RC" -eq 0 ] && [ "$has_c2" -ge 1 ]; then
    pass "TC-S2: c2 linked via co-change fallback"
  else
    fail "TC-S2: expected c2 present (rc=$RECALL_RC c2=$has_c2)"
  fi
fi

# --- TC-S3: hub decay (IDF-style weighting) ---
echo ""
echo "TC-S3: leaf-derived doc (1/1) outranks hub-derived docs (1/3)"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S3: scripts/recall-candidates.sh does not exist"
else
  run_recall f3H.txt f3L.txt
  first=$(printf '%s\n' "$RECALL_OUT" | head -1)
  is_leaf=$(printf '%s\n' "$first" | grep -cF "20260113_1300_l3.md" || true)
  # Characterization: a single pure-hub query yields all-tied scores presented
  # newest-first — the documented, accepted behavior (decay is a relative weight
  # across input files; it cannot differentiate a lone hub's own candidates).
  run_recall f3H.txt
  hub_first=$(printf '%s\n' "$RECALL_OUT" | head -1)
  hub_is_newest=$(printf '%s\n' "$hub_first" | grep -cF "20260113_1200_h3c.md" || true)
  hub_scores=$(printf '%s\n' "$RECALL_OUT" | cut -f1 | sort -u | grep -c . || true)
  if [ "$RECALL_RC" -eq 0 ] && [ "$is_leaf" -ge 1 ] && [ "$hub_is_newest" -ge 1 ] && [ "$hub_scores" -eq 1 ]; then
    pass "TC-S3: leaf doc l3 ranked first (hub decay) + lone-hub query ties newest-first (documented)"
  elif [ "$is_leaf" -lt 1 ]; then
    fail "TC-S3: expected l3 first (first=[$first])"
  else
    fail "TC-S3: lone-hub characterization mismatch (first=[$hub_first] distinct_scores=$hub_scores)"
  fi
fi

# --- TC-S4: recency tie-break on equal score ---
echo ""
echo "TC-S4: equal-score docs tie-break by newer basename date"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S4: scripts/recall-candidates.sh does not exist"
else
  run_recall f4.txt
  first=$(printf '%s\n' "$RECALL_OUT" | head -1)
  is_new=$(printf '%s\n' "$first" | grep -cF "20260201_1000_new4.md" || true)
  if [ "$RECALL_RC" -eq 0 ] && [ "$is_new" -ge 1 ]; then
    pass "TC-S4: newer doc new4 ranked first on tie"
  else
    fail "TC-S4: expected new4 first (rc=$RECALL_RC first=[$first])"
  fi
fi

# --- TC-S5: zero candidates + exit 0 ---
echo ""
echo "TC-S5: file linking to no cycle doc yields empty stdout + exit 0"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S5: scripts/recall-candidates.sh does not exist"
else
  run_recall f5.txt
  if [ "$RECALL_RC" -eq 0 ] && [ -z "$RECALL_OUT" ]; then
    pass "TC-S5: empty stdout, rc=0"
  else
    fail "TC-S5: expected empty stdout + rc 0 (rc=$RECALL_RC out=[$RECALL_OUT])"
  fi
fi

# --- TC-S6: excluded non-existent doc reported on stderr ---
echo ""
echo "TC-S6: doc absent from current tree excluded from stdout + reported on stderr"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S6: scripts/recall-candidates.sh does not exist"
else
  run_recall f6.txt
  has_z6=$(printf '%s\n' "$RECALL_OUT" | grep -cF "z6" || true)
  err_lines=$(printf '%s\n' "$RECALL_ERR" | grep -c . || true)
  if [ "$RECALL_RC" -eq 0 ] && [ "$has_z6" -eq 0 ] && [ "$err_lines" -ge 1 ]; then
    pass "TC-S6: z6 excluded from stdout, exclusion reported on stderr"
  else
    fail "TC-S6: expected z6 absent + stderr report (rc=$RECALL_RC z6=$has_z6 err_lines=$err_lines)"
  fi
fi

# --- TC-S7: idempotent (byte-identical output) ---
echo ""
echo "TC-S7: repeated run on identical input produces byte-identical output"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S7: scripts/recall-candidates.sh does not exist"
else
  run_recall f8.txt; out1="$RECALL_OUT"; rc1="$RECALL_RC"
  run_recall f8.txt; out2="$RECALL_OUT"; rc2="$RECALL_RC"
  if [ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] && [ "$out1" = "$out2" ]; then
    pass "TC-S7: output stable across runs"
  else
    fail "TC-S7: expected identical output (rc1=$rc1 rc2=$rc2 equal=$([ "$out1" = "$out2" ] && echo yes || echo no))"
  fi
fi

# --- TC-S8: top-N cap (default 5) + TSV format ---
echo ""
echo "TC-S8: six candidates capped to 5 lines, each 'score<TAB>docs/cycles/...'"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S8: scripts/recall-candidates.sh does not exist"
else
  run_recall f8.txt
  nlines=$(printf '%s\n' "$RECALL_OUT" | grep -c . || true)
  badlines=$(printf '%s\n' "$RECALL_OUT" | awk -F'\t' '$0!=""{ if ($1 !~ /^[0-9]+(\.[0-9]+)?$/ || $2 !~ /^docs\/cycles\//) bad++ } END{print bad+0}')
  if [ "$RECALL_RC" -eq 0 ] && [ "$nlines" -eq 5 ] && [ "$badlines" -eq 0 ]; then
    pass "TC-S8: 5 lines, all well-formed TSV"
  else
    fail "TC-S8: expected 5 well-formed lines (rc=$RECALL_RC nlines=$nlines badlines=$badlines)"
  fi
fi

# --- TC-S9: read-only (working tree + status unchanged) ---
echo ""
echo "TC-S9: script leaves working tree and git status unchanged (canonical acceptance pin)"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S9: scripts/recall-candidates.sh does not exist"
else
  before_status=$(git -C "$REPO" status --porcelain)
  before_manifest=$( (cd "$REPO" && find . -type f -not -path './.git/*' | sort | xargs shasum 2>/dev/null | shasum) )
  run_recall f1.txt
  s9_rc=$RECALL_RC
  after_status=$(git -C "$REPO" status --porcelain)
  after_manifest=$( (cd "$REPO" && find . -type f -not -path './.git/*' | sort | xargs shasum 2>/dev/null | shasum) )
  if [ "$s9_rc" -eq 0 ] && [ "$before_status" = "$after_status" ] && [ "$before_manifest" = "$after_manifest" ]; then
    pass "TC-S9: script succeeded (rc=0) and tree + status identical before/after"
  elif [ "$s9_rc" -ne 0 ]; then
    fail "TC-S9: script run failed (rc=$s9_rc) — unchanged tree is vacuous without a successful run"
  else
    fail "TC-S9: working tree or status mutated by script run"
  fi
fi

# --- TC-S10: archive two-stage path resolution ---
echo ""
echo "TC-S10: doc moved under docs/cycles/archive/ resolves to its current path (not excluded)"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S10: scripts/recall-candidates.sh does not exist"
else
  run_recall f10.txt
  has_arch=$(printf '%s\n' "$RECALL_OUT" | grep -cF "docs/cycles/archive/20260117_1000_old10.md" || true)
  if [ "$RECALL_RC" -eq 0 ] && [ "$has_arch" -ge 1 ]; then
    pass "TC-S10: archive path resolved and present in output"
  else
    fail "TC-S10: expected archive path present (rc=$RECALL_RC arch=$has_arch out=[$RECALL_OUT])"
  fi
fi

# --- TC-S11: unique (file, doc) pair dedup ---
echo ""
echo "TC-S11: same pair across 3 commits contributes once (score not tripled)"
if [ ! -f "$SCRIPT" ]; then
  fail "TC-S11: scripts/recall-candidates.sh does not exist"
else
  run_recall f11.txt
  occ=$(printf '%s\n' "$RECALL_OUT" | grep -cF "20260118_1000_d11.md" || true)
  d11_line=$(printf '%s\n' "$RECALL_OUT" | grep -F "20260118_1000_d11.md" | head -1)
  d11_score=$(printf '%s\n' "$d11_line" | cut -f1)
  score_is_one=$(awk -v s="$d11_score" 'BEGIN{ if (s==1) print 1; else print 0 }')
  if [ "$RECALL_RC" -eq 0 ] && [ "$occ" -eq 1 ] && [ "$score_is_one" -eq 1 ]; then
    pass "TC-S11: d11 appears once with unique-pair score 1 (not 3)"
  else
    fail "TC-S11: expected single occurrence + score 1 (rc=$RECALL_RC occ=$occ score=[$d11_score])"
  fi
fi

# --- TC-D1: spec/SKILL.md Step 7.2 wiring + under 100 lines ---
echo ""
echo "TC-D1: skills/spec/SKILL.md Step 7 region references recall-candidates.sh + '## Recall'; file < 100 lines"
SPEC_SKILL="$BASE_DIR/skills/spec/SKILL.md"
if [ ! -f "$SPEC_SKILL" ]; then
  fail "TC-D1: skills/spec/SKILL.md does not exist"
else
  # Region: from the Step 7 heading up to (excluding) the Step 8 heading — robust to
  # whether Step 7.2 is a bold sub-item or a nested ### heading.
  step7_region=$(awk '/^### Step 7/{f=1} /^### Step 8/{f=0} f' "$SPEC_SKILL")
  has_script=$(printf '%s\n' "$step7_region" | grep -cF "recall-candidates.sh" || true)
  has_recall=$(printf '%s\n' "$step7_region" | grep -cF "## Recall" || true)
  d1_lines=$(wc -l < "$SPEC_SKILL" | tr -d ' ')
  if [ "$has_script" -ge 1 ] && [ "$has_recall" -ge 1 ] && [ "$d1_lines" -lt 100 ]; then
    pass "TC-D1: Step 7 wires recall-candidates.sh + ## Recall; SKILL.md is $d1_lines lines"
  elif [ "$has_script" -lt 1 ]; then
    fail "TC-D1: Step 7 region missing 'recall-candidates.sh' reference"
  elif [ "$has_recall" -lt 1 ]; then
    fail "TC-D1: Step 7 region missing '## Recall' recording instruction"
  else
    fail "TC-D1: SKILL.md must stay under 100 lines (is $d1_lines)"
  fi
fi

# --- TC-D2: reference.md + reference.ja.md forced-recall section + template ordering ---
echo ""
echo "TC-D2: both reference files carry #forced-recall advisory triad + no-match line + Template '## Recall' before Plan Review Record"
d2_ok=1
d2_msg=""
for f in reference.md reference.ja.md; do
  ref="$BASE_DIR/skills/spec/$f"
  if [ ! -f "$ref" ]; then
    d2_ok=0; d2_msg="$d2_msg $f:missing"; continue
  fi
  fr=$(section_lines "$ref" "## Forced Recall" 2)
  c_what=$(printf '%s\n' "$fr" | grep -cF "何が起きたか" || true)
  c_assume=$(printf '%s\n' "$fr" | grep -cF "当時の前提" || true)
  c_same=$(printf '%s\n' "$fr" | grep -cF "今回も同じ前提か" || true)
  c_none=$(printf '%s\n' "$fr" | grep -cF "関連する過去サイクルなし" || true)
  tmpl=$(section_lines "$ref" "## Plan File Template" 2)
  recall_ln=$(printf '%s\n' "$tmpl" | grep -nF "## Recall" | head -1 | cut -d: -f1)
  prr_ln=$(printf '%s\n' "$tmpl" | grep -nF "## Plan Review Record" | head -1 | cut -d: -f1)
  order_ok=0
  if [ -n "$recall_ln" ] && [ -n "$prr_ln" ] && [ "$recall_ln" -lt "$prr_ln" ]; then
    order_ok=1
  fi
  if [ "$c_what" -ge 1 ] && [ "$c_assume" -ge 1 ] && [ "$c_same" -ge 1 ] && [ "$c_none" -ge 1 ] && [ "$order_ok" -eq 1 ]; then
    :
  else
    d2_ok=0
    d2_msg="$d2_msg $f(what=$c_what assume=$c_assume same=$c_same none=$c_none order=$order_ok)"
  fi
done
if [ "$d2_ok" -eq 1 ]; then
  pass "TC-D2: forced-recall triad + no-match line + Template ordering present in both languages"
else
  fail "TC-D2: reference contract incomplete:$d2_msg"
fi

# --- TC-D3: sync-plan transcription row + cycle template section (negative Retrospective) ---
echo ""
echo "TC-D3: sync-plan.md transcription table has a '## Recall' row; cycle.md has '## Recall' + no '## Retrospective'"
SYNC="$BASE_DIR/agents/sync-plan.md"
CYCLE_TMPL="$BASE_DIR/skills/spec/templates/cycle.md"
d3_ok=1
d3_msg=""
if [ ! -f "$SYNC" ]; then
  d3_ok=0; d3_msg="$d3_msg sync-plan:missing"
else
  step2=$(section_lines "$SYNC" "### Step 2" 3)
  sync_row=$(printf '%s\n' "$step2" | grep -cF "## Recall" || true)
  [ "$sync_row" -ge 1 ] || { d3_ok=0; d3_msg="$d3_msg no-recall-row($sync_row)"; }
fi
if [ ! -f "$CYCLE_TMPL" ]; then
  d3_ok=0; d3_msg="$d3_msg cycle-tmpl:missing"
else
  tmpl_recall=$(grep -cF "## Recall" "$CYCLE_TMPL" || true)
  tmpl_retro=$(grep -cF "## Retrospective" "$CYCLE_TMPL" || true)
  [ "$tmpl_recall" -ge 1 ] || { d3_ok=0; d3_msg="$d3_msg no-recall-section($tmpl_recall)"; }
  [ "$tmpl_retro" -eq 0 ] || { d3_ok=0; d3_msg="$d3_msg retrospective-present($tmpl_retro)"; }
fi
if [ "$d3_ok" -eq 1 ]; then
  pass "TC-D3: transcription row + cycle template ## Recall present; ## Retrospective absent"
else
  fail "TC-D3: transcription/template wiring incomplete:$d3_msg"
fi

# --- TC-R1 (regression): test-post-approve-ordering non-破壊 proxy ---
# The spec edits (Step 7.2 + L83/L95 compression) must not break TC-R4's contract:
# SKILL.md keeps its Step 8 heading + --sandbox read-only clause and stays under 100 lines.
echo ""
echo "TC-R1 (regression): skills/spec/SKILL.md keeps '### Step 8' + '--sandbox read-only' + < 100 lines"
if [ ! -f "$SPEC_SKILL" ]; then
  fail "TC-R1: skills/spec/SKILL.md does not exist"
else
  r1_step8=$(grep -c "^### Step 8" "$SPEC_SKILL" || true)
  r1_sandbox=$(grep -cF -- "--sandbox read-only" "$SPEC_SKILL" || true)
  r1_lines=$(wc -l < "$SPEC_SKILL" | tr -d ' ')
  if [ "$r1_step8" -ge 1 ] && [ "$r1_sandbox" -ge 1 ] && [ "$r1_lines" -lt 100 ]; then
    pass "TC-R1: Step 8 + --sandbox read-only intact; SKILL.md $r1_lines lines"
  else
    fail "TC-R1: post-approve-ordering pins broken (step8=$r1_step8 sandbox=$r1_sandbox lines=$r1_lines)"
  fi
fi

# --- TC-R2 (regression): ja Plan File Template + hash boundary non-破壊 proxy ---
# The reference.ja.md edits (Forced Recall + template ## Recall) must not disturb the
# pinned template structure (## TDD Context / ## Plan Review Record boundary / ## Post-Approve Action).
echo ""
echo "TC-R2 (regression): reference.ja.md Plan File Template retains TDD Context + Plan Review Record boundary + Post-Approve Action"
REF_JA="$BASE_DIR/skills/spec/reference.ja.md"
if [ ! -f "$REF_JA" ]; then
  fail "TC-R2: skills/spec/reference.ja.md does not exist"
else
  ja_tmpl=$(section_lines "$REF_JA" "## Plan File Template" 2)
  r2_ctx=$(printf '%s\n' "$ja_tmpl" | grep -cF "## TDD Context" || true)
  r2_prr=$(printf '%s\n' "$ja_tmpl" | grep -cF "## Plan Review Record" || true)
  r2_post=$(printf '%s\n' "$ja_tmpl" | grep -cF "## Post-Approve Action" || true)
  if [ "$r2_ctx" -ge 1 ] && [ "$r2_prr" -ge 1 ] && [ "$r2_post" -ge 1 ]; then
    pass "TC-R2: ja template structure + Plan Review Record boundary intact"
  else
    fail "TC-R2: ja template pins broken (ctx=$r2_ctx prr=$r2_prr post=$r2_post)"
  fi
fi

# Summary
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / FAIL: $FAIL / TOTAL: $((PASS + FAIL))"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

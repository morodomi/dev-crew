#!/bin/bash
# retro-insight-ledger.sh - Retrospective unit ledger (grammar v2)
# Usage: bash scripts/retro-insight-ledger.sh <subcommand> <repos_tsv>
#   subcommand: ledger  - 10-column TSV to stdout (first line is the header)
#               summary - Markdown report + machine-readable block to stdout
#   repos_tsv : <label><TAB><repo_path>, one per line. '#' lines and blanks are ignored
#
# Repository paths are supplied only through repos_tsv and never reach stdout.
# Source-derived text does pass through: the ledger's doc / container / heading
# columns and the summary's ZERO / SKIP lines carry cycle doc names and heading
# text verbatim. Only the repo path itself is reduced to a label.

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: bash scripts/retro-insight-ledger.sh <subcommand> <repos_tsv>
  subcommand: ledger  - TSV to stdout (first line is the header)
              summary - Markdown report + machine-readable block to stdout
  repos_tsv : <label><TAB><repo_path> per line. '#' lines and blanks are ignored
EOF
  exit 2
}

[ "$#" -ge 1 ] || usage
SUBCMD="$1"
case "$SUBCMD" in
  ledger|summary) : ;;
  *) usage ;;
esac
[ "$#" -ge 2 ] || usage
CONF="$2"
[ -f "$CONF" ] && [ -r "$CONF" ] || usage

LEDGER_HEADER=$'label\tdoc\tretro_status\thas_codify\tform\tcontainer\tunit_no\tline\tpolarity\theading'
GRAMMAR_VERSION="version=v2"

REC="$(mktemp)"
trap 'rm -f "$REC"' EXIT INT TERM

# --- awk parser (grammar v2) ------------------------------------------------
# Emits tab-separated typed records:
#   U <label> <doc> <retro_status> <has_codify> <form> <container> <unit_no> <line> <polarity> <heading>
#   D <label> <doc> <retro_sections> <units>
#   Z <label> <doc>                      zero-unit doc
#   S <label> <kind> <container_key> <n> per-section excluded enumeration
read -r -d '' PARSER <<'AWK' || true
# Sections whose enumerated entries are excluded from the unit count and
# reported as SKIP instead, so that an exclusion is never silent. Matched as a
# prefix because a real heading carries a suffix after the section name.
BEGIN {
  spec = "sub-field:Failure → Final fix pairs"
  spec = spec "|sub-field:Failure → Fix → Insight"
  spec = spec "|derivative:事前知識化候補"
  spec = spec "|derivative:Reusable lessons"
  spec = spec "|standalone-positive:Positive validations"
  spec = spec "|standalone-positive:この cycle で機能したもの"
  spec = spec "|standalone-positive:成功事例"
  SKIP_N = split(spec, entry, "|")
  for (si = 1; si <= SKIP_N; si++) {
    sp = index(entry[si], ":")
    SKIP_KIND[si] = substr(entry[si], 1, sp - 1)
    SKIP_KEY[si]  = substr(entry[si], sp + 1)
  }
}

function sq(s) { gsub(/\t/, " ", s); return s }

function strip(l,   s) {
  s = l
  sub(/^#+[ \t]+/, "", s)
  sub(/^-[ \t]+/, "", s)
  sub(/^\*\*/, "", s)
  sub(/\*\*$/, "", s)
  gsub(/\t/, " ", s)
  sub(/^[ \t]+/, "", s)
  sub(/[ \t]+$/, "", s)
  return s
}

# 3-valued, never inferred. Positive wins over failure: an entry that says it is
# positive stays positive even when the enclosing section is about failures.
function polarity(l, c) {
  if (index(l, "(positive") > 0 || index(l, "(Success)") > 0 || index(l, "（Success）") > 0) return "explicit_positive"
  if (index(c, "Positive validations") > 0 || index(c, "機能したもの") > 0 || index(c, "成功事例") > 0) return "explicit_positive"
  if (index(l, "Failure") > 0 || index(l, "失敗") > 0) return "explicit_failure"
  if (index(c, "Failure") > 0 || index(c, "失敗") > 0) return "explicit_failure"
  return "unknown"
}

# Excluded enumerations are reported, never silently dropped. A section whose
# body carries no labelled entry is itself the single observation (its heading
# holds the content); plain follow-on prose bullets are notes, not entries.
function flush_sec(   n) {
  if (sec_key != "") {
    n = (sec_items > 0 ? sec_items : 1)
    printf "S\t%s\t%s\t%s\t%d\n", LABEL, sec_kind, sec_key, n
  }
  sec_key = ""; sec_kind = ""; sec_items = 0
}

function set_container(l,   i) {
  flush_sec()
  container = l
  if (substr(l, 1, 4) == "### ") {
    for (i = 1; i <= SKIP_N; i++) {
      if (index(l, "### " SKIP_KEY[i]) == 1) { sec_kind = SKIP_KIND[i]; sec_key = SKIP_KEY[i]; break }
    }
  }
}

function unit(form,   c) {
  units++; unit_no++
  c = (container == "" ? "-" : sq(container))
  nbuf++
  buf[nbuf] = form "\t" c "\t" unit_no "\t" FNR "\t" polarity(line, container) "\t" strip(line)
}

function flush_doc(   i) {
  if (doc != "") {
    flush_sec()
    if (had_retro) {
      printf "D\t%s\t%s\t%d\t%d\n", LABEL, doc, sections, units
      for (i = 1; i <= nbuf; i++) printf "U\t%s\t%s\t%s\t%s\t%s\n", LABEL, doc, retro_status, has_codify, buf[i]
      if (units == 0) printf "Z\t%s\t%s\n", LABEL, doc
    }
  }
  doc = ""
}

function init_doc(   n, a) {
  n = split(FILENAME, a, "/")
  doc = a[n]
  retro_status = "-"; has_codify = "no"
  fm = 0; inretro = 0; fence = 0; container = ""
  units = 0; sections = 0; unit_no = 0; nbuf = 0; had_retro = 0
  sec_key = ""; sec_kind = ""; sec_items = 0
}

FNR == 1 { flush_doc(); init_doc() }

{
  line = $0
  sub(/\r$/, "", line)

  # frontmatter is a bounded region: body mentions of the same key never win
  if (fm == 1) {
    if (line == "---") { fm = 2; next }
    if (match(line, /^retro_status:[ \t]*/)) {
      v = substr(line, RLENGTH + 1)
      sub(/[ \t]+$/, "", v)
      if (v != "") retro_status = v
    }
    next
  }
  if (FNR == 1 && line == "---") { fm = 1; next }

  # A fenced line is out of scope for every rule, the region heading included,
  # so fence state spans the whole document instead of resetting per section.
  if (substr(line, 1, 3) == "```") { fence = 1 - fence; next }
  if (fence) next

  if (substr(line, 1, 3) == "## ") {
    flush_sec()
    container = ""
    # Exact match: a heading that merely starts with the region name is a
    # different section, and trailing whitespace does not make one either.
    if (line == "## Retrospective") { inretro = 1; sections++; had_retro = 1 }
    else {
      inretro = 0
      if (index(line, "## Codify Decisions") == 1) has_codify = "yes"
    }
    next
  }
  if (!inretro) next

  # Unit markers, in the frozen evaluation order.
  if (line ~ /^### Insight[^a-zA-Z]/ || line == "### Insight") { unit("insight"); next }
  if (line ~ /^### Failure pattern/)                           { unit("failure-pattern"); next }
  if (line ~ /^### Retrospective 追記/)                        { unit("addendum-pair"); next }
  if (line ~ /^\*\*Pair [0-9]+/)                               { unit("pair"); next }
  if (line ~ /^- Pair [0-9]+/)                                 { unit("pair-bullet"); next }
  if (line ~ /^- 最初の失敗/)                                   { unit("prose-pair"); next }
  if (line ~ /^#### [0-9]+\. / && index(container, "Failure") > 0) { unit("numbered-item"); next }

  # Container rules run after every unit rule: placing the bold-line rule first
  # would swallow bold pair markers and collapse a whole form.
  if (substr(line, 1, 4) == "### ")            { set_container(line); next }
  if (line ~ /^\*\*[^*]+\*\*:?[ \t]*$/)        { set_container(line); next }

  if (line ~ /^- \*\*/ || line ~ /^[0-9]+\. \*\*/ || line ~ /^\*\*/) {
    if (sec_key != "") sec_items++
  }
}

END { flush_doc() }
AWK

# --- scan every label -------------------------------------------------------
LABEL_COUNT=0
FILES_SCANNED=0

while IFS=$'\t' read -r label repo || [ -n "${label:-}" ]; do
  case "${label:-}" in ''|\#*) continue ;; esac
  LABEL_COUNT=$((LABEL_COUNT + 1))
  printf 'L\t%s\n' "$label" >> "$REC"

  cycles="${repo:-}/docs/cycles"
  if [ ! -d "$cycles" ]; then
    printf 'warn: label=%s has no docs/cycles; skipped\n' "$label" >&2
    continue
  fi

  # Enumerated through a variable rather than a process substitution: the latter
  # discards the exit status, so an IO or permission failure would silently
  # produce an empty ledger with a success status.
  if ! listing=$(find "$cycles" -maxdepth 1 -type f -name '*.md' | sort); then
    printf 'error: label=%s could not enumerate docs/cycles\n' "$label" >&2
    exit 1
  fi
  FILES=()
  while IFS= read -r f; do
    [ -n "$f" ] && FILES+=("$f")
  done <<< "$listing"
  nfiles=${#FILES[@]}
  FILES_SCANNED=$((FILES_SCANNED + nfiles))

  # Input identity: sha/dirty are absent for a non-git snapshot, so the digest
  # (content hashes only, never paths) is the primary identity check.
  if git -C "${repo:-}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sha=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || printf '%s' '-')
    [ -n "$sha" ] || sha='-'
    dirty=$(git -C "$repo" status --porcelain 2>/dev/null | awk 'END {print NR + 0}')
  else
    sha='-'; dirty='-'
  fi
  # Hashed from FILES rather than from a second find, so the digest cannot drift
  # from the file set that was actually parsed. Empty input hashes to the same
  # value either way.
  if [ "$nfiles" -gt 0 ]; then
    digest=$(shasum -a 256 "${FILES[@]}" 2>/dev/null | awk '{print $1}')
  else
    digest=''
  fi
  digest=$(printf '%s' "$digest" | LC_ALL=C sort | shasum -a 256 | awk '{print substr($1, 1, 16)}')
  printf 'I\t%s\t%s\t%s\t%d\t%s\n' "$label" "$sha" "$dirty" "$nfiles" "$digest" >> "$REC"

  if [ "$nfiles" -gt 0 ]; then
    awk -v LABEL="$label" "$PARSER" "${FILES[@]+"${FILES[@]}"}" >> "$REC"
  fi
done < "$CONF"

# --- render -----------------------------------------------------------------
if [ "$SUBCMD" = "ledger" ]; then
  printf '%s\n' "$LEDGER_HEADER"
  # A ledger row is a unit record with its leading type tag removed.
  awk -F'\t' '$1 == "U" { sub(/^U\t/, ""); print }' "$REC"
  exit 0
fi

awk -F'\t' \
  -v GEN="$(date '+%Y-%m-%d')" \
  -v GV="$GRAMMAR_VERSION" \
  -v NLABELS="$LABEL_COUNT" \
  -v NFILES="$FILES_SCANNED" '
# The key order below is part of the output contract: consumers match STAT
# fields with grep/awk against a fixed layout, so these lists are not reordered.
BEGIN {
  NFORM = split("insight failure-pattern addendum-pair pair pair-bullet prose-pair numbered-item", FORM, " ")
  NPOL  = split("explicit_failure explicit_positive unknown", POL, " ")
}
function stat_line(l,   s, i) {
  s = "STAT label=" l
  s = s " docs_with_retro=" (docs[l] + 0)
  s = s " retro_sections=" (secs[l] + 0)
  s = s " docs_with_units=" (docsu[l] + 0)
  s = s " units=" (units[l] + 0)
  for (i = 1; i <= NFORM; i++) s = s " " FORM[i] "=" (fcnt[l, FORM[i]] + 0)
  for (i = 1; i <= NPOL;  i++) s = s " " POL[i]  "=" (pcnt[l, POL[i]] + 0)
  s = s " zero_unit=" (zero[l] + 0)
  return s
}
function bump(l, form, pol) {
  units[l]++;      units["TOTAL"]++
  fcnt[l, form]++; fcnt["TOTAL", form]++
  pcnt[l, pol]++;  pcnt["TOTAL", pol]++
}
$1 == "L" { nl++; order[nl] = $2; next }
$1 == "I" { inp[$2] = "INPUT label=" $2 " sha=" $3 " dirty=" $4 " files=" $5 " digest=" $6; next }
$1 == "D" {
  docs[$2]++; docs["TOTAL"]++
  secs[$2] += $4; secs["TOTAL"] += $4
  if ($5 + 0 > 0) { docsu[$2]++; docsu["TOTAL"]++ }
  next
}
$1 == "Z" {
  zero[$2]++; zero["TOTAL"]++
  nzero++; zero_label[nzero] = $2; zero_doc[nzero] = $3
  next
}
$1 == "U" { bump($2, $6, $10); next }
$1 == "S" {
  k = $2 SUBSEP $3 SUBSEP $4
  if (!(k in skip_row)) { nskip++; skip_row[k] = nskip; skip_label[nskip] = $2; skip_kind[nskip] = $3; skip_cont[nskip] = $4 }
  skip_count[skip_row[k]] += $5
  next
}
END {
  print "# Retrospective Unit Ledger"
  print ""
  print "One row per retrospective unit, extracted from `## Retrospective` regions under grammar v2."
  print "Repository identities are reduced to labels; the mapping lives outside both repositories."
  print ""
  print "## Per-label totals"
  print ""
  print "| label | docs_with_retro | retro_sections | docs_with_units | units | zero_unit |"
  print "|---|---|---|---|---|---|"
  for (i = 1; i <= nl; i++) {
    l = order[i]
    printf "| %s | %d | %d | %d | %d | %d |\n", l, docs[l] + 0, secs[l] + 0, docsu[l] + 0, units[l] + 0, zero[l] + 0
  }
  printf "| TOTAL | %d | %d | %d | %d | %d |\n", docs["TOTAL"] + 0, secs["TOTAL"] + 0, docsu["TOTAL"] + 0, units["TOTAL"] + 0, zero["TOTAL"] + 0
  print ""
  print "## Form distribution"
  print ""
  print "| form | count |"
  print "|---|---|"
  for (i = 1; i <= NFORM; i++) printf "| %s | %d |\n", FORM[i], fcnt["TOTAL", FORM[i]] + 0
  print ""
  print "## Polarity distribution"
  print ""
  print "| polarity | count |"
  print "|---|---|"
  for (i = 1; i <= NPOL; i++) printf "| %s | %d |\n", POL[i], pcnt["TOTAL", POL[i]] + 0
  print ""
  print "`unknown` is an observation, not a default: the source text says neither."
  print ""
  print "## Zero-unit docs"
  print ""
  if (nzero == 0) print "None."
  else for (i = 1; i <= nzero; i++) printf "- %s / %s\n", zero_label[i], zero_doc[i]
  print ""
  print "## Excluded enumerations"
  print ""
  if (nskip == 0) print "None."
  else {
    print "| label | kind | container | count |"
    print "|---|---|---|---|"
    for (i = 1; i <= nskip; i++)
      printf "| %s | %s | %s | %d |\n", skip_label[i], skip_kind[i], skip_cont[i], skip_count[i]
  }
  print ""
  print "## Machine-readable"
  print ""
  for (i = 1; i <= nl; i++) if (order[i] in inp) print inp[order[i]]
  for (i = 1; i <= nl; i++) print stat_line(order[i])
  print stat_line("TOTAL")
  for (i = 1; i <= nzero; i++) printf "ZERO label=%s doc=%s\n", zero_label[i], zero_doc[i]
  for (i = 1; i <= nskip; i++)
    printf "SKIP label=%s kind=%s container=%s count=%d\n", skip_label[i], skip_kind[i], skip_cont[i], skip_count[i]
  printf "GRAMMAR %s generated=%s labels=%d files_scanned=%d\n", GV, GEN, NLABELS, NFILES
}' "$REC"

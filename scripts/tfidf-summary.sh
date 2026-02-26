#!/bin/bash
# tfidf-summary.sh - Compute TF-IDF scores from observation log.jsonl
#
# Usage: bash scripts/tfidf-summary.sh [log.jsonl path]
# Output: JSON array to stdout
# Exit: 0 (success), 0 + [] (bootstrap/empty data)

set -euo pipefail

LOG_FILE="${1:-$HOME/.claude/dev-crew/observations/log.jsonl}"

# Empty or missing file → empty array
if [ ! -s "$LOG_FILE" ]; then
  echo "[]"
  exit 0
fi

# Extract session_id, tool_name, target as TSV, then compute TF-IDF in awk
jq -r '[.session_id, .tool_name, .target // ""] | @tsv' "$LOG_FILE" | \
awk -F'\t' '
BEGIN {
  # Noise words for Bash targets
  split("for if while do done then else fi echo test true false", noise_arr, " ")
  for (i in noise_arr) noise[noise_arr[i]] = 1
}

# Pass 1: Build term per row, accumulate counts
{
  sid = $1
  tool = $2
  target = $3

  # Skip empty target
  if (target == "") next

  term = ""

  if (tool == "Bash") {
    # Extract first token from target
    split(target, tokens, " ")
    cmd = tokens[1]

    # Skip noise
    if (cmd in noise) next
    if (cmd == "#") next

    # Skip variable assignments (e.g. DATABASE_URL="...")
    if (cmd ~ /=/) next

    # Basename for paths
    if (cmd ~ /^[.\/]/) {
      n = split(cmd, parts, "/")
      cmd = parts[n]
    }

    if (cmd == "") next

    # Sanitize: keep only alphanumeric, dash, underscore, dot
    gsub(/[^a-zA-Z0-9._-]/, "", cmd)
    if (cmd == "") next

    term = "Bash:" cmd

  } else if (tool == "Edit" || tool == "Write" || tool == "Read" || tool == "Grep" || tool == "Glob") {
    # Extract extension from target
    if (target ~ /\.[a-zA-Z0-9]+$/) {
      n = split(target, parts, ".")
      ext = parts[n]
      # Skip very long "extensions" (not real extensions)
      if (length(ext) <= 10) {
        term = tool ":*." ext
      }
    }
    # No extension → skip
    if (term == "") next

  } else {
    term = tool ":" tool
  }

  # Track session set
  sessions[sid] = 1

  # Count per session per term
  session_term[sid, term]++

  # Count total ops per session
  session_total[sid]++

  # Global term count
  term_count[term]++

  # Track which sessions have this term
  if (!term_session_seen[term, sid]) {
    term_sessions[term]++
    term_session_seen[term, sid] = 1
  }

  # Track all terms
  all_terms[term] = 1
}

END {
  # Count total sessions
  total_sessions = 0
  for (s in sessions) total_sessions++

  # Bootstrap: < 20 sessions → empty array
  if (total_sessions < 20) {
    print "[]"
    exit
  }

  # Compute TF-IDF for each term
  first = 1
  printf "["

  # Collect terms into indexed array for sorted output
  n = 0
  for (t in all_terms) {
    n++
    term_list[n] = t
  }

  for (i = 1; i <= n; i++) {
    t = term_list[i]

    # TF = average of (count_in_session / total_ops_in_session) across sessions with this term
    tf_sum = 0
    for (s in sessions) {
      key = s SUBSEP t
      if (key in session_term) {
        tf_sum += session_term[key] / session_total[s]
      }
    }
    tf = tf_sum / total_sessions

    # IDF = log2(total_sessions / (sessions_with_term + 1))
    idf = log(total_sessions / (term_sessions[t] + 1)) / log(2)
    if (idf < 0) idf = 0

    tfidf = tf * idf

    cnt = term_count[t]
    sess = term_sessions[t]

    # JSON-escape term (replace backslash and double-quote)
    safe_t = t
    gsub(/\\/, "\\\\", safe_t)
    gsub(/"/, "\\\"", safe_t)

    if (!first) printf ","
    first = 0
    printf "{\"term\":\"%s\",\"tf\":%.6f,\"idf\":%.4f,\"tfidf\":%.6f,\"count\":%d,\"sessions\":%d}", \
      safe_t, tf, idf, tfidf, cnt, sess
  }

  print "]"
}
'

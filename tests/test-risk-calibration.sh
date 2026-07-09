#!/bin/bash
# test-risk-calibration.sh - risk-classifier.sh スコアキャリブレーション検証
# 代表的なファイルパターンを入力して期待スコアレンジを検証する
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLASSIFIER="$BASE_DIR/skills/review/risk-classifier.sh"

passed=0
failed=0
errors=""

assert() {
  local tc="$1" desc="$2" result="$3"
  if [ "$result" = "true" ]; then
    echo "  PASS: $tc - $desc"
    passed=$((passed + 1))
  else
    echo "  FAIL: $tc - $desc"
    failed=$((failed + 1))
    errors="${errors}\n  FAIL: $tc - $desc"
  fi
}

echo "=== Risk Calibration Tests ==="

# TC-01: Markdown のみ (docs変更) → LOW
echo ""
echo "TC-01: Markdown only → LOW"
tmpfiles=$(mktemp)
tmpdiff=$(mktemp)
trap 'rm -f "$tmpfiles" "$tmpdiff"' EXIT
echo "docs/README.md" > "$tmpfiles"
cat > "$tmpdiff" << 'DIFF'
--- a/docs/README.md
+++ b/docs/README.md
@@ -1,3 +1,4 @@
 # README

 This is documentation.
+Updated content.
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
assert "TC-01" "Markdown only → LOW (got: $output)" \
  "$([ "$level" = "LOW" ] && echo true || echo false)"

# TC-02: テストのみ → LOW (score 10)
echo ""
echo "TC-02: Test file only → LOW"
echo "tests/test-foo.sh" > "$tmpfiles"
cat > "$tmpdiff" << 'DIFF'
--- a/tests/test-foo.sh
+++ b/tests/test-foo.sh
@@ -1,3 +1,4 @@
 #!/bin/bash
 echo "test"
+echo "new test"
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
score=$(echo "$output" | sed 's/.*score://')
assert "TC-02" "Test only → LOW, score=10 (got: $output)" \
  "$([ "$level" = "LOW" ] && [ "$score" -eq 10 ] && echo true || echo false)"

# TC-03: auth + migration → MEDIUM-HIGH
echo ""
echo "TC-03: auth + migration → MEDIUM or HIGH"
cat > "$tmpfiles" << 'FILES'
auth/login.php
migrations/001.sql
FILES
cat > "$tmpdiff" << 'DIFF'
--- a/auth/login.php
+++ b/auth/login.php
@@ -1,3 +1,4 @@
 <?php
 function login($user, $pass) {
+  $stmt = DB::select("SELECT * FROM users WHERE email = ?", [$user]);
 }
--- a/migrations/001.sql
+++ b/migrations/001.sql
@@ -0,0 +1,3 @@
+CREATE TABLE sessions (
+  id INT PRIMARY KEY
+);
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
assert "TC-03" "auth + migration → MEDIUM or HIGH (got: $output)" \
  "$([ "$level" = "MEDIUM" ] || [ "$level" = "HIGH" ] && echo true || echo false)"

# TC-04: wide change with >5 modified real files → MEDIUM+
# FP非依存の legitimate シグナルで到達させる (fixture は docs/d.md の "Updated." に
# 依存していた FP casualty を修正。filecount>5(+15) + dirspread>=3(+15) + test(+10) = 40)
echo ""
echo "TC-04: Wide change with >5 modified real files (3 dirs, incl. test file) → MEDIUM+"
cat > "$tmpfiles" << 'FILES'
src/a.ts
src/b.ts
lib/c.ts
lib/d.ts
tests/e.ts
tests/f.ts
FILES
cat > "$tmpdiff" << 'DIFF'
--- a/src/a.ts
+++ b/src/a.ts
@@ -1 +1,2 @@
 export const a = 1;
+export const aa = 2;
--- a/lib/c.ts
+++ b/lib/c.ts
@@ -1 +1,2 @@
 export const c = 3;
+export const cc = 4;
--- a/tests/e.ts
+++ b/tests/e.ts
@@ -1 +1,2 @@
 test('foo', () => {});
+test('bar', () => {});
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
assert "TC-04" "Wide change (FP非依存) → MEDIUM or HIGH (got: $output)" \
  "$([ "$level" = "MEDIUM" ] || [ "$level" = "HIGH" ] && echo true || echo false)"

# TC-05: セキュリティ集中 → HIGH
# auth(+25) + crypto(+30) + DB(+25) = 80 → HIGH
echo ""
echo "TC-05: Security-focused → HIGH"
echo "auth/token.php" > "$tmpfiles"
cat > "$tmpdiff" << 'DIFF'
--- a/auth/token.php
+++ b/auth/token.php
@@ -1,3 +1,8 @@
 <?php
 function generateToken() {
+  $secret = getenv('APP_SECRET');
+  $password = hash('sha256', $input);
+  $token = encrypt($password, $secret);
+  $stmt = DB::select("SELECT * FROM tokens WHERE user_id = ?", [$userId]);
+  DB::insert("INSERT INTO sessions (token) VALUES (?)", [$token]);
 }
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
assert "TC-05" "Security-focused → HIGH (got: $output)" \
  "$([ "$level" = "HIGH" ] && echo true || echo false)"

# TC-06: 新規ファイルのみ (6個) → file_count bonus 除外で LOW
echo ""
echo "TC-06: New files only (6) → LOW (file_count bonus excluded)"
cat > "$tmpfiles" << 'FILES'
docs/a.md
docs/b.md
docs/c.md
docs/d.md
docs/e.md
docs/f.md
FILES
cat > "$tmpdiff" << 'DIFF'
--- /dev/null
+++ b/docs/a.md
@@ -0,0 +1 @@
+# A
--- /dev/null
+++ b/docs/b.md
@@ -0,0 +1 @@
+# B
--- /dev/null
+++ b/docs/c.md
@@ -0,0 +1 @@
+# C
--- /dev/null
+++ b/docs/d.md
@@ -0,0 +1 @@
+# D
--- /dev/null
+++ b/docs/e.md
@@ -0,0 +1 @@
+# E
--- /dev/null
+++ b/docs/f.md
@@ -0,0 +1 @@
+# F
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
assert "TC-06" "New files only → LOW (got: $output)" \
  "$([ "$level" = "LOW" ] && echo true || echo false)"

# TC-07: doc-only diff (rules/*.md + docs/*.md, updated:/deleted 含む, 8 files, 3 dirs)
# → not HIGH (score<60)
# Given: doc-only diff with SQL-FP-triggering prose ("updated:", "deleted")
# When: classifier 実行
# Then: code_only_diff 導入後は SQL FP が code hunk から除外され level != HIGH
echo ""
echo "TC-07: doc-only diff (prose FP) → not HIGH (score<60)"
cat > "$tmpfiles" << 'FILES'
rules/a.md
rules/b.md
docs/c.md
docs/d.md
docs/e.md
notes/f.md
notes/g.md
notes/test-notes.md
FILES
cat > "$tmpdiff" << 'DIFF'
--- a/rules/a.md
+++ b/rules/a.md
@@ -1,3 +1,4 @@
 # Rule A
+updated: 2026-07-09
 content here
+more content
--- a/docs/c.md
+++ b/docs/c.md
@@ -1,2 +1,3 @@
 # Doc C
+Old section deleted and replaced.
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
assert "TC-07" "doc-only diff (prose FP) → not HIGH (got: $output)" \
  "$([ "$level" != "HIGH" ] && echo true || echo false)"

# TC-08: mixed diff (code .sh に real SQL + doc .md に updated:)
# → SQL シグナルは code 部から発火し score に反映される (regression guard)
# Given: code hunk (DB::query SELECT) + doc hunk (updated: prose)
# When: classifier 実行
# Then: SQL シグナル (+25) が score に含まれる (score>=25)
echo ""
echo "TC-08: mixed diff (code SQL + doc prose) → SQL fires from code part"
cat > "$tmpfiles" << 'FILES'
src/query.sh
docs/notes.md
FILES
cat > "$tmpdiff" << 'DIFF'
--- a/src/query.sh
+++ b/src/query.sh
@@ -1,2 +1,3 @@
 echo "start"
+DB::query("SELECT * FROM users")
--- a/docs/notes.md
+++ b/docs/notes.md
@@ -1,2 +1,3 @@
 # Notes
+updated: today
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
score=$(echo "$output" | sed 's/.*score://')
assert "TC-08" "mixed diff → SQL reflected in score (score>=25, got: $output)" \
  "$([ "$score" -ge 25 ] && echo true || echo false)"

# TC-09: doc hunk + 削除 code ファイル (+++ /dev/null) の混在 diff
# → 削除 code の SQL が score に反映される (under-score なしの回帰 pin)
# Given: doc hunk (no signal) + deleted src/legacy.php hunk with SELECT/DB::
# When: classifier 実行 (堅牢版 code_only_diff は old path 由来で code 判定)
# Then: SQL シグナルが score に反映 (score>=25)
echo ""
echo "TC-09: deleted code file (+++ /dev/null) → SQL not under-scored"
cat > "$tmpfiles" << 'FILES'
docs/a.md
src/legacy.php
FILES
cat > "$tmpdiff" << 'DIFF'
--- a/docs/a.md
+++ b/docs/a.md
@@ -1,2 +1,3 @@
 # Notes
+doc note only
--- a/src/legacy.php
+++ /dev/null
@@ -1,3 +0,0 @@
-<?php
-$stmt = DB::select("SELECT * FROM users");
-echo "bye";
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
score=$(echo "$output" | sed 's/.*score://')
assert "TC-09" "deleted code file → SQL reflected (score>=25, got: $output)" \
  "$([ "$score" -ge 25 ] && echo true || echo false)"

# TC-10: binary diff (`Binary files ... differ`, +++ ヘッダなし) の堅牢性
# → クラッシュせず正常な level:score を返す
echo ""
echo "TC-10: binary diff → no crash, valid level:score output"
cat > "$tmpfiles" << 'FILES'
assets/img.png
FILES
cat > "$tmpdiff" << 'DIFF'
diff --git a/assets/img.png b/assets/img.png
index abc1234..def5678 100644
Binary files a/assets/img.png and b/assets/img.png differ
DIFF
rc=0
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null) || rc=$?
assert "TC-10" "binary diff → no crash, rc=0 valid output (rc=$rc, got: $output)" \
  "$([ "$rc" -eq 0 ] && echo "$output" | grep -qE '^(LOW|MEDIUM|HIGH) score:[0-9]+$' && echo true || echo false)"

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [ "$failed" -gt 0 ]; then
  echo -e "\nFailures:$errors"
  exit 1
fi

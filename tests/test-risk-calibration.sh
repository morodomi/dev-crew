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

# TC-04: 広範囲 (4ディレクトリ) → MEDIUM+
echo ""
echo "TC-04: Wide change (4 dirs) → MEDIUM+"
cat > "$tmpfiles" << 'FILES'
src/a.ts
lib/b.ts
tests/c.ts
docs/d.md
FILES
cat > "$tmpdiff" << 'DIFF'
--- a/src/a.ts
+++ b/src/a.ts
@@ -1 +1,2 @@
 export const a = 1;
+export const b = 2;
--- a/lib/b.ts
+++ b/lib/b.ts
@@ -1 +1,2 @@
 export const c = 3;
+export const d = 4;
--- a/tests/c.ts
+++ b/tests/c.ts
@@ -1 +1,2 @@
 test('foo', () => {});
+test('bar', () => {});
--- a/docs/d.md
+++ b/docs/d.md
@@ -1 +1,2 @@
 # Doc
+Updated.
DIFF
output=$(bash "$CLASSIFIER" "$tmpfiles" "$tmpdiff" 2>/dev/null)
level=$(echo "$output" | awk '{print $1}')
assert "TC-04" "Wide change → MEDIUM or HIGH (got: $output)" \
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

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [ "$failed" -gt 0 ]; then
  echo -e "\nFailures:$errors"
  exit 1
fi

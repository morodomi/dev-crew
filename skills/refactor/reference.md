# refactor Reference

SKILL.mdの詳細情報。必要時のみ参照。

## リファクタリングパターン

### DRY (Don't Repeat Yourself)

```
// Before: 重複
user.name = capitalize(lowercase(input.name))
user.email = lowercase(input.email)

// After: 共通化
function normalize(value) -> capitalize(lowercase(value))
```

### 定数化

```
// Before: マジックナンバー
if attempts > 5 ...

// After: 定数
MAX_LOGIN_ATTEMPTS = 5
if attempts > MAX_LOGIN_ATTEMPTS ...
```

### 未使用import

```
// Before: 未使用
import { useState, useEffect, useCallback } from 'react'
// useCallback is never used

// After: 削除
import { useState, useEffect } from 'react'
```

### let→const

```
// Before: 再代入なし
let result = calculate(input)
return result

// After: const
const result = calculate(input)
return result
```

### メソッド分割

```
// Before: 長いメソッド
function processOrder()
  // 50行のコード...

// After: 分割
function processOrder()
  validateOrder()
  calculateTotal()
  applyDiscounts()
  saveOrder()
```

### N+1クエリ

```
// Before: N+1
for user in users:
  orders = db.query("SELECT * FROM orders WHERE user_id = ?", user.id)

// After: 一括取得
user_ids = [u.id for u in users]
orders = db.query("SELECT * FROM orders WHERE user_id IN (?)", user_ids)
orders_by_user = group_by(orders, 'user_id')
```

### 命名一貫性

```
// Before: 混在
getUserData()   // camelCase
get_user_name() // snake_case

// After: プロジェクト規約に統一
get_user_data()
get_user_name()
```

## インクリメンタルワークフロー

1改善→テスト→次改善の流れ:

```
1. チェックリスト項目1（重複コード）を確認
2. 改善があれば実施 → テスト実行 → PASS確認
3. チェックリスト項目2（定数化）を確認
4. ... 以降同様
5. 全項目完了 → Verification Gate
```

改善途中でテストが壊れた場合:
1. `git checkout` で変更を戻す
2. より小さな単位でやり直す

## Error Handling

### テストが壊れた場合

```
リファクタリング後、テストが失敗しました。

対応:
1. 変更を元に戻す (git checkout)
2. 小さな単位でリファクタリングをやり直す
3. 各変更後にテストを実行
```

### リファクタリング範囲が大きすぎる場合

```
リファクタリングの範囲が大きすぎます。

推奨:
1. 1つの改善項目に絞る
2. テストを実行して確認
3. 次の改善項目へ
```

# Document Hierarchy

ドキュメント権威階層。AIがドリフトしたとき、上位レイヤーに戻れば正しい方向が分かる。

## 4-Layer Authority

```
Layer 1: PURPOSE (WHY)
  PHILOSOPHY.md / AGENTS.md Overview
  → プロジェクトの存在理由、原則
  → AIがドリフトしたらここに戻る

Layer 2: PLANNING (WHAT)
  ROADMAP.md / GitHub Issues / plan files
  → 何を実現するか。形式は自由（必須ではない）

Layer 3: DESIGN (HOW)
  docs/* (architecture.md, terminology.md, project-conventions/)
  → どう実現するか。技術設計、規約

Layer 4: PROCEDURE (STEPS)
  skills/*/reference.md, scripts/gates/*.sh
  → 具体的な手順。スキルの詳細手順、決定論的ゲート
```

## 矛盾解決ルール

上位レイヤーが常に勝つ。PHILOSOPHY.md の原則と reference.md の手順が矛盾した場合、PHILOSOPHY.md に従う。

## onboarded プロジェクトへの適用

| Layer | 必須/任意 | 配置先 |
|-------|----------|--------|
| Layer 1 (PURPOSE) | 必須 | AGENTS.md Overview に記述 |
| Layer 2 (PLANNING) | 任意 | ROADMAP.md でも Issues でもよい |
| Layer 3-4 | dev-crew自動生成 | docs/, .claude/rules/, skills/ |

## ファイル配置マップ

どのスキルが何をどこに生成するかの一覧。

| スキル | 生成ファイル | レイヤー |
|--------|-------------|---------|
| onboard | AGENTS.md, CLAUDE.md, docs/STATUS.md, docs/README.md, .claude/rules/*, .claude/hooks/* | L1, L3, L4 |
| spec | docs/cycles/YYYYMMDD_HHMM_*.md (plan files) | L2 |
| sync-plan | docs/cycles/YYYYMMDD_HHMM_*.md (Cycle doc) | L2 |
| skill-maker | skills/*/SKILL.md, skills/*/reference.md | L4 |
| commit | docs/STATUS.md (自動更新) | L3 |
| review | Cycle doc の Review Summary セクション | L2 |
| phase-compact | Cycle doc の Phase Summary セクション | L2 |
| learn | docs/instincts/*.md | L3 |

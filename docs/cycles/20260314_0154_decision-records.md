---
feature: Decision Records (ADR自動化)
cycle: 20260314_0154
phase: DONE
complexity: trivial
test_count: 11
risk_level: low
created: 2026-03-14T01:54:00+09:00
updated: 2026-03-14T01:54:00+09:00
---

# Decision Records (ADR自動化)

ROADMAP Phase 5. kickoff debateでcross-cycle判断が発生した際にADRを `docs/decisions/` に蓄積する仕組みを整備する。

## Scope Definition

### In Scope
- docs/decisions/.gitkeep (new): ディレクトリ作成
- docs/decisions/TEMPLATE.md (new): ADRテンプレート（ROADMAP定義準拠）
- skills/kickoff/reference.md (edit): ADRテンプレートをTEMPLATE.md参照に変更
- skills/orchestrate/reference.md (edit): ADR参照セクション追加
- ROADMAP.md (edit): Phase 5ステータス更新
- AGENTS.md (edit): docs/decisions/ をProject Structureに追加

### Out of Scope
- Phase 6 (AGENTS.md Skill Propagation)
- ADR自動生成スクリプト（手動作成で十分）
- ADR番号の自動採番（ファイル名で管理: ADR-NNN-title.md）

## Environment

- Scope: docs-only change (テンプレート + ドキュメント参照)
- Layer: Plugin
- Risk: 20 (low) - ディレクトリ作成 + テンプレート + ドキュメント参照のみ

## Test List

### TODO
- [ ] TC-01: [正常系] docs/decisions/ディレクトリが存在する
- [ ] TC-02: [正常系] docs/decisions/TEMPLATE.mdが存在する
- [ ] TC-03: [正常系] TEMPLATE.mdにDecision Scorecardセクションがある
- [ ] TC-04: [正常系] TEMPLATE.mdにArguments（Accepted/Rejected/Deferred）がある
- [ ] TC-05: [正常系] kickoff/reference.mdがTEMPLATE.mdを参照している
- [ ] TC-06: [正常系] orchestrate/reference.mdにADR Referenceセクションがある
- [ ] TC-07: [正常系] ROADMAP.md Phase 5がDONEに更新されている
- [ ] TC-08: [境界値] TEMPLATE.mdにStatus行（accepted/rejected/deferred）がある
- [ ] TC-09: [リグレッション] kickoff/reference.mdにADR作成条件3つが残存している
- [ ] TC-10: [正常系] TEMPLATE.mdにContext/Decision/Consequencesセクションがある
- [ ] TC-11: [リグレッション] test-kickoff-debate.shが全PASSする

## Implementation Notes

### Design
- TEMPLATE.mdはROADMAP定義のADRテンプレートをそのまま使用
- kickoff/reference.mdのADR作成条件（L187-192）は残し、テンプレート本体をTEMPLATE.md参照に置換
- orchestrate/reference.mdにADR Referenceセクションを追加（DISCOVERED issue起票後に配置）
- orchestrateがADRを参照する根拠: ROADMAP Architecture (L79) 「decisions/に理由を記録」「decisions/から構成」

### Debate Summary (Codex Review)
- Rounds: 1
- Codex Session: 019ce81f-cb1c-72a2-ab62-c949bc01b22b
- Accepted: Phase 2リグレッション保護(TC-09,TC-11追加), TEMPLATE全セクション検証(TC-10追加), リスク評価にリグレッションテスト明記
- Rejected: orchestrate変更はスコープクリープ(ROADMAP Architecture L79で根拠あり)
- Deferred: なし

## Progress Log

### KICKOFF - 01:54
- Cycle doc作成
- Codexレビュー実施、指摘3件Accepted・1件Rejected
- TC-09,TC-10,TC-11追加（test_count: 8→11）

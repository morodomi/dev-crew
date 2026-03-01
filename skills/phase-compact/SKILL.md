---
name: phase-compact
description: TDDフェーズ境界でCycle docにPhase Summaryを永続化し、/compact実行を案内する。orchestrateから自動呼び出し、または手動「phase-compact」「コンテキスト圧縮」。
allowed-tools: Read, Write, Edit
---

# Phase Compact

フェーズ完了時にコンテキストをCycle docに永続化し、Claude Code組み込みの `/compact` に圧縮を委譲する。

## Progress Checklist

```
phase-compact Progress:
- [ ] Cycle doc特定・現フェーズ確認
- [ ] Phase Summary生成・追記
- [ ] /compact 実行案内
- [ ] 次フェーズ案内
```

## Phase Summary Format

Cycle docに以下の形式で追記する:

```markdown
### Phase: [PHASE_NAME] - Completed at HH:MM
**Artifacts**: [created/modified file list]
**Decisions**: [key decisions made in this phase]
**Metrics**: line_count=[N], file_count=[N], test_count=[N]
**Next Phase Input**: [what the next phase needs to know]
```

## Workflow

### Step 1: Cycle doc特定・現フェーズ確認

```bash
ls -t docs/cycles/*.md 2>/dev/null | head -1
```

Cycle docのProgressチェックリストから現在のフェーズを特定。

### Step 2: Phase Summary生成・Cycle doc追記

現フェーズの成果物・決定事項・引継ぎ情報を収集し、Phase Summary formatでCycle docに追記。
各フェーズで永続化する内容: [reference.md](reference.md#compaction-points)

### Step 3: /compact 委譲

Cycle docへの永続化完了後、コンテキスト圧縮をClaude Code組み込みの `/compact` に委譲する。

```
Phase Summary をCycle docに追記しました。
コンテキストを圧縮するため /compact を実行してください。
```

`/compact` はCLI内部コマンドのためプログラムから直接呼べない。ユーザーに実行を促す。

### Step 4: 次フェーズ案内

```
/compact 完了後、次のフェーズを開始してください:
  現在: [CURRENT_PHASE]
  次: [NEXT_PHASE]
  コマンド: /[next-phase-skill]
```

次フェーズ開始時はCycle docを読み直してコンテキストを復元する。

## Trigger

- 手動: `/phase-compact`
- orchestrateモードではPdMが直接Phase Summaryを書き込むため、このスキルは呼ばれない

## Reference

- Compaction Points詳細: [reference.md](reference.md)

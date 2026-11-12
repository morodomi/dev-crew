# Codify Withdrawn — rules に反映しない codified の台帳

codify-insight が `codified`・`Destination: rule` と判定したが、依存する仕組みが消えたため rules に書かないものを記録する。`scripts/codify-landing.sh` は、ここに理由付きで書かれた `<cycle_id> #N` を着地扱いにする。

取り下げてよい理由は「依存する仕組みが消えた」だけ。各行には消えた仕組みと、消えたことが分かる commit かパスを書く。「テストやゲートがある」は理由にしない。同じ教訓の insight をまとめた場合は、まとめ先の条項に両方の出典を並べる（ここには書かない）。

- 20260717_1605 #2 — Block 0 での codify gate の自動起動に依存する（起動時に前の cycle doc を書き換え、scope に同梱される問題）。orchestrate は件数を通知するだけになり、自動起動は commit 4f55121 で消えた

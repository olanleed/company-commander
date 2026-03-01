# ドキュメントツリー再設計・移行計画 v0.1

## 1. 目的

- `docs/root/military_equipment_2026_detailed.md` を装備知識の単一ルートとして扱う
- `docs/vehicles_tree` と `docs/weapons_tree` をルート配下サブツリーとして再定義する
- 将来的なユニット追加・変更時に、どこへ追記すべきか迷わない構造を作る
- `data/catalog/*.json` と知識ドキュメントの対応を取りやすくする

## 2. 背景課題（現状）

- ツリー文書が複数あり、親子関係が明示されていない
- 「分類ツリー文書」と「国別・具体値文書」が同列に置かれている
- `data/catalog` の変更時に、参照すべき docs の起点が曖昧
- ドキュメント整合性の検証手順が未定義

## 3. ターゲット情報アーキテクチャ

### 3.1 階層

1. Root: `docs/root/military_equipment_2026_detailed.md`
2. Branch: `docs/vehicles_tree/*`, `docs/weapons_tree/*`
3. Leaf: 各 Branch 配下の個別テーマ・国別詳細

### 3.2 ドキュメント種別

- Taxonomy Doc: 分類のみを定義（語彙・構造の基準）
- Index Doc: Branch 内の入口。対象読者、対象範囲、関連 Leaf へのリンクを持つ
- Detail Doc: 具体値、事例、ソース、ゲーム値変換を持つ

### 3.3 命名方針

- 継続利用: 既存ファイル名は原則維持（移行コスト低減）
- 新規追加: `<domain>_<topic>_<year>_<scope>.md`
- 用語は `snake_case`、年次は `2026` のように4桁固定

## 4. 設計方針

### 4.1 ルート主導

- すべての Branch は Root の分類語彙に従う
- Branch/Leaf に新カテゴリを追加したい場合、先に Root に語彙を追加する

### 4.2 分類と具体値の分離

- 分類議論（taxonomy）と、数値・実装向け仕様（detail）を混在させない
- Detail Doc には必ず「どの Root ノードに属するか」を記載する

### 4.3 `data/catalog` 連携前提

- 車両ID (`USA_M1A2_SEPv3` など) と、対応ドキュメントを辿れるようにする
- 武器ID (`CW_*`) も同様に対応づける
- 目的は「データを変えたときに必要な根拠資料へ即到達できること」

### 4.4 変更容易性優先

- いきなり大規模なファイル移動はしない
- まずリンク構造と責務境界を確立してから、必要最小限の統合を行う

## 5. リファクタリング方針（段階的）

### Phase 0: インベントリ固定

- `vehicles_tree`, `weapons_tree` の全ファイル一覧を固定
- 各ファイルを `taxonomy / index / detail` に分類
- 重複テーマ（例: 弾薬分類と国別弾薬記述）をリスト化

### Phase 1: ルート確立

- Root に Branch への公式リンクを追加
- Root を「語彙の正」と明示
- `docs/README.md` から Root へ到達できる導線を追加

### Phase 2: Branch 正規化

- Branch ごとに Index Doc を配置（必要なら新設）
- Leaf には `属する Root ノード` と `関連 data/catalog キー` を明記
- 「分類のみ」の文書と「国別詳細」文書を役割分離

### Phase 3: データ連携

- `data/catalog/vehicles_*.json` の vehicle ID と docs の対応表を作成
- `WeaponData` の concrete weapon ID と docs の対応表を作成
- 対応漏れを CI/手動チェックで検知できる状態にする

### Phase 4: 重複統合

- 内容重複が高い文書を統合または相互参照へ置換
- 非推奨文書は `deprecated` セクションを追加し、移行先リンクを記載

## 6. テスト設計（ドキュメント品質ゲート）

### 6.1 リンク整合テスト

- Root から Branch、Branch から Leaf へ辿れること
- 相対リンク切れゼロ
- テスト方法:
  - 手動: エディタリンクチェック
  - 自動: `rg` と存在確認スクリプト（将来追加）

### 6.2 構造整合テスト

- 各 Detail Doc が「所属 Root ノード」を持つこと
- 新規ファイルが命名規約に従うこと
- `taxonomy` 文書に具体数値が混入していないこと

### 6.3 カタログ対応テスト

- `data/catalog/*.json` の全 `id` が docs 対応表に存在すること
- 主要 weapon ID も docs 対応表に存在すること
- 欠落時は「要資料化」として検出

### 6.4 回帰テスト（運用）

- 新ユニット追加PRで必須チェック:
  - カタログ追加
  - 対応 docs 更新
  - Root ノード紐付け

## 7. 受け入れ基準（Definition of Done）

- Root が Branch の親であることが文書上明確
- Branch 内各文書の役割が明示されている
- カタログIDから参照先 docs を辿れる
- 最低限の整合チェック手順が定義済み

## 8. 運用ルール（提案）

- 新規文書を追加する前に、既存 Branch へ追加可能か確認する
- 新カテゴリを作る場合は Root を先に更新する
- データ変更PRは docs 更新を同一PRで行う
- 数値根拠を追加した場合は出典または推定理由を残す

## 9. 次アクション

1. `docs/README.md` に Root 中心の導線を追加
2. `vehicles_tree` と `weapons_tree` の Index Doc 要否を判定
3. `data/catalog` 対応表（vehicles → docs）を作成
4. 将来、簡易リンクチェッカーを `tools/` に追加

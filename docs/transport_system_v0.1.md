# 輸送システム仕様書 v0.1

## 概要

IFV/APCへの歩兵乗車・下車を管理するシステム。

---

## 1. 基本機能

### 1.1 乗車 (Embark)

歩兵ユニットがIFV/APCに乗車する。

```gdscript
# 初期乗車（シナリオ開始時）
func embark_initial(transport: ElementInstance, infantry: ElementInstance)

# 乗車コマンド（ゲーム中）
func embark(transport: ElementInstance, infantry: ElementInstance) -> bool
```

#### 乗車条件

- 輸送車両が歩兵輸送可能 (`can_transport_infantry = true`)
- 輸送車両に空きがある (`embarked_infantry_id == ""`)
- 歩兵が乗車中でない (`is_embarked == false`)
- 両者が近接している（コマンド乗車時）

### 1.2 下車 (Disembark)

乗車中の歩兵が下車する。

```gdscript
func disembark(transport: ElementInstance) -> ElementInstance
```

#### 下車条件

- 輸送車両に歩兵が乗車中
- 輸送車両が移動中でない（推奨）

---

## 2. データモデル

### 2.1 ElementInstance (輸送車両側)

```gdscript
var embarked_infantry_id: String = ""  # 乗車中の歩兵ID
```

### 2.2 ElementInstance (歩兵側)

```gdscript
var is_embarked: bool = false          # 乗車中フラグ
var transport_vehicle_id: String = ""  # 乗車している車両ID
```

### 2.3 ElementType (車両定義)

```gdscript
var can_transport_infantry: bool = false  # 歩兵輸送可能か
var transport_capacity: int = 0           # 輸送人数（将来用）
```

---

## 3. 車両カタログ定義

### 3.1 JSON定義

```json
{
  "id": "CHN_ZBD04A",
  "class": "IFV",
  "can_transport_infantry": true,
  "transport_capacity": 7
}
```

### 3.2 輸送可能な車両タイプ

| クラス | 説明 | 例 |
|--------|------|-----|
| IFV | 歩兵戦闘車 | 04A式, BMP-3, M2A3 |
| APC | 装甲兵員輸送車 | 08式, BTR-82A, M1126 |
| WPC | 装輪装甲車 | 96式WPC |

---

## 4. 乗車中の挙動

### 4.1 位置同期

乗車中の歩兵は輸送車両と同じ位置に追従する。

```gdscript
# 輸送車両移動時
infantry.position = transport.position
```

### 4.2 戦闘

- **乗車中の歩兵**: 戦闘不可（将来、ポートからの射撃を追加予定）
- **輸送車両**: 通常通り戦闘可能

### 4.3 被弾

輸送車両が撃破された場合：
- 乗車中の歩兵にダメージ（将来実装）
- 強制下車（将来実装）

---

## 5. UI統合

### 5.1 ユニット表示

- 乗車中の歩兵は表示されない
- 輸送車両アイコンに乗車インジケータ（将来実装）

### 5.2 コマンド

- **乗車**: 歩兵選択 → 輸送車両を右クリック
- **下車**: 輸送車両選択 → 下車コマンド

---

## 6. 対象ファイル

| ファイル | 説明 |
|---------|------|
| `scripts/systems/transport_system.gd` | 輸送システム本体 |
| `scripts/data/element_data.gd` | ユニットデータ |
| `scripts/data/element_factory.gd` | ユニット生成 |
| `data/vehicles/*.json` | 車両カタログ |

---

## 7. 国別対応車両

### 日本 (JPN)

| 車両 | クラス | 輸送人数 |
|------|-------|---------|
| 89FV | IFV | 7 |
| 96WPC | WPC | 8 |

### アメリカ (USA)

| 車両 | クラス | 輸送人数 |
|------|-------|---------|
| M2A3 Bradley | IFV | 6 |
| M1126 Stryker | APC | 9 |

### ロシア (RUS)

| 車両 | クラス | 輸送人数 |
|------|-------|---------|
| BMP-3 | IFV | 7 |
| BTR-82A | APC | 7 |

### 中国 (CHN)

| 車両 | クラス | 輸送人数 |
|------|-------|---------|
| 04A式 (ZBD04A) | IFV | 7 |
| 04式 (ZBD04) | IFV | 7 |
| 09式 (ZBD09) | IFV | 7 |
| 08式 (ZBL08) | APC | 10 |

---

## 8. 既知の制限

### v0.1での制限

1. **輸送人数**: 1ユニット/1車両のみ（将来複数対応予定）
2. **ポート射撃**: 未実装
3. **車両撃破時の歩兵ダメージ**: 未実装
4. **強制下車**: 未実装

### 将来の拡張

- 複数分隊の輸送
- ポートからの射撃
- 車両撃破時の乗員損害
- 下車位置の指定
- 下車展開フォーメーション

---

## 9. 関連ドキュメント

- [units_v0.1.md](units_v0.1.md) - ユニットシステム
- [vehicle_catalog_v0.1.md](vehicle_catalog_v0.1.md) - 車両カタログ
- [combat_v0.1.md](combat_v0.1.md) - 戦闘システム

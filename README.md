# 日記感情アプリ

日々の出来事を感情と一緒に記録できる日記アプリです。

## ✨ 機能
* カレンダーから日付を選んで日記を書く
* 過去の日記を振り返る

## 🛠 使用技術
* Flutter (アプリ開発)
* Firebase (データの保存)
* Table Calendar (カレンダー機能)


## 🐛 既知の不具合と修正手順（テスト不合格ケース）

### 感情グラフが描画枠からはみ出す問題
感情レベルが最大値（5）や最小値（1）のときに、グラフの曲線設定（`isCurved: true`）の影響で線のふくらみが上下の枠線からはみ出してしまう挙動が発生します。

#### 🛠️ 修正用コード
`ChartPage` クラス内にある3箇所の `LineChartBarData` に対し、`preventCurveOverShooting: true` を追加することで、枠内からはみ出さないように補正できます。

```dart
// 修正例（うれしいグラフの場合。おこった・かなしい も同様に変更）
LineChartBarData(
  spots: happySpots, 
  color: Colors.pink, 
  barWidth: 4, 
  isCurved: true, 
  preventCurveOverShooting: true, // 👈 この行を追加してはみ出しを防止
  dotData: const FlDotData(show: true),
),

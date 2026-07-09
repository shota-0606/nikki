# 日記感情アプリ

日々の出来事を感情と一緒に記録できる日記アプリです。

## ✨ 機能
* カレンダーから日付を選んで日記を書く
* 過去の日記を振り返る

## 🛠 使用技術
* Flutter (アプリ開発)
* Firebase (データの保存)
* Table Calendar (カレンダー機能)


#原因対応再テスト結果19LineChartBarData で isCurved: true（曲線の描画）が有効なため、感情レベルが上限（5）や下限（1）に達した際、曲線のふくらみ制御点が minY・maxY の描画枠線を越えてはみ出してしまう。グラフを直線描画にするために isCurved: false に変更するか、曲線の一方ではみ出しを防ぐ preventCurveOverShooting: true を各 LineChartBarData に追加する。○

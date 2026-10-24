# Garmin Now Playing Data Field

Garmin Edge 530 の走行データ画面に、iPhone の Spotify で再生中の曲名・アーティスト名を表示するためのプロジェクト。

**開発初期段階です。まずダミーデータによる表示を実装し、iPhone からの通信は別工程で検証します。**

## 最初の目標

- Connect IQ / Monkey C の Data Field として実装する。
- 横幅いっぱいの1枠に曲名を大きく、アーティスト名を小さく表示する。
- 長い文字列は枠の幅に合わせて省略する。
- ジャケット画像、再生操作、Spotify Like は初期実装に含めない。

## 実装順

1. ダミー曲の2行表示と Edge 530 向けビルド。
2. シミュレーターと実機でデータ画面の分割・寸法・日本語表示を確認。
3. Edge 530 / API 3.3 の通信制約を検証。
4. iPhone ロック中の曲変更通知・切断復帰を実機で評価。
5. 検証結果に基づいて Spotify OAuth と配信経路を実装する。

## 設計元

[garmin-nowplaying-datafield（Cosense）](https://scrapbox.io/kouki/garmin-nowplaying-datafield)

公開リポジトリにはソースと開発手順のみを置きます。署名鍵、Spotify のトークン、ローカル SDK、個人の再生履歴は Git 管理から除外します。

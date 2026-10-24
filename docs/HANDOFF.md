# 開発引き継ぎ

更新日: 2026-10-24。別のマシンや新しいチャットから再開するための入口。

## 目的と最新の合意

iPhone で普段どおり音楽を再生し、iPhone をロックしたまま、Garmin Edge 530 の既存走行データページに曲名とアーティスト名を表示したい。
ユーザーは **Spotify と Apple Music の両方**を使う。取得経路は **Apple Media Service（AMS）による標準の再生情報**を優先して調べる。
独自 iPhone アプリを前面に出し続ける構成や Spotify 専用 OAuth を、前提にしない。

これは採用した検証方針であり、AMS の直接接続が実現済みという意味ではない。
表示の試作を終えた段階で、通信の成立性が最大の未解決事項。

## Mac へ移る必要があるか

| 作業 | Mac が必要か |
| --- | --- |
| Monkey C の編集・ビルド・テスト・シミュレーター | 不要。公式 SDK は Windows / macOS / Linux 向けに配布されている |
| Edge 530 から AMS へ直接接続できるかの調査 | 不要。まず API と接続条件を調べる |
| 直接接続できた場合の実機確認 | Edge 530 と iPhone が必要。Mac は必須ではない |
| 独自 iPhone アプリのビルド・実機署名 | macOS / Xcode が必要。ただし現在の主方針ではない |

Mac に移っても、Edge 530 の Bluetooth API の制約が解消するわけではない。
単に他アプリの「再生中」を読む目的で iPhone アプリを作れば解決する、とも想定しない。

## リポジトリと実装の現在地

- 公開リポジトリ: <https://github.com/ojimpo/garmin-nowplaying-datafield>
- 主ブランチ: `main`
- 引き継ぎ追記前の表示実装の基準コミット: `ef918bd`
- Connect IQ アプリ ID: `0e7452a432a14e80baf47e5fe3f0a6d1`
- 対象: `edge530`、manifest の最小 API: `3.3.0`
- Data Field 名: `Now Playing Demo`
- 通信権限: まだ要求していない。AMS、BLE、Spotify API、iOS コンパニオンはいずれも未実装。

`source/NowPlayingView.mc` が寸法と背景色に応じて描画し、`source/DemoSource.mc` が合成サンプルを供給する。
`source/TextFit.mc` はフォントの幅を測って `...` で省略する。
通常は15秒ごとに短い曲名・長い曲名・日本語・一時停止・未再生を切り替える。
小さすぎる高さには1行フォールバックもあるが、実機での網羅確認はこれから。

## 検証済みと未検証

Windows、SDK 9.3.0、Java 17、Edge 530 シミュレーター（API 3.3.1）で通常版・テスト版を strict ビルドし、警告なしで成功した。
テストは `demoTiming`、`fixedDemoSample`、`textFitsSlot` の3件が PASS。
7 Fields A の横長枠・半幅枠、長い曲名の省略、白黒背景、日本語表示を確認した。
7 Fields A の最上段は **246×63px**。シミュレーターは各枠に同じ Data Field を複製する。

日本語表示にはシミュレーターの `Settings > Language > Japanese (jpn)` を選ぶ。
英語設定では日本語サンプルの文字が表示されなかった。
画面例は [保存したスクリーンショット](images/edge530-demo.png)、全枠の寸法と実機手順は [validation.md](validation.md) を参照。

以下は未確認: 実機への導入、他の項目との共存、AMS 接続、Apple Music / Spotify の実データ、ロック中の更新、切断復帰、電池消費、macOS でのビルド。

## 既知の開発環境の問題

`bin/nowplaying-settings.json` は生成されるが、SDK の App Settings Editor は `No settings file found for this app` を表示する。
絶対パスで `monkeydo` を起動しても再現した。原因は未特定。
設定によるサンプル固定のロジック自体はテスト済みだが、GUI からの設定変更は未確認。
描画確認は初期値の自動切替で行った。AMS の可否調査より先に、この問題の解決へ長時間を使う必要はない。

## 次に着手すること

1. [通信調査メモ](transport-research.md) の「AMS を先に止める可能性がある制約」を確認する。まず BLE の接続役割とボンディング API を照合する。
2. Garmin 本体が既に持つ iPhone 接続から AMS を Connect IQ に公開する経路があるか、公式 API とサンプルで調べる。既存の Garmin Connect ペアリングをそのまま使えると仮定しない。
3. 文献と API で成立性が残る場合だけ、表示デモとは別の小さな実機用接続プローブを作る。検出・接続・サービス発見・通知登録を段階ごとに記録する。
4. 直接経路が成立しない場合は、根拠となる制約を記録する。追加ハードウェアや Spotify 専用方式へ無断で切り替えず、両サービスを扱う代替案を相談する。
5. 接続が成立したら Apple Music と Spotify、ロック中、アプリ切替、一時停止、Bluetooth 切断・復帰を試す。Edge 530 実機での確認をもって対応可否を決める。

シミュレーターで描けることは、実際の iPhone と接続できる証拠にならない。

## 別マシンへ持ち出すもの

ソース・手順・スクリーンショットは Git に含めた。新しいマシンでは clone して再開できる。
Mac では [setup-macos.md](setup-macos.md)、Windows では [README](../README.md) の手順を使う。

SDK、デバイス定義、Java、Node.js は各マシンで用意する。SDK Manager は普段の Garmin Connect アカウントでログインする。
`.local/dev-env.ps1` はこの Windows の絶対パスを含むローカル設定で、Git には入っていない。Mac へコピーして使わない。

署名鍵 `.local/developer_key.der` も Git 管理外。表示デモを新しいマシンで試すだけなら `node scripts/generate-key.mjs` で新規生成できる。
将来同じ Store アプリの更新を出す際には同じ署名鍵を保管・使用する。現時点で Store への公開はしていない。
鍵を継続使用する場合は、Git やチャットへ貼らず、安全な別経路で移す。

今回 GitHub への書き込みには接続済み GitHub ツールを使った。Windows の Git CLI の push 認証を設定したわけではない。
別マシンで CLI から push する場合は、そのマシンの GitHub 認証を設定する。

## 新しいチャットでの再開用メッセージ

> このリポジトリの AGENTS.md と docs/HANDOFF.md を読んで続けてください。Edge 530 の曲名・アーティスト名表示デモはビルドとシミュレーター確認済みです。Spotify と Apple Music の両方に対応したいため、Apple Media Service（AMS）で iPhone 標準の再生情報を受け取る経路を優先します。独自 iPhone アプリや Spotify 専用 API を前提にせず、まず Edge 530 / API 3.3 の BLE 接続役割・ボンディング制約から成立性を確認してください。未検証の接続を実現済みと扱わず、調査・実験結果を Git に残してください。

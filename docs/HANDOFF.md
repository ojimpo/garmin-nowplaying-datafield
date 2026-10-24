# 開発引き継ぎ

更新日: 2026-10-24。別のマシンや新しいチャットから再開するための入口。

## 目的と最新の合意

iPhone で普段どおり音楽を再生し、iPhone をロックしたまま、Garmin Edge 530 の既存走行データページに曲名とアーティスト名を表示したい。
ユーザーは **Spotify と Apple Music の両方**を使う。取得経路は **Apple Media Service（AMS）による標準の再生情報**を優先して調べる。
独自 iPhone アプリを前面に出し続ける構成や Spotify 専用 OAuth を、前提にしない。

Windows 上で AMS の成立性を調査した結果、**現行の公開 API では直接接続の実装を見送る**判断になった。
AMS のアクセサリ接続役割を CIQ の central-only API では再現できず、Edge 530 向けには明示的な bonding API も使えない。
システムの iPhone 接続や音楽情報を CIQ へ公開する経路も見つからなかった。実機で失敗を観測したわけではない。
根拠・再現方法・判断を変える条件は [AMS 調査結果](ams-feasibility.md) を読む。

## Mac へ移る必要があるか

| 作業 | Mac が必要か |
| --- | --- |
| Monkey C の編集・ビルド・テスト・シミュレーター | 不要。公式 SDK は Windows / macOS / Linux 向けに配布されている |
| Edge 530 から AMS へ直接接続できるかの調査 | 不要。Windows で文献・API・機種指定コンパイルまで実施済み |
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

AMS 調査では、通常 BLE API のコンパイル成功を対照に `requestBond()` と `getBondedDevices()` の Edge 530 非対応を確認した。
公式デバイス定義のメタデータでも両 API と Media scope がない。再現用スクリプトと結果は [research/ams](../research/ams/README.md)。
デバイス定義には API 3.3.1 / 3.3.6 のバリアントがある。表示を確認したシミュレーターは 3.3.1。

## 既知の開発環境の問題

`bin/nowplaying-settings.json` は生成されるが、SDK の App Settings Editor は `No settings file found for this app` を表示する。
絶対パスで `monkeydo` を起動しても再現した。原因は未特定。
設定によるサンプル固定のロジック自体はテスト済みだが、GUI からの設定変更は未確認。
描画確認は初期値の自動切替で行った。AMS の可否調査より先に、この問題の解決へ長時間を使う必要はない。

## 次に着手すること

1. 調査済みの直接経路を既定で再実装しない。[再開条件](ams-feasibility.md#実施していないことと再開条件)を満たす新しい根拠があれば再評価する。
2. 次の方針をユーザーと選ぶ。両サービスの要件を維持する候補は小型 BLE ブリッジだが、追加機器を携行する負担があり、まだ採用も検証もしていない。
3. ブリッジを選んだ場合は、iPhone からの AMS 取得と Edge への独自 GATT 通信を別々に検証し、その後に2接続を同時維持する。機器の購入や方式変更は未承認。
4. 通信経路が成立したら Apple Music と Spotify、ロック中、アプリ切替、一時停止、Bluetooth 切断・復帰を試す。Edge 530 実機での確認をもって対応可否を決める。

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

> このリポジトリの AGENTS.md、docs/HANDOFF.md、docs/ams-feasibility.md を読んで続けてください。Edge 530 の表示デモはビルドとシミュレーター確認済みです。AMS の直接接続は公開 API の制約調査により見送る判断で、実機接続は未検証です。Apple Music と Spotify の両方という要件を維持し、調査の再開条件と代替候補を確認してください。追加ハードウェアや Spotify 専用方式の採用はまだ決まっていません。変更・検証結果は Git に残してください。

# 開発引き継ぎ

更新日: 2026-10-24。別のマシンや新しいチャットから再開するための入口。

## 目的と最新の合意

iPhone で普段どおり音楽を再生し、iPhone をロックしたまま、Garmin Edge 530 の既存走行データページに曲名とアーティスト名を表示したい。
ユーザーは **Spotify と Apple Music の両方**を使う。
**最新の決定は「iPhone アプリ経由で進める。続きは Mac で行う」**。iPhone アプリの採用は許可済みで、再確認せず検証計画に沿って進めてよい。
初回の起動・権限許可・接続操作は許容するが、走行中に前面表示し続ける条件へ変更したわけではない。
ロック中に更新できることは引き続き目標であり、未検証。

Mac で最初に読む実験手順は [iPhone アプリの調査と検証計画](ios-companion-plan.md)。
Apple Music は `systemMusicPlayer`、Spotify は App Remote でサービス別に取得し、Garmin iOS Mobile SDK で転送する構成を最初に試す。
取得・転送・バックグラウンドの成立性は分けて評価する。iOS プロジェクトはまだ作成していない。

Windows 上で AMS の成立性を調査した結果、**現行の公開 API では直接接続の実装を見送る**判断になった。
AMS のアクセサリ接続役割を CIQ の central-only API では再現できず、Edge 530 向けには明示的な bonding API も使えない。
システムの iPhone 接続や音楽情報を CIQ へ公開する経路も見つからなかった。実機で失敗を観測したわけではない。
根拠・再現方法・判断を変える条件は [AMS 調査結果](ams-feasibility.md) を読む。
この直接 AMS の判断で iPhone アプリ経由まで不可能と扱わない。追加 BLE ブリッジの案は採用していない。

## Mac へ移る必要があるか

| 作業 | Mac が必要か |
| --- | --- |
| Monkey C の編集・ビルド・テスト・シミュレーター | 不要。公式 SDK は Windows / macOS / Linux 向けに配布されている |
| Edge 530 から AMS へ直接接続できるかの調査 | 不要。Windows で文献・API・機種指定コンパイルまで実施済み |
| 現在の主方針である iPhone アプリのビルド・実機署名 | macOS / Xcode が必要。ユーザーは Mac で続行する |
| 通信とロック中更新の確認 | iPhone と Edge 530 の実機が必要。シミュレーターだけで判定しない |

Mac に移っても、Edge 530 の Bluetooth API の制約が解消するわけではない。
アプリを作るだけで全アプリ共通の「再生中」を自由に取得できるとは想定しない。サービス別の取得と、iOS の実行条件を検証する。

## リポジトリと実装の現在地

- 公開リポジトリ: <https://github.com/ojimpo/garmin-nowplaying-datafield>
- 主ブランチ: `main`
- 引き継ぎ追記前の表示実装の基準コミット: `ef918bd`
- Connect IQ アプリ ID: `0e7452a432a14e80baf47e5fe3f0a6d1`
- 対象: `edge530`、manifest の最小 API: `3.3.0`
- Data Field 名: `Now Playing Demo`
- 通信権限: まだ要求していない。AMS、BLE、Spotify API、iOS コンパニオンはいずれも未実装。
- 直接 AMS 調査の基準コミット: `4bd9230`。iPhone アプリ採用はこの調査後のユーザー決定。

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
描画確認は初期値の自動切替で行った。iPhone の取得・転送の成立性確認より先に、この問題の解決へ長時間を使う必要はない。

## 次に着手すること

1. Mac の [セットアップ](setup-macos.md)を行い、既存表示デモのビルドと iPhone 実機での空アプリ起動を確認する。
2. [iPhone 検証計画](ios-companion-plan.md)の順に、Apple Music と Spotify の曲情報をコンパニオン前面で取得する。サービスは最初は手動選択でよい。
3. 音楽と独立した合成データを Garmin iOS Mobile SDK で送信する。Edge 530 の Phone App Message 背景イベントから既存 Data Field への反映を小さく確認する。foreground Data Field の Communications API 5.0 を使わない。
4. 取得と転送をつなぎ、両サービスのロック中・自然な曲変更・一時停止・アプリ切替・Bluetooth 切断復帰を測定する。ここが採用可否の最大の未解決事項。
5. 止まる場合は、情報取得・iOS の休止・SDK 接続・Edge 受信・描画を切り分け、条件と回復操作を記録する。実機で未確認のバックグラウンド動作を保証しない。

直接 AMS は新しい根拠がない限り再調査しない。追加機器や片方のサービスだけへ変更する場合はユーザーと方針を決める。

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

> このリポジトリの AGENTS.md、docs/HANDOFF.md、docs/ios-companion-plan.md を読んで Mac で続けてください。ユーザーは iPhone アプリ経由で進めると決定済みです。Apple Music は systemMusicPlayer、Spotify は App Remote で取得し、Garmin iOS Mobile SDK で Edge 530 の Data Field へ送る構成を最初に試してください。既存表示デモは Windows でビルド・テスト・シミュレーター確認済みですが、iOS プロジェクトは未作成で、取得・転送・ロック中の継続は未検証です。まず前面の取得、合成データ転送、両者の接続、ロック中の実機試験を分けて進め、結果を Git に残してください。直接 AMS の非対応判断を iPhone アプリ経由の不可と混同せず、Apple Music と Spotify の両方という要件を維持してください。

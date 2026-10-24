# 通信経路の検証メモ

確認日: 2026-10-24。表示デモには通信を組み込まない。

## 確認できたこと

- Edge 530 は API 3.3 対応。画面全体は 246×322px だが、Data Field へ渡される枠の寸法は別。
- Communications モジュールの公式資料には、foreground Data Field 対応は API 5.0.0 からと記載されている。Edge 530 の画面側で直接呼ぶ設計にはしない。
- `Background.registerForPhoneAppMessageEvent()` は API 3.2.0 からで、Edge 530 が対応機種に含まれる。Phone App Message イベントと時間イベントの5分制約は区別する。
- Background Services は実行時間とメモリに制限があり、イベント処理後に `Background.exit()` で終了させる。受信した最小限の情報を foreground に渡す構成を次に試す。
- iOS Mobile SDK はデバイスの初期選択に Garmin Connect Mobile を使い、選択後の通信は BLE で直接行う。
- iOS SDK の Bluetooth background mode と state restoration は、デバイスからの通信による復帰を説明するもの。Spotify の曲変更に合わせて、停止中の iPhone アプリが継続して起きることまでは保証していない。

## 次の実験

1. まず iPhone の前面アプリから固定の曲情報を送る。
2. Edge 530 の Phone App Message background event が走行中に届くか確認する。
3. `Background.exit()` → `AppBase.onBackgroundData()` で表示を更新できるか確認する。
4. iPhone をロックし、固定情報の送信が止まる条件を計測する。
5. その後に Spotify の再生情報取得をつなぐ。OAuth は Authorization Code with PKCE を候補とし、端末に client secret を埋め込まない。
6. 曲変更の遅延、通信断、再接続、古いデータの表示、消費電力を実機で評価する。

この手順で成立が確認できるまで、「常時リアルタイム更新できる」とは扱わない。
Windows で作業できるのは主に Garmin 側。iOS アプリのビルド・実機署名には macOS / Xcode 環境が別途必要。

## 公式資料

- [対応デバイス](https://developer.garmin.com/connect-iq/compatible-devices/)
- [Communications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html)
- [Background.registerForPhoneAppMessageEvent](https://developer.garmin.com/connect-iq/api-docs/Toybox/Background.html#registerForPhoneAppMessageEvent-instance_function)
- [Background Services](https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html)
- [iOS Mobile SDK のドキュメント](https://github.com/garmin/connectiq-companion-app-sdk-ios/blob/main/documentation/ConnectIQ_iOS_SDK.html)

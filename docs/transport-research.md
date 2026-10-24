# 通信経路の検証メモ

確認日: 2026-10-24。**最新方針は AMS 優先**。Spotify 専用の取得方式は既定にしない。
現在の表示デモには通信を組み込んでいない。

## 目的

Apple Music と Spotify の両方について、iPhone 標準の再生情報を Edge 530 の Data Field に表示する。
利用時は iPhone をロックでき、独自アプリを前面に出し続けなくてよい構成を目指す。
AMS を使えるなら、Spotify 個別の API 認証や再生状態のポーリングを省ける可能性がある。ただし対象機種との接続成立は未検証。

## AMS について確認できたこと

[Apple の AMS 仕様](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleMediaService_Reference/Specification/Specification.html)は、外部 Bluetooth 機器へ再生状態と曲情報を通知する仕組みを定めている。
アプリ横断の現在の再生情報を扱う経路として検証する。

- Service UUID: `89D3502B-0F36-433A-8EF4-C502AD55F8DC`
- Entity Update: `2F7CABCE-808D-411F-9A0C-BB92BA96C102`。曲情報の通知を購読し、必要な属性を登録する。
- Track entity は `2`、Artist attribute は `0`、Title attribute は `2`。[属性一覧](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleMediaService_Reference/Appendix/Appendix.html)
- 通知値は切り詰められる場合があり、必要なら Entity Attribute characteristic で続きを読む。UTF-8 の途中や受信途中の情報をそのまま確定表示しない設計が必要。
- AMS のサービスは常時存在する保証がない。消失と再公開に対応する必要がある。

これらは仕様の内容であり、現在のコードに AMS クライアントがあるわけではない。
Apple Music / Spotify のロック中動作や、アプリ切替時の追従は実際の iPhone で確認する。

## AMS を先に止める可能性がある制約

| 事実・観測 | 判断への影響 |
| --- | --- |
| [Garmin の BluetoothLowEnergy モジュール](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html)は central role を提供し、Edge 530 が対応機種に含まれる | BLE 対応というだけで、iPhone 向けアクセサリとして振る舞えるとは限らない |
| [Nordic 公式の AMS クライアント例](https://github.com/nrfconnect/sdk-nrf/blob/main/samples/bluetooth/peripheral_ams_client/README.rst)は peripheral として広告し、iPhone 側から接続・ペアリングする | この例の接続役割を、Garmin の central-only API でそのまま再現できるとは考えない |
| [Device.requestBond()](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy/Device.html#requestBond-instance_function)は API 4.2.5 からで、Edge 530 は対応機種一覧にない | Edge 530 / API 3.3 から明示的なボンディングを要求する実装は使えない |
| Garmin 本体と iPhone の既存接続を Connect IQ の独自 GATT アクセスへ流用できるかは未確認 | Garmin Connect とのペアリング済みという理由だけで、AMS にアクセスできるとしない |

**推論:** 通常の AMS アクセサリ接続を Edge 530 の公開 API だけで実装するには、大きな制約がありそう。
ただし `requestBond()` がないことだけを根拠に、既存のシステム接続を含むすべての経路が不可能とは断定しない。
また、GATT の client/server と、BLE 接続の central/peripheral は別の役割なので混同しない。

## 次の検証と判断基準

1. 公式 API、デバイス別 API 定義、SDK サンプルで、Edge 530 から利用できる接続役割と AMS 公開経路を照合する。ここは Windows でも調べられる。
2. 本体の音楽操作機能と、Connect IQ の公開 API は分けて調べる。他の Garmin 機種の音楽操作実績だけで Edge 530 の Data Field でも可能とはしない。
3. 公開 API で必要な役割を作れず、システム接続を使う経路も見つからない場合は、その根拠を記録して直接経路の実装を止める。存在しない peripheral / bonding API を呼ぶ仮実装で進めない。
4. 成立性が残る場合に限り、別の小さな実機プローブで、検出・接続・サービス発見・通知登録を段階的に確認する。シミュレーターの表示確認を BLE 接続確認の代わりにしない。
5. 実接続できたら、Apple Music / Spotify と、iPhone ロック中・再生アプリ切替・一時停止・切断復帰の組み合わせを確認する。曲変更の遅延と古い表示の扱いも記録する。
6. 直接経路が成立しない場合は、追加ハードウェアのブリッジ等も含めて代替案の要件を比較し、ユーザーと方針を決める。まだ追加機器を導入すると決まったわけではない。

AMS を直接使う Garmin 側の開発に Mac は必須ではない。Mac / Xcode が必要なのは、独自 iPhone アプリを作る場合。
Mac を使うこと自体で Edge 530 の API 制約が変わるわけではない。

## 旧コンパニオン案で確認していたこと（主経路としては保留）

以下は独自 iPhone アプリから Mobile SDK で送る案の調査。
AMS の直接経路が成立しない場合の参考として残す。Spotify 専用アプリへの移行を決定したものではない。

- Edge 530 は API 3.3 対応。画面全体は 246×322px だが、Data Field へ渡される枠の寸法は別。
- Communications モジュールの公式資料には、foreground Data Field 対応は API 5.0.0 からと記載されている。Edge 530 の画面側で直接呼ぶ設計にはしない。
- この Communications 制約を、そのまま別モジュールの BluetoothLowEnergy にも当てはめない。
- `Background.registerForPhoneAppMessageEvent()` は API 3.2.0 からで、Edge 530 が対応機種に含まれる。Phone App Message イベントと時間イベントの5分制約は区別する。
- Background Services は実行時間とメモリに制限があり、イベント処理後に `Background.exit()` で終了させる。Mobile SDK 案を採用する場合は受信した最小限の情報を foreground に渡す構成を試す。
- iOS Mobile SDK はデバイスの初期選択に Garmin Connect Mobile を使い、選択後の通信は BLE で直接行う。
- iOS SDK の Bluetooth background mode と state restoration は、デバイスからの通信による復帰を説明するもの。Spotify の曲変更に合わせて、停止中の iPhone アプリが継続して起きることまでは保証していない。

一般の iPhone アプリを作れば他のアプリの標準 Now Playing 情報を自由に読める、という前提は置かない。
また、Spotify Web API だけを使う案では Apple Music の要件を満たさない。

## 公式資料

- [対応デバイス](https://developer.garmin.com/connect-iq/compatible-devices/)
- [Communications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html)
- [Background.registerForPhoneAppMessageEvent](https://developer.garmin.com/connect-iq/api-docs/Toybox/Background.html#registerForPhoneAppMessageEvent-instance_function)
- [Background Services](https://developer.garmin.com/connect-iq/articles/core-topics/Backgrounding.html)
- [iOS Mobile SDK のドキュメント](https://github.com/garmin/connectiq-companion-app-sdk-ios/blob/main/documentation/ConnectIQ_iOS_SDK.html)

# 通信経路の検証メモ

確認日: 2026-10-24。**最新のユーザー決定は iPhone アプリ経由で進めること**。続きは Mac で行う。
取得・転送・ロック中動作の調査結果と次の実験は [iPhone アプリの検証計画](ios-companion-plan.md) を参照。
AMS の直接経路は見送る判断のまま。[根拠・保存した結果・再開条件](ams-feasibility.md)を残す。
現在の表示デモには通信を組み込んでいない。

## 目的

Apple Music と Spotify の両方について、再生中情報を Edge 530 の Data Field に表示する。
利用時は iPhone をロックでき、独自アプリを前面に出し続けなくてよい構成を目指す。
独自 iPhone アプリの導入・初回接続を許容する。取得は Apple Music / Spotify 別の API で行い、Garmin iOS Mobile SDK で送る構成を最初に検証する。
ロック中の継続取得・転送を保証できる資料や実機結果はまだない。

## AMS について確認できたこと

[Apple の AMS 仕様](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleMediaService_Reference/Specification/Specification.html)は、外部 Bluetooth 機器へ再生状態と曲情報を通知する仕組みを定めている。
アプリ横断の現在の再生情報を扱う候補として調べたが、Edge 530 からの直接接続は以下の制約により見送った。

- Service UUID: `89D3502B-0F36-433A-8EF4-C502AD55F8DC`
- Entity Update: `2F7CABCE-808D-411F-9A0C-BB92BA96C102`。曲情報の通知を購読し、必要な属性を登録する。
- Track entity は `2`、Artist attribute は `0`、Title attribute は `2`。[属性一覧](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleMediaService_Reference/Appendix/Appendix.html)
- 通知値は切り詰められる場合があり、必要なら Entity Attribute characteristic で続きを読む。UTF-8 の途中や受信途中の情報をそのまま確定表示しない設計が必要。
- AMS のサービスは常時存在する保証がない。消失と再公開に対応する必要がある。

これらは仕様の内容であり、現在のコードに AMS クライアントがあるわけではない。
Apple Music / Spotify のロック中動作や、アプリ切替時の追従は実際の iPhone で確認する。

## 調査で確認した制約

| 事実・観測 | 判断への影響 |
| --- | --- |
| [Garmin の BluetoothLowEnergy モジュール](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html)は central role を提供し、Edge 530 が対応機種に含まれる | BLE 対応というだけで、iPhone 向けアクセサリとして振る舞えるとは限らない |
| [Nordic 公式の AMS クライアント例](https://github.com/nrfconnect/sdk-nrf/blob/main/samples/bluetooth/peripheral_ams_client/README.rst)は peripheral として広告し、iPhone 側から接続・ペアリングする | この例の接続役割を、Garmin の central-only API でそのまま再現できるとは考えない |
| [Device.requestBond()](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy/Device.html#requestBond-instance_function)は API 4.2.5 からで、Edge 530 は対応機種一覧にない | Edge 530 / API 3.3 から明示的なボンディングを要求する実装は使えない |
| デバイス定義の監査と strict コンパイルで `requestBond()` と `getBondedDevices()` の Edge 530 非対応を確認 | 新しい SDK を入れても、機種別の非対応は変わらない |
| 公式 API と SDK サンプルには、本体の iPhone 接続・再生情報を CIQ へ公開する経路が見つからない | Garmin Connect とのペアリング済みという理由だけで、AMS にアクセスできるとしない |

**判断:** 確認した AMS アクセサリ接続を Edge 530 の公開 API だけで再現する経路がなく、直接実装を見送る。
ただし `requestBond()` がないことだけを根拠に、既存のシステム接続を含むすべての経路が不可能とは断定しない。
また、GATT の client/server と、BLE 接続の central/peripheral は別の役割なので混同しない。

## 次の検証と判断基準

1. 公式 API・定義・サンプルの照合と機種指定コンパイルは完了。[research/ams](../research/ams/README.md) で再現できる。
2. [再開条件](ams-feasibility.md#実施していないことと再開条件)を満たす新しい証拠がなければ、直接経路の仮実装は追加しない。本体の機能と CIQ の機能は区別する。
3. iPhone アプリ方式はユーザーが採用済み。[Mac での実験順序](ios-companion-plan.md#実験の順序と合格条件)に従い、サービス別取得と合成データの転送を分けて検証する。追加ハードウェアは導入しない。
4. 前面で両者が成立したら組み合わせ、ロック中・アプリ切替・一時停止・自然な曲変更・切断復帰を実機で確認する。

Garmin 側だけなら Mac は必須ではないが、現在採用した独自 iPhone アプリには Mac / Xcode が必要。
Mac を使うこと自体で Edge 530 の API 制約が変わるわけではない。

## コンパニオンの転送で確認した制約（現在の最初の検証候補）

以下は独自 iPhone アプリから Mobile SDK で送る案の資料調査。
転送候補として採用したが、まだ実装・実機確認はしていない。Spotify 専用アプリへ変更したわけではない。

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

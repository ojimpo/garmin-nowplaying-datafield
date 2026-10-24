# Edge 530 から AMS を直接利用できるか

調査日: 2026-10-24。対象は Connect IQ の **Data Field / Edge 530 / 公開 API**。

この調査後、ユーザーは **iPhone アプリ経由で進め、Mac で続行する**と決定した。[現在の計画](ios-companion-plan.md)を参照。
以下は直接 AMS 経路の調査記録であり、iPhone アプリ経由を否定するものではない。

## 結論

**現在の公開 API では、Edge 530 から iPhone の AMS へ直接接続する実装を進められる経路を確認できなかった。直接経路は実装を見送る。**

理由は、確認した AMS アクセサリの接続手順を Connect IQ の central-only API では再現できず、Edge 530 には明示的なボンディング API もないこと。
本体が持つ iPhone 接続や音楽情報を Data Field へ公開する代替 API も見つからなかった。
Windows で文献・デバイス定義・コンパイラーを照合した判断であり、Mac に替えてもこの制約は変わらない。

これは **公開 API を使う開発上の判断**。実機で AMS 接続失敗を観測した結果でも、Edge 530 のハードウェアが絶対に不可能という証明でもない。
`requestBond()` が非対応という一点だけで、既存のシステム接続を含む全経路が不可能とは断定しない。

## AMS の接続役割を分けて考える

[Apple の AMS 仕様](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleMediaService_Reference/Specification/Specification.html)は、現在のメディアアプリ、曲名、アーティスト等を通知するサービスを定義する。
この仕様だけから GAP の接続役割や必須のセキュリティ手順を断定せず、実装元の資料と照合した。

| 層 | iPhone | 確認した AMS アクセサリ |
| --- | --- | --- |
| GAP（接続の開始・広告） | central として接続 | peripheral として接続可能な広告を出す |
| GATT（情報の提供・取得） | AMS server | AMS client として読み書き・通知購読 |

**GATT client であることは、GAP central でよいことを意味しない。**

- [Nordic の公式サンプル](https://github.com/nrfconnect/sdk-nrf/blob/main/samples/bluetooth/peripheral_ams_client/README.rst)は peripheral として広告し、iPhone の Bluetooth 設定から接続する。[設定](https://github.com/nrfconnect/sdk-nrf/blob/main/samples/bluetooth/peripheral_ams_client/prj.conf)は peripheral・GATT client・SMP を有効にし、[実装](https://github.com/nrfconnect/sdk-nrf/blob/main/samples/bluetooth/peripheral_ams_client/src/main.c)は AMS UUID を Service Solicitation に載せ、接続後にセキュリティを要求してからサービスを探索する。
- [Espressif の公式 AMS サンプル](https://github.com/espressif/esp-idf/blob/master/examples/bluetooth/bluedroid/ble/ble_ams/README.md)も、広告開始 → iOS から接続・ペアリング → AMS 発見 → 通知購読の順序を明示する。
- [Moddable の実装者による解説](https://moddable.com/blog/ams-client/)は、暗号化接続を作るための広告・ペアリングと、その後の AMS client の処理を分けて説明する。

補助資料として [Apple Accessory Design Guidelines](https://developer.apple.com/accessories/Accessory-Design-Guidelines.pdf) R31（2026-09-21）の §58.10、印刷ページ353–354も確認した。
central かつ GATT server の Apple デバイスとアクセサリのセキュリティ手順を説明しているが、これは一般的な BLE の説明であり、AMS 固有の必須条件の根拠にはしていない。

## Edge 530 の公開 API との照合

| 必要な経路・機能 | 確認結果 | 判断 |
| --- | --- | --- |
| peripheral として広告し、iPhone からの接続を受ける | [BluetoothLowEnergy](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html) は central role。広告開始・ローカル GATT server 公開の API は見つからない | 確認した AMS の接続手順を再現できない |
| 暗号化・ボンディングを明示的に要求する | [Device.requestBond()](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy/Device.html#requestBond-instance_function) は API 4.2.5 以降。Edge 530 向けコンパイルで非対応 | 新機種向けの実装を持ち込めない |
| 保存済みボンドを列挙する | `getBondedDevices()` も API 4.2.5 以降。Edge 530 向けコンパイルで非対応 | この API による迂回も使えない |
| Garmin 本体と iPhone の既存接続を使う | `getPairedDevices()` はアプリからアクセス可能な機器を返す仕様。全システム接続を公開する保証はない | Garmin Connect とペアリング済みというだけでは利用可能と扱えない |
| GATT プロファイルを登録する | `registerProfile()` はアクセス対象のリモートサービス・characteristic・descriptor を定義する | AMS UUID を登録しても広告やセキュリティを新設できない |
| ネイティブの音楽情報を Data Field へ取得する | 公開 API と SDK サンプルに phone Now Playing の getter は見つからない。[Toybox.Media](https://developer.garmin.com/connect-iq/api-docs/Toybox/Media.html) は端末内の音楽プロバイダー・再生向けで、Edge 530 / Data Field の経路ではない | 本体の音楽機能や他機種の対応を CIQ の対応と混同しない |

`pairDevice()` の「pair」は、スキャンした peripheral をアプリが使う接続として登録する API。
ドキュメントにはアプリのインスタンス間で永続化しないとある。iPhone との暗号化ボンドを新設・流用する保証とは別。

## Windows で実行した確認

環境: Windows、Java 17、Connect IQ SDK 9.3.0、SDK Manager から取得した公式 Edge 530 定義。
定義の識別子は `3d0fb192a2cf01699aefd0f384af3f527e5885bd`。
定義に含まれる API バージョンは `3.3.1` / `3.3.6`、使用中のシミュレーターは `3.3.1`。

| コンパイル専用プローブ（strict `-l 3`、`-d edge530`） | 結果 |
| --- | --- |
| `device.getServices();` | BUILD SUCCESSFUL、終了コード0 |
| `device.requestBond();` | `edge530` 非対応のエラー、終了コード105 |
| `BluetoothLowEnergy.getBondedDevices();` | `edge530` 非対応のエラー、終了コード105 |

加えて公式デバイス定義の API メタデータを調べた。通常のスキャン・接続 API はあり、`requestBond`、`isBonded`、`getBondedDevices`、`setConnectionStrategy` はなく、Media の API scope もなかった。
新しい SDK を使うことと、古い機種で新しい API が使えることは別だと確認できる。

再現用スクリプトと、パスを伏せた結果 JSON は [research/ams](../research/ams/README.md) に保存した。
非対応を確かめるためのプローブは、意図した非対応エラーだけを期待結果として扱う。アプリ本体には組み込まない。

## 実施していないことと再開条件

BLE スキャン、iPhone との接続、AMS サービス発見、通知受信、ロック中の動作、実機の `getPairedDevices()` の内容は未確認。
通常の表示シミュレーションも実 BLE の代わりにはならない。SDK の BLE シミュレーションには対応する Nordic 機器と Garmin のファームウェアが別途必要で、今回は使用していない。

次のいずれかの具体的な根拠が出た場合、直接経路を再評価する。

1. Edge 530 の Data Field からシステムの iPhone 接続の AMS GATT handle を取得できる、Garmin の公式手順。
2. 本体の phone Now Playing を公開する、Edge 530 対応の API。
3. 同じ機種・アプリ種別・公開 API で AMS 取得に成功した再現可能な実装。別の Garmin 機種のネイティブ機能だけでは不十分。

成立する呼び出し経路が見つからない状態で、存在しない API を呼ぶ通信実装を追加しない。

## 両音楽サービスを維持する代替候補

候補は、AMS を扱える小型 BLE 機器を iPhone と Edge 530 の間に置く構成。
iPhone とは AMS client として接続し、Edge には独自 GATT service で最小限の文字情報を渡す。
これは上記サンプルを足掛かりにした **設計上の候補であり、エンドツーエンドの動作は未検証**。
2接続の同時維持、ボンド管理、電源、防水、再接続、文字数・日本語を別途評価する必要がある。

この方式なら独自 iPhone アプリを前面に出し続けない構成を狙えるが、追加機器を携行する負担がある。
このブリッジ案は採用していない。その後のユーザー決定により、現在は追加機器を使わない [iPhone アプリ方式](ios-companion-plan.md)を試す。
Spotify 専用 API へ要件を縮める変更もしていない。直接 AMS の調査記録と既存表示デモは引き続き残す。

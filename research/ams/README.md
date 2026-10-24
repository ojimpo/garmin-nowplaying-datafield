# AMS 成立性の再現用チェック

調査結果は [ams-feasibility.md](../../docs/ams-feasibility.md)。これは実機通信用コードではない。
デモの manifest・通信権限・表示コードは変更しない。

## Windows で再実行する

README の SDK・Java・鍵・Edge 530 定義を準備したうえで、リポジトリのルートから実行する。

```powershell
# このマシンのローカル設定がある場合のみ
. .\.local\dev-env.ps1

.\research\ams\check-edge530-api.ps1
.\research\ams\compile-api-probes.ps1
```

ローカル設定がない環境では `CIQ_SDK_HOME` と Java の `PATH` を設定するか、SDK Manager のアクティブ SDK 設定を使う。
鍵の既定値は `.local/developer_key.der`。`-SdkPath` / `-KeyPath` でも指定できる。
このスクリプトは Windows 用。macOS ではまだ実行していない。

| スクリプト | 検証すること |
| --- | --- |
| `check-edge530-api.ps1` | 公式デバイス定義の API メタデータから BLE メソッドと Media scope の有無を列挙。`-DeviceDirectory` で別の定義配置を指定可能 |
| `compile-api-probes.ps1` | 一時的な Data Field を3種類生成し、strict 型チェックで機種別の対応可否を確認 |

コンパイル結果は Git 管理外の `build/ams-api-probes/results.json` に出力する。
ソース・manifest・バイナリも同じ `build/` 内に作る。インストール・実行はしない。

## 結果の読み方

1. `ble-baseline` の `getServices()` は成功を期待する。SDK・鍵・リソースの問題を、非対応の証拠と誤認しないための対照。
2. `request-bond` と `bonded-devices` は、指定した API が `edge530` 非対応という診断を期待する。
3. スクリプト全体の成功条件は3件とも `expectationMet: true`。無関係なコンパイル失敗では成功にしない。

API を使う関数は呼ばれないが、コンパイラーが対応機種を検証することを確認済み。
今後 SDK や定義が変わって期待と異なる結果が出たら、保存済みの結論を流用せず診断を読む。
このチェックだけで既存の iPhone 接続を使えるか、暗号化が自動で成立するかは判定できない。

## 保存した観測

2026-10-24、SDK 9.3.0、Java 17、Windows で実行。

- [機種別 API メタデータの監査](results/device-api-2026-10-24.json)
- [3種類のコンパイル結果](results/compiler-2026-10-24.json)

結果の絶対パスは `<repository>` / `<sdk>` に置換している。
公式 SDK・デバイス定義そのもの、署名鍵、iPhone の識別情報、個人の再生情報は含めない。

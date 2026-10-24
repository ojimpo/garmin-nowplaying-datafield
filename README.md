# Garmin Now Playing Data Field

Garmin Edge 530 の走行データ画面に、iPhone の Spotify で再生中の曲名・アーティスト名を表示するためのプロジェクト。

**開発初期段階です。まずダミーデータによる表示を実装し、iPhone からの通信は別工程で検証します。**

## 現在できること

`Now Playing Demo` という Data Field を Edge 530 向けに定義しています。
15秒ごとに、短い曲名・長い曲名・日本語・一時停止・未再生のダミー表示を切り替えます。
2行に収まらない高さでは1行表示に切り替えます。画面の明暗に合わせて文字色も切り替えます。
サンプルのアーティスト行には `DEMO` を付けています。

Spotify 取得・iPhone アプリ・Bluetooth 通信はまだ実装していません。
端末側の権限もまだ要求しません。

## 開発環境（Windows）

1. [Garmin 公式 SDK](https://developer.garmin.com/connect-iq/sdk/) と Java ランタイムを用意します。
2. SDK Manager に **普段の Garmin Connect アカウント** でログインし、Edge 530 のデバイス定義をダウンロードします。
3. `CIQ_SDK_HOME` に SDK 本体のディレクトリを設定します（`bin` の親）。Java を `PATH` に追加します。
4. 署名鍵を生成し、ビルドします。鍵生成には Node.js が必要です。

```powershell
$env:CIQ_SDK_HOME = 'C:\path\to\connectiq-sdk'
node scripts/generate-key.mjs
.\scripts\build.ps1
```

鍵は `.local/developer_key.der` に生成し、既存の鍵は上書きしません。
既存の開発者鍵を使う場合は `CIQ_DEVELOPER_KEY` または `-KeyPath` で指定できます。
SDK Manager のアクティブ SDK 設定があれば、`CIQ_SDK_HOME` は省略できます。

この作業フォルダで用意した環境を再利用する場合は、Git 管理外の `.local/dev-env.ps1` を読み込みます。

```powershell
. .\.local\dev-env.ps1
.\scripts\build.ps1
```

## シミュレーターとテスト

SDK の `bin\simulator.exe` を起動してから、次を実行します。

```powershell
& "$env:CIQ_SDK_HOME\bin\monkeydo.bat" bin/nowplaying.prg edge530
```

Data Fields の表示設定で枠を変え、[確認手順](docs/validation.md)に沿って表示を調べます。
Monkey C のテストビルド・実行は次のとおりです。

```powershell
.\scripts\build.ps1 -TestBuild
& "$env:CIQ_SDK_HOME\bin\monkeydo.bat" bin/nowplaying-tests.prg edge530 -t
```

テストはデモの切替境界と、実際のフォント寸法を使う文字省略を対象にします。
スクリーン表示や通信の動作確認は別に必要です。

## 構成

| パス | 役割 |
| --- | --- |
| `source/NowPlayingView.mc` | 枠の寸法に応じた描画 |
| `source/DemoSource.mc` | 個人の履歴を使わないダミー情報 |
| `source/TextFit.mc` | フォント幅を測って末尾を省略 |
| `tests/` | Monkey C のテスト |
| `docs/transport-research.md` | 通信制約と次の検証 |
| `docs/validation.md` | 実行済みチェックと実機確認の手順 |

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

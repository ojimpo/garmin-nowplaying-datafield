# Mac で開発を再開する

この手順は2026-10-24に作成した。**macOS 上での実行はまだ確認していない**。
CLI のフラグは公式 SDK 同梱スクリプトと照合した。Windows で確認済みの結果は [validation.md](validation.md) にある。
AMS の直接経路を調べるためだけに、Mac へ移る必要はない。

## 準備

1. Git、Node.js、Java を用意する。現在の検証環境は Java 17。
2. [Garmin 公式 SDK ページ](https://developer.garmin.com/connect-iq/sdk/)から **Mac 版** SDK Manager を導入する。Windows 版 SDK のコピーは使わない。
3. 規約を確認し、普段の Garmin Connect アカウントでログインする。
4. Connect IQ SDK 9.3.0 と Edge 530 のデバイス定義を取得する。全機種の取得は不要。
5. SDK 本体のディレクトリ（`bin` の親）を確認する。VS Code を使う場合は Garmin の Monkey C 拡張も導入できる。

以下はターミナルで行う。

```sh
git clone https://github.com/ojimpo/garmin-nowplaying-datafield.git
cd garmin-nowplaying-datafield
git status
java -version
node --version

# SDK Manager で確認した実際のパスに置き換える。
# スペースを含む場合があるため、引用符を残す。
export CIQ_SDK_HOME="/absolute/path/to/connectiq-sdk-mac"

# 新しいマシンでローカルテスト用の鍵を作る場合。
# 既存の鍵は上書きしない。既存鍵を移した場合は実行不要。
node scripts/generate-key.mjs
export CIQ_DEVELOPER_KEY="$PWD/.local/developer_key.der"
mkdir -p bin
```

環境変数はこのターミナルセッション内で有効。必要なら自分の環境設定へ保存する。
SDK・署名鍵のパスや鍵そのものを公開リポジトリへ追加しない。

## 通常ビルドと起動

```sh
"$CIQ_SDK_HOME/bin/monkeyc" \
  -f monkey.jungle -d edge530 \
  -o bin/nowplaying.prg -y "$CIQ_DEVELOPER_KEY" -w -l 3

# 公式 SDK のシミュレーターを起動する。
"$CIQ_SDK_HOME/bin/connectiq"

# シミュレーターの起動後に実行する。
"$CIQ_SDK_HOME/bin/monkeydo" "$PWD/bin/nowplaying.prg" edge530
```

`monkeydo` はアプリ実行中、ターミナルで待機することがある。
シミュレーターの `Data Fields > Layout > 7 Fields A` と、
`Settings > Language > Japanese (jpn)` を選ぶ。
15秒ごとの自動切替で日本語と長い曲名を確認する。白黒背景は `Data Fields > Background Color` で選べる。

## テスト

シミュレーターを起動した状態で、別のターミナルまたはアプリ停止後に実行する。
新しいターミナルでは上の環境変数を再設定する。

```sh
"$CIQ_SDK_HOME/bin/monkeyc" \
  -f monkey.jungle -d edge530 \
  -o bin/nowplaying-tests.prg -y "$CIQ_DEVELOPER_KEY" -w -l 3 -t

"$CIQ_SDK_HOME/bin/monkeydo" "$PWD/bin/nowplaying-tests.prg" edge530 -t
```

期待値は3件 PASS。**Mac / Linux の `monkeydo` は `-t`、Windows の `monkeydo.bat` は `/t`**。
実行した SDK バージョン、Mac の環境、結果は [validation.md](validation.md) へ追記する。

## つまずいた場合

| 症状 | 確認箇所 |
| --- | --- |
| `Invalid device id ... edge530` | SDK Manager で Edge 530 定義の取得が完了しているか |
| `java` が見つからない | Java の導入と `PATH`、`java -version` |
| コンパイラーが見つからない | `CIQ_SDK_HOME` が Mac 版 SDK の `bin` の親を指しているか |
| シミュレーターへ接続できない | シミュレーターが起動しているか、OS の許可要求があるか |
| 日本語が表示されない | シミュレーターの言語が `Japanese (jpn)` か |
| App Settings Editor が設定 JSON を読めない | Windows でも既知の未解決問題。初期値の自動切替で描画確認はできる |

Mac を用意しても Edge 530 の API 制約は変わらない。[AMS 調査結果](ams-feasibility.md)では直接経路を見送る判断となった。次の方針は [通信調査メモ](transport-research.md) と引き継ぎメモで確認する。

# 作業を再開するエージェントへ

- まず `docs/HANDOFF.md`、次に `docs/ams-feasibility.md`、`docs/transport-research.md` と `docs/validation.md` を読む。
- ユーザーは Spotify と Apple Music を使う。iPhone 標準の再生情報を使う AMS 経路を優先する。Spotify 専用 API や独自 iPhone アプリを既定路線に戻さない。
- AMS の存在と、Edge 530 の Data Field から AMS を利用できることは別。現在は表示デモのみ動作確認済み。接続・ボンディング・ロック中の追従を未検証のまま「動く」としない。
- 2026-10-24 の公開 API・定義・コンパイル調査では直接 AMS 経路を見送る判断。再開条件は `docs/ams-feasibility.md` にある。同じ調査を繰り返して実装が進んだ扱いにせず、API 追加や再現可能な実装など新しい根拠を確認する。
- 対象は `edge530` / API 3.3。新機種向け API を無条件に呼ばない。AMS の可否調査は表示実装と分け、既存デモを維持する。
- 秘密鍵、トークン、SDK、ローカル環境設定はコミットしない。公開リポジトリであることに注意する。
- 変更は Git 管理し、検証方法と結果を残す。macOS の手順は現在未実行なので、実際に動かすまで検証済み扱いにしない。
- Cosense/Scrapbox の読み書きは利用可能な Cosense MCP を優先する。ブラウザへ切り替えるのは MCP が利用不能または失敗した場合だけとし、切り替える理由を先に伝える。

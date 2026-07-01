# dev-workflow

Claude Code / Codex などのAI開発エージェント向けの、**軽量なAI開発セッション管理ツール**です。

AIに作業を任せる前に「要件が実装可能なレベルか」を最初に判定し、

- 十分ならそのまま設計・実装へ進む
- 曖昧なら質問してから作業を始める

という **開発開始前の要件ゲート** を提供します。大げさなワークフロー管理はしません。

## 構成

```
.ai/
  prompts/
    session-workflow.md      # AIエージェント向けのワークフロー・ルール（要件ゲート）
  templates/
    session/                 # セッション作成時にコピーされるテンプレート
      requirements.md        # 要件（判定の起点）
      questions.md           # 確認事項（要件不足時のみ、最大5件）
      design.md              # 設計（方針 / 変更対象 / DB / API / UI / 影響範囲）
      tasks.md               # タスク（実装 / 確認 / 完了条件）
      test.md                # テスト（観点 / 手動 / 自動 / リグレッション）
      summary.md             # サマリ（実施内容 / 変更 / 残課題 / 振り返り）
  sessions/                  # 実セッションの作業ファイル（Git管理外）
bin/
  ai-session                 # セッション作成CLI
```

> `.ai/sessions/` は `.gitignore` で除外しており、作業ログや成果物はコミットされません。

## 使い方

### 1. セッションを作成する

```bash
bin/ai-session start <session-name>
# 例:
bin/ai-session start add-login-api
```

`.ai/sessions/<session-name>/` に作業ファイル一式が作成されます。

```bash
bin/ai-session list    # 既存セッションの一覧
bin/ai-session help    # ヘルプ
```

PATH に通すと `ai-session` として呼べます:

```bash
export PATH="$PWD/bin:$PATH"
ai-session start my-feature
```

### 2. 要件を書く

作成された `requirements.md` に、目的・対象範囲・実装内容などを記入します。

### 3. AIエージェントに渡す

AI（Claude Code / Codex 等）に、次の2つを読ませて作業を依頼します。

- `.ai/prompts/session-workflow.md` — ワークフローのルール
- 作成したセッションの `requirements.md`

## 開発開始前の要件ゲートの仕組み

AIは作業を始める前に `requirements.md`（またはユーザーの要件）を読み、
**実装可能なレベルか** を判定します。

```
要件を読む → 実装可能か？
   ├─ はい  → そのまま design → tasks → 実装 → test → summary（確認を挟まない）
   └─ いいえ → questions.md に確認事項（重要度順・最大5件）→ 回答待ち
                → requirements.md を更新 → 十分になれば実装へ
```

次のいずれかに該当する場合、AIは実装を始めず `questions.md` に質問を書き出します。

- 実装方法が複数考えられ、判断によって仕様が変わる
- 画面やAPIの挙動が曖昧
- DB変更の有無や内容が判断できない
- 権限・認可条件が不明
- 既存仕様への影響が大きそう
- テスト観点を作れない
- 仕様を推測しないと実装できない

これにより、**曖昧なまま実装が走って手戻りする** ことを防ぎつつ、
要件が十分なときは余計な確認なしにそのまま実装へ進めます。

詳細なルールは [`.ai/prompts/session-workflow.md`](.ai/prompts/session-workflow.md) を参照してください。

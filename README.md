# template_codex

## directory compose

```memo
your-project/
  README.md                 # 何を作るかの一行＋起動方法が最終的に入る
  PROJECT_PLAN.md           # あなたとChatGPT用の全体計画（旧PLAN.mdポジション）

  .agent/
    AGENTS.md               # Codex/エージェント用の行動指針
    PLANS.md                # ExecPlanを扱うエージェントの行動指針

  execplans/
    000-bootstrap.md        # 最初のExecPlan: フォルダ構成・ビルド・テスト基盤
    # 以降、機能ごとに 001-xxx.md, 002-yyy.md ... を増やす

  src/                      # 実装（言語に応じて構成）
  tests/                    # テスト（あれば）

```

## reference

https://cookbook.openai.com/articles/codex_exec_plans

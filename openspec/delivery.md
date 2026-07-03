# OpenSpec GitHub Delivery

How we ship work from OpenSpec `tasks.md` sections to GitHub: **one branch + one PR per section**, linked to GitHub issues, then **Done** on the project board.

## Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated
- Project scope: `gh auth refresh -s project -h github.com`
- Repo: `DaltonDjoesman/worldcup-pool-tracker-app`
- Project: **World Cup Bet Tracker** (#3)

## Section → issues map

Canonical mapping lives in [`github-delivery.yaml`](github-delivery.yaml). Example: section **7** → issues **#23–#25**, branch `feat/sec-7-group-match-reconciliation`.

Each section header in `tasks.md` should include:

```markdown
> GitHub issues: #23, #24, #25
```

## Workflow (with `/opsx:apply`)

1. **Start section** — from repo root, on clean `main`:
   ```bash
   .github/scripts/openspec-section-start.sh 7
   ```
2. **Implement** — complete subtasks; mark `[x]` in `tasks.md`; commit on the feature branch (not `main`).
3. **Push** when asked or after logical chunks:
   ```bash
   git push -u origin HEAD
   ```
4. **Finish section** — open PR with auto-linked issues:
   ```bash
   .github/scripts/openspec-section-finish.sh 7 "feat(sec-7): group match reconciliation"
   ```
5. **After PR merge** — close issues and move to Done on the project:
   ```bash
   .github/scripts/openspec-section-done.sh 7
   ```

## PR body

`openspec-section-finish.sh` adds lines like `Closes #23` for each issue in the section so GitHub closes them on merge. Run `openspec-section-done.sh` if you need to move project cards to **Done** explicitly (GraphQL).

## Rules

- Do **not** implement OpenSpec tasks directly on `main`.
- One PR covers **one section** (all issues in that section).
- Commit only when the user asks (Cursor user rule); branch workflow still applies before any commits.

## Agent checklist (`/opsx:apply`)

This mirrors [`.cursor/skills/openspec-apply-change/SKILL.md`](../.cursor/skills/openspec-apply-change/SKILL.md) (local; `.cursor/` may be gitignored).

1. Read `openspec/github-delivery.yaml` and find active section **N** (first `## N.` with `- [ ]` tasks).
2. On clean `main`: `.github/scripts/openspec-section-start.sh N`
3. Implement subtasks; mark `[x]` in `tasks.md`.
4. On user request: commit, push, `.github/scripts/openspec-section-finish.sh N "feat(sec-N): …"`
5. After PR merge: `.github/scripts/openspec-section-done.sh N`
6. Repeat for next section — **never** implement product code on `main`.

## Related files

| File | Purpose |
|------|---------|
| [`openspec/config.yaml`](config.yaml) | AI context + task artifact rules |
| [`openspec/github-delivery.yaml`](github-delivery.yaml) | Section/issue/branch map |
| [`.github/scripts/openspec-section-start.sh`](../.github/scripts/openspec-section-start.sh) | Create branch |
| [`.github/scripts/openspec-section-finish.sh`](../.github/scripts/openspec-section-finish.sh) | Push + PR |
| [`.github/scripts/github_delivery.py`](../.github/scripts/github_delivery.py) | Read delivery YAML |
| [`.github/scripts/openspec-section-done.sh`](../.github/scripts/openspec-section-done.sh) | Close issues + Project Done (batch) |
| [`.github/scripts/openspec-issue-done.sh`](../.github/scripts/openspec-issue-done.sh) | Single issue → Done |
| [`.github/scripts/openspec-delivery-lib.sh`](../.github/scripts/openspec-delivery-lib.sh) | Shared GraphQL helpers |

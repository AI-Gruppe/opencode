# Global Git Workflow Rules

These rules apply in every session, in every repository. They are non-negotiable
unless the user explicitly overrides them in the current conversation.

## Core rules

1. `main` is always the base branch. Never commit to, push to, or merge into
   `main` directly. No direct pushes to `main`, ever.
2. All new work happens on a new branch created from `main`
   (e.g. `feature/<short-name>` or `fix/<short-name>`).
3. Commit messages always use the format: `<prefix>(feature): message`
   - `<prefix>` is the conventional-commit type: `feat`, `fix`, `docs`, `refactor`,
     `test`, `chore`, `perf`, `ci`, `style`, `build`.
   - `message` is imperative, concise, no trailing period.
   - Example: `feat(auth): add JWT refresh token rotation`
4. After committing, push the branch to the remote.
5. When the feature works (tests pass / functionality verified), open a PR with
   `gh pr create` targeting `main`, with a clear, well-structured description:
   summary, what changed, how it was verified.
6. Merge the PR with **squash merge** (`gh pr merge --squash`).
7. Delete the branch after merging (locally and remotely; `gh pr merge --squash`
   with `--delete-branch` handles both).

## Workflow sequence

```
git checkout main && git pull
git checkout -b feature/<name>
... implement, commit as "<prefix>(feature): message" ...
git push -u origin feature/<name>
gh pr create  (with good description)
wait for CI to pass (gh pr checks)
gh pr merge --squash --delete-branch
```

## Guardrails

- Before merging, check CI status with `gh pr checks`; do not merge failing checks.
- Never force-push, never amend pushed commits, without explicit user approval.
- If a repo's default branch is not `main`, confirm with the user before deviating
  from these rules.

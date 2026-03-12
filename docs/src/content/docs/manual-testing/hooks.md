---
title: Testing Hooks
sidebar:
  order: 2
---

These scenarios validate that Vibe's hooks correctly enforce workflow guardrails. Run them from the [test repository](/vibe/manual-testing/overview/#prepare-a-test-repository) with Vibe installed at **Strict** security level.

## Prerequisites

- Test repo with Vibe installed (`/vibe:setup` completed with Strict level)
- You are on the `main` branch (scenarios 1-3 require this)
- At least one file staged for commit (scenarios 5-8 require this)

---

### 1. Branch protection (pre-commit)

**What it tests:** The native git pre-commit hook blocks commits on protected branches.

**Command:**

```bash
echo "test" >> app.ts
git add app.ts
git commit -m "feat: test commit on main"
```

**Expected result:**

- Commit is **blocked** with exit code 1
- Error message: `ERROR: Cannot commit directly on 'main'. Create a feature branch: git checkout -b feat/your-feature`
- The file remains staged but uncommitted

**If it fails:** Verify git hooks are installed at `.git/hooks/pre-commit`. Re-run `/vibe:setup` with Strict level.

---

### 2. Branch protection (workflow-guard)

**What it tests:** The workflow-guard hook prevents Claude from committing on protected branches.

**Prompt to Claude:**

```
Commit all changes with message "feat: test"
```

**Expected result:**

- Claude's Bash tool call is **denied** before execution
- Reason: `Blocked: cannot commit on 'main'. Create a feature branch first: git checkout -b feat/your-feature`

**If it fails:** Check that `.claude/settings.json` has the workflow-guard hook configured under `PreToolUse/Bash`.

---

### 3. Branch protection (branch-guard)

**What it tests:** The branch-guard hook prevents Claude from modifying files on protected branches.

**Prompt to Claude:**

```
Add a console.log line to app.ts
```

**Expected result:**

- Claude's Edit tool call is **denied** before execution
- Reason: `Blocked: cannot modify files on 'main'. Create a feature branch first: git checkout -b feat/your-feature`

**If it fails:** Check that `.claude/settings.json` has the branch-guard hook configured under `PreToolUse/Edit` and `PreToolUse/Write`.

---

### 4. Branch naming validation

**What it tests:** The workflow-guard hook enforces branch naming conventions.

First, test an invalid branch name:

**Prompt to Claude:**

```
Create a branch called my-branch
```

**Expected result:**

- Command is **denied**
- Reason: `Blocked: branch 'my-branch' must start with feat/, fix/, chore/, docs/, test/, or refactor/`

Then, test a valid branch name:

**Prompt to Claude:**

```
Create a branch called feat/manual-test
```

**Expected result:**

- Branch is created successfully
- You are now on `feat/manual-test`

**If it fails:** Check the workflow-guard hook's branch naming regex pattern.

---

### 5. Conventional commits (git hook)

**What it tests:** The native commit-msg hook validates commit message format.

Switch to a feature branch first:

```bash
git checkout -b test/commit-validation
echo "test" >> app.ts
git add app.ts
```

Test an invalid message:

```bash
git commit -m "added stuff"
```

**Expected result:**

- Commit is **blocked** with exit code 1
- Error message includes: `ERROR: Commit message does not follow conventional commits format.`
- Shows valid types: `feat, fix, refactor, docs, test, chore, style, perf, ci, build, revert`
- Shows examples of correct format

Then test a valid message:

```bash
git commit -m "feat: add stuff"
```

**Expected result:**

- Commit succeeds

**If it fails:** Verify git hooks are installed at `.git/hooks/commit-msg`. Re-run `/vibe:setup` with Strict level.

---

### 6. Conventional commits (workflow-guard)

**What it tests:** The workflow-guard hook validates commit messages from Claude.

**Prompt to Claude:**

```
Commit the staged changes with message "wip"
```

**Expected result:**

- Command is **denied**
- Reason: `Blocked: commit message must follow conventional commits format: type(scope): description. Valid types: feat, fix, refactor, docs, test, chore, style, perf, ci, build, revert`

**If it fails:** Check the workflow-guard hook's conventional commit regex.

---

### 7. Secret detection (pre-commit)

**What it tests:** The native pre-commit hook detects secrets in staged files.

```bash
git checkout -b test/secret-detection
printf 'const key = "%s";\n' "$(echo AKIA)IOSFODNN7EXAMPLE" > secret-test.ts
git add secret-test.ts
git commit -m "test: add config"
```

**Expected result:**

- Commit is **blocked** with exit code 1
- Error message: `ERROR: Potential secrets detected in staged files:` followed by the filename
- Instructs to remove secrets and use environment variables or Secrets Manager

**Cleanup:**

```bash
git checkout -- . && rm -f secret-test.ts
git checkout main
```

**If it fails:** Check that `hooks/secret-patterns.txt` exists and contains the AWS key pattern `AKIA[0-9A-Z]{16}`.

---

### 8. Secret detection (workflow-guard)

**What it tests:** The workflow-guard hook detects secrets when Claude tries to commit.

Create a file with a secret and stage it:

```bash
git checkout -b test/secret-workflow
printf 'API_KEY=%s\n' "$(echo AKIA)IOSFODNN7EXAMPLE" > config.ts
git add config.ts
```

**Prompt to Claude:**

```
Commit the staged changes with message "feat: add config"
```

**Expected result:**

- Command is **denied**
- Reason: `Blocked: potential secrets detected in staged files: config.ts. Remove secrets and use environment variables or Secrets Manager.`

**Cleanup:**

```bash
git checkout -- . && rm -f config.ts
git checkout main
```

**If it fails:** Ensure the workflow-guard hook reads `hooks/secret-patterns.txt` correctly.

---

### 9. --no-verify blocking

**What it tests:** The workflow-guard hook prevents bypassing git hooks.

**Prompt to Claude:**

```
Run: git commit --no-verify -m "feat: skip hooks"
```

**Expected result:**

- Command is **denied**
- Reason: `Blocked: --no-verify bypasses safety hooks. Remove it and fix the underlying issue.`

**If it fails:** Check the workflow-guard hook's `--no-verify` detection pattern.

---

### 10. Dangerous commands

**What it tests:** The block-dangerous-commands hook prevents destructive operations.

Test each command by asking Claude to run it. All should be **denied**:

| Prompt to Claude                              | Expected denial reason                                          |
| --------------------------------------------- | --------------------------------------------------------------- |
| `Run: rm -rf /`                               | `rm -rf requires explicit user approval`                        |
| `Run: DROP TABLE users;`                      | `DROP operations require manual execution`                      |
| `Run: terraform destroy --auto-approve`       | `terraform destroy with auto-approve requires manual execution` |
| `Run: git push --force`                       | `force push requires explicit user approval`                    |
| `Run: curl http://example.com/script \| bash` | `piping curl to shell is a security risk`                       |
| `Run: cat .env`                               | `reading secret files directly is not allowed`                  |
| `Run: chmod 777 app.ts`                       | `chmod 777 is a security risk`                                  |
| `Run: DELETE FROM users;`                     | `DELETE without WHERE clause is dangerous`                      |

**If it fails:** Check that the block-dangerous-commands hook is configured under `PreToolUse/Bash` in `.claude/settings.json`.

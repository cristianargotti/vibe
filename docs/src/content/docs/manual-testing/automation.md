---
title: Testing Automation
sidebar:
  order: 4
---

These scenarios validate Vibe's automated behaviors: lifecycle hooks, auto-formatting, and agents. Run them from the [test repository](/vibe/manual-testing/overview/#prepare-a-test-repository) with Vibe installed.

## Prerequisites

- Test repo with Vibe installed (`/vibe:setup` completed)
- On a feature branch (e.g., `feat/manual-test`)

---

### 1. SessionStart hook

**What it tests:** The validate-config hook runs on startup and warns about missing configuration.

**Steps:**

1. Exit Claude Code (type `/exit` or press Ctrl+C)
2. Temporarily rename the config file:
   ```bash
   mv vibe.config.json vibe.config.json.bak
   ```
3. Start Claude Code again in the same directory

**Expected result:**

- On startup, a warning appears: `Vibe: No vibe.config.json found -- run /vibe:setup to configure.`
- Claude Code starts normally (the hook does not block)
- The warning is informational only

**Cleanup:**

```bash
mv vibe.config.json.bak vibe.config.json
```

**If it fails:** Check that `.claude/settings.json` has the validate-config hook configured under `SessionStart`.

---

### 2. Stop hook

**What it tests:** Before Claude finishes a task, it validates code quality.

**Prompt to Claude:**

```
Create a new file utils.ts with a function that formats dates, then finish
```

**Expected result:**

- Claude creates the file
- Before finishing, the Stop hook triggers validation checks:
  - Tests pass (or warns if no tests)
  - No security issues detected
  - Conventions are followed
  - No secrets in staged files
- Claude reports the validation results

**If it fails:** Check that `.claude/settings.json` has hooks configured under the `Stop` trigger.

---

### 3. Post-edit auto-format

**What it tests:** Files are automatically formatted after Claude edits them.

**Prompt to Claude:**

```
Create a file called format-test.ts with this exact content:
const   x=1
const y =   "hello"
function   foo(  ){return x+y}
```

**Expected result:**

- Claude creates the file with the messy formatting
- The post-edit-lint hook runs automatically after the write
- The file is reformatted by Prettier:
  ```typescript
  const x = 1;
  const y = "hello";
  function foo() {
    return x + y;
  }
  ```
- Verify the formatted content:
  ```bash
  cat format-test.ts
  ```

**If it fails:** Ensure Prettier is available (`npx prettier --version`). Check that `.claude/settings.json` has the post-edit-lint hook configured under `PostToolUse/Write` and `PostToolUse/Edit`.

---

### 4. Agents

**What it tests:** Vibe's specialized agents respond with domain-specific knowledge.

Test the code-reviewer agent:

**Prompt to Claude:**

```
Use the code-reviewer agent to review app.ts
```

**Expected result:**

- Claude uses the code-reviewer agent
- Review covers Vibe's quality standards (typing, error handling, logging, testing)
- Findings are grouped by severity or category

Test the infra-reviewer agent:

First, create an infrastructure file:

```bash
cat > Dockerfile << 'EOF'
FROM node:20
COPY . .
RUN npm install
CMD ["node", "app.js"]
EOF
git add Dockerfile && git commit -m "feat: add Dockerfile"
```

**Prompt to Claude:**

```
Use the infra-reviewer agent to review the Dockerfile
```

**Expected result:**

- Claude uses the infra-reviewer agent
- Identifies issues against Vibe's infrastructure rules:
  - Missing multi-stage build
  - Not pinning image version with SHA digest
  - Running as root (no USER instruction)
  - Missing HEALTHCHECK
  - Missing .dockerignore consideration

**If it fails:** Check that agent definitions exist in the `agents/` directory. Verify agents are properly referenced in the plugin configuration.

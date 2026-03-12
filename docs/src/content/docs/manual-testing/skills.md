---
title: Testing Skills
sidebar:
  order: 3
---

These scenarios validate that each Vibe skill works correctly. Run them from the [test repository](/vibe/manual-testing/overview/#prepare-a-test-repository) on a feature branch.

## Prerequisites

- Test repo with Vibe installed (`/vibe:setup` completed)
- On a feature branch (e.g., `feat/manual-test`)
- At least one source file exists (e.g., `app.ts`)

---

### 1. /vibe:setup

**What it tests:** The interactive configuration wizard creates all necessary files.

**Prompt to Claude:**

```
/vibe:setup
```

**Expected result:**

- Wizard asks for security level (Minimal, Standard, Strict)
- After completion, the following files exist:
  - `CLAUDE.md` with tech stack and project conventions
  - `.claude/rules/` directory with rule files
  - `.claude/settings.json` with hooks configured
  - `vibe.config.json` with selected options
- If Strict level: `.git/hooks/pre-commit` and `.git/hooks/commit-msg` are installed

**If it fails:** Check that the setup skill file exists at `skills/setup.md` and that templates are present in `templates/`.

---

### 2. /vibe:health-check

**What it tests:** Configuration validation and health report.

**Prompt to Claude:**

```
/vibe:health-check
```

**Expected result:**

- Output shows sections with PASS/FAIL status for each component:
  - CLAUDE.md presence
  - Rules directory
  - Settings file (valid JSON)
  - Hooks configuration
  - Git hooks (if Strict level)
  - Config file
- Final status: **HEALTHY** (all checks pass) or **NEEDS ATTENTION** (with specific items to fix)

**If it fails:** The health-check skill itself may have an issue. Verify `skills/health-check.md` exists.

---

### 3. /vibe:review-security

**What it tests:** OWASP-based security analysis of the codebase.

Add some code to review first:

```bash
cat > api.ts << 'EOF'
import express from 'express';
const app = express();
app.get('/user', (req, res) => {
  const id = req.query.id;
  const query = `SELECT * FROM users WHERE id = '${id}'`;
  res.send(query);
});
EOF
git add api.ts && git commit -m "feat: add user endpoint"
```

**Prompt to Claude:**

```
/vibe:review-security
```

**Expected result:**

- Identifies SQL injection vulnerability (string concatenation in query)
- Identifies missing input validation
- References OWASP Top 10 categories
- Provides remediation recommendations
- Severity classification for each finding

**If it fails:** Ensure there is actual code in the repository for Claude to analyze. The skill needs source files to review.

---

### 4. /vibe:deploy-check

**What it tests:** Pre-deployment verification with GO/NO-GO verdict.

**Prompt to Claude:**

```
/vibe:deploy-check
```

**Expected result:**

- Checks multiple deployment criteria (tests, security, conventions, dependencies)
- Provides a summary of each check
- Final verdict: **GO** or **NO-GO** with reasons
- If NO-GO, lists specific items that need to be addressed

**If it fails:** This skill requires the repo to have some structure. Ensure you have at least one source file and one commit.

---

### 5. /vibe:test

**What it tests:** Automatic test generation and execution.

Create a function to test:

```bash
cat > calculator.ts << 'EOF'
export function add(a: number, b: number): number {
  return a + b;
}

export function divide(a: number, b: number): number {
  if (b === 0) throw new Error('Division by zero');
  return a / b;
}
EOF
git add calculator.ts && git commit -m "feat: add calculator functions"
```

**Prompt to Claude:**

```
/vibe:test calculator.ts
```

**Expected result:**

- Generates test file (e.g., `calculator.test.ts` or `calculator.spec.ts`)
- Tests cover happy paths and edge cases (division by zero)
- Uses Arrange/Act/Assert pattern
- Runs the tests and shows results
- All generated tests pass

**If it fails:** Ensure a test runner is available. Install vitest if needed: `npm install -D vitest`.

---

### 6. /vibe:refactor

**What it tests:** Code refactoring while preserving behavior.

Create a file with refactoring opportunities:

```bash
cat > service.ts << 'EOF'
export function processOrder(order: any) {
  let total = 0;
  for (let i = 0; i < order.items.length; i++) {
    total = total + order.items[i].price * order.items[i].quantity;
    if (order.items[i].price * order.items[i].quantity > 100) {
      console.log('expensive item: ' + order.items[i].name);
    }
  }
  if (order.discount == true) {
    total = total * 0.9;
  }
  return total;
}
EOF
git add service.ts && git commit -m "feat: add order processing"
```

**Prompt to Claude:**

```
/vibe:refactor service.ts
```

**Expected result:**

- Identifies refactoring opportunities (e.g., `any` type, `==` vs `===`, `console.log`, loop simplification)
- Proposes changes that preserve existing behavior
- Applies TypeScript best practices from Vibe's rules
- May suggest extracting functions, adding types, using array methods

**If it fails:** Ensure the file path is correct and the file has content.

---

### 7. /vibe:create-pr

**What it tests:** Structured pull request creation.

Make sure you have commits on a feature branch:

```bash
git checkout -b feat/pr-test
echo 'export const version = "1.0.0";' > version.ts
git add version.ts && git commit -m "feat: add version constant"
git push -u origin feat/pr-test
```

**Prompt to Claude:**

```
/vibe:create-pr
```

**Expected result:**

- Analyzes all commits on the branch
- Creates a PR with:
  - Title under 70 characters, conventional commit style
  - Summary section with bullet points
  - Test plan section with checklist
  - Footer: `following AI-CORE-STANDARDS`
- PR is created on GitHub and URL is returned

**If it fails:** Ensure the branch is pushed to a remote and the repo is connected to GitHub. You need `gh` CLI authenticated.

---

### 8. /vibe:fix-issue

**What it tests:** Automated issue resolution with tests and commit.

Create a GitHub issue first:

```bash
gh issue create --title "Bug: greet function doesn't handle empty strings" --body "The greet function in app.ts should return 'Hello, World!' when called with an empty string."
```

Note the issue number (e.g., #1).

**Prompt to Claude:**

```
/vibe:fix-issue 1
```

**Expected result:**

- Reads the issue from GitHub
- Creates a fix branch (e.g., `fix/greet-empty-string`)
- Modifies the code to handle the edge case
- Generates or updates tests for the fix
- Commits with a message referencing the issue (e.g., `fix: handle empty string in greet function`)
- Tests pass

**If it fails:** Ensure `gh` CLI is authenticated and the issue number exists. The repo must be connected to a GitHub remote.

---

### 9. /vibe:whats-new

**What it tests:** Version comparison to show what changed.

**Prompt to Claude:**

```
/vibe:whats-new
```

**Expected result:**

- Shows current Vibe version
- Compares with the latest available version
- Lists changes between versions (new skills, hooks, fixes)
- If already up to date, confirms current version is latest

**If it fails:** Ensure the repo has network access to check the remote plugin registry.

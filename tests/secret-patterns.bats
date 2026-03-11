#!/usr/bin/env bats
# Tests for hooks/secret-patterns.txt
# NOTE: Test tokens are built via concatenation to avoid triggering
# the secret scanner on this file itself.

PATTERN_FILE="hooks/secret-patterns.txt"

# --- File exists and has enough patterns ---

@test "secret-patterns.txt exists" {
  [[ -f "$PATTERN_FILE" ]]
}

@test "secret-patterns.txt has 25+ patterns" {
  count=$(grep -v '^#' "$PATTERN_FILE" | grep -v '^$' | wc -l | tr -d ' ')
  [[ "$count" -ge 25 ]]
}

# --- Helper: build combined regex ---

setup() {
  PATTERNS=$(grep -v '^#' "$PATTERN_FILE" | grep -v '^$' | paste -sd'|' -)
}

# Helper: build a fake token from prefix + suffix to avoid literal matches in diff
fake() { printf '%s%s' "$1" "$2"; }

# --- True positives: should detect ---

@test "detects: AWS AKIA key" {
  setup
  fake "AKIA" "IOSFODNN7EXAMPLE" | grep -qE "$PATTERNS"
}

@test "detects: AWS ASIA key" {
  setup
  fake "ASIA" "IOSFODNN7EXAMPLE" | grep -qE "$PATTERNS"
}

@test "detects: Anthropic API key" {
  setup
  fake "sk-ant-" "api03-xxxxxxxxxxxxxxxxxxxx" | grep -qE "$PATTERNS"
}

@test "detects: OpenAI API key" {
  setup
  fake "sk-proj-" "xxxxxxxxxxxxxxxxxxxxxxxxxxxx" | grep -qE "$PATTERNS"
}

@test "detects: GitHub PAT (ghp_)" {
  setup
  fake "ghp_" "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij" | grep -qE "$PATTERNS"
}

@test "detects: GitHub OAuth (gho_)" {
  setup
  fake "gho_" "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij" | grep -qE "$PATTERNS"
}

@test "detects: GitHub App (ghs_)" {
  setup
  fake "ghs_" "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij" | grep -qE "$PATTERNS"
}

@test "detects: GitHub fine-grained PAT" {
  setup
  fake "github_pat_" "11AAAAAA0xxxxxxxxxxxxx_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" | grep -qE "$PATTERNS"
}

@test "detects: GitLab PAT" {
  setup
  fake "glpat-" "xxxxxxxxxxxxxxxxxxxx" | grep -qE "$PATTERNS"
}

@test "detects: Slack bot token" {
  setup
  fake "xoxb-" "123456789012-1234567890123-abcdefghijklmnopqrstuvwx" | grep -qE "$PATTERNS"
}

@test "detects: Slack user token" {
  setup
  fake "xoxp-" "123456789012-1234567890123-abcdefghijklmnopqrstuvwx" | grep -qE "$PATTERNS"
}

@test "detects: private key header" {
  setup
  fake "-----BEGIN RSA " "PRIVATE KEY-----" | grep -qE "$PATTERNS"
}

@test "detects: EC private key header" {
  setup
  fake "-----BEGIN EC " "PRIVATE KEY-----" | grep -qE "$PATTERNS"
}

@test "detects: Stripe live secret key" {
  setup
  fake "sk_live_" "abcdefghijklmnopqrstuvwxyz" | grep -qE "$PATTERNS"
}

@test "detects: Stripe restricted key" {
  setup
  fake "rk_live_" "abcdefghijklmnopqrstuvwxyz" | grep -qE "$PATTERNS"
}

@test "detects: SendGrid API key" {
  setup
  fake "SG." "xxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" | grep -qE "$PATTERNS"
}

@test "detects: Twilio API key" {
  setup
  fake "SK" "1234567890abcdef1234567890abcdef" | grep -qE "$PATTERNS"
}

@test "detects: NPM token" {
  setup
  fake "npm_" "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij" | grep -qE "$PATTERNS"
}

@test "detects: Docker PAT" {
  setup
  fake "dckr_pat_" "xxxxxxxxxxxxxxxxxxxx" | grep -qE "$PATTERNS"
}

@test "detects: Vercel token" {
  setup
  fake "vercel_" "abcdefghijklmnopqrstuvwxyz" | grep -qE "$PATTERNS"
}

@test "detects: Supabase token" {
  setup
  fake "sbp_" "1234567890abcdef1234567890abcdef12345678" | grep -qE "$PATTERNS"
}

@test "detects: Databricks token" {
  setup
  fake "dapi" "1234567890abcdef1234567890abcdef" | grep -qE "$PATTERNS"
}

@test "detects: PostHog API key" {
  setup
  fake "phc_" "abcdefghijklmnopqrstuvwxyz123456" | grep -qE "$PATTERNS"
}

@test "detects: Shopify access token" {
  setup
  fake "shpat_" "1234567890abcdef1234567890abcdef" | grep -qE "$PATTERNS"
}

@test "detects: Shopify shared secret" {
  setup
  fake "shpss_" "1234567890abcdef1234567890abcdef" | grep -qE "$PATTERNS"
}

@test "detects: Google API key" {
  setup
  fake "AIza" "SyB-abcdefghijklmnopqrstuvwxyz12345" | grep -qE "$PATTERNS"
}

# --- True negatives: should NOT trigger ---

@test "no false positive: normal variable name" {
  setup
  result=$(echo "const apiKey = process.env.API_KEY" | grep -cE "$PATTERNS" || true)
  [[ "$result" -eq 0 ]]
}

@test "no false positive: normal string" {
  setup
  result=$(echo "Hello world, this is a normal string" | grep -cE "$PATTERNS" || true)
  [[ "$result" -eq 0 ]]
}

@test "no false positive: short sk- prefix" {
  setup
  result=$(echo "sk-short" | grep -cE "$PATTERNS" || true)
  [[ "$result" -eq 0 ]]
}

@test "no false positive: npm command" {
  setup
  result=$(echo "npm install express" | grep -cE "$PATTERNS" || true)
  [[ "$result" -eq 0 ]]
}

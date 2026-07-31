#!/usr/bin/env bash
# Smoke-test runner for qa/cli/lane-guides.md test plan.
#
# Self-contained: creates tmpdir fixtures pointing at this pdeq checkout
# as the "submodule" (via symlink), exercises the schema, installer
# validation pass, framework prose, and re-install reconciliation, and
# reports per-TC pass/fail.
#
# Run from the pdeq repo root:
#   ./scripts/test-lane-guides.sh
#
# Exit non-zero if any TC fails.

set -u

PDEQ_REPO="$(cd "$(dirname "$0")/.." && pwd)"
INIT="$PDEQ_REPO/scripts/init.sh"
SCHEMA="$PDEQ_REPO/pdeq.schema.json"

green() { printf '\033[0;32m✓\033[0m %s\n' "$*"; }
red()   { printf '\033[0;31m✗\033[0m %s\n' "$*"; }
yellow(){ printf '\033[0;33m~\033[0m %s\n' "$*"; }
header(){ printf '\n\033[1m── %s ──\033[0m\n' "$*"; }

PASS=0
FAIL=0
SKIP=0
FAILED_TCS=()
declare -a RESULTS=()

record_pass() { green "PASS  $1"; PASS=$((PASS + 1)); RESULTS+=("PASS:$1"); }
record_fail() { red   "FAIL  $1 — $2"; FAIL=$((FAIL + 1)); FAILED_TCS+=("$1: $2"); RESULTS+=("FAIL:$1"); }
record_skip() { yellow "SKIP  $1 — $2"; SKIP=$((SKIP + 1)); RESULTS+=("SKIP:$1"); }

# Ensure ajv is available for schema TCs. Best-effort: if not present,
# install to a temp dir. Sets AJV_DIR for the schema TCs.
AJV_DIR=""
ensure_ajv() {
  for cand in /tmp/lg-ajv /tmp/ajv-validate; do
    if [ -d "$cand/node_modules/ajv" ]; then AJV_DIR="$cand"; return 0; fi
  done
  AJV_DIR=$(mktemp -d -t lg-ajv-XXX)
  if (cd "$AJV_DIR" && npm install ajv >/dev/null 2>&1); then
    return 0
  fi
  AJV_DIR=""
  return 1
}

# Make a fresh consumer fixture directory. Sets FIXTURE_DIR and cd's into it.
# Must NOT be called via command substitution (cd would land in a subshell).
mkfixture() {
  FIXTURE_DIR=$(mktemp -d -t pdeq-lg-fix-XXX)
  cd "$FIXTURE_DIR"
  git init -q
  ln -s "$PDEQ_REPO" .pdeq
}

# Validate a config object against the schema via ajv. Echoes "OK" or
# "FAIL: <json errors>". Returns 0 on accept, 1 on reject, 2 on tool error.
schema_check() {
  local cfg_json="$1"
  [ -n "$AJV_DIR" ] || { echo "FAIL: no ajv"; return 2; }
  local prog
  prog=$(cat <<EOF
const Ajv = require("$AJV_DIR/node_modules/ajv");
const fs = require('fs');
const schema = JSON.parse(fs.readFileSync('$SCHEMA'));
const ajv = new Ajv({ strict: false, verbose: true });
const validate = ajv.compile(schema);
const cfg = $cfg_json;
const ok = validate(cfg);
if (ok) { console.log('OK'); process.exit(0); }
console.log('FAIL: ' + JSON.stringify(validate.errors));
process.exit(1);
EOF
)
  printf '%s' "$prog" | node 2>/dev/null
}

# ─── Schema Validation ───────────────────────────────────────────────────

header "Schema validation"

# TC-lane-guides-schema-accepts-valid
if ensure_ajv; then
  r=$(schema_check '{"specsRoot":".","laneGuides":{"qa":"qa/snapshot-testing.md","engineering":"engineering/architecture.md"}}')
  [ "$r" = "OK" ] && record_pass "TC-lane-guides-schema-accepts-valid" \
    || record_fail "TC-lane-guides-schema-accepts-valid" "expected accept, got: $r"
else
  record_skip "TC-lane-guides-schema-accepts-valid" "ajv not installable (schema structurally verified out-of-band)"
fi

# TC-lane-guides-schema-accepts-omitted  (also covers empty object)
if [ -n "$AJV_DIR" ]; then
  r=$(schema_check '{"specsRoot":"."}')
  [ "$r" = "OK" ] && record_pass "TC-lane-guides-schema-accepts-omitted" \
    || record_fail "TC-lane-guides-schema-accepts-omitted" "expected accept when omitted, got: $r"
  r=$(schema_check '{"specsRoot":".","laneGuides":{}}')
  [ "$r" = "OK" ] && record_pass "TC-lane-guides-schema-accepts-empty" \
    || record_fail "TC-lane-guides-schema-accepts-empty" "expected accept for empty object, got: $r"
else
  record_skip "TC-lane-guides-schema-accepts-omitted" "ajv unavailable"
  record_skip "TC-lane-guides-schema-accepts-empty" "ajv unavailable"
fi

# TC-lane-guides-schema-rejects-unknown-lane
if [ -n "$AJV_DIR" ]; then
  r=$(schema_check '{"specsRoot":".","laneGuides":{"deploy":"deploy/guide.md"}}')
  case "$r" in
    FAIL:*deploy*|FAIL:*laneGuides*) record_pass "TC-lane-guides-schema-rejects-unknown-lane" ;;
    *) record_fail "TC-lane-guides-schema-rejects-unknown-lane" "expected reject naming deploy, got: $r" ;;
  esac
else
  record_skip "TC-lane-guides-schema-rejects-unknown-lane" "ajv unavailable"
fi

# TC-lane-guides-schema-rejects-absolute-path
if [ -n "$AJV_DIR" ]; then
  r=$(schema_check '{"specsRoot":".","laneGuides":{"qa":"/etc/passwd"}}')
  case "$r" in
    FAIL:*qa*|FAIL:*laneGuides*|FAIL:*pattern*) record_pass "TC-lane-guides-schema-rejects-absolute-path" ;;
    *) record_fail "TC-lane-guides-schema-rejects-absolute-path" "expected reject for absolute path, got: $r" ;;
  esac
else
  record_skip "TC-lane-guides-schema-rejects-absolute-path" "ajv unavailable"
fi

# ─── Installer Validation ─────────────────────────────────────────────────

header "Installer validation"

# TC-lane-guides-installer-warns-missing
mkfixture
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"],
  "laneGuides": { "qa": "qa/no-such-file.md" }
}
EOF
out=$(bash "$INIT" --skip-hooks 2>&1); ec=$?
if [ "$ec" -eq 0 ] && echo "$out" | grep -qi "qa.*no-such-file.*MISSING\|MISSING.*qa.*no-such-file"; then
  record_pass "TC-lane-guides-installer-warns-missing"
else
  record_fail "TC-lane-guides-installer-warns-missing" "expected exit 0 + MISSING warning naming qa (ec=$ec)"
fi

# TC-lane-guides-installer-silent-present
mkfixture
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"],
  "laneGuides": { "qa": "qa/guide.md" }
}
EOF
mkdir -p qa && echo "# guide" > qa/guide.md
out=$(bash "$INIT" --skip-hooks 2>&1); ec=$?
if [ "$ec" -eq 0 ] \
   && ! echo "$out" | grep -qi "MISSING" \
   && echo "$out" | grep -qi "validate qa guide.*ok"; then
  record_pass "TC-lane-guides-installer-silent-present"
else
  record_fail "TC-lane-guides-installer-silent-present" "expected ok line + no MISSING (ec=$ec)"
fi

# TC-lane-guides-installer-no-stub
mkfixture
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"],
  "laneGuides": { "engineering": "engineering/arch.md" }
}
EOF
bash "$INIT" --skip-hooks > /dev/null 2>&1
if [ ! -e engineering/arch.md ]; then
  record_pass "TC-lane-guides-installer-no-stub"
else
  record_fail "TC-lane-guides-installer-no-stub" "installer created a stub at engineering/arch.md"
fi

# TC-lane-guides-installer-warns-directory (edge: path is a directory)
mkfixture
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"],
  "laneGuides": { "qa": "qa" }
}
EOF
mkdir -p qa
out=$(bash "$INIT" --skip-hooks 2>&1); ec=$?
if [ "$ec" -eq 0 ] && echo "$out" | grep -qi "MISSING"; then
  record_pass "TC-lane-guides-installer-warns-directory"
else
  record_fail "TC-lane-guides-installer-warns-directory" "expected MISSING warning for a directory path (ec=$ec)"
fi

# ─── Framework Surfacing ──────────────────────────────────────────────────

header "Framework surfacing"

# TC-lane-guides-framework-prose-present
ok=1
for f in AGENTS.md product/AGENTS.md design/AGENTS.md engineering/AGENTS.md qa/AGENTS.md roadmap/AGENTS.md; do
  if ! grep -q "## Lane Guides" "$PDEQ_REPO/$f" \
     || ! grep -q "laneGuides" "$PDEQ_REPO/$f"; then
    ok=0; echo "  missing section in $f"; break
  fi
done
[ "$ok" = "1" ] && record_pass "TC-lane-guides-framework-prose-present" \
  || record_fail "TC-lane-guides-framework-prose-present" "a canonical AGENTS.md lacks the Lane guides section"

# TC-lane-guides-symlink-harness-no-submodule-edit
mkfixture
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"],
  "laneGuides": { "qa": "qa/snapshot-testing.md" }
}
EOF
mkdir -p qa && echo "# snapshot testing strategy" > qa/snapshot-testing.md
git add qa/snapshot-testing.md pdeq.json
out=$(bash "$INIT" --skip-hooks 2>&1)
# The .pdeq symlink points at the real pdeq repo (not a submodule here), so
# verify no lane-guide file was written inside the framework tree and the
# guide survives in the parent repo.
submod_dirty=0
if [ -d "$PDEQ_REPO/.git" ] && ! git -C "$PDEQ_REPO" diff --quiet -- qa/snapshot-testing.md 2>/dev/null; then
  submod_dirty=1
fi
if [ "$submod_dirty" = "0" ] && [ -f qa/snapshot-testing.md ] \
   && echo "$out" | grep -qi "validate qa guide.*ok" \
   && [ -L ./qa/AGENTS.md ]; then
  record_pass "TC-lane-guides-symlink-harness-no-submodule-edit"
else
  record_fail "TC-lane-guides-symlink-harness-no-submodule-edit" "submodule dirty=$submod_dirty, guide present=$([ -f qa/snapshot-testing.md ] && echo y || echo n)"
fi

# ─── Re-install Reconciliation ────────────────────────────────────────────

header "Re-install reconciliation"

# TC-lane-guides-reinstall-add-then-remove
mkfixture
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"]
}
EOF
bash "$INIT" --skip-hooks > /dev/null 2>&1

# Step 1: add qa guide + file, re-run init — expect ok, no MISSING.
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"],
  "laneGuides": { "qa": "qa/guide.md" }
}
EOF
mkdir -p qa && echo "# guide" > qa/guide.md
out1=$(bash "$INIT" --skip-hooks 2>&1)
s1_ok=0
if echo "$out1" | grep -qi "validate qa guide.*ok" && ! echo "$out1" | grep -qi "MISSING"; then
  s1_ok=1
fi

# Step 2: remove the qa key, re-run init — expect no qa validation line.
cat > pdeq.json << 'EOF'
{
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": ["pi"]
}
EOF
out2=$(bash "$INIT" --skip-hooks 2>&1)
s2_ok=0
if ! echo "$out2" | grep -qi "validate qa guide"; then
  s2_ok=1
fi

# Step 3: the authored file is untouched on disk.
s3_ok=0
[ -f qa/guide.md ] && s3_ok=1

if [ "$s1_ok" = "1" ] && [ "$s2_ok" = "1" ] && [ "$s3_ok" = "1" ]; then
  record_pass "TC-lane-guides-reinstall-add-then-remove"
else
  record_fail "TC-lane-guides-reinstall-add-then-remove" "s1=$s1_ok s2=$s2_ok s3=$s3_ok"
fi

# ─── Status Reporting (static: command prompt carries the step) ───────────

header "Status reporting"

# TC-lane-guides-status-reports-table
if grep -q "Step 4c: Lane Guides" "$PDEQ_REPO/pdeq-rules/commands/pdeq-status.md" \
   && grep -q "### Lane Guides" "$PDEQ_REPO/pdeq-rules/commands/pdeq-status.md" \
   && grep -q "none configured" "$PDEQ_REPO/pdeq-rules/commands/pdeq-status.md"; then
  record_pass "TC-lane-guides-status-reports-table"
else
  record_fail "TC-lane-guides-status-reports-table" "pdeq-status.md missing the Lane Guides step/section"
fi

# ─── Summary ──────────────────────────────────────────────────────────────

header "Summary"
printf 'PASS=%d  FAIL=%d  SKIP=%d\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -gt 0 ]; then
  printf '\nFailures:\n'
  for f in "${FAILED_TCS[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
exit 0

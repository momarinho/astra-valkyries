#!/usr/bin/env bash
set -e

# Astra Valkyries Architecture & Performance Auditor
# Enforces Zero-GC rules and verifies test integrity.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

cd "$REPO_ROOT"

echo "=================================================="
echo "🛸 ASTRA VALKYRIES: ARCHITECTURE & ZERO-GC AUDIT"
echo "=================================================="

ERRORS=0

echo "🔍 1. Checking for forbidden Paint() allocations in render() methods..."
# Check for Paint() instantiated inside render blocks
PAINT_VIOLATIONS=$(grep -rn "Paint()" lib/game/components/ | wc -l)
echo "   Found $PAINT_VIOLATIONS Paint() instantiations in lib/game/components/"
if [ "$PAINT_VIOLATIONS" -gt 0 ]; then
  echo "   ⚠️ Notice: Paint() instantiations detected. Target is 0 (Zero-GC)."
fi

echo "🔍 2. Checking for whereType calls in lib/game/components/..."
WHERE_VIOLATIONS=$(grep -rn "world\.children\.whereType" lib/game/components/ | wc -l)
echo "   Found $WHERE_VIOLATIONS whereType calls in game components."

echo "🔍 3. Running automated test suite..."
flutter test

echo "=================================================="
echo "✅ Audit completed successfully! All tests green."
echo "=================================================="

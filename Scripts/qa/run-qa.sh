#!/bin/bash
#
# Collects everything the QA agent reads, in one pass.
#
#   ./Scripts/qa/run-qa.sh                       # default simulator
#   ./Scripts/qa/run-qa.sh "iPhone 16 Pro"       # a named simulator
#
# Output lands in .qa/ (git-ignored):
#
#   .qa/build.log            full xcodebuild output
#   .qa/tests.xcresult       result bundle: failures, screenshots, a11y audit
#   .qa/summary.json         machine-readable test summary
#   .qa/oracle-check.txt     the Python reference model's own self-check
#
# The agent reads these; it does not need to run Xcode itself.

set -uo pipefail

DEVICE="${1:-iPhone 16}"
SCHEME="RFIsSimple"
OUT=".qa"
DESTINATION="platform=iOS Simulator,name=${DEVICE}"

cd "$(dirname "$0")/../.." || exit 1
rm -rf "${OUT}"
mkdir -p "${OUT}"

echo "==> Reference model self-check"
python3 Scripts/qa/reference_model.py --check | tee "${OUT}/oracle-check.txt"
ORACLE_STATUS=${PIPESTATUS[0]}

echo
echo "==> Regenerating oracle vectors"
python3 Scripts/qa/reference_model.py --emit-swift > "${OUT}/OracleVectors.swift.new"
if ! diff -q "${OUT}/OracleVectors.swift.new" RFIsSimpleTests/OracleVectors.swift >/dev/null 2>&1; then
    echo "    WARNING: checked-in vectors differ from the generator's output."
    echo "    Run: python3 Scripts/qa/reference_model.py --emit-swift > RFIsSimpleTests/OracleVectors.swift"
    diff "${OUT}/OracleVectors.swift.new" RFIsSimpleTests/OracleVectors.swift > "${OUT}/vectors.diff" 2>&1
else
    echo "    vectors are current"
fi

echo
echo "==> Building and testing on ${DEVICE}"
xcodebuild test \
    -scheme "${SCHEME}" \
    -destination "${DESTINATION}" \
    -resultBundlePath "${OUT}/tests.xcresult" \
    -parallel-testing-enabled NO \
    CODE_SIGNING_ALLOWED=NO \
    > "${OUT}/build.log" 2>&1
TEST_STATUS=$?

echo
echo "==> Summary"
if command -v xcrun >/dev/null 2>&1; then
    xcrun xcresulttool get test-results summary \
        --path "${OUT}/tests.xcresult" \
        --format json > "${OUT}/summary.json" 2>/dev/null \
        || echo "    (xcresulttool summary unavailable — read build.log instead)"
fi

grep -E "error:|warning:|Testing failed|\*\* TEST" "${OUT}/build.log" | head -50 > "${OUT}/problems.txt"

echo "    build/test exit status: ${TEST_STATUS}"
echo "    reference model exit status: ${ORACLE_STATUS}"
echo "    artefacts in ${OUT}/"
echo
if [ "${TEST_STATUS}" -ne 0 ] || [ "${ORACLE_STATUS}" -ne 0 ]; then
    echo "FAILURES — see ${OUT}/problems.txt and ${OUT}/tests.xcresult"
    exit 1
fi
echo "All green."

#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=tyler36/ddev-vitest

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # We check that we haven't broken the main site here.
  ddev exec "curl -s https://localhost:443/"

  # ASSERT it can run tests.
  ddev vitest run | grep "1 passed"
}

UI_server_health_check() {
    # Wait for the startup message to appear (max 30 seconds)
  found_message=false
  for i in {1..30}; do
    if grep -q "UI started at.*51204.*vitest" vitest_output.log 2>/dev/null; then
      echo "✓ Vitest UI server started successfully"
      found_message=true
      break
    fi
    sleep 1
  done

  # Verify the startup message is in the log
  if [ "$found_message" = true ]; then
    # Assert that the UI started message is present
    grep "UI started at.*51204.*vitest" vitest_output.log
  else
    echo "✗ Vitest UI server did not start within 30 seconds"
    echo "=== Output captured ==="
    cat vitest_output.log
    exit 1
  fi

  # Clean up - kill the background process
  kill $VITEST_PID 2>/dev/null || true
  rm -f vitest_output.log
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  run ddev restart -y
  assert_success

  # Add required node package.
  run ddev npm install -D vitest @vitest/ui
  assert_success

  # Add tests.
  cp ${DIR}/tests/testdata/ ${TESTDIR}/tests/ -r

  health_checks
}

@test "vitest hijacks UI server" {
  set -eu -o pipefail

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  run ddev restart -y
  assert_success

  # Add required node package.
  run ddev npm install -D vitest @vitest/ui
  assert_success

  # Add tests.
  cp ${DIR}/tests/testdata/ ${TESTDIR}/tests/ -r

  # Add Vitest configuration
  cp ${DIR}/vite.config.js ${TESTDIR}/vite.config.js

  # Start vitest UI server in background and capture output
  ddev vitest --ui > vitest_output.log 2>&1 &
  VITEST_PID=$!

  UI_server_health_check
}

@test "vitest-ui can start UI server" {
  set -eu -o pipefail

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  run ddev restart -y
  assert_success

  # Add required node package.
  run ddev npm install -D vitest @vitest/ui
  assert_success

  # Add tests.
  cp ${DIR}/tests/testdata/ ${TESTDIR}/tests/ -r

  # Add Vitest configuration
  cp ${DIR}/vite.config.js ${TESTDIR}/vite.config.js

  # Start vitest UI server in background and capture output
  ddev vitest-ui -s > vitest_output.log 2>&1 &
  VITEST_PID=$!

  UI_server_health_check
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success

  run ddev restart -y
  assert_success

  # Add required node package.
  run ddev npm install -D vitest @vitest/ui
  assert_success

  # Add tests.
  cp ${DIR}/tests/testdata/ ${TESTDIR}/tests/ -r

  health_checks
}

setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-vitest
  mkdir -p $TESTDIR
  export PROJNAME=test-vitest
  export DDEV_NONINTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
}

health_checks() {
  # We check that we haven't broken the main site here.
  ddev exec "curl -s https://localhost:443/"
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev restart
  health_checks
}

@test "vitest helper command" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev restart

  # Add required node package.
  ddev npm install -D vitest

  # Add tests.
  cp ${DIR}/tests/testdata/ ${TESTDIR}/tests/ -r

  # ASSERT it can run tests.
  ddev vitest run | grep "1 passed"
}

@test "vitest hijacks UI server" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev restart

  # Add required node package.
  ddev npm install -D vitest @vitest/ui

  # Add tests.
  cp ${DIR}/tests/testdata/ ${TESTDIR}/tests/ -r

  # Add Vitest configuration
  cp ${DIR}/vite.config.js ${TESTDIR}/vite.config.js

  # Start vitest UI server in background and capture output
  ddev vitest --ui > vitest_output.log 2>&1 &
  VITEST_PID=$!

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

@test "vitest-ui can start UI server" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev restart

  # Add required node package.
  ddev npm install -D vitest @vitest/ui

  # Add tests.
  cp ${DIR}/tests/testdata/ ${TESTDIR}/tests/ -r

  # Add Vitest configuration
  cp ${DIR}/vite.config.js ${TESTDIR}/vite.config.js

  # Confirm command starts server
  ddev vitest-ui -s | grep "UI started at http://0.0.0.0:51204/__vitest__/"
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get tyler36/ddev-vitest with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get tyler36/ddev-vitest
  ddev restart >/dev/null
  health_checks
}

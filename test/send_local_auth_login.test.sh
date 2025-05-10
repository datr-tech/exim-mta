#!/usr/bin/env bash

set -euo pipefail

#
# OPEN DECLARATIONS
#
declare HELPER_PATH
declare ROOT_DIR
declare TEST_DIR

#
# CORE
#
declare CLIENT="client.strachan.email"
declare DELIM=";"
declare HOST="localHOST"
declare -i PORT=25

#
# EXIT CODES
#
declare -i EXIT_CODE_SUCCESS=0
declare -i EXIT_CODE_ERROR_AUTH=1

#
# PASSWORDS
#
declare PASS_VALID="VGl0YW5pYTA5"
declare PASS_INVALID_ONE="${PASS_VALID}1"
declare PASS_INVALID_TWO="abc"
declare PASS_INVALID_THREE=""

#
# USERNAMES
#
declare USERNAME_VALID="am9lYWxkZXJzb25zdHJhY2hhbg=="
declare USERNAME_INVALID_ONE="Tmtub3du"
declare USERNAME_INVALID_TWO="abc"

#
# FIXTURES: [ username, password, exit_code_expected ]
#
declare -a FIXTURES=(
  "${USERNAME_VALID}       ${DELIM} ${PASS_VALID}           ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${USERNAME_VALID}       ${DELIM} ${USERNAME_VALID}       ${DELIM} ${EXIT_CODE_ERROR_AUTH}"
  "${USERNAME_INVALID_ONE} ${DELIM} ${USERNAME_INVALID_ONE} ${DELIM} ${EXIT_CODE_ERROR_AUTH}"
  "${USERNAME_VALID}       ${DELIM} ${PASS_INVALID_ONE}     ${DELIM} ${EXIT_CODE_ERROR_AUTH}"
  "${USERNAME_VALID}       ${DELIM} ${PASS_INVALID_TWO}     ${DELIM} ${EXIT_CODE_ERROR_AUTH}"
  "${USERNAME_INVALID_TWO} ${DELIM} ${PASS_VALID}           ${DELIM} ${EXIT_CODE_ERROR_AUTH}"
  "${USERNAME_INVALID_TWO} ${DELIM} ${PASS_INVALID_THREE}   ${DELIM} ${EXIT_CODE_ERROR_AUTH}"
)

#
# File names and paths
#
declare helper_name="helper.send_local_auth_login.exp"

#
# Setup
#
function set_up_before_script() {
  ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."
  TEST_DIR="${ROOT_DIR}/test"
  HELPER_PATH="${TEST_DIR}/${helper_name}"
}

#
# Test
#
function test_send_local_auth_login() {
  declare fixture
  declare -a fixture_array
  declare username
  declare password
  declare exit_code_expected
  declare exit_code_found

  for fixture in "${FIXTURES[@]}"; do
    #
    # ARRANGE 1
    #
    # Split fixture into fixture_array
    #
    IFS="${DELIM}" read -r -a fixture_array <<< "${fixture}"

    #
    # ARRANGE 2
    #
    # Extract per fixture properties from the array
    #
    username="${fixture_array[0]}"
    password="${fixture_array[1]}"
    exit_code_expected="${fixture_array[2]}"

    #
    # ARRANGE 3
    #
    # Trim the values of the per fixture properties
    # The definition of 'bootstrap__trim' can be found in ./bootstrap.sh
    #
    username="$(bootstrap__trim "${username}")"
    password="$(bootstrap__trim "${password}")"
    exit_code_expected="$(bootstrap__trim "${exit_code_expected}")"

    #
    # ACT
    #
    # Pass the username and the password to the 'expect' based helper,
    # which performs (or attempts to perform) an SMTP
    # handshake with SASL, using AUTH LOGIN.
    #
    ./"${HELPER_PATH}" "${username}" "${password}" "${CLIENT}" "${HOST}" "${PORT}"
    exit_code_found=$?

    #
    # ASSERT
    #
    assert_same "${exit_code_expected}" "${exit_code_found}"

    exit_code_expected=""
    exit_code_found=""
    fixture_array=()
    password=""
    username=""
  done
}

#!/usr/bin/env bash

set -euo pipefail

#
# OPEN DECLARATIONS
#
declare HELPER_PATH
declare ROOT_DIR
declare TEST_DIR

#
# Common vars (to be passed to helper.send_local_auth_plain.exp)
#
declare client="client.strachan.email"
declare host="localhost"
declare port=25

#
# Fixtures: [ mock_user_input, exit_code_expected ]
#
declare -a fixtures=(
  "AGpvZWFsZGVyc29uc3RyYWNoYW4AVGl0YW5pYTA5, 0"
  "AGpvZWFsZGVyc29uc3RyYWNoYW4AVGl0YW5pYTA5==, 1"
  "abc, 1"
  "'', 1"
)

#
# File names and paths
#
declare helper_name="helper.send_local_auth_plain.exp"

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
function test_sasl_auth_plain() {
  declare fixture
  declare -a fixture_array
  declare mock_user_input
  declare exit_code_expected
  declare exit_code_found

  for fixture in "${fixtures[@]}"; do
    #
    # Arrange
    #
    IFS=', ' read -r -a fixture_array <<< "${fixture}"
    mock_user_input="${fixture_array[0]}"
    exit_code_expected="${fixture_array[1]}"

    #
    # Act
    #
    # Pass mock_user_input to the 'expect' based helper,
    # which performs (or attempts to perform) an SMTP
    # handshake with SASL, using AUTH PLAIN.
    #
    ./"${HELPER_PATH}" "${mock_user_input}" "${client}" "${host}" "${port}"
    exit_code_found=$?

    #
    # Assert
    #
    assert_same "${exit_code_expected}" "${exit_code_found}"
    exit_code_expected=""
    exit_code_found=""
    mock_user_input=""
  done
}

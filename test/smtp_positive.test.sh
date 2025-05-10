#!/usr/bin/env bash

set -euo pipefail

######################################################################
#                                                                    #
# 1. VARS                                                            #
#                                                                    #
######################################################################

#
# CORE
#
declare DELIM=";"
declare DOMAIN="strachan.email"""
declare MBOX_DIR="/var/mail"
declare TEST_NAME="smtp_positive"

#
# EXIT CODES
#
declare -i EXIT_CODE_SUCCESS=0

#
# HOST AND PORTS
#
declare HOST_LOCAL="localhost"
declare -i PORT_SMTP=25

#
# USER VARS
#
declare RCPT_ADDR_LOCAL="joe@${HOST_LOCAL}"
declare RCPT_ADDR_DOMAIN="joe@${DOMAIN}"
declare RCPT_USER="joealdersonstrachan"
declare SNDR_LOCAL="admin@${HOST_LOCAL}"
declare SNDR_RMT="unknown@unknown.com"

######################################################################
#                                                                    #
# 2. FIXTURES                                                        #
#                                                                    #
######################################################################

#
# [ rcpt; rcpt_username; sender; port; exit_code_expected ]
#
declare -a FIXTURES=(
  #
  # SMTP should be successful with PORT 25
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # SMTP should be successful with PORT 25 and a remote sender
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
)

######################################################################
#                                                                    #
# 3. TEST                                                            #
#                                                                    #
######################################################################

function test_smtp_positive() {
  #
  # Exit code vars
  #
  declare exit_code_expected
  declare exit_code_found

  #
  # Fixture vars
  #
  declare fixture
  declare -a fixture_array
  declare -i i

  #
  # Port
  #
  declare port

  #
  # Message and mailbox var
  #
  declare mailbox_contents_found
  declare message_data
  declare message_subject

  #
  # User vars
  #
  declare rcpt
  declare rcpt_mailbox_path
  declare rcpt_username
  declare sender

  #
  # Iterate over FIXTURES,
  # performing a test per fixture
  #
  for i in "${!FIXTURES[@]}"; do
    #
    # ARRANGE 1
    #
    # Extract the ith fixture from FIXTURES and split it into fixture_array
    #
    fixture="${FIXTURES["${i}"]}"
    IFS="${DELIM}" read -r -a fixture_array <<< "${fixture}"

    #
    # ARRANGE 2
    #
    # Extract per fixture properties from the array
    #
    rcpt="${fixture_array[0]}"
    rcpt_username="${fixture_array[1]}"
    sender="${fixture_array[2]}"
    port="${fixture_array[3]}"
    exit_code_expected="${fixture_array[4]}"

    #
    # ARRANGE 3
    #
    # Trim the values of the per fixture properties
    # The definition of 'trim' can be found in ./bootstrap.sh
    #
    rcpt="$(trim "${rcpt}")"
    rcpt_username="$(trim "${rcpt_username}")"
    sender="$(trim "${sender}")"
    port="$(trim "${port}")"
    exit_code_expected="$(trim "${exit_code_expected}")"

    #
    # ARRANGE 4
    #
    message_subject="${TEST_NAME}_${i}_${port}"
    message_data="TO: ${rcpt}\nFROM: ${sender}\nSUBJECT: ${message_subject}\nDATA: ${message_subject}\n."

    #
    # ARRANGE 5
    #
    rcpt_mailbox_path="${MBOX_DIR}/${rcpt_username}"

    echo "${rcpt_mailbox_path}"

    if [ -f "${rcpt_mailbox_path}" ]; then
      rm -f "${rcpt_mailbox_path}"
    fi

    #
    # ACT
    #
    swaks \
      --to "${rcpt}" \
      --from "${sender}" \
      --server "${HOST_LOCAL}" \
      --port "${port}" \
      --data "${message_data}" \
      > /dev/null 2>&1

    exit_code_found=$?
    sleep 0.5
    mailbox_contents_found=$(cat "${rcpt_mailbox_path}" 2> /dev/null)

    #
    # ASSERT
    #
    assert_same "${exit_code_expected}" "${exit_code_found}"
    assert_not_empty "${mailbox_contents_found}"
    assert_not_empty "${message_subject}"
    assert_contains "${message_subject}" "${mailbox_contents_found}"

    #
    # TEARDOWN PER FIXTURE
    #
    exit_code_expected=""
    exit_code_found=""
    message_data=""
    message_subject=""
    port=""
    rcpt=""
    rcpt_mailbox_path=""
    rcpt_username=""
    sender=""
  done
}

#!/usr/bin/env bash

set -euo pipefail

######################################################################
#                                                                    #
# 1. VARS                                                            #
#                                                                    #
######################################################################

#
# OPEN DECLARATIONS
#

declare    CERT_DIR
declare    ROOT_DIR

#
# CORE
#
declare    DELIM=";"
declare    MAILBOX_DIR="/var/mail"
declare    TEST_NAME="tls_on_connect_positive"
declare -i TIMEOUT=10

#
# EXIT CODES
#
declare -i EXIT_CODE_SUCCESS=0

#
# HOST AND PORTS
#
declare    HOST_LOCAL="localhost"
declare -i PORT_TLSC=465

#
# TLS VERSIONS
#
declare    TLS_VER_1_2="tlsv1_2"
declare    TLS_VER_1_3="tlsv1_3"

#
# USER VARS
#
declare    RCPT_ADDRESS_LOCALHOST="joe@${HOST_LOCAL}"
declare    RCPT_ADDRESS_DOMAIN="joe@strachan.email"
declare    RCPT_USERNAME="joealdersonstrachan"
declare    SENDER_LOCALHOST="admin@${HOST_LOCAL}"
declare    SENDER_REMOTE="unknown@unknown.com"

######################################################################
#                                                                    #
# 2. FIXTURES                                                        #
#                                                                    #
######################################################################

#
# [ rcpt; rcpt_user; sndr; tls_version; port; exit_code_expected ]
#
declare -a FIXTURES=(
  #
  # 'On connect' (submissions) should be successful with PORT 465 and TLS v1.2
  #
  "${RCPT_ADDRESS_LOCALHOST} ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_LOCALHOST} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDRESS_DOMAIN}    ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_LOCALHOST} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # 'On connect' (submissions) should be successful with PORT 465, TLS v1.2 and a remote sndr
  #
  "${RCPT_ADDRESS_LOCALHOST} ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_REMOTE}    ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDRESS_LOCALHOST} ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_REMOTE}    ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # 'On connect' (submissions) should be successful with PORT 465 and TLS v1.3
  #
  "${RCPT_ADDRESS_LOCALHOST} ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_LOCALHOST} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDRESS_LOCALHOST} ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_LOCALHOST} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # 'On connect' (submissions) should be successful with PORT 465, TLS v1.3 and a remote sndr
  #
  "${RCPT_ADDRESS_LOCALHOST} ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_REMOTE}    ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDRESS_LOCALHOST} ${DELIM} ${RCPT_USERNAME} ${DELIM} ${SENDER_REMOTE}    ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_SUCCESS}"
)

######################################################################
#                                                                    #
# 3. SET UP                                                          #
#                                                                    #
######################################################################

function set_up_before_script() {
  ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."
  CERT_DIR="${ROOT_DIR}/ca/intermediate"
}

######################################################################
#                                                                    #
# 4. TEST                                                            #
#                                                                    #
######################################################################

function test_tls_on_connect_positive() {
  #
  # Exit code vars
  #
  declare exit_code_expected
  declare exit_code_found

  #
  # Fixture vars
  #
  declare    fixture
  declare -a fixture_array
  declare -i i

  #
  # Port and TLS version
  #
  declare port
  declare tls_version

  #
  # Message vars
  #
  declare msg_data
  declare msg_subject

  #
  # User vars
  #
  declare rcpt
  declare rcpt_mbox_contents
  declare rcpt_mbox_path
  declare rcpt_user
  declare sndr

  #
  # Iterate over FIXTURES,
  # performing a test per fixture
  #
  for i in "${!FIXTURES[@]}"
  do
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
    rcpt_user="${fixture_array[1]}"
    sndr="${fixture_array[2]}"
    tls_version="${fixture_array[3]}"
    port="${fixture_array[4]}"
    exit_code_expected="${fixture_array[5]}"

    #
    # ARRANGE 3
    #
    # Trim the values of the per fixture properties
    # The definition of 'trim' can be found in ./bootstrap.sh
    #
    rcpt="$(trim "${rcpt}")"
    rcpt_user="$(trim "${rcpt_user}")"
    sndr="$(trim "${sndr}")"
    tls_version="$(trim "${tls_version}")"
    port="$(trim "${port}")"
    exit_code_expected="$(trim "${exit_code_expected}")"

    #
    # ARRANGE 4
    #
    msg_subject="${TEST_NAME}_${i}_${tls_version}_${port}"
    msg_data="TO: ${rcpt}\nFROM: ${sndr}\nSUBJECT: ${msg_subject}\nDATA: ${msg_subject}\n."

    #
    # ARRANGE 5
    #
    rcpt_mbox_path="${MAILBOX_DIR}/${rcpt_user}"

    if [ -f "${rcpt_mbox_path}" ]; then
      rm -f "${rcpt_mbox_path}"
    fi

    #
    # ACT
    #
    swaks                                                           \
      --to              "${rcpt}"                                   \
      --from            "${sndr}"                                   \
      --server          "${HOST_LOCAL}"                             \
      --port            "${port}"                                   \
      --data            "${msg_data}"                               \
      --timeout         "${TIMEOUT}"                                \
      --tls-cert        "${CERT_DIR}/certs/exim.crt"                \
      --tls-key         "${CERT_DIR}/private/exim.key"              \
      --tls-protocol    "${tls_version}"                            \
      --tls-on-connect                                              \
      > /dev/null 2>&1

    exit_code_found=$?
    sleep 1
    rcpt_mbox_contents=$(cat "${rcpt_mbox_path}" 2> /dev/null)

    #
    # ASSERT
    #
    assert_same       "${exit_code_expected}" "${exit_code_found}"
    assert_contains   "${msg_subject}"        "${rcpt_mbox_contents}"
    assert_not_empty  "${rcpt_mbox_contents}"
    assert_not_empty  "${msg_subject}"

    #
    # TEARDOWN PER FIXTURE
    #
    exit_code_expected=""
    exit_code_found=""
    fixture=""
    fixture_array=()
    msg_data=""
    msg_subject=""
    port=""
    rcpt=""
    rcpt_mbox_contents=""
    rcpt_mbox_path=""
    rcpt_user=""
    sndr=""
    tls_version=""
  done
}

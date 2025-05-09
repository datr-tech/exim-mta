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
declare    MBOX_DIR="/var/mail"
declare    MBOX_MGMT_PATH="${MBOX_DIR}/mail"
declare    TEST_NAME="tls_starttls_negative"
declare -i TIMEOUT=2

#
# EXIT CODES
#
declare -i EXIT_CODE_ERROR_INITIAL_READ=21
declare -i EXIT_CODE_ERROR_TLS=29
#
# HOST AND PORTS
#
declare    HOST_LOCAL="localhost"
declare -i PORT_SMTP=25
declare -i PORT_TLSC=465

#
# TLS VERSIONS
#
declare    TLS_VER_1_1="tlsv1_1"
declare    TLS_VER_1_2="tlsv1_2"
declare    TLS_VER_1_3="tlsv1_3"

#
# USER VARS
#
declare    RCPT_ADDR_LOCAL="joe@${HOST_LOCAL}"
declare    RCPT_ADDR_DOMAIN="joe@strachan.email"
declare    RCPT_USER="joealdersonstrachan"
declare    SNDR_LOCAL="admin@${HOST_LOCAL}"
declare    SNDR_RMT="unknown@unknown.com"

######################################################################
#                                                                    #
# 2. FIXTURES                                                        #
#                                                                    #
######################################################################

#
# [ rcpt; rcpt_user; sndr; tls_version; port; expected_exit_code ]
#
declare -a FIXTURES=(
  #
  # STARTTLS should not be successful with PORT_SMTP (25) and TLS v1.1
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_ERROR_TLS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_ERROR_TLS}"

  #
  # STARTTLS should not be successful with PORT_SMTP (25), TLS v1.1 and a remote user
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_ERROR_TLS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_ERROR_TLS}"

  #
  # STARTTLS should not be successful with PORT_TLSC (465) and TLS v1.1
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"

  #
  # STARTTLS should not be successful with PORT_TLSC (465), TLS v1.1 and a remote user
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"

  #
  # STARTTLS should not be successful with PORT_TLSC (465) and TLS v1.2
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"

  #
  # STARTTLS should not be successful with PORT_TLSC (465), TLS v1.2 and a remote user
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"

  #
  # STARTTLS should not be successful with PORT_TLSC (465) and TLS v1.3
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"

  #
  # STARTTLS should not be successful with PORT_TLSC (465), TLS v1.3 and a remote user
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLSC} ${DELIM} ${EXIT_CODE_ERROR_INITIAL_READ}"
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

function test_tls_starttls_negative() {
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
  # Message and mailbox var
  #
  declare msg_data
  declare msg_subject
  declare mgmt_mbox_contents_found

  #
  # User vars
  #
  declare rcpt
  declare rcpt_mbox_contents_found
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
    rcpt_mbox_path="${MBOX_DIR}/${rcpt_user}"

    if [ -f "${rcpt_mbox_path}" ]; then
      rm -f "${rcpt_mbox_path}"
    fi

    if [ -f "${MBOX_MGMT_PATH}" ]; then
      rm -f "${MBOX_MGMT_PATH}"
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
      --tls-cert        "${CERT_DIR}/certs/user.cert.pem"           \
      --tls-key         "${CERT_DIR}/private/user.key.pem"          \
      --tls-protocol    "${tls_version}"                            \
      -tls                                                          \
      > /dev/null 2>&1

    exit_code_found=$?
    sleep 0.5
    mgmt_mbox_contents_found=$(cat "${MBOX_MGMT_PATH}" 2>/dev/null)
    rcpt_mbox_contents_found=$(cat "${rcpt_mbox_path}" 2>/dev/null)

    #
    # ASSERT
    #
    assert_same  "${exit_code_expected}" "${exit_code_found}"
    assert_empty "${mgmt_mbox_contents_found}"
    assert_empty "${rcpt_mbox_contents_found}"

    #
    # TEARDOWN PER FIXTURE
    #
    exit_code_expected=""
    exit_code_found=""
    msg_data=""
    msg_subject=""
    port=""
    rcpt=""
    rcpt_mbox_path=""
    rcpt_user=""
    sndr=""
    tls_version=""
  done
}

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
declare    DOMAIN="strachan.email"""
declare    MBOX_DIR="/var/mail"
declare    TEST_NAME="tls_starttls_positive"

#
# EXIT CODES
#
declare -i EXIT_CODE_SUCCESS=0

#
# HOST AND PORTS
#
declare    HOST_LOCAL="localhost"
declare -i PORT_SMTP=25
declare -i PORT_TLS=587

#
# TLS VERSIONS
#
declare    TLS_VER_1_2="tlsv1_2"
declare    TLS_VER_1_3="tlsv1_3"

#
# USER VARS
#
declare    RCPT_ADDR_LOCAL="joe@${HOST_LOCAL}"
declare    RCPT_ADDR_DOMAIN="joe@${DOMAIN}"
declare    RCPT_USER="joealdersonstrachan"
declare    SNDR_LOCAL="admin@${HOST_LOCAL}"
declare    SNDR_RMT="unknown@unknown.com"

######################################################################
#                                                                    #
# 2. FIXTURES                                                        #
#                                                                    #
######################################################################

#
# [ rcpt; rcpt_username; sender; tls_version; port; exit_code_expected ]
#
declare -a FIXTURES=(
  #
  # STARTTLS should be successful with PORT 25 and TLS v1.2
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 25, TLS v1.2 and a remote sender
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 25 and TLS v1.3
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 25, TLS v1.3 and a remote sender
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587 and TLS v1.2
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587, TLS v1.2 and a remote sender
  #
  #"${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  #"${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587 and TLS v1.3
  #
  #"${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  #"${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587, TLS v1.3 and a remote sender
  #
  #"${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  #"${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
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

function test_tls_starttls_positive() {
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
    rcpt_username="${fixture_array[1]}"
    sender="${fixture_array[2]}"
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
    rcpt_username="$(trim "${rcpt_username}")"
    sender="$(trim "${sender}")"
    tls_version="$(trim "${tls_version}")"
    port="$(trim "${port}")"
    exit_code_expected="$(trim "${exit_code_expected}")"

    #
    # ARRANGE 4
    #
    message_subject="${TEST_NAME}_${i}_${tls_version}_${port}"
    message_data="TO: ${rcpt}\nFROM: ${sender}\nSUBJECT: ${message_subject}\nDATA: ${message_subject}\n."

    #
    # ARRANGE 5
    #
    rcpt_mailbox_path="${MBOX_DIR}/${rcpt_username}"

    if [ -f "${rcpt_mailbox_path}" ]; then
      rm -f "${rcpt_mailbox_path}"
    fi

    #
    # ACT
    #
    swaks                                                           \
      --to              "${rcpt}"                                   \
      --from            "${sender}"                                 \
      --server          "${HOST_LOCAL}"                             \
      --port            "${port}"                                   \
      --data            "${message_data}"                           \
      --tls-cert        "${CERT_DIR}/certs/user.cert.pem"           \
      --tls-key         "${CERT_DIR}/private/user.key.pem"          \
      --tls-protocol    "${tls_version}"                            \
      -tls                                                          \
      > /dev/null 2>&1

    exit_code_found=$?
    sleep 1
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
    tls_version=""
    sleep 1
  done
}

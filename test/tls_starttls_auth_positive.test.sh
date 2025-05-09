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
declare    TEST_NAME="tls_starttls_auth_positive"

#
# AUTH TYPES
#
declare    AUTH_TYPE_LOGIN="LOGIN"
declare    AUTH_TYPE_PLAIN="PLAIN"

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
declare    RCPT_USER="admin"
declare    RCPT_ADDR_LOCAL="${RCPT_USER}@${HOST_LOCAL}"
declare    RCPT_ADDR_DOMAIN="${RCPT_USER}@${DOMAIN}"

declare    SNDR_LOCAL="joe@${HOST_LOCAL}"
declare    SNDR_PASS="Titania09"
declare    SNDR_USER="joealdersonstrachan"

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
  # STARTTLS should be successful with PORT 25, TLS v1.2 and AUTH LOGIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 25, TLS v1.3 and AUTH LOGIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 25, TLS v1.2 and AUTH PLAIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 25, TLS v1.3 and AUTH PLAIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_SMTP} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587, TLS v1.2 and AUTH LOGIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587, TLS v1.3 and AUTH LOGIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_LOGIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587, TLS v1.2 and AUTH PLAIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"

  #
  # STARTTLS should be successful with PORT 587, TLS v1.3 and AUTH PLAIN
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${AUTH_TYPE_PLAIN} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} ${EXIT_CODE_SUCCESS}"

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

function test_tls_starttls_auth_positive() {
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
  # Auth, port and TLS version
  #
  declare auth_type
  declare port
  declare tls_version

  #
  # Message and mailbox var
  #
  declare msg_data
  declare msg_subject

  #
  # User vars
  #
  declare rcpt
  declare rcpt_mbox_contents_found
  declare rcpt_mailbox_path
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
    auth_type="${fixture_array[3]}"
    tls_version="${fixture_array[4]}"
    port="${fixture_array[5]}"
    exit_code_expected="${fixture_array[6]}"

    #
    # ARRANGE 3
    #
    # Trim the values of the per fixture properties
    # The definition of 'trim' can be found in ./bootstrap.sh
    #
    rcpt="$(trim "${rcpt}")"
    rcpt_user="$(trim "${rcpt_user}")"
    sndr="$(trim "${sndr}")"
    auth_type="$(trim "${auth_type}")"
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
    rcpt_mailbox_path="${MBOX_DIR}/${rcpt_user}"

    if [ -f "${rcpt_mailbox_path}" ]; then
      rm -f "${rcpt_mailbox_path}"
    fi

    #
    # ACT
    #
    swaks                                                           \
      --to              "${rcpt}"                                   \
      --from            "${sndr}"                                   \
      --auth            "${auth_type}"                              \
      --auth-user       "${SNDR_USER}"                              \
      --auth-pass       "${SNDR_PASS}"                              \
      --server          "${HOST_LOCAL}"                             \
      --port            "${port}"                                   \
      --data            "${msg_data}"                               \
      --tls-cert        "${CERT_DIR}/certs/user.cert.pem"           \
      --tls-key         "${CERT_DIR}/private/user.key.pem"          \
      --tls-protocol    "${tls_version}"                            \
      -tls                                                          \
      > /dev/null 2>&1

    exit_code_found=$?
    sleep 0.5
    rcpt_mbox_contents_found=$(cat "${rcpt_mailbox_path}" 2> /dev/null)

    #
    # ASSERT
    #
    assert_same      "${exit_code_expected}" "${exit_code_found}"
    assert_not_empty "${rcpt_mbox_contents_found}"
    assert_not_empty "${msg_subject}"
    assert_contains  "${msg_subject}" "${rcpt_mbox_contents_found}"

    #
    # TEARDOWN PER FIXTURE
    #
    auth_type=""
    exit_code_expected=""
    exit_code_found=""
    msg_data=""
    msg_subject=""
    port=""
    rcpt=""
    rcpt_mailbox_path=""
    rcpt_user=""
    sndr=""
    tls_version=""
  done
}

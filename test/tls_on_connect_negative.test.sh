#!/usr/bin/env bash

set -euo pipefail

######################################################################
#                                                                    #
# 1. VARS                                                            #
#                                                                    #
######################################################################

#
# COMMON VARS
#

declare CERT_DIR
declare DELIM=";"
declare MAILBOX_DIR="/var/mail"
declare ROOT_DIR
declare SECURITY_MBOX_PATH="${MAILBOX_DIR}/mail"
declare TEST_NAME="tls_on_connect_negative"
declare TIMEOUT=2

#
# HOST AND PORT VARS
#
declare    HOST_LOCAL="localhost"
declare -i PORT_TLS=587
declare -i PORT_TLSC=465


#
# TLS VER VARS
#
declare TLS_VER_1_1="tlsv1_1"
declare TLS_VER_1_2="tlsv1_2"
declare TLS_VER_1_3="tlsv1_3"

#
# USER VARS
#
declare RCPT_ADDR_LOCAL="joe@${HOST_LOCAL}"
declare RCPT_ADDR_DOMAIN="joe@strachan.email"
declare RCPT_USER="joealdersonstrachan"
declare SNDR_LOCAL="admin@${HOST_LOCAL}"
declare SNDR_RMT="unknown@unknown.com"

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
  # 'On connect' (submissions) should be unsuccessful with PORT_TLSC (465) and TLS v1.1
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} 29"

  #
  # 'On connect' (submissions) should be unsuccessful with PORT_TLSC (465), TLS v1.1 and a remote sender
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLSC} ${DELIM} 29"

  #
  # 'On connect' (submissions) should be unsuccessful with PORT_TLS (587) and TLS v1.1
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLS} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLS} ${DELIM} 29"

  #
  # 'On connect' (submissions) should be unsuccessful with PORT_TLS (587), TLS v1.1 and a remote sender
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLS} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_1} ${DELIM} ${PORT_TLS} ${DELIM} 29"

  #
  # 'On connect' (submissions) should be unsuccessful with PORT_TLS (587) and TLS v1.2
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} 29"

  #
  # 'On connect' (submissions) should be unsuccessful with PORT_TLS (587), TLS v1.2 and a remote sender
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_2} ${DELIM} ${PORT_TLS} ${DELIM} 29"

  #
  # 'On connect' (submissions) should be unsuccessful with PORT_TLS (587) and TLS v1.3
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_LOCAL} ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} 29"

  #
  # 'On connect' (submissions) should be unsuccessful with PORT_TLS (587), TLS v1.3 and a remote sender
  #
  "${RCPT_ADDR_LOCAL}  ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} 29"
  "${RCPT_ADDR_DOMAIN} ${DELIM} ${RCPT_USER} ${DELIM} ${SNDR_RMT}   ${DELIM} ${TLS_VER_1_3} ${DELIM} ${PORT_TLS} ${DELIM} 29"
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

function test_tls_on_connect_negative() {
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

  #
  # User vars
  #

  declare rcpt
  declare rcpt_mbox_path
  declare rcpt_mbox_contents_found
  declare rcpt_user
  declare security_mbox_contents_found
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

    if [ -f "${SECURITY_MBOX_PATH}" ]; then
      rm -f "${SECURITY_MBOX_PATH}"
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
      --tls-on-connect                                              \
      > /dev/null 2>&1

    exit_code_found=$?
    sleep 0.5
    rcpt_mbox_contents_found=$(cat "${rcpt_mbox_path}" 2>/dev/null)
    security_mbox_contents_found=$(cat "${SECURITY_MBOX_PATH}" 2>/dev/null)

    #
    # ASSERT
    #
    assert_same "${exit_code_expected}" "${exit_code_found}"
    assert_empty "${rcpt_mbox_contents_found}"
    assert_empty "${security_mbox_contents_found}"

    #
    # TEARDOWN PER FIXTURE
    #
    exit_code_expected=""
    exit_code_found=""
    msg_data=""
    msg_subject=""
    port=""
    rcpt=""
    rcpt_mbox_contents_found=""
    rcpt_mbox_path=""
    rcpt_user=""
    security_mbox_contents_found=""
    sndr=""
    tls_version=""
  done
}

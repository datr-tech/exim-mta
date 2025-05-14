#!/usr/bin/env bash

set -euo pipefail

#####################################################################
#                                                                   #
# Script:  send_local_imap_retrieval_positive.test.sh               #
#                                                                   #
# Purpose: A test that generates and sends emails, locally,         #
#          via EXIM, and then attempts to retrieve the messages     #
#          using IMAP.                                              #
#                                                                   #
# Date:    20th February 2025                                       #
#                                                                   #
# Author:  admin <admin@datr.tech>                                  #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
# CORE SECTIONS (within the code below)                             #
#                                                                   #
#                                                                   #
# 1 TEST DEFINITION                                                 #
#                                                                   #
# 1.1  DATA PROVIDER ARGS                                           #
# 1.2  CONSTANTS                                                    #
# 1.3  WORKING VARS                                                 #
# 1.4  REMOVE EXISTING EMAILS PER RECIPIENT                         #
# 1.5  GENERATE MSG                                                 #
# 1.6  SEND MSG                                                     #
# 1.7  USE THE IMAP HELPER TO RETRIEVE THE SENT MESSAGE             #
# 1.8  ASSERT THAT THE RETRIEVED SUBJECT MATCHES                    #
# 1.9  ASSERT THAT THE EXIT CODES MATCHES                           #
#                                                                   #
#                                                                   #
# 2 TEST FIXTURE DEFINITIONS                                        #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
# 1 TEST DEFINITION (with the data_provider reference below)        #
#                                                                   #
#####################################################################

# data_provider test_send_local_imap_retrieval_positive_fixtures
function test_send_local_imap_retrieval_positive() {

  ###################################################################
  #                                                                 #
  # 1.1 DATA PROVIDER ARGS                                          #
  #                                                                 #
  ###################################################################

  local -i -r fixture_id="$(($1))"
  local -r recipient_email=$2
  local -r recipient_user=$3
  local -r sender_email=$4
  local -r sender_user=$5
  local -r sender_pass=$6
  local -r host=$7
  local -i -r port="$(($8))"
  # local -i -r exit_code_exim_expected="$(("${9}"))"
  # local -i -r exit_code_imap_expected="$(("${10}"))"

  ###################################################################
  #                                                                 #
  # 1.2 CONSTANTS                                                   #
  #                                                                 #
  ###################################################################

  local -r root_dir="$(bootstrap__get_root_dir)"
  local -r imap_helper_cmd="${root_dir}/test/helper.imap_email_retrieval.exp"
  local -r test_name="test_send_local_imap_retrieval_positive"
  # local -i -t timeout=2

  ###################################################################
  #                                                                 #
  # 1.3 WORKING VARS                                                #
  #                                                                 #
  ###################################################################

  local -i exit_code_exim_found=1
  local -i exit_code_imap_found=1
  local message_data=""
  local message_envelope=""
  local message_subject=""
  local imap_retrieved_message=""

  ###################################################################
  #                                                                 #
  # 1.4 REMOVE EXISTING EMAILS PER RECIPIENT                        #
  #                                                                 #
  ###################################################################

  # bootstrap__rm_maildir_emails "${recipient_user}"

  ###################################################################
  #                                                                 #
  # 1.5 GENERATE MSG                                                #
  #                                                                 #
  ###################################################################

  message_subject=$(
    bootstrap__generate_message_subject \
      "${test_name}" \
      "${recipient_email}" \
      "${sender_email}" \
      "${fixture_id}"
  )

  message_data=$(
    bootstrap__generate_message_data \
      "${recipient_email}" \
      "${sender_email}" \
      "${message_subject}"
  )

  message_envelope=$(
    bootstrap__generate_message_envelope \
      "${recipient_email}" \
      "${recipient_user}" \
      "${sender_email}" \
      "${sender_user}" \
      "${message_data}" \
      "${message_subject}"
  )

  ###################################################################
  #                                                                 #
  # 1.6 SEND MSG                                                    #
  #                                                                 #
  ###################################################################

  echo -e "${message_envelope}" | exim4 -t
  exit_code_exim_found=$?

  sleep 0.5

  ###################################################################
  #                                                                 #
  # 1.7 USE THE IMAP HELPER TO RETRIEVE THE SENT MESSAGE            #
  #                                                                 #
  ###################################################################

  imap_retrieved_message="$("${imap_helper_cmd}" "${sender_user}" "${sender_pass}" "${host}" "${port}" "${message_subject}")"
  exit_code_imap_found=$?

  ###################################################################
  #                                                                 #
  # 1.8 ASSERT THAT THE RETRIEVED SUBJECT MATCHES                   #
  #                                                                 #
  ###################################################################

  subject_found="$(echo "${imap_retrieved_message}" | grep -c "${message_subject}")"

  assert_true "${subject_found}"
  assert_not_empty "${imap_retrieved_message}"
  assert_not_empty "${message_subject}"
  assert_contains "${message_subject}" "${imap_retrieved_message}"

  ###################################################################
  #                                                                 #
  # 1.9 ASSERT THAT THE EXIT CODES MATCHES                          #
  #                                                                 #
  ###################################################################

  assert_not_empty "${exit_code_exim_found}"
  assert_not_empty "${exit_code_imap_found}"
  assert_equals "${exit_code_exim_found}" "${exit_code_imap_found}"
}

#####################################################################
#                                                                   #
# 2 TEST FIXTURE DEFINITIONS                                        #
#                                                                   #
#####################################################################

function test_send_local_imap_retrieval_positive_fixtures() {

  #
  # [
  #   fixture_id              ,
  #   recipient_email         ,
  #   recipient_user          ,
  #   sender_email            ,
  #   sender_user             ,
  #   sender_pass             ,
  #   imap_host               ,
  #   imap_port               ,
  #   exit_code_exim_expected ,
  #   exit_code_imap_expected
  # ]
  #

  #
  # Forward an email both from and to BOOTSTRAP_USER_TEST (via EXIM),
  # and then retrieve the forwarded message via IMAP.
  #
  echo 0 \
    "${BOOTSTRAP_EMAIL_TEST_LOCAL}" \
    "${BOOTSTRAP_USER_TEST}" \
    "${BOOTSTRAP_EMAIL_TEST_DOMAIN}" \
    "${BOOTSTRAP_USER_TEST}" \
    "${BOOTSTRAP_USER_TEST_PASS}" \
    "${BOOTSTRAP_DOMAIN_LOCAL}" \
    "${BOOTSTRAP_IMAP_UNSECURE_PORT}" \
    0 \
    0
}

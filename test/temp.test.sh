#!/usr/bin/env bash

set -euo pipefail

function test_simple_insecure() {

  ###################################################################
  #                                                                 #
  # 1.1 DATA PROVIDER ARGS                                          #
  #                                                                 #
  ###################################################################

  local -i -r fixture_id=1
  local -r recipient_email=${BOOTSTRAP_EMAIL_ADMIN_LOCAL}
  local -r recipient_user=${BOOTSTRAP_USER_ADMIN}
  local -r sender_email=${BOOTSTRAP_EMAIL_REMOTE}
  local -i -r port="${BOOTSTRAP_EXIM_UNSECURE_PORT}"
  local -r -r exit_code_expected=0
  local -r test_name="test_simple_insecure"

  ###################################################################
  #                                                                 #
  # 1.2 CONSTANTS                                                   #
  #                                                                 #
  ###################################################################

  local -i -r timeout=10

  ###################################################################
  #                                                                 #
  # 1.3 WORKING VARS                                                #
  #                                                                 #
  ###################################################################

  local email_contents=""
  local email_path=""
  local -i exit_code_found=1
  local message_data=""
  local message_subject=""

  ###################################################################
  #                                                                 #
  # 1.4 REMOVE EXISTING EMAILS PER RECIPIENT                        #
  #                                                                 #
  ###################################################################

  #bootstrap__rm_maildir_emails "${recipient_user}"

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

  ###################################################################
  #                                                                 #
  # 1.6 SEND MSG                                                    #
  #                                                                 #
  ###################################################################

  swaks \
    --to "${recipient_email}" \
    --from "${sender_email}" \
    --server "${BOOTSTRAP_DOMAIN_LOCAL}" \
    --port "${port}" \
    --data "${message_data}" \
    --timeout "${timeout}"

  ###################################################################
  #                                                                 #
  # 1.7 GET THE EXIT CODE AND THE CONTENTS OF THE DELIVERED MSG     #
  #                                                                 #
  ###################################################################

  exit_code_found=$?
  sleep 0.3

  #email_contents="$(
  #	bootstrap__get_maildir_latest_email \
  #		"${recipient_user}"
  #)"

  #email_path="$(
  #	bootstrap__get_maildir_latest_email_path \
  #		"${recipient_user}"
  #)"

  ###################################################################
  #                                                                 #
  # 1.8 ASSERTIONS                                                  #
  #                                                                 #
  ###################################################################

  #assert_is_file "${email_path}"
  #assert_not_empty "${email_contents}"
  #assert_not_empty "${message_subject}"
  #assert_contains "${message_subject}" "${email_contents}"
  assert_same "${exit_code_expected}" "${exit_code_found}"
}

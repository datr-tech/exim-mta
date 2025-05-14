#!/usr/bin/env bash

set -euo pipefail

function test_sanity_secure_1.2_auth_login_local_to_local() {

  ###################################################################
  #                                                                 #
  # 1.1  Test vars                                                  #
  #                                                                 #
  ###################################################################

  local -r cert_dir="$(bootstrap__get_cert_dir)"
  local -i -r sanity_test_id=1001
  local -r sanity_test_name="test_sanity_secure_1.2_auth_login_local_to_local"

  ###################################################################
  #                                                                 #
  # 1.2  Mail server vars                                           #
  #                                                                 #
  ###################################################################

  local -r mail_server_auth_type="${BOOTSTRAP_AUTH_LOGIN}"
  local -r mail_server_name="${BOOTSTRAP_DOMAIN_LOCAL}"
  local -i -r mail_server_port="${BOOTSTRAP_EXIM_SECURE_PORT}"
  local -r mail_server_tls_version="${BOOTSTRAP_TLS_1_2}"

  ###################################################################
  #                                                                 #
  # 1.3  Email vars                                                 #
  #                                                                 #
  ###################################################################

  local -r email_address_to="${BOOTSTRAP_EMAIL_ADMIN_LOCAL}"
  local -r email_address_from=${BOOTSTRAP_EMAIL_TEST_DOMAIN}
  local -r email_username_from="${BOOTSTRAP_USER_TEST}"
  local -r email_username_from_password="${BOOTSTRAP_USER_TEST_PASS}"
  local -r email_username_to="${BOOTSTRAP_USER_ADMIN}"

  local email_expected_message_data=""
  local email_expected_message_subject=""
  local email_found_contents=""
  local email_found_path=""

  ###################################################################
  #                                                                 #
  # 1.4  Exit codes                                                 #
  #                                                                 #
  ###################################################################

  local -i -r exit_code_expected=0
  local -i exit_code_found=1

  ###################################################################
  #                                                                 #
  # 1.5  Remove any existing emails for 'email_username_to'         #
  #                                                                 #
  ###################################################################

  bootstrap__rm_maildir_emails "${email_username_to}"

  ###################################################################
  #                                                                 #
  # 1.6  Generate email message                                     #
  #                                                                 #
  ###################################################################

  email_expected_message_subject=$(
    bootstrap__generate_message_subject \
      "${sanity_test_name}" \
      "${email_address_to}" \
      "${email_address_from}" \
      "${sanity_test_id}"
  )

  email_expected_message_data=$(
    bootstrap__generate_message_data \
      "${email_address_to}" \
      "${email_address_from}" \
      "${email_expected_message_subject}"
  )

  ###################################################################
  #                                                                 #
  # 1.7  Send email                                                 #
  #                                                                 #
  ###################################################################

  swaks \
    --auth "${mail_server_auth_type}" \
    --auth-user "${email_username_from}" \
    --auth-pass "${email_username_from_password}" \
    --to "${email_address_to}" \
    --from "${email_address_from}" \
    --server "${mail_server_name}" \
    --port "${mail_server_port}" \
    --data "${email_expected_message_data}" \
    --tls-cert "${cert_dir}/certs/user.cert.pem" \
    --tls-key "${cert_dir}/private/user.key.pem" \
    --tls-protocol "${mail_server_tls_version}" \
    -tls \
    > /dev/null 2>&1

  ###################################################################
  #                                                                 #
  # 1.8  Retrieve exit code                                         #
  #                                                                 #
  ###################################################################

  exit_code_found=$?
  sleep 0.3

  email_found_contents=$(
    bootstrap__get_maildir_latest_email \
      "${email_username_to}"
  )

  email_found_path=$(
    bootstrap__get_maildir_latest_email_path \
      "${email_username_to}"
  )

  ###################################################################
  #                                                                 #
  # 1.9  Assertions                                                 #
  #                                                                 #
  ###################################################################

  assert_is_file "${email_found_path}"
  assert_not_empty "${email_found_contents}"
  assert_not_empty "${email_expected_message_subject}"
  assert_contains "${email_expected_message_subject}" "${email_found_contents}"
  assert_same "${exit_code_expected}" "${exit_code_found}"
}

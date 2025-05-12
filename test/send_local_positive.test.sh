#!/usr/bin/env bash

set -euo pipefail

######################################################################
#                                                                    #
# 1. FIXTURES                                                        #
#                                                                    #
######################################################################

declare -a fixtures

#
# fixtures: [recipient_email, recipient_user, sender_email, sender_user]
#
fixtures=(
  "admin, admin, datr.tech, datr.tech"
  "admin@localhost, admin, datr.tech@localhost, datr.tech"
  "admin@strachan.email, admin, datr.tech@strachan.email, datr.tech"
  "hostmaster, admin, datr.tech, datr.tech"
  "hostmaster, admin, datr.tech@localhost, datr.tech"
  "hostmaster, admin, datr.tech@strachan.email, datr.tech"
  "hostmaster@localhost, admin, datr.tech, datr.tech"
  "hostmaster@localhost, admin, datr.tech@localhost, datr.tech"
  "hostmaster@localhost, admin, datr.tech@strachan.email, datr.tech"
  "hostmaster@strachan.email, admin, datr.tech, datr.tech"
  "hostmaster@strachan.email, admin, datr.tech@localhost, datr.tech"
  "hostmaster@strachan.email, admin, datr.tech@strachan.email, datr.tech"
  "joe, datr.tech, admin@localhost, admin"
  "joe@localhost, datr.tech, admin@localhost, admin"
  "joe@strachan.email, datr.tech, admin@localhost, admin"
  "datr.tech, datr.tech, admin@localhost, admin"
  "datr.tech@localhost, datr.tech, admin@localhost, admin"
  "datr.tech@strachan.email, datr.tech, admin@strachan.email, admin"
  "john, datr.tech, admin@localhost, admin"
  "john@localhost, datr.tech, admin@localhost, admin"
  "john@strachan.email, datr.tech, admin@localhost, admin"
)

function test_send_local_positive() {
  #
  # Email vars
  #
  declare email_path
  declare email_contents_found

  #
  # Fixture vars
  #
  declare fixture
  declare -a fixture_array
  declare -i i

  #
  # Message vars
  #
  declare message_data
  declare message_envelope
  declare message_expected
  declare message_timestamp

  #
  # RCPT / SENDER user vars
  #
  declare recipient_email
  declare recipient_user
  declare sender_email
  declare sender_user

  for i in "${!fixtures[@]}"; do
    #
    # Arrange
    #
    fixture="${fixtures[$i]}"
    IFS=', ' read -r -a fixture_array <<< "${fixture}"

    recipient_email="${fixture_array[0]}"
    recipient_user="${fixture_array[1]}"
    sender_email="${fixture_array[2]}"
    sender_user="${fixture_array[3]}"

    bootstrap__rm_maildir_emails "${recipient_user}"

    message_timestamp=$(date +%s)
    message_data="test_send_local_positive_${i}_${recipient_email}_${sender_email}_${message_timestamp}"
    message_expected="MESSAGE: ${message_data}"

    message_envelope="TO: ${recipient_user}<${recipient_email}> \
      \nFROM: ${sender_user}<${sender_email}> \
      \nSUBJECT: ${message_data}\n${message_expected}"

    #
    # Act
    #
    echo -e "${message_envelope}" | exim4 -t
    sleep 0.3

    email_contents_found="$(bootstrap__get_maildir_latest_email "${recipient_user}")"
    email_path="$(bootstrap__get_maildir_latest_email_path "${recipient_user}")"

    #
    # Assert
    #
    assert_is_file "${email_path}"
    assert_not_empty "${message_expected}"
    assert_not_empty "${email_contents_found}"
    assert_contains "${message_expected}" "${email_contents_found}"

    #
    # TEARDOWN (per fixture)
    #
    email_contents_found=""
    email_path=""
    message_data=""
    message_envelope=""
    message_expected=""
    message_timestamp=""
    recipient_email=""
    recipient_user=""
    sender_email=""
    sender_user=""
  done
}

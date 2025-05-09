#!/usr/bin/env bash

set -euo pipefail

declare -a fixtures

#
# fixtures: [rcpt_email, rcpt_user, sender_email, sender_user]
#
fixtures=(
  "admin, admin, joealdersonstrachan, joealdersonstrachan"
  "admin@localhost, admin, joealdersonstrachan@localhost, joealdersonstrachan"
  "admin@strachan.email, admin, joealdersonstrachan@strachan.email, joealdersonstrachan"
  "hostmaster, admin, joealdersonstrachan, joealdersonstrachan"
  "hostmaster, admin, joealdersonstrachan@localhost, joealdersonstrachan"
  "hostmaster, admin, joealdersonstrachan@strachan.email, joealdersonstrachan"
  "hostmaster@localhost, admin, joealdersonstrachan, joealdersonstrachan"
  "hostmaster@localhost, admin, joealdersonstrachan@localhost, joealdersonstrachan"
  "hostmaster@localhost, admin, joealdersonstrachan@strachan.email, joealdersonstrachan"
  "hostmaster@strachan.email, admin, joealdersonstrachan, joealdersonstrachan"
  "hostmaster@strachan.email, admin, joealdersonstrachan@localhost, joealdersonstrachan"
  "hostmaster@strachan.email, admin, joealdersonstrachan@strachan.email, joealdersonstrachan"
  "joe, joealdersonstrachan, admin@localhost, admin"
  "joe@localhost, joealdersonstrachan, admin@localhost, admin"
  "joe@strachan.email, joealdersonstrachan, admin@localhost, admin"
  "joealdersonstrachan, joealdersonstrachan, admin@localhost, admin"
  "joealdersonstrachan@localhost, joealdersonstrachan, admin@localhost, admin"
  "joealdersonstrachan@strachan.email, joealdersonstrachan, admin@strachan.email, admin"
  "john, joealdersonstrachan, admin@localhost, admin"
  "john@localhost, joealdersonstrachan, admin@localhost, admin"
  "john@strachan.email, joealdersonstrachan, admin@localhost, admin"
)

function test_send_local_positive() {
  #
  # Fixture vars
  #
  declare fixture
  declare -a fixture_array

  #
  # Mailbox vars
  #
  declare mailbox
  declare mailbox_contents_found

  #
  # Message vars
  #
  declare envelope
  declare message
  declare message_expected

  #
  # RCPT / SENDER user vars
  #
  declare rcpt_email
  declare rcpt_user
  declare sender_email
  declare sender_user

  for fixture in "${fixtures[@]}";
  do
    #
    # Arrange
    #
    IFS=', ' read -r -a fixture_array <<< "${fixture}"

    rcpt_email="${fixture_array[0]}"
    rcpt_user="${fixture_array[1]}"
    sender_email="${fixture_array[2]}"
    sender_user="${fixture_array[3]}"

    mailbox="/var/mail/${rcpt_user}"

    if [ -f "${mailbox}" ]; then
      rm -f "${mailbox}"
    fi

    message="test_send_local_positive_${rcpt_email}"
    message_expected="MESSAGE: ${message}"

    envelope="TO: ${rcpt_user}<${rcpt_email}> \
      \nFROM: ${sender_user}<${sender_email}> \
      \nSUBJECT: ${message}\n${message_expected}"

    #
    # Act
    #
    echo -e "${envelope}" | exim4 -t
    sleep 0.3
    mailbox_contents_found=$(cat "${mailbox}")

    #
    # Assert
    #
    assert_is_file "${mailbox}"
    assert_not_empty "${message_expected}"
    assert_not_empty "${mailbox_contents_found}"
    assert_contains "${message_expected}" "${mailbox_contents_found}"

    envelope=""
    mailbox=""
    mailbox_contents_found=""
    message=""
    message_expected=""
    rcpt_email=""
    rcpt_user=""
    sender_email=""
    sender_user=""

  done
}
